#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PLUGIN_ROOT/scripts/lib/vm.sh"
source "$PLUGIN_ROOT/scripts/lib/probe.sh"
source "$PLUGIN_ROOT/scripts/lib/static_server.sh"
source "$PLUGIN_ROOT/scripts/lib/verifier.sh"

usage() {
    cat >&2 <<'EOF'
Usage: presentation.sh <project-dir> <build|start|info|stop> [focus]

Commands:
  build  Read the repo and generate the visual workflow HTML for the optional focus.
  start  Build, start the presentation server on a public 2000-2999 port, probe it, and print the URL.
  info   Print the last generated presentation URL.
  stop   Stop the current project's presentation server if a URL was recorded.

Optional:
  LARV_PRESENTATION_PORT=2000-2999 chooses an explicit public VM port.
  focus examples:
    skills visual representation
    dataflow loan approval
    feature onboarding workflow
EOF
    exit 64
}

project_root() {
    local dir="$1"
    cd "$dir" && pwd -P
}

read_yq() {
    local expr="$1" file="$2"
    command -v yq >/dev/null || return 0
    [ -f "$file" ] || return 0
    yq -r "$expr" "$file" 2>/dev/null || true
}

project_slug() {
    local dir="$1" slug
    slug="$(read_yq '.project.slug // ""' "$dir/docs/larv/STATE.yaml")"
    if [ -n "$slug" ] && [ "$slug" != "null" ]; then
        printf "%s\n" "$slug"
        return
    fi
    basename "$(project_root "$dir")" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-'
}

project_name() {
    local dir="$1" name
    name="$(read_yq '.project.name // .project.slug // ""' "$dir/docs/larv/STATE.yaml")"
    if [ -n "$name" ] && [ "$name" != "null" ]; then
        printf "%s\n" "$name"
        return
    fi
    if [ -f "$dir/composer.json" ] && command -v jq >/dev/null; then
        name="$(jq -r '.name // empty' "$dir/composer.json" 2>/dev/null || true)"
        [ -n "$name" ] && { printf "%s\n" "$name"; return; }
    fi
    basename "$(project_root "$dir")"
}

presentation_dir() {
    local dir="$1"
    if [ -d "$dir/docs/larv" ]; then
        echo "$dir/docs/larv/presentation"
    else
        echo "$dir/.larv/presentation"
    fi
}

presentation_url_file() {
    local dir="$1"
    if [ -d "$dir/docs/larv" ]; then
        echo "$dir/docs/larv/presentation-url.txt"
    else
        echo "$dir/.larv/presentation-url.txt"
    fi
}

html_escape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

list_files() {
    local dir="$1"
    if command -v rg >/dev/null; then
        (cd "$dir" && rg --files \
            -g '!vendor/**' -g '!node_modules/**' -g '!storage/**' -g '!bootstrap/cache/**' \
            -g '!public/build/**' -g '!dist/**' -g '!coverage/**' -g '!.git/**' \
            -g '!docs/larv/presentation/**' -g '!.larv/presentation/**' | sort)
    else
        (cd "$dir" && find . -type f \
            ! -path './vendor/*' ! -path './node_modules/*' ! -path './storage/*' \
            ! -path './bootstrap/cache/*' ! -path './public/build/*' ! -path './dist/*' \
            ! -path './coverage/*' ! -path './.git/*' ! -path './docs/larv/presentation/*' \
            ! -path './.larv/presentation/*' | sed 's#^\./##' | sort)
    fi
}

write_list_items() {
    local title="$1" content="$2"
    printf '<section class="panel"><div class="panel-head"><span>%s</span></div><ul class="list">\n' "$(printf "%s" "$title" | html_escape)"
    if [ -n "$content" ]; then
        printf "%s\n" "$content" | sed -n '1,14p' | while IFS= read -r line; do
            [ -n "$line" ] || continue
            printf '<li>%s</li>\n' "$(printf "%s" "$line" | html_escape)"
        done
    else
        printf '<li>No strong signal found yet. Add docs/user-manual/testing or role/persona notes to enrich this view.</li>\n'
    fi
    printf '</ul></section>\n'
}

collect_matches() {
    local dir="$1" pattern="$2" globs="$3"
    if command -v rg >/dev/null; then
        (cd "$dir" && rg -n -i "$pattern" \
            -g '*.md' -g '*.php' -g '*.tsx' -g '*.jsx' -g '*.vue' -g '*.feature' \
            -g '!vendor/**' -g '!node_modules/**' -g '!storage/**' -g '!bootstrap/cache/**' \
            -g '!docs/larv/presentation/**' -g '!.larv/presentation/**' 2>/dev/null \
            | sed 's/^[^:]*:[0-9]*://g' | sed 's/^[[:space:]-]*//' | awk 'length($0) > 2' | sort -u | sed -n '1,24p') || true
    fi
}

collect_routes() {
    local dir="$1"
    {
        [ -f "$dir/routes/web.php" ] && sed -n "s/.*Route::[a-zA-Z]*(['\"]\\([^'\"]*\\)['\"].*/\\1/p" "$dir/routes/web.php"
        [ -f "$dir/routes/api.php" ] && sed -n "s/.*Route::[a-zA-Z]*(['\"]\\([^'\"]*\\)['\"].*/api:\\1/p" "$dir/routes/api.php"
        true
    } | awk 'length($0) > 0' | sort -u | sed -n '1,30p'
}

collect_models() {
    local dir="$1"
    local roots=()
    [ -d "$dir/app" ] && roots+=("$dir/app")
    [ -d "$dir/database/migrations" ] && roots+=("$dir/database/migrations")
    [ "${#roots[@]}" -gt 0 ] || return 0
    find "${roots[@]}" -type f 2>/dev/null \
        \( -name '*.php' -o -name '*.sql' \) \
        | sed "s#^$dir/##" | grep -E '(app/Models|database/migrations)' | sed -n '1,30p' || true
}

collect_tables() {
    local dir="$1"
    {
        if [ -d "$dir/database/migrations" ]; then
            find "$dir/database/migrations" -type f -name '*.php' -print0 2>/dev/null \
                | xargs -0 sed -n "s/.*Schema::\\(create\\|table\\)(['\"]\\([^'\"]*\\)['\"].*/\\2/p" 2>/dev/null
        fi
        if [ -d "$dir/app/Models" ]; then
            find "$dir/app/Models" -type f -name '*.php' -print0 2>/dev/null \
                | xargs -0 sed -n 's/.*protected[[:space:]]\+\$table[[:space:]]*=[[:space:]]*['"'"'"]\([^'"'"'"]*\)['"'"'"].*/\1/p' 2>/dev/null
        fi
    } | awk 'length($0) > 0' | sort -u | sed -n '1,80p'
}

collect_log_tables() {
    collect_tables "$1" | grep -Ei '(audit|log|history|snapshot|event|activity|movement|session|failed|job|cache|telescope|pulse)' | sed -n '1,32p' || true
}

collect_core_tables() {
    collect_tables "$1" | grep -Evi '(audit|log|history|snapshot|event|activity|movement|session|failed|job|cache|telescope|pulse|password|personal_access)' | sed -n '1,36p' || true
}

snake_case() {
    printf "%s" "$1" \
        | sed -E 's/([A-Z]+)([A-Z][a-z])/\1_\2/g; s/([a-z0-9])([A-Z])/\1_\2/g' \
        | tr '[:upper:]' '[:lower:]'
}

pluralize_table() {
    local word="$1"
    case "$word" in
        *y) printf "%sies" "${word%y}" ;;
        *s) printf "%s" "$word" ;;
        *) printf "%ss" "$word" ;;
    esac
}

collect_model_table_map() {
    local dir="$1" file model table fallback
    [ -d "$dir/app/Models" ] || return 0
    while IFS= read -r -d '' file; do
        model="$(basename "$file" .php)"
        table="$(sed -n 's/.*protected[[:space:]]\+\$table[[:space:]]*=[[:space:]]*['"'"'"]\([^'"'"'"]*\)['"'"'"].*/\1/p' "$file" | head -1)"
        if [ -z "$table" ]; then
            fallback="$(snake_case "$model")"
            table="$(pluralize_table "$fallback")"
        fi
        printf "%s|%s\n" "$model" "$table"
    done < <(find "$dir/app/Models" -type f -name '*.php' -print0 2>/dev/null)
}

filter_core_edges() {
    local edges="$1" core_tables="$2"
    [ -n "$edges" ] || return 0
    [ -n "$core_tables" ] || return 0
    awk '
        NR == FNR {
            core[$0] = 1
            next
        }
        {
            parent = $1
            child = $3
            if (core[parent] && core[child]) {
                print $0
            }
        }
    ' <(printf "%s\n" "$core_tables") <(printf "%s\n" "$edges")
}

