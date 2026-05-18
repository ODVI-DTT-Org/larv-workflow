#!/usr/bin/env bats

load helpers

setup() {
    TMP_PROJECT="$(setup_tmp_project)"
    export LARV_SANDBOX_OWNER_DIR="$TMP_PROJECT/owners"
    export LARV_PORT_RESERVATION_DIR="$TMP_PROJECT/port-reservations"
    mkdir -p "$TMP_PROJECT/docs/larv/07-runtime"
    mkdir -p "$TMP_PROJECT/docs/larv/03-design/mockups"
    mkdir -p "$TMP_PROJECT/docs/user-manual/testing"
    cat > "$TMP_PROJECT/docs/larv/STATE.yaml" <<'YAML'
project:
  name: Goal OS
  slug: goal-os
sandbox:
  app_url: http://31.220.79.31:9101
  database:
    name: larv_goal_os
YAML
    printf "http://31.220.79.31:9101\n" > "$TMP_PROJECT/docs/larv/07-runtime/sandbox-url.txt"
    printf "http://31.220.79.31:9501\n" > "$TMP_PROJECT/docs/larv/docsite-url.txt"
    printf "http://31.220.79.31:9401\n" > "$TMP_PROJECT/docs/larv/03-design/mockup-url.txt"
    cat > "$TMP_PROJECT/docs/user-manual/seed-data.md" <<'MD'
# Seed Data

## Test Credentials

| Role | Email | Password |
|---|---|---|
| CEO | sarah@example.test | password |
| Admin | admin@example.test | password |
MD
    cat > "$TMP_PROJECT/docs/user-manual/testing/slice-01.md" <<'MD'
# Slice 01 Testing

## What can be tested
- Navigate to the dashboard.
- Test role-scoped login.
MD
}

teardown() {
    teardown_tmp_project "$TMP_PROJECT"
    unset LARV_SANDBOX_OWNER_DIR LARV_PORT_RESERVATION_DIR LARV_TEST_SS_OUTPUT LARV_STARTED_PORTS LARV_DEPLOY_LOG
}

@test "sandbox info prints URLs credentials testing guides and succeeds when generated URLs are reachable" {
    local bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$bin"
    cat > "$bin/curl" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    chmod +x "$bin/curl"

    PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" info
    [ "$status" -eq 0 ]
    grep -q "Larv sandbox for Goal OS (goal-os)" <<<"$output"
    grep -q "App:.*http://31.220.79.31:9101.*ready" <<<"$output"
    grep -q "Docs:.*http://31.220.79.31:9501.*ready" <<<"$output"
    grep -q "Mockups:.*http://31.220.79.31:9401.*ready" <<<"$output"
    grep -q "Source: docs/user-manual/seed-data.md" <<<"$output"
    grep -q "sarah@example.test" <<<"$output"
    grep -q "docs/user-manual/testing/slice-01.md" <<<"$output"
    grep -q "All generated URLs are reachable." <<<"$output"
}

@test "sandbox info fails when a generated URL is down" {
    local bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$bin"
    cat > "$bin/curl" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *":9501"*) exit 7 ;;
  *) exit 0 ;;
esac
SH
    chmod +x "$bin/curl"

    PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" info
    [ "$status" -ne 0 ]
    grep -q "Docs:.*http://31.220.79.31:9501.*down" <<<"$output"
    grep -q "Run /larv:sandbox-start" <<<"$output"
}

