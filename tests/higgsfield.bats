#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    STUB_DIR="$(mktemp -d)"; export STUB_DIR
    export HOME="$STUB_DIR/home"; mkdir -p "$HOME"
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export LARV_HIGGSFIELD_BIN="$PROJECT_ROOT/tests/fixtures/higgsfield-stub.sh"
    . scripts/lib/design_tools.sh
    . scripts/lib/higgsfield.sh
    printf 'Desktop mockup of "PRS" — cost $5 `x`\nsecond line\n' >"$TMP/prompt.txt"
}

teardown() {
    teardown_tmp_project "$TMP"
    rm -rf "$STUB_DIR"
}

@test "hf_account_json and hf_credits read the account" {
    run hf_credits
    [ "$status" -eq 0 ]
    [ "$output" = "79" ]
    STUB_SIGNED_OUT=1 run hf_account_json
    [ "$status" -ne 0 ]
}

@test "hf_cost returns integer credits for nano_banana_pro 2k" {
    run hf_cost "$TMP/prompt.txt" 3:2
    [ "$output" = "2" ]
    grep -q -- "generate cost nano_banana_pro" "$STUB_DIR/hf.log"
    grep -q -- "--resolution 2k" "$STUB_DIR/hf.log"
    grep -q -- "--aspect_ratio 3:2" "$STUB_DIR/hf.log"
}

@test "hf_generate_comp passes prompt verbatim and writes the png" {
    run hf_generate_comp "$TMP/prompt.txt" 3:2 "$TMP/out/a.png"
    [ "$status" -eq 0 ]
    [ "$output" = "job-0" ]
    [ -s "$TMP/out/a.png" ]
    diff <(printf 'Desktop mockup of "PRS" — cost $5 `x`\nsecond line') "$STUB_DIR/last-prompt.txt"
}

@test "hf_generate_comp failure leaves no file" {
    STUB_FAIL_CREATE=1 run hf_generate_comp "$TMP/prompt.txt" 3:2 "$TMP/out/a.png"
    [ "$status" -ne 0 ]
    [ ! -e "$TMP/out/a.png" ]
}

@test "hf_generate_comp attaches a reference image when given" {
    printf 'png' >"$TMP/ref.png"
    run hf_generate_comp "$TMP/prompt.txt" 9:16 "$TMP/out/b.png" "$TMP/ref.png"
    [ "$status" -eq 0 ]
    grep -q -- "--image-references $TMP/ref.png" "$STUB_DIR/hf.log"
}

@test "library never calls auth token" {
    hf_credits >/dev/null
    hf_cost "$TMP/prompt.txt" 3:2 >/dev/null
    ! grep -q "auth token" "$STUB_DIR/hf.log"
}
