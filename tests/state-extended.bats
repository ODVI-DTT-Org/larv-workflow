#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "state init seeds execution.mode, allocations, features, debugs" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run yq -r '.execution.mode // "missing"' "$TMP/docs/larv/STATE.yaml"
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
