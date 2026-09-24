# Impeccable + Higgsfield design directions — design spec

Date: 2026-09-24 · Branch: `feat/impeccable-higgsfield-design` · Target version: larv 0.4.30

## Goal

Make the design flow proven on the PRS redesign (`loi/prs`, 2026-09-23) a standard larv capability:

1. **Impeccable** proposes grounded visual directions from `PRODUCT.md`.
2. **Higgsfield** renders one comp per direction (cheapest path).
3. The options are presented on a **probe-confirmed public sandbox URL**, not localhost.
4. The user picks; the pick becomes `DESIGN.md` and drives implementation.

Available to everyone on this server without setup, from Claude Code, Grok and Codex.

## Decisions (confirmed by the user)

| Topic | Decision |
|---|---|
| Entry points | Both: Phase 3 (`larv-design`) gains an `impeccable-higgsfield` mode, and a new command `/larv:redesign-impeccable-higgsfield` redesigns existing apps. |
| Cost | "Most cheapest". Board shows **comps only** (one per dealt direction, `nano_banana_pro`, 2k, 2 credits each ≈ 6 credits/round). No comps for declined challengers. No re-roll without asking. Redesign goes straight from the picked comp to implementation. Phase 3 builds **one** clickable HTML prototype, of the picked comp only, because the downstream visual-implementation contract requires it (no credits). |
| Higgsfield login | One shared login for all `claude-team` users: **dtt@oakdriveventures.com** (Lite plan), reused from `loi/prs`. |
| Fallback | If Higgsfield is not signed in, out of credits, or Impeccable's `concept-seed` API is unreachable: still serve the board with **zero-credit palette/wireframe cards** and say why. |
| Setup | **Preinstalled on this server now** (done 2026-09-24, see below). A `/larv:design-setup` command exists for other machines; the design flow never installs or signs in mid-round. |
| Agents | Logic lives in shell scripts; skills are thin wrappers. Claude Code and Grok load larv's `.claude-plugin` skills/commands (Grok accepts `.claude-plugin/` manifests); Codex uses a `codex-skills/` mirror. |

## Server state already in place (2026-09-24)

All developers share the `claude-team` OS account, so user-level installs cover everyone.

| Item | Location | Notes |
|---|---|---|
| Higgsfield CLI v1.1.26 linux_amd64 | `~/.local/share/larv/higgsfield/bin/higgsfield` | SHA-256 `5d666fae70c99b7388690191a649d1487962250ed50820e079edfd1ffac7bf5b` verified from the official release. Dir mode 700. |
| Higgsfield wrapper | `~/.local/share/larv/higgsfield/higgsfield`, symlinked at `~/.local/bin/higgsfield` | Sets `HIGGSFIELD_CREDENTIALS_PATH`, `HIGGSFIELD_CONFIG_PATH`, `HIGGSFIELD_DISABLE_TELEMETRY=1`, `HIGGSFIELD_NO_UPDATE_CHECK=1`. |
| Shared login | `~/.local/share/larv/higgsfield/credentials.json` (0600) | Copied from `loi/prs/.tools/higgsfield`. Verified: `dtt@oakdriveventures.com — lite plan, 79 credits`. |
| Impeccable skill 4.3.1 | `~/.claude/skills/impeccable`, `~/.grok/skills/impeccable`, `~/.agents/skills/impeccable` | Copied from `loi/prs` (upstream commit `83c2c735777c68e30ea536ab9cc97f7843456945`). Previous Grok 4.1.1 backed up under `~/.local/share/larv/backups/`. |
| Impeccable engine 0.1.5 | `~/.impeccable/bin/0.1.5/impeccable` | Downloaded and checksum-verified by the skill launcher. |

The larv plugin itself is installed from a cache (`~/.claude/plugins/cache/larv-local/larv/0.4.29`); the code changes below reach users only after a plugin update (see Rollout).

## Architecture

```
/larv:redesign-impeccable-higgsfield ─┐
larv-design (mode impeccable-higgsfield)┼─► scripts/design-setup.sh check   (gate, no side effects)
                                       └─► scripts/design-directions.sh <step> …
                                              context → seed → cost → comps → board → serve → pick
                                              uses: Impeccable launcher, higgsfield wrapper,
                                                    scripts/lib/{vm,verifier,static_server,probe}.sh
```

### Unit 1 — `scripts/design-setup.sh`

`check [dir]` | `install` | `help`. Pure bash, agent-neutral.

- **Tool resolution** (shared with Unit 2 via `scripts/lib/design_tools.sh`):
  - Higgsfield: `$LARV_HIGGSFIELD_BIN` → `~/.local/share/larv/higgsfield/higgsfield` → `higgsfield` on PATH.
  - Impeccable launcher: `$LARV_IMPECCABLE_SKILL_DIR/scripts/impeccable` → `<plugin>/bundle/impeccable/scripts/impeccable` → `~/.claude/skills/impeccable/scripts/impeccable` → `~/.agents/skills/impeccable/scripts/impeccable`.
  - Public host: `LARV_VM_HOST` unless it is unset or `sandbox.example.com`; else first address of `hostname -I`. Refuse `localhost`, `127.*`, `sandbox.example.com`.
