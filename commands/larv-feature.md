---
name: larv:feature
description: Add a feature to a managed Laravel app. Runs Laravel Superpowers brainstorming, design, planning, handoff, tracker/state updates, doc-site rebuild, and gated implementation.
---

Argument: `<feature-name>` — short slug for the feature.

Invoke the `larv-orchestrator` skill in feature mode with the provided name. Feature mode is a full mini-flow, not a direct coding command.

## Preconditions

- `docs/larv/STATE.yaml` must exist (project must be managed).
- Working tree must be clean outside of `docs/` and `adr/`.

## Mini-flow phases (each gated like `/larv:full`)

1. **Feature bootstrap** — create `docs/larv/features/<feature-slug>/`, append a `STATE.yaml.features[]` entry with `status: brainstorming`, and add a tracker entry with `type: feature_planning`.
2. **Laravel Superpowers brainstorming** — invoke bundled `bundle/superpowers-laravel/skills/brainstorming/SKILL.md` or `/superpowers-laravel:brainstorm`. No implementation is allowed until the user approves the design. Save the approved output to both:
   - `docs/larv/features/<feature-slug>/design.md`
   - `docs/superpowers/specs/YYYY-MM-DD-<feature-slug>-design.md`
3. **Mini DDD interview** — only if the feature introduces new business words/invariants. Save to `docs/larv/features/<feature-slug>/domain-delta.md` and append relevant terms to `docs/larv/01-domain/`.
4. **Mini discuss** — only for new tech/package needs. Save to `docs/larv/features/<feature-slug>/package-delta.md` and append approved package choices to `docs/larv/00-discuss/library-decisions.md`.
5. **Design deltas** — save UI/API/data changes to `docs/larv/features/<feature-slug>/design-delta.md` and append durable deltas to existing design docs.
6. **Architecture delta** — create an ADR if a previous decision changes or a new package/boundary is introduced.
7. **Mini premortem** — save risks to `docs/larv/features/<feature-slug>/premortem.md`.
8. **Laravel Superpowers writing plan** — invoke bundled `bundle/superpowers-laravel/skills/writing-plans/SKILL.md` or `/superpowers-laravel:write-plan`. Save to both:
   - `docs/larv/features/<feature-slug>/plan.md`
   - `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`
9. **Mini slice plan** — append 1–N new slices to `docs/larv/06-implementation/elephant-carpaccio.md`, with `depends_on` linking to completed/current slices.
10. **Per-slice handsoff** generation via `larv-handoff`.
11. **Tracker + STATE updates** — append planning and slice entries; update `STATE.yaml.features[]` with `{ name, slug, status, design_path, plan_path, slices, started_at, last_updated_at }`.
12. **User manual and docs index updates** — ensure `DOCS.md`, `docs/user-manual/README.md`, `docs/user-manual/seed-data.md`, and feature testing guide requirements under `docs/user-manual/testing/` are updated.
13. **Visual parity** — if the feature touches UI, update or extend `docs/larv/03-design/visual-implementation-contract.md`, map routes to exact chosen mockup files, and require desktop/mobile screenshot checks in the feature slice.
13. **Learning capture** — append useful findings to `docs/larv/local-learnings.md`.
14. **AI starting-point files** regenerated.
15. **Doc-site rebuild** so the feature design, plan, user manual, testing guides, and handoff are browsable.
16. **Routing-menu hard gate** before implementation. Ask venue and review cadence (`auto`, `manual-slice`, `manual-adr`, `manual-phase`).

`STATE.yaml.features` array gains an entry: `{ name, slug, started_at, last_updated_at, status, design_path, plan_path, slices }`.

## What changes vs `/larv:full`

- The pre-flight phase is replaced with a delta check ("verify allocations are still valid").
- Phases 0a, 0, 1, 2 produce *deltas*, not full documents.
- Brainstorming and planning are mandatory and saved under `docs/larv/features/<feature-slug>/` plus the Superpowers specs/plans folders.
- Implementation tracker entries are tagged `type: feature`.
- Implementation honors `STATE.yaml.execution.review_mode`: auto completes all slices; manual modes pause by slice, ADR, or phase with URL and QA checklist.
- Every feature slice must update `docs/user-manual/testing/` and `docs/user-manual/seed-data.md`, even when implementation runs in `auto-all`.
- Every user-facing feature slice must preserve demo seeders, `DEMO_MODE=true` sandbox access, and the navbar User Switcher; production must use `DEMO_MODE=false`.
- Every feature slice must write implementation reports under `docs/larv/08-implementation/reports/`, never at the project root.
- Every UI feature slice must preserve visual parity with `docs/larv/03-design/visual-implementation-contract.md` and the approved mockups. The production screen should look like the selected mockup unless a difference is explicitly approved.

## Subagent return contract

Per `larv-orchestrator`'s contract.
