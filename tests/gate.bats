#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; bash scripts/state.sh init "$TMP" my-app greenfield; }
teardown() { teardown_tmp_project "$TMP"; }

@test "soft_gate prints summary and exits 0 (auto-continue)" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && soft_gate '$TMP' 0 discuss 'Phase 0 complete' 'docs/larv/00-discuss/product-brief.md'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Phase 0 complete"
    echo "$output" | grep -q "product-brief.md"
    echo "$output" | grep -qiE "auto-continue"
}

@test "soft_gate honors LARV_GATE_PAUSE env to require explicit input" {
    LARV_GATE_PAUSE=1 run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo continue | soft_gate '$TMP' 0 discuss 'Phase 0 complete' 'a.md'"
    [ "$status" -eq 0 ]
}

@test "hard_gate blocks until 'approved' is read on stdin" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo approved | hard_gate '$TMP' 7 'Provisioning ready'"
    [ "$status" -eq 0 ]
}

@test "hard_gate exits non-zero when input is anything other than 'approved'" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo nope | hard_gate '$TMP' 7 'Provisioning ready'"
    [ "$status" -ne 0 ]
}

@test "routing_menu accepts 'same-session' and updates STATE.yaml mode" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo same-session | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-same-session" ]
}

@test "routing_menu accepts 'subagents'" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo subagents | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-subagents" ]
}

@test "routing_menu accepts 'handoff' and exits the orchestrator" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo handoff | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "handed-off-external" ]
}

@test "routing_menu rejects an invalid choice" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/gate.sh && echo banana | routing_menu '$TMP'"
    [ "$status" -ne 0 ]
}
