# larv plugin MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the larv plugin's MVP — gates, mandatory self-contained handsoff, live-scan verifier with probe-before-announce, auto-commit policy, implementation tracker, AI starting-point files, and `/larv:feature` + `/larv:debug` parity — by filling in existing skill stubs and adding shared shell libraries, with bats coverage for every library function.

**Architecture:** Logic lives in `scripts/lib/*.sh` shared libraries; skills (`SKILL.md`) are thin orchestration prompts that source those libraries. STATE.yaml gains `mode`, `allocations`, `features`, `debugs` fields. Handsoff documents inline every action a foreign AI must take so all execution venues (same-session, subagents, foreign AI) read the same artifact.

**Tech Stack:** bash 5+, bats-core for tests, yq for YAML manipulation, ssh + curl for VM probes, git for commits. No Python, no Node (Layer 2 will add `npx docsify-cli`).

**Spec reference:** `docs/superpowers/specs/2026-05-06-larv-plugin-overhaul-design.md`. MVP scope is §22.1.

---

## File Structure

**New shared libraries (under `scripts/lib/`):**

| File | Responsibility |
|---|---|
| `vm.sh` | Single source of truth for `LARV_VM_HOST=31.220.79.31` |
| `probe.sh` | `probe_url_inside`, `probe_url_outside`, `probe_with_retries` per service profile |
| `verifier.sh` | Live-scan ports/DBs/project-roots over SSH; allocate with auto-pick on conflict |
| `git_safe.sh` | Default-branch detection, dirty-path guard, push-protected fallback to `larv/<slug>` |
| `tracker.sh` | `tracker_init`, `tracker_append`, `tracker_render` (yaml ↔ md) |
| `handsoff.sh` | Generate `docs/Handsoff.md` + per-slice handsoffs + AI starting-points |
| `gate.sh` | `soft_gate`, `hard_gate`, `routing_menu` UX |

**Templates (under `templates/`):**

| File | Used by |
|---|---|
| `handsoff-index.md.tmpl` | `handsoff_render_index` |
| `handsoff-slice.md.tmpl` | `handsoff_render_slice` |
| `ai-starting-point.md.tmpl` | `handsoff_render_starting_points` (one body, multiple destinations) |
| `tracker.yaml.tmpl` | `tracker_init` (initial yaml shape) |
| `routing-menu.md.tmpl` | `routing_menu` |

**Modified scripts:**

- `scripts/state.sh` — add `mode`, `allocations`, `features`, `debugs` fields to the init template; new `cmd_set_mode`, `cmd_record_allocation` subcommands.

**Skills filled in (existing stubs at `skills/<name>/SKILL.md`):**

| Skill | Becomes |
|---|---|
| `larv-orchestrator` | Real dispatcher: per-phase soft gate → hard gate before Phase 7 → routing menu before Phase 8 |
| `larv-provision` | Verifier-driven allocation, probe-before-announce, runbook generation |
| `larv-handoff` | Calls `handsoff.sh` to write index + per-slice + AI starting-points + tracker init |
| `larv-implement` | Thin loop: read `docs/Handsoff/slice-NN-*.md`, execute its inline bash, soft-gate per slice |

**Commands updated:**

- `commands/larv-feature.md` — invoke orchestrator in feature mode with mini-flow phase list
- `commands/larv-debug.md` — invoke orchestrator in debug mode with mini-flow phase list

**Tests added (under `tests/`):**

`vm.bats` · `probe.bats` · `verifier.bats` · `git_safe.bats` · `tracker.bats` · `handsoff.bats` · `gate.bats` · `state-extended.bats` · `orchestrator-flow.bats`

---

## Task 1: VM constant module

**Files:**
- Create: `scripts/lib/vm.sh`
- Create: `tests/vm.bats`

- [ ] **Step 1.1: Write the failing test**

Create `tests/vm.bats`:

```bash
#!/usr/bin/env bats

load helpers

@test "vm.sh exports LARV_VM_HOST as 31.220.79.31" {
    run bash -c 'source scripts/lib/vm.sh && echo "$LARV_VM_HOST"'
    [ "$status" -eq 0 ]
    [ "$output" = "31.220.79.31" ]
}

@test "vm.sh sets LARV_VM_HOST_SSH_USER to a non-empty string" {
    run bash -c 'source scripts/lib/vm.sh && echo "$LARV_VM_HOST_SSH_USER"'
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "vm.sh allows override via environment" {
    run bash -c 'export LARV_VM_HOST=10.0.0.1; source scripts/lib/vm.sh && echo "$LARV_VM_HOST"'
    [ "$status" -eq 0 ]
    [ "$output" = "10.0.0.1" ]
}
```

- [ ] **Step 1.2: Run the test to verify it fails**

Run: `bats tests/vm.bats`
Expected: FAIL with "scripts/lib/vm.sh: No such file or directory"

- [ ] **Step 1.3: Implement `scripts/lib/vm.sh`**

Create `scripts/lib/vm.sh`:

```bash
#!/usr/bin/env bash
# VM connection constants for larv. Single point of change for future
# generalization (multi-VM support is out of scope for MVP).

: "${LARV_VM_HOST:=31.220.79.31}"
: "${LARV_VM_HOST_SSH_USER:=larv}"
: "${LARV_VM_PROJECT_ROOT:=/srv/larv}"

export LARV_VM_HOST LARV_VM_HOST_SSH_USER LARV_VM_PROJECT_ROOT
```

- [ ] **Step 1.4: Run the test to verify it passes**

Run: `bats tests/vm.bats`
Expected: 3 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add scripts/lib/vm.sh tests/vm.bats
git commit -m "feat(lib): add vm.sh with LARV_VM_HOST constant"
```

---

## Task 2: Probe library (probe-before-announce)

**Files:**
- Create: `scripts/lib/probe.sh`
- Create: `tests/probe.bats`

- [ ] **Step 2.1: Write the failing test**

Create `tests/probe.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    PORT=$(awk 'BEGIN{srand(); print 30000 + int(rand()*10000)}')
    # spawn a simple HTTP server in background
    python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 0.5
}

teardown() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

@test "probe_url succeeds against a live HTTP server" {
    run bash -c "source scripts/lib/probe.sh && probe_url 'http://127.0.0.1:$PORT/' static"
    [ "$status" -eq 0 ]
}

@test "probe_url fails against a closed port" {
    local closed_port=1
    run bash -c "source scripts/lib/probe.sh && probe_url 'http://127.0.0.1:$closed_port/' static"
    [ "$status" -ne 0 ]
}

@test "probe_with_retries returns 0 quickly when service is up" {
    run bash -c "source scripts/lib/probe.sh && probe_with_retries 'http://127.0.0.1:$PORT/' static"
    [ "$status" -eq 0 ]
    # Ensure it didn't burn through every retry slot
    [[ ! "$output" =~ retry\ 5/5 ]]
}

@test "probe_with_retries fails after exhausting retries on dead service" {
    run bash -c "source scripts/lib/probe.sh && PROBE_STATIC_RETRIES=2 PROBE_STATIC_DELAY=1 probe_with_retries 'http://127.0.0.1:1/' static"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "exhausted"
}

@test "probe_with_retries rejects unknown service profile" {
    run bash -c "source scripts/lib/probe.sh && probe_with_retries 'http://127.0.0.1/' bogus"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "unknown.*profile"
}
```

- [ ] **Step 2.2: Run the test to verify it fails**

Run: `bats tests/probe.bats`
Expected: FAIL with "scripts/lib/probe.sh: No such file".

- [ ] **Step 2.3: Implement `scripts/lib/probe.sh`**

Create `scripts/lib/probe.sh`:

```bash
#!/usr/bin/env bash
# Probe-before-announce. Per-spec §3.3: no URL is announced until the service
# behind it returns HTTP 200 (or documented non-error) from inside the VM and
# from the runner's perspective.

# Service profiles: per-service retry counts and inter-attempt delay (seconds).
# Override via environment for tests.
: "${PROBE_STATIC_RETRIES:=5}"
: "${PROBE_STATIC_DELAY:=1}"
: "${PROBE_LARAVEL_RETRIES:=6}"
: "${PROBE_LARAVEL_DELAY:=10}"
: "${PROBE_NGINX_RETRIES:=5}"
: "${PROBE_NGINX_DELAY:=2}"

probe_profile_retries() {
    case "$1" in
        static)  echo "$PROBE_STATIC_RETRIES" ;;
        laravel) echo "$PROBE_LARAVEL_RETRIES" ;;
        nginx)   echo "$PROBE_NGINX_RETRIES" ;;
        *) return 1 ;;
    esac
}

probe_profile_delay() {
    case "$1" in
        static)  echo "$PROBE_STATIC_DELAY" ;;
        laravel) echo "$PROBE_LARAVEL_DELAY" ;;
        nginx)   echo "$PROBE_NGINX_DELAY" ;;
        *) return 1 ;;
    esac
}

# probe_url <url> <profile>
# Single attempt. Returns 0 on HTTP 2xx/3xx, non-zero otherwise.
probe_url() {
    local url="$1"
    local profile="$2"
    if ! probe_profile_retries "$profile" >/dev/null; then
        echo "ERROR: unknown probe profile: $profile" >&2
        return 2
    fi
    curl -fsS --max-time 5 -o /dev/null "$url"
}

# probe_with_retries <url> <profile>
# Retries per-profile. Prints status to stderr; returns 0 on first success,
# non-zero after retries are exhausted.
probe_with_retries() {
    local url="$1"
    local profile="$2"
    local retries delay attempt
    retries="$(probe_profile_retries "$profile")" || {
        echo "ERROR: unknown probe profile: $profile" >&2
        return 2
    }
    delay="$(probe_profile_delay "$profile")"
    for ((attempt=1; attempt<=retries; attempt++)); do
        if probe_url "$url" "$profile"; then
            echo "probe ok ($url, profile=$profile, attempt=$attempt/$retries)" >&2
            return 0
        fi
        if [ "$attempt" -lt "$retries" ]; then
            sleep "$delay"
        fi
    done
    echo "probe exhausted: $url (profile=$profile, retries=$retries)" >&2
    return 1
}

# probe_url_inside <ssh-target> <port> <profile>
# Probe via SSH from inside the VM. Used to confirm the service is bound on
# 127.0.0.1 from the VM's perspective before exposing it externally.
probe_url_inside() {
    local ssh_target="$1"
    local port="$2"
    local profile="$3"
    local retries delay attempt
    retries="$(probe_profile_retries "$profile")" || return 2
    delay="$(probe_profile_delay "$profile")"
    for ((attempt=1; attempt<=retries; attempt++)); do
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
            "curl -fsS --max-time 5 -o /dev/null http://127.0.0.1:$port/" \
            >/dev/null 2>&1; then
            return 0
        fi
        [ "$attempt" -lt "$retries" ] && sleep "$delay"
    done
    return 1
}
```

- [ ] **Step 2.4: Run the test to verify it passes**

Run: `bats tests/probe.bats`
Expected: 5 tests pass. If `python3` is unavailable, replace the test server line in `setup()` with `php -S 127.0.0.1:"$PORT" >/dev/null 2>&1 &`.

- [ ] **Step 2.5: Commit**

```bash
git add scripts/lib/probe.sh tests/probe.bats
git commit -m "feat(lib): add probe.sh with per-profile retry policies"
```

---

## Task 3: Verifier library (live-scan + auto-pick allocation)

**Files:**
- Create: `scripts/lib/verifier.sh`
- Create: `tests/verifier.bats`

- [ ] **Step 3.1: Write the failing test (with a stub SSH for offline testing)**

Create `tests/verifier.bats`:

```bash
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
```

- [ ] **Step 3.2: Run the test to verify it fails**

Run: `bats tests/verifier.bats`
Expected: FAIL with "scripts/lib/verifier.sh: No such file".

- [ ] **Step 3.3: Implement `scripts/lib/verifier.sh`**

Create `scripts/lib/verifier.sh`:

```bash
#!/usr/bin/env bash
# Live-scan VM resource verifier. No central registry. Per spec §14.
#
# Requires: scripts/lib/vm.sh sourced first (LARV_VM_HOST, LARV_VM_HOST_SSH_USER).

