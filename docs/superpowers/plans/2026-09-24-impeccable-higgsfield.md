# Impeccable + Higgsfield Design Directions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Impeccable-directions + Higgsfield-comps design round to larv (Phase 3 mode and `/larv:redesign-impeccable-higgsfield`) that presents the options on a probe-confirmed public sandbox URL.

**Architecture:** All behavior lives in agent-neutral bash: `scripts/lib/design_tools.sh` (tool + host resolution), `scripts/lib/higgsfield.sh` (the only code that talks to Higgsfield: account, cost, comp generation), `scripts/design-setup.sh` (readiness check / installer), and `scripts/design-directions.sh` (context → seed → cost → comps → board → serve → pick). Skills and commands are thin wrappers telling any agent (Claude Code, Grok, Codex) which script step to run and where to pause for the user.

**Tech Stack:** bash, jq, yq, python3 (existing `impeccable.sh`), bats, PHP built-in static server (existing `static_server.sh`), Higgsfield CLI 1.1.26, Impeccable skill 4.3.1 / engine 0.1.5.

**Spec:** `docs/superpowers/specs/2026-09-24-impeccable-higgsfield-design.md`

## Global Constraints

- Repo: `/home/claude-team/kaito/workflow`, branch `feat/impeccable-higgsfield-design`. The branch carries ~91 pre-existing unstaged modifications that are **not ours**: always `git add` explicit paths, never `git add -A`/`.`/`-u`.
- Higgsfield model `nano_banana_pro`, resolution `2k`, aspect `3:2` (desktop) or `9:16` (phone). One comp per dealt direction; declined challengers never get a comp.
- Credit cap per round: `LARV_HIGGSFIELD_CREDIT_CAP`, default `10`.
- Higgsfield archive: `https://github.com/higgsfield-ai/cli/releases/download/v1.1.26/hf_1.1.26_linux_amd64.tar.gz`, SHA-256 `5d666fae70c99b7388690191a649d1487962250ed50820e079edfd1ffac7bf5b`, only for `uname -sm` = `Linux x86_64`.
- Shared install paths: Higgsfield `~/.local/share/larv/higgsfield/higgsfield`; Impeccable skill `~/.claude/skills/impeccable`, `~/.agents/skills/impeccable`; engine `~/.impeccable/bin/0.1.5/impeccable`.
- Never run or print `higgsfield auth token`. Never run `higgsfield auth login` from a script.
- Never announce `localhost`, `127.*` or `sandbox.example.com`.
- Reference images for comps are accepted only from `<out>/refs/` and only when `<out>/refs/FICTIONAL-DATA-CONFIRMED` exists.
- Tests never touch the network or spend credits: every test sets `HOME` to a temp dir, `PATH` to `"$BIN_DIR:/usr/local/bin:/usr/bin:/bin"`, and stubs via `LARV_HIGGSFIELD_BIN` / `LARV_IMPECCABLE_SKILL_DIR`.
- The larv guard hook (`hooks/guard-pre-tool.sh`) blocks Write/Edit on paths containing `/.claude/`, `/.agents/`, `/.codex/`, `*token*`, `*credentials*`. Do not name new files with those words; installs into `~/.claude/skills` happen only via `design-setup.sh install` run through Bash.
- Every new skill/command/codex skill starts with the standard "larv Headroom Combo" block (copy from `skills/larv-redesign-attio-finance/SKILL.md` lines 6–8).
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Full-suite runs take >10 min: use `bats --jobs 4 tests/` in the background; single files run directly.

## Review Focus

- Higgsfield signed out or `account status` failing mid-round → `comps` must fall back per card to wireframes and the board must still serve (no half-empty board, no crash). Pinned in Task 4 (`comps falls back per card`) and Task 5 (`board renders wireframe when comp missing`).
- `options.json` authored by the agent missing a required field or containing a duplicate id → `board` must refuse with a message naming the card, not render a broken page. Pinned in Task 5.
- Prompt text containing quotes, `$`, backticks or newlines → must reach Higgsfield verbatim with no shell expansion. Pinned in Task 2 (`hf_generate_comp passes prompt verbatim`).
- Running the round twice in the same project → second `comps` must not re-spend on cards that already have a PNG. Pinned in Task 4 (`comps skips existing`).
- Project without `docs/larv/STATE.yaml` (e.g. `loi/prs`) → slug from directory basename, port recorded in `run.yaml`, `state.sh` never called. Pinned in Task 1 (`design_slug`) and Task 5 (`serve without STATE`).

---

## File Structure

| File | Responsibility |
|---|---|
| Create `scripts/lib/design_tools.sh` | Resolve Higgsfield wrapper, Impeccable launcher, public host, project slug. No side effects. |
| Create `scripts/lib/higgsfield.sh` | `hf_account_json`, `hf_credits`, `hf_cost`, `hf_generate_comp`. Only file that invokes the Higgsfield CLI. |
| Create `templates/higgsfield-wrapper.sh` | Wrapper installed next to the Higgsfield binary (same as on this server). |
| Create `scripts/design-setup.sh` | `check` (exit 0 ready / 3 fallback-only / 1 hard fail), `install`, `help`. |
| Modify `scripts/pre-flight.sh:90-97,155-160` | Report `design-setup.sh check` output (report only). |
| Modify `scripts/impeccable.sh` (`cmd_context`) | `LARV_IMPECCABLE_PRODUCT_ONLY=1` writes PRODUCT.md only. |
| Create `scripts/design-directions.sh` | Steps `context seed cost comps board serve pick`. |
| Create `templates/design-board.html.tmpl` | Board page shell (CSS + placeholders) filled by `board`. |
| Create `bundle/impeccable/` | Vendored Impeccable skill 4.3.1 + `UPSTREAM.md`. |
| Modify `bundle/VERSIONS.yaml` | `impeccable-skill: "4.3.1"`, `higgsfield-cli: "1.1.26"`. |
| Create `commands/larv-design-setup.md`, `commands/larv-redesign-impeccable-higgsfield.md` | Command entry points (Claude Code + Grok). |
| Create `skills/larv-redesign-impeccable-higgsfield/SKILL.md` | Redesign workflow. |
| Create `codex-skills/design-setup/SKILL.md`, `codex-skills/redesign-impeccable-higgsfield/SKILL.md` | Codex mirrors. |
| Modify `skills/larv-discuss/SKILL.md`, `skills/larv-design/SKILL.md` | Phase 3 `impeccable-higgsfield` mode. |
| Modify `README.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` (if it carries a version) | Docs + 0.4.30. |
| Tests: create `tests/design_tools.bats`, `tests/higgsfield.bats`, `tests/design_setup.bats`, `tests/design_directions.bats`; modify `tests/commands.bats`, `tests/skills.bats`, `tests/codex.bats`, `tests/readme.bats`, `tests/impeccable.bats`, `tests/pre-flight.bats` | |

---

### Task 1: Tool and host resolution library

**Files:**
- Create: `scripts/lib/design_tools.sh`
- Test: `tests/design_tools.bats`

**Interfaces:**
- Produces:
  - `design_higgsfield_bin` → prints path, returns 1 if none. If `LARV_HIGGSFIELD_BIN` is set, it is the only candidate.
  - `design_impeccable_launcher` → prints path to `scripts/impeccable` launcher, returns 1 if none. If `LARV_IMPECCABLE_SKILL_DIR` is set, it is the only candidate.
  - `design_public_host` → prints host, returns 1 if none usable.
  - `design_slug <project_dir>` → prints slug.

- [ ] **Step 1: Write the failing tests**

`tests/design_tools.bats`:

```bash
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/design_tools.bats`
Expected: FAIL — `scripts/lib/design_tools.sh: No such file or directory`.

- [ ] **Step 3: Implement `scripts/lib/design_tools.sh`**

```bash
#!/usr/bin/env bash
# Resolve the shared design tools (Higgsfield wrapper, Impeccable launcher),
# the public host used to announce design boards, and the project slug.
# Sourced by design-setup.sh and design-directions.sh. No side effects.

DESIGN_TOOLS_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

design_higgsfield_bin() {
    if [ -n "${LARV_HIGGSFIELD_BIN:-}" ]; then
        [ -x "$LARV_HIGGSFIELD_BIN" ] && { echo "$LARV_HIGGSFIELD_BIN"; return 0; }
        return 1
    fi
    local shared="$HOME/.local/share/larv/higgsfield/higgsfield"
    [ -x "$shared" ] && { echo "$shared"; return 0; }
    command -v higgsfield 2>/dev/null
}

design_impeccable_launcher() {
    if [ -n "${LARV_IMPECCABLE_SKILL_DIR:-}" ]; then
        [ -x "$LARV_IMPECCABLE_SKILL_DIR/scripts/impeccable" ] \
            && { echo "$LARV_IMPECCABLE_SKILL_DIR/scripts/impeccable"; return 0; }
        return 1
    fi
    local c
    for c in "$DESIGN_TOOLS_PLUGIN_ROOT/bundle/impeccable" \
             "$HOME/.claude/skills/impeccable" \
             "$HOME/.agents/skills/impeccable"; do
        [ -x "$c/scripts/impeccable" ] && { echo "$c/scripts/impeccable"; return 0; }
    done
    return 1
}

design_public_host() {
    local host="${LARV_VM_HOST:-}"
    if [ -z "$host" ] || [ "$host" = "sandbox.example.com" ]; then
        host="$( (hostname -I 2>/dev/null || true) | awk '{print $1}')"
    fi
    case "$host" in
        ""|localhost|127.*|sandbox.example.com) return 1 ;;
    esac
    echo "$host"
}

design_slug() {
    local dir="$1" slug=""
    if [ -f "$dir/docs/larv/STATE.yaml" ]; then
        slug="$(yq -r '.project.slug // ""' "$dir/docs/larv/STATE.yaml" 2>/dev/null || true)"
    fi
    if [ -z "$slug" ] || [ "$slug" = "null" ]; then
        slug="$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    fi
    echo "$slug"
}
```

Note: the launcher must be `-x`. The Impeccable launcher ships as `scripts/impeccable` (a sh script); `cp -a` keeps its mode. If a copy lost the bit, `chmod +x` it during Task 6.

- [ ] **Step 4: Run tests**

Run: `bats tests/design_tools.bats`
Expected: 7 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/design_tools.sh tests/design_tools.bats
git commit -m "feat(design): resolve shared design tools and public host

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Higgsfield library (the Higgsfield unit)

**Files:**
- Create: `scripts/lib/higgsfield.sh`
- Create: `tests/fixtures/higgsfield-stub.sh` (shared stub for Tasks 2–5)
- Test: `tests/higgsfield.bats`
- Modify: `docs/superpowers/specs/2026-09-24-impeccable-higgsfield-design.md` (name the Higgsfield unit explicitly)

