---
name: larv:feature
description: Add a feature to a managed Laravel app. Runs Laravel Superpowers brainstorming, design, planning, handoff, tracker/state updates, doc-site rebuild, and gated implementation.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

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
3. **Ponytail YAGNI audit** — run the larv wrapper audit against the approved design. Save it to `docs/larv/features/<feature-slug>/yagni-audit.md` with removed unrequested scope, reused existing screens/config/workflows, package/abstraction rejections, and whether the feature can be one small slice.
4. **Mini DDD interview** — only if the feature introduces new business words/invariants. Save to `docs/larv/features/<feature-slug>/domain-delta.md` and append relevant terms to `docs/larv/01-domain/`.
5. **Mini discuss** — only for new tech/package needs. Save to `docs/larv/features/<feature-slug>/package-delta.md` and append approved package choices to `docs/larv/00-discuss/library-decisions.md`.
6. **Design deltas** — save UI/API/data changes to `docs/larv/features/<feature-slug>/design-delta.md` and append durable deltas to existing design docs.
7. **Architecture delta** — create an ADR if a previous decision changes or a new package/boundary is introduced.
8. **Mini premortem** — save risks to `docs/larv/features/<feature-slug>/premortem.md`.
9. **Laravel Superpowers writing plan** — invoke bundled `bundle/superpowers-laravel/skills/writing-plans/SKILL.md` or `/superpowers-laravel:write-plan`. Save to both:
   - `docs/larv/features/<feature-slug>/plan.md`
   - `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`
10. **Ponytail YAGNI audit refresh** — re-run the audit against the written plan before handoff generation and update `yagni-audit.md` so only the minimum needed slices proceed.
11. **Mini slice plan** — append 1–N new slices to `docs/larv/06-implementation/elephant-carpaccio.md`, with `depends_on` linking to completed/current slices.
12. **Per-slice handsoff** generation via `larv-handoff`.
13. **Tracker + STATE updates** — append planning and slice entries; update `STATE.yaml.features[]` with `{ name, slug, status, design_path, yagni_audit_path, plan_path, slices, started_at, last_updated_at }`.
14. **User manual and docs index updates** — ensure `DOCS.md`, `docs/user-manual/README.md`, `docs/user-manual/seed-data.md`, and feature testing guide requirements under `docs/user-manual/testing/` are updated.
15. **Visual parity** — if the feature touches UI, update or extend `docs/larv/03-design/visual-implementation-contract.md`, map routes to exact chosen mockup files, and require desktop/mobile screenshot checks in the feature slice.
16. **Learning capture** — append useful findings to `docs/larv/local-learnings.md`.
17. **AI starting-point files** regenerated.
18. **Doc-site rebuild** so the feature design, plan, user manual, testing guides, and handoff are browsable.
19. **Routing-menu hard gate** before implementation. Ask venue and review cadence (`auto`, `manual-slice`, `manual-adr`, `manual-phase`).

`STATE.yaml.features` array gains an entry: `{ name, slug, started_at, last_updated_at, status, design_path, yagni_audit_path, plan_path, slices }`.

## Optional style controls for narrative and planning output

This command participates in the Caveman allowlist.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset to normal.
- For one-command overrides, parse `Caveman full`, `Caveman lite`, or `Caveman ultra`.
- If no one-shot override is present, use the persisted `/larv-caveman` value.

## What changes vs `/larv:full`

- The pre-flight phase is replaced with a delta check ("verify allocations are still valid").
- Phases 0a, 0, 1, 2 produce *deltas*, not full documents.
- Brainstorming and planning are mandatory and saved under `docs/larv/features/<feature-slug>/` plus the Superpowers specs/plans folders.
- Implementation tracker entries are tagged `type: feature`.
- Implementation honors `STATE.yaml.execution.review_mode`: auto completes all slices; manual modes pause by slice, ADR, or phase with URL and QA checklist.
- Every feature slice must update `docs/user-manual/testing/` and `docs/user-manual/seed-data.md`, even when implementation runs in `auto-all`.
- Every user-facing feature slice must preserve realistic seeders and seeded test credentials for every role/persona needed to test the full app flow through normal login.
- Every feature slice must write implementation reports under `docs/larv/08-implementation/reports/`, never at the project root.
- Every UI feature slice must preserve visual parity with `docs/larv/03-design/visual-implementation-contract.md` and the approved mockups. The production screen should look like the selected mockup unless a difference is explicitly approved.
- The AI must run required Laravel commands, restart/probe the sandbox when needed, and show the public test URL. Do not ask the user to run migrations, seeders, cache clears, build commands, queue/runtime restarts, or server restarts for sandbox review.

## Subagent return contract

Per `larv-orchestrator`'s contract.
