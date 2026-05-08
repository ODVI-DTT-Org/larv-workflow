#!/usr/bin/env bash
# Handsoff document generator. Per spec §15: writes docs/Handsoff.md (index),
# docs/Handsoff/bootstrap-sandbox.md, runtime/deploy guides, and
# docs/Handsoff/slice-NN-<name>.md (per slice), plus AI starting-point files
# (CLAUDE.md, AGENTS.md, GEMINI.md, .cursor/rules/larv.mdc, .codex/AGENTS.md).
# Self-contained: handsoff content references no plugin scripts.

__handsoff_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

# Read STATE.yaml and produce a key=value map for sed substitution.
handsoff_collect_tokens() {
    local dir="$1"
    local sp="$dir/docs/larv/STATE.yaml"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local plugin_version
    plugin_version="$(yq -r '.version // "0.0.0"' "$plugin_root/.claude-plugin/plugin.json" 2>/dev/null || echo "0.0.0")"
    local git_sha git_default_branch
    git_sha="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo "uncommitted")"
    git_default_branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || echo "detached")"

    local app_port mockup_port db_name project_root slug
    slug="$(yq -r '.project.slug' "$sp")"
    app_port="$(yq -r '.execution.allocations[] | select(.kind == "app-port") | .value' "$sp" 2>/dev/null | head -1)"
    mockup_port="$(yq -r '.execution.allocations[] | select(.kind == "mockup-port") | .value' "$sp" 2>/dev/null | head -1)"
    db_name="$(yq -r '.execution.allocations[] | select(.kind == "db-name") | .value' "$sp" 2>/dev/null | head -1)"
    project_root="$(yq -r '.execution.allocations[] | select(.kind == "project-root") | .value' "$sp" 2>/dev/null | head -1)"

    __handsoff_token() {
        local key="$1"
        local value="$2"
        printf "__LARV_TOKEN_START__%s\n%s\n__LARV_TOKEN_END__\n" "$key" "$value"
    }

    __handsoff_file_or_default() {
        local file="$1"
        local default="$2"
        if [ -f "$file" ]; then
            cat "$file"
        else
            printf "%s\n" "$default"
        fi
    }

    __handsoff_token project_name "$(yq -r '.project.name' "$sp")"
    __handsoff_token project_slug "$slug"
    __handsoff_token plugin_version "$plugin_version"
    __handsoff_token generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    __handsoff_token git_sha "$git_sha"
    __handsoff_token git_default_branch "$git_default_branch"
    __handsoff_token vm_host "${LARV_VM_HOST:-31.220.79.31}"
    __handsoff_token ssh_user "${LARV_VM_HOST_SSH_USER:-claude-team}"
    __handsoff_token app_port "${app_port:-TBD}"
    __handsoff_token mockup_port "${mockup_port:-TBD}"
    __handsoff_token db_name "${db_name:-TBD}"
    __handsoff_token db_user "${db_name:-TBD}"
    __handsoff_token project_root "${project_root:-$(cd "$dir" && pwd -P)}"
    __handsoff_token redis_prefix "larv:$slug:"
    __handsoff_token ssh_key_path "~/.ssh/larv_${slug}_ed25519"
    __handsoff_token mission_paragraph "See docs/larv/00-discuss/product-brief.md"
    __handsoff_token adr_aggregator_inlined "$(__handsoff_file_or_default "$dir/docs/larv/decisions.md" "_(no ADRs yet)_")"
    __handsoff_token ddd_model_inlined_or_flat_model "$(__handsoff_file_or_default "$dir/docs/larv/01-domain/domain-model.md" "_(domain model TBD)_")"
    __handsoff_token c4_diagrams_inlined "$(__handsoff_file_or_default "$dir/docs/larv/02-architecture/c4-context.md" "_(C4 TBD)_")"
    __handsoff_token data_model_inlined "$(__handsoff_file_or_default "$dir/docs/larv/03-design/data-model.md" "_(data model TBD)_")"
    __handsoff_token api_surface_inlined "$(__handsoff_file_or_default "$dir/docs/larv/03-design/api-surface.md" "_(API surface TBD)_")"
    __handsoff_token test_strategy_inlined "$(__handsoff_file_or_default "$dir/docs/larv/04-test-strategy/strategy.md" "_(test strategy TBD)_")"
    __handsoff_token slice_plan_inlined "$(__handsoff_file_or_default "$dir/docs/larv/06-implementation/elephant-carpaccio.md" "_(slice plan TBD)_")"
    __handsoff_token design_pick_slug "$(test -f "$dir/docs/larv/03-design/design-decision.md" && grep -m1 -oE 'pick: [A-Za-z0-9_-]+' "$dir/docs/larv/03-design/design-decision.md" | head -1 | sed 's/pick: //' || echo "TBD")"
    __handsoff_token smoke_path "$(yq -r '.sandbox.smoke_path // "health"' "$sp" 2>/dev/null || echo "health")"
}