**Interfaces:**
- Consumes: `design_higgsfield_bin` (Task 1).
- Produces:
  - `HF_MODEL` (default `nano_banana_pro`, override `LARV_HIGGSFIELD_MODEL`), `HF_RESOLUTION` (`2k`).
  - `hf_account_json` → prints `{"credits":N,"email":"…","subscription_plan_type":"…"}`; returns non-zero when signed out/unavailable.
  - `hf_credits` → prints integer credits.
  - `hf_cost <prompt_file> <aspect>` → prints integer credits for one comp.
  - `hf_generate_comp <prompt_file> <aspect> <out_png> [ref_png]` → writes `out_png`, prints the job id; non-zero on any failure (no partial file left).

- [ ] **Step 1: Write the stub**

`tests/fixtures/higgsfield-stub.sh` (executable):

```bash
#!/usr/bin/env bash
# Test double for the Higgsfield CLI. Logs every call; never touches network.
# Env: STUB_DIR (required), STUB_CREDITS (default 79), STUB_SIGNED_OUT=1,
#      STUB_FAIL_CREATE=1, STUB_COST (default 2)
set -u
printf '%s\n' "$*" >>"$STUB_DIR/hf.log"
case "$1 ${2:-}" in
    "account status")
        [ "${STUB_SIGNED_OUT:-0}" = "1" ] && { echo "not logged in" >&2; exit 1; }
        printf '{"credits":%s,"email":"dtt@oakdriveventures.com","subscription_plan_type":"lite"}\n' "${STUB_CREDITS:-79}"
        ;;
    "generate cost")
        printf '{"credits":%s}\n' "${STUB_COST:-2}"
        ;;
    "generate create")
        [ "${STUB_FAIL_CREATE:-0}" = "1" ] && { echo "insufficient credits" >&2; exit 1; }
        n=$(ls "$STUB_DIR"/result-*.png 2>/dev/null | wc -l)
        out="$STUB_DIR/result-$n.png"
        printf '\x89PNG\r\n\x1a\nstub' >"$out"
        # record the exact prompt argument for verbatim checks
        prev=""; for a in "$@"; do [ "$prev" = "--prompt" ] && printf '%s' "$a" >"$STUB_DIR/last-prompt.txt"; prev="$a"; done
        printf '[{"id":"job-%s","status":"completed","result_url":"file://%s"}]\n' "$n" "$out"
        ;;
    "auth token")
        echo "FORBIDDEN" >&2; exit 99 ;;
    *) echo "stub: unhandled $*" >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Write the failing tests**

`tests/higgsfield.bats`:

```bash
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
```

- [ ] **Step 3: Run to verify failure**

Run: `chmod +x tests/fixtures/higgsfield-stub.sh && bats tests/higgsfield.bats`
Expected: FAIL — `scripts/lib/higgsfield.sh: No such file or directory`.

- [ ] **Step 4: Implement `scripts/lib/higgsfield.sh`**

```bash
#!/usr/bin/env bash
# Higgsfield CLI access for larv design comps. The only code that invokes the
# Higgsfield CLI. Requires scripts/lib/design_tools.sh sourced first.
# Never calls `auth token` or `auth login`.

HF_MODEL="${LARV_HIGGSFIELD_MODEL:-nano_banana_pro}"
HF_RESOLUTION="2k"

__hf() {
    local bin
    bin="$(design_higgsfield_bin)" || { echo "ERROR: Higgsfield CLI not installed (run /larv:design-setup)" >&2; return 1; }
    "$bin" "$@"
}

hf_account_json() {
    local json
    json="$(__hf account status --json 2>/dev/null)" || return 1
    printf '%s' "$json" | jq -e '.credits != null' >/dev/null 2>&1 || return 1
    printf '%s\n' "$json" | jq -c '{credits, email, subscription_plan_type}'
}

hf_credits() {
    hf_account_json | jq -r '.credits'
}

hf_cost() {
    local prompt_file="$1" aspect="$2"
    __hf generate cost "$HF_MODEL" --prompt "$(cat "$prompt_file")" \
        --aspect_ratio "$aspect" --resolution "$HF_RESOLUTION" --json \
        | jq -r '.credits'
}

hf_generate_comp() {
    local prompt_file="$1" aspect="$2" out_png="$3" ref="${4:-}"
    local args=(generate create "$HF_MODEL" --prompt "$(cat "$prompt_file")"
                --aspect_ratio "$aspect" --resolution "$HF_RESOLUTION" --wait --json)
    [ -n "$ref" ] && args+=(--image-references "$ref")
    local json url id tmp
    json="$(__hf "${args[@]}")" || return 1
    url="$(printf '%s' "$json" | jq -r '[.. | objects | .result_url? // empty] | first // empty')"
    id="$(printf '%s' "$json" | jq -r '[.. | objects | .id? // empty] | first // empty')"
    [ -n "$url" ] || { echo "ERROR: Higgsfield returned no result_url" >&2; return 1; }
    mkdir -p "$(dirname "$out_png")"
    tmp="$out_png.part"
    if ! curl -fsSL -o "$tmp" "$url" || [ ! -s "$tmp" ]; then
        rm -f "$tmp"; return 1
    fi
    mv "$tmp" "$out_png"
    echo "$id"
}
```

- [ ] **Step 5: Run tests**

Run: `bats tests/higgsfield.bats`
Expected: 6 tests, 0 failures.

- [ ] **Step 6: Amend the spec so Higgsfield is its own unit**

In the spec's Architecture section, insert after "Unit 1" a new heading `### Unit 1b — scripts/lib/higgsfield.sh (Higgsfield)` with this body:

```markdown
The only code that talks to Higgsfield. `hf_account_json`/`hf_credits` (balance, never tokens), `hf_cost <prompt> <aspect>` (price check, no spend), `hf_generate_comp <prompt> <aspect> <out.png> [ref.png]` (`generate create nano_banana_pro --resolution 2k --wait --json`, downloads `result_url`). Used by `design-setup.sh check` and by the `cost` and `comps` steps. Higgsfield's role in the round: it renders the comp image on every dealt direction card — the images the user chooses between on the sandbox board — and the chosen comp is the visual target for implementation parity.
```

- [ ] **Step 7: Commit**

```bash
git add scripts/lib/higgsfield.sh tests/fixtures/higgsfield-stub.sh tests/higgsfield.bats docs/superpowers/specs/2026-09-24-impeccable-higgsfield-design.md
git commit -m "feat(design): Higgsfield library for account, cost and comps

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `design-setup.sh` (check / install) + `/larv:design-setup` + pre-flight

**Files:**
- Create: `templates/higgsfield-wrapper.sh`, `scripts/design-setup.sh`, `tests/fixtures/impeccable-launcher-stub/scripts/impeccable`
- Create: `commands/larv-design-setup.md`, `codex-skills/design-setup/SKILL.md`
- Modify: `scripts/pre-flight.sh` (after the Impeccable check block, lines ~90-97, and the report heredoc, ~155-157)
- Test: `tests/design_setup.bats`; modify `tests/pre-flight.bats`

**Interfaces:**
- Consumes: Task 1 + Task 2 functions.
- Produces: `bash scripts/design-setup.sh check [dir]` → exit `0` ready, `3` fallback-only (Higgsfield missing/signed out/credits below cap), `1` hard fail (no Impeccable launcher, no public host, or missing `php curl ss setsid`). One line per item: `  ok: …`, `  fallback: …`, `  missing: …`. `install` → exit 0/1.

- [ ] **Step 1: Write the Impeccable launcher stub**

`tests/fixtures/impeccable-launcher-stub/scripts/impeccable` (executable):

```bash
#!/usr/bin/env bash
# Test double for the Impeccable skill launcher. STUB_SEED_FAIL=1 simulates API outage.
printf '%s\n' "$*" >>"${STUB_DIR:-/tmp}/impeccable.log"
case "$1" in
    engine-probe) echo "impeccable-engine 0.1.5" ;;
    concept-seed)
        [ -f PRODUCT.md ] || { echo "NO_PRODUCT_MD"; exit 1; }
        [ "${STUB_SEED_FAIL:-0}" = "1" ] && { echo "seed api unreachable" >&2; exit 1; }
        echo "SURFACE CONCEPT SEED (key: stubkey1; mode: unscoped)"
        echo "DEALT INDICES: 5, 2, 1 (index 5 leads)"
        ;;
    *) echo "stub: unhandled $*" >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Write the failing tests**

`tests/design_setup.bats`:

```bash
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

@test "install is a no-op report when already installed and never signs in" {
    mkdir -p "$HOME/.local/share/larv/higgsfield"
    cp tests/fixtures/higgsfield-stub.sh "$HOME/.local/share/larv/higgsfield/higgsfield"
    export LARV_HIGGSFIELD_BIN=""
    run bash scripts/design-setup.sh install
    [[ "$output" == *"ok: higgsfield already installed"* ]]
    ! grep -q "auth login" "$STUB_DIR/hf.log"
}
```

