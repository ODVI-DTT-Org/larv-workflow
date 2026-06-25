---
name: larv-implement
description: Phase 8 thin loop — read each docs/Handsoff/slice-NN-*.md and execute its inline bash. Same code path for same-session, subagents, and external-AI execution.
---

# larv-implement

Execute slices by following their handsoff documents. Do not improvise. Do not call plugin scripts that are not referenced inside the handsoff, except the mandatory non-executing security scanner described below. The handsoff is self-contained by spec rule §3.2.

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

## Security scans — mandatory around implementation

The implementation loop must run static, non-executing security checks before and after each slice:

- Before slice `NN`: `bash <larv-plugin-root>/scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/slices/pre-slice-NN.md"`.
- After slice `NN`: `bash <larv-plugin-root>/scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/slices/post-slice-NN.md"`.
- Record both report paths in `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-<slice-id>.md`.
- If a scan fails, stop before running the next slice, mark the slice failed, write the report path into the implementation report and `STATE.yaml.errors_unresolved`, and ask the user to review. Only continue with `LARV_SECURITY_ALLOW_FAIL=1` after the user explicitly acknowledges the report.

While investigating a security finding, do not source project scripts, run unknown binaries, or execute package lifecycle scripts. Prefer reading files and static command output.

## YAGNI discipline — Ponytail (always-on during implementation)

Before writing any code for a slice, stop at the first rung of this ladder
that holds. The ladder runs after you understand the problem — read the
slice spec and trace the real flow first, then climb.

1. **Does this need to exist at all?** The slice handsoff defines scope.
   If the handsoff does not require it, skip it.
2. **Already in this codebase?** Reuse the shared helper, trait, or
   pattern — do not re-implement what is a few files over.
3. **Laravel / PHP stdlib does it?** Eloquent relationships, collections,
   validation rules, middleware, jobs, events, policies — use the framework.
4. **Native Laravel feature covers it?** A DB constraint beats app-code
   validation. A route middleware beats per-controller logic. An attribute
   cast beats a mutator.
5. **Already-installed dependency solves it?** If Filament, Cashier,
   Sanctum, Horizon, or another installed package provides it, use it.
   Never add a new package for what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code the slice spec requires.

Rules:
- No abstractions not required by the slice spec.
- No boilerplate "for later" — the next slice scaffolds for itself.
- Deletion over addition when the slice requires a refactor.
- Mark deliberate simplifications: `// ponytail: <trade-off and upgrade path>`.
- Bug fix = root cause, not symptom. Grep every caller of the function
  you touch and fix it once at the shared path.

Never simplify away: input validation at trust boundaries, security measures,
error handling that prevents data loss, accessibility basics, or anything the
slice spec explicitly requires.

Full specification: `bundle/ponytail/skills/ponytail/SKILL.md`.

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
2. Run the pre-slice security scan.
3. Execute every bash block in section 12 (Implementation commands).
4. Run section 12.1's Laravel runtime commands yourself: migrations, seeders, cache clears, asset builds, queue/runtime restarts, and sandbox restart/probe when applicable. Never ask the user to run sandbox verification commands manually.
5. If the slice touches UI, read `docs/larv/03-design/visual-implementation-contract.md`, `brand-spec.md`, `ui-design.md`, and the chosen mockups before styling. Implement the app route to match the chosen mockup as the visual source of truth. Capture desktop and mobile screenshots under `docs/larv/08-implementation/screenshots/<slice-id>/`, compare them to the reference mockups, and fix drift before completion. Remaining visual differences require explicit documentation and user approval.
6. Run section 12.2's browser flow and mockup parity verification. Check every page, route, state, credential role, and planned flow touched by the slice against the PRD/product brief, `docs/larv` plan, approved decisions, and mockups. Approved mockups are the final UI contract; the implemented app must match them in layout, typography, colors, spacing, component styling, density, responsive behavior, and seeded-data feel. Fix functional or visual mismatches before completion.
7. If this slice touches Filament, admin features, roles, navigation, layout, auth, panels, or dashboards, verify the app still uses one shared layout/design system for all roles. Admin menus/actions/resources must be shown or hidden by authorization inside the same shell; do not create a separate visually different admin layout. Fix layout drift before completion.
8. Run the post-slice security scan.
9. Run section 10's Definition of Done checklist.
10. Write `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-<slice-id>.md` per section 16; never write implementation reports at the project root. Include browser flow verification, visual parity results, and security scan report paths.
11. Write or update the hard-required user testing guide at `docs/user-manual/testing/<slice-id>-<slice-slug>.md`.
12. Update `docs/user-manual/seed-data.md` with seeded records, test credentials for every role/persona needed for full-flow QA, permissions scopes, reset commands, and test-data removal notes.
13. Run section 13's tracker append snippet.
14. Run section 14's local-learnings append snippet if you discovered something.
15. Run section 15's STATE.yaml update snippet.
16. Apply the execution cadence above. Always print the public sandbox URL and exact guide paths when pausing for user review.

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
