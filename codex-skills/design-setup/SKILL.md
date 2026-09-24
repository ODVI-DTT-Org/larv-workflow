---
name: design-setup
description: Use when the user types /larv:design-setup or asks to check or install the Impeccable + Higgsfield design tools.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:design-setup

This is the Codex-compatible entry point for `/larv:design-setup`.

Read `commands/larv-design-setup.md` and follow it exactly.