collect_table_edges() {
    local dir="$1" file table explicit inferred field base target
    [ -d "$dir/database/migrations" ] || return 0
    while IFS= read -r -d '' file; do
        table="$(sed -n "s/.*Schema::\\(create\\|table\\)(['\"]\\([^'\"]*\\)['\"].*/\\2/p" "$file" | head -1)"
        [ -n "$table" ] || continue
        explicit="$(sed -n "s/.*foreignId(['\"]\\([^'\"]*\\)['\"]).*constrained(['\"]\\([^'\"]*\\)['\"]).*/\\2 -> $table via \\1/p" "$file")"
        if [ -n "$explicit" ]; then
            printf "%s\n" "$explicit"
        fi
        inferred="$(sed -n "s/.*foreignId(['\"]\\([^'\"]*_id\\)['\"]).*constrained().*/\\1/p" "$file")"
        while IFS= read -r field; do
            [ -n "$field" ] || continue
            base="${field%_id}"
            case "$base" in
                company) target="companies" ;;
                category) target="categories" ;;
                status) target="statuses" ;;
                *) target="${base}s" ;;
            esac
            printf "%s -> %s via %s\n" "$target" "$table" "$field"
        done <<<"$inferred"
    done < <(find "$dir/database/migrations" -type f -name '*.php' -print0 2>/dev/null)
}

collect_data_write_flows() {
    local dir="$1" core_tables="$2" model_map="$3" candidates rel line_no line model table var
    [ -n "$core_tables" ] || return 0
    [ -d "$dir/app" ] || return 0
    if command -v rg >/dev/null; then
        candidates="$(cd "$dir" && rg -n '(::|->|DB::table).*(create|updateOrCreate|firstOrCreate|createOrFirst|insert|insertOrIgnore|upsert|update|save|delete|forceDelete)\(' app routes -g '*.php' -g '!vendor/**' -g '!node_modules/**' 2>/dev/null || true)"
    else
        candidates="$(find "$dir/app" "$dir/routes" -type f -name '*.php' -print 2>/dev/null | while IFS= read -r file; do grep -nE '(::|->|DB::table).*(create|updateOrCreate|firstOrCreate|createOrFirst|insert|insertOrIgnore|upsert|update|save|delete|forceDelete)\(' "$file" | sed "s#^#$file:#"; done | sed "s#^$dir/##")"
    fi
    while IFS=: read -r rel line_no line; do
        [ -n "$line" ] || continue
        if printf "%s" "$line" | grep -Eq '\b[A-Z][A-Za-z0-9_]*::'; then
            model="$(printf "%s" "$line" | sed -n 's/.*\b\([A-Z][A-Za-z0-9_]*\)::.*$/\1/p' | head -1)"
            table="$(printf "%s\n" "$model_map" | awk -F'|' -v model="$model" '$1 == model { print $2; exit }')"
            if [ -n "$table" ] && printf "%s\n" "$core_tables" | grep -Fxq "$table"; then
                if printf "%s" "$line" | grep -Eq '::(withoutGlobalScopes\(\)->)?(create|updateOrCreate|firstOrCreate|createOrFirst)\('; then
                    printf "CREATE|%s|%s|%s::create\n" "$table" "$rel" "$model"
                fi
                if printf "%s" "$line" | grep -Eq '::.*->update\('; then
                    printf "UPDATE|%s|%s|%s query update\n" "$table" "$rel" "$model"
                fi
                if printf "%s" "$line" | grep -Eq '::.*->(delete|forceDelete)\('; then
                    printf "DELETE|%s|%s|%s query delete\n" "$table" "$rel" "$model"
                fi
            fi
        fi
        if printf "%s" "$line" | grep -Eq '\$[A-Za-z_][A-Za-z0-9_]*->(update|save)\('; then
            var="$(printf "%s" "$line" | sed -n 's/.*\$\([A-Za-z_][A-Za-z0-9_]*\)->\(update\|save\)(.*/\1/p' | head -1)"
            table="$(pluralize_table "$(snake_case "$var")")"
            printf "%s\n" "$core_tables" | grep -Fxq "$table" && printf "UPDATE|%s|%s|$%s update\n" "$table" "$rel" "$var"
        fi
        if printf "%s" "$line" | grep -Eq '\$[A-Za-z_][A-Za-z0-9_]*->(delete|forceDelete)\('; then
            var="$(printf "%s" "$line" | sed -n 's/.*\$\([A-Za-z_][A-Za-z0-9_]*\)->\(delete\|forceDelete\)(.*/\1/p' | head -1)"
            table="$(pluralize_table "$(snake_case "$var")")"
            printf "%s\n" "$core_tables" | grep -Fxq "$table" && printf "DELETE|%s|%s|$%s delete\n" "$table" "$rel" "$var"
        fi
        if printf "%s" "$line" | grep -Eq "DB::table\\(['\"][^'\"]+['\"]\\)->.*(insert|insertOrIgnore|upsert)\\("; then
            table="$(printf "%s" "$line" | sed -n "s/.*DB::table(['\"]\\([^'\"]*\\)['\"]).*/\\1/p" | head -1)"
            printf "%s\n" "$core_tables" | grep -Fxq "$table" && printf "CREATE|%s|%s|DB::table insert\n" "$table" "$rel"
        fi
        if printf "%s" "$line" | grep -Eq "DB::table\\(['\"][^'\"]+['\"]\\)->.*update\\("; then
            table="$(printf "%s" "$line" | sed -n "s/.*DB::table(['\"]\\([^'\"]*\\)['\"]).*/\\1/p" | head -1)"
            printf "%s\n" "$core_tables" | grep -Fxq "$table" && printf "UPDATE|%s|%s|DB::table update\n" "$table" "$rel"
        fi
        if printf "%s" "$line" | grep -Eq "DB::table\\(['\"][^'\"]+['\"]\\)->.*delete\\("; then
            table="$(printf "%s" "$line" | sed -n "s/.*DB::table(['\"]\\([^'\"]*\\)['\"]).*/\\1/p" | head -1)"
            printf "%s\n" "$core_tables" | grep -Fxq "$table" && printf "DELETE|%s|%s|DB::table delete\n" "$table" "$rel"
        fi
    done <<<"$candidates"
}

focus_mode() {
    local focus="$1" lower
    lower="$(printf "%s" "$focus" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
        *skill*) echo "skills" ;;
        *dataflow*|*data\ flow*) echo "dataflow" ;;
        *feature*) echo "feature" ;;
        *) echo "workflow" ;;
    esac
}

focus_title() {
    local mode="$1" focus="$2"
    case "$mode" in
        skills) echo "Skills visual representation" ;;
        dataflow) echo "Dataflow: ${focus:-repository}" ;;
        feature) echo "Feature workflow: ${focus#feature }" ;;
        *) echo "Role workflow map" ;;
    esac
}

focus_summary() {
    local mode="$1"
    case "$mode" in
        skills)
            echo "Generated from command files, larv skills, Codex skill aliases, scripts, tests, and README references. Use this to explain what the plugin can do and how the workflow is wired."
            ;;
        dataflow)
            echo "Generated from models, migrations, routes, controllers, tests, docs, and feature references. Use this to explain how data enters, changes, and exits the selected feature."
            ;;
        feature)
            echo "Generated from feature docs, routes, screens, tests, handoff slices, and user guides. Use this to explain the selected feature's user journey and implementation surface."
            ;;
        *)
            echo "Generated from repository files, larv docs, routes, screens, tests, and user-manual guides. Use this to explain how each role moves through the product before or after implementation."
            ;;
    esac
}

focus_pattern() {
    local focus="$1" escaped
    escaped="$(printf "%s" "$focus" | sed -E 's/^(dataflow|data flow|feature|skills|visual representation)[[:space:]]+//I' | sed 's/[][(){}.^$*+?|\\]/\\&/g')"
    [ -n "$escaped" ] && printf "%s" "$escaped" || printf "."
}

collect_skills() {
    local dir="$1"
    list_files "$dir" | grep -E '^(skills|codex-skills)/[^/]+/SKILL\.md$|^commands/larv-.*\.md$' | sed -n '1,80p' || true
}

collect_skill_names() {
    local dir="$1"
    find "$dir/skills" "$dir/codex-skills" "$dir/commands" -type f 2>/dev/null \
        \( -name 'SKILL.md' -o -name 'larv-*.md' \) \
        | sed "s#^$dir/##" | sort | sed -n '1,80p' || true
}

collect_dataflow() {
    local dir="$1" focus="$2" pattern
    pattern="$(focus_pattern "$focus")"
    {
        collect_matches "$dir" "(dataflow|data flow|database|migration|model|table|field|foreign key|request|response|event|job|queue|policy|controller|service|repository|${pattern})" ""
        collect_models "$dir"
        collect_routes "$dir"
    } | awk 'length($0) > 0' | sort -u | sed -n '1,40p'
}

