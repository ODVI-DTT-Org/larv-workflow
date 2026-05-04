#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_BUDGET_TOKENS=4500000
DEFAULT_BUDGET_MINUTES=480
DEFAULT_BUDGET_COST=42.00

usage() {
    echo "Usage: pre-flight.sh <project-dir> <project-name> <mode>"
    exit 64
}

read_bundle_version() {
    local name="$1"
    local vfile="$PLUGIN_ROOT/bundle/VERSIONS.yaml"
    if [ -f "$vfile" ]; then
        yq -r ".[\"$name\"] // \"0.0.0\"" "$vfile"
    else
        echo "0.0.0"
    fi
}

main() {
    [ "$#" -eq 3 ] || usage
    local dir="$1"
    local name="$2"
    local mode="$3"
    local sp="$dir/docs/larv/STATE.yaml"
    if [ -f "$sp" ]; then
        echo "ERROR: STATE.yaml already exists at $sp" >&2
        exit 1
    fi

    echo "[larv pre-flight]"
    echo "Bundle check:"
    local b
    for b in masterplan superpowers-laravel domain-driven-design huashu-design; do
        if [ -d "$PLUGIN_ROOT/bundle/$b" ]; then
            echo "  ok $b $(read_bundle_version "$b")"
        else
            echo "  missing $b"
        fi
    done
    echo "MCP check:"
    echo "  context7 stub"

    bash "$PLUGIN_ROOT/scripts/state.sh" init "$dir" "$name" "$mode"

    local bm bs bd bh
    bm="$(read_bundle_version masterplan)"
    bs="$(read_bundle_version superpowers-laravel)"
    bd="$(read_bundle_version domain-driven-design)"
    bh="$(read_bundle_version huashu-design)"
    bash "$PLUGIN_ROOT/scripts/state.sh" update "$dir" \
        ".plugin.bundle_versions = {\"masterplan\": \"$bm\", \"superpowers-laravel\": \"$bs\", \"domain-driven-design\": \"$bd\", \"huashu-design\": \"$bh\"}"
    bash "$PLUGIN_ROOT/scripts/state.sh" update "$dir" \
        ".budget.estimated_total = {\"tokens\": $DEFAULT_BUDGET_TOKENS, \"minutes\": $DEFAULT_BUDGET_MINUTES, \"cost_usd\": $DEFAULT_BUDGET_COST}"

    cat >"$dir/docs/larv/pre-flight.md" <<EOF
# Pre-flight report

Project: $name
Mode: $mode
Plugin: larv 0.1.0
Bundle versions:
  - masterplan: $bm
  - superpowers-laravel: $bs
  - domain-driven-design: $bd
  - huashu-design: $bh

Estimated budget: ~$DEFAULT_BUDGET_MINUTES min, ~\$$DEFAULT_BUDGET_COST
Cap policy: pause_at_120pct

This is a sub-project A stub. Full pre-flight checks are deferred.
EOF

    echo "Project: $name"
    echo "Estimated budget: ~$DEFAULT_BUDGET_MINUTES min, ~\$$DEFAULT_BUDGET_COST"
    echo "STATE.yaml initialized at $sp"
}

main "$@"
