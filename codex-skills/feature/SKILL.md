---
name: feature
description: Use when the user types /larv:feature or asks to add a feature to a larv-managed Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:feature

This is the Codex-compatible entry point for `/larv:feature`.

Read `commands/larv-feature.md`, then invoke the `larv-orchestrator` skill in feature mode with the user's feature slug or description.

Feature mode must not jump straight to code. It must run the Laravel Superpowers brainstorming and writing-plan sequence first:

1. Use `bundle/superpowers-laravel/skills/brainstorming/SKILL.md` for feature design.
2. Save the approved design to `docs/larv/features/<feature-slug>/design.md` and `docs/superpowers/specs/YYYY-MM-DD-<feature-slug>-design.md`.
3. Run the larv wrapper **Ponytail YAGNI audit** and save it to `docs/larv/features/<feature-slug>/yagni-audit.md`.
4. Use `bundle/superpowers-laravel/skills/writing-plans/SKILL.md` for implementation planning.
5. Save the plan to `docs/larv/features/<feature-slug>/plan.md` and `docs/superpowers/plans/YYYY-MM-DD-<feature-slug>-plan.md`.
6. Re-run the Ponytail YAGNI audit before handoff generation so unrequested scope, unnecessary packages, and avoidable multi-slice plans are removed before implementation routing.
7. Update `STATE.yaml.features`, tracker, handoff docs, AI starting-point files, doc-site, and review cadence before implementation.

## Caveman style controls

`larv:feature` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