verifier_ssh_target() {
    echo "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
}

# allocate_port <role>
# Roles: mockup (9000-9499), docsite (9500-9999), app (8000-8999).
# Strategy: live-scan via ss -tlnp; pick first free port in range.
# Caller is responsible for binding immediately to close the TOCTOU window.
allocate_port() {
    local role="$1"
    local lo hi
    case "$role" in
        mockup)  lo=9000; hi=9499 ;;
        docsite) lo=9500; hi=9999 ;;
        app)     lo=8000; hi=8999 ;;
        *) echo "ERROR: unknown port role: $role" >&2; return 1 ;;
    esac

    local listening
    listening="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"

    local port
    for ((port=lo; port<=hi; port++)); do
        if ! grep -qx "$port" <<<"$listening"; then
            echo "$port"
            return 0
        fi
    done
    echo "ERROR: port range $lo-$hi exhausted (role=$role)" >&2
    return 1
}

# allocate_db <slug>
# Returns "larv_<slug-with-dashes-as-underscores>". Verifies it does not exist
# on the VM's MySQL instance (or returns non-zero if it does).
allocate_db() {
    local slug="$1"
    local db_name
    db_name="larv_$(echo "$slug" | tr '-' '_')"
    local existing
    existing="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" \
        "mysql -N -B -e 'SHOW DATABASES' 2>/dev/null" 2>/dev/null || true)"
    if grep -qx "$db_name" <<<"$existing"; then
        echo "ERROR: database $db_name already exists on VM" >&2
        return 1
    fi
    echo "$db_name"
}

# allocate_project_root <slug>
# Returns /srv/larv/<slug>. Verifies it does not already exist on the VM.
allocate_project_root() {
    local slug="$1"
    local existing
    existing="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ls /srv/larv/ 2>/dev/null" 2>/dev/null || true)"
    if grep -qx "$slug" <<<"$existing"; then
        echo "ERROR: project root /srv/larv/$slug is taken" >&2
        return 1
    fi
    echo "${LARV_VM_PROJECT_ROOT}/$slug"
}

# verify_allocation <port> <role>
# Re-scan to confirm a previously allocated port is still free (catches TOCTOU
# races). Returns 0 if free, non-zero if taken.
verify_allocation() {
    local port="$1"
    local listening
    listening="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"
    ! grep -qx "$port" <<<"$listening"
}
```

- [ ] **Step 3.4: Run the test to verify it passes**

Run: `bats tests/verifier.bats`
Expected: 8 tests pass.

- [ ] **Step 3.5: Commit**

```bash
git add scripts/lib/verifier.sh tests/verifier.bats
git commit -m "feat(lib): add verifier.sh with live-scan port/db/project allocation"
```

---

## Task 4: Git-safe library (auto-commit policy)

**Files:**
- Create: `scripts/lib/git_safe.sh`
- Create: `tests/git_safe.bats`

- [ ] **Step 4.1: Write the failing test**

Create `tests/git_safe.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    REPO="$(mktemp -d)"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "test"
    mkdir -p "$REPO/docs/larv" "$REPO/adr"
    echo "init" >"$REPO/README.md"
    git -C "$REPO" add README.md
    git -C "$REPO" commit -q -m "initial"
}

teardown() {
    [ -d "$REPO" ] && rm -rf "$REPO"
}

@test "git_default_branch detects main" {
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && git_default_branch"
    [ "$status" -eq 0 ]
    # could be 'main' or 'master' depending on git default
    [[ "$output" =~ ^(main|master)$ ]]
}

@test "git_dirty_outside_docs returns 0 when no dirty paths exist" {
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -eq 0 ]
}

@test "git_dirty_outside_docs returns 1 when dirty path is outside docs/ and adr/" {
    echo "dirty" > "$REPO/app.php"
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -ne 0 ]
}

@test "git_dirty_outside_docs returns 0 when only docs/ is dirty" {
    mkdir -p "$REPO/docs/larv"
    echo "dirty" > "$REPO/docs/larv/note.md"
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -eq 0 ]
}

@test "safe_commit_docs commits docs/ and adr/ to default branch" {
    mkdir -p "$REPO/docs/larv"
    echo "doc" > "$REPO/docs/larv/note.md"
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && safe_commit_docs '[larv] phase 0: discuss approved'"
    [ "$status" -eq 0 ]
    run git -C "$REPO" log -1 --pretty=%s
    [[ "$output" == *"phase 0: discuss approved"* ]]
}

@test "safe_commit_docs refuses to commit if dirty paths exist outside docs/" {
    echo "dirty" > "$REPO/app.php"
    mkdir -p "$REPO/docs/larv"
    echo "doc" > "$REPO/docs/larv/note.md"
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && safe_commit_docs 'msg'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "dirty path"
}

@test "safe_commit_docs no-ops when no docs/ changes are staged or unstaged" {
    run bash -c "cd $REPO && source scripts/lib/git_safe.sh && safe_commit_docs 'msg'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "nothing to commit"
}
```

- [ ] **Step 4.2: Run the test to verify it fails**

Run: `bats tests/git_safe.bats`
Expected: FAIL.

- [ ] **Step 4.3: Implement `scripts/lib/git_safe.sh`**

Create `scripts/lib/git_safe.sh`:

```bash
#!/usr/bin/env bash
# Auto-commit safety per spec §18. Operates only on docs/ and adr/ paths.

# git_default_branch
# Detects the default branch. Tries: origin/HEAD symbolic ref, then init.defaultBranch.
git_default_branch() {
    local ref
    ref="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [ -n "$ref" ]; then
        echo "${ref##*/}"
        return 0
    fi
    local init_default
    init_default="$(git config --get init.defaultBranch 2>/dev/null || true)"
    [ -n "$init_default" ] && { echo "$init_default"; return 0; }
    echo "main"
}

