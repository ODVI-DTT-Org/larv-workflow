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
| 7 | `larv-provision` | `sandbox_url` | `docs/larv/07-runtime/sandbox-url.txt` |

Each URL must start with `http://31.220.79.31:` and must only be accepted after the phase subagent reports both inside-VM and outside probe success. Missing URL, missing artifact, `null`, `TBD`, or "skipped" means failure.

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
10. **Phase 6.5**: dispatch `larv-docsite` (writes nothing; serves the doc-site)
11. **Phase 7 hard gate** (provisioning approval)
12. **Phase 7**: dispatch `larv-provision`
13. **larv-handoff** (mandatory)
14. **Phase 8 hard gate** (routing menu)
15. **Phase 8**: dispatch `larv-implement` (or stop, if `handoff` was chosen)
16. **Phase 9**: dispatch `larv-verify`
17. **Phase 10**: dispatch `larv-deploy`
18. **Phase 11**: dispatch `larv-learn`

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
