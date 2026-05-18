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
- `docs/larv/01-domain/`
- `docs/larv/03-design/visual-implementation-contract.md`
- `docs/larv/03-design/mockups/`
- `docs/larv/04-test-strategy/acceptance-criteria.md`
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
5. Save final verification screenshots under `docs/larv/09-verification/screenshots/`.
6. Fix all mismatches before returning `status: complete`. If a mismatch is intentionally accepted, it must be explicitly documented as a user-approved deviation with reason and evidence.

If Playwright is available, encode the critical end-to-end flows and role paths as Playwright tests and run them. If Playwright is not available, document the manual/browser automation method used.

## Required output

Write `docs/larv/09-verification/final-report.md` with:

- command run
- pass/fail result
- relevant output summary
- sandbox URL checked
- browser pages and flows verified against the approved plan
- seeded credentials/roles used during verification
- mockup parity result and screenshot paths
- any approved deviations with reasons
- unresolved failures, if any
- production readiness recommendation

## Completion gate

Do not return `status: complete` if Pint, Pest, Larastan, asset build, migration status, or sandbox smoke fails.

Do not return `status: complete` if any planned page/flow is untested, any role credential path is unchecked, any approved mockup route is unmatched, any screen visibly drifts from the chosen mockup, or any implemented behavior contradicts approved decisions from `/larv:full`, unless the final report documents an explicit user-approved deviation. Approved mockups are the final UI contract: after implementation, the app must match the approved mockups in layout, typography, color, spacing, component styling, density, responsive behavior, and seeded-data feel.

## Subagent return contract

```yaml
status: complete | failed
files_written:
  - docs/larv/09-verification/final-report.md
errors_unresolved: []
plugin_improvement_notes: (none)
```
