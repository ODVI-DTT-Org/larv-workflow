---
name: larv:feature
description: Add a feature to a managed Laravel app. Mini-flow with full discipline parity — gates, handsoff, tracker, AI starting-points refresh.
---

Argument: `<feature-name>` — short slug for the feature.

Invoke the `larv-orchestrator` skill in feature mode with the provided name.

## Preconditions

- `docs/larv/STATE.yaml` must exist (project must be managed).
- Working tree must be clean outside of `docs/` and `adr/`.

## Mini-flow phases (each gated like `/larv:full`)

1. **Mini DDD interview** — only if the feature introduces new business words/invariants. Output appends to `docs/larv/ddd-interview/`. (Layer 2; in MVP this step is a single recommendation prompt: "any new business invariants? if yes, list them; if no, type `none`.")
2. **Mini discuss** — only for new tech needs. Output appends to `docs/larv/00-discuss/library-decisions.md`.
3. **Architecture delta** — new ADR if a previous decision changes.
4. **Data / API / UI deltas** — appended to existing design docs.
5. **Mini premortem** — 1–2 questions.
6. **Mini plan** — 1–N new slices with `depends_on` linking to existing slices, written to `docs/larv/06-implementation/elephant-carpaccio.md`.
7. **Per-slice handsoff** generation via `larv-handoff`.
8. **Tracker entries** appended (one per slice).
9. **AI starting-point files** regenerated.
10. **Doc-site rebuild** (Layer 2).
11. **Routing-menu hard gate** before implementation.

`STATE.yaml.features` array gains an entry: `{ name, started_at, slices: [...], status }`.

## What changes vs `/larv:full`

- The pre-flight phase is replaced with a delta check ("verify allocations are still valid").
- Phases 0a, 0, 1, 2 produce *deltas*, not full documents.
- Implementation tracker entries are tagged `type: feature`.

## Subagent return contract

Per `larv-orchestrator`'s contract.
