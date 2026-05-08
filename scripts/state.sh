#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<EOF
Usage: state.sh <command> <project-dir> [args...]

Commands:
  init <dir> <name> <mode>
  read <dir>
  update <dir> <yq-expr>
  set-mode <dir> <mode>
  set-review-mode <dir> <review-mode>
  record-allocation <dir> <kind> <value>
EOF
    exit 64
}

state_path() {
    echo "$1/docs/larv/STATE.yaml"
}

now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

yaml_double_quote() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '"%s"' "$value"
}

plugin_version() {
    yq -r '.version // "0.0.0"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "0.0.0"
}

slug_from_name() {
    local name="$1"
    local base
    base="$(printf "%s" "$name" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
    [ -n "$base" ] || base="larv-app"
    printf "%s-%s" "$base" "$(date -u +"%Y-%m")"
}

cmd_init() {
    local dir="$1"
    local name="$2"
    local mode="$3"
    local sp
    sp="$(state_path "$dir")"

    if [ "$mode" != "greenfield" ] && [ "$mode" != "adopted" ]; then
        echo "ERROR: mode must be greenfield or adopted" >&2
        return 1
    fi
    if [ -e "$sp" ]; then
        echo "ERROR: STATE.yaml already exists at $sp" >&2
        return 1
    fi

    mkdir -p "$(dirname "$sp")"
    local greenfield now slug
    greenfield=false
    [ "$mode" = "greenfield" ] && greenfield=true
    now="$(now_iso)"
    slug="$(slug_from_name "$name")"

    local quoted_name quoted_slug pver
    quoted_name="$(yaml_double_quote "$name")"
    quoted_slug="$(yaml_double_quote "$slug")"
    pver="$(plugin_version)"

    cat >"$sp" <<EOF
schema_version: 1
project:
  name: $quoted_name
  slug: $quoted_slug
  greenfield: $greenfield
  mode: $mode
  started_at: "$now"
  last_updated_at: "$now"
plugin:
  name: larv
  version: "$pver"
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "0000000"
phase:
  current: -1
  last_completed: null
  gates_pending: []
gates: []
slices:
  total: 0
  status: {}
sandbox:
  vm_host: null
  app_url: null
  status: not_provisioned
  last_deploy_at: null
  last_test_run_at: null
  last_test_result: null
budget:
  estimated_total: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  consumed: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
execution:
  mode: not-yet-decided
  review_mode: not-yet-decided
  allocations: []
features: []
debugs: []
EOF
}

cmd_read() {
    local sp
    sp="$(state_path "$1")"
    [ -f "$sp" ] || { echo "ERROR: no STATE.yaml at $sp" >&2; return 1; }
    cat "$sp"
}

cmd_update() {
    local dir="$1"
    local expr="$2"
    local sp tmp now
    sp="$(state_path "$dir")"
    [ -f "$sp" ] || { echo "ERROR: no STATE.yaml at $sp" >&2; return 1; }
    tmp="$(mktemp)"
    now="$(now_iso)"
    yq "$expr | .project.last_updated_at = \"$now\"" "$sp" >"$tmp"
    mv "$tmp" "$sp"
}

cmd_set_mode() {
    local dir="$1"
    local mode="$2"
    case "$mode" in
        not-yet-decided|executing-same-session|executing-subagents|handed-off-external)
            ;;
        *) echo "ERROR: invalid mode: $mode" >&2; return 1 ;;
    esac
    cmd_update "$dir" ".execution.mode = \"$mode\""
}

cmd_set_review_mode() {
    local dir="$1"
    local mode="$2"
    case "$mode" in
        auto-all|manual-slice|manual-adr|manual-phase|not-yet-decided)
            ;;
        *) echo "ERROR: invalid review mode: $mode" >&2; return 1 ;;
    esac
    cmd_update "$dir" ".execution.review_mode = \"$mode\""
}

cmd_record_allocation() {
    local dir="$1"
    local kind="$2"
    local value="$3"
    cmd_update "$dir" ".execution.allocations += [{ \"kind\": \"$kind\", \"value\": \"$value\" }]"
}

main() {
    [ "$#" -lt 2 ] && usage
    local cmd="$1"
    shift
    case "$cmd" in
        init) [ "$#" -eq 3 ] || usage; cmd_init "$@" ;;
        read) [ "$#" -eq 1 ] || usage; cmd_read "$@" ;;
        update) [ "$#" -eq 2 ] || usage; cmd_update "$@" ;;
        set-mode) [ "$#" -eq 2 ] || usage; cmd_set_mode "$@" ;;
        set-review-mode) [ "$#" -eq 2 ] || usage; cmd_set_review_mode "$@" ;;
        record-allocation) [ "$#" -eq 3 ] || usage; cmd_record_allocation "$@" ;;
        *) usage ;;
    esac
}

main "$@"