Add to `tests/pre-flight.bats` (append; reuse that file's existing setup/env conventions for running pre-flight):

```bash
@test "pre-flight report includes the design tools check" {
    grep -q 'design-setup.sh" check' scripts/pre-flight.sh
    grep -q '^Design tools check:$' scripts/pre-flight.sh
}
```

- [ ] **Step 3: Run to verify failure**

Run: `chmod +x tests/fixtures/impeccable-launcher-stub/scripts/impeccable && bats tests/design_setup.bats`
Expected: FAIL — `scripts/design-setup.sh: No such file or directory`.

- [ ] **Step 4: Create `templates/higgsfield-wrapper.sh`**

```sh
#!/bin/sh
# larv shared Higgsfield CLI wrapper. Keeps credentials and config beside the
# pinned binary. Never run `auth token` in recorded sessions: it prints the access token.
set -eu
larv_hf_dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)
umask 077
export HIGGSFIELD_CREDENTIALS_PATH="$larv_hf_dir/credentials.json"
export HIGGSFIELD_CONFIG_PATH="$larv_hf_dir/config.json"
export HIGGSFIELD_DISABLE_TELEMETRY=1
export HIGGSFIELD_NO_UPDATE_CHECK=1
exec "$larv_hf_dir/bin/higgsfield" "$@"
```

- [ ] **Step 5: Create `scripts/design-setup.sh`**

```bash
#!/usr/bin/env bash
# Readiness check and installer for the larv Impeccable + Higgsfield design round.
# check exit codes: 0 ready, 3 zero-credit fallback only, 1 hard failure.
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$PLUGIN_ROOT/scripts/lib/design_tools.sh"
. "$PLUGIN_ROOT/scripts/lib/higgsfield.sh"

HF_VERSION="1.1.26"
HF_SHA256="5d666fae70c99b7388690191a649d1487962250ed50820e079edfd1ffac7bf5b"
HF_ARCHIVE_URL="${LARV_HIGGSFIELD_ARCHIVE_URL:-https://github.com/higgsfield-ai/cli/releases/download/v${HF_VERSION}/hf_${HF_VERSION}_linux_amd64.tar.gz}"
HF_DEST="$HOME/.local/share/larv/higgsfield"
CAP="${LARV_HIGGSFIELD_CREDIT_CAP:-10}"
LOGIN_HINT="! $HF_DEST/higgsfield auth login   (no --port; see README 'Impeccable + Higgsfield design directions')"

usage() {
    cat <<'EOF'
Usage: design-setup.sh <command> [project-dir]

Commands:
  check [dir]   Report readiness. Exit 0 ready, 3 zero-credit fallback only, 1 hard failure
  install       Install the pinned Higgsfield CLI and the vendored Impeccable skill (never signs in)
  help          Show this help
EOF
}

cmd_check() {
    local hard=0 fallback=0 launcher host acct tool
    echo "Design tools check:"
    if launcher="$(design_impeccable_launcher)"; then
        if "$launcher" engine-probe >/dev/null 2>&1; then
            echo "  ok: impeccable engine ($launcher)"
        else
            echo "  missing: impeccable engine (run: $launcher engine-probe)"; hard=1
        fi
    else
        echo "  missing: impeccable skill (run /larv:design-setup)"; hard=1
    fi
    if ! design_higgsfield_bin >/dev/null; then
        echo "  fallback: higgsfield not installed (run /larv:design-setup)"; fallback=1
    elif ! acct="$(hf_account_json)"; then
        echo "  fallback: higgsfield not signed in; user runs: $LOGIN_HINT"; fallback=1
    else
        local credits email plan
        credits="$(jq -r '.credits' <<<"$acct")"
        email="$(jq -r '.email' <<<"$acct")"
        plan="$(jq -r '.subscription_plan_type' <<<"$acct")"
        if [ "$credits" -lt "$CAP" ]; then
            echo "  fallback: $credits credits left (cap $CAP) on $email"; fallback=1
        else
            echo "  ok: higgsfield $email ($plan, $credits credits)"
        fi
    fi
    if host="$(design_public_host)"; then
        echo "  ok: public host $host"
    else
        echo "  missing: public host (set LARV_VM_HOST to this server's public IP)"; hard=1
    fi
    for tool in php curl ss setsid jq; do
        command -v "$tool" >/dev/null 2>&1 || { echo "  missing: $tool"; hard=1; }
    done
    [ "$hard" -eq 1 ] && return 1
    [ "$fallback" -eq 1 ] && return 3
    return 0
}

install_higgsfield() {
    if [ -x "$HF_DEST/higgsfield" ]; then
        echo "  ok: higgsfield already installed at $HF_DEST"
        return 0
    fi
    local platform="${LARV_DESIGN_SETUP_UNAME:-$(uname -sm)}" tmp
    if [ "$platform" != "Linux x86_64" ]; then
        echo "ERROR: no pinned Higgsfield checksum for $platform; install it manually and set LARV_HIGGSFIELD_BIN" >&2
        return 1
    fi
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/hf.tgz" "$HF_ARCHIVE_URL" \
        || ! echo "$HF_SHA256  $tmp/hf.tgz" | sha256sum -c - >/dev/null 2>&1; then
        echo "ERROR: Higgsfield download failed or checksum mismatch; nothing installed" >&2
        rm -rf "$tmp"; return 1
    fi
    (
        umask 077
        mkdir -p "$HF_DEST/bin"
        tar -xzf "$tmp/hf.tgz" -C "$tmp" hf
        mv "$tmp/hf" "$HF_DEST/bin/higgsfield"
        cp "$PLUGIN_ROOT/templates/higgsfield-wrapper.sh" "$HF_DEST/higgsfield"
        chmod 700 "$HF_DEST/bin/higgsfield" "$HF_DEST/higgsfield"
    )
    rm -rf "$tmp"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HF_DEST/higgsfield" "$HOME/.local/bin/higgsfield"
    echo "  ok: higgsfield $HF_VERSION installed at $HF_DEST"
}

install_impeccable() {
    local src="$PLUGIN_ROOT/bundle/impeccable" target
    [ -d "$src" ] || { echo "ERROR: bundle/impeccable missing" >&2; return 1; }
    for target in "$HOME/.claude/skills/impeccable" "$HOME/.agents/skills/impeccable"; do
        if [ -e "$target" ] && [ "${LARV_DESIGN_SETUP_FORCE:-0}" != "1" ]; then
            echo "  ok: impeccable skill kept at $target"
            continue
        fi
        if [ -e "$target" ]; then
            local bk="$HOME/.local/share/larv/backups/$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$bk"; mv "$target" "$bk/"
            echo "  info: backed up $target to $bk"
        fi
        mkdir -p "$(dirname "$target")"
        cp -a "$src" "$target"
        echo "  ok: impeccable skill installed at $target"
    done
    "$HOME/.claude/skills/impeccable/scripts/impeccable" engine-probe >/dev/null \
        && echo "  ok: impeccable engine ready" \
        || { echo "ERROR: impeccable engine-probe failed (needs network once)" >&2; return 1; }
}

cmd_install() {
    echo "Design tools install:"
    install_higgsfield || return 1
    if [ -z "${LARV_IMPECCABLE_SKILL_DIR:-}" ]; then
        install_impeccable || return 1
    fi
    if ! hf_account_json >/dev/null 2>&1; then
        echo "  next: sign in once (user step): $LOGIN_HINT"
    fi
}

main() {
    local cmd="${1:-help}"
    shift || true
    case "$cmd" in
        check) cmd_check "$@" ;;
        install) cmd_install ;;
        help|-h|--help) usage ;;
        *) usage >&2; exit 64 ;;
    esac
}

main "$@"
```

Note: the `set -e` + `cmd_check` returning 3 is intended; `main` propagates the status.

- [ ] **Step 6: Wire pre-flight**

In `scripts/pre-flight.sh`, directly after the Impeccable block (the `fi` closing `if [ -n "$impeccable_output" ]`), insert:

```bash
    echo "Design tools check:"
    local design_output
    design_output="$(bash "$PLUGIN_ROOT/scripts/design-setup.sh" check "$dir" 2>&1 | sed '1d' || true)"
    printf "%s\n" "${design_output:-  info: design-setup check produced no lines}"
```

In the report heredoc, after the `$impeccable_output` line and its blank line, insert:

```
Design tools check:
$design_output

```

- [ ] **Step 7: Create `commands/larv-design-setup.md`**

```markdown
---
name: larv:design-setup
description: Check or install the shared Impeccable + Higgsfield design tools used by /larv:redesign-impeccable-higgsfield and the Phase 3 impeccable-higgsfield mode.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"` and show the result.

- Exit 0: ready. Say so.
- Exit 3 or 1: run `bash <larv-plugin-root>/scripts/design-setup.sh install`, then `check` again.
- If Higgsfield is installed but not signed in, the sign-in is the user's step. Tell them to type `! ~/.local/share/larv/higgsfield/higgsfield auth login` (no `--port`). On a headless server: open the `https://clerk.higgsfield.ai/oauth/authorize…` link from the printed file in their own browser, then deliver the failed `http://localhost:<port>/callback?...` URL to the waiting CLI with `curl` on the server. Never run `higgsfield auth token`.
- On the shared claude-team server the tools are preinstalled and signed in as dtt@oakdriveventures.com; `check` should already pass.
```

- [ ] **Step 8: Create `codex-skills/design-setup/SKILL.md`**

```markdown
---
name: design-setup
description: Use when the user types /larv:design-setup or asks to check or install the Impeccable + Higgsfield design tools.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:design-setup

This is the Codex-compatible entry point for `/larv:design-setup`.

Read `commands/larv-design-setup.md` and follow it exactly.
```

- [ ] **Step 9: Run tests**

Run: `bats tests/design_setup.bats tests/pre-flight.bats`
Expected: all pass.

- [ ] **Step 10: Real check on this server (read-only)**

Run: `LARV_VM_HOST= bash scripts/design-setup.sh check /home/claude-team/loi/prs; echo "exit=$?"`
Expected: `ok: higgsfield dtt@oakdriveventures.com (lite, 79 credits)` (or current balance), `ok: public host 46.250.229.188`, `exit=0`.

- [ ] **Step 11: Commit**

```bash
git add templates/higgsfield-wrapper.sh scripts/design-setup.sh tests/fixtures/impeccable-launcher-stub/scripts/impeccable tests/design_setup.bats tests/pre-flight.bats scripts/pre-flight.sh commands/larv-design-setup.md codex-skills/design-setup/SKILL.md
git commit -m "feat(design): design-setup check/install and /larv:design-setup

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `design-directions.sh` — context, seed, cost, comps, pick

**Files:**
- Create: `scripts/design-directions.sh`
- Modify: `scripts/impeccable.sh` (`cmd_context`: product-only switch)
- Test: `tests/design_directions.bats`; modify `tests/impeccable.bats`

**Interfaces:**
- Consumes: Tasks 1–3 (`design_*`, `hf_*`, launcher stub).
- Produces (CLI, all take `<project-dir> <out-dir>` unless noted):
  - `context <dir> <out>` → ensures `<dir>/PRODUCT.md`; exit 2 with `NEEDS_PRODUCT_MD` if it cannot be derived (the skill then authors it).
  - `seed <dir> <out>` → `<out>/seed.txt`; on failure writes `<out>/fallback` containing `seed-unavailable` and exits 0.
  - `cost <dir> <out>` → `<out>/cost.json` `{"per_comp":{"<id>":2},"total":6,"cap":10}`; exit 4 when total > cap and `LARV_DESIGN_CONFIRMED_SPEND` < total.
  - `comps <dir> <out>` → `<out>/comps/<id>.png` + `<id>.json` for every comp card; per-card failure writes `<id>.fallback`; never regenerates an existing PNG.
  - `pick <dir> <out> <id>` → sidecar `approved: true`, `<out>/decision.md`.
- Data contract (authored by the agent between `seed` and `cost`):
  - `<out>/options.json`: `{ "title", "question", "options": [ {id,label,thesis,palette[],viewport,risk, kicker?, verdict?, kept?, surface?} ], "canonCard"?: {…same fields} }`. A **comp card** is any option whose `verdict` is absent or not `"declined"`. `surface` is `"desktop"` (default, aspect `3:2`) or `"phone"` (aspect `9:16`).
  - `<out>/prompts/<id>.txt`: one prompt per comp card.

- [ ] **Step 1: Add the product-only switch test to `tests/impeccable.bats`**

```bash
@test "context with LARV_IMPECCABLE_PRODUCT_ONLY writes PRODUCT.md but not DESIGN.md" {
    seed_larv_docs
    LARV_IMPECCABLE_PRODUCT_ONLY=1 run bash scripts/impeccable.sh context "$TMP"
    [ "$status" -eq 0 ]
    [ -f "$TMP/PRODUCT.md" ]
    [ ! -f "$TMP/DESIGN.md" ]
}
```

- [ ] **Step 2: Write the failing directions tests**

`tests/design_directions.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    STUB_DIR="$(mktemp -d)"; export STUB_DIR
    export HOME="$STUB_DIR/home"; mkdir -p "$HOME"
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export LARV_HIGGSFIELD_BIN="$PROJECT_ROOT/tests/fixtures/higgsfield-stub.sh"
    export LARV_IMPECCABLE_SKILL_DIR="$PROJECT_ROOT/tests/fixtures/impeccable-launcher-stub"
    OUT="$TMP/docs/larv/redesigns/t-impeccable-higgsfield/directions"
    mkdir -p "$OUT/prompts"
    printf '# PRS\n\nPouch receiving.\n' >"$TMP/PRODUCT.md"
}

teardown() {
    teardown_tmp_project "$TMP"
    rm -rf "$STUB_DIR"
}

write_options() {
    cat >"$OUT/options.json" <<'EOF'
{"title":"PRS directions","question":"Pick one","options":[
 {"id":"assigned","label":"Service counter","kicker":"THE ROLL","thesis":"Queue beside record","palette":["#ffffff","#125c3b"],"viewport":"Queue left, record right","risk":"Busy on desktop"},
 {"id":"model-pick","label":"Dispatch register","kicker":"IMPECCABLE'S PICK","thesis":"Fast register","palette":["#f4f7f5","#125c3b"],"viewport":"Wide table","risk":"Familiar"},
 {"id":"phone-card","label":"Pocket queue","thesis":"Phone first","palette":["#ffffff","#23392e"],"viewport":"One card per package","risk":"Dense on desktop","surface":"phone"},
 {"id":"cassette","label":"Control panel","verdict":"declined","thesis":"Panels","palette":["#ffffff"],"viewport":"Fascia","risk":"Misleading toggles","kept":"Clear group labels"}
]}
EOF
    for id in assigned model-pick phone-card; do printf 'Mockup %s\n' "$id" >"$OUT/prompts/$id.txt"; done
}

@test "context keeps an existing PRODUCT.md" {
    run bash scripts/design-directions.sh context "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "Pouch receiving" "$TMP/PRODUCT.md"
}

@test "context without PRODUCT.md or larv brief asks the agent to author it" {
    rm "$TMP/PRODUCT.md"
    run bash scripts/design-directions.sh context "$TMP" "$OUT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"NEEDS_PRODUCT_MD"* ]]
}

@test "seed saves concept-seed output" {
    run bash scripts/design-directions.sh seed "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "DEALT INDICES" "$OUT/seed.txt"
    [ ! -f "$OUT/fallback" ]
}

@test "seed failure records the fallback and still exits 0" {
    STUB_SEED_FAIL=1 run bash scripts/design-directions.sh seed "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -qx "seed-unavailable" "$OUT/fallback"
}

@test "cost prices only comp cards and writes cost.json" {
    write_options
    run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.total' "$OUT/cost.json")" = "6" ]
    [ "$(jq -r '.per_comp | keys | join(",")' "$OUT/cost.json")" = "assigned,model-pick,phone-card" ]
    ! grep -q "cassette" "$OUT/cost.json"
}

@test "cost over the cap exits 4 unless the spend was confirmed" {
    write_options
    LARV_HIGGSFIELD_CREDIT_CAP=5 run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 4 ]
    [[ "$output" == *"6 credits exceeds cap 5"* ]]
    LARV_HIGGSFIELD_CREDIT_CAP=5 LARV_DESIGN_CONFIRMED_SPEND=6 run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
}

@test "comps writes png and sidecar for each comp card with the right aspect" {
    write_options
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    for id in assigned model-pick phone-card; do
        [ -s "$OUT/comps/$id.png" ]
        [ "$(jq -r '.model' "$OUT/comps/$id.json")" = "nano_banana_pro" ]
        [ "$(jq -r '.approved' "$OUT/comps/$id.json")" = "false" ]
        [ "$(jq -r '.sample_data' "$OUT/comps/$id.json")" = "true" ]
    done
    [ ! -e "$OUT/comps/cassette.png" ]
    [ "$(jq -r '.aspect_ratio' "$OUT/comps/phone-card.json")" = "9:16" ]
    [ "$(jq -r '.aspect_ratio' "$OUT/comps/assigned.json")" = "3:2" ]
}

@test "comps falls back per card when Higgsfield fails" {
    write_options
    STUB_FAIL_CREATE=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/assigned.fallback" ]
    [ ! -e "$OUT/comps/assigned.png" ]
}

@test "comps falls back for every card when signed out, without calling create" {
    write_options
    STUB_SIGNED_OUT=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/model-pick.fallback" ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps skips existing images so a rerun spends nothing" {
    write_options
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    : >"$STUB_DIR/hf.log"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps refuses reference images without the fictional-data confirmation" {
    write_options
    mkdir -p "$OUT/refs"; printf 'png' >"$OUT/refs/reference.png"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 5 ]
    [[ "$output" == *"FICTIONAL-DATA-CONFIRMED"* ]]
    touch "$OUT/refs/FICTIONAL-DATA-CONFIRMED"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q -- "--image-references $OUT/refs/reference.png" "$STUB_DIR/hf.log"
}

@test "pick approves only the chosen sidecar and writes decision.md" {
    write_options
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" model-pick
    [ "$status" -eq 0 ]
    [ "$(jq -r '.approved' "$OUT/comps/model-pick.json")" = "true" ]
    [ "$(jq -r '.approved' "$OUT/comps/assigned.json")" = "false" ]
    grep -q "pick: model-pick" "$OUT/decision.md"
    grep -q "Dispatch register" "$OUT/decision.md"
}

@test "pick rejects an unknown id" {
    write_options
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" nope
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown option id: nope"* ]]
}
```

- [ ] **Step 3: Run to verify failure**

Run: `bats tests/design_directions.bats tests/impeccable.bats`
Expected: FAIL — `design-directions.sh` missing; impeccable product-only test fails because DESIGN.md is written.

- [ ] **Step 4: Implement the product-only switch in `scripts/impeccable.sh`**

In `cmd_context`, change the python invocation line to pass a 4th argument:

```bash
    python3 - "$dir" "$FORCE" "$PLUGIN_ROOT" "${LARV_IMPECCABLE_PRODUCT_ONLY:-0}" <<'PY'
```

In the python body, after `force = sys.argv[2] == "1"` add:

```python
product_only = len(sys.argv) > 4 and sys.argv[4] == "1"
```

and change the DESIGN.md block to:

```python
if product_only:
    print("context: product-only, DESIGN.md left for the direction pick")
elif force or not design_path.exists():
    design_path.write_text(design, encoding="utf-8")
    wrote.append("DESIGN.md")
else:
    print(f"context: keep existing {design_path}")
```

- [ ] **Step 5: Implement `scripts/design-directions.sh` (steps context, seed, cost, comps, pick)**

```bash
#!/usr/bin/env bash
# Impeccable directions + Higgsfield comps design round.
# Steps: context seed cost comps board serve pick (see usage).
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$PLUGIN_ROOT/scripts/lib/design_tools.sh"
. "$PLUGIN_ROOT/scripts/lib/higgsfield.sh"

CAP="${LARV_HIGGSFIELD_CREDIT_CAP:-10}"

usage() {
    cat <<'EOF'
Usage: design-directions.sh <step> <project-dir> <out-dir> [arg]

Steps (run in order; the agent authors options.json and prompts/<id>.txt after seed):
  context  Ensure PRODUCT.md (exit 2 NEEDS_PRODUCT_MD when the agent must author it)
  seed     Run Impeccable concept-seed into seed.txt (fallback marker on failure)
  cost     Price every comp card with Higgsfield; exit 4 when over LARV_HIGGSFIELD_CREDIT_CAP
  comps    Generate one Higgsfield comp per comp card (per-card wireframe fallback)
  board    Render board/index.html from options.json and comps
  serve    Serve the board on a public 9000-9499 port (probe before announce)
  pick     Approve the chosen card: pick <dir> <out> <id>
EOF
}

comp_ids() {
    jq -r '.options[] | select((.verdict // "") != "declined") | .id' "$1/options.json"
}

aspect_for() {
    local surface
    surface="$(jq -r --arg id "$2" '.options[] | select(.id == $id) | .surface // "desktop"' "$1/options.json")"
    [ "$surface" = "phone" ] && echo "9:16" || echo "3:2"
}

step_context() {
    local dir="$1" out="$2"
    mkdir -p "$out"
    if [ -f "$dir/PRODUCT.md" ]; then
        echo "context: keep existing $dir/PRODUCT.md"; return 0
    fi
    if [ -f "$dir/docs/larv/00-discuss/product-brief.md" ]; then
        LARV_IMPECCABLE_PRODUCT_ONLY=1 bash "$PLUGIN_ROOT/scripts/impeccable.sh" context "$dir"
        return 0
    fi
    echo "NEEDS_PRODUCT_MD: write $dir/PRODUCT.md from the existing app (Impeccable init ask round), then rerun context"
    return 2
}

step_seed() {
    local dir="$1" out="$2" launcher
    mkdir -p "$out"; rm -f "$out/fallback"
    launcher="$(design_impeccable_launcher)" || { echo "seed-unavailable" >"$out/fallback"; echo "seed: no impeccable launcher; fallback"; return 0; }
    if (cd "$dir" && "$launcher" concept-seed --candidate-count 7) >"$out/seed.txt" 2>&1; then
        echo "seed: wrote $out/seed.txt"
    else
        echo "seed-unavailable" >"$out/fallback"
        echo "seed: concept-seed failed; author directions from PRODUCT.md and mark the board as fallback"
    fi
}

step_cost() {
    local dir="$1" out="$2" id c total=0 per='{}'
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    for id in $(comp_ids "$out"); do
        [ -f "$out/comps/$id.png" ] && continue
        [ -f "$out/prompts/$id.txt" ] || { echo "ERROR: missing prompt $out/prompts/$id.txt" >&2; return 1; }
        c="$(hf_cost "$out/prompts/$id.txt" "$(aspect_for "$out" "$id")")"
        per="$(jq -c --arg id "$id" --argjson c "$c" '. + {($id): $c}' <<<"$per")"
        total=$((total + c))
    done
    jq -n --argjson per "$per" --argjson total "$total" --argjson cap "$CAP" \
        '{per_comp: $per, total: $total, cap: $cap}' >"$out/cost.json"
    echo "cost: $total credits for $(jq 'length' <<<"$per") comps (cap $CAP)"
    if [ "$total" -gt "$CAP" ] && [ "${LARV_DESIGN_CONFIRMED_SPEND:-0}" -lt "$total" ]; then
        echo "cost: $total credits exceeds cap $CAP; ask the user, then rerun with LARV_DESIGN_CONFIRMED_SPEND=$total"
        return 4
    fi
}

step_comps() {
    local dir="$1" out="$2" id ref="" aspect job
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    mkdir -p "$out/comps"
    if [ -f "$out/refs/reference.png" ]; then
        if [ ! -f "$out/refs/FICTIONAL-DATA-CONFIRMED" ]; then
            echo "ERROR: $out/refs/reference.png needs $out/refs/FICTIONAL-DATA-CONFIRMED (seeded/fictional data only)" >&2
            return 5
        fi
        ref="$out/refs/reference.png"
    fi
    local signed_in=1
    hf_account_json >/dev/null 2>&1 || signed_in=0
    for id in $(comp_ids "$out"); do
        if [ -f "$out/comps/$id.png" ]; then echo "comps: keep $id"; continue; fi
        if [ "$signed_in" -eq 0 ]; then
            echo "higgsfield-unavailable" >"$out/comps/$id.fallback"; continue
        fi
        aspect="$(aspect_for "$out" "$id")"
        if job="$(hf_generate_comp "$out/prompts/$id.txt" "$aspect" "$out/comps/$id.png" ${ref:+"$ref"})"; then
            rm -f "$out/comps/$id.fallback"
            jq -n --rawfile prompt "$out/prompts/$id.txt" --arg model "$HF_MODEL" \
                --arg aspect "$aspect" --arg res "$HF_RESOLUTION" --arg job "$job" \
                --arg date "$(date +%F)" --arg ref "$ref" \
                '{prompt: $prompt, tool: "Higgsfield CLI", model: $model, aspect_ratio: $aspect,
                  resolution: $res, job_id: $job, generated_on: $date, reference: $ref,
                  approved: false, sample_data: true}' >"$out/comps/$id.json"
            echo "comps: $id done"
        else
            echo "generation-failed" >"$out/comps/$id.fallback"
            echo "comps: $id failed; wireframe card will be shown"
        fi
    done
    [ "$signed_in" -eq 0 ] && echo "comps: Higgsfield unavailable; board uses zero-credit wireframe cards"
    return 0
}

step_pick() {
    local dir="$1" out="$2" id="${3:-}" label
    label="$(jq -r --arg id "$id" '.options[] | select(.id == $id) | .label' "$out/options.json")"
    [ -n "$id" ] && [ -n "$label" ] || { echo "ERROR: unknown option id: $id" >&2; return 1; }
    if [ -f "$out/comps/$id.json" ]; then
        local tmp="$out/comps/$id.json.tmp"
        jq --arg d "$(date +%F)" '.approved = true | .approved_on = $d' "$out/comps/$id.json" >"$tmp"
        mv "$tmp" "$out/comps/$id.json"
    fi
    cat >"$out/decision.md" <<EOF
# Design direction decision

pick: $id
label: $label
date: $(date +%F)
comp: $( [ -f "$out/comps/$id.png" ] && echo "comps/$id.png" || echo "none (wireframe card)" )
EOF
    echo "pick: $id ($label)"
}

main() {
    local step="${1:-help}"
    case "$step" in
        help|-h|--help) usage; return 0 ;;
    esac
    [ "$#" -ge 3 ] || { usage >&2; exit 64; }
    shift
    local dir out
    dir="$(cd "$1" && pwd -P)"; out="$2"; shift 2
    mkdir -p "$out"; out="$(cd "$out" && pwd -P)"
    case "$step" in
        context) step_context "$dir" "$out" ;;
        seed) step_seed "$dir" "$out" ;;
        cost) step_cost "$dir" "$out" ;;
        comps) step_comps "$dir" "$out" ;;
        pick) step_pick "$dir" "$out" "$@" ;;
        *) usage >&2; exit 64 ;;
    esac
}

main "$@"
```

- [ ] **Step 6: Run tests**

Run: `bats tests/design_directions.bats tests/impeccable.bats`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add scripts/design-directions.sh scripts/impeccable.sh tests/design_directions.bats tests/impeccable.bats
git commit -m "feat(design): directions round context, seed, cost, comps and pick

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `design-directions.sh` — board and serve

**Files:**
- Create: `templates/design-board.html.tmpl`
- Modify: `scripts/design-directions.sh` (add `step_board`, `step_serve`, dispatch)
- Test: extend `tests/design_directions.bats`

**Interfaces:**
- Consumes: `options.json`, `comps/*`, `fallback` (Task 4); `allocate_port`, `verify_allocation`, `release_port_reservation` (`scripts/lib/verifier.sh`); `static_server_*` (`scripts/lib/static_server.sh`); `probe_url_inside`, `probe_with_retries` (`scripts/lib/probe.sh`); `design_public_host`, `design_slug` (Task 1).
- Produces:
  - `board <dir> <out>` → `<out>/board/index.html` + copied `<out>/board/comps/<id>.png`; exit 1 naming the bad card on invalid options.
  - `serve <dir> <out> [port|auto]` → `<out>/board-url.txt` with `http://<public-host>:<port>/`; records `mockup-port` in `STATE.yaml` via `state.sh record-allocation` when it exists, else `<out>/../run.yaml` `board_port:`. Env `LARV_DESIGN_SKIP_PROBE=1` (tests only) skips firewall + probes.

- [ ] **Step 1: Write the failing tests** (append to `tests/design_directions.bats`)

```bash
@test "board renders every card with comps, sample-data labels and no external URLs" {
    write_options
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    html="$OUT/board/index.html"
    for label in "Service counter" "Dispatch register" "Pocket queue" "Control panel"; do grep -q "$label" "$html"; done
    grep -q 'src="comps/assigned.png"' "$html"
    [ -s "$OUT/board/comps/assigned.png" ]
    grep -q "Sample data" "$html"
    grep -q "pick: assigned" "$html"
    grep -q "Clear group labels" "$html"
    ! grep -Eq '(src|href)="https?://' "$html"
}

@test "board renders a wireframe when a comp is missing and names the reason" {
    write_options
    STUB_SIGNED_OUT=1 bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q 'class="wireframe"' "$OUT/board/index.html"
    grep -q "Higgsfield was unavailable" "$OUT/board/index.html"
}

@test "board escapes HTML in agent-authored text" {
    write_options
    jq '.options[0].thesis = "<script>alert(1)</script> & more"' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    ! grep -q "<script>alert" "$OUT/board/index.html"
    grep -q "&lt;script&gt;" "$OUT/board/index.html"
}

@test "board refuses a card missing required fields" {
    write_options
    jq 'del(.options[1].thesis)' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"option model-pick missing thesis"* ]]
}

@test "board refuses duplicate ids" {
    write_options
    jq '.options[1].id = "assigned"' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"duplicate option id: assigned"* ]]
}

@test "serve without STATE uses the basename slug, public host and run.yaml" {
    write_options
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    export LARV_VM_HOST=203.0.113.10 LARV_DESIGN_SKIP_PROBE=1
    export LARV_PORT_RESERVATION_DIR="$STUB_DIR/ports" LARV_SANDBOX_PROCESS_DIR="$STUB_DIR/procs"
    run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 0 ]
    url="$(cat "$OUT/board-url.txt")"
    [[ "$url" =~ ^http://203\.0\.113\.10:9[0-4][0-9][0-9]/$ ]]
    port="${url##*:}"; port="${port%/}"
    grep -q "board_port: $port" "$OUT/../run.yaml"
    curl -fsS "http://127.0.0.1:$port/" | grep -q "Dispatch register"
    source scripts/lib/vm.sh; source scripts/lib/static_server.sh
    static_server_stop "" "$(yq -r '.board_session' "$OUT/../run.yaml")"
}

@test "serve refuses to announce a placeholder host" {
    write_options
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    mkdir -p "$STUB_DIR/bin"; printf '#!/bin/sh\necho ""\n' >"$STUB_DIR/bin/hostname"; chmod +x "$STUB_DIR/bin/hostname"
    PATH="$STUB_DIR/bin:$PATH" LARV_VM_HOST=sandbox.example.com run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 1 ]
    [[ "$output" == *"no public host"* ]]
    [ ! -f "$OUT/board-url.txt" ]
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/design_directions.bats`
Expected: new tests FAIL (`board`/`serve` hit `usage`, exit 64).

- [ ] **Step 3: Create `templates/design-board.html.tmpl`**

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{TITLE}}</title>
<style>
:root{--bg:#f6f6f4;--surface:#fff;--ink:#1d1f1e;--muted:#5d6360;--line:#e2e4e1;--accent:#1f5f46}
@media (prefers-color-scheme:dark){:root{--bg:#141615;--surface:#1c1f1d;--ink:#eceeed;--muted:#a3aaa6;--line:#2c302e;--accent:#6fc19b}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:1280px;margin:0 auto;padding:32px 16px 64px}
h1{font-size:28px;margin:0 0 4px}.q{color:var(--muted);margin:0 0 8px}
.note{background:var(--surface);border:1px solid var(--line);border-radius:8px;padding:10px 14px;margin:16px 0}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:20px;margin-top:20px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}
.card img{width:100%;display:block;border-bottom:1px solid var(--line);background:var(--bg)}
.card .body{padding:16px;display:flex;flex-direction:column;gap:8px}
.kicker{font-size:12px;letter-spacing:.08em;color:var(--accent);font-weight:600}
.card h2{font-size:20px;margin:0}.muted{color:var(--muted)}
.chips{display:flex;gap:6px}.chip{width:28px;height:28px;border-radius:6px;border:1px solid var(--line)}
.pick{font-family:ui-monospace,monospace;background:var(--bg);border:1px solid var(--line);border-radius:6px;padding:6px 10px;align-self:flex-start}
.wireframe{aspect-ratio:3/2;display:grid;grid-template-columns:22% 1fr;gap:8px;padding:14px;border-bottom:1px solid var(--line)}
.wireframe.phone{aspect-ratio:9/16;max-height:520px;grid-template-columns:1fr}
.wireframe span{border-radius:6px}
.declined{margin-top:28px}.declined li{margin:6px 0}
footer{margin-top:32px;color:var(--muted);font-size:13px}
</style>
</head>
<body>
<main>
<h1>{{TITLE}}</h1>
<p class="q">{{QUESTION}}</p>
{{NOTE}}
<section class="cards">
{{CARDS}}
</section>
{{DECLINED}}
<footer>Sample data only. These are direction comps, not working screens. Reply in chat with <code>pick: &lt;id&gt;</code>.</footer>
</main>
</body>
</html>
```

- [ ] **Step 4: Add `step_board` and `step_serve` to `scripts/design-directions.sh`**

Add above `main()`:

```bash
step_board() {
    local dir="$1" out="$2"
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    mkdir -p "$out/board/comps"
    local id
    for id in $(comp_ids "$out"); do
        [ -f "$out/comps/$id.png" ] && cp "$out/comps/$id.png" "$out/board/comps/$id.png"
    done
    python3 - "$out" "$PLUGIN_ROOT/templates/design-board.html.tmpl" <<'PY'
import html, json, sys
from pathlib import Path
out = Path(sys.argv[1]); tmpl = Path(sys.argv[2]).read_text(encoding="utf-8")
data = json.loads((out / "options.json").read_text(encoding="utf-8"))
opts = list(data.get("options") or [])
canon = data.get("canonCard")
if isinstance(canon, dict):
    canon = dict(canon, id=canon.get("id") or "canon", kicker=canon.get("kicker") or "CATEGORY STANDARD")
    opts.append(canon)
seen = set()
for o in opts:
    oid = o.get("id")
    if not oid:
        sys.exit("ERROR: option without id")
    if oid in seen:
        sys.exit(f"ERROR: duplicate option id: {oid}")
    seen.add(oid)
    for field in ("label", "thesis", "palette", "viewport", "risk"):
        if not o.get(field):
            sys.exit(f"ERROR: option {oid} missing {field}")
e = lambda s: html.escape(str(s), quote=True)
fallback = (out / "fallback").read_text().strip() if (out / "fallback").exists() else ""
reasons = set()
cards, declined = [], []
for o in opts:
    oid = o["id"]
    chips = "".join(f'<span class="chip" style="background:{e(c)}" title="{e(c)}"></span>' for c in o["palette"][:6])
    if o.get("verdict") == "declined":
        kept = f' Kept: {e(o["kept"])}' if o.get("kept") else ""
        declined.append(f'<li><strong>{e(o["label"])}</strong> <span class="muted">— {e(o.get("case") or o["risk"])}.{kept}</span></li>')
        continue
    png = out / "board" / "comps" / f"{oid}.png"
    if png.exists():
        visual = f'<img src="comps/{e(oid)}.png" alt="{e(o["label"])} comp (sample data)" loading="lazy">'
    else:
        fb = out / "comps" / f"{oid}.fallback"
        reasons.add(fb.read_text().strip() if fb.exists() else "no-comp")
        pal = o["palette"] + ["#dddddd"] * 3
        phone = " phone" if o.get("surface") == "phone" else ""
        visual = (f'<div class="wireframe{phone}" aria-label="{e(o["label"])} wireframe" style="background:{e(pal[0])}">'
                  f'<span style="background:{e(pal[1])}"></span><span style="background:{e(pal[2])};opacity:.35"></span></div>')
    kicker = f'<div class="kicker">{e(o["kicker"])}</div>' if o.get("kicker") else ""
    cards.append(f'''<article class="card" id="{e(oid)}">{visual}<div class="body">{kicker}
<h2>{e(o["label"])}</h2><p>{e(o["thesis"])}</p><div class="chips">{chips}</div>
<p class="muted"><strong>First screen:</strong> {e(o["viewport"])}</p>
<p class="muted"><strong>Risk:</strong> {e(o["risk"])}</p>
<code class="pick">pick: {e(oid)}</code></div></article>''')
notes = []
if fallback == "seed-unavailable":
    notes.append("Impeccable's direction service was unreachable; these directions were written from PRODUCT.md.")
if reasons & {"higgsfield-unavailable", "generation-failed"}:
    notes.append("Higgsfield was unavailable for some cards, so they show zero-credit wireframes.")
note = f'<p class="note">{" ".join(e(n) for n in notes)}</p>' if notes else ""
dec = f'<section class="declined"><h3>Considered and declined</h3><ul>{"".join(declined)}</ul></section>' if declined else ""
page = (tmpl.replace("{{TITLE}}", e(data.get("title") or "Design directions"))
            .replace("{{QUESTION}}", e(data.get("question") or "Choose one direction."))
            .replace("{{NOTE}}", note).replace("{{CARDS}}", "\n".join(cards)).replace("{{DECLINED}}", dec))
(out / "board" / "index.html").write_text(page, encoding="utf-8")
print(f"board: {len(cards)} cards, {len(declined)} declined -> {out / 'board' / 'index.html'}")
PY
}

step_serve() {
    local dir="$1" out="$2" requested="${3:-auto}" host slug port session url
    [ -f "$out/board/index.html" ] || { echo "ERROR: run board first" >&2; return 1; }
    host="$(design_public_host)" || { echo "ERROR: no public host (set LARV_VM_HOST); refusing to announce a local URL" >&2; return 1; }
    export LARV_VM_HOST="$host"
    . "$PLUGIN_ROOT/scripts/lib/vm.sh"
    . "$PLUGIN_ROOT/scripts/lib/verifier.sh"
    . "$PLUGIN_ROOT/scripts/lib/static_server.sh"
    . "$PLUGIN_ROOT/scripts/lib/probe.sh"
    slug="$(design_slug "$dir")"
    if [ "$requested" = "auto" ] || [ -z "$requested" ]; then
        port="$(allocate_port mockup "$slug")"
    else
        case "$requested" in *[!0-9]*) echo "ERROR: port must be numeric or auto" >&2; return 1 ;; esac
        [ "$requested" -ge 9000 ] && [ "$requested" -le 9499 ] || { echo "ERROR: port must be in 9000-9499" >&2; return 1; }
        verify_allocation "$requested" mockup "$slug" || { echo "ERROR: port $requested is taken" >&2; return 1; }
        port="$requested"
    fi
    session="larv-design-board-$slug"
    if [ "${LARV_DESIGN_SKIP_PROBE:-0}" != "1" ]; then
        static_server_check_remote_deps "" || { release_port_reservation mockup "$port" "$slug" || true; echo "ERROR: php/curl/ss/setsid missing" >&2; return 1; }
        static_server_open_firewall "" "$port" || { release_port_reservation mockup "$port" "$slug" || true; return 1; }
    fi
    static_server_start "" "$port" "$out/board" "$session" || { release_port_reservation mockup "$port" "$slug" || true; return 1; }
    url="$(static_server_url "$port")/"
    if [ "${LARV_DESIGN_SKIP_PROBE:-0}" != "1" ]; then
        probe_url_inside "" "$port" static || { echo "ERROR: inside probe failed" >&2; return 1; }
        probe_with_retries "$url" static || { echo "ERROR: external probe failed for $url" >&2; return 1; }
    fi
    release_port_reservation mockup "$port" "$slug" || true
    if [ -f "$dir/docs/larv/STATE.yaml" ]; then
        bash "$PLUGIN_ROOT/scripts/state.sh" record-allocation "$dir" mockup-port "$port"
    else
        printf 'slug: %s\nboard_port: %s\nboard_session: %s\n' "$slug" "$port" "$session" >"$out/../run.yaml"
    fi
    printf '%s\n' "$url" >"$out/board-url.txt"
    echo "Design board ready at $url"
}
```

Extend the `main` dispatch:

```bash
        board) step_board "$dir" "$out" ;;
        serve) step_serve "$dir" "$out" "$@" ;;
