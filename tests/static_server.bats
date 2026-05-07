#!/usr/bin/env bats

load helpers

setup() {
    PORT=$(awk 'BEGIN{srand(); print 30000 + int(rand()*10000)}')
    BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$BIN"
}

@test "static_server_compose_command produces a php -S command for a path" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 /srv/larv/x/mockups"
    [ "$status" -eq 0 ]
    [[ "$output" == *"php -S 0.0.0.0:8001"* ]]
    [[ "$output" == *"-t /srv/larv/x/mockups"* ]]
}

@test "static_server_url returns http url with VM host and port" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/vm.sh && source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_url 8001"
    [ "$status" -eq 0 ]
    [ "$output" = "http://31.220.79.31:8001" ]
}

@test "static_server_compose_command rejects empty arguments" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command '' /tmp/x"
    [ "$status" -ne 0 ]
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 ''"
    [ "$status" -ne 0 ]
}

@test "static_server_check_remote_deps uses ssh to require php tmux curl ss rsync" {
    cat > "$BIN/ssh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    *"command -v php"*command\ -v\ tmux*command\ -v\ curl*command\ -v\ ss*command\ -v\ rsync*) exit 0 ;;
    *) exit 1 ;;
esac
EOF
    chmod +x "$BIN/ssh"
    PATH="$BIN:$PATH" run bash -c "export LARV_RUNTIME_MODE=remote; source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_check_remote_deps user@example.test"
    [ "$status" -eq 0 ]
}

@test "static_server_check_remote_deps defaults to local runtime without ssh" {
    cat > "$BIN/php" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$BIN/tmux" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$BIN/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$BIN/ss" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$BIN/ssh" <<'EOF'
#!/usr/bin/env bash
exit 99
EOF
    chmod +x "$BIN/php" "$BIN/tmux" "$BIN/curl" "$BIN/ss" "$BIN/ssh"
    PATH="$BIN:$PATH" run bash -c "source $PROJECT_ROOT/scripts/lib/vm.sh && source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_check_remote_deps ignored"
    [ "$status" -eq 0 ]
}

@test "static_server_open_firewall fails when ufw command fails" {
    cat > "$BIN/ssh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$BIN/ssh"
    PATH="$BIN:$PATH" run bash -c "export LARV_RUNTIME_MODE=remote; source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_open_firewall user@example.test 9000"
    [ "$status" -ne 0 ]
}

@test "static_server_open_firewall confirms local ufw rule when ufw exists" {
    cat > "$BIN/ufw" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    allow) echo "$2" > "$LARV_TEST_UFW_RULE_FILE"; exit 0 ;;
    status) printf "%s ALLOW Anywhere\n" "$(cat "$LARV_TEST_UFW_RULE_FILE")"; exit 0 ;;
    *) exit 1 ;;
esac
EOF
    cat > "$BIN/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    chmod +x "$BIN/ufw" "$BIN/sudo"
    export LARV_TEST_UFW_RULE_FILE="$BATS_TEST_TMPDIR/ufw-rule"
    PATH="$BIN:$PATH" run bash -c "source $PROJECT_ROOT/scripts/lib/vm.sh && source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_open_firewall ignored 9000"
    [ "$status" -eq 0 ]
    [ "$(cat "$LARV_TEST_UFW_RULE_FILE")" = "9000/tcp" ]
}
