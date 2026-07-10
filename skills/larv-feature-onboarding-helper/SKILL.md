---
name: larv-feature-onboarding-helper
description: Use when the user types /larv-feature-onboarding-helper or asks to add onboarding, first-login setup, guided tours, role walkthroughs, or user-flow helper UX to a Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-feature-onboarding-helper

Add a production onboarding helper to the current Laravel app. The helper must capture the full user flow surface, not just display a welcome message.

## Reference Sources

Read these local examples before designing or implementing:

- `examples/rfp/app/Livewire/Onboarding.php` and `examples/rfp/resources/views/livewire/onboarding.blade.php` - first-login onboarding page with setup input, workflow explanation, setup CTAs, and completion redirect.
- `examples/rfp/app/Http/Middleware/RedirectToOnboarding.php` - first-time-user redirect guard that avoids trapping logout/onboarding routes.
- `examples/rfp/app/Domain/Onboarding/Actions/ProvisionTeamDefaults.php` - idempotent setup defaults before users enter the workflow.
- `examples/rfp/tests/Feature/Onboarding/FirstLoginOnboardingTest.php` - tests for completion flag and redirect behavior.
- `examples/imu/docs/superpowers/specs/2026-05-31-in-app-help-tour.md` and `examples/imu/docs/superpowers/plans/2026-05-31-in-app-help-tour.md` - in-app help/tour planning references.
- `examples/imu/docs/superpowers/plans/2026-05-30-pipeline-legend-and-onboarding.md` - onboarding/pipeline legend planning reference.
- `examples/imu/frontend-web-imu/docs/architecture/user-flows.md` and `examples/imu/frontend-mobile-imu/imu_flutter/docs/USER_FLOW_DOCUMENTATION.md` - user-flow documentation references.
- `examples/async` if present in the workspace - use any onboarding, visual workflow, or guided interview references found there.

## Required User-Flow Capture

Before implementation, create `docs/larv/features/onboarding-helper/user-flow-inventory.md` by reading:

- routes and navigation
- controllers, Livewire/Filament/Inertia/Vue/React pages
- roles, policies, permissions, seed users
- dashboards and first landing pages
- create/edit/review/approve/export/report flows
- empty states and first-use states
- docs, tests, existing guides, and presentation artifacts

The inventory must list each role/persona, start route, expected next action, completion state, and the onboarding/help content needed for that path.

## Feature Shape

Choose the smallest shape that covers all flows:

- First-login setup page when users need required defaults before using the app.
- Persistent help button or guided tour when users need contextual help across pages.
- Role-specific checklist when different roles have different paths.
- Guide page when the app needs a stable reference after first-use onboarding.

Use the app's native stack and existing layout. Do not create a separate design system.

## Workflow

1. Verify Laravel app and frontend stack.
2. Build `user-flow-inventory.md` from repository evidence.
3. Write `docs/larv/features/onboarding-helper/design.md` with chosen helper type, role paths, routes, data model, completion/progress rules, and test plan.
4. Implement the helper:
   - first-login route/middleware only if needed
   - progress/completion persistence when appropriate
   - idempotent default provisioning if setup data is required
   - contextual page steps/checklists/tours for all detected user flows
   - role-aware content and menu visibility
5. Add or update navigation/help entry so users can reopen guidance after onboarding.
6. Use semantic theme tokens/classes so dark/light modes keep working if the app has them.
7. Add tests for redirect/visibility/progress/completion and at least one role-specific flow.
8. Update `docs/user-manual/onboarding-helper.md` when `docs/user-manual/` exists.
9. Run required Laravel/frontend commands yourself.
10. Restart/probe sandbox if the app is running and print the public URL for the onboarding/helper entry point.
11. Write `docs/larv/features/onboarding-helper/implementation-report.md`.

## Hard Blocks

- Do not implement a generic welcome screen without inventorying all user flows.
- Do not block users in a redirect loop; onboarding and logout routes must remain reachable.
- Do not lose existing navigation, roles, policies, or completed workflows.
- Do not force first-login onboarding if the app only needs a reusable guide/tour.
- Do not ask the user to run Laravel, npm, migration, queue, build, cache, server restart, or sandbox commands manually.
- Do not announce completion without `user-flow-inventory.md`, route/helper entry point, public URL, and implementation report path.
