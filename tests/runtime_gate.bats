#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "runtime_gate validates expected VM URL" {
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_validate_url 'http://31.220.79.31:9000/'"
    [ "$status" -eq 0 ]
}

@test "runtime_gate rejects missing placeholder and wrong host URLs" {
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_validate_url ''"
    [ "$status" -ne 0 ]
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_validate_url 'TBD'"
    [ "$status" -ne 0 ]
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_validate_url 'http://127.0.0.1:9000/'"
    [ "$status" -ne 0 ]
}

@test "runtime_gate requires phase URL artifacts" {
    mkdir -p "$TMP/docs/larv/03-design" "$TMP/docs/larv/07-runtime"
    printf "http://31.220.79.31:9000/\n" > "$TMP/docs/larv/03-design/mockup-url.txt"
    printf "http://31.220.79.31:9500/\n" > "$TMP/docs/larv/docsite-url.txt"
    printf "http://31.220.79.31:8000/\n" > "$TMP/docs/larv/07-runtime/sandbox-url.txt"

    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_require_phase_url '$TMP' design"
    [ "$status" -eq 0 ]
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_require_phase_url '$TMP' docsite"
    [ "$status" -eq 0 ]
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_require_phase_url '$TMP' sandbox"
    [ "$status" -eq 0 ]
}

@test "runtime_gate fails when artifact is absent" {
    run bash -c "source scripts/lib/runtime_gate.sh && runtime_gate_require_phase_url '$TMP' design"
    [ "$status" -ne 0 ]
}
