---
name: larv-implement
description: Phase 8 thin loop — read each docs/Handsoff/slice-NN-*.md and execute its inline bash. Same code path for same-session, subagents, and external-AI execution.
---

# larv-implement

Execute slices by following their handsoff documents. Do not improvise. Do not call plugin scripts that are not referenced inside the handsoff. The handsoff is self-contained by spec rule §3.2.

When Claude Code executes this phase directly, use bundled Laravel guidance from `bundle/superpowers-laravel/skills` as needed for migrations, policies, validation, queues, env config, tests, and quality checks. External handoff tools do not need those skills because the handoff files are self-contained.

## Inputs

- `docs/larv/STATE.yaml`
- `docs/Handsoff.md`
- `docs/Handsoff/bootstrap-sandbox.md`
- `docs/Handsoff/slice-NN-<name>.md` (one per slice)
- `docs/larv/03-design/visual-implementation-contract.md`
- chosen mockups under `docs/larv/03-design/mockups/`

## Bootstrap — mandatory before first slice

Before executing any slice, read `docs/Handsoff/bootstrap-sandbox.md` and execute its bash block top to bottom. For greenfield docs-only projects, this bootstrap creates the bare Laravel scaffold first when `artisan` is missing; that is not considered slice implementation. Do not proceed to slice implementation until it prints the sandbox URL and writes `docs/larv/07-runtime/sandbox-url.txt`.

## Execution cadence

Before the loop, read `STATE.yaml.execution.review_mode`.

- `auto-all`: implement every eligible slice without stopping until all slices pass verification, the app is fully tested, or a blocker/failing test requires user input.
- `manual-slice`: after every slice, show `docs/larv/07-runtime/sandbox-url.txt`, list terminal commands run, list browser QA actions from `docs/user-manual/testing/<slice-id>-<slice-slug>.md`, show `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-<slice-id>.md`, and wait for user approval.
- `manual-adr`: pause only after slices that create or change ADRs/significant decisions.
- `manual-phase`: pause after major boundaries such as bootstrap, feature group, final verification, and deployment prep.

If missing or `not-yet-decided`, default to `manual-slice`.

## Loop body — do this for every slice in dependency order

For each `slice-NN-<name>.md`:

1. Read it from top to bottom.
2. Execute every bash block in section 12 (Implementation commands).
3. If the slice touches UI, read `docs/larv/03-design/visual-implementation-contract.md`, `brand-spec.md`, `ui-design.md`, and the chosen mockups before styling. Implement the app route to match the chosen mockup as the visual source of truth. Capture desktop and mobile screenshots under `docs/larv/08-implementation/screenshots/<slice-id>/`, compare them to the reference mockups, and fix drift before completion. Remaining visual differences require explicit documentation and user approval.
4. Run section 10's Definition of Done checklist.
5. Write `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-<slice-id>.md` per section 16; never write implementation reports at the project root.
6. Write or update the hard-required user testing guide at `docs/user-manual/testing/<slice-id>-<slice-slug>.md`.
7. Update `docs/user-manual/seed-data.md` with seeded records, demo credentials, reset commands, and demo-data removal notes.
8. Run section 13's tracker append snippet.
9. Run section 14's local-learnings append snippet if you discovered something.
10. Run section 15's STATE.yaml update snippet.
11. Apply the execution cadence above. Always print the public sandbox URL and exact guide paths when pausing for user review.

## Failure handling

If any step fails:

1. Mark `STATE.yaml.slices.NN.status: failed`.
2. Write the failed `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-<slice-id>.md` describing what broke.
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
