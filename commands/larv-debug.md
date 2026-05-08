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
- The AI must implement the fix, run the regression tests, run required Laravel commands, restart/probe the sandbox when needed, and show the public URL where the user can verify the bug is fixed. Do not ask the user to run migrations, seeders, cache clears, build commands, queue/runtime restarts, or server restarts for sandbox review.

## Subagent return contract

Per `larv-orchestrator`'s contract.
