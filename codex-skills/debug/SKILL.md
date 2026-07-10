---
name: debug
description: Use when the user types /larv:debug or asks to debug a larv-managed Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:debug

This is the Codex-compatible entry point for `/larv:debug`.

Read `commands/larv-debug.md`, then invoke the `larv-orchestrator` skill in debug mode with the user's issue slug or description.

## Caveman style controls

`larv:debug` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
