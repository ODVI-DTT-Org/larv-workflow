#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "state init seeds execution.mode, allocations, features, debugs" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run yq -r '.execution.mode // "missing"' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "not-yet-decided" ]
    run yq -r '.execution.review_mode // "missing"' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "not-yet-decided" ]
    run yq -r '.execution.allocations | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.features | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.debugs | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
}

@test "state set-mode writes a valid execution mode" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh set-mode "$TMP" executing-subagents
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-subagents" ]
}

@test "state set-mode rejects an invalid mode" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run bash scripts/state.sh set-mode "$TMP" not-a-real-mode
    [ "$status" -ne 0 ]
}

@test "state set-review-mode writes a valid review cadence" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh set-review-mode "$TMP" manual-slice
    run yq -r '.execution.review_mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "manual-slice" ]
}

@test "state set-review-mode rejects an invalid review cadence" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run bash scripts/state.sh set-review-mode "$TMP" chaos
    [ "$status" -ne 0 ]
}

@test "state record-allocation appends to execution.allocations" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh record-allocation "$TMP" mockup-port 9001
    bash scripts/state.sh record-allocation "$TMP" app-port 8001
    run yq -r '.execution.allocations | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "2" ]
    run yq -r '.execution.allocations[0].kind' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "mockup-port" ]
    run yq -r '.execution.allocations[0].value' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "9001" ]
}

@test "caveman style helpers persist and clear session mode" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh set-caveman-style "$TMP" full
    run yq -r '.execution.caveman_style' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "full" ]
    bash scripts/state.sh set-caveman-style "$TMP" off
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "normal" ]
    bash scripts/state.sh clear-caveman-style "$TMP"
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "normal" ]
}

@test "state caveman helper normalizes off/normal aliases" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh set-caveman-style "$TMP" normal
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "normal" ]
}
