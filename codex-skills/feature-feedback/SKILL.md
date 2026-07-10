---
name: feature-feedback
description: Use when the user types /larv-feature-feedback or asks to add in-app feedback, bug report, idea report, screenshot feedback, or developer feedback to a Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-feature-feedback

This is the Codex-compatible entry point for `/larv-feature-feedback`.

Read `commands/larv-feature-feedback.md`, then follow `skills/larv-feature-feedback/SKILL.md`.

Reference `examples/rfp` and `examples/imu` feedback implementations before coding. Use Resend API through Laravel mail config, persist feedback before email delivery, add the in-app widget, add admin triage, run required commands, restart/probe sandbox when needed, and show the public URL.

## Caveman style controls

`larv-feature-feedback` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
