#!/usr/bin/env bats

load helpers

@test "greenfield-todo fixture directory exists" {
    [ -d tests/fixtures/greenfield-todo ]
}

@test "smoke test: pre-flight runs end-to-end on greenfield-todo fixture" {
    local tmp
    tmp="$(mktemp -d)"
    cp -r tests/fixtures/greenfield-todo/. "$tmp"
    run bash scripts/pre-flight.sh "$tmp" todo-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$tmp/docs/larv/STATE.yaml" ]
    [ -f "$tmp/docs/larv/pre-flight.md" ]
    grep -q "skipped (LARV_PREFLIGHT_SKIP_DESIGN_CHECK=1)" "$tmp/docs/larv/pre-flight.md"

    run bash scripts/status.sh "$tmp"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "todo-app"

    run bash scripts/resume.sh "$tmp"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "phase 0"
    rm -rf "$tmp"
}

@test "existing-blog fixture is recognizable as Laravel" {
    [ -f tests/fixtures/existing-blog/composer.json ]
    run jq -r '.require | keys | .[]' tests/fixtures/existing-blog/composer.json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "laravel/framework"
}
