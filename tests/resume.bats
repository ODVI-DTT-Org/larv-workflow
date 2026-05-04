#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "resume fails when STATE.yaml is missing" {
    run bash scripts/resume.sh "$TMP"
    [ "$status" -ne 0 ]
}

@test "resume from empty state advances to phase 0" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "next.*phase 0|advance.*0|spawn.*phase 0"
}

@test "resume with gate pending surfaces the gate for review" {
    cp tests/fixtures/state-gate-pending.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "gate.*pending|approve.*phase 0"
}

@test "resume with errors_unresolved surfaces errors before anything else" {
    cp tests/fixtures/state-errors-unresolved.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "unresolved error|fix.*error.*first"
    ! echo "$output" | grep -q "spawn.*slice"
}

@test "resume with budget exceeded pauses for cap policy review" {
    cp tests/fixtures/state-budget-exceeded.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "budget.*exceeded|cap.*reached|bump.*cap"
}

@test "resume mid-slice continues the in-progress slice" {
    cp tests/fixtures/state-mid-slice.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "continue slice 03|resume.*03"
}

@test "resume --force-unlock clears stale lock" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    run bash scripts/resume.sh "$TMP" --force-unlock
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}
