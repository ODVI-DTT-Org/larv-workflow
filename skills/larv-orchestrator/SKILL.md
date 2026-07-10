---
name: larv-orchestrator
description: Top-level dispatcher. Per-phase soft gate, required mockup/docsite URLs, mandatory handoff generation, and routing menu before Phase 8. Spawns fresh subagents per phase.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-orchestrator

Drive the larv workflow. Read `STATE.yaml`, decide the next phase, dispatch the appropriate skill, gate on its output, commit, and advance.

## Invocation modes

- **greenfield** — full flow (Phase −1 → 11). Invoked by `/larv:full`.
- **feature** — `/larv:feature <name>` mini-flow. Mandatory Laravel Superpowers brainstorming + writing-plan first; saves feature design/plan artifacts, then appends deltas, ADRs, handoff slices, tracker, STATE, doc-site, and implementation cadence.
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
# 4. Run scripts/token-optimizer.sh status "$dir"; use only the gate's run path if safe.
# 5. Determine next phase from STATE.yaml.phase.current.
```

## Security gates

Security checks are hard gates for greenfield execution. Use `larv-security` as the shared repository guard; it wraps the static, non-executing `scripts/security-scan.sh` scanner.

- **Phase -1 baseline**: `scripts/pre-flight.sh` runs `scripts/security-scan.sh` before creating `STATE.yaml`. If the scanner fails, stop the workflow before planning, dependency installation, app bootstrap, or implementation. The report path is `docs/larv/security/pre-flight-security.md`.
- **Before Phase 8**: Re-run `bash <larv-plugin-root>/scripts/security-scan.sh "$dir" "$dir/docs/larv/security/pre-implementation-security.md"` after handoff/docsite generation and before the routing menu dispatches implementation. If it fails, write `errors_unresolved` to `STATE.yaml` with the report path and stop.
- **Phase 8 slices**: `larv-implement` must run the same scanner before and after each slice, writing reports under `docs/larv/security/slices/`. A post-slice failure blocks the next slice and requires user review.
- **Bypass policy**: Do not bypass failed security scans automatically. `LARV_SECURITY_ALLOW_FAIL=1` is only acceptable when the user explicitly acknowledges the report path and asks to continue for a controlled test or false positive.

The scanner is intentionally static and non-executing. Do not source repository scripts, install dependencies, run package lifecycle scripts, or execute unknown binaries while investigating a failed security check.

## Token optimizer gate

Headroom and LeanCTX are optional. They must never be invoked directly from a larv workflow. Before context-heavy work, run:

```bash
bash scripts/token-optimizer.sh status "$dir"
```

Only a `safe` result may be used, and execution must route through `scripts/token-optimizer.sh run`. If the gate reports fallback, continue without an optimizer and surface the fallback reason in status/pre-flight. Do not use Headroom wrap/proxy/Docker-wrapper/memory/telemetry modes. Do not let LeanCTX run onboarding/setup mutation, shell/autostart hooks, update checks, stats, or reads outside the workspace.

## Per-phase loop

For each phase `N`:

1. **Spawn the phase subagent** (skill `larv-<name>`).
2. **Wait for its return contract** (yaml from §8 of the spec).
3. **Validate hard completion requirements** for that phase.
4. **Apply state_updates** via `bash scripts/state.sh update`.
5. **Auto-commit** via `safe_commit_docs "[larv] phase $N: $name approved"`.
6. **Soft gate** via `soft_gate "$dir" "$N" "$name" "$summary" "$changed_csv"`.
7. **Loopback check.** If subagent's `state_updates.current_phase` points backward, jump there.

## Runtime URL enforcement

Some phases create browser-visible services. These are hard completion requirements, not optional niceties.

If a phase subagent returns `status: complete` but any required runtime URL or probe artifact is missing, treat the phase as failed, write `errors_unresolved` to `STATE.yaml`, and stop. Do not soft-gate, do not advance, and do not tell the user to proceed manually.

Required runtime fields:

| Phase | Skill | Required field | Required artifact |
|---|---|---|---|
| 3 | `larv-design` | `mockup_url` | `docs/larv/03-design/mockup-url.txt` |
| 6.5 | `larv-docsite` | `docsite_url` | `docs/larv/docsite-url.txt` |

Each URL must start with `http://sandbox.example.com:` and must only be accepted after the phase subagent reports firewall handling plus both inside-VM and outside probe success. Missing URL, missing artifact, `null`, `TBD`, `127.0.0.1`, `localhost`, or "skipped" means failure.

## Phase sequence (greenfield)

The greenfield mode dispatches phases in this exact order:

