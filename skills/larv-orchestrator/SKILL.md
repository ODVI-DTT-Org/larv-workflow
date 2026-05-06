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