```

- [ ] **Step 5: Run tests**

Run: `bats tests/design_directions.bats`
Expected: all pass. (The serve test binds a real local port in 9000–9499 and stops it at the end.)

- [ ] **Step 6: Commit**

```bash
git add scripts/design-directions.sh templates/design-board.html.tmpl tests/design_directions.bats
git commit -m "feat(design): render and serve the directions board on a public port

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Vendor Impeccable 4.3.1

**Files:**
- Create: `bundle/impeccable/` (copy), `bundle/impeccable/UPSTREAM.md`
- Modify: `bundle/VERSIONS.yaml`, `scripts/bundle-update.sh` (`verify_bundle` checks), `tests/bundle.bats`

**Interfaces:**
- Produces: `bundle/impeccable/scripts/impeccable` (executable launcher, `VERSION` = `0.1.5`), resolved first by `design_impeccable_launcher`.

- [ ] **Step 1: Write the failing tests** (append to `tests/bundle.bats`)

```bash
@test "impeccable skill is vendored at 4.3.1 with an executable launcher" {
    [ "$(yq -r '.["impeccable-skill"]' bundle/VERSIONS.yaml)" = "4.3.1" ]
    [ "$(yq -r '.["higgsfield-cli"]' bundle/VERSIONS.yaml)" = "1.1.26" ]
    grep -q "version: 4.3.1" bundle/impeccable/SKILL.md
    [ -x bundle/impeccable/scripts/impeccable ]
    [ "$(tr -d '[:space:]' < bundle/impeccable/scripts/VERSION)" = "0.1.5" ]
    grep -q "83c2c735777c68e30ea536ab9cc97f7843456945" bundle/impeccable/UPSTREAM.md
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/bundle.bats`
Expected: the new test FAILS.

