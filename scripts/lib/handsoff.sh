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

    local app_port mockup_port db_name project_root
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
    __handsoff_token project_slug "$(yq -r '.project.slug' "$sp")"
    __handsoff_token plugin_version "$plugin_version"
    __handsoff_token generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    __handsoff_token git_sha "$git_sha"
    __handsoff_token git_default_branch "$git_default_branch"
    __handsoff_token vm_host "${LARV_VM_HOST:-31.220.79.31}"
    __handsoff_token ssh_user "${LARV_VM_HOST_SSH_USER:-larv}"
    __handsoff_token app_port "${app_port:-TBD}"
    __handsoff_token mockup_port "${mockup_port:-TBD}"
    __handsoff_token db_name "${db_name:-TBD}"
    __handsoff_token db_user "${db_name:-TBD}"
    __handsoff_token project_root "${project_root:-/srv/larv/$(yq -r '.project.slug' "$sp")}"
    __handsoff_token redis_prefix "larv:$(yq -r '.project.slug' "$sp"):"
    __handsoff_token ssh_key_path "~/.ssh/larv_$(yq -r '.project.slug' "$sp")_ed25519"
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
    local body
    body="$(__handsoff_render_template "$plugin_root/templates/ai-starting-point.md.tmpl" "$tokens")"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Claude Code}"
    } > "$dir/CLAUDE.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Agent}"
    } > "$dir/AGENTS.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Gemini CLI}"
    } > "$dir/GEMINI.md"

    mkdir -p "$dir/.codex"
    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Codex CLI}"
    } > "$dir/.codex/AGENTS.md"

    mkdir -p "$dir/.cursor/rules"
    __handsoff_render_template "$plugin_root/templates/cursor-rule.mdc.tmpl" "$tokens" \
        > "$dir/.cursor/rules/larv.mdc"

    rm -f "$tokens"
}
