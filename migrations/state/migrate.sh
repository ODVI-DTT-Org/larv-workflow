#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_VERSION=1

usage() {
    echo "Usage: migrate.sh <project-dir>"
    exit 64
}

main() {
    [ "$#" -eq 1 ] || usage
    local dir="$1"
    local sp="$dir/docs/larv/STATE.yaml"
    [ -f "$sp" ] || { echo "ERROR: no STATE.yaml at $sp" >&2; exit 1; }

    local current
    current="$(yq -r '.schema_version' "$sp")"
    if [ "$current" = "null" ] || [ -z "$current" ]; then
        echo "ERROR: STATE.yaml has no schema_version" >&2
        exit 1
    fi
    if [ "$current" -gt "$TARGET_VERSION" ]; then
        echo "ERROR: STATE.yaml schema_version=$current is newer than target=$TARGET_VERSION" >&2
        exit 1
    fi

    cp "$sp" "$sp.bak.$(date -u +%s)"

    while [ "$current" -lt "$TARGET_VERSION" ]; do
        local next script
        next=$((current + 1))
        script="$PLUGIN_ROOT/migrations/state/v${current}-to-v${next}.sh"
        [ -x "$script" ] || { echo "ERROR: missing migration script $script" >&2; exit 1; }
        bash "$script" "$sp"
        current="$next"
        yq -i ".schema_version = $current" "$sp"
    done

    local same="$PLUGIN_ROOT/migrations/state/v${current}-to-v${current}.sh"
    [ -x "$same" ] && bash "$same" "$sp"
    echo "Migrated to schema_version=$current"
}

main "$@"