# git_dirty_outside_docs
# Returns 0 if all dirty paths (staged, unstaged, untracked) are inside
# docs/ or adr/. Returns 1 if anything else is dirty.
git_dirty_outside_docs() {
    local dirty
    dirty="$(git status --porcelain | awk '{print $2}')"
    [ -z "$dirty" ] && return 0
    local p
    while IFS= read -r p; do
        case "$p" in
            docs/*|adr/*) ;;
            *) return 1 ;;
        esac
    done <<<"$dirty"
    return 0
}

# safe_commit_docs <message>
# Commits docs/ and adr/ to the default branch. Refuses if dirty paths exist
# outside those directories. No-op if there are no docs/ or adr/ changes.
safe_commit_docs() {
    local message="$1"
    if ! git_dirty_outside_docs; then
        echo "ERROR: dirty path(s) outside docs/ or adr/ — commit those first:" >&2
        git status --porcelain | grep -vE '^.. (docs/|adr/)' >&2
        return 1
    fi

    local has_changes=0
    if ! git diff --quiet -- docs/ adr/ 2>/dev/null; then
        has_changes=1
    fi
    if ! git diff --cached --quiet -- docs/ adr/ 2>/dev/null; then
        has_changes=1
    fi
    if git ls-files --others --exclude-standard -- docs/ adr/ | grep -q .; then
        has_changes=1
    fi

    if [ "$has_changes" -eq 0 ]; then
        echo "[larv] nothing to commit in docs/ or adr/"
        return 0
    fi

    git add docs/ adr/ 2>/dev/null || true
    git commit -m "$message" -- docs/ adr/
}
```

- [ ] **Step 4.4: Run the test to verify it passes**

Run: `bats tests/git_safe.bats`
Expected: 7 tests pass.

- [ ] **Step 4.5: Commit**

```bash
git add scripts/lib/git_safe.sh tests/git_safe.bats
git commit -m "feat(lib): add git_safe.sh with default-branch-aware auto-commit"
```

---

## Task 5: Tracker library + initial yaml template

**Files:**
- Create: `scripts/lib/tracker.sh`
- Create: `templates/tracker.yaml.tmpl`
- Create: `tests/tracker.bats`

- [ ] **Step 5.1: Write the failing test**

Create `tests/tracker.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
}
teardown() { teardown_tmp_project "$TMP"; }

@test "tracker_init creates implementation-tracker.yaml at expected path" {
    run bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/implementation-tracker.yaml" ]
}

@test "tracker_init produces a valid YAML with schema_version: 1 and empty entries" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run yq '.schema_version' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
    run yq '.entries | length' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "0" ]
}

@test "tracker_init refuses to overwrite an existing tracker" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "already exists"
}

@test "tracker_append adds an entry with a generated ID" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' \
        'Add billing' 'Wire Cashier-Stripe' feature claude-code claude-opus-4-7 \
        'slice-07-billing' 'app/Models/Subscription.php' completed"
    [ "$status" -eq 0 ]
    run yq '.entries | length' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "1" ]
    run yq -r '.entries[0].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [[ "$output" =~ ^ENT-[0-9]{4}$ ]]
    run yq -r '.entries[0].title' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "Add billing" ]
    run yq -r '.entries[0].created_by.tool' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "claude-code" ]
}

@test "tracker_append generates monotonically-increasing IDs" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b feature t m s f completed"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' c d bug t m s f completed"
    run yq -r '.entries[0].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "ENT-0001" ]
    run yq -r '.entries[1].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "ENT-0002" ]
}

@test "tracker_render produces a markdown view at implementation-tracker.md" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' \
        'Add billing' 'Wire Cashier-Stripe' feature claude-code claude-opus-4-7 \
        'slice-07' 'app/Models/Subscription.php' completed"
    run bash -c "source scripts/lib/tracker.sh && tracker_render '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/implementation-tracker.md" ]
    grep -q "Add billing" "$TMP/docs/larv/implementation-tracker.md"
    grep -q "claude-code" "$TMP/docs/larv/implementation-tracker.md"
    grep -q "ENT-0001" "$TMP/docs/larv/implementation-tracker.md"
}

@test "tracker_append rejects an invalid type" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b NOTREAL t m s f completed"
    [ "$status" -ne 0 ]
}

@test "tracker_append rejects an invalid status" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b feature t m s f NOTREAL"
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 5.2: Run the test to verify it fails**

Run: `bats tests/tracker.bats`
Expected: FAIL.

- [ ] **Step 5.3: Create `templates/tracker.yaml.tmpl`**

Create `templates/tracker.yaml.tmpl`:

```yaml
schema_version: 1
entries: []
```

- [ ] **Step 5.4: Implement `scripts/lib/tracker.sh`**

Create `scripts/lib/tracker.sh`:

```bash
#!/usr/bin/env bash
# Implementation tracker per spec §16.

# Resolve the plugin root from this script's location.
__tracker_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

tracker_path_yaml() { echo "$1/docs/larv/implementation-tracker.yaml"; }
tracker_path_md()   { echo "$1/docs/larv/implementation-tracker.md"; }

tracker_init() {
    local dir="$1"
    local p plugin_root
    p="$(tracker_path_yaml "$dir")"
    if [ -e "$p" ]; then
        echo "ERROR: tracker already exists at $p" >&2
        return 1
    fi
    plugin_root="$(__tracker_plugin_root)"
    mkdir -p "$(dirname "$p")"
    cp "$plugin_root/templates/tracker.yaml.tmpl" "$p"
}

# tracker_append <dir> <title> <description> <type> <tool> <model> \
#   <slices_csv> <files_csv> <status>
tracker_append() {
    local dir="$1" title="$2" description="$3" type="$4"
    local tool="$5" model="$6" slices_csv="$7" files_csv="$8" status="$9"

    case "$type" in
        feature|bug|hotfix|refactor|migration) ;;
        *) echo "ERROR: invalid type: $type" >&2; return 1 ;;
    esac
    case "$status" in
        planned|in-progress|completed|reverted) ;;
        *) echo "ERROR: invalid status: $status" >&2; return 1 ;;
    esac

    local p next_id now slices_yaml files_yaml
    p="$(tracker_path_yaml "$dir")"
    [ -f "$p" ] || { echo "ERROR: no tracker at $p — call tracker_init first" >&2; return 1; }

    local count
    count="$(yq '.entries | length' "$p")"
    next_id="$(printf "ENT-%04d" $((count + 1)))"
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Build YAML arrays from CSV input
    slices_yaml="$(echo "$slices_csv" | awk -F, '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')"
    files_yaml="$(echo "$files_csv" | awk -F, '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')"

    yq -i ".entries += [{
        \"id\": \"$next_id\",
        \"title\": \"$title\",
        \"description\": \"$description\",
        \"type\": \"$type\",
        \"created_by\": { \"tool\": \"$tool\", \"model\": \"$model\" },
        \"created_at\": \"$now\",
        \"slices_touched\": [$slices_yaml],
        \"files_changed\": [$files_yaml],
        \"status\": \"$status\",
        \"related_adr\": [],
        \"related_handsoff\": \"\",
        \"learnings_appended\": false
    }]" "$p"
}

tracker_render() {
    local dir="$1"
    local yaml_p md_p
    yaml_p="$(tracker_path_yaml "$dir")"
    md_p="$(tracker_path_md "$dir")"
    [ -f "$yaml_p" ] || { echo "ERROR: no tracker at $yaml_p" >&2; return 1; }

    {
        echo "# Implementation Tracker"
        echo
        echo "Auto-generated from \`implementation-tracker.yaml\`. Do not edit by hand."
        echo
        echo "| ID | Type | Title | By | Status | When |"
        echo "|---|---|---|---|---|---|"
        yq -r '.entries[]
            | [.id, .type, .title, (.created_by.tool + " (" + .created_by.model + ")"), .status, .created_at]
            | @tsv' "$yaml_p" \
        | awk -F'\t' '{ printf "| %s | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$6 }'
    } > "$md_p"
}
```

- [ ] **Step 5.5: Run the test to verify it passes**

Run: `bats tests/tracker.bats`
Expected: 8 tests pass.

- [ ] **Step 5.6: Commit**

```bash
git add scripts/lib/tracker.sh templates/tracker.yaml.tmpl tests/tracker.bats
git commit -m "feat(lib): add tracker.sh with append/render and yaml template"
```

---

## Task 6: STATE.yaml schema extensions

**Files:**
- Modify: `scripts/state.sh` — add `mode`, `allocations`, `features`, `debugs` to init template; add `cmd_set_mode` and `cmd_record_allocation` subcommands.
- Create: `tests/state-extended.bats`
- Modify: existing fixtures to include the new fields (where the test expects them; otherwise the new fields are optional in `cmd_read`).

- [ ] **Step 6.1: Write the failing test**

Create `tests/state-extended.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "state init seeds execution.mode, allocations, features, debugs" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run yq -r '.execution.mode // "missing"' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "not-yet-decided" ]
    run yq -r '.execution.allocations | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.features | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.debugs | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
}

@test "state set-mode writes a valid execution mode" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh set-mode "$TMP" executing-subagents
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-subagents" ]
}

@test "state set-mode rejects an invalid mode" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run bash scripts/state.sh set-mode "$TMP" not-a-real-mode
    [ "$status" -ne 0 ]
}

@test "state record-allocation appends to execution.allocations" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    bash scripts/state.sh record-allocation "$TMP" mockup-port 9001
    bash scripts/state.sh record-allocation "$TMP" app-port 8001
    run yq -r '.execution.allocations | length' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "2" ]
    run yq -r '.execution.allocations[0].kind' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "mockup-port" ]
    run yq -r '.execution.allocations[0].value' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "9001" ]
}
```

- [ ] **Step 6.2: Run the test to verify it fails**

Run: `bats tests/state-extended.bats`
Expected: FAIL — none of the new fields exist; subcommands are unknown.

- [ ] **Step 6.3: Modify `scripts/state.sh`**

Edit `scripts/state.sh`:

Find the heredoc inside `cmd_init` and add the new fields just before the closing `EOF`. The existing heredoc ends with `policies:` block. Append after that block (before `EOF`):

```bash
execution:
  mode: not-yet-decided
  allocations: []
features: []
debugs: []
```

So the full tail becomes:

```bash
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
execution:
  mode: not-yet-decided
  allocations: []
features: []
debugs: []
EOF
```

Then add two new subcommand functions just before `main()`:

```bash
cmd_set_mode() {
    local dir="$1"
    local mode="$2"
    case "$mode" in
        not-yet-decided|executing-same-session|executing-subagents|handed-off-external)
            ;;
        *) echo "ERROR: invalid mode: $mode" >&2; return 1 ;;
    esac
    cmd_update "$dir" ".execution.mode = \"$mode\""
}

cmd_record_allocation() {
    local dir="$1"
    local kind="$2"
    local value="$3"
    cmd_update "$dir" ".execution.allocations += [{ \"kind\": \"$kind\", \"value\": \"$value\" }]"
}
```

Update `main()`'s case to add:

```bash
        set-mode) [ "$#" -eq 2 ] || usage; cmd_set_mode "$@" ;;
        record-allocation) [ "$#" -eq 3 ] || usage; cmd_record_allocation "$@" ;;
```

Update `usage()`'s heredoc to add the new commands:

```bash
  set-mode <dir> <mode>
  record-allocation <dir> <kind> <value>
```

- [ ] **Step 6.4: Run the test to verify it passes**

Run: `bats tests/state-extended.bats`
Expected: 4 tests pass.

- [ ] **Step 6.5: Re-run the existing state suite to confirm no regression**

Run: `bats tests/state.bats`
Expected: all existing tests still pass.

- [ ] **Step 6.6: Commit**

```bash
git add scripts/state.sh tests/state-extended.bats
git commit -m "feat(state): add execution.mode, allocations, features, debugs"
```

---

## Task 7: Handsoff templates

**Files:**
- Create: `templates/handsoff-index.md.tmpl`
- Create: `templates/handsoff-slice.md.tmpl`
- Create: `templates/ai-starting-point.md.tmpl`
- Create: `templates/cursor-rule.mdc.tmpl`

These are **plain templates** — they use `{{tokens}}` for substitution via `sed`. They do NOT reference plugin scripts (per spec §3.2: handsoff content is self-contained).

- [ ] **Step 7.1: Create `templates/handsoff-index.md.tmpl`**

```markdown
# Handsoff — {{project_name}}

> This is the universal execution contract for {{project_slug}}. Any AI session — Claude Code, Codex CLI, Cursor, Gemini, or another tool — can execute the plan from this document plus the per-slice handsoffs in `docs/Handsoff/`. **Do not skip steps.**

## 1. Project identity

| | |
|---|---|
| Name | {{project_name}} |
| Slug | {{project_slug}} |
| Plugin version | {{plugin_version}} |
| Generated at | {{generated_at}} |
| Git SHA | {{git_sha}} |
| Default branch | {{git_default_branch}} |

## 2. Mission

{{mission_paragraph}}

## 3. Decisions log

{{adr_aggregator_inlined}}

## 4. DDD model

{{ddd_model_inlined_or_flat_model}}

## 5. Architecture (C4)

{{c4_diagrams_inlined}}

## 6. Data model

{{data_model_inlined}}

## 7. API surface

{{api_surface_inlined}}

## 8. UI / Brand

Chosen design pick: {{design_pick_slug}}
Brand spec: `docs/larv/03-design/brand-spec.md`

## 9. Test strategy

{{test_strategy_inlined}}

## 10. Slice plan

{{slice_plan_inlined}}

For each slice, see the per-slice handsoff at `docs/Handsoff/slice-NN-<name>.md`.

## 11. Sandbox info

| | |
|---|---|
| VM host | {{vm_host}} |
| App port | {{app_port}} |
| Mockup port | {{mockup_port}} |
| Database | {{db_name}} |
| DB user | {{db_user}} |
| Project root | {{project_root}} |
| Redis prefix | {{redis_prefix}} |
| SSH key | {{ssh_key_path}} |

Verify the sandbox is alive:

```bash
ssh {{ssh_user}}@{{vm_host}} "cd {{project_root}} && docker compose ps"
```

## 12. Verification commands

```bash
# Run from {{project_root}} on the VM
docker compose exec app vendor/bin/pest
docker compose exec app vendor/bin/pint --test
docker compose exec app vendor/bin/phpstan analyse
```

Smoke-test URL (after each slice): `http://{{vm_host}}:{{app_port}}/{{smoke_path}}`

## 13. Constraints for the implementer

- Do not change schema without consulting the slice handsoff's migration field.
- Do not skip tests. If a test in DoD does not pass, mark `STATE.yaml.slices.NN.status: failed` and stop.
- After each slice, append to `docs/larv/implementation-tracker.yaml` (snippet in slice handsoff).
- Append discoveries worth saving to `docs/larv/local-learnings.md` (snippet in slice handsoff).
- Identify yourself accurately when filling `created_by.tool` and `created_by.model`.

## 14. Foreign-AI notes

If you are not Claude Code: ignore any references to "superpowers" or "skills" outside this document. Treat this Handsoff and the per-slice files as a complete plain-language spec. You do not need to install the larv plugin; everything you need to do is encoded inline.
```

- [ ] **Step 7.2: Create `templates/handsoff-slice.md.tmpl`**

```markdown
# Slice {{slice_id}} — {{slice_name}}

> Per-slice execution contract. Read this file from top to bottom and execute every step. Update STATE.yaml and the implementation tracker on completion.

## 1. Goal

{{goal_one_line}}

## 2. Why this slice

{{why_user_visible_value}}

## 3. Files to create

{{files_to_create_list}}

## 4. Files to modify

{{files_to_modify_list}}

## 5. Migrations

{{migrations_list}}

## 6. Tests to write

{{tests_list_with_acceptance_criteria}}

## 7. API endpoints

{{api_endpoints_with_examples}}

## 8. UI screens touched

{{ui_screens_list}}

## 9. Dependencies

depends_on: {{depends_on_list}}
parallel: {{parallel_flag}}

## 10. Definition of Done

- [ ] All tests in section 6 pass: `docker compose exec app vendor/bin/pest --filter='{{test_filter}}'`
- [ ] Migration runs forward: `docker compose exec app php artisan migrate`
- [ ] Migration runs backward: `docker compose exec app php artisan migrate:rollback`
- [ ] No N+1 queries on listed endpoints (verified with Telescope or similar)
- [ ] `IMPLEMENTATION-REPORT-{{slice_id}}.md` written
- [ ] Tracker entry appended (see section 13)
- [ ] Learnings appended if any (see section 14)

## 11. Estimated effort

Tokens: {{est_tokens}} · Minutes: {{est_minutes}}

## 12. Implementation commands

```bash
cd {{project_root}}
{{implementation_bash}}
```

## 13. Tracker append snippet (run on completion)

```bash
yq -i '.entries += [{
  "id": "ENT-{{tracker_id_padding}}",
  "title": "{{slice_name}}",
  "description": "{{goal_one_line}}",
  "type": "feature",
  "created_by": { "tool": "{{your_tool_id}}", "model": "{{your_model_id}}" },
  "created_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
  "slices_touched": ["{{slice_id}}"],
  "files_changed": [{{files_changed_yaml_array}}],
  "status": "completed",
  "related_adr": [{{related_adr_yaml_array}}],
  "related_handsoff": "docs/Handsoff/{{slice_id}}-{{slice_slug}}.md",
  "learnings_appended": {{learnings_appended_bool}}
}]' docs/larv/implementation-tracker.yaml
```

Then regenerate the rendered view:

```bash
# Inline render — does not depend on plugin scripts
yq -r '.entries[] | [.id, .type, .title, (.created_by.tool + " (" + .created_by.model + ")"), .status, .created_at] | @tsv' \
    docs/larv/implementation-tracker.yaml \
    | awk -F'\t' 'BEGIN{ print "# Implementation Tracker\n\n| ID | Type | Title | By | Status | When |\n|---|---|---|---|---|---|" }
                  { printf "| %s | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$6 }' \
    > docs/larv/implementation-tracker.md
```

## 14. Local learnings append snippet (run if you discover something worth saving)

```bash
cat >> docs/larv/local-learnings.md <<'EOF'

## {{slice_id}} — $(date -u +%Y-%m-%d)

<your one-paragraph learning here, focused on what surprised you or what
future implementers should know. Tag as [plugin] if it applies to the
plugin itself, [project] if it's project-specific.>
EOF
```

## 15. STATE.yaml update snippet (run on completion)

```bash
yq -i '.slices.status["{{slice_id}}"] = "completed" | .project.last_updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' \
    docs/larv/STATE.yaml
```

## 16. Implementation report

Write `IMPLEMENTATION-REPORT-{{slice_id}}.md` at the project root with the following sections:

```markdown
# {{slice_id}} — {{slice_name}}

## What was built
- ...

## How to QA
URL: http://{{vm_host}}:{{app_port}}/{{smoke_path}}
Login: {{seeded_email}} / {{seeded_password}}
1. ...
2. ...

## Tests
Pest: {{passed}}/{{total}}

## Notes for the next implementer
- ...
```

## 17. Foreign-AI notes

If you are not Claude Code or are unfamiliar with the larv plugin: this document is self-contained. Do not look for plugin scripts to call; every action above is plain bash. Identify yourself accurately in section 13's tracker append snippet.
```

- [ ] **Step 7.3: Create `templates/ai-starting-point.md.tmpl`**

```markdown
# {{tool_friendly_name}} starting point — {{project_name}}

This project is managed by the **larv** Laravel workflow plugin. The full plan and execution contract live in:

- `docs/Handsoff.md` — index + project context (start here)
- `docs/Handsoff/slice-NN-<name>.md` — per-slice execution contract
- `docs/larv/implementation-tracker.yaml` — tracker (append on every change)
- `docs/larv/local-learnings.md` — learnings staging (append when you discover something worth saving)
- `adr/` — architecture decision records

## How to work in this project

1. Read `docs/Handsoff.md` end to end before changing anything.
2. To implement a slice, open the matching `docs/Handsoff/slice-NN-<name>.md` and execute it top to bottom.
3. Probe-before-announce: never tell the user a URL until you have curl-confirmed the service responds.
4. Recommendation-with-every-question: when you ask the user a question, pair it with a recommendation block:
   ```
   Recommendation: <option>
   Why: <one-sentence reason citing the plan>
   Tradeoffs: <one-line counterpoint>
   ```
5. After every change:
   - Append a tracker entry (snippet in the slice handsoff).
   - Update `STATE.yaml.slices.<slice-id>.status` (snippet in the slice handsoff).
   - Append to `docs/larv/local-learnings.md` if you discovered something.
   - Run the slice's Definition of Done checklist before claiming completion.
   - Identify yourself accurately when filling `created_by.tool` and `created_by.model` in the tracker.

## Code conventions

- Format: Pint (`vendor/bin/pint`)
- Tests: Pest (`vendor/bin/pest`)
- Static analysis: Larastan (`vendor/bin/phpstan analyse`)
- Use the canonical ubiquitous-language terms from `docs/larv/01-domain/ubiquitous-language.md`. Do not invent new names for existing concepts.

## Sandbox

| | |
|---|---|
| VM host | {{vm_host}} |
| App URL | http://{{vm_host}}:{{app_port}} |
| Project root on VM | {{project_root}} |
| Database | {{db_name}} |

SSH: `ssh {{ssh_user}}@{{vm_host}}`

## What to do if you are stuck

If a slice handsoff seems incomplete or contradicts itself, stop and surface the inconsistency to the user. Do not improvise. The plan is the source of truth; if it's wrong, fix the plan first.
```

- [ ] **Step 7.4: Create `templates/cursor-rule.mdc.tmpl`**

```markdown
---
description: larv plugin context for {{project_name}}
globs: ["**/*.php", "**/*.blade.php", "**/*.md"]
alwaysApply: true
---

This project is managed by the larv plugin. See `docs/Handsoff.md` for the execution contract. Execute slices from `docs/Handsoff/slice-NN-*.md` only — never improvise.

Probe-before-announce: never claim a service is running until curl confirms it. Append a tracker entry to `docs/larv/implementation-tracker.yaml` after every change.

Code conventions: Pint formatting, Pest tests, Larastan static analysis. Use the canonical ubiquitous-language terms from `docs/larv/01-domain/ubiquitous-language.md`.
```

- [ ] **Step 7.5: Commit**

```bash
git add templates/handsoff-index.md.tmpl templates/handsoff-slice.md.tmpl \
        templates/ai-starting-point.md.tmpl templates/cursor-rule.mdc.tmpl
git commit -m "feat(templates): add handsoff index/slice and AI starting-point templates"
```

---

## Task 8: Handsoff library

**Files:**
- Create: `scripts/lib/handsoff.sh`
- Create: `tests/handsoff.bats`

- [ ] **Step 8.1: Write the failing test**

Create `tests/handsoff.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    bash scripts/state.sh init "$TMP" my-app greenfield
    # seed minimal docs the renderer expects
    mkdir -p "$TMP/docs/larv/01-domain" "$TMP/docs/larv/02-architecture" \
        "$TMP/docs/larv/03-design" "$TMP/docs/larv/06-implementation" \
        "$TMP/adr"
    echo "# C4 Context\n\nMermaid here." > "$TMP/docs/larv/02-architecture/c4-context.md"
    echo "# Domain model" > "$TMP/docs/larv/01-domain/domain-model.md"
    cat > "$TMP/docs/larv/06-implementation/elephant-carpaccio.md" <<EOF
# Slice Plan

## slice-01-auth
goal: Auth scaffold
depends_on: []
parallel: false
EOF
}

