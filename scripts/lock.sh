#!/usr/bin/env bash
set -euo pipefail

LOCK_STALE_MINUTES="${LOCK_STALE_MINUTES:-30}"

usage() {
    cat <<EOF
Usage: lock.sh <command> <project-dir> [owner-pid]

Commands:
  acquire
  release
  force-unlock
EOF
    exit 64
}

lock_path() {
    echo "$1/docs/larv/.lock"
}

now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

iso_to_epoch() {
    if date -d "$1" +%s >/dev/null 2>&1; then
        date -d "$1" +%s
    else
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s
    fi
}

is_stale() {
    local started_at="$1"
    local now_epoch lock_epoch diff_minutes
    now_epoch="$(date -u +%s)"
    lock_epoch="$(iso_to_epoch "$started_at")"
    diff_minutes=$(((now_epoch - lock_epoch) / 60))
    [ "$diff_minutes" -gt "$LOCK_STALE_MINUTES" ]
}

owner_pid() {
    echo "${1:-$$}"
}

cmd_acquire() {
    local dir="$1"
    local owner
    owner="$(owner_pid "${2:-}")"
    local lp
    lp="$(lock_path "$dir")"
    mkdir -p "$(dirname "$lp")"

    if [ -f "$lp" ]; then
        local pid started_at
        pid="$(awk -F': ' '/^pid:/ {print $2}' "$lp")"
        started_at="$(awk -F': ' '/^started_at:/ {print $2}' "$lp")"
        if [ "$pid" = "$owner" ]; then
            return 0
        fi
        if [ -n "$started_at" ] && is_stale "$started_at"; then
            rm -f "$lp"
        else
            echo "ERROR: lock held by pid=$pid since $started_at" >&2
            return 1
        fi
    fi

    cat >"$lp" <<EOF
pid: $owner
hostname: $(hostname 2>/dev/null || echo unknown)
started_at: $(now_iso)
EOF
}

cmd_release() {
    rm -f "$(lock_path "$1")"
}

cmd_force_unlock() {
    rm -f "$(lock_path "$1")"
}

main() {
    [ "$#" -lt 2 ] && usage
    local cmd="$1"
    shift
    case "$cmd" in
        acquire) cmd_acquire "$@" ;;
        release) [ "$#" -eq 1 ] || usage; cmd_release "$@" ;;
        force-unlock) [ "$#" -eq 1 ] || usage; cmd_force_unlock "$@" ;;
        *) usage ;;
    esac
}

main "$@"