# render_template <template_path> <tokens_file>
__handsoff_render_template() {
    local tmpl="$1"
    local tokens_file="$2"
    local out
    if [ ! -s "$tmpl" ]; then
        echo "ERROR: handsoff template missing or empty: $tmpl" >&2
        return 1
    fi
    out="$(cat "$tmpl")"
    if grep -q '^__LARV_TOKEN_START__' "$tokens_file"; then
        local key value line
        while IFS= read -r line; do
            case "$line" in
                __LARV_TOKEN_START__*)
                    key="${line#__LARV_TOKEN_START__}"
                    value=""
                    while IFS= read -r line; do
                        [ "$line" = "__LARV_TOKEN_END__" ] && break
                        if [ -n "$value" ]; then
                            value="${value}"$'\n'"${line}"
                        else
                            value="$line"
                        fi
                    done
                    out="${out//\{\{${key}\}\}/${value}}"
                    ;;
                *=*)
                    key="${line%%=*}"
                    value="${line#*=}"
                    [ -z "$key" ] && continue
                    out="${out//\{\{${key}\}\}/${value}}"
                    ;;
            esac
        done < "$tokens_file"
    else
        while IFS='=' read -r k v; do
            [ -z "$k" ] && continue
            out="${out//\{\{${k}\}\}/${v}}"
        done < "$tokens_file"
    fi
    if [ -z "$out" ]; then
        echo "ERROR: rendered handsoff template is empty: $tmpl" >&2
        return 1
    fi
    printf "%s\n" "$out"
}

handsoff_render_index() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    mkdir -p "$dir/docs"
    __handsoff_render_template "$plugin_root/templates/handsoff-index.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff.md"
    rm -f "$tokens"
}

handsoff_render_bootstrap_sandbox() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    mkdir -p "$dir/docs/Handsoff"
    __handsoff_render_template "$plugin_root/templates/bootstrap-sandbox.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/bootstrap-sandbox.md"
    rm -f "$tokens"
}

handsoff_render_runtime_guides() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    mkdir -p "$dir/docs/Handsoff"
    __handsoff_render_template "$plugin_root/templates/production-deploy.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/production-deploy.md"
    __handsoff_render_template "$plugin_root/templates/env-guide.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/env-guide.md"
    __handsoff_render_template "$plugin_root/templates/operations-guide.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/operations-guide.md"
    __handsoff_render_template "$plugin_root/templates/package-matrix.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/package-guide.md"
    mkdir -p "$dir/docs/user-manual/testing"
    __handsoff_render_template "$plugin_root/templates/user-manual-index.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/README.md"
    __handsoff_render_template "$plugin_root/templates/operations-guide.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/installation.md"
    __handsoff_render_template "$plugin_root/templates/env-guide.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/environment.md"
    __handsoff_render_template "$plugin_root/templates/production-deploy.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/production-deploy.md"
    __handsoff_render_template "$plugin_root/templates/package-matrix.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/package-guide.md"
    __handsoff_render_template "$plugin_root/templates/seed-data-guide.md.tmpl" "$tokens" \
        > "$dir/docs/user-manual/seed-data.md"
    mkdir -p "$dir/docs/larv/08-implementation/reports"
    __handsoff_render_template "$plugin_root/templates/docs-index.md.tmpl" "$tokens" \
        > "$dir/DOCS.md"
    rm -f "$tokens"
}