1. **Phase -1**: pre-flight (script, not a skill)
2. **Phase 0a**: dispatch `larv-domain-interview`
3. **Phase 0**: dispatch `larv-discuss`
4. **Phase 1**: dispatch `larv-domain`
5. **Phase 2**: dispatch `larv-architecture`
6. **Phase 3**: dispatch `larv-design`
7. **Phase 4**: dispatch `larv-tests`
8. **Phase 5**: dispatch `larv-premortem`
9. **Phase 6**: dispatch `larv-plan`
10. **larv-handoff** (mandatory): writes `docs/Handsoff.md`, `docs/Handsoff/bootstrap-sandbox.md`, production/env/ops guides, and per-slice handoffs.
11. **Phase 6.5**: dispatch `larv-docsite` after handoff so the doc-site includes `docs/Handsoff/*`.
12. **Phase 8 routing menu**: show exact handoff paths and ask `same-session` | `subagents` | `handoff`.
13. **Phase 8**: dispatch `larv-implement` (or stop, if `handoff` was chosen). Implementation must run `docs/Handsoff/bootstrap-sandbox.md` before the first slice.
14. **Phase 9**: dispatch `larv-verify`
15. **Phase 10**: dispatch `larv-deploy`
16. **Phase 11**: dispatch `larv-learn`

## Feature sequence

For `/larv:feature <name>`, do not run the greenfield phases and do not implement immediately.

1. Verify `docs/larv/STATE.yaml` exists and the working tree is clean outside `docs/` and `adr/`.
2. Create `docs/larv/features/<feature-slug>/`.
3. Invoke Laravel Superpowers brainstorming from `bundle/superpowers-laravel/skills/brainstorming/SKILL.md`; save the approved design to `docs/larv/features/<feature-slug>/design.md` and `docs/superpowers/specs/YYYY-MM-DD-<feature-slug>-design.md`.
4. Run a larv-owned **Ponytail YAGNI audit** on the approved design and save it to `docs/larv/features/<feature-slug>/yagni-audit.md`. This wrapper audit must record the need/not-needed decision, removed scope, reused existing screens/config/workflows, rejected packages or abstractions, slice-count rationale, and protected items not simplified away. It must decide whether the feature needs to exist, remove unrequested feature scope, prefer existing screens/config/workflows and native Laravel behavior, reject new packages or abstractions for future use, and collapse the plan to one small slice instead of several when that satisfies the approved need. It must not remove security, validation, accessibility, or explicitly requested scope.
5. Update `STATE.yaml.features[]` with `status: design-approved`, `design_path`, `yagni_audit_path`, and timestamps.
6. Produce DDD/package/design/architecture deltas only where the feature requires them. Save durable feature-local files under `docs/larv/features/<feature-slug>/` and append stable project decisions to existing `docs/larv/` docs or `adr/`.
7. Invoke Laravel Superpowers writing-plans from `bundle/superpowers-laravel/skills/writing-plans/SKILL.md`; save to `docs/larv/features/<feature-slug>/plan.md` and `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`.
8. Re-run the Ponytail YAGNI audit against the written plan before handoff generation; update `yagni-audit.md` with any removed scope, reused existing paths, rejected packages or abstractions, protected items, and why the remaining slices are the minimum needed.
9. Append feature slices to `docs/larv/06-implementation/elephant-carpaccio.md` and update `STATE.yaml.slices`.
10. Regenerate per-slice handoff, `docs/Handsoff.md`, AI starting-point files, and doc-site.
11. Append tracker entries with `type: feature_planning` for planning and `type: feature` for implementation slices. Append `docs/larv/local-learnings.md` if anything useful was learned.
12. Call `routing_menu "$dir"` so the user chooses venue and review cadence (`auto`, `manual-slice`, `manual-adr`, or `manual-phase`) before implementation.

## Hard gates

- **Security baseline**: `STATE.yaml.security.baseline.status` must be `passed` before any phase after Phase -1. `bypassed` is acceptable only when the user explicitly acknowledged the report path and requested continuation. Missing security state means failure for greenfield mode.
- **Before Phase 8**: After `larv-handoff` and `larv-docsite` succeed, print the next-step paths:
  - `docs/Handsoff.md`
  - `docs/Handsoff/bootstrap-sandbox.md`
  - `docs/Handsoff/production-deploy.md`
  - `docs/Handsoff/env-guide.md`
  - `docs/Handsoff/operations-guide.md`
  - `docs/Handsoff/package-guide.md`
  - `docs/Handsoff/slice-NN-<name>.md`
  - `docs/larv/docsite-url.txt`
  Then run the pre-implementation security scan described above and call `routing_menu "$dir"`. If `mode=handed-off-external`, mark `/larv:full` complete and exit after telling the user to open `docs/Handsoff.md` first and run `docs/Handsoff/bootstrap-sandbox.md` before any slice. Otherwise, dispatch `larv-implement`.

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
- You do not bypass gates; soft gates and the Phase 8 routing menu are mandatory.
- You do not commit non-`docs/`/`adr/` paths except generated AI entry points; `safe_commit_docs` enforces this.
