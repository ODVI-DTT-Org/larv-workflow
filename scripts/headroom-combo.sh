#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<EOF
Usage: headroom-combo.sh status <project-dir>

Bootstraps larv's Ponytail + gated Headroom + Caveman workflow combo.
EOF
    exit 64
}

caveman_style() {
    local dir="$1"
    local stored resolved
    stored="$(bash "$PLUGIN_ROOT/scripts/state.sh" get-caveman-style "$dir" 2>/dev/null || true)"
    [ -n "$stored" ] || stored="full"
    resolved="$(LARV_CAVEMAN_ALLOW_UNSCOPED_RESOLVE=1 bash "$PLUGIN_ROOT/scripts/caveman.sh" resolve "$dir" "$stored" 2>/dev/null || true)"
    [ -n "$resolved" ] || resolved="full-unavailable"
    printf "%s\n" "$resolved"
}

optimizer_json() {
    local dir="$1"
    local workspace="$dir/docs/larv/headroom"

    env \
        LARV_TOKEN_OPTIMIZER_CANDIDATES="${LARV_TOKEN_OPTIMIZER_CANDIDATES:-headroom}" \
        HEADROOM_WORKSPACE_DIR="${HEADROOM_WORKSPACE_DIR:-$workspace}" \
        HEADROOM_CONFIG_DIR="${HEADROOM_CONFIG_DIR:-$workspace/config}" \
        HEADROOM_WRAP="${HEADROOM_WRAP:-0}" \
        HEADROOM_PROXY="${HEADROOM_PROXY:-0}" \
        HEADROOM_LEARNING="${HEADROOM_LEARNING:-0}" \
        HEADROOM_MEMORY="${HEADROOM_MEMORY:-0}" \
        HEADROOM_TELEMETRY="${HEADROOM_TELEMETRY:-0}" \
        HEADROOM_DOCKER_WRAPPER="${HEADROOM_DOCKER_WRAPPER:-0}" \
        bash "$PLUGIN_ROOT/scripts/token-optimizer.sh" json "$dir" 2>/dev/null
}

status() {
    local dir="$1"
    local workspace="$dir/docs/larv/headroom"
    local json selected state reason safe_mode

    echo "larv Headroom combo:"
    echo "Ponytail: active (YAGNI/minimum scope)"

    if json="$(optimizer_json "$dir")"; then
        selected="$(jq -r '.selected // "none"' <<<"$json")"
        state="$(jq -r '.status // "fallback"' <<<"$json")"
        reason="$(jq -r '.fallback_reason // .reason // ""' <<<"$json")"
        safe_mode="$(jq -r '.safe_mode // ""' <<<"$json")"
        if [ "$selected" = "headroom" ] && [ "$state" = "safe" ]; then
            echo "Headroom: safe"
            echo "Headroom workspace: $workspace"
            echo "Headroom mode: $safe_mode"
            echo "Token measurement: available via scripts/token-optimizer.sh measure <project-dir> <file|-> (50% target; may use lossy larv-context-pack)"
        else
            echo "Headroom: fallback${reason:+ - $reason}"
            echo "Headroom workspace: $workspace"
            echo "Token measurement: unavailable until Headroom passes the gate"
        fi
    else
        echo "Headroom: fallback - optimizer gate unavailable"
        echo "Headroom workspace: $workspace"
        echo "Token measurement: unavailable until Headroom passes the gate"
    fi

    echo "Caveman: $(caveman_style "$dir")"
}

main() {
    [ "$#" -eq 2 ] || usage
    case "$1" in
        status) status "$2" ;;
        *) usage ;;
    esac
}

main "$@"