# handsoff_render_slice <dir> <slice_id> <slice_slug>
handsoff_render_slice() {
    local dir="$1"
    local slice_id="$2"
    local slice_slug="$3"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    cat >> "$tokens" <<EOF
slice_id=$slice_id
slice_name=$slice_slug
slice_slug=$slice_slug
goal_one_line=See slice plan
why_user_visible_value=See slice plan
files_to_create_list=- (see slice plan)
files_to_modify_list=- (see slice plan)
migrations_list=- (see slice plan)
tests_list_with_acceptance_criteria=- (see slice plan)
api_endpoints_with_examples=- (see slice plan)
ui_screens_list=- (see slice plan)
depends_on_list=[]
parallel_flag=false
test_filter=$slice_id
est_tokens=TBD
est_minutes=TBD
implementation_bash=# (insert exact bash from slice plan)
tracker_id_padding=0001
your_tool_id=<your tool>
your_model_id=<your model>
files_changed_yaml_array=
related_adr_yaml_array=
learnings_appended_bool=false
seeded_email=admin@example.com
seeded_password=password
passed=
total=
EOF
    mkdir -p "$dir/docs/Handsoff"
    __handsoff_render_template "$plugin_root/templates/handsoff-slice.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/$slice_id-$slice_slug.md"
    rm -f "$tokens"
}

handsoff_render_starting_points() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"

    # Five files, one body, different prepends in tool_friendly_name.
    local body tmpdir
    body="$(__handsoff_render_template "$plugin_root/templates/ai-starting-point.md.tmpl" "$tokens")" || {
        rm -f "$tokens"
        return 1
    }
    if [ -z "$body" ] || ! grep -q "docs/Handsoff.md" <<<"$body" || ! grep -q "bootstrap-sandbox.md" <<<"$body"; then
        echo "ERROR: rendered AI starting-point body failed validation" >&2
        rm -f "$tokens"
        return 1
    fi
    tmpdir="$(mktemp -d)"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        printf "%s\n" "${body//\{\{tool_friendly_name\}\}/Claude Code}"
    } > "$tmpdir/CLAUDE.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        printf "%s\n" "${body//\{\{tool_friendly_name\}\}/Agent}"
    } > "$tmpdir/AGENTS.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        printf "%s\n" "${body//\{\{tool_friendly_name\}\}/Gemini CLI}"
    } > "$tmpdir/GEMINI.md"

    mkdir -p "$tmpdir/.codex"
    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        printf "%s\n" "${body//\{\{tool_friendly_name\}\}/Codex CLI}"
    } > "$tmpdir/.codex/AGENTS.md"

    mkdir -p "$tmpdir/.cursor/rules"
    __handsoff_render_template "$plugin_root/templates/cursor-rule.mdc.tmpl" "$tokens" \
        > "$tmpdir/.cursor/rules/larv.mdc" || {
            rm -rf "$tmpdir"
            rm -f "$tokens"
            return 1
        }

    local f
    for f in "$tmpdir/CLAUDE.md" "$tmpdir/AGENTS.md" "$tmpdir/GEMINI.md" \
             "$tmpdir/.codex/AGENTS.md" "$tmpdir/.cursor/rules/larv.mdc"; do
        if [ ! -s "$f" ] || ! grep -q "Handsoff.md" "$f" || ! grep -q "bootstrap-sandbox.md" "$f"; then
            echo "ERROR: invalid generated AI starting-point file: $f" >&2
            rm -rf "$tmpdir"
            rm -f "$tokens"
            return 1
        fi
    done

    mkdir -p "$dir/.codex" "$dir/.cursor/rules"
    mv "$tmpdir/CLAUDE.md" "$dir/CLAUDE.md"
    mv "$tmpdir/AGENTS.md" "$dir/AGENTS.md"
    mv "$tmpdir/GEMINI.md" "$dir/GEMINI.md"
    mv "$tmpdir/.codex/AGENTS.md" "$dir/.codex/AGENTS.md"
    mv "$tmpdir/.cursor/rules/larv.mdc" "$dir/.cursor/rules/larv.mdc"
    rm -rf "$tmpdir"

    rm -f "$tokens"
}
