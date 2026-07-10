---
name: brainstorm
description: Use when the user types /larv:brainstorm or asks to run larv's standalone brainstorm phase.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:brainstorm

This is the Codex-compatible entry point for `/larv:brainstorm`.

Read `commands/larv-brainstorm.md`, then invoke the `larv-discuss` skill from `<larv-plugin-root>/skills/larv-discuss/SKILL.md` in standalone exploratory mode.

## Caveman style controls

`larv:brainstorm` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
