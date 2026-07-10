---
name: feature-how-it-works
description: Use when the user types /larv-feature-how-it-works or asks to add a How It Works, Guide, walkthrough, product tour, or user workflow page to a Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-feature-how-it-works

This is the Codex-compatible entry point for `/larv-feature-how-it-works`.

Read `commands/larv-feature-how-it-works.md`, then follow `skills/larv-feature-how-it-works/SKILL.md`.

Reference the local examples before implementing:

- `examples/rfp/resources/views/livewire/guide.blade.php`
- `examples/rfp/routes/web.php`
- `examples/interview/visual-workflow/`

Implement a real app route such as `/guide` or `/how-it-works`. The page must include How It Works sections for every detected role/persona in the app, backed by `docs/larv/features/how-it-works/role-flow-inventory.md`. Update navigation, run required Laravel/frontend commands, restart/probe the sandbox when needed, and show the public URL.

## Caveman style controls

`larv-feature-how-it-works` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the request.
