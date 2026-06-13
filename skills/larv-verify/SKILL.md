---
name: larv-verify
description: Phase 9 - final verification across Pint, Pest, Larastan, asset build, migrations, and sandbox smoke before production deploy guidance.
---

# larv-verify

Run the final verification pass after implementation and before production deployment. Use the bundled `bundle/masterplan/skills/masterplan-verification/SKILL.md` as the verification discipline reference, but execute the concrete Laravel checks below.

## Inputs

- `docs/larv/STATE.yaml`
- `docs/larv/07-runtime/sandbox-url.txt`
- `docs/larv/07-runtime/sandbox-runbook.md`
- `docs/larv/implementation-tracker.yaml`
- `docs/larv/00-discuss/`
- original PRD or product requirements supplied by the user, if present in the repo or copied into `docs/larv/00-discuss/`
- `docs/larv/01-domain/`
- `docs/larv/02-architecture/`
- `docs/larv/03-design/visual-implementation-contract.md`
- `docs/larv/03-design/mockups/`
- `docs/larv/04-test-strategy/acceptance-criteria.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`
- `docs/user-manual/testing/`
- `docs/larv/08-implementation/reports/`
- all implemented application code

## Required checks

Run from the project root:

```bash
composer install --no-interaction --prefer-dist
vendor/bin/pint --test
vendor/bin/pest
vendor/bin/phpstan analyse
npm install
npm run build
php artisan migrate:status
```

Then smoke-test the sandbox URL:

```bash
sandbox_url="$(cat docs/larv/07-runtime/sandbox-url.txt)"
curl -fsS "$sandbox_url" >/dev/null
curl -fsS "${sandbox_url%/}/health" >/dev/null || true
```

If Playwright tests exist, run them:

```bash
if [ -f package.json ] && grep -q playwright package.json; then
    npx playwright test
fi
```

## Source-code and plan parity verification

After automated checks pass, audit the implemented source code against the user's approved product intent. This is a hard "find and fix" gate, not a report-only review.

Read:

- the original PRD or copied product requirements, if present
- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/00-discuss/library-decisions.md`
- `docs/larv/01-domain/`
- `docs/larv/02-architecture/`
- `docs/larv/03-design/`
- `docs/larv/04-test-strategy/acceptance-criteria.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`
- `docs/larv/implementation-tracker.yaml`
- all implementation reports
- all application source code, routes, controllers/actions, models, policies, requests, jobs/listeners, views/components, Filament resources/panels when present, migrations, seeders, tests, and frontend assets

Required audit:

1. Build a requirements traceability matrix in `docs/larv/09-verification/final-report.md` with columns: source requirement, planned artifact, implemented code path, test/browser evidence, result, fix path if failed.
2. Verify every PRD feature, invariant, role, permission, workflow, dashboard, report, data field, state transition, onboarding gate, and integration selected in `docs/larv` has corresponding source code, tests or browser evidence, and seeded data where applicable.
3. Verify implemented source code does not contradict `docs/larv` decisions, ADRs, package decisions, the domain vocabulary, or the slice plan.
4. Verify no planned feature is only documented without implementation.
5. If a gap, contradiction, missing feature, weak seed, missing test, broken route, or incomplete workflow is found, fix the application code, data, tests, docs, or plan as appropriate, rerun verification, and record the fix. Do not leave a known gap as "future work" unless the user explicitly approves the scope cut.

## Single-layout and Filament verification

The app must use one coherent visual shell/layout across roles. Role differences should be expressed through permissions and menu visibility, not separate visual systems.

If Filament is used:

- Use one shared app layout/design language for all roles and users.
- Prefer the policy-app pattern: admin routes live inside the same main app shell as employee/user routes, using the same layout component, sidebar/header, CSS tokens, spacing, and mockup-derived components.
- Do not create a separate admin layout that looks different from the main app or index route layout.
- Do not split users into unrelated "admin app" and "user app" layouts unless the PRD explicitly requires separate products.
- Admin-only resources, widgets, actions, and menu items must be shown/hidden through policies, gates, roles, navigation visibility, and route authorization inside the same visual shell.
- In Blade/Livewire apps, admin views should extend the same main layout (for example `layouts.app`) and show admin navigation groups conditionally (for example `@if(auth()->user()->isAdmin())`) rather than using a separate admin Blade layout.
- Filament panels/resources must be themed and structured to match `brand-spec.md`, `ui-design.md`, `visual-implementation-contract.md`, and the approved mockups.

Verification must inspect routes, layouts, Blade/Inertia/Livewire components, Filament panel providers/resources, navigation definitions, middleware, and screenshots for every seeded role. Confirm admin routes use the same shell as the main route and that only menus/actions differ by authorization. If any role lands in a different-looking admin shell or separate layout, fix it before `status: complete`.

## Browser flow and mockup parity verification

After automated checks and sandbox smoke pass, verify the completed app against the approved user decisions and mockups. This is a hard gate.

Read:

- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/00-discuss/library-decisions.md`
- `docs/larv/01-domain/`
- `docs/larv/03-design/design-decision.md`
- `docs/larv/03-design/brand-spec.md`
- `docs/larv/03-design/ui-design.md`
- `docs/larv/03-design/visual-implementation-contract.md`
- `docs/larv/04-test-strategy/acceptance-criteria.md`
- all `docs/user-manual/testing/*.md`
- all `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-*.md`