teardown() { teardown_tmp_project "$TMP"; }

@test "handsoff_render_index writes docs/Handsoff.md" {
    run bash -c "source scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff.md" ]
    grep -q "Handsoff — my-app" "$TMP/docs/Handsoff.md"
    grep -q "31.220.79.31" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_index inlines C4 content (does not link only)" {
    bash -c "source scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    grep -q "C4 Context" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_slice writes docs/Handsoff/slice-01-auth.md" {
    run bash -c "source scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff/slice-01-auth.md" ]
    grep -q "slice-01" "$TMP/docs/Handsoff/slice-01-auth.md"
}

@test "handsoff_render_slice contains inline tracker append snippet" {
    bash -c "source scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    grep -q 'yq -i' "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q 'implementation-tracker.yaml' "$TMP/docs/Handsoff/slice-01-auth.md"
}

@test "handsoff_render_slice does not reference plugin internal scripts" {
    bash -c "source scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    # spec discipline §3.2: handsoff is self-contained
    if grep -E 'scripts/(state|lock|tracker|handsoff|verifier|probe|gate|git_safe)\.sh' \
        "$TMP/docs/Handsoff/slice-01-auth.md"; then
        echo "FAIL: handsoff references plugin scripts" >&2
        return 1
    fi
}

@test "handsoff_render_starting_points writes all five starting-point files" {
    bash -c "source scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    [ -f "$TMP/CLAUDE.md" ]
    [ -f "$TMP/AGENTS.md" ]
    [ -f "$TMP/GEMINI.md" ]
    [ -f "$TMP/.cursor/rules/larv.mdc" ]
    [ -f "$TMP/.codex/AGENTS.md" ]
}

@test "starting-point files all reference docs/Handsoff.md" {
    bash -c "source scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        grep -q "Handsoff.md" "$f" || { echo "missing reference in $f"; return 1; }
    done
}
```

- [ ] **Step 8.2: Run the test to verify it fails**

Run: `bats tests/handsoff.bats`
Expected: FAIL.

- [ ] **Step 8.3: Implement `scripts/lib/handsoff.sh`**

Create `scripts/lib/handsoff.sh`:

```bash
#!/usr/bin/env bash
# Handsoff document generator. Per spec §15: writes docs/Handsoff.md (index)
# and docs/Handsoff/slice-NN-<name>.md (per slice), plus AI starting-point
# files (CLAUDE.md, AGENTS.md, GEMINI.md, .cursor/rules/larv.mdc, .codex/AGENTS.md).
# Self-contained: handsoff content references no plugin scripts.

__handsoff_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

# Read STATE.yaml and produce a key=value map for sed substitution.
handsoff_collect_tokens() {
    local dir="$1"
    local sp="$dir/docs/larv/STATE.yaml"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local plugin_version
    plugin_version="$(yq -r '.version // "0.0.0"' "$plugin_root/.claude-plugin/plugin.json" 2>/dev/null || echo "0.0.0")"
    local git_sha git_default_branch
    git_sha="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo "uncommitted")"
    git_default_branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || echo "detached")"

    local app_port mockup_port db_name project_root
    app_port="$(yq -r '.execution.allocations[] | select(.kind == "app-port") | .value' "$sp" 2>/dev/null | head -1)"
    mockup_port="$(yq -r '.execution.allocations[] | select(.kind == "mockup-port") | .value' "$sp" 2>/dev/null | head -1)"
    db_name="$(yq -r '.execution.allocations[] | select(.kind == "db-name") | .value' "$sp" 2>/dev/null | head -1)"
    project_root="$(yq -r '.execution.allocations[] | select(.kind == "project-root") | .value' "$sp" 2>/dev/null | head -1)"

    cat <<EOF
