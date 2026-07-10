---
name: larv:debug
description: Fix a bug in a managed Laravel app. Mini-flow with full discipline parity — gates, handsoff, tracker, AI starting-points refresh.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

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

## Optional style controls for narrative and planning output

This command participates in the Caveman allowlist.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset to normal.
- For one-command overrides, apply `Caveman full`, `Caveman lite`, or `Caveman ultra`.
- If no one-shot override is present, use the persisted `/larv-caveman` value.

## What changes vs `/larv:feature`

- No design phase; reuse existing UI/brand.
- Test-strategy phase is replaced with a single regression-test requirement in the slice's DoD.
- The AI must implement the fix, run the regression tests, run required Laravel commands, restart/probe the sandbox when needed, and show the public URL where the user can verify the bug is fixed. Do not ask the user to run migrations, seeders, cache clears, build commands, queue/runtime restarts, or server restarts for sandbox review.

## Subagent return contract

Per `larv-orchestrator`'s contract.
