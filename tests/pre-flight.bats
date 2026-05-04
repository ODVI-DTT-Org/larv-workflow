#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "pre-flight initializes STATE.yaml when called for a new project" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/STATE.yaml" ]
    run yq -r '.phase.current' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "-1" ]
}

@test "pre-flight populates plugin.bundle_versions" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.plugin.bundle_versions.masterplan' "$TMP/docs/larv/STATE.yaml"
    [ "$status" -eq 0 ]
    [ "$output" != "null" ]
}

@test "pre-flight writes pre-flight.md report" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ -f "$TMP/docs/larv/pre-flight.md" ]
    run grep -F "Project: my-app" "$TMP/docs/larv/pre-flight.md"
    [ "$status" -eq 0 ]
}

@test "pre-flight reports bundle and MCP checks" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "bundle check"
    echo "$output" | grep -qiE "mcp check"
}

@test "pre-flight estimates a non-zero budget" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.budget.estimated_total.cost_usd' "$TMP/docs/larv/STATE.yaml"
    awk -v v="$output" 'BEGIN { exit !(v > 0) }'
}

@test "pre-flight refuses to run if STATE.yaml already exists" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
}
