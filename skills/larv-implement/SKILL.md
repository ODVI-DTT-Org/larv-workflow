---
name: larv-implement
description: Phase 8 thin loop — read each docs/Handsoff/slice-NN-*.md and execute its inline bash. Same code path for same-session, subagents, and external-AI execution.
---

# larv-implement

Execute slices by following their handsoff documents. Do not improvise. Do not call plugin scripts that are not referenced inside the handsoff. The handsoff is self-contained by spec rule §3.2.

## Inputs

- `docs/larv/STATE.yaml`
- `docs/Handsoff.md`
- `docs/Handsoff/bootstrap-sandbox.md`
- `docs/Handsoff/slice-NN-<name>.md` (one per slice)

## Bootstrap — mandatory before first slice

Before executing any slice, read `docs/Handsoff/bootstrap-sandbox.md` and execute its bash block top to bottom. Do not proceed to slice implementation until it prints the sandbox URL and writes `docs/larv/07-runtime/sandbox-url.txt`.

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
