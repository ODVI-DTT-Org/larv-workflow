#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    BIN="$TMP/bin"
    mkdir -p "$BIN"
    # fake ssh that prints a deterministic "ss -tlnp" result based on env
    cat >"$BIN/ssh" <<'EOF'
#!/usr/bin/env bash
# Returns the contents of $LARV_TEST_SS_OUTPUT for any command containing 'ss -tlnp'
# Returns the contents of $LARV_TEST_LS_OUTPUT for any command containing 'ls /srv/larv'
case "$*" in
    *"ss -tlnp"*)  printf "%s\n" "${LARV_TEST_SS_OUTPUT:-}" ;;
    *"ls /srv/larv"*) printf "%s\n" "${LARV_TEST_LS_OUTPUT:-}" ;;
    *"SHOW DATABASES"*) printf "%s\n" "${LARV_TEST_DB_OUTPUT:-}" ;;
esac
EOF
    chmod +x "$BIN/ssh"
    PATH_ORIG="$PATH"
    export PATH="$BIN:$PATH_ORIG"
}

teardown() {
    teardown_tmp_project "$TMP"
    export PATH="${PATH_ORIG:-$PATH}"
}

@test "allocate_port returns first port in range when nothing is in use" {
    LARV_TEST_SS_OUTPUT="" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port mockup"
    [ "$status" -eq 0 ]
    [ "$output" = "9000" ]
}

@test "allocate_port skips occupied ports and picks first free" {
    LARV_TEST_SS_OUTPUT="LISTEN 0 4096 0.0.0.0:9000 0.0.0.0:* users:((\"a\",pid=1,fd=1))
LISTEN 0 4096 0.0.0.0:9001 0.0.0.0:* users:((\"a\",pid=1,fd=1))" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port mockup"
    [ "$status" -eq 0 ]
    [ "$output" = "9002" ]
}

@test "allocate_port supports the app range (8000-8999)" {
    LARV_TEST_SS_OUTPUT="LISTEN 0 4096 0.0.0.0:8000" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port app"
    [ "$status" -eq 0 ]
    [ "$output" = "8001" ]
}

@test "allocate_port supports the docsite range (9500-9999)" {
    LARV_TEST_SS_OUTPUT="" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port docsite"
    [ "$status" -eq 0 ]
    [ "$output" = "9500" ]
}

@test "allocate_port rejects an unknown role" {
    run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port unknown"
    [ "$status" -ne 0 ]
}

@test "allocate_port fails when the entire range is occupied" {
    # generate output with every port in 9000-9499 as LISTEN
    local listen
    listen=$(seq 9000 9499 | awk '{print "LISTEN 0 4096 0.0.0.0:"$1}')
    LARV_TEST_SS_OUTPUT="$listen" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_port mockup"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "exhausted"
}

@test "allocate_project_root returns /srv/larv/<slug> when free" {
    LARV_TEST_LS_OUTPUT="other-project" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_project_root my-app-2026-05"
    [ "$status" -eq 0 ]
    [ "$output" = "/srv/larv/my-app-2026-05" ]
}

@test "allocate_project_root rejects when slug is already taken" {
    LARV_TEST_LS_OUTPUT="my-app-2026-05" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_project_root my-app-2026-05"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "taken"
}

@test "allocate_db returns normalized db name when free" {
    LARV_TEST_DB_OUTPUT="mysql information_schema" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_db my-app-2026-05"
    [ "$status" -eq 0 ]
    [ "$output" = "larv_my_app_2026_05" ]
}

@test "allocate_db rejects when database already exists" {
    LARV_TEST_DB_OUTPUT="larv_my_app_2026_05" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && allocate_db my-app-2026-05"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "already exists"
}

@test "verify_allocation returns success when port is still free" {
    LARV_TEST_SS_OUTPUT="LISTEN 0 4096 0.0.0.0:9000" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && verify_allocation 9001 mockup"
    [ "$status" -eq 0 ]
}

@test "verify_allocation returns non-zero when port is taken" {
    LARV_TEST_SS_OUTPUT="LISTEN 0 4096 0.0.0.0:9001" \
        run bash -c "source scripts/lib/vm.sh && source scripts/lib/verifier.sh && verify_allocation 9001 mockup"
    [ "$status" -ne 0 ]
}
