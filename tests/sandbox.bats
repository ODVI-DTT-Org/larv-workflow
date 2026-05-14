#!/usr/bin/env bats

load helpers

setup() {
    TMP_PROJECT="$(setup_tmp_project)"
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
    cat > "$bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LARV_TMUX_LOG"
exit 0
SH
    chmod +x "$bin/tmux"

    LARV_TMUX_LOG="$log" PATH="$bin:$PATH" run bash scripts/sandbox.sh "$TMP_PROJECT" stop
    [ "$status" -eq 0 ]
    grep -q "Stopped larv sandbox sessions for goal-os." <<<"$output"
    grep -q "kill-session -t larv-app-9101" "$log"
    grep -q "kill-session -t larv-docsite-goal-os" "$log"
    grep -q "kill-session -t larv-docsite-goal-os-9501" "$log"
    grep -q "kill-session -t larv-mockups-goal-os" "$log"
    grep -q "kill-session -t larv-mockups-goal-os-9401" "$log"
}