@test "sandbox stop kills only project-scoped sessions" {
    local bin="$BATS_TEST_TMPDIR/bin" log="$BATS_TEST_TMPDIR/tmux.log"
    mkdir -p "$bin"
    mkdir -p "$LARV_SANDBOX_OWNER_DIR/app" "$LARV_SANDBOX_OWNER_DIR/docs" "$LARV_SANDBOX_OWNER_DIR/mockups"
    cat > "$LARV_SANDBOX_OWNER_DIR/app/9101" <<EOF
slug=goal-os
root=$TMP_PROJECT
kind=app
port=9101
session=larv-app-goal-os-9101
EOF
    cat > "$LARV_SANDBOX_OWNER_DIR/docs/9501" <<EOF
slug=goal-os
root=$TMP_PROJECT
kind=docs
port=9501
session=larv-docsite-goal-os-9501
EOF
    cat > "$LARV_SANDBOX_OWNER_DIR/mockups/9401" <<EOF
slug=goal-os
root=$TMP_PROJECT
kind=mockups
port=9401
session=larv-mockups-goal-os-9401
EOF
    cat > "$bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LARV_TMUX_LOG"
exit 0
SH
    chmod +x "$bin/tmux"

    LARV_TMUX_LOG="$log" PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" stop
    [ "$status" -eq 0 ]
    grep -q "Stopped larv sandbox sessions for goal-os." <<<"$output"
    grep -q "kill-session -t larv-app-goal-os-9101" "$log"
    grep -q "kill-session -t larv-docsite-goal-os-9501" "$log"
    grep -q "kill-session -t larv-mockups-goal-os-9401" "$log"
}

@test "sandbox stop does not kill unowned sessions from URL files alone" {
    local bin="$BATS_TEST_TMPDIR/bin" log="$BATS_TEST_TMPDIR/tmux.log"
    mkdir -p "$bin"
    cat > "$bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LARV_TMUX_LOG"
exit 0
SH
    chmod +x "$bin/tmux"

    LARV_TMUX_LOG="$log" PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" stop
    [ "$status" -eq 0 ]
    [ ! -s "$log" ]
}

@test "sandbox start reallocates foreign occupied ports and writes project-owned URLs" {
    local bin="$BATS_TEST_TMPDIR/bin" log="$BATS_TEST_TMPDIR/tmux.log" started="$BATS_TEST_TMPDIR/started-ports"
    mkdir -p "$bin"
    cat > "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh" <<'SH'
#!/usr/bin/env bash
printf 'APP_PORT=%s SESSION=%s PID_FILE=%s\n' "$APP_PORT" "$LARV_APP_SESSION" "$LARV_APP_PID_FILE" >> "$LARV_DEPLOY_LOG"
mkdir -p "$(dirname "$LARV_APP_PID_FILE")"
printf '%s\n' "$$" > "$LARV_APP_PID_FILE"
printf 'LISTEN 0 4096 0.0.0.0:%s\n' "$APP_PORT" >> "$LARV_STARTED_PORTS"
SH
    chmod +x "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh"
    cat > "$bin/curl" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$bin/sudo" <<'SH'
#!/usr/bin/env bash
exec "$@"
SH
    cat > "$bin/ufw" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$bin/ss" <<'SH'
#!/usr/bin/env bash
printf 'LISTEN 0 4096 0.0.0.0:9101\n'
printf 'LISTEN 0 4096 0.0.0.0:9501\n'
[ -f "$LARV_STARTED_PORTS" ] && cat "$LARV_STARTED_PORTS"
SH
    cat > "$bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LARV_TMUX_LOG"
exit 0
SH
    cat > "$bin/setsid" <<'SH'
#!/usr/bin/env bash
cmd="$*"
port="$(grep -oE '0\.0\.0\.0:[0-9]+' <<<"$cmd" | grep -oE '[0-9]+' | tail -1)"
[ -n "$port" ] && printf 'LISTEN 0 4096 0.0.0.0:%s\n' "$port" >> "$LARV_STARTED_PORTS"
exit 0
SH
    chmod +x "$bin/curl" "$bin/sudo" "$bin/ufw" "$bin/ss" "$bin/tmux" "$bin/setsid"

    LARV_TMUX_LOG="$log" LARV_STARTED_PORTS="$started" LARV_DEPLOY_LOG="$BATS_TEST_TMPDIR/deploy.log" PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" start
    [ "$status" -eq 0 ]
    grep -q "WARN: recorded app port 9101" <<<"$output"
    grep -q "WARN: recorded docs port 9501" <<<"$output"
    grep -q "APP_PORT=8000 SESSION=larv-app-goal-os-8000" "$BATS_TEST_TMPDIR/deploy.log"
    ! grep -q "new-session" "$log"
    grep -q "http://31.220.79.31:8000/" "$TMP_PROJECT/docs/larv/07-runtime/sandbox-url.txt"
    grep -q "http://31.220.79.31:9500/" "$TMP_PROJECT/docs/larv/docsite-url.txt"
    grep -q "slug=goal-os" "$LARV_SANDBOX_OWNER_DIR/app/8000"
    grep -q "session=larv-docsite-goal-os-9500" "$LARV_SANDBOX_OWNER_DIR/docs/9500"
}

