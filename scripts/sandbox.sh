#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PLUGIN_ROOT/scripts/lib/vm.sh"
source "$PLUGIN_ROOT/scripts/lib/probe.sh"
source "$PLUGIN_ROOT/scripts/lib/static_server.sh"
source "$PLUGIN_ROOT/scripts/lib/verifier.sh"

usage() {
    cat >&2 <<'EOF'
Usage: sandbox.sh <project-dir> <info|start|stop|reset>

Commands:
  info   Show app/docs/mockup URLs, probe status, seeded credentials, and testing guides.
  start  Start/restart the app sandbox and static docs/mockup servers for this project.
         Unsafe or foreign-owned recorded ports are reallocated before start.
  stop   Stop app/docs/mockup sessions owned by this project.
  reset  Run migrate:fresh --seed, restart the app sandbox, and show sandbox info.
EOF
    exit 64
}

require_project() {
    local dir="$1"
    [ -f "$dir/docs/larv/STATE.yaml" ] || {
        echo "ERROR: no docs/larv/STATE.yaml in $dir" >&2
        exit 1
    }
}

read_yq() {
    local expr="$1" file="$2"
    yq -r "$expr" "$file" 2>/dev/null || true
}

project_slug() {
    local dir="$1"
    local slug
    slug="$(read_yq '.project.slug // ""' "$dir/docs/larv/STATE.yaml")"
    [ -n "$slug" ] && [ "$slug" != "null" ] && printf "%s\n" "$slug" || basename "$dir"
}

project_name() {
    local dir="$1"
    local name
    name="$(read_yq '.project.name // .project.slug // ""' "$dir/docs/larv/STATE.yaml")"
    [ -n "$name" ] && [ "$name" != "null" ] && printf "%s\n" "$name" || basename "$dir"
}

url_file() {
    local dir="$1" kind="$2"
    case "$kind" in
        app)     echo "$dir/docs/larv/07-runtime/sandbox-url.txt" ;;
        docs)    echo "$dir/docs/larv/docsite-url.txt" ;;
        mockups) echo "$dir/docs/larv/03-design/mockup-url.txt" ;;
        *) return 1 ;;
    esac
}

url_for() {
    local dir="$1" kind="$2" file
    file="$(url_file "$dir" "$kind")"
    if [ -s "$file" ]; then
        head -1 "$file" | tr -d '[:space:]'
        return
    fi
    if [ "$kind" = "app" ]; then
        local from_state
        from_state="$(read_yq '.sandbox.app_url // ""' "$dir/docs/larv/STATE.yaml")"
        [ -n "$from_state" ] && [ "$from_state" != "null" ] && printf "%s\n" "$from_state"
    fi
}

port_from_url() {
    local url="$1"
    [ -n "$url" ] || return 0
    sed -E 's#^https?://[^:/]+:([0-9]+).*$#\1#' <<<"$url"
}

port_role_for_kind() {
    case "$1" in
        app) echo "app" ;;
        docs) echo "docsite" ;;
        mockups) echo "mockup" ;;
        *) return 1 ;;
    esac
}

session_for() {
    local kind="$1" slug="$2" port="$3"
    case "$kind" in
        app) echo "larv-app-$slug-$port" ;;
        docs) echo "larv-docsite-$slug-$port" ;;
        mockups) echo "larv-mockups-$slug-$port" ;;
        *) return 1 ;;
    esac
}

owner_base() {
    echo "${LARV_SANDBOX_OWNER_DIR:-/tmp/larv-sandbox-owners}"
}

owner_file() {
    local kind="$1" port="$2" base
    base="$(owner_base)"
    mkdir -p "$base/$kind"
    echo "$base/$kind/$port"
}

write_owner() {
    local dir="$1" kind="$2" port="$3" session="$4" file
    file="$(owner_file "$kind" "$port")"
    {
        printf "slug=%s\n" "$(project_slug "$dir")"
        printf "root=%s\n" "$(cd "$dir" && pwd -P)"
        printf "kind=%s\n" "$kind"
        printf "port=%s\n" "$port"
        printf "session=%s\n" "$session"
        printf "updated_at=%s\n" "$(date +%s)"
    } > "$file"
}

remove_owner() {
    local kind="$1" port="$2" file
    [ -n "$port" ] || return 0
    file="$(owner_file "$kind" "$port")"
    rm -f "$file"
}

owner_value() {
    local file="$1" key="$2"
    awk -F= -v key="$key" '$1 == key {print $2}' "$file" 2>/dev/null | head -1
}

