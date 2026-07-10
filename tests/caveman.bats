#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    FAKE_CAVEMAN_DIR="$(mktemp -d)"
    FAKE_CAVEMAN_BIN="$FAKE_CAVEMAN_DIR/caveman"
    printf '#!/usr/bin/env bash\nexit 0\n' >"$FAKE_CAVEMAN_BIN"
    chmod +x "$FAKE_CAVEMAN_BIN"
    export LARV_CAVEMAN_BIN="$FAKE_CAVEMAN_BIN"
    bash scripts/state.sh init "$TMP" my-app greenfield
}

teardown() {
    unset LARV_CAVEMAN_BIN
    rm -rf "$FAKE_CAVEMAN_DIR"
    teardown_tmp_project "$TMP"
}

@test "caveman resolve follows explicit override before session state" {
    bash scripts/state.sh set-caveman-style "$TMP" lite
    run bash scripts/caveman.sh resolve "$TMP" full larv-full
    [ "$status" -eq 0 ]
    echo "$output" | tail -n 1 | grep -q "^full$"
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "lite" ]
}

@test "caveman resolve returns session state and does not mutate on explicit normal override" {
    bash scripts/state.sh set-caveman-style "$TMP" lite
    run bash scripts/caveman.sh resolve "$TMP" normal larv-full
    [ "$status" -eq 0 ]
    [ "$output" = "lite" ]
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "lite" ]
}

@test "caveman set/clear off and normal return to strict full" {
    bash scripts/state.sh set-caveman-style "$TMP" ultra
    bash scripts/state.sh set-caveman-style "$TMP" off
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "full" ]
    bash scripts/state.sh set-caveman-style "$TMP" lite
    bash scripts/state.sh clear-caveman-style "$TMP"
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "full" ]
}

@test "caveman fallback can be explicitly relaxed for deterministic compatibility" {
    bash scripts/state.sh set-caveman-style "$TMP" full
    run bash -c "LARV_CAVEMAN_STRICT=0 LARV_CAVEMAN_BIN=__missing_caveman_mode__ bash scripts/caveman.sh resolve \"$TMP\" full larv-full"
    [ "$status" -eq 0 ]
    echo "$output" | tail -n 1 | grep -q "^normal$"
    echo "$output" | grep -q "Caveman full requested"
}

@test "caveman status exposes session and effective modes" {
    bash scripts/state.sh set-caveman-style "$TMP" normal
    run bash scripts/caveman.sh status "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "session-style="
    echo "$output" | grep -q "effective-style="
}

@test "caveman defaults to full and marks strict mode" {
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$status" -eq 0 ]
    [ "$output" = "full" ]

    run bash scripts/caveman.sh status "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "session-style=full"
    echo "$output" | grep -q "strict=1"
}

@test "bundled Caveman binary satisfies strict full mode by default" {
    unset LARV_CAVEMAN_BIN

    run bash scripts/caveman.sh status "$TMP"

    [ "$status" -eq 0 ]
    echo "$output" | grep -q "effective-style=full"
    echo "$output" | grep -q "strict=1"
}

@test "caveman strict mode fails instead of silently downgrading full when dependency is missing" {
    run bash -c "LARV_CAVEMAN_BIN=__missing_caveman_mode__ bash scripts/caveman.sh resolve \"$TMP\" full larv-full"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "Caveman full requested"
    echo "$output" | grep -q "strict mode"
}

@test "resolve-command allows Caveman only for allowlisted commands" {
    bash scripts/state.sh set-caveman-style "$TMP" full
    run bash scripts/caveman.sh resolve-command "$TMP" larv-full "Caveman full"
    [ "$status" -eq 0 ]
    [ "$output" = "full" ]
    run bash scripts/caveman.sh resolve-command "$TMP" larv-adopt "Caveman full"
    [ "$status" -eq 0 ]
    [ "$output" = "normal" ]
}

@test "resolve supports optional command guard in third argument" {
    bash scripts/state.sh set-caveman-style "$TMP" full
    run bash scripts/caveman.sh resolve "$TMP" "Caveman full" "larv-full"
    [ "$status" -eq 0 ]
    [ "$output" = "full" ]
    run bash scripts/caveman.sh resolve "$TMP" "Caveman full" "larv-adopt"
    [ "$status" -eq 0 ]
    [ "$output" = "normal" ]
}

@test "resolve-command parses one-shot text overrides without mutating session mode" {
    bash scripts/state.sh set-caveman-style "$TMP" lite
    run bash scripts/caveman.sh resolve-command "$TMP" larv-feature "Caveman ultra please"
    [ "$status" -eq 0 ]
    [ "$output" = "ultra" ]
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "lite" ]
}

@test "allowlist reflects custom allowlist override" {
    run bash -c "LARV_CAVEMAN_ALLOWLIST='full,feature' bash scripts/caveman.sh allowlist"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Caveman allowlist:"
    echo "$output" | grep -q "Source: LARV_CAVEMAN_ALLOWLIST override"
    echo "$output" | grep -q "  - full"
    echo "$output" | grep -q "  - feature"
}

@test "resolve without explicit command context falls back to normal" {
    bash scripts/state.sh set-caveman-style "$TMP" full
    run bash scripts/caveman.sh resolve "$TMP" full
    [ "$status" -eq 0 ]
    [ "$output" = "normal" ]
}

@test "resolve-command follows explicit command-only override without mutating session mode" {
    bash scripts/state.sh set-caveman-style "$TMP" lite
    run bash scripts/caveman.sh resolve-command "$TMP" feature "Caveman ultra please"
    [ "$status" -eq 0 ]
    [ "$output" = "ultra" ]
    run bash scripts/state.sh get-caveman-style "$TMP"
    [ "$output" = "lite" ]
}
