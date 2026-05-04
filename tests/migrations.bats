#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "migrate.sh runs noop v1-to-v1 migration successfully" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash migrations/state/migrate.sh "$TMP"
    [ "$status" -eq 0 ]
    run yq -r '.schema_version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "1" ]
}

@test "migrate.sh fails for unknown schema version" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    yq -i '.schema_version = 99' "$TMP/docs/larv/STATE.yaml"
    run bash migrations/state/migrate.sh "$TMP"
    [ "$status" -ne 0 ]
}

@test "migrate.sh creates a backup before migrating" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    bash migrations/state/migrate.sh "$TMP"
    run ls "$TMP/docs/larv/"
    echo "$output" | grep -qE 'STATE\.yaml\.bak\.[0-9]+'
}
