#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    STUB_DIR="$(mktemp -d)"; export STUB_DIR
    BIN_DIR="$STUB_DIR/bin"; mkdir -p "$BIN_DIR"
    export HOME="$STUB_DIR/home"; mkdir -p "$HOME"
    export PATH="$BIN_DIR:/usr/local/bin:/usr/bin:/bin"
    export LARV_HIGGSFIELD_BIN="$PROJECT_ROOT/tests/fixtures/higgsfield-stub.sh"
    export LARV_IMPECCABLE_SKILL_DIR="$PROJECT_ROOT/tests/fixtures/impeccable-launcher-stub"
    export LARV_VM_HOST=203.0.113.10
}

teardown() {
    teardown_tmp_project "$TMP"
    rm -rf "$STUB_DIR"
}

@test "check exits 0 when everything is ready and prints account without secrets" {
    run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok: higgsfield dtt@oakdriveventures.com (lite, 79 credits)"* ]]
    [[ "$output" == *"ok: impeccable engine"* ]]
    [[ "$output" == *"ok: public host 203.0.113.10"* ]]
    ! grep -q "auth token" "$STUB_DIR/hf.log"
}

@test "check exits 3 when Higgsfield is signed out" {
    STUB_SIGNED_OUT=1 run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 3 ]
    [[ "$output" == *"fallback: higgsfield not signed in"* ]]
    [[ "$output" == *"higgsfield auth login"* ]]
}

@test "check exits 3 when credits are below the cap" {
    STUB_CREDITS=4 run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 3 ]
    [[ "$output" == *"fallback: 4 credits left (cap 10)"* ]]
}

@test "check exits 3 when the credit balance is not a whole number" {
    STUB_CREDITS=12.5 run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 3 ]
    [[ "$output" == *"fallback"* ]]
    [[ "$output" != *"ok: higgsfield"* ]]
}

@test "check exits 3 when Higgsfield is not installed" {
    export LARV_HIGGSFIELD_BIN="$STUB_DIR/none"
    run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 3 ]
    [[ "$output" == *"fallback: higgsfield not installed"* ]]
}

@test "check exits 1 without an Impeccable launcher" {
    export LARV_IMPECCABLE_SKILL_DIR="$STUB_DIR/none"
    run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing: impeccable skill"* ]]
}

@test "check exits 1 without a public host" {
    printf '#!/bin/sh\necho ""\n' >"$BIN_DIR/hostname"; chmod +x "$BIN_DIR/hostname"
    export LARV_VM_HOST=sandbox.example.com
    run bash scripts/design-setup.sh check "$TMP"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing: public host"* ]]
}

@test "install refuses unknown platforms" {
    export LARV_HIGGSFIELD_BIN=""
    LARV_DESIGN_SETUP_UNAME="Darwin arm64" run bash scripts/design-setup.sh install
    [ "$status" -eq 1 ]
    [[ "$output" == *"no pinned Higgsfield checksum for Darwin arm64"* ]]
    [ ! -e "$HOME/.local/share/larv/higgsfield/higgsfield" ]
}

@test "install refuses a checksum mismatch and leaves nothing behind" {
    export LARV_HIGGSFIELD_BIN=""
    printf 'not the real archive' >"$STUB_DIR/bogus.tgz"
    LARV_DESIGN_SETUP_UNAME="Linux x86_64" LARV_HIGGSFIELD_ARCHIVE_URL="file://$STUB_DIR/bogus.tgz" \
        run bash scripts/design-setup.sh install
    [ "$status" -eq 1 ]
    [[ "$output" == *"checksum mismatch"* ]]
    [ ! -e "$HOME/.local/share/larv/higgsfield" ]
}

@test "install fails cleanly when the archive has no hf binary, even if checksum matches" {
    export LARV_HIGGSFIELD_BIN=""
    printf 'not-a-cli' >"$STUB_DIR/decoy"
    tar -czf "$STUB_DIR/no-hf.tgz" -C "$STUB_DIR" decoy
    local sha
    sha="$(sha256sum "$STUB_DIR/no-hf.tgz" | awk '{print $1}')"
    LARV_DESIGN_SETUP_UNAME="Linux x86_64" LARV_HIGGSFIELD_ARCHIVE_URL="file://$STUB_DIR/no-hf.tgz" \
        LARV_HIGGSFIELD_SHA256="$sha" run bash scripts/design-setup.sh install
    [ "$status" -eq 1 ]
    [[ "$output" == *"Higgsfield install incomplete"* ]]
    [ ! -e "$HOME/.local/share/larv/higgsfield" ]
}

@test "install is a no-op report when already installed and never signs in" {
    mkdir -p "$HOME/.local/share/larv/higgsfield"
    cp tests/fixtures/higgsfield-stub.sh "$HOME/.local/share/larv/higgsfield/higgsfield"
    export LARV_HIGGSFIELD_BIN=""
    run bash scripts/design-setup.sh install
    [[ "$output" == *"ok: higgsfield already installed"* ]]
    ! grep -q "auth login" "$STUB_DIR/hf.log"
}
