---
name: redesign-impeccable-higgsfield
description: Use when the user types /larv:redesign-impeccable-higgsfield or asks to redesign a Laravel frontend with Impeccable directions and Higgsfield comps.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:redesign-impeccable-higgsfield

This is the Codex-compatible entry point for `/larv:redesign-impeccable-higgsfield`.

Read `commands/larv-redesign-impeccable-higgsfield.md`, then follow `skills/larv-redesign-impeccable-higgsfield/SKILL.md`.

The command must redesign the actual Laravel frontend, not only serve a board. Run `scripts/design-setup.sh check` first, present the options on the public board URL, implement the user's pick, restart/probe the sandbox, and show the public URL.
