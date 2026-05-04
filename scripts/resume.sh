#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PLUGIN_ROOT/scripts/lib/budget.sh"

usage() {
    echo "Usage: resume.sh <project-dir> [--force-unlock]"
    exit 64
}

is_int() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

main() {
    [ "$#" -ge 1 ] || usage
    local dir="$1"
    local force_unlock=0
    [ "${2:-}" = "--force-unlock" ] && force_unlock=1
    local sp="$dir/docs/larv/STATE.yaml"
    [ -f "$sp" ] || { echo "ERROR: no STATE.yaml at $sp" >&2; exit 1; }

    if [ "$force_unlock" -eq 1 ]; then
        bash "$PLUGIN_ROOT/scripts/lock.sh" force-unlock "$dir"
        echo "Lock cleared at $dir/docs/larv/.lock"
    fi

    local errs
    errs="$(yq -r '[.errors_unresolved[] | select(.resolved == false)] | length' "$sp")"
    if [ "$errs" -gt 0 ]; then
        echo "$errs unresolved error(s) - fix error first before resuming."
        yq -o=yaml '.errors_unresolved[] | select(.resolved == false)' "$sp"
        return 0
    fi

    local gates_pending
    gates_pending="$(yq -r '.phase.gates_pending | length' "$sp")"
    if [ "$gates_pending" -gt 0 ]; then
        local first_gate
        first_gate="$(yq -r '.phase.gates_pending[0]' "$sp")"
        echo "Gate pending - approve phase $first_gate before continuing."
        return 0
    fi

    local b_cost e_cost cap
    b_cost="$(yq -r '.budget.consumed.cost_usd' "$sp")"
    e_cost="$(yq -r '.budget.estimated_total.cost_usd' "$sp")"
    cap="$(yq -r '.budget.cap_policy' "$sp")"
    if awk -v e="$e_cost" 'BEGIN { exit !(e > 0) }' && budget_cap_exceeded "$b_cost" "$e_cost" "$cap"; then
        echo "Budget exceeded: cap reached ($cap). Bump cap, reduce scope, or halt."
        return 0
    fi

    local cur last
    cur="$(yq -r '.phase.current' "$sp")"
    last="$(yq -r '.phase.last_completed' "$sp")"
    if [ "$cur" = "11" ] && [ "$last" = "11" ]; then
        echo "Project complete."
        return 0
    fi

    if is_int "$cur" && [ "$cur" -lt 8 ]; then
        local next=$((cur + 1))
        echo "Next: spawn phase $next subagent (advance to phase $next)."
        return 0
    fi

    if [ "$cur" = "8" ]; then
        local in_progress_slice
        in_progress_slice="$(yq -r '[.slices.status | to_entries[] | select(.value.state == "in_progress")][0].key' "$sp")"
        if [ "$in_progress_slice" != "null" ] && [ -n "$in_progress_slice" ]; then
            echo "Continue slice $in_progress_slice."
            return 0
        fi
        local next_pending
        next_pending="$(yq -r '[.slices.status | to_entries[] | select(.value.state == "pending")][0].key' "$sp")"
        if [ "$next_pending" != "null" ] && [ -n "$next_pending" ]; then
            echo "Spawn slice $next_pending subagent."
            return 0
        fi
        echo "All slices done - advance to phase 9."
        return 0
    fi

    if is_int "$cur"; then
        local next=$((cur + 1))
        echo "Next: spawn phase $next subagent."
        return 0
    fi

    echo "Resume adoption phase $cur."
}

main "$@"
