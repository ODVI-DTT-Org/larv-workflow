#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "status fails when STATE.yaml is missing" {
    run bash scripts/status.sh "$TMP"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qiE "no.*state.yaml|not found"
}

@test "status against empty state shows project name and slug" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "my-app"
    echo "$output" | grep -q "my-app-2026-05"
}

@test "status against empty state shows pre-flight phase" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "phase.*-1|pre-flight"
}

@test "status against mid-slice state shows slice progress" {
    cp tests/fixtures/state-mid-slice.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qE "Slices.*2/4"
}

@test "status against budget-exceeded state surfaces the cap" {
    cp tests/fixtures/state-budget-exceeded.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "exceeded|over.*budget|cap"
}

@test "status --json dumps raw YAML" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP" --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "schema_version: 1"
}

@test "status against errors-unresolved state surfaces errors" {
    cp tests/fixtures/state-errors-unresolved.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "1.*error|unresolved.*error"
}