- [ ] **Step 3: Vendor**

```bash
cp -a /home/claude-team/loi/prs/.agents/skills/impeccable bundle/impeccable
chmod +x bundle/impeccable/scripts/impeccable
cat >bundle/impeccable/UPSTREAM.md <<'EOF'
# Vendored Impeccable skill

- Skill version: 4.3.1 (engine 0.1.5, fetched and checksum-verified by `scripts/impeccable` on first run into `~/.impeccable/bin/0.1.5/`)
- Upstream: https://github.com/pbakaus/impeccable, commit 83c2c735777c68e30ea536ab9cc97f7843456945
- Source copy: loi/prs `.agents/skills/impeccable` (static scan passed; hooks not installed)
- Used by: scripts/design-directions.sh (concept-seed), scripts/design-setup.sh (engine-probe, install)
EOF
printf 'impeccable-skill: "4.3.1"\nhiggsfield-cli: "1.1.26"\n' >>bundle/VERSIONS.yaml
```

In `scripts/bundle-update.sh` `verify_bundle`, add to the `checks` array:

```bash
        "$PLUGIN_ROOT/bundle/impeccable/SKILL.md"
        "$PLUGIN_ROOT/bundle/impeccable/scripts/impeccable"
```

- [ ] **Step 4: Run tests**