collect_feature_focus() {
    local dir="$1" focus="$2" pattern
    pattern="$(focus_pattern "$focus")"
    {
        collect_matches "$dir" "(feature|workflow|screen|route|test|acceptance|handoff|slice|${pattern})" ""
        list_files "$dir" | grep -Ei "$pattern" || true
    } | awk 'length($0) > 0' | sort -u | sed -n '1,40p'
}

collect_role_names() {
    local dir="$1"
    local corpus role
    if command -v rg >/dev/null; then
        corpus="$(cd "$dir" && rg -i --no-heading \
            -g '*.md' -g '*.php' -g '*.blade.php' -g '*.tsx' -g '*.jsx' -g '*.vue' \
            -g '!vendor/**' -g '!node_modules/**' -g '!storage/**' -g '!bootstrap/cache/**' \
            '(Super ?Admin|Admin|Field Collector|Tele Collector|Client Updater|Reporter|Legal|Manager|Borrower|Loan Officer|Credit Manager|CEO|Department Head|Operator|Approver|Reviewer|Candidate|HR|Member|User)' 2>/dev/null || true)"
    else
        corpus="$(collect_matches "$dir" '(Super ?Admin|Admin|Field Collector|Tele Collector|Client Updater|Reporter|Legal|Manager|Borrower|Loan Officer|Credit Manager|CEO|Department Head|Operator|Approver|Reviewer|Candidate|HR|Member|User)' '')"
    fi
    for role in \
        "SuperAdmin" "Admin" "Tele Collector" "Field Collector" "Client Updater" \
        "Reporter" "Legal" "Manager" "CEO" "Department Head" "Borrower" \
        "Loan Officer" "Credit Manager" "Operator" "Approver" "Reviewer" \
        "Candidate" "HR" "Member" "User"; do
        if grep -Eiq "$(printf "%s" "$role" | sed 's/SuperAdmin/Super ?Admin/')" <<<"$corpus"; then
            printf "%s\n" "$role"
        fi
    done | sed -n '1,10p'
}

write_graph_cards() {
    local content="$1" class_name="${2:-node}" limit="${3:-12}" index=1
    if [ -n "$content" ]; then
        printf "%s\n" "$content" | sed -n "1,${limit}p" | while IFS= read -r line; do
            [ -n "$line" ] || continue
            printf '<article class="%s" style="--i:%s"><b>%02d</b><span>%s</span></article>\n' \
                "$class_name" "$index" "$index" "$(printf "%s" "$line" | html_escape)"
            index=$((index + 1))
        done
    else
        printf '<article class="%s" style="--i:1"><b>01</b><span>No strong repo signal found. Add docs, routes, models, tests, or seed guides to enrich this graph.</span></article>\n' "$class_name"
    fi
}