- **`check`** prints one line per item and exits 0 when the full path is ready, 3 when only the zero-credit fallback is available, 1 on hard failure (no Impeccable launcher, no public host, missing `php curl ss setsid`):
  - Impeccable launcher present and `engine-probe` succeeds.
  - Higgsfield wrapper present; `account status` succeeds; prints account email, plan and credits (never tokens).
  - Credits ≥ `LARV_HIGGSFIELD_CREDIT_CAP` (default 10) → ready; else fallback.
  - Public host resolved.
- **`install`** (other machines only; a no-op report when already installed):
  - Detects `uname -sm`; only `Linux x86_64` has a known checksum. Other platforms: refuse with a message.
  - Downloads the pinned Higgsfield archive, verifies SHA-256, installs the wrapper exactly as on this server.
  - Copies the vendored Impeccable skill from `bundle/impeccable/` into `~/.claude/skills/impeccable` and `~/.agents/skills/impeccable` only when absent (never overwrites without `LARV_DESIGN_SETUP_FORCE=1`, backing up first), then runs `engine-probe`.
  - Never runs `higgsfield auth login` itself. Prints the one user step: `! ~/.local/share/larv/higgsfield/higgsfield auth login` (no `--port`; headless callback steps copied from `loi/prs/docs/higgsfield-setup.md`). Never runs `auth token`.
- `pre-flight.sh` calls `design-setup.sh check` and reports only (like the existing Impeccable status line).

### Unit 2 — `scripts/design-directions.sh`

Each step is a subcommand so the skill can pause for the user between steps. Output directory `OUT`:
- Phase 3: `docs/larv/03-design/directions/`
- Redesign: `docs/larv/redesigns/<ts>-impeccable-higgsfield/directions/`

| Step | Does | Writes |
|---|---|---|
| `context <dir> <out>` | Phase 3: derive `PRODUCT.md` from larv docs (existing `impeccable.sh context` logic, PRODUCT only; `DESIGN.md` is **not** written yet). Redesign: keep an existing `PRODUCT.md`; otherwise the skill authors it from the app (Impeccable `init` ask round) before continuing. | `PRODUCT.md` |
| `seed <dir> <out>` | Runs `impeccable concept-seed --candidate-count 7`, saves raw output. The agent then authors `options.json` in the `serve-question --schema` shape (assigned card, model pick, dealt challengers with verdicts, canon card) with `comp` paths under `<out>/comps/`. On API failure: mark `fallback: seed-unavailable`. | `seed.txt`, `options.json` |
| `cost <out>` | `higgsfield generate cost nano_banana_pro` per card needing a comp; sums; compares with cap. Over cap → exit 4 (skill asks the user). | `cost.json` |
| `comps <out>` | For each comp card in reading order: `higgsfield generate create nano_banana_pro --prompt-file … --aspect_ratio <3:2 desktop / 9:16 phone> --resolution 2k --wait`, download result, write `<id>.png` + `<id>.json` sidecar (prompt, model, credits, date, `approved: false`, `sample_data: true`). Any failure → that card falls back to its wireframe; the run continues. | `comps/*` |
| `board <out>` | Renders a static `index.html` from `options.json` + comps: one full card per dealt direction (comp or wireframe, palette chips, thesis, first viewport, risk), declined challengers as compact rows with their "kept" line, a canon/Attio baseline card, "Sample data" labels, and the pick instruction (`pick: <id>` in chat). No external requests. | `board/index.html`, `board/*.png` |
| `serve <dir> <out>` | Allocates a 9000–9499 port (`allocate_port mockup <slug>`, user may request a number), opens firewall, `static_server_start` on `<out>/board`, inside + external probes, then prints the URL. Slug: `STATE.yaml .project.slug`, else directory basename. Port recorded in `STATE.yaml` when present, else `<out>/../run.yaml`. | `board-url.txt` |
| `pick <out> <id>` | Marks the chosen card's sidecar `approved: true` with date; others unchanged. | sidecar update, `decision.md` |

Prompt discipline (from PRS, enforced in the skill text): structure-led prompt, real product name, fictional labeled sample data, the card's own palette and type, no invented claims or features; frame aspect matches the surface.

### Unit 3 — `/larv:redesign-impeccable-higgsfield [page|role|workflow]`

Files: `commands/larv-redesign-impeccable-higgsfield.md` (name `larv:redesign-impeccable-higgsfield`), `skills/larv-redesign-impeccable-higgsfield/SKILL.md`, `codex-skills/redesign-impeccable-higgsfield/SKILL.md`. Headroom Combo header block like every other skill.

