---
name: larv-orchestrator
description: Top-level dispatcher. Per-phase soft gate, required mockup/docsite URLs, mandatory handoff generation, and routing menu before Phase 8. Spawns fresh subagents per phase.
---

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
# 4. Determine next phase from STATE.yaml.phase.current.
```

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

Each URL must start with `http://31.220.79.31:` and must only be accepted after the phase subagent reports firewall handling plus both inside-VM and outside probe success. Missing URL, missing artifact, `null`, `TBD`, `127.0.0.1`, `localhost`, or "skipped" means failure.

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
4. Update `STATE.yaml.features[]` with `status: design-approved`, `design_path`, and timestamps.
5. Produce DDD/package/design/architecture deltas only where the feature requires them. Save durable feature-local files under `docs/larv/features/<feature-slug>/` and append stable project decisions to existing `docs/larv/` docs or `adr/`.
6. Invoke Laravel Superpowers writing-plans from `bundle/superpowers-laravel/skills/writing-plans/SKILL.md`; save to `docs/larv/features/<feature-slug>/plan.md` and `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`.
7. Append feature slices to `docs/larv/06-implementation/elephant-carpaccio.md` and update `STATE.yaml.slices`.
8. Regenerate per-slice handoff, `docs/Handsoff.md`, AI starting-point files, and doc-site.
9. Append tracker entries with `type: feature_planning` for planning and `type: feature` for implementation slices. Append `docs/larv/local-learnings.md` if anything useful was learned.
10. Call `routing_menu "$dir"` so the user chooses venue and review cadence (`auto`, `manual-slice`, `manual-adr`, or `manual-phase`) before implementation.

## Hard gates

- **Before Phase 8**: After `larv-handoff` and `larv-docsite` succeed, print the next-step paths:
  - `docs/Handsoff.md`
  - `docs/Handsoff/bootstrap-sandbox.md`
  - `docs/Handsoff/production-deploy.md`
  - `docs/Handsoff/env-guide.md`
  - `docs/Handsoff/operations-guide.md`
  - `docs/Handsoff/package-guide.md`
  - `docs/Handsoff/slice-NN-<name>.md`
  - `docs/larv/docsite-url.txt`
  Then call `routing_menu "$dir"`. If `mode=handed-off-external`, mark `/larv:full` complete and exit after telling the user to open `docs/Handsoff.md` first and run `docs/Handsoff/bootstrap-sandbox.md` before any slice. Otherwise, dispatch `larv-implement`.

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
- You do not commit non-`docs/`/`adr/` paths; `safe_commit_docs` enforces this.