@test "sandbox start honors user-requested app docs and mockup ports" {
    local bin="$BATS_TEST_TMPDIR/bin" log="$BATS_TEST_TMPDIR/tmux.log" started="$BATS_TEST_TMPDIR/started-requested"
    mkdir -p "$bin"
    cat > "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh" <<'SH'
#!/usr/bin/env bash
printf 'APP_PORT=%s SESSION=%s PID_FILE=%s\n' "$APP_PORT" "$LARV_APP_SESSION" "$LARV_APP_PID_FILE" >> "$LARV_DEPLOY_LOG"
mkdir -p "$(dirname "$LARV_APP_PID_FILE")"
printf '%s\n' "$$" > "$LARV_APP_PID_FILE"
printf 'LISTEN 0 4096 0.0.0.0:%s\n' "$APP_PORT" >> "$LARV_STARTED_PORTS"
SH
    chmod +x "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh"
    cat > "$bin/curl" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$bin/sudo" <<'SH'
#!/usr/bin/env bash
exec "$@"
SH
    cat > "$bin/ufw" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$bin/ss" <<'SH'
#!/usr/bin/env bash
[ -f "$LARV_STARTED_PORTS" ] && cat "$LARV_STARTED_PORTS"
SH
    cat > "$bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LARV_TMUX_LOG"
exit 0
SH
    cat > "$bin/setsid" <<'SH'
#!/usr/bin/env bash
cmd="$*"
port="$(grep -oE '0\.0\.0\.0:[0-9]+' <<<"$cmd" | grep -oE '[0-9]+' | tail -1)"
[ -n "$port" ] && printf 'LISTEN 0 4096 0.0.0.0:%s\n' "$port" >> "$LARV_STARTED_PORTS"
exit 0
SH
    chmod +x "$bin/curl" "$bin/sudo" "$bin/ufw" "$bin/ss" "$bin/tmux" "$bin/setsid"

    LARV_APP_PORT=8123 LARV_DOCS_PORT=9567 LARV_MOCKUPS_PORT=9123 \
        LARV_TMUX_LOG="$log" LARV_STARTED_PORTS="$started" LARV_DEPLOY_LOG="$BATS_TEST_TMPDIR/requested-deploy.log" PATH="$bin:$PATH" \
        run bash scripts/sandbox.sh "$TMP_PROJECT" start
    [ "$status" -eq 0 ]
    grep -q "APP_PORT=8123 SESSION=larv-app-goal-os-8123" "$BATS_TEST_TMPDIR/requested-deploy.log"
    grep -q "http://31.220.79.31:8123/" "$TMP_PROJECT/docs/larv/07-runtime/sandbox-url.txt"
    grep -q "http://31.220.79.31:9567/" "$TMP_PROJECT/docs/larv/docsite-url.txt"
    grep -q "http://31.220.79.31:9123/" "$TMP_PROJECT/docs/larv/03-design/mockup-url.txt"
    grep -q "port=8123" "$LARV_SANDBOX_OWNER_DIR/app/8123"
    grep -q "port=9567" "$LARV_SANDBOX_OWNER_DIR/docs/9567"
    grep -q "port=9123" "$LARV_SANDBOX_OWNER_DIR/mockups/9123"
}

@test "sandbox start rejects user-requested occupied port instead of reallocating" {
    local bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$bin"
    cat > "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    chmod +x "$TMP_PROJECT/docs/larv/07-runtime/deploy-sandbox.sh"
    cat > "$bin/ss" <<'SH'
#!/usr/bin/env bash
printf 'LISTEN 0 4096 0.0.0.0:8123\n'
SH
    chmod +x "$bin/ss"

    LARV_APP_PORT=8123 PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" start
    [ "$status" -ne 0 ]
    grep -q "requested app port 8123 is already in use" <<<"$output"
}
