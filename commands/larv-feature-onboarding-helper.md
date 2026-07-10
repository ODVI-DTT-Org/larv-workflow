---
name: larv-feature-onboarding-helper
description: Add an onboarding helper feature that captures all user flows in the current Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument: optional focus such as `first-login`, `role-tour`, `checklist`, `admin`, or `all flows`.

Invoke the `larv-feature-onboarding-helper` skill.

## Contract

- Add a real onboarding helper feature, not only docs or a mockup.
- Reference these local implementations first:
  - `examples/rfp/app/Livewire/Onboarding.php`
  - `examples/rfp/resources/views/livewire/onboarding.blade.php`
  - `examples/rfp/app/Http/Middleware/RedirectToOnboarding.php`
  - `examples/rfp/app/Domain/Onboarding/Actions/ProvisionTeamDefaults.php`
  - `examples/rfp/tests/Feature/Onboarding/FirstLoginOnboardingTest.php`
  - `examples/imu/docs/superpowers/specs/2026-05-31-in-app-help-tour.md`
  - `examples/imu/docs/superpowers/plans/2026-05-30-pipeline-legend-and-onboarding.md`
  - `examples/imu/frontend-web-imu/docs/architecture/user-flows.md`
  - `examples/imu/frontend-mobile-imu/imu_flutter/docs/USER_FLOW_DOCUMENTATION.md`
- The helper must capture all user flows from repository evidence: roles, routes, dashboards, create/edit/review/approve/export flows, first-login setup, empty states, and completion states.
- Include first-login or first-use guidance when the app has authenticated users.
- Include role-specific paths when roles/permissions exist.
- Persist onboarding completion/progress when appropriate.
- Run required Laravel/frontend commands, restart/probe the sandbox if needed, and show the public URL.

## Required Artifacts

- `docs/larv/features/onboarding-helper/user-flow-inventory.md`
- `docs/larv/features/onboarding-helper/design.md`
- `docs/larv/features/onboarding-helper/implementation-report.md`
- `docs/user-manual/onboarding-helper.md` when `docs/user-manual/` exists.

## Optional style controls for narrative output

This command participates in the Caveman allowlist.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset to normal.
- For a one-command override, apply `Caveman full`, `Caveman lite`, or `Caveman ultra`.
