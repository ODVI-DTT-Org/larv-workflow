#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(mktemp -d)"
}

teardown() {
    [ -n "$TMP" ] && [ -d "$TMP" ] && rm -rf "$TMP"
}

generate_project() {
    bash scripts/simulate-full.sh "$TMP/project" "Contract Pilot" >/dev/null
}

rerender_contracts() {
    (
        cd "$TMP/project"
        source "$PROJECT_ROOT/scripts/lib/handsoff.sh"
        handsoff_render_index "."
        handsoff_render_starting_points "."
    )
}

@test "check-dox-contracts passes on valid generated fixture" {
    generate_project

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -eq 0 ]
    grep -q "DOX contract check passed" <<<"$output"
}

@test "check-dox-contracts passes when runtime URL, Handsoff, root AGENTS, and STATE agree" {
    generate_project
    printf "http://46.250.229.188:25000/admin\n" > "$TMP/project/docs/larv/07-runtime/sandbox-url.txt"
    yq -i '.sandbox.app_url = "http://46.250.229.188:25000/"' "$TMP/project/docs/larv/STATE.yaml"
    rerender_contracts

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -eq 0 ]
    grep -q "DOX contract check passed" <<<"$output"
}

@test "check-dox-contracts fails on stale runtime host leakage" {
    generate_project
    printf "http://46.250.229.188:25000/admin\n" > "$TMP/project/docs/larv/07-runtime/sandbox-url.txt"

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -ne 0 ]
    grep -q "does not mention runtime host" <<<"$output"
}

@test "check-dox-contracts fails on STATE runtime disagreement" {
    generate_project
    printf "http://46.250.229.188:25000/admin\n" > "$TMP/project/docs/larv/07-runtime/sandbox-url.txt"
    yq -i '.sandbox.app_url = "http://203.0.113.55:25000/"' "$TMP/project/docs/larv/STATE.yaml"
    rerender_contracts

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -ne 0 ]
    grep -q "disagrees with sandbox-url.txt" <<<"$output"
}

@test "check-dox-contracts fails on unresolved template token" {
    generate_project
    printf "\n{{unresolved_token}}\n" >> "$TMP/project/AGENTS.md"

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -ne 0 ]
    grep -q "unresolved template token" <<<"$output"
}

@test "check-dox-contracts fails on model-specific wording" {
    generate_project
    printf "\nUse Opus for this step.\n" >> "$TMP/project/AGENTS.md"

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -ne 0 ]
    grep -q "model-specific wording" <<<"$output"
}

@test "check-dox-contracts fails on raw TBD placeholders" {
    generate_project
    printf "\n_(API surface TBD)_\n" >> "$TMP/project/AGENTS.md"

    run bash scripts/check-dox-contracts.sh "$TMP/project"

    [ "$status" -ne 0 ]
    grep -q "raw TBD placeholder" <<<"$output"
}
