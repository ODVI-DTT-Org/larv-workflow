#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PLUGIN_ROOT/scripts/lib/format.sh"
source "$PLUGIN_ROOT/scripts/lib/budget.sh"

usage() {
    echo "Usage: status.sh <project-dir> [--json]"
    exit 64
}

phase_name() {
    case "$1" in
        -1) echo "pre-flight" ;;
        0) echo "Discuss" ;;
        1) echo "Domain" ;;
        2) echo "Architecture" ;;
        3) echo "Design" ;;
        4) echo "Test strategy" ;;
        5) echo "Premortem" ;;
        6) echo "Slice plan" ;;
        7) echo "Handoff and doc-site" ;;
        8) echo "Implementation loop" ;;
        9) echo "Final verification" ;;
        10) echo "Deploy" ;;
        11) echo "Learn" ;;
        *) echo "unknown" ;;
    esac
}

main() {
    [ "$#" -ge 1 ] || usage
    local dir="$1"
    local json_mode=0
    [ "${2:-}" = "--json" ] && json_mode=1
    local sp="$dir/docs/larv/STATE.yaml"
    if [ ! -f "$sp" ]; then
        echo "ERROR: no STATE.yaml at $sp (not found)" >&2
        exit 1
    fi

    if [ "$json_mode" -eq 1 ]; then
        cat "$sp"
        return 0
    fi

    local name slug mode started plug_ver cur last gates_pending total completed in_progress pending
    name="$(yq -r '.project.name' "$sp")"
    slug="$(yq -r '.project.slug' "$sp")"
    mode="$(yq -r '.project.mode' "$sp")"
    started="$(yq -r '.project.started_at' "$sp")"
    plug_ver="$(yq -r '.plugin.version' "$sp")"
    cur="$(yq -r '.phase.current' "$sp")"
    last="$(yq -r '.phase.last_completed' "$sp")"
    gates_pending="$(yq -r '.phase.gates_pending | length' "$sp")"
    total="$(yq -r '.slices.total' "$sp")"
    completed="$(yq -r '[.slices.status[] | select(.state == "completed")] | length' "$sp")"
    in_progress="$(yq -r '[.slices.status[] | select(.state == "in_progress")] | length' "$sp")"
    pending="$(yq -r '[.slices.status[] | select(.state == "pending")] | length' "$sp")"

    echo "Project: $name ($slug, $mode, started $started)"
    echo "Plugin: larv $plug_ver"
    echo
    echo "Phase $cur - $(phase_name "$cur")"
    echo "Last completed: $last"
    [ "$gates_pending" -gt 0 ] && echo "Gates pending: $gates_pending"
    [ "$total" -gt 0 ] && echo "Slices: $completed/$total done, $in_progress in progress, $pending pending"

    local sb_url sb_status sb_test
    sb_url="$(yq -r '.sandbox.app_url' "$sp")"
    sb_status="$(yq -r '.sandbox.status' "$sp")"
    sb_test="$(yq -r '.sandbox.last_test_result' "$sp")"
    if [ "$sb_url" != "null" ]; then
        echo "Sandbox: $sb_url ($sb_status, tests $sb_test)"
    fi

    local b_min b_cost e_min e_cost cap
    b_min="$(yq -r '.budget.consumed.minutes' "$sp")"
    b_cost="$(yq -r '.budget.consumed.cost_usd' "$sp")"
    e_min="$(yq -r '.budget.estimated_total.minutes' "$sp")"
    e_cost="$(yq -r '.budget.estimated_total.cost_usd' "$sp")"
    cap="$(yq -r '.budget.cap_policy' "$sp")"
    if awk -v e="$e_cost" 'BEGIN { exit !(e > 0) }'; then
        echo "Budget: $(fmt_minutes "$b_min") / $(fmt_minutes "$e_min"), $(fmt_money "$b_cost") / $(fmt_money "$e_cost"), $(fmt_pct "$b_cost" "$e_cost") consumed"
        if budget_cap_exceeded "$b_cost" "$e_cost" "$cap"; then
            echo "Budget cap exceeded: $cap"
        fi
    fi

    local errs
    errs="$(yq -r '[.errors_unresolved[] | select(.resolved == false)] | length' "$sp")"
    if [ "$errs" -gt 0 ]; then
        echo "$errs unresolved error(s)"
    fi
}

main "$@"
