#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    BIN_DIR="$(mktemp -d)"
    FAKE_HOME="$(mktemp -d)"
    export HOME="$FAKE_HOME"
    export PATH="$BIN_DIR:/usr/local/bin:/usr/bin:/bin"
    unset LARV_HIGGSFIELD_BIN LARV_IMPECCABLE_SKILL_DIR LARV_VM_HOST
    . scripts/lib/design_tools.sh
}

teardown() {
    teardown_tmp_project "$TMP"
    rm -rf "$BIN_DIR" "$FAKE_HOME"
}

make_exec() { mkdir -p "$(dirname "$1")"; printf '#!/bin/sh\nexit 0\n' >"$1"; chmod +x "$1"; }

@test "design_higgsfield_bin prefers LARV_HIGGSFIELD_BIN and does not fall back when it is missing" {
    make_exec "$FAKE_HOME/.local/share/larv/higgsfield/higgsfield"
    export LARV_HIGGSFIELD_BIN="$BIN_DIR/nope"
    run design_higgsfield_bin
    [ "$status" -eq 1 ]
    make_exec "$BIN_DIR/nope"
    run design_higgsfield_bin
    [ "$output" = "$BIN_DIR/nope" ]
}

@test "design_higgsfield_bin finds the shared install, then PATH" {
    run design_higgsfield_bin
    [ "$status" -eq 1 ]
    make_exec "$BIN_DIR/higgsfield"
    run design_higgsfield_bin
    [ "$output" = "$BIN_DIR/higgsfield" ]
    make_exec "$FAKE_HOME/.local/share/larv/higgsfield/higgsfield"
    run design_higgsfield_bin
    [ "$output" = "$FAKE_HOME/.local/share/larv/higgsfield/higgsfield" ]
}

@test "design_impeccable_launcher resolution order" {
    export LARV_IMPECCABLE_SKILL_DIR="$BIN_DIR/skill"
    run design_impeccable_launcher
    [ "$status" -eq 1 ]
    make_exec "$BIN_DIR/skill/scripts/impeccable"
    run design_impeccable_launcher
    [ "$output" = "$BIN_DIR/skill/scripts/impeccable" ]
    unset LARV_IMPECCABLE_SKILL_DIR
    run design_impeccable_launcher
    # bundle/impeccable exists after Task 6; before that the home copies are used
    [ "$status" -eq 0 ] || [ ! -d bundle/impeccable ]
}

@test "design_public_host uses LARV_VM_HOST when real" {
    export LARV_VM_HOST=46.250.229.188
    run design_public_host
    [ "$output" = "46.250.229.188" ]
}

@test "design_public_host replaces the placeholder with hostname -I" {
    printf '#!/bin/sh\necho "10.9.8.7 fe80::1"\n' >"$BIN_DIR/hostname"; chmod +x "$BIN_DIR/hostname"
    export LARV_VM_HOST=sandbox.example.com
    run design_public_host
    [ "$output" = "10.9.8.7" ]
}

@test "design_public_host refuses localhost, loopback and empty" {
    printf '#!/bin/sh\necho ""\n' >"$BIN_DIR/hostname"; chmod +x "$BIN_DIR/hostname"
    for h in localhost 127.0.0.1 sandbox.example.com ""; do
        export LARV_VM_HOST="$h"
        run design_public_host
        [ "$status" -eq 1 ] || { echo "accepted '$h'"; return 1; }
    done
}

@test "design_slug reads STATE.yaml, else sanitized basename" {
    mkdir -p "$TMP/My App_v2"
    run design_slug "$TMP/My App_v2"
    [ "$output" = "my-app-v2" ]
    printf 'project:\n  slug: prs-portal\n' >"$TMP/docs/larv/STATE.yaml"
    run design_slug "$TMP"
    [ "$output" = "prs-portal" ]
}