port_owned_by_project() {
    local dir="$1" kind="$2" port="$3" file root
    [ -n "$port" ] || return 1
    file="$(owner_file "$kind" "$port")"
    [ -f "$file" ] || return 1
    root="$(cd "$dir" && pwd -P)"
    [ "$(owner_value "$file" slug)" = "$(project_slug "$dir")" ] && [ "$(owner_value "$file" root)" = "$root" ]
}

port_is_listening() {
    local port="$1" listening
    [ -n "$port" ] || return 1
    listening="$(verifier_run "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un || true)"
    grep -qx "$port" <<<"$listening"
}

tmux_session_exists() {
    local session="$1"
    command -v tmux >/dev/null && tmux has-session -t "$session" >/dev/null 2>&1
}

detect_app_session() {
    local slug="$1" port="$2" preferred legacy
    preferred="$(session_for app "$slug" "$port")"
    legacy="larv-app-$port"
    if tmux_session_exists "$preferred"; then
        echo "$preferred"
        return
    fi
    if tmux_session_exists "$legacy"; then
        echo "$legacy"
        return
    fi
    echo "$preferred"
}

stop_owned_session() {
    local dir="$1" kind="$2" port="$3" file session
    [ -n "$port" ] || return 0
    if ! port_owned_by_project "$dir" "$kind" "$port"; then
        return 0
    fi
    file="$(owner_file "$kind" "$port")"
    session="$(owner_value "$file" session)"
    [ -n "$session" ] || session="$(session_for "$kind" "$(project_slug "$dir")" "$port")"
    tmux kill-session -t "$session" 2>/dev/null || true
    remove_owner "$kind" "$port"
}

write_url() {
    local dir="$1" kind="$2" url="$3" file
    file="$(url_file "$dir" "$kind")"
    mkdir -p "$(dirname "$file")"
    printf "%s\n" "$url" > "$file"
    if [ "$kind" = "app" ] && command -v yq >/dev/null; then
        APP_URL_VALUE="$url" yq -i '.sandbox.app_url = strenv(APP_URL_VALUE)' "$dir/docs/larv/STATE.yaml" 2>/dev/null || true
    fi
}

record_allocation_if_possible() {
    local dir="$1" kind="$2" port="$3" allocation_kind
    case "$kind" in
        app) allocation_kind="app-port" ;;
        docs) allocation_kind="docsite-port" ;;
        mockups) allocation_kind="mockup-port" ;;
        *) return 0 ;;
    esac
    bash "$PLUGIN_ROOT/scripts/state.sh" record-allocation "$dir" "$allocation_kind" "$port" >/dev/null 2>&1 || true
}

safe_port_for_kind() {
    local dir="$1" kind="$2" preferred="${3:-}" slug role port url owner
    slug="$(project_slug "$dir")"
    role="$(port_role_for_kind "$kind")"
    owner="$slug:$(cd "$dir" && pwd -P):$kind"

    if [ -n "$preferred" ] && [[ "$preferred" =~ ^[0-9]+$ ]]; then
        if port_owned_by_project "$dir" "$kind" "$preferred"; then
            echo "$preferred"
            return 0
        fi
        if ! port_is_listening "$preferred" && verify_allocation "$preferred" "$role" "$owner"; then
            echo "$preferred"
            return 0
        fi
        echo "WARN: recorded $kind port $preferred is already in use or owned by another project; allocating a new port." >&2
    fi

    port="$(allocate_port "$role" "$owner")"
    url="$(static_server_url "$port")/"
    write_url "$dir" "$kind" "$url"
    record_allocation_if_possible "$dir" "$kind" "$port"
    echo "$port"
}

status_for_url() {
    local url="$1" profile="${2:-static}"
    if [ -z "$url" ]; then
        echo "missing"
        return 2
    fi
    if probe_url "$url" "$profile" >/dev/null 2>&1; then
        echo "ready"
        return 0
    fi
    echo "down"
    return 1
}

show_url_line() {
    local dir="$1" label="$2" kind="$3" profile="$4" url status
    url="$(url_for "$dir" "$kind")"
    status="$(status_for_url "$url" "$profile" || true)"
    if [ -n "$url" ]; then
        printf "%-8s %s [%s]\n" "$label:" "$url" "$status"
    else
        printf "%-8s %s\n" "$label:" "(not generated yet)"
    fi
    [ "$status" = "ready" ] || [ "$status" = "missing" ]
}

seed_guide_excerpt() {
    local dir="$1" file="$dir/docs/user-manual/seed-data.md"
    echo
    echo "Seeded users and credentials"
    echo "----------------------------"
    if [ ! -s "$file" ]; then
        echo "(missing: docs/user-manual/seed-data.md)"
        return
    fi
    echo "Source: docs/user-manual/seed-data.md"
    awk '
        BEGIN { shown=0 }
        /^## / && shown && $0 !~ /Test Credentials|Demo Credentials|Seed|Feature Seed Inventory/ { exit }
        /Test Credentials|Demo Credentials|Seeded|Credentials|Role|Email|Username|Password|Permissions|Purpose|Recommended flow/ { shown=1 }
        shown { print }
    ' "$file" | sed -n '1,120p'
}

