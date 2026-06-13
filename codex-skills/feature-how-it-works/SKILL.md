---
name: feature-how-it-works
description: Use when the user types /larv-feature-how-it-works or asks to add a How It Works, Guide, walkthrough, product tour, or user workflow page to a Laravel app.
---

# larv-feature-how-it-works

This is the Codex-compatible entry point for `/larv-feature-how-it-works`.

Read `commands/larv-feature-how-it-works.md`, then follow `skills/larv-feature-how-it-works/SKILL.md`.

Reference the local examples before implementing:

- `examples/rfp/resources/views/livewire/guide.blade.php`
- `examples/rfp/routes/web.php`
- `examples/interview/visual-workflow/`

Implement a real app route such as `/guide` or `/how-it-works`. The page must include How It Works sections for every detected role/persona in the app, backed by `docs/larv/features/how-it-works/role-flow-inventory.md`. Update navigation, run required Laravel/frontend commands, restart/probe the sandbox when needed, and show the public URL.
