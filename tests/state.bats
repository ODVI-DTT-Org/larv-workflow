#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
}

teardown() {
    teardown_tmp_project "$TMP"
}

@test "state init creates STATE.yaml with schema_version 1" {
    run bash scripts/state.sh init "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/STATE.yaml" ]
    run yq -r '.schema_version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "1" ]
}

@test "state init sets project name and slug" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run yq -r '.project.name' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "my-app" ]
    run yq -r '.project.slug' "$TMP/docs/larv/STATE.yaml"
    [[ "$output" =~ ^my-app-[0-9]{4}-[0-9]{2}$ ]]
}

@test "state init slugifies human project names safely" {
    bash scripts/state.sh init "$TMP" "Loan Approval System!" greenfield
    run yq -r '.project.name' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "Loan Approval System!" ]
    run yq -r '.project.slug' "$TMP/docs/larv/STATE.yaml"
    [[ "$output" =~ ^loan-approval-system-[0-9]{4}-[0-9]{2}$ ]]
    [[ "$output" != *" "* ]]
}

@test "state init safely quotes project names with punctuation" {
    bash scripts/state.sh init "$TMP" 'Loan "VIP" Approval: System' greenfield
    run yq -r '.project.name' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = 'Loan "VIP" Approval: System' ]
    run yq -r '.project.slug' "$TMP/docs/larv/STATE.yaml"
    [[ "$output" =~ ^loan-vip-approval-system-[0-9]{4}-[0-9]{2}$ ]]
}

@test "state init refuses to overwrite existing STATE.yaml" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run bash scripts/state.sh init "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
}

@test "state init in adopted mode sets greenfield: false" {
    bash scripts/state.sh init "$TMP" existing-blog adopted
    run yq -r '.project.greenfield' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "false" ]
    run yq -r '.project.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "adopted" ]
}

@test "state init records current plugin version" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    local expected
    expected="$(yq -r '.version' .claude-plugin/plugin.json)"
    run yq -r '.plugin.version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "$expected" ]
}

@test "state read returns the YAML" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/state.sh read "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "schema_version: 1"
}

@test "state read fails when STATE.yaml is missing" {
    run bash scripts/state.sh read "$TMP"
    [ "$status" -ne 0 ]
}

@test "state update merges patch atomically" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/state.sh update "$TMP" '.phase.current = 0 | .phase.last_completed = -1'
    [ "$status" -eq 0 ]
    run yq -r '.phase.current' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.phase.last_completed' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "-1" ]
}

@test "state update bumps last_updated_at" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    local before
    before="$(yq -r '.project.last_updated_at' "$TMP/docs/larv/STATE.yaml")"
    sleep 1
    bash scripts/state.sh update "$TMP" '.phase.current = 0'
    local after
    after="$(yq -r '.project.last_updated_at' "$TMP/docs/larv/STATE.yaml")"
    [ "$after" != "$before" ]
}

@test "budget cap policy returns correct threshold for default" {
    run bash -c 'source scripts/lib/budget.sh && budget_cap_threshold pause_at_120pct'
    [ "$status" -eq 0 ]
    [ "$output" = "1.20" ]
}

@test "budget cap policy returns correct threshold for never_pause" {
    run bash -c 'source scripts/lib/budget.sh && budget_cap_threshold never_pause'
    [ "$status" -eq 0 ]
    [ "$output" = "999" ]
}