testing_guides_excerpt() {
    local dir="$1" guide_dir="$dir/docs/user-manual/testing"
    echo
    echo "Browser testing guides"
    echo "----------------------"
    if [ ! -d "$guide_dir" ]; then
        echo "(missing: docs/user-manual/testing/)"
        return
    fi
    local found=0 guide
    while IFS= read -r guide; do
        found=1
        printf "\n%s\n" "${guide#$dir/}"
        grep -E '^(#|##|###|[-*] (What can be tested|Flow|Test|Navigate|Sign in|Expected|URL|Credentials))' "$guide" | sed -n '1,35p' || true
    done < <(find "$guide_dir" -maxdepth 1 -type f -name '*.md' | sort)
    [ "$found" -eq 1 ] || echo "(no per-slice testing guides yet)"
}

runtime_report() {
    local dir="$1" failures=0
    require_project "$dir"
    echo "Larv sandbox for $(project_name "$dir") ($(project_slug "$dir"))"
    echo
    echo "URLs"
    echo "----"
    show_url_line "$dir" "App" "app" "laravel" || failures=$((failures + 1))
    show_url_line "$dir" "Docs" "docs" "static" || failures=$((failures + 1))
    show_url_line "$dir" "Mockups" "mockups" "static" || failures=$((failures + 1))
    seed_guide_excerpt "$dir"
    testing_guides_excerpt "$dir"
    echo
    echo "Verification"
    echo "------------"
    if [ "$failures" -eq 0 ]; then
        echo "All generated URLs are reachable."
        return 0
    fi
    echo "$failures generated URL(s) are not reachable. Run /larv:sandbox-start from this project to restart them."
    return 1
}

open_firewall_if_possible() {
    local port="$1"
    if command -v ufw >/dev/null; then
        sudo ufw allow "$port/tcp" >/dev/null || true
    fi
}

stage_docsite() {
    local dir="$1" slug="$2" root="/tmp/larv-$slug-docsite"
    rm -rf "$root"
    mkdir -p "$root"
    if command -v rsync >/dev/null; then
        rsync -a "$dir/docs/larv/" "$root/"
        [ -f "$dir/docs/Handsoff.md" ] && rsync -a "$dir/docs/Handsoff.md" "$root/Handsoff.md"
        [ -d "$dir/docs/Handsoff" ] && rsync -a "$dir/docs/Handsoff/" "$root/Handsoff/"
        [ -d "$dir/docs/user-manual" ] && rsync -a "$dir/docs/user-manual/" "$root/user-manual/"
        [ -f "$dir/DOCS.md" ] && rsync -a "$dir/DOCS.md" "$root/DOCS.md"
    else
        cp -R "$dir/docs/larv/." "$root/"
        [ -f "$dir/docs/Handsoff.md" ] && cp "$dir/docs/Handsoff.md" "$root/Handsoff.md"
        if [ -d "$dir/docs/Handsoff" ]; then mkdir -p "$root/Handsoff"; cp -R "$dir/docs/Handsoff/." "$root/Handsoff/"; fi
        if [ -d "$dir/docs/user-manual" ]; then mkdir -p "$root/user-manual"; cp -R "$dir/docs/user-manual/." "$root/user-manual/"; fi
        [ -f "$dir/DOCS.md" ] && cp "$dir/DOCS.md" "$root/DOCS.md"
    fi
    cat > "$root/README.md" <<EOF
# $(project_name "$dir")

This doc-site is generated by larv for browser review.

- [State](STATE.yaml)
- [Handoff](Handsoff.md)
- [Seed data](user-manual/seed-data.md)
- [Testing guides](user-manual/testing/)
EOF
    cat > "$root/index.html" <<'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>larv docs</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css">
</head><body><div id="app">Loading documentation...</div>
<script>window.$docsify={name:'larv docs',homepage:'README.md',loadSidebar:true,subMaxLevel:2,search:'auto'};</script>
<script src="https://cdn.jsdelivr.net/npm/docsify@4"></script>
<script src="https://cdn.jsdelivr.net/npm/docsify@4/lib/plugins/search.min.js"></script>
</body></html>
HTML
    echo "$root"
}