Flow:
1. `design-setup.sh check` → stop with the setup message on exit 1; announce fallback on exit 3.
2. Verify Laravel app; create `docs/larv/redesigns/<ts>-impeccable-higgsfield/`; write `screen-inventory.md` (every screen per role).
3. `context` → `seed` → `cost` (ask if over cap) → `serve` (board goes up first with shimmer placeholders) → `comps` → `board` re-render → print URL.
4. User picks in chat (`pick: <id>`, or the harness question tool). Steer/re-roll only on request, each re-roll re-running `cost` and asking.
5. `pick`; write `DESIGN.md` from the chosen card (tokens, type, patterns) and `design-source.md`.
6. Implement per the `larv-redesign-attio-*` contract: preserve routes/policies/validation/data; **every screen rebuilt** (PRS rule, `DESIGN.md` "Redesign rule"); build, cache clears, sandbox restart + public probe; Playwright desktop + mobile screenshots compared against the comp; `visual-parity.md`, `implementation-report.md`; run `impeccable.sh detect`.
7. Stop the board server after the user confirms the implementation (or leave it running on request).

### Unit 4 — Phase 3 changes

- `larv-discuss`: add choice `(d) Impeccable directions + Higgsfield comps` → `mode: impeccable-higgsfield`.
- `larv-design`: when mode is `impeccable-higgsfield`, steps 2–8 are replaced by the Unit 2 steps (board on the Phase 3 mockup port; the Attio workspace baseline appears as the canon card). After the pick, build **one** interactive HTML prototype of the chosen comp under `docs/larv/03-design/mockups/<pick-slug>/` (index harness, interaction map, logo/favicon) served on the same port, then steps 9–11 unchanged. `DESIGN.md` is written from the pick (not derived from `brand-spec.md` by `impeccable.sh context`).
- Rule text changes: "Do not replace Attio mockups with an Impeccable world roll" and "Attio mockups stay the visual source of truth" apply only when mode ≠ `impeccable-higgsfield`. Completion gate gains: board URL probe-confirmed, `decision.md` exists, chosen sidecar `approved: true`.
- Orchestrator: no change (Phase 3 subagent contract is unchanged; `files_written` gains the directions paths).

## Safety

- **No live data leaves the server.** Reference screenshots uploaded to Higgsfield must come from seeded/fictional data only; never live records, receiver tokens, attachments or credentials. The skill states this as a hard block; `comps` only accepts references under `<out>/refs/` and the skill must confirm they are fictional.
- **Spend control:** `cost` before every spend, cap per round (`LARV_HIGGSFIELD_CREDIT_CAP`, default 10), no automatic re-roll, credits printed before and after.
- **Secrets:** never run or print `auth token`; credential files 0600 in a 0700 dir; wrappers disable telemetry and update checks.
- **Announce rules:** reuse probe-before-announce; never print localhost/127.*/sandbox.example.com.

## Vendoring

- `bundle/impeccable/` = the 4.3.1 skill (≈2.2 MB) with `UPSTREAM.md` recording the commit; `bundle/VERSIONS.yaml` gains `impeccable-skill: "4.3.1"` and `higgsfield-cli: "1.1.26"`.
- `scripts/impeccable.sh` keeps using the npm CLI (`impeccable@3.6.0`) for `detect` only; direction work uses the vendored skill launcher.

## Testing

Bats, no network, no credits:

- `tests/design_setup.bats`: tool resolution order; `check` exit codes 0/3/1 with stubbed `LARV_HIGGSFIELD_BIN` (signed in / signed out / low credits) and stub launcher; host resolution refuses `sandbox.example.com`/localhost; `install` refuses non-`Linux x86_64` and checksum mismatch (stub download).
- `tests/design_directions.bats`: `cost` sums and cap exit 4; `comps` writes png + sidecar per card and falls back per card on stub failure; `board` renders every dealt card, labels sample data, contains no external URLs; `serve` uses the directory-basename slug without `STATE.yaml` and writes `run.yaml`; `pick` sets `approved: true` on only the chosen sidecar.
- Existing suites updated: `commands.bats`, `skills.bats`, `codex.bats`, `readme.bats`, `manifest.bats`, `bundle.bats` pass with the new command/skill/bundle entries; `scripts/check-dox-contracts.sh` passes.
- Manual smoke on this server: run the redesign command against a throwaway copy of a small app, confirm the board URL opens externally on `46.250.229.188`, one real comp (2 credits) renders.

## Docs and rollout

- README: new section "Impeccable + Higgsfield design directions" (setup, cost, fallback, privacy rule); CHANGELOG 0.4.30; `plugin.json` and `marketplace.json` → 0.4.30.
- After merge: `claude plugin marketplace update larv-local && claude plugin update larv@larv-local` (Claude), `grok plugin marketplace add /home/claude-team/kaito/workflow` then install `larv` (Grok), Codex reads `codex-skills/` per `docs/CODEX.md`.
- Commit only files this work adds or changes; the branch was created over pre-existing uncommitted edits, which stay unstaged.

## Out of scope

- Impeccable's `serve-question` daemon and live mode (localhost-bound, refuses headless).
- Video/animation generation, Higgsfield `website` builder.
- Per-user Higgsfield accounts.
- Changing Phase 3's default (Attio remains the default recommendation).