project_name=$(yq -r '.project.name' "$sp")
project_slug=$(yq -r '.project.slug' "$sp")
plugin_version=$plugin_version
generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
git_sha=$git_sha
git_default_branch=$git_default_branch
vm_host=${LARV_VM_HOST:-31.220.79.31}
ssh_user=${LARV_VM_HOST_SSH_USER:-larv}
app_port=${app_port:-TBD}
mockup_port=${mockup_port:-TBD}
db_name=${db_name:-TBD}
db_user=${db_name:-TBD}
project_root=${project_root:-/srv/larv/$(yq -r '.project.slug' "$sp")}
redis_prefix=larv:$(yq -r '.project.slug' "$sp"):
ssh_key_path=~/.ssh/larv_$(yq -r '.project.slug' "$sp")_ed25519
mission_paragraph=See docs/larv/00-discuss/product-brief.md
adr_aggregator_inlined=$(test -f "$dir/docs/larv/decisions.md" && cat "$dir/docs/larv/decisions.md" || echo "_(no ADRs yet)_")
ddd_model_inlined_or_flat_model=$(test -f "$dir/docs/larv/01-domain/domain-model.md" && cat "$dir/docs/larv/01-domain/domain-model.md" || echo "_(domain model TBD)_")
c4_diagrams_inlined=$(test -f "$dir/docs/larv/02-architecture/c4-context.md" && cat "$dir/docs/larv/02-architecture/c4-context.md" || echo "_(C4 TBD)_")
data_model_inlined=$(test -f "$dir/docs/larv/03-design/data-model.md" && cat "$dir/docs/larv/03-design/data-model.md" || echo "_(data model TBD)_")
api_surface_inlined=$(test -f "$dir/docs/larv/03-design/api-surface.md" && cat "$dir/docs/larv/03-design/api-surface.md" || echo "_(API surface TBD)_")
test_strategy_inlined=$(test -f "$dir/docs/larv/04-test-strategy/strategy.md" && cat "$dir/docs/larv/04-test-strategy/strategy.md" || echo "_(test strategy TBD)_")
slice_plan_inlined=$(test -f "$dir/docs/larv/06-implementation/elephant-carpaccio.md" && cat "$dir/docs/larv/06-implementation/elephant-carpaccio.md" || echo "_(slice plan TBD)_")
design_pick_slug=$(test -f "$dir/docs/larv/03-design/design-decision.md" && grep -m1 -oE 'pick: [A-Za-z0-9_-]+' "$dir/docs/larv/03-design/design-decision.md" | head -1 | sed 's/pick: //' || echo "TBD")
smoke_path=$(yq -r '.sandbox.smoke_path // "health"' "$sp" 2>/dev/null || echo "health")
EOF
}

# render_template <template_path> <tokens_file>
__handsoff_render_template() {
    local tmpl="$1"
    local tokens_file="$2"
    local out
    out="$(cat "$tmpl")"
    while IFS='=' read -r k v; do
        [ -z "$k" ] && continue
        out="${out//\{\{${k}\}\}/${v}}"
    done < "$tokens_file"
    printf "%s\n" "$out"
}

handsoff_render_index() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    mkdir -p "$dir/docs"
    __handsoff_render_template "$plugin_root/templates/handsoff-index.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff.md"
    rm -f "$tokens"
}

# handsoff_render_slice <dir> <slice_id> <slice_slug>
handsoff_render_slice() {
    local dir="$1"
    local slice_id="$2"
    local slice_slug="$3"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"
    cat >> "$tokens" <<EOF
slice_id=$slice_id
slice_name=$slice_slug
slice_slug=$slice_slug
goal_one_line=See slice plan
why_user_visible_value=See slice plan
files_to_create_list=- (see slice plan)
files_to_modify_list=- (see slice plan)
migrations_list=- (see slice plan)
tests_list_with_acceptance_criteria=- (see slice plan)
api_endpoints_with_examples=- (see slice plan)
ui_screens_list=- (see slice plan)
depends_on_list=[]
parallel_flag=false
test_filter=$slice_id
est_tokens=TBD
est_minutes=TBD
implementation_bash=# (insert exact bash from slice plan)
tracker_id_padding=0001
your_tool_id=<your tool>
your_model_id=<your model>
files_changed_yaml_array=
related_adr_yaml_array=
learnings_appended_bool=false
seeded_email=admin@example.com
seeded_password=password
passed=
total=
EOF
    mkdir -p "$dir/docs/Handsoff"
    __handsoff_render_template "$plugin_root/templates/handsoff-slice.md.tmpl" "$tokens" \
        > "$dir/docs/Handsoff/$slice_id-$slice_slug.md"
    rm -f "$tokens"
}

handsoff_render_starting_points() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__handsoff_plugin_root)"
    local tokens
    tokens="$(mktemp)"
    handsoff_collect_tokens "$dir" > "$tokens"

    # Five files, one body, different prepends in tool_friendly_name.
    local body
    body="$(__handsoff_render_template "$plugin_root/templates/ai-starting-point.md.tmpl" "$tokens")"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Claude Code}"
    } > "$dir/CLAUDE.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Agent}"
    } > "$dir/AGENTS.md"

    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Gemini CLI}"
    } > "$dir/GEMINI.md"

    mkdir -p "$dir/.codex"
    {
        printf "<!-- Generated by larv-handoff. Do not edit by hand. -->\n\n"
        echo "${body//\{\{tool_friendly_name\}\}/Codex CLI}"
    } > "$dir/.codex/AGENTS.md"

    mkdir -p "$dir/.cursor/rules"
    __handsoff_render_template "$plugin_root/templates/cursor-rule.mdc.tmpl" "$tokens" \
        > "$dir/.cursor/rules/larv.mdc"

    rm -f "$tokens"
}
```

- [ ] **Step 8.4: Run the test to verify it passes**

Run: `bats tests/handsoff.bats`
Expected: 7 tests pass.

- [ ] **Step 8.5: Commit**

```bash
git add scripts/lib/handsoff.sh tests/handsoff.bats
git commit -m "feat(lib): add handsoff.sh — index/slice/starting-points generation"
```

---

## Task 9: Gate library (soft, hard, routing menu)

**Files:**
- Create: `scripts/lib/gate.sh`
- Create: `templates/routing-menu.md.tmpl`
- Create: `tests/gate.bats`

- [ ] **Step 9.1: Write the failing test**

Create `tests/gate.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; bash scripts/state.sh init "$TMP" my-app greenfield; }
teardown() { teardown_tmp_project "$TMP"; }

@test "soft_gate prints summary and exits 0 (auto-continue)" {
    run bash -c "source scripts/lib/gate.sh && soft_gate '$TMP' 0 discuss 'Phase 0 complete' 'docs/larv/00-discuss/product-brief.md'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Phase 0 complete"
    echo "$output" | grep -q "product-brief.md"
    echo "$output" | grep -qiE "auto-continue"
}

@test "soft_gate honors LARV_GATE_PAUSE env to require explicit input" {
    LARV_GATE_PAUSE=1 run bash -c "source scripts/lib/gate.sh && echo continue | soft_gate '$TMP' 0 discuss 'Phase 0 complete' 'a.md'"
    [ "$status" -eq 0 ]
}

@test "hard_gate blocks until 'approved' is read on stdin" {
    run bash -c "source scripts/lib/gate.sh && echo approved | hard_gate '$TMP' 7 'Provisioning ready'"
    [ "$status" -eq 0 ]
}

@test "hard_gate exits non-zero when input is anything other than 'approved'" {
    run bash -c "source scripts/lib/gate.sh && echo nope | hard_gate '$TMP' 7 'Provisioning ready'"
    [ "$status" -ne 0 ]
}

@test "routing_menu accepts 'same-session' and updates STATE.yaml mode" {
    run bash -c "source scripts/lib/gate.sh && echo same-session | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-same-session" ]
}

@test "routing_menu accepts 'subagents'" {
    run bash -c "source scripts/lib/gate.sh && echo subagents | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "executing-subagents" ]
}

@test "routing_menu accepts 'handoff' and exits the orchestrator" {
    run bash -c "source scripts/lib/gate.sh && echo handoff | routing_menu '$TMP'"
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "handed-off-external" ]
}

