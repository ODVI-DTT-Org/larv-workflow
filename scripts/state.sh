#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: state.sh <command> <project-dir> [args...]

Commands:
  init <dir> <name> <mode>
  read <dir>
  update <dir> <yq-expr>
EOF
    exit 64
}

state_path() {
    echo "$1/docs/larv/STATE.yaml"
}

now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

slug_from_name() {
    local name="$1"
    printf "%s-%s" "$name" "$(date -u +"%Y-%m")"
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

    cat >"$sp" <<EOF
schema_version: 1
project:
  name: $name
  slug: $slug
  greenfield: $greenfield
  mode: $mode
  started_at: "$now"
  last_updated_at: "$now"
plugin:
  name: larv
  version: 0.1.0
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

main() {
    [ "$#" -lt 2 ] && usage
    local cmd="$1"
    shift
    case "$cmd" in
        init) [ "$#" -eq 3 ] || usage; cmd_init "$@" ;;
        read) [ "$#" -eq 1 ] || usage; cmd_read "$@" ;;
        update) [ "$#" -eq 2 ] || usage; cmd_update "$@" ;;
        *) usage ;;
    esac
}

main "$@"