start_static_kind() {
    local dir="$1" kind="$2" slug="$3" root session url port file
    url="$(url_for "$dir" "$kind")"
    if [ -z "$url" ] && [ "$kind" = "docs" ]; then
        port="$(safe_port_for_kind "$dir" "$kind" "")"
        url="$(static_server_url "$port")/"
    elif [ -z "$url" ] && [ "$kind" = "mockups" ] && [ -d "$dir/docs/larv/03-design/mockups" ]; then
        port="$(safe_port_for_kind "$dir" "$kind" "")"
        url="$(static_server_url "$port")/"
    fi
    [ -n "$url" ] || return 0
    port="$(port_from_url "$url")"
    port="$(safe_port_for_kind "$dir" "$kind" "$port")"
    [ -n "$port" ] && [[ "$port" =~ ^[0-9]+$ ]] || return 0
    url="$(static_server_url "$port")/"
    case "$kind" in
        docs)
            root="$(stage_docsite "$dir" "$slug")"
            session="$(session_for "$kind" "$slug" "$port")"
            ;;
        mockups)
            root="$dir/docs/larv/03-design/mockups"
            [ -d "$root" ] || return 0
            session="$(session_for "$kind" "$slug" "$port")"
            ;;
        *) return 0 ;;
    esac
    open_firewall_if_possible "$port"
    static_server_start "" "$port" "$root" "$session"
    probe_with_retries "$url" static >/dev/null
    write_url "$dir" "$kind" "$url"
    write_owner "$dir" "$kind" "$port" "$session"
    release_port_reservation "$(port_role_for_kind "$kind")" "$port" "$(project_slug "$dir"):$(cd "$dir" && pwd -P):$kind" || true
}

start_app() {
    local dir="$1" url port db slug session
    [ -x "$dir/docs/larv/07-runtime/deploy-sandbox.sh" ] || return 0
    slug="$(project_slug "$dir")"
    url="$(url_for "$dir" app)"
    if [ -n "$url" ]; then
        port="$(port_from_url "$url")"
    else
        port="$(read_yq '.execution.allocations[]? | select(.kind == "app-port") | .value' "$dir/docs/larv/STATE.yaml" | tail -1)"
    fi
    port="$(safe_port_for_kind "$dir" app "$port")"
    session="$(session_for app "$slug" "$port")"
    db="$(read_yq '.sandbox.database.name // ""' "$dir/docs/larv/STATE.yaml")"
    [ -n "$db" ] && [ "$db" != "null" ] || db="$(grep '^DB_DATABASE=' "$dir/.env" 2>/dev/null | tail -1 | cut -d= -f2- || true)"
    open_firewall_if_possible "$port"
    (cd "$dir" && APP_PORT="$port" DB_DATABASE="${db:-}" LARV_PROJECT_SLUG="$slug" LARV_APP_SESSION="$session" bash docs/larv/07-runtime/deploy-sandbox.sh)
    session="$(detect_app_session "$slug" "$port")"
    url="$(static_server_url "$port")/"
    probe_with_retries "$url" laravel >/dev/null
    write_url "$dir" app "$url"
    write_owner "$dir" app "$port" "$session"
    release_port_reservation app "$port" "$slug:$(cd "$dir" && pwd -P):app" || true
}

sandbox_start() {
    local dir="$1" slug
    require_project "$dir"
    slug="$(project_slug "$dir")"
    start_app "$dir"
    start_static_kind "$dir" docs "$slug"
    start_static_kind "$dir" mockups "$slug"
    runtime_report "$dir"
}

sandbox_stop() {
    local dir="$1" slug app_url app_port docs_url docs_port mockups_url mockups_port
    require_project "$dir"
    slug="$(project_slug "$dir")"
    app_url="$(url_for "$dir" app)"
    docs_url="$(url_for "$dir" docs)"
    mockups_url="$(url_for "$dir" mockups)"
    app_port="$(port_from_url "$app_url")"
    docs_port="$(port_from_url "$docs_url")"
    mockups_port="$(port_from_url "$mockups_url")"
    stop_owned_session "$dir" app "$app_port"
    stop_owned_session "$dir" docs "$docs_port"
    stop_owned_session "$dir" mockups "$mockups_port"
    echo "Stopped larv sandbox sessions for $slug."
}

sandbox_reset() {
    local dir="$1"
    require_project "$dir"
    if [ ! -f "$dir/artisan" ]; then
        echo "ERROR: artisan not found in $dir; start/bootstrap the sandbox first." >&2
        exit 1
    fi
    (cd "$dir" && php artisan migrate:fresh --seed --force)
    sandbox_start "$dir"
}

main() {
    [ "$#" -eq 2 ] || usage
    local dir="$1" command="$2"
    case "$command" in
        info) runtime_report "$dir" ;;
        start) sandbox_start "$dir" ;;
        stop) sandbox_stop "$dir" ;;
        reset) sandbox_reset "$dir" ;;
        *) usage ;;
    esac
}

main "$@"