@test "routing_menu rejects an invalid choice" {
    run bash -c "source scripts/lib/gate.sh && echo banana | routing_menu '$TMP'"
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 9.2: Run the test to verify it fails**

Run: `bats tests/gate.bats`
Expected: FAIL.

- [ ] **Step 9.3: Create `templates/routing-menu.md.tmpl`**

```
[Phase 7 complete]

Handsoff documents written:
  docs/Handsoff.md                  (index)
  docs/Handsoff/slice-NN-<name>.md  (one per slice)

Where do you want to execute these slices?

  same-session  — this Claude Code session runs Phase 8 slice-by-slice
  subagents     — fresh subagents per slice, parallel where deps allow
  handoff       — stop here; you'll point another AI at docs/Handsoff.md

Recommendation: subagents
Why: keeps your conversation buffer clean while preserving Claude Code's tool access.
Tradeoffs: subagent failures are slightly harder to debug.
```

- [ ] **Step 9.4: Implement `scripts/lib/gate.sh`**

Create `scripts/lib/gate.sh`:

```bash
#!/usr/bin/env bash
# Gate UX per spec §4.2 and §4.3.

__gate_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

# soft_gate <dir> <phase_num> <phase_name> <summary> <changed_files_csv>
# Prints summary + changed files. Auto-continues unless LARV_GATE_PAUSE=1.
soft_gate() {
    local dir="$1" phase_num="$2" phase_name="$3" summary="$4" changed_csv="$5"
    echo
    echo "[Phase $phase_num — $phase_name]"
    echo
    echo "$summary"
    echo
    echo "Changed files:"
    echo "$changed_csv" | tr ',' '\n' | sed 's/^/  /'
    echo

    if [ "${LARV_GATE_PAUSE:-0}" = "1" ]; then
        echo "Paused. Type 'continue' to advance, 'pause' to stay, or 'back' to redo previous phase:"
        local reply
        IFS= read -r reply
        case "$reply" in
            continue) return 0 ;;
            pause) return 2 ;;
            back) return 3 ;;
            *) return 2 ;;
        esac
    else
        echo "Auto-continue in 30s. Reply 'pause' to review or 'back' to redo previous phase."
        return 0
    fi
}

# hard_gate <dir> <phase_num> <prompt>
# Reads from stdin. Returns 0 only if user types 'approved'.
hard_gate() {
    local dir="$1" phase_num="$2" prompt="$3"
    echo
    echo "[Hard gate — Phase $phase_num]"
    echo "$prompt"
    echo
    echo "Type 'approved' to continue:"
    local reply
    IFS= read -r reply
    if [ "$reply" = "approved" ]; then
        return 0
    fi
    echo "Gate not approved (received: '$reply'). Stopping." >&2
    return 1
}

# routing_menu <dir>
# Prints menu, reads choice from stdin, updates STATE.yaml.execution.mode.
routing_menu() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__gate_plugin_root)"
    cat "$plugin_root/templates/routing-menu.md.tmpl"
    echo
    echo "Choose: same-session | subagents | handoff"
    local choice
    IFS= read -r choice
    local mode
    case "$choice" in
        same-session) mode="executing-same-session" ;;
        subagents)    mode="executing-subagents" ;;
        handoff)      mode="handed-off-external" ;;
        *) echo "ERROR: invalid choice: $choice" >&2; return 1 ;;
    esac
    bash "$plugin_root/scripts/state.sh" set-mode "$dir" "$mode"
    echo "[Routing] STATE.yaml.execution.mode = $mode"
}
```

- [ ] **Step 9.5: Run the test to verify it passes**

Run: `bats tests/gate.bats`
Expected: 8 tests pass.

- [ ] **Step 9.6: Commit**

```bash
git add scripts/lib/gate.sh templates/routing-menu.md.tmpl tests/gate.bats
git commit -m "feat(lib): add gate.sh — soft/hard gates and routing menu"
```

---

## Task 10: Fill in larv-handoff skill prompt

**Files:**
- Modify: `skills/larv-handoff/SKILL.md`

The skill is currently a stub. Replace it with a real prompt that drives the handsoff library.

- [ ] **Step 10.1: Read the current stub for context**

Run: `cat skills/larv-handoff/SKILL.md`
Expected: stub with "STUB — sub-project A scaffolding only" header.

- [ ] **Step 10.2: Rewrite `skills/larv-handoff/SKILL.md`**

Overwrite with:

```markdown
---
name: larv-handoff
description: Generate the universal Handsoff.md index, per-slice handsoffs, and AI starting-point files. Mandatory before the Phase 8 routing menu.
---

# larv-handoff

Generate the documents that every execution venue (same-session, subagents, foreign AI) reads to implement the slice plan. These are the only artifacts the implementation phase consumes.

## Inputs

- `docs/larv/STATE.yaml` (project + execution.allocations)
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/c4-*.md`
- `docs/larv/03-design/{brand-spec,ui-design,design-decision}.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`
- `adr/*.md`
- `docs/larv/decisions.md` (ADR aggregator)

## What you do

Source the helper libraries and call them in this exact order. Do not improvise.

```bash
. scripts/lib/vm.sh
. scripts/lib/handsoff.sh
. scripts/lib/tracker.sh
. scripts/lib/git_safe.sh

# 1. Initialize the tracker if it does not exist
if [ ! -f docs/larv/implementation-tracker.yaml ]; then
    tracker_init "."
    tracker_render "."
fi

# 2. Render the Handsoff index
handsoff_render_index "."

# 3. Render per-slice handsoffs from elephant-carpaccio.md
#    For each slice id + name in the slice plan:
#      handsoff_render_slice "." "$slice_id" "$slice_slug"

# 4. Render the AI starting-point files
handsoff_render_starting_points "."

# 5. Commit (auto-commit policy)
safe_commit_docs "[larv] handsoff documents generated for $(yq -r .project.slug docs/larv/STATE.yaml)"
```

## What you do not do

- You do not invoke other skills.
- You do not write content directly to handsoff files; you call library functions.
- You do not modify files outside `docs/`, `adr/`, and the AI starting-point paths.
- You do not run probe/verifier — that is `larv-provision`'s job.

## Required outputs

- `docs/Handsoff.md`
- `docs/Handsoff/slice-NN-<name>.md` for every slice in the plan
- `docs/larv/implementation-tracker.yaml` and `.md`
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/larv.mdc`, `.codex/AGENTS.md`

## Subagent return contract

Return:

```yaml
status: complete
files_written:
  - docs/Handsoff.md
  - docs/Handsoff/slice-NN-<name>.md  (one per slice)
  - docs/larv/implementation-tracker.yaml
  - docs/larv/implementation-tracker.md
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
  - .cursor/rules/larv.mdc
  - .codex/AGENTS.md
state_updates: {}
plugin_improvement_notes: (none)
```
```

- [ ] **Step 10.3: Add a smoke test**

Append to `tests/skills.bats` (or create `tests/larv-handoff.bats` if `skills.bats` is structured differently — check first):

```bash
@test "larv-handoff SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-handoff/SKILL.md
    grep -q "handsoff_render_index" skills/larv-handoff/SKILL.md
    grep -q "handsoff_render_starting_points" skills/larv-handoff/SKILL.md
}
```

- [ ] **Step 10.4: Run the new tests to verify they pass**

Run: `bats tests/skills.bats`
Expected: pass (existing + new).

- [ ] **Step 10.5: Commit**

```bash
git add skills/larv-handoff/SKILL.md tests/skills.bats
git commit -m "feat(skill): wire larv-handoff to the handsoff library"
```

---

## Task 11: Fill in larv-provision skill

**Files:**
- Modify: `skills/larv-provision/SKILL.md`

- [ ] **Step 11.1: Rewrite `skills/larv-provision/SKILL.md`**

Overwrite with:

```markdown
---
name: larv-provision
description: Phase 7 — verifier-driven port/DB/project allocation, Docker compose deploy, probe-before-announce, runbook generation, and AI starting-point regeneration.
---

# larv-provision

Allocate VM resources for this project, deploy the Docker compose stack, verify every service responds before printing URLs, and regenerate the handsoff documents (so they reflect runtime info before the Phase 8 routing menu).

## Inputs

- `docs/larv/STATE.yaml`
- `docs/larv/02-architecture/library-pins.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`

## What you do

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/probe.sh
. scripts/lib/handsoff.sh
. scripts/lib/git_safe.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)

# 1. Allocate
app_port=$(allocate_port app)
mockup_port=$(allocate_port mockup)
db_name=$(allocate_db "$slug")
project_root=$(allocate_project_root "$slug")

bash scripts/state.sh record-allocation . app-port "$app_port"
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
bash scripts/state.sh record-allocation . db-name "$db_name"
bash scripts/state.sh record-allocation . project-root "$project_root"

# 2. SSH to VM, scaffold project root, copy compose stack, bring it up
#    (compose template + seed scripts are in templates/sandbox/ — out of MVP scope to fill in)
ssh "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}" "mkdir -p $project_root"
# (deployment commands here)

# 3. Probe-before-announce
if probe_url_inside "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}" "$app_port" laravel; then
    if probe_with_retries "http://${LARV_VM_HOST}:${app_port}/" laravel; then
        app_url="http://${LARV_VM_HOST}:${app_port}"
    else
        echo "ERROR: external probe failed at $app_url" >&2
        return 1
    fi
fi

# 4. Regenerate handsoff (now with allocated values inlined)
handsoff_render_index .
# (regenerate slice handsoffs here)
handsoff_render_starting_points .

# 5. Write runbook
mkdir -p docs/larv/07-runtime
cat > docs/larv/07-runtime/sandbox-runbook.md <<EOF
# Sandbox Runbook — $slug

App URL: $app_url
DB: $db_name
Project root: $project_root
SSH: ssh ${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}
EOF

# 6. Commit
safe_commit_docs "[larv] phase 7: provision approved (app=$app_port db=$db_name)"
```

## Probe-before-announce rule (hard requirement)

Never print a URL until both the inside probe (curl from the VM at 127.0.0.1) and the outside probe (curl from the runner at LARV_VM_HOST) succeed. Use the `laravel` profile (60s × 6) for the app, `static` (5s × 5) for static servers, `nginx` (10s × 5) for the reverse proxy.

## What you do not do

- You do not write to `docs/Handsoff/slice-*.md` — that is `larv-handoff`'s job; this skill calls into it.
- You do not pick ports manually — always go through `allocate_port`.

## Required outputs

- `docs/larv/07-runtime/sandbox-runbook.md`
- Updated allocations in `STATE.yaml.execution.allocations`
- Regenerated `docs/Handsoff.md` and AI starting-point files

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/07-runtime/sandbox-runbook.md
state_updates:
  execution.allocations: [...]
  sandbox.app_url: "http://31.220.79.31:<port>"
  sandbox.status: provisioned
plugin_improvement_notes: (none)
```
```

- [ ] **Step 11.2: Add a smoke test**

Append to `tests/skills.bats`:

```bash
@test "larv-provision SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-provision/SKILL.md
    grep -q "allocate_port" skills/larv-provision/SKILL.md
    grep -q "probe_with_retries" skills/larv-provision/SKILL.md
}
```

- [ ] **Step 11.3: Run tests**

Run: `bats tests/skills.bats`
Expected: pass.

- [ ] **Step 11.4: Commit**

```bash
git add skills/larv-provision/SKILL.md tests/skills.bats
git commit -m "feat(skill): wire larv-provision to verifier + probe libraries"
```

---

## Task 12: Fill in larv-implement skill (thin loop)

**Files:**
- Modify: `skills/larv-implement/SKILL.md`

- [ ] **Step 12.1: Rewrite `skills/larv-implement/SKILL.md`**

Overwrite with:

```markdown
---
name: larv-implement
description: Phase 8 thin loop — read each docs/Handsoff/slice-NN-*.md and execute its inline bash. Same code path for same-session, subagents, and external-AI execution.
---

# larv-implement

Execute slices by following their handsoff documents. Do not improvise. Do not call plugin scripts that are not referenced inside the handsoff. The handsoff is self-contained by spec rule §3.2.

## Inputs

- `docs/larv/STATE.yaml`
- `docs/Handsoff.md`
- `docs/Handsoff/slice-NN-<name>.md` (one per slice)

## Loop body — do this for every slice in dependency order

For each `slice-NN-<name>.md`:

1. Read it from top to bottom.
2. Execute every bash block in section 12 (Implementation commands).
3. Run section 10's Definition of Done checklist.
4. Run section 13's tracker append snippet.
5. Run section 14's local-learnings append snippet if you discovered something.
6. Run section 15's STATE.yaml update snippet.
7. Write `IMPLEMENTATION-REPORT-<slice-id>.md` per section 16.
8. Soft-gate to user: print one-line slice summary, list files changed.

## Failure handling

If any step fails:

1. Mark `STATE.yaml.slices.NN.status: failed`.
2. Write the failed `IMPLEMENTATION-REPORT-<slice-id>.md` describing what broke.
3. Stop the loop. The orchestrator prompts the user: retry · skip · stop.

## What you do not do

- You do not consult elephant-carpaccio.md directly. The slice handsoff is the source of truth.
- You do not call `scripts/lib/*` directly. Everything you need is inlined in the handsoff.
- You do not change tests, ADRs, or design docs. If a slice requires a design change, stop and surface it.

## Subagent return contract

```yaml
status: complete | failed
slices_completed: [<slice-id>, ...]
slices_failed: [<slice-id>, ...]
state_updates:
  slices.status: { ... }
plugin_improvement_notes: (none)
```
```

- [ ] **Step 12.2: Add a smoke test**

Append to `tests/skills.bats`:

```bash
@test "larv-implement SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-implement/SKILL.md
    grep -q "Handsoff/slice-NN" skills/larv-implement/SKILL.md
    grep -q "self-contained" skills/larv-implement/SKILL.md
}

@test "larv-implement does not reference plugin lib scripts" {
    # spec discipline §3.2: implement reads handsoff, which is self-contained
    if grep -E 'scripts/lib/[a-z_]+\.sh' skills/larv-implement/SKILL.md; then
        echo "FAIL: larv-implement references plugin lib scripts" >&2
        return 1
    fi
}
```

- [ ] **Step 12.3: Run tests**

Run: `bats tests/skills.bats`
Expected: pass.

- [ ] **Step 12.4: Commit**

```bash
git add skills/larv-implement/SKILL.md tests/skills.bats
git commit -m "feat(skill): wire larv-implement as thin loop reading handsoff docs"
```

---

## Task 13: Fill in larv-orchestrator skill (gates + dispatch + routing)

**Files:**
- Modify: `skills/larv-orchestrator/SKILL.md`

- [ ] **Step 13.1: Rewrite `skills/larv-orchestrator/SKILL.md`**

Overwrite with:

```markdown
---
name: larv-orchestrator
description: Top-level dispatcher. Per-phase soft gate, hard gate before Phase 7, routing menu before Phase 8. Spawns fresh subagents per phase.
---

# larv-orchestrator

Drive the larv workflow. Read `STATE.yaml`, decide the next phase, dispatch the appropriate skill, gate on its output, commit, and advance.

## Invocation modes

- **greenfield** — full flow (Phase −1 → 11). Invoked by `/larv:full`.
- **feature** — `/larv:feature <name>` mini-flow. Reuses existing docs; appends new ADRs and slices.
- **debug** — `/larv:debug <issue>` mini-flow. Adds a single fix slice.

## On entry

```bash
. scripts/lib/vm.sh
. scripts/lib/git_safe.sh
. scripts/lib/gate.sh
. scripts/lib/handsoff.sh

# 1. Read STATE.yaml; refuse mode mismatch.
# 2. Acquire lock via scripts/lock.sh.
# 3. Load LEARNINGS digest from plugin repo's LEARNINGS.md.
# 4. Determine next phase from STATE.yaml.phase.current.
```

## Per-phase loop

For each phase `N`:

1. **Spawn the phase subagent** (skill `larv-<name>`).
2. **Wait for its return contract** (yaml from §8 of the spec).
3. **Apply state_updates** via `bash scripts/state.sh update`.
4. **Auto-commit** via `safe_commit_docs "[larv] phase $N: $name approved"`.
5. **Soft gate** via `soft_gate "$dir" "$N" "$name" "$summary" "$changed_csv"`.
6. **Loopback check.** If subagent's `state_updates.current_phase` points backward, jump there.

## Hard gates

- **Before Phase 7**: `hard_gate "$dir" 7 "Provisioning will allocate VM ports/DB/project root and may write to the VM."` Refuse to advance without `approved`.
- **Before Phase 8**: After `larv-handoff` succeeds, call `routing_menu "$dir"`. If `mode=handed-off-external`, mark `/larv:full` complete and exit. Otherwise, dispatch `larv-implement`.

## Mode handling

| Mode | Behavior |
|---|---|
| `executing-same-session` | Dispatch `larv-implement` in this session. |
| `executing-subagents` | Dispatch one subagent per slice (parallel where dependencies allow). |
| `handed-off-external` | Print "Plan complete. Open another AI session, point it at docs/Handsoff.md." Exit. |

## Failure handling

If a phase subagent returns `status: failed`, write `errors_unresolved` to STATE.yaml and stop. The user must run `/larv:resume` after fixing.

## On exit

```bash
bash scripts/lock.sh release "$dir"
bash scripts/state.sh update "$dir" '.project.last_updated_at = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"'
```

## What you do not do

- You do not run code from the plan yourself; phase subagents do.
- You do not bypass gates; soft + hard gates per spec §4.2.
- You do not commit non-`docs/`/`adr/` paths; `safe_commit_docs` enforces this.
```

- [ ] **Step 13.2: Add a smoke test**

Append to `tests/skills.bats`:

```bash
@test "larv-orchestrator SKILL.md describes hybrid gates" {
    grep -q "soft_gate" skills/larv-orchestrator/SKILL.md
    grep -q "hard_gate" skills/larv-orchestrator/SKILL.md
    grep -q "routing_menu" skills/larv-orchestrator/SKILL.md
    grep -q "Hard gates" skills/larv-orchestrator/SKILL.md
}

@test "larv-orchestrator handles all three execution modes" {
    grep -q "executing-same-session" skills/larv-orchestrator/SKILL.md
    grep -q "executing-subagents" skills/larv-orchestrator/SKILL.md
    grep -q "handed-off-external" skills/larv-orchestrator/SKILL.md
}
```

- [ ] **Step 13.3: Run tests**

Run: `bats tests/skills.bats`
Expected: pass.

- [ ] **Step 13.4: Commit**

```bash
git add skills/larv-orchestrator/SKILL.md tests/skills.bats
git commit -m "feat(skill): wire larv-orchestrator with gates + routing"
```

---

## Task 14: Fill in /larv:feature command

**Files:**
- Modify: `commands/larv-feature.md`

- [ ] **Step 14.1: Rewrite `commands/larv-feature.md`**

Overwrite with:

```markdown
---
name: larv:feature
description: Add a feature to a managed Laravel app. Mini-flow with full discipline parity — gates, handsoff, tracker, AI starting-points refresh.
---

Argument: `<feature-name>` — short slug for the feature.

Invoke the `larv-orchestrator` skill in feature mode with the provided name.

## Preconditions

- `docs/larv/STATE.yaml` must exist (project must be managed).
- Working tree must be clean outside of `docs/` and `adr/`.

## Mini-flow phases (each gated like `/larv:full`)

1. **Mini DDD interview** — only if the feature introduces new business words/invariants. Output appends to `docs/larv/ddd-interview/`. (Layer 2; in MVP this step is a single recommendation prompt: "any new business invariants? if yes, list them; if no, type `none`.")
2. **Mini discuss** — only for new tech needs. Output appends to `docs/larv/00-discuss/library-decisions.md`.
3. **Architecture delta** — new ADR if a previous decision changes.
4. **Data / API / UI deltas** — appended to existing design docs.
5. **Mini premortem** — 1–2 questions.
6. **Mini plan** — 1–N new slices with `depends_on` linking to existing slices, written to `docs/larv/06-implementation/elephant-carpaccio.md`.
7. **Per-slice handsoff** generation via `larv-handoff`.
8. **Tracker entries** appended (one per slice).
9. **AI starting-point files** regenerated.
10. **Doc-site rebuild** (Layer 2).
11. **Routing-menu hard gate** before implementation.

`STATE.yaml.features` array gains an entry: `{ name, started_at, slices: [...], status }`.

## What changes vs `/larv:full`

- The pre-flight phase is replaced with a delta check ("verify allocations are still valid").
- Phases 0a, 0, 1, 2 produce *deltas*, not full documents.
- Implementation tracker entries are tagged `type: feature`.

## Subagent return contract

Per `larv-orchestrator`'s contract.
```

- [ ] **Step 14.2: Add a test**

Append to `tests/commands.bats`:

```bash
@test "larv-feature command describes mini-flow with gates" {
    grep -q "Mini DDD interview" commands/larv-feature.md
    grep -q "Per-slice handsoff" commands/larv-feature.md
    grep -q "Tracker entries" commands/larv-feature.md
    grep -q "Routing-menu hard gate" commands/larv-feature.md
}
```

- [ ] **Step 14.3: Run tests**

Run: `bats tests/commands.bats`
Expected: pass.

- [ ] **Step 14.4: Commit**

```bash
git add commands/larv-feature.md tests/commands.bats
git commit -m "feat(command): /larv:feature mini-flow with full discipline parity"
```

---

## Task 15: Fill in /larv:debug command

**Files:**
- Modify: `commands/larv-debug.md`

- [ ] **Step 15.1: Rewrite `commands/larv-debug.md`**

Overwrite with:

```markdown
---
name: larv:debug
description: Fix a bug in a managed Laravel app. Mini-flow with full discipline parity — gates, handsoff, tracker, AI starting-points refresh.
---

Argument: `<issue>` — one-line description of the bug.

Invoke the `larv-orchestrator` skill in debug mode with the provided issue text.

## Preconditions

- `docs/larv/STATE.yaml` must exist.
- Working tree must be clean outside of `docs/` and `adr/`.

## Mini-flow phases

1. **Domain-context check** — does this bug imply a missing invariant? If yes, append to `docs/larv/01-domain/business-invariants.md` and create an ADR explaining the change.
2. **Root-cause investigation** — diff of current behavior vs documented invariants and acceptance criteria. Output: `docs/larv/05-premortem/debug-<issue-slug>-rca.md`.
3. **Fix slice** — single slice with regression test. Appended to `docs/larv/06-implementation/elephant-carpaccio.md` with `type: bug`.
4. **Per-slice handsoff** generation via `larv-handoff`.
5. **Tracker entry** with `type: bug` (or `hotfix` for production patches).
6. **AI starting-point files** regenerated.
7. **Doc-site rebuild** (Layer 2).
8. **Implementation hard gate**: even debug fixes go through the routing menu.

`STATE.yaml.debugs` array gains an entry: `{ issue, slug, started_at, slice_id, status }`.

## What changes vs `/larv:feature`

- No design phase; reuse existing UI/brand.
- Test-strategy phase is replaced with a single regression-test requirement in the slice's DoD.

## Subagent return contract

Per `larv-orchestrator`'s contract.
```

- [ ] **Step 15.2: Add a test**

Append to `tests/commands.bats`:

```bash
@test "larv-debug command describes mini-flow with regression test" {
    grep -q "Domain-context check" commands/larv-debug.md
    grep -q "regression test" commands/larv-debug.md
    grep -q "Tracker entry" commands/larv-debug.md
    grep -q "Implementation hard gate" commands/larv-debug.md
}
```

- [ ] **Step 15.3: Run tests**

Run: `bats tests/commands.bats`
Expected: pass.

- [ ] **Step 15.4: Commit**

```bash
git add commands/larv-debug.md tests/commands.bats
git commit -m "feat(command): /larv:debug mini-flow with full discipline parity"
```

---

## Task 16: Integration test — end-to-end MVP flow

**Files:**
- Create: `tests/orchestrator-flow.bats`
- Create: `tests/fixtures/integration-greenfield/elephant-carpaccio.md`
- Create: `tests/fixtures/integration-greenfield/decisions.md`

This test exercises a scripted dry-run of the orchestrator's library calls (without dispatching real subagents). It confirms the libraries compose into a working pipeline and that all spec invariants hold on the produced artifacts.

- [ ] **Step 16.1: Create the fixtures**

Create `tests/fixtures/integration-greenfield/elephant-carpaccio.md`:

```markdown
# Slice Plan

## slice-01-auth-scaffold
goal: Stand up Sanctum auth with seeded admin
depends_on: []
parallel: false

## slice-02-todos-crud
goal: CRUD for todo items, scoped per user
depends_on: [slice-01-auth-scaffold]
parallel: false
```

Create `tests/fixtures/integration-greenfield/decisions.md`:

```markdown
# Decisions

| ID | Title | Status | Date |
|---|---|---|---|
| 0001 | Use Laravel 12 | accepted | 2026-05-06 |
| 0002 | Filament for admin | accepted | 2026-05-06 |
```

- [ ] **Step 16.2: Write the integration test**

Create `tests/orchestrator-flow.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    REPO="$(mktemp -d)"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "test"
    mkdir -p "$REPO/docs/larv/01-domain" "$REPO/docs/larv/02-architecture" \
        "$REPO/docs/larv/03-design" "$REPO/docs/larv/06-implementation" \
        "$REPO/adr"
    bash scripts/state.sh init "$REPO" todo-app greenfield

    cp tests/fixtures/integration-greenfield/elephant-carpaccio.md \
       "$REPO/docs/larv/06-implementation/elephant-carpaccio.md"
    cp tests/fixtures/integration-greenfield/decisions.md \
       "$REPO/docs/larv/decisions.md"

    echo "# C4 Context\n\nMermaid here." > "$REPO/docs/larv/02-architecture/c4-context.md"
    echo "# Domain model" > "$REPO/docs/larv/01-domain/domain-model.md"

    git -C "$REPO" add . && git -C "$REPO" commit -q -m "fixtures"
}

teardown() { [ -d "$REPO" ] && rm -rf "$REPO"; }

@test "integration: end-to-end handsoff + tracker + starting-points" {
    cd "$REPO"

    bash -c '
        . '"$PROJECT_ROOT"'/scripts/lib/vm.sh
        . '"$PROJECT_ROOT"'/scripts/lib/handsoff.sh
        . '"$PROJECT_ROOT"'/scripts/lib/tracker.sh
        . '"$PROJECT_ROOT"'/scripts/lib/git_safe.sh

        tracker_init "."
        tracker_render "."
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." app-port 8001
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." mockup-port 9001
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." db-name larv_todo_app_2026_05
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." project-root /srv/larv/todo-app-2026-05

        handsoff_render_index "."
        handsoff_render_slice "." slice-01 auth-scaffold
        handsoff_render_slice "." slice-02 todos-crud
        handsoff_render_starting_points "."
    '

    [ -f docs/Handsoff.md ]
    [ -f docs/Handsoff/slice-01-auth-scaffold.md ]
    [ -f docs/Handsoff/slice-02-todos-crud.md ]
    [ -f CLAUDE.md ]
    [ -f AGENTS.md ]
    [ -f GEMINI.md ]
    [ -f .cursor/rules/larv.mdc ]
    [ -f .codex/AGENTS.md ]
    [ -f docs/larv/implementation-tracker.yaml ]

    grep -q "31.220.79.31" docs/Handsoff.md
    grep -q "8001" docs/Handsoff.md
    grep -q "larv_todo_app_2026_05" docs/Handsoff.md

    # Spec discipline §3.2 — handsoff is self-contained
    ! grep -rE 'scripts/(lib/)?(state|lock|tracker|handsoff|verifier|probe|gate|git_safe)\.sh' \
        docs/Handsoff.md docs/Handsoff/

    # Spec discipline §15.2 — Handsoff includes inlined sections
    grep -q "Handsoff — todo-app" docs/Handsoff.md
    grep -q "Sandbox info" docs/Handsoff.md

    # Starting-point files all reference Handsoff.md
    grep -q "Handsoff.md" CLAUDE.md
    grep -q "Handsoff.md" AGENTS.md
    grep -q "Handsoff.md" GEMINI.md
    grep -q "Handsoff.md" .cursor/rules/larv.mdc
    grep -q "Handsoff.md" .codex/AGENTS.md
}

@test "integration: routing menu sets STATE.yaml.execution.mode" {
    cd "$REPO"
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/gate.sh
        echo subagents | routing_menu '.'
    "
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' docs/larv/STATE.yaml
    [ "$output" = "executing-subagents" ]
}

@test "integration: safe_commit_docs commits only docs/ and adr/" {
    cd "$REPO"
    echo "non-docs change" > app.php
    echo "doc change" > docs/larv/00-discuss/product-brief.md
    mkdir -p docs/larv/00-discuss
    echo "doc change" > docs/larv/00-discuss/product-brief.md
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/git_safe.sh
        safe_commit_docs 'msg'
    "
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "dirty path"

    rm app.php
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/git_safe.sh
        safe_commit_docs 'msg'
    "
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 16.3: Run the integration test**

Run: `bats tests/orchestrator-flow.bats`
Expected: 3 tests pass.

- [ ] **Step 16.4: Run the full bats suite as a regression check**

Run: `bats tests/`
Expected: all bats files pass.

- [ ] **Step 16.5: Commit**

```bash
git add tests/orchestrator-flow.bats tests/fixtures/integration-greenfield
git commit -m "test(integration): end-to-end MVP handsoff + tracker + routing flow"
```

---

## Task 17: README + LEARNINGS update

**Files:**
- Modify: `README.md` — add "MVP behavior" section
- Modify: `LEARNINGS.md` — add an entry about the design discipline rules
- Modify: `CHANGELOG.md` — record the MVP

- [ ] **Step 17.1: Append to `CHANGELOG.md`**

After the current entries, add:

```markdown
## 0.3.0 (2026-05-06) — MVP overhaul

- **Workflow control**: hybrid gates added; soft gate after every approved phase, hard gate before Phase 7 and Phase 8.
- **Routing menu** before Phase 8: `same-session` | `subagents` | `handoff`. Sets `STATE.yaml.execution.mode`.
- **Handsoff system**: mandatory generation of `docs/Handsoff.md` (index) and `docs/Handsoff/slice-NN-<name>.md` (per slice). Self-contained — no plugin script references inside handsoff content.
- **Verifier**: live-scan port/db/project-root allocation, auto-pick on conflict.
- **Probe-before-announce**: per-service retry policies (`static`, `laravel`, `nginx`); inside + outside curl confirms before any URL is announced.
- **Auto-commit**: per approved phase, `docs/` + `adr/` only, default-branch-aware.
- **Implementation tracker**: `implementation-tracker.yaml` (canonical) + rendered `.md` view. Append protocol inlined in every slice handsoff.
- **AI starting-point files**: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/larv.mdc`, `.codex/AGENTS.md` — generated before the Phase 8 hard gate.
- **/larv:feature** and **/larv:debug** preserve full discipline (gates, handsoff, tracker, starting-point regen).
- **VM constant** `LARV_VM_HOST=31.220.79.31` isolated to `scripts/lib/vm.sh`.

Layer 2 (DDD interview, design picker, mockup server, doc-site, Discuss enrichment) is a separate plan.
```

- [ ] **Step 17.2: Add an MVP-behavior section to `README.md`**

After the "Prerequisites" section, add:

```markdown
## How the MVP enforces venue parity

larv produces docs in `docs/Handsoff.md` and `docs/Handsoff/slice-NN-*.md` that are self-contained: every action a foreign AI must take is encoded as inline bash, no plugin script references. Same-session, subagents, and external-AI execution all read these same files. There is no internal Phase 8 logic distinct from "what we tell a foreign AI to do."

The routing menu (Phase 7 → 8) lets you choose where to execute:

- `same-session` — this Claude Code session continues
- `subagents` — fresh subagents per slice
- `handoff` — stop here; you point another AI at `docs/Handsoff.md`

All three options use the same handsoff documents. The plugin's job ends at the handoff for the third option; for the first two, it loops slices through `larv-implement`, which itself only reads handsoff content.
```

- [ ] **Step 17.3: Append to `LEARNINGS.md`**

Add:

```markdown
## 2026-05-06 — Discipline rules from MVP design

[plugin] Three invariants hold all design choices together:

1. **Venue parity**: same-session, subagents, and foreign-AI all read the same handsoff. No special internal-only Phase 8 logic.
2. **Handsoff self-containment**: every action a foreign AI takes is inline bash inside the handsoff document. No `scripts/lib/*` references.
3. **Probe-before-announce**: no URL is printed until both inside-VM and outside curl confirm the service responds.

Bake these into every future skill prompt; they're easy to forget and load-bearing.

[project] When asking the user a question, always pair it with `Recommendation / Why / Tradeoffs`. Strong norm, not enforced — easy for skills to drift.
```

- [ ] **Step 17.4: Run the existing readme/learnings tests**

Run: `bats tests/readme.bats tests/learnings.bats`
Expected: pass.

- [ ] **Step 17.5: Commit**

```bash
git add README.md CHANGELOG.md LEARNINGS.md
git commit -m "docs: record MVP overhaul behaviors and discipline rules"
```

---

## Task 18: Bump plugin version

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.codex-plugin/plugin.json`

- [ ] **Step 18.1: Bump `.claude-plugin/plugin.json` to `0.3.0`**

Find the `"version": "0.2.2"` line and change it to `"version": "0.3.0"`.

- [ ] **Step 18.2: Bump `.claude-plugin/marketplace.json` to `0.3.0`**

Find the `"version": "0.2.2"` line and change it to `"version": "0.3.0"`.

- [ ] **Step 18.3: Bump `.codex-plugin/plugin.json` to `0.3.0`**

Find the `"version"` field (likely `"0.2.2"` or similar) and change to `"0.3.0"`.

- [ ] **Step 18.4: Run manifest tests**

Run: `bats tests/manifest.bats`
Expected: pass.

- [ ] **Step 18.5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json
git commit -m "chore: bump plugin version to 0.3.0 (MVP overhaul)"
```

---

## Self-Review

**1. Spec coverage:**

| Spec section | Plan task |
|---|---|
| §3.1 Venue parity | Task 12 (larv-implement reads handsoff only); Task 16 integration test asserts |
| §3.2 Handsoff self-containment | Task 8 (handsoff.sh); Task 16 grep assertion |
| §3.3 Probe-before-announce | Task 2 (probe.sh); Task 11 (provision uses it) |
| §4.2 Hybrid gates | Task 9 (soft_gate, hard_gate); Task 13 (orchestrator wires them) |
| §4.3 Routing menu | Task 9 (routing_menu); Task 13 (orchestrator dispatches) |
| §14 Verifier | Task 3 (verifier.sh) |
| §14.4 VM constant | Task 1 (vm.sh) |
| §15 Handsoff system | Task 7 (templates) + Task 8 (library) + Task 10 (skill) |
| §16 Implementation tracker | Task 5 (tracker.sh + template) |
| §17 AI starting-point files | Task 7 (template) + Task 8 (handsoff_render_starting_points) |
| §18 Auto-commit | Task 4 (git_safe.sh); Task 13 (orchestrator calls it) |
| §19 /feature + /debug parity | Task 14, Task 15 |
| §21 Discipline rules | Task 12 + Task 16 enforce the most critical (handsoff self-containment); recommendation norm is documented in Task 17 LEARNINGS |
| STATE.yaml extensions | Task 6 |
| Skill stub fill-in | Task 10 (handoff), Task 11 (provision), Task 12 (implement), Task 13 (orchestrator) |
| Tests for every library | Tasks 1–9 each include bats; Task 16 integration |

Layer 2 items (DDD interview, design picker, mockup server, doc-site, Discuss enrichment) are explicitly out of MVP scope per spec §22.1.

**2. Placeholder scan:**

- Templates use `{{token}}` substitutions filled by `handsoff_collect_tokens` — these are intentional template variables, not plan placeholders.
- Slice handsoff template has `(see slice plan)` defaults — implementing skills will fill these from `elephant-carpaccio.md` parsing; that parsing is wrapped into `handsoff_render_slice` in Task 8 step 3 (the function accepts only `slice_id` + `slice_slug` for MVP; deeper slice-card parsing happens in Layer 2 when slice cards are written by `larv-plan`).
- No "TBD", "TODO", "implement later" inside step bodies.

**3. Type consistency:**

- `LARV_VM_HOST` (Task 1) → used in probe.sh (Task 2), verifier.sh (Task 3), handsoff.sh (Task 8): ✓
- `tracker_init`, `tracker_append`, `tracker_render` signatures consistent across Tasks 5, 8, 16: ✓
- `allocate_port` roles `mockup`/`docsite`/`app` consistent across Tasks 3, 11: ✓
- `safe_commit_docs` signature `(message)` consistent across Tasks 4, 8, 11, 13: ✓
- `soft_gate(dir, num, name, summary, csv)` and `hard_gate(dir, num, prompt)` consistent across Task 9, Task 13: ✓
- `routing_menu(dir)` consistent across Task 9, Task 13: ✓
- `STATE.yaml.execution.mode` enum (`not-yet-decided` / `executing-same-session` / `executing-subagents` / `handed-off-external`) consistent across Task 6, Task 9, Task 13: ✓
- `tracker.entries[].type` enum (`feature` / `bug` / `hotfix` / `refactor` / `migration`) consistent across Task 5, Task 14, Task 15: ✓

No issues.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-06-larv-plugin-mvp.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