Run: `bats tests/bundle.bats tests/design_tools.bats`
Expected: all pass (the launcher-order test now resolves the bundle).

- [ ] **Step 5: Commit**

```bash
git add bundle/impeccable bundle/VERSIONS.yaml scripts/bundle-update.sh tests/bundle.bats
git commit -m "chore(bundle): vendor Impeccable skill 4.3.1

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: `/larv:redesign-impeccable-higgsfield` command, skill and Codex mirror

**Files:**
- Create: `commands/larv-redesign-impeccable-higgsfield.md`, `skills/larv-redesign-impeccable-higgsfield/SKILL.md`, `codex-skills/redesign-impeccable-higgsfield/SKILL.md`
- Modify: `tests/commands.bats`, `tests/skills.bats`, `tests/codex.bats`

- [ ] **Step 1: Write the failing tests**

In `tests/commands.bats`: add `larv-redesign-impeccable-higgsfield larv-design-setup` to `COMMANDS`, rename the count test to `"all 22 command files exist"`, and append:

```bash
@test "impeccable-higgsfield redesign command wires setup, board and implementation" {
    f=commands/larv-redesign-impeccable-higgsfield.md
    grep -q "name: larv:redesign-impeccable-higgsfield" "$f"
    grep -q "design-setup.sh check" "$f"
    grep -q "design-directions.sh" "$f"
    grep -q "Preserve all backend behavior" "$f"
    grep -q "visual-parity.md" "$f"
    grep -q "board-url.txt" "$f"
}
```

In `tests/skills.bats`: add `larv-redesign-impeccable-higgsfield` to `SKILLS`, rename to `"all 25 skill files exist"`, and append:

```bash
@test "impeccable-higgsfield redesign skill enforces cost, privacy and full-screen rules" {
    f=skills/larv-redesign-impeccable-higgsfield/SKILL.md
    grep -q "/larv:redesign-impeccable-higgsfield" "$f"
    grep -q "production app redesign" "$f"
    grep -q "screen-inventory.md" "$f"
    grep -q "visual-parity.md" "$f"
    grep -q "FICTIONAL-DATA-CONFIRMED" "$f"
    grep -q "LARV_DESIGN_CONFIRMED_SPEND" "$f"
    grep -q "every screen" "$f"
    grep -q "Never run \`higgsfield auth token\`" "$f"
    grep -q "Do not ask the user to run" "$f"
}
```

In `tests/codex.bats`: add `redesign-impeccable-higgsfield design-setup` to the skill loop list, and append:

```bash
@test "Codex redesign-impeccable-higgsfield entry point points at the command and skill" {
    run grep -F "/larv:redesign-impeccable-higgsfield" codex-skills/redesign-impeccable-higgsfield/SKILL.md
    [ "$status" -eq 0 ]
    grep -q "skills/larv-redesign-impeccable-higgsfield/SKILL.md" codex-skills/redesign-impeccable-higgsfield/SKILL.md
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/commands.bats tests/skills.bats tests/codex.bats`
Expected: FAIL on missing files.

- [ ] **Step 3: Create `commands/larv-redesign-impeccable-higgsfield.md`**

```markdown
---
name: larv:redesign-impeccable-higgsfield
description: Redesign the current Laravel frontend from Impeccable directions with Higgsfield comps, chosen on a public sandbox board.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument: optional focus such as `<page>`, `<role>`, or `<workflow>`. If omitted, redesign the whole frontend UI.

Invoke the `larv-redesign-impeccable-higgsfield` skill.

## Contract

- First run `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`. Exit 1: stop and point to `/larv:design-setup`. Exit 3: continue with zero-credit wireframe cards and say why.
- Directions come from Impeccable; each dealt direction gets one Higgsfield comp (`nano_banana_pro`, 2k, ~2 credits). Declined challengers get no comp.
- All steps run through `bash <larv-plugin-root>/scripts/design-directions.sh <step> "$PWD" <out>`; the options board is served on a public 9000-9499 port and its URL is in `<out>/board-url.txt`.
- The user picks with `pick: <id>`; then the picked comp becomes `DESIGN.md` and the production frontend is redesigned.
- Preserve all backend behavior, routes, policies, validation, migrations, seeders, and user flows unless the user explicitly asks for functional changes.
- Rebuild every screen for every role; run the build, cache/view commands, sandbox restart/probe and desktop + mobile screenshot checks yourself. Show the public sandbox URL.

## Required Artifacts

- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/directions/` (options.json, prompts/, comps/, board/, board-url.txt, decision.md)
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/design-source.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/screen-inventory.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/implementation-report.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/visual-parity.md`
- `PRODUCT.md`, `DESIGN.md`
```

- [ ] **Step 4: Create `skills/larv-redesign-impeccable-higgsfield/SKILL.md`**

```markdown
---
name: larv-redesign-impeccable-higgsfield
description: Use when the user types /larv:redesign-impeccable-higgsfield or asks to redesign a Laravel frontend using Impeccable directions and Higgsfield comps presented on a sandbox URL.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-redesign-impeccable-higgsfield

Redesign the current Laravel frontend: Impeccable proposes grounded directions, Higgsfield renders one comp per direction, the user picks on a public sandbox board, then you implement the pick. This is a production app redesign command, not a mockup-only command. The same steps work in Claude Code, Grok and Codex: every action is a script call or a question to the user.

`D=<larv-plugin-root>/scripts/design-directions.sh`, `R=docs/larv/redesigns/<YYYYMMDD-HHMM>-impeccable-higgsfield`, `OUT=$R/directions`.

## Workflow

1. **Readiness.** `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`. Exit 1: stop, show the output, point to `/larv:design-setup`. Exit 3: tell the user the board will use zero-credit wireframe cards and why (signed out, low credits, or not installed), then continue. Never install tools or sign in here.
2. **Inventory.** Verify this is a Laravel app. Create `$R/`. Write `$R/screen-inventory.md`: every screen for every role (lists, detail pages, create/edit forms, dashboards, admin/settings, profile, dialogs, public pages, empty/loading/error states). Apply the focus argument only to ordering, not to coverage, unless the user limited scope.
3. **Product context.** `bash $D context "$PWD" $OUT`. On `NEEDS_PRODUCT_MD`, read the Impeccable skill's `reference/init.md` and write `PRODUCT.md` from the app and the user's answers (platform, users, purpose, constraints, brand commitments, what must be preserved), then rerun.
4. **Directions.** `bash $D seed "$PWD" $OUT`. Read `$OUT/seed.txt` and the Impeccable skill's `reference/new-work.md` direction-round rules. Author `$OUT/options.json` (shape: `impeccable serve-question --schema`; fields `id,label,thesis,palette,viewport,risk`, optional `kicker,verdict,kept,case,surface`, plus `canonCard`). Three dealt directions as full cards (lead kicker `THE ROLL`), declined challengers with `verdict: "declined"` and a `kept` line, and the category standard as `canonCard`. If `$OUT/fallback` says `seed-unavailable`, write three directions grounded in PRODUCT.md yourself.
5. **Comp prompts.** For each non-declined card write `$OUT/prompts/<id>.txt`: structure-led description of the app's most important screen in that direction, the real product name, the card's palette and type, fictional sample data labeled "Sample data", no invented features, claims, charts or maps. Frame: desktop 3:2 unless the card's `surface` is `phone` (9:16).
6. **Reference image (optional).** A screenshot of the current app may anchor comps only if it shows seeded or fictional data. Save it as `$OUT/refs/reference.png` and create `$OUT/refs/FICTIONAL-DATA-CONFIRMED` only after checking every visible name, token, and attachment is fictional. Never upload live records, receiver links, tokens or attachments to Higgsfield.
7. **Cost.** `bash $D cost "$PWD" $OUT`. Exit 4: show the total and the cap, ask the user; on approval rerun with `LARV_DESIGN_CONFIRMED_SPEND=<total>`. Report credits before spending.
8. **Board first, then comps.** `bash $D board "$PWD" $OUT` then `bash $D serve "$PWD" $OUT auto` (or the port the user asked for). Print the URL from `$OUT/board-url.txt`. Then `bash $D comps "$PWD" $OUT` and `bash $D board "$PWD" $OUT` again (the server serves the updated files). Tell the user the comps are in and credits used.
9. **Pick.** Ask the user to choose (`pick: <id>`, or the harness question tool listing the cards). Steer/re-roll only on request; every re-roll reruns seed → prompts → cost (ask) → comps → board. Then `bash $D pick "$PWD" $OUT <id>`.
10. **DESIGN.md.** Write `DESIGN.md` from the picked card and comp: tokens (color, type, radius, spacing), shell geometry, component patterns, and the rule "every screen is rebuilt". Write `$R/design-source.md` naming the comp file, options.json, and why the pick fits.
11. **Implement.** Apply the redesign to the actual frontend code. Preserve backend behavior, routes, forms, Livewire/Filament actions, validation names, policies, data and workflows. Rebuild every screen in `screen-inventory.md`; a screen on its old markup under new CSS is not redesigned. Keep all roles in one coherent layout. Keep the app logo and favicon.
12. **Verify.** Run dependency install when needed, asset build, Laravel view/cache clears, tests covering touched surfaces, sandbox restart, and public URL probe. Take Playwright desktop and mobile screenshots and compare them with the picked comp; fix drift, broken layouts, inaccessible text and dead actions. Run `bash <larv-plugin-root>/scripts/impeccable.sh detect "$PWD"`.
13. **Report.** Write `$R/visual-parity.md` (screens checked, comp reference, accepted differences, fixes) and `$R/implementation-report.md` (files changed, commands run, sandbox URL, board URL, credits spent, remaining risks). List every screen per role with its coverage. Update `DOCS.md` or `docs/user-manual/README.md` when present.
14. **Board lifetime.** Leave the board running until the user confirms the implementation, then stop it: `static_server_stop "" larv-design-board-<slug>` (slug in `$R/run.yaml` or STATE.yaml).

## Hard Blocks

- Do not stop after the board; the pick must be implemented.
- Do not ask the user to run `npm`, `composer`, `php artisan`, migrations, cache clears, build commands or sandbox restarts. The only user-run step in this whole flow is a Higgsfield sign-in, and that belongs to `/larv:design-setup`.
- Never run `higgsfield auth token`. Never run `higgsfield auth login` yourself.
- Do not spend above the cap without the user's explicit yes; do not re-roll on your own.
- Do not upload live data to Higgsfield (see step 6).
- Do not announce localhost, 127.* or sandbox.example.com URLs.
- Do not change database schema, authorization rules, business logic, seeded credentials, or app workflows unless explicitly requested.
```

- [ ] **Step 5: Create `codex-skills/redesign-impeccable-higgsfield/SKILL.md`**

```markdown
---
name: redesign-impeccable-higgsfield
description: Use when the user types /larv:redesign-impeccable-higgsfield or asks to redesign a Laravel frontend with Impeccable directions and Higgsfield comps.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:redesign-impeccable-higgsfield

This is the Codex-compatible entry point for `/larv:redesign-impeccable-higgsfield`.

Read `commands/larv-redesign-impeccable-higgsfield.md`, then follow `skills/larv-redesign-impeccable-higgsfield/SKILL.md`.

The command must redesign the actual Laravel frontend, not only serve a board. Run `scripts/design-setup.sh check` first, present the options on the public board URL, implement the user's pick, restart/probe the sandbox, and show the public URL.
```

- [ ] **Step 6: Run tests**

Run: `bats tests/commands.bats tests/skills.bats tests/codex.bats`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add commands/larv-redesign-impeccable-higgsfield.md skills/larv-redesign-impeccable-higgsfield/SKILL.md codex-skills/redesign-impeccable-higgsfield/SKILL.md tests/commands.bats tests/skills.bats tests/codex.bats
git commit -m "feat: add /larv:redesign-impeccable-higgsfield

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Phase 3 `impeccable-higgsfield` mode

**Files:**
- Modify: `skills/larv-discuss/SKILL.md` (design-preference choices, ~lines 30-40), `skills/larv-design/SKILL.md`
- Modify: `codex-skills/full/SKILL.md` only if it restates Phase 3 rules (check with `grep -n "world roll" codex-skills -r`)
- Test: `tests/skills.bats`

- [ ] **Step 1: Write the failing test** (append to `tests/skills.bats`)

```bash
@test "Phase 0 and Phase 3 support the impeccable-higgsfield design mode" {
    grep -q "mode: impeccable-higgsfield" skills/larv-discuss/SKILL.md
    f=skills/larv-design/SKILL.md
    grep -q "mode: impeccable-higgsfield" "$f"
    grep -q "design-directions.sh" "$f"
    grep -q "design-setup.sh check" "$f"
    grep -q "docs/larv/03-design/directions/" "$f"
    grep -q "only when the design mode is not \`impeccable-higgsfield\`" "$f"
    grep -q "one interactive HTML prototype of the picked comp" "$f"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/skills.bats`
Expected: the new test FAILS.

- [ ] **Step 3: Edit `skills/larv-discuss/SKILL.md`**

Where the design-preference question lists choices (a)/(b)/(c), add choice (d) to the prompt text:

```
(d) Impeccable directions with Higgsfield comps — I propose three grounded directions, render one comp each (~2 credits per comp), and show them on a sandbox URL for you to pick.
```

and after the `(c)` recording line add:

```
If the user chooses (d), record `mode: impeccable-higgsfield` and `credit_cap: 10` (or the number the user gives).
```

- [ ] **Step 4: Edit `skills/larv-design/SKILL.md`**

a) After the `## Step sequence` heading, insert:

```markdown
### Mode: impeccable-higgsfield

If `docs/larv/00-discuss/design-preferences.md` records `mode: impeccable-higgsfield`, replace steps 2–8 with the directions round, using `OUT=docs/larv/03-design/directions/` and `D=<larv-plugin-root>/scripts/design-directions.sh`:

1. `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`: exit 1 stops the phase with `status: failed`; exit 3 continues with zero-credit wireframe cards (say why).
2. `bash $D context "$PWD" $OUT` (writes PRODUCT.md only; DESIGN.md waits for the pick).
3. `bash $D seed "$PWD" $OUT`; author `$OUT/options.json` and `$OUT/prompts/<id>.txt` exactly as in `skills/larv-redesign-impeccable-higgsfield/SKILL.md` steps 4–5. Add the Attio workspace baseline (`templates/attio-crm-workspace.html`) as the `canonCard`.
4. `bash $D cost "$PWD" $OUT` (exit 4: ask the user, rerun with `LARV_DESIGN_CONFIRMED_SPEND`).
5. Ask for the mockup port as in step 5 below, then `bash $D board "$PWD" $OUT`, `bash $D serve "$PWD" $OUT <port|auto>`, `bash $D comps "$PWD" $OUT`, `bash $D board "$PWD" $OUT`. Print `$OUT/board-url.txt`.
6. User picks (`pick: <id>`); `bash $D pick "$PWD" $OUT <id>`. Copy `$OUT/decision.md` to `docs/larv/03-design/design-decision.md` with the user's rationale.
7. Build one interactive HTML prototype of the picked comp under `docs/larv/03-design/mockups/<pick-slug>/` (`index.html` harness, `interaction-map.md`, working navigation and primary actions, app logo and favicon) and serve it with step 7's mockup-server block on the same port (stop the board session first: `static_server_stop "" larv-design-board-<slug>`). Only one prototype is built: the picked comp's.
8. Continue with step 9. Write `DESIGN.md` from the picked comp and brand spec; do not regenerate it with `impeccable.sh context`.
```

b) Change the sentence in Step 9 "Attio mockups stay the visual source of truth; Impeccable context is a portable export for later polish/detect, not a new design world:" to:

```
Attio mockups stay the visual source of truth only when the design mode is not `impeccable-higgsfield`; in that mode the picked comp and its prototype are the source of truth and DESIGN.md is written from them. Otherwise Impeccable context is a portable export for later polish/detect, not a new design world:
```

c) Change the "What you do not do" bullet "Do not replace Attio mockups with an Impeccable world roll. `PRODUCT.md` and `DESIGN.md` are derived from the approved brand spec." to:

