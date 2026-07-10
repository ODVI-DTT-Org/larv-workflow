---
name: feature-onboarding-helper
description: Use when the user types /larv-feature-onboarding-helper or asks to add onboarding, first-login setup, guided tours, role walkthroughs, or user-flow helper UX to a Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-feature-onboarding-helper

This is the Codex-compatible entry point for `/larv-feature-onboarding-helper`.

Read `commands/larv-feature-onboarding-helper.md`, then follow `skills/larv-feature-onboarding-helper/SKILL.md`.

Reference `examples/rfp`, `examples/imu`, and `examples/async` onboarding/user-flow examples before coding. Create a full user-flow inventory, implement the native Laravel onboarding/helper route or components, update docs, run required commands, restart/probe sandbox when needed, and show the public URL.

## Caveman style controls

`larv-feature-onboarding-helper` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
