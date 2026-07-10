---
name: larv-feature-how-it-works
description: Add a How It Works or Guide page feature to the current Laravel app using the bundled reference examples.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument: optional route or focus, for example `route=/guide`, `route=/how-it-works`, `onboarding`, `admin`, or `customer flow`.

Invoke the `larv-feature-how-it-works` skill.

## Contract

- Add a real in-app feature page, not only docs or a mockup.
- Use these local references before designing:
  - `examples/rfp/resources/views/livewire/guide.blade.php` for a practical `/guide` page with numbered step cards, CTAs, notes, and workflow overview strip.
  - `examples/rfp/routes/web.php` for the route pattern.
  - `examples/interview/visual-workflow/` for visual workflow, role lanes, demo/training/go-live page patterns.
- Default route: `/guide` when the app already has user/account/help style navigation; otherwise `/how-it-works`.
- The page must explain the actual current app workflow from setup to completion, using routes, roles, seed data, docs, tests, and existing UI labels from the repository.
- The page must include a How It Works section for each detected role/persona in the app. If roles or permission groups exist, every role gets its own ordered workflow with start route, primary actions, completion state, and CTAs. If no roles exist, include the primary user workflow and explicitly record that no role split was detected.
- Add navigation entry where the app keeps help/guide/productivity pages.
- Preserve backend behavior. Do not change existing workflows except to link to the new guide page.
- Run required Laravel/frontend commands, restart/probe the sandbox if needed, and show the public URL.

## Required Artifacts

- `docs/larv/features/how-it-works/design.md`
- `docs/larv/features/how-it-works/role-flow-inventory.md`
- `docs/larv/features/how-it-works/implementation-report.md`
- `docs/user-manual/how-it-works.md` when `docs/user-manual/` exists.

## Optional style controls for narrative output

This command participates in the Caveman allowlist.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset to normal.
- For a one-command override, apply `Caveman full`, `Caveman lite`, or `Caveman ultra`.