```
- Do not replace Attio mockups with an Impeccable world roll only when the design mode is not `impeccable-higgsfield`. In that mode, the directions round is the approved path and one interactive HTML prototype of the picked comp replaces the multi-screen Attio set.
```

d) In "Mandatory completion gate", add bullets:

```
- In mode `impeccable-higgsfield`: `docs/larv/03-design/directions/board-url.txt` was probe-confirmed and shown, `directions/decision.md` exists, the picked comp sidecar has `approved: true` (unless the pick was a wireframe card), and the single prototype of the picked comp satisfies every mockup bullet above.
```

e) In the subagent return contract `files_written`, add:

```yaml
  - docs/larv/03-design/directions/options.json      # mode impeccable-higgsfield
  - docs/larv/03-design/directions/comps/<id>.png    # mode impeccable-higgsfield
  - docs/larv/03-design/directions/board-url.txt     # mode impeccable-higgsfield
  - docs/larv/03-design/directions/decision.md       # mode impeccable-higgsfield
```

- [ ] **Step 5: Run tests**

Run: `bats tests/skills.bats tests/design-galleries.bats tests/orchestrator-flow.bats`
Expected: all pass (galleries and orchestrator tests must be unaffected; if one greps the exact old "world roll" sentence, update that assertion to the new wording and note it in the commit).