write_visual_graph_page() {
    local out="$1" title="$2" subtitle="$3" eyebrow="$4" nav_prefix="$5" lane_a_title="$6" lane_a_content="$7" lane_b_title="$8" lane_b_content="$9" lane_c_title="${10}" lane_c_content="${11}"
    {
        cat <<'HTML_HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>larv visual graph</title>
<style>
:root{--paper:#f2eee5;--ink:#201d18;--muted:#746c5f;--line:#d8d0c2;--panel:rgba(255,252,244,.78);--panel-strong:#fffaf0;--accent:#9f6a3d;--accent-dark:#68452b;--green:#5c7258;--blue:#506a78;--red:#8a4d42;--shadow:0 24px 80px rgba(61,49,34,.12);--radius:28px;--mono:"SFMono-Regular","Cascadia Mono","Liberation Mono",monospace;--sans:"Aptos","Segoe UI",sans-serif}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;min-height:100dvh;font-family:var(--sans);color:var(--ink);background:radial-gradient(circle at 84% 8%,rgba(159,106,61,.18),transparent 34%),radial-gradient(circle at 8% 42%,rgba(80,106,120,.14),transparent 32%),linear-gradient(135deg,#f8f2e7 0%,var(--paper) 52%,#e9dfcf 100%);overflow-x:hidden}
body:before{content:"";position:fixed;inset:0;pointer-events:none;opacity:.28;background-image:linear-gradient(rgba(32,29,24,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(32,29,24,.035) 1px,transparent 1px);background-size:42px 42px;mask-image:linear-gradient(to bottom,black,transparent 90%)}
.shell{width:min(1420px,calc(100% - 36px));margin:0 auto;padding:34px 0 70px}.topbar{display:flex;justify-content:space-between;gap:18px;align-items:center;margin-bottom:30px}.brand{display:flex;gap:12px;align-items:center}.mark{width:42px;height:42px;border-radius:14px;background:var(--ink);color:var(--paper);display:grid;place-items:center;font-family:var(--mono);font-size:12px;letter-spacing:.08em;box-shadow:var(--shadow)}.brand strong{display:block;font-size:14px;letter-spacing:.08em;text-transform:uppercase}.brand span{color:var(--muted);font-size:12px}.status{border:1px solid var(--line);background:rgba(255,255,255,.45);border-radius:999px;padding:8px 12px;font-family:var(--mono);font-size:12px;color:var(--accent-dark)}
.hero{display:grid;grid-template-columns:1.05fr .95fr;gap:26px;align-items:stretch;margin-bottom:26px}.hero-main,.hero-side,.panel{border:1px solid rgba(138,119,91,.28);background:var(--panel);backdrop-filter:blur(18px);border-radius:var(--radius);box-shadow:var(--shadow)}.hero-main{padding:clamp(28px,5vw,58px);min-height:360px;position:relative;overflow:hidden}.hero-main:after{content:"";position:absolute;width:360px;height:360px;border-radius:50%;right:-120px;top:-110px;border:1px solid rgba(159,106,61,.25);background:radial-gradient(circle,rgba(159,106,61,.12),transparent 65%)}.eyebrow{font-family:var(--mono);color:var(--accent-dark);font-size:12px;text-transform:uppercase;letter-spacing:.14em;margin-bottom:18px}h1{font-size:clamp(40px,6vw,82px);line-height:.92;letter-spacing:-.07em;margin:0 0 22px;max-width:950px}.lead{font-size:clamp(17px,2vw,22px);color:#5c5347;line-height:1.45;max-width:800px;margin:0}.hero-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:34px}.btn{display:inline-flex;align-items:center;gap:10px;border:1px solid var(--ink);background:var(--ink);color:var(--paper);border-radius:999px;padding:12px 16px;text-decoration:none;font-weight:700;font-size:13px}.btn.secondary{background:transparent;color:var(--ink);border-color:var(--line)}.hero-side{padding:24px;display:grid;align-content:space-between;gap:18px}.metric{padding:18px;border-radius:22px;background:rgba(255,250,240,.72);border:1px solid rgba(216,208,194,.7)}.metric b{display:block;font-size:30px;letter-spacing:-.05em}.metric span{color:var(--muted);font-size:13px;line-height:1.35}
.section-title{display:flex;justify-content:space-between;align-items:end;gap:16px;margin:34px 0 16px}.section-title h2{font-size:clamp(26px,4vw,48px);letter-spacing:-.05em;margin:0}.section-title p{color:var(--muted);max-width:560px;margin:0;line-height:1.45}.graph{display:grid;gap:14px}.lane{display:grid;grid-template-columns:190px 1fr;gap:14px;align-items:stretch}.lane-label{border-radius:24px;border:1px solid var(--line);background:rgba(255,255,255,.38);padding:18px;position:sticky;top:16px;min-height:110px}.lane-label .role{font-family:var(--mono);font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.12em}.lane-label strong{display:block;font-size:24px;letter-spacing:-.04em;margin-top:8px}.nodes{display:grid;grid-template-columns:repeat(6,minmax(170px,1fr));gap:12px;overflow-x:auto;padding-bottom:4px}.node{min-height:150px;border-radius:24px;padding:16px;border:1px solid var(--line);background:var(--panel-strong);position:relative;animation:rise .65s ease both;animation-delay:calc(var(--i) * 45ms)}.node:after{content:"->";position:absolute;right:-12px;top:22px;font-family:var(--mono);color:var(--accent);background:var(--paper);border:1px solid var(--line);border-radius:999px;padding:2px 5px;font-size:11px}.node:last-child:after{display:none}.node b{display:block;font-family:var(--mono);color:var(--accent-dark);font-size:11px;margin-bottom:16px}.node span{display:block;color:var(--muted);font-size:13px;line-height:1.35}.lane:nth-child(1) .node{background:#f8f3e9}.lane:nth-child(2) .node{background:#fff8ec}.lane:nth-child(3) .node{background:#eef3f0}.footer{color:var(--muted);font-size:12px;margin-top:38px;font-family:var(--mono)}@keyframes rise{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}@media(max-width:980px){.hero{grid-template-columns:1fr}.lane{grid-template-columns:1fr}.lane-label{position:relative;top:auto;min-height:auto}.nodes{grid-template-columns:repeat(6,minmax(230px,1fr))}}
</style>
</head>
<body>
HTML_HEAD
        printf '<main class="shell"><div class="topbar"><div class="brand"><div class="mark">Attio Venture</div><div><strong>%s</strong><span>larv visual representation</span></div></div><div class="status">%s</div></div>\n' "$(printf "%s" "$title" | html_escape)" "$(printf "%s" "$eyebrow" | html_escape)"
        printf '<section class="hero"><div class="hero-main"><div class="eyebrow">%s</div><h1>%s</h1><p class="lead">%s</p><div class="hero-actions"><a class="btn" href="#graph">View graph</a><a class="btn secondary" href="%sindex.html">Summary</a><a class="btn secondary" href="%sdata-flow-graph.html">Data flow</a><a class="btn secondary" href="%suser-flow-graph.html">User flow</a><a class="btn secondary" href="%scomplete-workflow-graph.html">Complete workflow</a></div></div><aside class="hero-side"><div class="metric"><b>Data</b><span>Database tables, migrations, models, jobs, policies, and controller entry points.</span></div><div class="metric"><b>Users</b><span>Roles, personas, routes, screens, seed accounts, and testable journeys.</span></div><div class="metric"><b>Workflow</b><span>Complete graph tying user actions to runtime state and verification.</span></div></aside></section>\n' "$(printf "%s" "$eyebrow" | html_escape)" "$(printf "%s" "$title" | html_escape)" "$(printf "%s" "$subtitle" | html_escape)" "$nav_prefix" "$nav_prefix" "$nav_prefix" "$nav_prefix"
        printf '<section id="graph"><div class="section-title"><h2>Graph lanes</h2><p>Each lane is generated from repository evidence, not hand-maintained screenshots.</p></div><div class="graph">\n'
        printf '<div class="lane"><div class="lane-label"><div class="role">Lane A</div><strong>%s</strong></div><div class="nodes">\n' "$(printf "%s" "$lane_a_title" | html_escape)"
        write_graph_cards "$lane_a_content" node 8
        printf '</div></div>\n'
        printf '<div class="lane"><div class="lane-label"><div class="role">Lane B</div><strong>%s</strong></div><div class="nodes">\n' "$(printf "%s" "$lane_b_title" | html_escape)"
        write_graph_cards "$lane_b_content" node 8
        printf '</div></div>\n'
        printf '<div class="lane"><div class="lane-label"><div class="role">Lane C</div><strong>%s</strong></div><div class="nodes">\n' "$(printf "%s" "$lane_c_title" | html_escape)"
        write_graph_cards "$lane_c_content" node 8
        printf '</div></div></div></section><div class="footer">Generated by /larv:presentation · visual graph artifact</div></main></body></html>\n'
    } > "$out"
}

write_table_nodes() {
    local content="$1" class_name="${2:-table-node}" index=1
    if [ -n "$content" ]; then
        printf "%s\n" "$content" | sed -n '1,40p' | while IFS= read -r table; do
            [ -n "$table" ] || continue
            printf '<article class="%s" style="--i:%s"><b>%s</b><span>%s</span></article>\n' \
                "$class_name" "$index" "$(printf "%02d" "$index")" "$(printf "%s" "$table" | html_escape)"
            index=$((index + 1))
        done
    else
        printf '<article class="%s" style="--i:1"><b>01</b><span>No tables detected. Add Laravel migrations or Eloquent models to populate this flowchart.</span></article>\n' "$class_name"
    fi
}

write_edge_rows() {
    local content="$1" index=1
    if [ -n "$content" ]; then
        printf "%s\n" "$content" | awk 'length($0) > 0' | sort -u | sed -n '1,40p' | while IFS= read -r edge; do
            printf '<div class="edge-row" style="--i:%s"><span>%s</span></div>\n' "$index" "$(printf "%s" "$edge" | html_escape)"
            index=$((index + 1))
        done
    else
        printf '<div class="edge-row"><span>No foreign-key edges detected. The graph still lists tables, but migrations should use foreignId()->constrained() for relationship arrows.</span></div>\n'
    fi
}

mermaid_id() {
    printf "%s" "$1" | tr -c 'A-Za-z0-9_' '_' | sed 's/^_\+//; s/_\+$//'
}

build_logic_mermaid() {
    local write_rows="$1" core_tables="$2"
    {
        printf "flowchart TD\n"
        printf "  UI[User action or API request] --> AUTH[Validate and authorize]\n"
        printf "  AUTH --> RULES[Apply backend business rules]\n"
        printf "  RULES --> CREATE[CREATE data]\n"
        printf "  RULES --> UPDATE[UPDATE data]\n"
        printf "  RULES --> DELETE[DELETE data]\n"
        local op table source evidence id seen_create="" seen_update="" seen_delete="" table_id
        if [ -n "$write_rows" ]; then
            while IFS='|' read -r op table source evidence; do
                [ -n "$op" ] && [ -n "$table" ] || continue
                id="$(mermaid_id "${op}_${table}")"
                table_id="$(mermaid_id "T_${table}")"
                printf "  %s --> %s[%s %s]\n" "$op" "$id" "$op" "$table"
                printf "  %s --> %s[(%s)]\n" "$id" "$table_id" "$table"
                case "$op" in
                    CREATE) seen_create=1 ;;
                    UPDATE) seen_update=1 ;;
                    DELETE) seen_delete=1 ;;
                esac
            done <<<"$(printf "%s\n" "$write_rows" | awk -F'|' 'length($1) && length($2) { key=$1 "|" $2; if (!seen[key]++) print $0 }' | sed -n '1,24p')"
        fi
        if [ -z "$seen_create$seen_update$seen_delete" ]; then
            local first_table
            first_table="$(printf "%s\n" "$core_tables" | awk 'length($0) > 0 { print; exit }')"
            [ -n "$first_table" ] || first_table="core business table"
            table_id="$(mermaid_id "T_${first_table}")"
            printf "  CREATE --> CREATE_%s[CREATE %s]\n" "$table_id" "$first_table"
            printf "  UPDATE --> UPDATE_%s[UPDATE %s]\n" "$table_id" "$first_table"
            printf "  DELETE --> DELETE_%s[DELETE %s]\n" "$table_id" "$first_table"
            printf "  CREATE_%s --> %s[(%s)]\n" "$table_id" "$table_id" "$first_table"
            printf "  UPDATE_%s --> %s\n" "$table_id" "$table_id"
            printf "  DELETE_%s --> %s\n" "$table_id" "$table_id"
        fi
        printf "  CREATE --> RESPONSE[Return updated UI or report]\n"
        printf "  UPDATE --> RESPONSE\n"
        printf "  DELETE --> RESPONSE\n"
    }
}

write_database_flow_page() {
    local out="$1" title="$2" slug="$3" routes="$4" core_tables="$5" edge_rows="$6" write_rows="$7" now="$8"
    local logic_mermaid
    logic_mermaid="$(build_logic_mermaid "$write_rows" "$core_tables")"
    {
        cat <<'HTML_HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>larv database flow graph</title>
<style>
:root{--paper:#f2eee5;--ink:#201d18;--muted:#746c5f;--line:#d8d0c2;--panel:rgba(255,252,244,.78);--panel-strong:#fffaf0;--accent:#9f6a3d;--accent-dark:#68452b;--green:#5c7258;--blue:#506a78;--red:#8a4d42;--shadow:0 24px 80px rgba(61,49,34,.12);--radius:28px;--mono:"SFMono-Regular","Cascadia Mono","Liberation Mono",monospace;--sans:"Aptos","Segoe UI",sans-serif}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;min-height:100dvh;font-family:var(--sans);color:var(--ink);background:radial-gradient(circle at 84% 8%,rgba(159,106,61,.18),transparent 34%),radial-gradient(circle at 8% 42%,rgba(80,106,120,.14),transparent 32%),linear-gradient(135deg,#f8f2e7 0%,var(--paper) 52%,#e9dfcf 100%);overflow-x:hidden}body:before{content:"";position:fixed;inset:0;pointer-events:none;opacity:.28;background-image:linear-gradient(rgba(32,29,24,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(32,29,24,.035) 1px,transparent 1px);background-size:42px 42px;mask-image:linear-gradient(to bottom,black,transparent 90%)}
.shell{width:min(1480px,calc(100% - 36px));margin:0 auto;padding:34px 0 70px}.topbar{display:flex;justify-content:space-between;gap:18px;align-items:center;margin-bottom:30px}.brand{display:flex;gap:12px;align-items:center}.mark{width:42px;height:42px;border-radius:14px;background:var(--ink);color:var(--paper);display:grid;place-items:center;font-family:var(--mono);font-size:12px;letter-spacing:.08em;box-shadow:var(--shadow)}.brand strong{display:block;font-size:14px;letter-spacing:.08em;text-transform:uppercase}.brand span{color:var(--muted);font-size:12px}.status{border:1px solid var(--line);background:rgba(255,255,255,.45);border-radius:999px;padding:8px 12px;font-family:var(--mono);font-size:12px;color:var(--accent-dark)}
.hero{display:grid;grid-template-columns:1.05fr .95fr;gap:26px;align-items:stretch;margin-bottom:26px}.hero-main,.hero-side,.panel,.flow-section{border:1px solid rgba(138,119,91,.28);background:var(--panel);backdrop-filter:blur(18px);border-radius:var(--radius);box-shadow:var(--shadow)}.hero-main{padding:clamp(28px,5vw,58px);min-height:360px;position:relative;overflow:hidden}.hero-main:after{content:"";position:absolute;width:360px;height:360px;border-radius:50%;right:-120px;top:-110px;border:1px solid rgba(159,106,61,.25);background:radial-gradient(circle,rgba(159,106,61,.12),transparent 65%)}.eyebrow{font-family:var(--mono);color:var(--accent-dark);font-size:12px;text-transform:uppercase;letter-spacing:.14em;margin-bottom:18px}h1{font-size:clamp(40px,6vw,82px);line-height:.92;letter-spacing:-.07em;margin:0 0 22px;max-width:980px}.lead{font-size:clamp(17px,2vw,22px);color:#5c5347;line-height:1.45;max-width:840px;margin:0}.hero-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:34px}.btn{display:inline-flex;align-items:center;gap:10px;border:1px solid var(--ink);background:var(--ink);color:var(--paper);border-radius:999px;padding:12px 16px;text-decoration:none;font-weight:700;font-size:13px}.btn.secondary{background:transparent;color:var(--ink);border-color:var(--line)}.hero-side{padding:24px;display:grid;align-content:space-between;gap:18px}.metric{padding:18px;border-radius:22px;background:rgba(255,250,240,.72);border:1px solid rgba(216,208,194,.7)}.metric b{display:block;font-size:30px;letter-spacing:-.05em}.metric span{color:var(--muted);font-size:13px;line-height:1.35}
.section-title{display:flex;justify-content:space-between;align-items:end;gap:16px;margin:34px 0 16px}.section-title h2{font-size:clamp(26px,4vw,48px);letter-spacing:-.05em;margin:0}.section-title p{color:var(--muted);max-width:620px;margin:0;line-height:1.45}.flow-board{display:grid;grid-template-columns:1.05fr 1.3fr .95fr;gap:14px}.flow-section{padding:18px;min-height:300px}.flow-section h3{margin:0 0 12px;font-size:20px;letter-spacing:-.04em}.table-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.table-node{border:1px solid var(--line);background:var(--panel-strong);border-radius:18px;padding:12px;min-height:78px;animation:rise .6s ease both;animation-delay:calc(var(--i) * 35ms)}.table-node.log{background:#eef3f0}.table-node b{display:block;font-family:var(--mono);font-size:11px;color:var(--accent-dark);margin-bottom:9px}.table-node span{font-family:var(--mono);font-size:13px;line-height:1.2;word-break:break-word}.edge-list{display:grid;gap:8px}.edge-row{border:1px solid var(--line);background:rgba(255,250,240,.72);border-radius:999px;padding:10px 12px;font-family:var(--mono);font-size:12px;color:#554838;animation:rise .6s ease both;animation-delay:calc(var(--i) * 35ms)}.mermaid{border:1px solid var(--line);background:rgba(255,250,240,.72);border-radius:22px;padding:20px;min-height:430px;display:grid;place-items:center;overflow:auto}.footer{color:var(--muted);font-size:12px;margin-top:38px;font-family:var(--mono)}@keyframes rise{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}@media(max-width:1050px){.hero,.flow-board{grid-template-columns:1fr}.table-grid{grid-template-columns:1fr}}
</style>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>document.addEventListener("DOMContentLoaded",function(){if(window.mermaid){mermaid.initialize({startOnLoad:true,theme:"base",themeVariables:{primaryColor:"#fffaf0",primaryBorderColor:"#d8d0c2",primaryTextColor:"#201d18",lineColor:"#9f6a3d",tertiaryColor:"#eef3f0"}});}});</script>
</head>
<body>
HTML_HEAD
        printf '<main class="shell"><div class="topbar"><div class="brand"><div class="mark">Attio Venture</div><div><strong>%s</strong><span>core business data flowchart</span></div></div><div class="status">core data graph · %s · %s</div></div>\n' "$(printf "%s" "$title" | html_escape)" "$(printf "%s" "$slug" | html_escape)" "$(printf "%s" "$now" | html_escape)"
        printf '<section class="hero"><div class="hero-main"><div class="eyebrow">core business data flow</div><h1>%s data flow graph</h1><p class="lead">A focused business-data flowchart generated from migrations, models, routes, and logic references. It excludes audit logs, histories, sessions, cache tables, jobs, and other infrastructure tables so the demo stays centered on the product domain.</p><div class="hero-actions"><a class="btn" href="#tables">View table flow</a><a class="btn secondary" href="index.html">Summary</a><a class="btn secondary" href="user-flow-graph.html">User flow</a><a class="btn secondary" href="complete-workflow-graph.html">Complete workflow</a></div></div><aside class="hero-side"><div class="metric"><b>Routes</b><span>Business entry points that create, review, update, approve, or report core records.</span></div><div class="metric"><b>Tables</b><span>Only core domain tables are included in the presentation flow.</span></div><div class="metric"><b>Arrows</b><span>Foreign keys are rendered only when both sides are core business tables.</span></div></aside></section>\n' "$(printf "%s" "$title" | html_escape)"
        printf '<section id="tables"><div class="section-title"><h2>Core business table flowchart</h2><p>Use this graph to explain where business data enters, how it moves between domain tables, and which relationships drive the product workflow.</p></div><div class="flow-board">\n'
        printf '<div class="flow-section"><h3>Inputs and routes</h3><div class="edge-list">\n'
        write_edge_rows "$routes"
        printf '</div></div><div class="flow-section"><h3>Core database tables</h3><div class="table-grid">\n'
        write_table_nodes "$core_tables" table-node
        printf '</div></div><div class="flow-section"><h3>Core relationship movement</h3><div class="edge-list">\n'
        write_edge_rows "$edge_rows"
        printf '</div></div></div></section>\n'
        printf '<section><div class="section-title"><h2>Foreign-key data movement</h2><p>Each row is parsed from Laravel migrations using <code>foreignId(...)->constrained(...)</code> and filtered to core business tables only.</p></div><div class="flow-section"><div class="edge-list">\n'
        write_edge_rows "$edge_rows"
        printf '</div></div></section>\n'
        printf '<section><div class="section-title"><h2>Business logic and write rules</h2><p>Rendered Mermaid diagram for demos, training, and technical review. The chart is generated from backend code and the database schema, showing detected CREATE, UPDATE, and DELETE flows into core business tables.</p></div><div class="flow-section"><div class="mermaid">\n'
        printf "%s\n" "$logic_mermaid"
        printf '</div></div></section><div class="footer">Generated by /larv:presentation · database flowchart artifact</div></main></body></html>\n'
    } > "$out"
}

write_role_wizard_steps() {
    local role="$1"
    printf '<div class="wizard-steps">\n'
    printf '<article class="wizard-step"><b>01</b><h3>Enter %s workspace</h3><p>Sign in with the seeded or production identity for this role and land on the correct permission-gated menu.</p></article>\n' "$(printf "%s" "$role" | html_escape)"
    printf '<article class="wizard-step"><b>02</b><h3>Review assigned work</h3><p>Open the queue, dashboard, report, or record list that this role is expected to use during training.</p></article>\n'
    printf '<article class="wizard-step"><b>03</b><h3>Open a real record</h3><p>Inspect the seeded client, request, task, or domain record with enough data to demonstrate the full flow.</p></article>\n'
    printf '<article class="wizard-step"><b>04</b><h3>Perform the role action</h3><p>Complete the primary action: create, update, approve, record, assign, export, resolve, or escalate.</p></article>\n'
    printf '<article class="wizard-step"><b>05</b><h3>Verify evidence</h3><p>Show the resulting status change, audit/history row, notification, job, report, or linked child record.</p></article>\n'
    printf '<article class="wizard-step"><b>06</b><h3>Hand off next step</h3><p>Explain what the next role sees and where the user should go after this step in go-live operations.</p></article>\n'
    printf '</div>\n'
}

write_user_wizard_page() {
    local out="$1" title="$2" slug="$3" roles="$4" routes="$5" screens="$6" tests="$7" now="$8"
    {
        cat <<'HTML_HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>larv user role wizard</title>
<style>
:root{--paper:#f2eee5;--ink:#201d18;--muted:#746c5f;--line:#d8d0c2;--panel:rgba(255,252,244,.78);--panel-strong:#fffaf0;--accent:#9f6a3d;--accent-dark:#68452b;--green:#5c7258;--blue:#506a78;--shadow:0 24px 80px rgba(61,49,34,.12);--radius:28px;--mono:"SFMono-Regular","Cascadia Mono","Liberation Mono",monospace;--sans:"Aptos","Segoe UI",sans-serif}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;min-height:100dvh;font-family:var(--sans);color:var(--ink);background:radial-gradient(circle at 84% 8%,rgba(159,106,61,.18),transparent 34%),radial-gradient(circle at 8% 42%,rgba(80,106,120,.14),transparent 32%),linear-gradient(135deg,#f8f2e7 0%,var(--paper) 52%,#e9dfcf 100%);overflow-x:hidden}body:before{content:"";position:fixed;inset:0;pointer-events:none;opacity:.28;background-image:linear-gradient(rgba(32,29,24,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(32,29,24,.035) 1px,transparent 1px);background-size:42px 42px;mask-image:linear-gradient(to bottom,black,transparent 90%)}
.shell{width:min(1480px,calc(100% - 36px));margin:0 auto;padding:34px 0 70px}.topbar{display:flex;justify-content:space-between;gap:18px;align-items:center;margin-bottom:30px}.brand{display:flex;gap:12px;align-items:center}.mark{width:42px;height:42px;border-radius:14px;background:var(--ink);color:var(--paper);display:grid;place-items:center;font-family:var(--mono);font-size:12px;letter-spacing:.08em;box-shadow:var(--shadow)}.brand strong{display:block;font-size:14px;letter-spacing:.08em;text-transform:uppercase}.brand span{color:var(--muted);font-size:12px}.status{border:1px solid var(--line);background:rgba(255,255,255,.45);border-radius:999px;padding:8px 12px;font-family:var(--mono);font-size:12px;color:var(--accent-dark)}
.hero{display:grid;grid-template-columns:1.05fr .95fr;gap:26px;align-items:stretch;margin-bottom:26px}.hero-main,.hero-side,.panel,.role-wizard{border:1px solid rgba(138,119,91,.28);background:var(--panel);backdrop-filter:blur(18px);border-radius:var(--radius);box-shadow:var(--shadow)}.hero-main{padding:clamp(28px,5vw,58px);min-height:360px;position:relative;overflow:hidden}.hero-main:after{content:"";position:absolute;width:360px;height:360px;border-radius:50%;right:-120px;top:-110px;border:1px solid rgba(159,106,61,.25);background:radial-gradient(circle,rgba(159,106,61,.12),transparent 65%)}.eyebrow{font-family:var(--mono);color:var(--accent-dark);font-size:12px;text-transform:uppercase;letter-spacing:.14em;margin-bottom:18px}h1{font-size:clamp(40px,6vw,82px);line-height:.92;letter-spacing:-.07em;margin:0 0 22px;max-width:980px}.lead{font-size:clamp(17px,2vw,22px);color:#5c5347;line-height:1.45;max-width:840px;margin:0}.hero-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:34px}.btn{display:inline-flex;align-items:center;gap:10px;border:1px solid var(--ink);background:var(--ink);color:var(--paper);border-radius:999px;padding:12px 16px;text-decoration:none;font-weight:700;font-size:13px}.btn.secondary{background:transparent;color:var(--ink);border-color:var(--line)}.hero-side{padding:24px;display:grid;align-content:space-between;gap:18px}.metric{padding:18px;border-radius:22px;background:rgba(255,250,240,.72);border:1px solid rgba(216,208,194,.7)}.metric b{display:block;font-size:30px;letter-spacing:-.05em}.metric span{color:var(--muted);font-size:13px;line-height:1.35}
.section-title{display:flex;justify-content:space-between;align-items:end;gap:16px;margin:34px 0 16px}.section-title h2{font-size:clamp(26px,4vw,48px);letter-spacing:-.05em;margin:0}.section-title p{color:var(--muted);max-width:650px;margin:0;line-height:1.45}.role-list{display:grid;gap:14px}.role-wizard{padding:18px}.role-head{display:flex;justify-content:space-between;gap:14px;align-items:center;margin-bottom:14px}.role-head h3{font-size:26px;letter-spacing:-.05em;margin:0}.role-head span{font-family:var(--mono);font-size:12px;color:var(--accent-dark)}.wizard-steps{display:grid;grid-template-columns:repeat(6,minmax(176px,1fr));gap:12px;overflow-x:auto;padding-bottom:4px}.wizard-step{min-height:178px;border-radius:24px;padding:16px;border:1px solid var(--line);background:var(--panel-strong);position:relative}.wizard-step:after{content:"->";position:absolute;right:-12px;top:22px;font-family:var(--mono);color:var(--accent);background:var(--paper);border:1px solid var(--line);border-radius:999px;padding:2px 5px;font-size:11px}.wizard-step:last-child:after{display:none}.wizard-step b{display:block;font-family:var(--mono);font-size:11px;color:var(--accent-dark);margin-bottom:14px}.wizard-step h3{font-size:17px;line-height:1.05;letter-spacing:-.035em;margin:0 0 10px}.wizard-step p{color:var(--muted);font-size:13px;line-height:1.35;margin:0}.evidence{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.evidence-card{border:1px solid var(--line);border-radius:20px;background:rgba(255,255,255,.5);padding:14px;color:#5a5145;font-size:13px;line-height:1.35}.footer{color:var(--muted);font-size:12px;margin-top:38px;font-family:var(--mono)}@media(max-width:1050px){.hero,.evidence{grid-template-columns:1fr}.wizard-steps{grid-template-columns:repeat(6,minmax(230px,1fr))}}
</style>
</head>
<body>
HTML_HEAD
        printf '<main class="shell"><div class="topbar"><div class="brand"><div class="mark">Attio Venture</div><div><strong>%s</strong><span>demo and training wizard</span></div></div><div class="status">role wizard · %s · %s</div></div>\n' "$(printf "%s" "$title" | html_escape)" "$(printf "%s" "$slug" | html_escape)" "$(printf "%s" "$now" | html_escape)"
        printf '<section class="hero"><div class="hero-main"><div class="eyebrow">demo · training · go live</div><h1>%s user flow graph</h1><p class="lead">A role-by-role wizard for demos, training, and go-live readiness. Each role has a six-step walkthrough: enter the workspace, review assigned work, open a real record, perform the action, verify evidence, and hand off the next step.</p><div class="hero-actions"><a class="btn" href="#roles">View role wizards</a><a class="btn secondary" href="data-flow-graph.html">Data flow</a><a class="btn secondary" href="complete-workflow-graph.html">Complete workflow</a></div></div><aside class="hero-side"><div class="metric"><b>Role</b><span>Each lane is written as what that user should do during a live walkthrough.</span></div><div class="metric"><b>Steps</b><span>Steppers are ordered for training and go-live, not just source-code evidence.</span></div><div class="metric"><b>Proof</b><span>Every role ends by showing the evidence, logs, reports, or next handoff.</span></div></aside></section>\n' "$(printf "%s" "$title" | html_escape)"
        printf '<section id="roles"><div class="section-title"><h2>Role demo wizards</h2><p>Use these steppers as the script for training users or presenting the app before go-live.</p></div><div class="role-list">\n'
        if [ -n "$roles" ]; then
            printf "%s\n" "$roles" | sed -n '1,8p' | while IFS= read -r role; do
                [ -n "$role" ] || continue
                printf '<section class="role-wizard"><div class="role-head"><h3>%s</h3><span>go-live walkthrough</span></div>\n' "$(printf "%s" "$role" | html_escape)"
                write_role_wizard_steps "$role"
                printf '</section>\n'
            done
        else
            printf '<section class="role-wizard"><div class="role-head"><h3>Primary User</h3><span>go-live walkthrough</span></div>\n'
            write_role_wizard_steps "Primary User"
            printf '</section>\n'
        fi
        printf '</div></section><section><div class="section-title"><h2>Supporting evidence</h2><p>Quick links inferred from the repository to help trainers find the relevant screens, routes, and tests.</p></div><div class="evidence">\n'
        printf '<article class="evidence-card"><b>Routes</b><br>%s</article>\n' "$(printf "%s" "$routes" | sed -n '1,8p' | html_escape | awk '{printf "%s<br>", $0}')"
        printf '<article class="evidence-card"><b>Screens</b><br>%s</article>\n' "$(printf "%s" "$screens" | sed -n '1,8p' | html_escape | awk '{printf "%s<br>", $0}')"
        printf '<article class="evidence-card"><b>Tests and guides</b><br>%s</article>\n' "$(printf "%s" "$tests" | sed -n '1,8p' | html_escape | awk '{printf "%s<br>", $0}')"
        printf '</div></section><div class="footer">Generated by /larv:presentation · user role wizard artifact</div></main></body></html>\n'
    } > "$out"
}

build_visual_graphs() {
    local dir="$1" out_dir="$2" title="$3" slug="$4" focus="$5" roles="$6" workflows="$7" routes="$8" models="$9" docs="${10}" tests="${11}" screens="${12}" now="${13}"
    local graph_dir data_logic user_entry user_actions complete_runtime core_tables edge_rows raw_edge_rows role_names model_map write_rows
    graph_dir="$out_dir/visual-workflow"
    mkdir -p "$graph_dir"
    data_logic="$(collect_matches "$dir" '(controller|request|validate|policy|service|job|event|listener|queue|audit|log|state|transition|business rule|invariant)' '')"
    role_names="$(collect_role_names "$dir")"
    user_entry="${role_names:-$roles}"
    user_actions="$workflows"
    complete_runtime="$routes"
    core_tables="$(collect_core_tables "$dir")"
    raw_edge_rows="$(collect_table_edges "$dir" | sort -u | sed -n '1,80p')"
    edge_rows="$(filter_core_edges "$raw_edge_rows" "$core_tables" | sort -u | sed -n '1,80p')"
    model_map="$(collect_model_table_map "$dir")"
    write_rows="$(collect_data_write_flows "$dir" "$core_tables" "$model_map" | sort -u | sed -n '1,80p')"

    write_database_flow_page "$graph_dir/data-flow-graph.html" \
        "$title" "$slug" "$routes" "$core_tables" "$edge_rows" "$write_rows" "$now"

    write_user_wizard_page "$graph_dir/user-flow-graph.html" \
        "$title" "$slug" "$user_entry" "$routes" "$screens" "$tests" "$now"

    write_visual_graph_page "$graph_dir/complete-workflow-graph.html" \
        "$title complete workflow graph" \
        "Complete go-live visual workflow: role steppers, runtime entry points, data changes, design/mockup surfaces, and verification evidence for demos, training, and launch review." \
        "go-live workflow graph · $slug · $now" "" \
        "Role Demo Steps" "$user_entry" \
        "Runtime Flow" "$complete_runtime" \
        "Screens and Evidence" "$(printf "%s\n%s\n%s" "$screens" "$docs" "$tests")"

    write_visual_graph_page "$graph_dir/index.html" \
        "$title visual workflow graphs" \
        "Presentation hub generated by /larv:presentation. Open the data flow graph for database and logic, user flow graph for role journeys, or complete workflow graph for the current visual workflow." \
        "visual graph hub · $slug · $now" "" \
        "Data Flow Graph" "Core business tables, models, migrations, controllers, requests, policies, relationships, and report outputs." \
        "User Flow Graph" "Roles, personas, screens, routes, seeded users, testing guides, and user-visible paths." \
        "Complete Workflow Graph" "The current complete visual workflow tying user action, system logic, data persistence, mockups, and verification together."
}

build_html() {
    local dir="$1" focus="${2:-}" out_dir out title slug now files roles workflows routes models docs tests screens mode headline summary evidence_a evidence_b evidence_c evidence_d step1 step2 step3 step4
    dir="$(project_root "$dir")"
    mode="$(focus_mode "$focus")"
    out_dir="$(presentation_dir "$dir")"
    mkdir -p "$out_dir"
    out="$out_dir/index.html"
    title="$(project_name "$dir")"
    slug="$(project_slug "$dir")"
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    files="$(list_files "$dir" | sed -n '1,80p')"
    roles="$(collect_matches "$dir" '(^|[^a-z])(role|persona|actor|admin|owner|manager|member|customer|user|guest|ceo|operator|approver|reviewer|agent)([^a-z]|$)' '-g "*.md" -g "*.php" -g "*.tsx" -g "*.jsx" -g "*.vue"')"
    workflows="$(collect_matches "$dir" '(workflow|flow|journey|step|navigate|sign in|login|approve|review|create|submit|dashboard|meeting|onboarding|handoff)' '-g "*.md" -g "*.feature" -g "*.php" -g "*.tsx" -g "*.jsx" -g "*.vue"')"
    routes="$(collect_routes "$dir")"
    models="$(collect_models "$dir")"
    docs="$(list_files "$dir" | grep -E '(^DOCS\.md$|^README\.md$|^docs/|^adr/)' | sed -n '1,26p' || true)"
    tests="$(list_files "$dir" | grep -E '(^tests/|^cypress/|^e2e/|playwright|pest|phpunit)' | sed -n '1,26p' || true)"
    screens="$(list_files "$dir" | grep -E '(resources/views|resources/js|app/Filament|routes/web.php|docs/larv/03-design/mockups)' | sed -n '1,30p' || true)"
    headline="$(focus_title "$mode" "$focus")"
    summary="$(focus_summary "$mode")"
    case "$mode" in
        skills)
            evidence_a="$(collect_skill_names "$dir")"
            evidence_b="$(collect_matches "$dir" '(/larv:|Phase [0-9]|sandbox|presentation|orchestrator|handoff|verify|deploy|learn)' "")"
            evidence_c="$(list_files "$dir" | grep -E '^(scripts|tests|templates)/' | sed -n '1,40p' || true)"
            evidence_d="$(collect_skills "$dir")"
            step1="Command Entry"; step2="Skill Dispatch"; step3="Scripts and Gates"; step4="Installed Runtime"
            ;;
        dataflow)
            evidence_a="$(collect_dataflow "$dir" "$focus")"
            evidence_b="$models"
            evidence_c="$routes"
            evidence_d="$tests"
            step1="Input"; step2="Validation"; step3="Persistence"; step4="Output"
            ;;
        feature)
            evidence_a="$(collect_feature_focus "$dir" "$focus")"
            evidence_b="$screens"
            evidence_c="$routes"
            evidence_d="$tests"
            step1="User Intent"; step2="Screen Flow"; step3="Domain Change"; step4="Verification"
            ;;
        *)
            evidence_a="$roles"
            evidence_b="$workflows"
            evidence_c="$routes"
            evidence_d="$models"
            step1="Entry"; step2="Role Action"; step3="Review"; step4="Outcome"
            ;;
    esac

    {
        cat <<'HTML_HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>larv visual workflow</title>
<style>
:root{--ink:#18202a;--muted:#6f7782;--line:#e3e7ec;--paper:#f7f8f6;--panel:#fff;--brand:#1b5e7f;--gold:#faa000;--green:#287a4b;--radius:8px;--shadow:0 18px 48px rgba(19,27,38,.08)}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:14px/1.45 Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;letter-spacing:0}
.shell{display:grid;grid-template-columns:280px 1fr;min-height:100vh}.side{background:#102d42;color:#eaf2f6;padding:28px 20px;position:sticky;top:0;height:100vh}.brand{display:flex;gap:12px;align-items:center;margin-bottom:32px}.mark{width:38px;height:38px;border-radius:8px;background:linear-gradient(135deg,var(--gold),#ffe2a0);display:grid;place-items:center;color:#102d42;font-weight:800}.brand h1{font-size:17px;margin:0}.brand p{margin:2px 0 0;color:#aac2cf;font-size:12px}.nav{display:grid;gap:8px}.nav a{color:#d9e7ee;text-decoration:none;padding:9px 10px;border:1px solid rgba(255,255,255,.08);border-radius:8px}.main{padding:28px 34px 44px}.hero{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:24px;align-items:end;border-bottom:1px solid var(--line);padding-bottom:24px;margin-bottom:24px}.eyebrow{color:var(--brand);font-size:12px;text-transform:uppercase;font-weight:760;letter-spacing:.08em}.hero h2{font-size:34px;line-height:1.08;margin:8px 0 10px;max-width:900px}.hero p{color:var(--muted);margin:0;max-width:780px}.meta{display:grid;gap:8px;min-width:250px}.chip{background:var(--panel);border:1px solid var(--line);border-radius:999px;padding:8px 12px;color:#46515d;box-shadow:0 1px 0 rgba(0,0,0,.02)}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.panel{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden}.panel-head{display:flex;justify-content:space-between;gap:12px;align-items:center;padding:14px 16px;border-bottom:1px solid var(--line);font-weight:780}.list{list-style:none;margin:0;padding:8px 0}.list li{padding:9px 16px;border-bottom:1px solid #f0f2f5;color:#303943}.list li:last-child{border-bottom:0}.workflow{display:grid;grid-template-columns:repeat(4,minmax(180px,1fr));gap:12px;margin:16px 0}.step{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);padding:14px;min-height:128px}.step b{display:block;color:var(--brand);margin-bottom:8px}.step span{color:var(--muted)}.wide{grid-column:1/-1}.files{columns:2;column-gap:22px}.footer{margin-top:20px;color:var(--muted);font-size:12px}@media(max-width:900px){.shell{grid-template-columns:1fr}.side{position:relative;height:auto}.hero{grid-template-columns:1fr}.grid,.workflow{grid-template-columns:1fr}.files{columns:1}}
</style>
</head>
<body>
HTML_HEAD
        printf '<div class="shell"><aside class="side"><div class="brand"><div class="mark">L</div><div><h1>%s</h1><p>%s</p></div></div><nav class="nav"><a href="#roles">Signals</a><a href="#workflow">Flow</a><a href="#screens">Screens</a><a href="#evidence">Repo Evidence</a></nav></aside><main class="main">\n' "$(printf "%s" "$title" | html_escape)" "$(printf "%s" "$headline" | html_escape)"
        printf '<section class="hero"><div><div class="eyebrow">larv presentation · %s</div><h2>%s</h2><p>%s</p></div><div class="meta"><div class="chip">Project: %s</div><div class="chip">Focus: %s</div><div class="chip">Generated: %s</div><div class="chip">Design: HTML Effectiveness / Attio-style app shell</div></div></section>\n' "$(printf "%s" "$mode" | html_escape)" "$(printf "%s — %s" "$title" "$headline" | html_escape)" "$(printf "%s" "$summary" | html_escape)" "$(printf "%s" "$slug" | html_escape)" "$(printf "%s" "${focus:-whole repo}" | html_escape)" "$now"
        printf '<section id="workflow" class="workflow"><div class="step"><b>1. %s</b><span>Start from the strongest matching repo signals for this focus.</span></div><div class="step"><b>2. %s</b><span>Connect docs and code paths into the visible user or system flow.</span></div><div class="step"><b>3. %s</b><span>Show the implementation surfaces, runtime gates, or state transitions.</span></div><div class="step"><b>4. %s</b><span>End with tests, guides, probes, or review artifacts that prove the flow works.</span></div></section>\n' "$(printf "%s" "$step1" | html_escape)" "$(printf "%s" "$step2" | html_escape)" "$(printf "%s" "$step3" | html_escape)" "$(printf "%s" "$step4" | html_escape)"
        printf '<div class="grid">\n'
        case "$mode" in
            skills)
                write_list_items "Commands and Skills" "$evidence_a"
                write_list_items "Workflow Signals" "$evidence_b"
                write_list_items "Scripts, Tests, and Templates" "$evidence_c"
                write_list_items "Skill Source Files" "$evidence_d"
                ;;
            dataflow)
                write_list_items "Dataflow Signals" "$evidence_a"
                write_list_items "Models and Tables" "$evidence_b"
                write_list_items "Routes and Entry Points" "$evidence_c"
                write_list_items "Verification" "$evidence_d"
                ;;
            feature)
                write_list_items "Feature Signals" "$evidence_a"
                write_list_items "Screens and UI" "$evidence_b"
                write_list_items "Routes and Entry Points" "$evidence_c"
                write_list_items "Tests and Acceptance" "$evidence_d"
                ;;
            *)
                write_list_items "Roles and Personas" "$evidence_a"
                write_list_items "Primary Workflows" "$evidence_b"
                write_list_items "Routes" "$evidence_c"
                write_list_items "Models and Data" "$evidence_d"
                ;;
        esac
        write_list_items "Screens and Mockup Sources" "$screens"
        write_list_items "Tests and Verification" "$tests"
        printf '<section id="evidence" class="panel wide"><div class="panel-head"><span>Documentation Evidence</span></div><ul class="list files">\n'
        if [ -n "$docs" ]; then
            printf "%s\n" "$docs" | sed -n '1,40p' | while IFS= read -r line; do
                printf '<li>%s</li>\n' "$(printf "%s" "$line" | html_escape)"
            done
        else
            printf '<li>No docs found. Add README, DOCS.md, docs/larv, or docs/user-manual to improve this presentation.</li>\n'
        fi
        printf '</ul></section>\n'
        printf '<section class="panel wide"><div class="panel-head"><span>Scanned Files</span></div><ul class="list files">\n'
        printf "%s\n" "$files" | sed -n '1,80p' | while IFS= read -r line; do
            printf '<li>%s</li>\n' "$(printf "%s" "$line" | html_escape)"
        done
        printf '</ul></section></div><p class="footer">Generated by /larv:presentation. Source artifact: %s</p></main></div></body></html>\n' "$(printf "%s" "${out#$dir/}" | html_escape)"
    } > "$out"
    build_visual_graphs "$dir" "$out_dir" "$title" "$slug" "$focus" "$roles" "$workflows" "$routes" "$models" "$docs" "$tests" "$screens" "$now"
    echo "$out"
}

port_from_url() {
    local url="$1"
    [ -n "$url" ] || return 0
    sed -E 's#^https?://[^:/]+:([0-9]+).*$#\1#' <<<"$url"
}

port_in_presentation_range() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 2000 ] && [ "$port" -le 2999 ]
}

recorded_url() {
    local dir="$1" file
    file="$(presentation_url_file "$dir")"
    [ -s "$file" ] && head -1 "$file" | tr -d '[:space:]'
    return 0
}

presentation_session() {
    local slug="$1" port="$2"
    echo "larv-presentation-$slug-$port"
}

choose_port() {
    local dir="$1" slug="$2" requested="${LARV_PRESENTATION_PORT:-}" recorded port owner
    owner="$slug:$(project_root "$dir"):presentation"
    if [ -n "$requested" ]; then
        port_in_presentation_range "$requested" || {
            echo "ERROR: LARV_PRESENTATION_PORT must be in 2000-2999." >&2
            return 1
        }
        verify_allocation "$requested" presentation "$owner" || {
            echo "ERROR: requested presentation port $requested is already in use. Pick a different 2000-2999 port." >&2
            return 1
        }
        echo "$requested"
        return
    fi
    recorded="$(recorded_url "$dir")"
    port="$(port_from_url "$recorded")"
    if port_in_presentation_range "$port" && verify_allocation "$port" presentation "$owner"; then
        echo "$port"
        return
    fi
    allocate_port presentation "$owner"
}

open_firewall_if_possible() {
    local port="$1"
    if command -v ufw >/dev/null; then
        sudo ufw allow "$port/tcp" >/dev/null || true
    fi
}

presentation_start() {
    local dir="$1" focus="${2:-}" slug out_dir port url session old_url old_port old_session url_file
    dir="$(project_root "$dir")"
    slug="$(project_slug "$dir")"
    build_html "$dir" "$focus" >/dev/null
    out_dir="$(presentation_dir "$dir")"
    old_url="$(recorded_url "$dir")"
    old_port="$(port_from_url "$old_url")"
    port="$(choose_port "$dir" "$slug")"
    if port_in_presentation_range "$old_port" && [ "$old_port" != "$port" ]; then
        old_session="$(presentation_session "$slug" "$old_port")"
        static_server_stop "" "$old_session" 2>/dev/null || true
    fi
    session="$(presentation_session "$slug" "$port")"
    url="$(static_server_url "$port")/"
    open_firewall_if_possible "$port"
    static_server_start "" "$port" "$out_dir" "$session"
    probe_url_inside "" "$port" static
    probe_with_retries "$url" static >/dev/null
    release_port_reservation presentation "$port" "$slug:$(project_root "$dir"):presentation" || true
    url_file="$(presentation_url_file "$dir")"
    mkdir -p "$(dirname "$url_file")"
    printf "%s\n" "$url" > "$url_file"
    echo "Presentation ready at $url"
    echo "Source: ${out_dir#$dir/}/index.html"
}

presentation_info() {
    local dir="$1" url
    url="$(recorded_url "$dir")"
    if [ -n "$url" ]; then
        echo "Presentation URL: $url"
        echo "Artifact: $(presentation_dir "$(project_root "$dir")")/index.html"
        return
    fi
    echo "No presentation URL recorded yet. Run /larv:presentation."
    return 1
}

presentation_stop() {
    local dir="$1" slug url port session
    dir="$(project_root "$dir")"
    slug="$(project_slug "$dir")"
    url="$(recorded_url "$dir")"
    port="$(port_from_url "$url")"
    if port_in_presentation_range "$port"; then
        session="$(presentation_session "$slug" "$port")"
        static_server_stop "" "$session" 2>/dev/null || true
    fi
    echo "Stopped larv presentation for $slug."
}

main() {
    [ "$#" -ge 2 ] || usage
    local dir="$1" command="$2" focus=""
    shift 2
    focus="$*"
    [ -d "$dir" ] || { echo "ERROR: not a directory: $dir" >&2; exit 1; }
    case "$command" in
        build) build_html "$dir" "$focus" ;;
        start) presentation_start "$dir" "$focus" ;;
        info) presentation_info "$dir" ;;
        stop) presentation_stop "$dir" ;;
        *) usage ;;
    esac
}

main "$@"
