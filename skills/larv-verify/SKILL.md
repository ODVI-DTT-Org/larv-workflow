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

## Required output

Write `docs/larv/09-verification/final-report.md` with:

- command run
- pass/fail result
- relevant output summary
- sandbox URL checked
- unresolved failures, if any
- production readiness recommendation

## Completion gate

Do not return `status: complete` if Pint, Pest, Larastan, asset build, migration status, or sandbox smoke fails.

## Subagent return contract

```yaml
status: complete | failed
files_written:
  - docs/larv/09-verification/final-report.md
errors_unresolved: []
plugin_improvement_notes: (none)
```
