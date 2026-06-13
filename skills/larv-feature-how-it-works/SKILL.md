---
name: larv-feature-how-it-works
description: Use when the user types /larv-feature-how-it-works or asks to add a How It Works, Guide, walkthrough, product tour, or user workflow page to a Laravel app.
---

# larv-feature-how-it-works

Add a production How It Works or Guide feature page to the current Laravel app. This skill is for an in-app route such as `/guide` or `/how-it-works`, not a docs-only artifact.

## Reference Sources

Read these local examples before designing or implementing:

- `examples/rfp/resources/views/livewire/guide.blade.php` - practical in-app `/guide` page with workflow overview strip, numbered timeline cards, CTAs, notes, alternate paths, and completion guidance.
- `examples/rfp/routes/web.php` - route and Livewire page registration pattern for `/guide`.
- `examples/interview/visual-workflow/` - visual workflow presentation examples with role lanes, demo/training/go-live framing, and interactive workflow cards.

Use the RFP guide when the app needs a simple operational guide. Use the interview visual workflow style when the app needs a presentation/training experience with role lanes or workflow graphs. Hybridize only when the app genuinely needs both.

## Workflow

1. Verify this is a Laravel app: check `artisan`, `composer.json`, `routes/web.php`, frontend stack, app shell/navigation, and whether Livewire, Blade, Filament, Inertia, Vue, or React is used.
2. Inspect the current app workflow from repository evidence:
   - `README.md`, `DOCS.md`, `docs/larv/`, `docs/user-manual/`
   - routes, controllers, Livewire pages, Filament resources, views, tests, seeders
   - existing navigation labels, role names, statuses, and primary CTAs
3. Decide the route:
   - Prefer `/guide` when the app already has account/help/documentation style navigation.
   - Use `/how-it-works` when the page is more product-tour or onboarding oriented.
   - If one route already exists, extend it instead of creating a duplicate.
4. Create or update `docs/larv/features/how-it-works/design.md` with:
   - selected route
   - reference source used (`examples/rfp`, `examples/interview`, or hybrid)
   - target roles/personas
   - workflow steps
   - CTAs and linked app routes
   - visual style notes
5. Create `docs/larv/features/how-it-works/role-flow-inventory.md` before implementation. It must list every detected role/persona, where the role starts, the screens/routes they use, the actions they perform, the data they create/update/review/approve/export, and the completion state for that role. If no roles are detected, explicitly record the repository evidence checked and treat the app as one primary user flow.
6. Implement the actual page in the app's native stack:
   - Livewire component plus Blade view when the app uses Livewire pages
   - Blade route view when the app is server-rendered
   - Filament page when the app is primarily Filament and the guide belongs inside the panel
   - Inertia/Vue/React page when the app uses that frontend stack
7. The page must include:
   - clear title: "How It Works" or app-specific equivalent
   - one-sentence promise explaining the workflow
   - ordered step flow from setup/start to completion for each detected role/persona
   - primary CTAs linking to real app routes
   - separate role sections, role tabs, role lanes, or role cards for every app role/persona
   - optional/alternate path sections where the workflow branches
   - "what to test next" or completion guidance
   - responsive layout
8. Add navigation entry in the existing shell/sidebar/header/help area. Keep the current app layout and theme.
9. If dark/light theme support exists, use semantic tokens/classes so the guide adapts to both modes. Do not add a new theme switcher unless requested.
10. Update `docs/user-manual/how-it-works.md` when `docs/user-manual/` exists.
11. Write `docs/larv/features/how-it-works/implementation-report.md` with files changed, route URL, commands run, screenshots/checks, and test instructions.
12. Run required commands yourself:
    - Laravel route/view/cache clears when needed
    - frontend build when assets changed
    - focused tests if available
    - sandbox restart/probe when the page affects the running app
13. Show the public VM URL for the new route, never `localhost` or `127.0.0.1`.

## Hard Blocks

- Do not create only markdown documentation.
- Do not invent generic workflow content. Ground the steps in current app routes, roles, statuses, seeders, tests, and docs.
- Do not omit role-specific workflows when roles, permissions, seeded users, teams, departments, or personas exist.
- Do not ask the user to run Laravel, npm, build, cache, migration, server restart, or sandbox commands manually.
- Do not change business logic, permissions, database schema, or existing workflows unless explicitly requested.
- Do not announce completion without a route path, public URL, `role-flow-inventory.md`, and implementation report path.
