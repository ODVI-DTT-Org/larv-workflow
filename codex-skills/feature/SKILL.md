---
name: feature
description: Use when the user types /larv:feature or asks to add a feature to a larv-managed Laravel app.
---

# larv:feature

This is the Codex-compatible entry point for `/larv:feature`.

Read `commands/larv-feature.md`, then invoke the `larv-orchestrator` skill in feature mode with the user's feature slug or description.

Feature mode must not jump straight to code. It must run the Laravel Superpowers brainstorming and writing-plan sequence first:

1. Use `bundle/superpowers-laravel/skills/brainstorming/SKILL.md` for feature design.
2. Save the approved design to `docs/larv/features/<feature-slug>/design.md` and `docs/superpowers/specs/YYYY-MM-DD-<feature-slug>-design.md`.
3. Use `bundle/superpowers-laravel/skills/writing-plans/SKILL.md` for implementation planning.
4. Save the plan to `docs/larv/features/<feature-slug>/plan.md` and `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`.
5. Update `STATE.yaml.features`, tracker, handoff docs, AI starting-point files, doc-site, and review cadence before implementation.
