#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "lock acquire creates the lock file" {
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/.lock" ]
    run grep -E '^pid:' "$TMP/docs/larv/.lock"
    [ "$status" -eq 0 ]
}

@test "lock acquire fails if a fresh lock exists from another pid" {
    bash scripts/lock.sh acquire "$TMP"
    sed -i 's/^pid:.*$/pid: 99999/' "$TMP/docs/larv/.lock"
    sed -i "s/^started_at:.*$/started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$TMP/docs/larv/.lock"
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -ne 0 ]
}

@test "lock acquire succeeds re-entrant for the same owner pid" {
    bash scripts/lock.sh acquire "$TMP"
    local pid
    pid="$(awk -F': ' '/^pid:/ {print $2}' "$TMP/docs/larv/.lock")"
    run bash scripts/lock.sh acquire "$TMP" "$pid"
    [ "$status" -eq 0 ]
}

@test "lock release removes the lock file" {
    bash scripts/lock.sh acquire "$TMP"
    run bash scripts/lock.sh release "$TMP"
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}

@test "stale lock greater than 30 min auto-cleared on acquire" {
    mkdir -p "$TMP/docs/larv"
    local stale_iso
    stale_iso="$(date -u -d '40 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-40M +%Y-%m-%dT%H:%M:%SZ)"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $stale_iso
EOF
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -eq 0 ]
    run grep -E "^pid:" "$TMP/docs/larv/.lock"
    [ "$status" -eq 0 ]
}

@test "force-unlock clears any lock unconditionally" {
    mkdir -p "$TMP/docs/larv"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    run bash scripts/lock.sh force-unlock "$TMP"
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}