Required final checks:

1. Visit every planned user-facing page, route, modal, table, dashboard, detail view, form, empty/error state, and role-specific view listed in the visual contract, acceptance criteria, and testing guides.
2. Sign in with every seeded credential required for the app's full flow and role/permission coverage.
3. Execute every planned flow from the product/domain/test docs, including happy paths, denied paths, status transitions, approvals, create/edit/delete actions, and cross-role handoffs.
4. Compare implemented UI against approved mockups route by route. Verify layout, typography, colors, spacing, density, icons, forms, tables, states, and responsive behavior.
5. Verify every role sees the same application shell/layout and that admin capabilities appear only as authorized menu items/actions inside that shell.
6. Save final verification screenshots under `docs/larv/09-verification/screenshots/`.
7. Fix all mismatches before returning `status: complete`. If a mismatch is intentionally accepted, it must be explicitly documented as a user-approved deviation with reason and evidence.

If Playwright is available, encode the critical end-to-end flows and role paths as Playwright tests and run them. If Playwright is not available, document the manual/browser automation method used.

## Required output

Write `docs/larv/09-verification/final-report.md` with:

- command run
- pass/fail result
- relevant output summary
- sandbox URL checked
- requirements traceability matrix comparing PRD/product requirements, docs/larv plan, implemented source code, and evidence
- browser pages and flows verified against the approved plan
- seeded credentials/roles used during verification
- mockup parity result and screenshot paths
- single-layout/Filament result, including role navigation/menu visibility evidence
- any approved deviations with reasons
- unresolved failures, if any
- production readiness recommendation

## Completion gate

Do not return `status: complete` if Pint, Pest, Larastan, asset build, migration status, or sandbox smoke fails.

Do not return `status: complete` if any PRD requirement, `docs/larv` decision, domain invariant, package decision, planned slice, planned page/flow, or acceptance criterion is missing from source code or unverified in tests/browser evidence.

Do not return `status: complete` if any planned page/flow is untested, any role credential path is unchecked, any approved mockup route is unmatched, any screen visibly drifts from the chosen mockup, or any implemented behavior contradicts approved decisions from `/larv:full`, unless the final report documents an explicit user-approved deviation. Approved mockups are the final UI contract: after implementation, the app must match the approved mockups in layout, typography, color, spacing, component styling, density, responsive behavior, and seeded-data feel.

Do not return `status: complete` if the app uses separate role-specific layouts or a visually different Filament/admin shell. All roles must share one app layout/design system; admin features are controlled by menu/action visibility and authorization.

## Subagent return contract

```yaml
status: complete | failed
files_written:
  - docs/larv/09-verification/final-report.md
errors_unresolved: []
plugin_improvement_notes: (none)
```