- [ ] **Step 6: Commit**

```bash
git add skills/larv-discuss/SKILL.md skills/larv-design/SKILL.md tests/skills.bats
git commit -m "feat(design): Phase 3 impeccable-higgsfield mode

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Docs, version 0.4.30, full verification, rollout

**Files:**
- Modify: `README.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` (only if it has `"version"`), `tests/readme.bats`

- [ ] **Step 1: Write the failing README test** (in `tests/readme.bats`: add `/larv:redesign-impeccable-higgsfield /larv:design-setup` to the public-commands loop and append)

```bash
@test "README documents Impeccable + Higgsfield design directions" {
    grep -q "## Impeccable + Higgsfield design directions" README.md
    grep -q "/larv:redesign-impeccable-higgsfield" README.md
    grep -q "nano_banana_pro" README.md
    grep -q "LARV_HIGGSFIELD_CREDIT_CAP" README.md
    grep -q "FICTIONAL-DATA-CONFIRMED" README.md
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/readme.bats`
Expected: FAIL.

- [ ] **Step 3: README section** (insert after the "Impeccable design detector" section)

```markdown
## Impeccable + Higgsfield design directions

`/larv:redesign-impeccable-higgsfield [page|role|workflow]` redesigns an existing Laravel app; Phase 3 offers the same round as design mode `impeccable-higgsfield`.

1. Impeccable (vendored skill 4.3.1) deals three grounded directions from `PRODUCT.md`.
2. Higgsfield renders one comp per direction with `nano_banana_pro` at 2k (about 2 credits each). Declined directions get no comp.
3. `scripts/design-directions.sh` renders the options board and serves it on a public 9000-9499 port (probe before announce). You pick with `pick: <id>`.
4. The pick becomes `DESIGN.md`; the redesign command then rebuilds every screen, Phase 3 builds one clickable prototype.

| Setting | Default |
|---|---|
| `LARV_HIGGSFIELD_CREDIT_CAP` | `10` credits per round; above it larv asks first |
| `LARV_HIGGSFIELD_MODEL` | `nano_banana_pro` |
| `LARV_VM_HOST` | public host for board URLs; falls back to `hostname -I` |

Setup: `/larv:design-setup` runs `scripts/design-setup.sh check|install`. It installs the SHA-256-pinned Higgsfield CLI 1.1.26 into `~/.local/share/larv/higgsfield/` and the Impeccable skill into `~/.claude/skills` and `~/.agents/skills`. Signing in is the one user step (`! ~/.local/share/larv/higgsfield/higgsfield auth login`); larv never runs `auth token`. When Higgsfield is unavailable the board uses zero-credit wireframe cards.

Privacy: only screenshots of seeded or fictional data may be sent to Higgsfield as reference images, and `directions/refs/FICTIONAL-DATA-CONFIRMED` must exist before one is used.

Works in Claude Code and Grok (both load larv's `.claude-plugin` commands and skills) and Codex (`codex-skills/`).
```

Also add the two commands to the README's command list/table wherever `/larv:redesign-attio-venture` is listed, using the same row format.

- [ ] **Step 4: CHANGELOG and versions**

Prepend to `CHANGELOG.md` (below its title, matching existing entry style):

```markdown
## 0.4.30 — 2026-09-24

- Add `/larv:redesign-impeccable-higgsfield`: Impeccable directions + Higgsfield comps on a public sandbox board, then a full-screen production redesign.
- Add Phase 3 design mode `impeccable-higgsfield` (one prototype of the picked comp).
- Add `/larv:design-setup` and `scripts/design-setup.sh` (pinned Higgsfield CLI 1.1.26, readiness check in pre-flight).
- Vendor Impeccable skill 4.3.1 in `bundle/impeccable/`.
- `impeccable.sh context` honors `LARV_IMPECCABLE_PRODUCT_ONLY=1`.
```

Set `"version": "0.4.30"` in `.claude-plugin/plugin.json`, both version fields in `.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json` if it has one:

```bash
jq '.version = "0.4.30"' .claude-plugin/plugin.json > /tmp/p.json && mv /tmp/p.json .claude-plugin/plugin.json
jq '.plugins[0].version = "0.4.30"' .claude-plugin/marketplace.json > /tmp/m.json && mv /tmp/m.json .claude-plugin/marketplace.json
grep -q '"version"' .codex-plugin/plugin.json && jq '.version = "0.4.30"' .codex-plugin/plugin.json > /tmp/c.json && mv /tmp/c.json .codex-plugin/plugin.json || true
```

- [ ] **Step 5: Full verification**

Run in background: `bats --jobs 4 tests/ > /tmp/larv-bats.tap 2>&1; echo exit=$? >> /tmp/larv-bats.tap`
Expected: `exit=0`, or only failures that were already present in the pre-change baseline (compare with the baseline TAP captured before Task 1; list any such pre-existing failures in the final report).

Run: `bash scripts/check-dox-contracts.sh tests/fixtures/integration-greenfield` if that fixture carries the contracts, else the fixture the existing `tests/dox-contracts.bats` uses. Expected: same result as on `main`.

- [ ] **Step 6: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json tests/readme.bats
git commit -m "docs: document Impeccable + Higgsfield design directions; bump 0.4.30

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 7: Live smoke on this server (spends ~2 credits; ask the user first)**

```bash
S=$(mktemp -d); mkdir -p "$S/smoke"; printf '# Smoke\n\nOne-screen todo app for a small team.\n' > "$S/smoke/PRODUCT.md"
OUT="$S/smoke/directions"; mkdir -p "$OUT/prompts"
cat > "$OUT/options.json" <<'EOF'
{"title":"Smoke","question":"Smoke test","options":[{"id":"assigned","label":"Ledger","kicker":"THE ROLL","thesis":"Todo as a ledger","palette":["#ffffff","#1f5f46"],"viewport":"Single list","risk":"Plain"}]}
EOF
printf 'High-fidelity desktop web app mockup, landscape, flat screenshot. "Smoke" todo app, one list of five fictional tasks, white and forest green, labeled Sample data.\n' > "$OUT/prompts/assigned.txt"
bash scripts/design-directions.sh cost "$S/smoke" "$OUT"
bash scripts/design-directions.sh comps "$S/smoke" "$OUT"
bash scripts/design-directions.sh board "$S/smoke" "$OUT"
bash scripts/design-directions.sh serve "$S/smoke" "$OUT" auto
curl -fsS "$(cat "$OUT/board-url.txt")" | grep -q Ledger && echo SMOKE-OK
```

Expected: `cost: 2 credits`, `comps: assigned done`, `Design board ready at http://46.250.229.188:9xxx/`, `SMOKE-OK`. Then stop the board: `bash -c '. scripts/lib/vm.sh; . scripts/lib/static_server.sh; static_server_stop "" larv-design-board-smoke'`.

- [ ] **Step 8: Rollout instructions for the user (do not run without approval)**

- Claude Code: `claude plugin marketplace update larv-local && claude plugin update larv@larv-local`, then restart sessions.
- Grok: `grok plugin marketplace add /home/claude-team/kaito/workflow` and install `larv` from it.
- Codex: already reads `codex-skills/` from the repo per `docs/CODEX.md`.
- Merge/push of `feat/impeccable-higgsfield-design` is the user's call.
```

- [ ] **Step 9: Final report**

Report: commits on the branch, test results (with any pre-existing baseline failures listed), the smoke board URL and credits spent, and the rollout commands.
