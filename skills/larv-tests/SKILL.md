---
name: larv-tests
description: Phase 4 - Pest, Playwright, package-specific test matrix, and acceptance criteria for Laravel apps.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-tests

Define the test strategy and make every selected Laravel package testable. Use the bundled references:

- `bundle/masterplan/skills/masterplan-test-strategy/SKILL.md`
- `bundle/superpowers-laravel/skills/tdd-with-pest/SKILL.md`
- `bundle/superpowers-laravel/skills/e2e-playwright/SKILL.md`
- `bundle/superpowers-laravel/skills/controller-tests/SKILL.md`
- `bundle/superpowers-laravel/skills/policies-and-authorization/SKILL.md`

## Inputs

- `docs/larv/00-discuss/library-decisions.md`
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/package-integration-matrix.md`
- `docs/larv/03-design/*.md`

## What you do

1. Write Pest unit/feature strategy.
2. Write Playwright browser-flow strategy for user-visible flows.
3. Write package-specific test obligations at `docs/larv/04-test-strategy/package-test-matrix.md`.
4. Write acceptance criteria mapped to implementation slices.

## Package test matrix

Require package-specific coverage when selected:

- **Filament/Nova**: resource authorization, form validation, table filters, actions, relation managers.
- **Sanctum/Fortify/Passport/Socialite**: auth flows, token abilities/scopes, throttling, password reset, provider callback fakes.
- **Horizon/queues**: job dispatch, retry/backoff behavior, failed job handling, idempotency.
- **Reverb/broadcasting**: channel authorization and event broadcasting.
- **Pulse/Telescope**: dashboard access policy and environment restrictions.
- **Octane**: smoke test under long-lived process if enabled.
- **Cashier Stripe/Paddle**: webhook signature validation, subscription state transitions, invoice/payment behavior.
- **tenancy**: tenant isolation, cross-tenant authorization denial, tenant migrations.
- **Scout/search**: indexing, search filters, queued reindex jobs.
- **Storage/uploads**: validation, private/public URL behavior, cleanup.
- **Mail/notifications**: notification fakes and rendered content checks.

## Required outputs

- `docs/larv/04-test-strategy/pest-strategy.md`
- `docs/larv/04-test-strategy/playwright-flows.md`
- `docs/larv/04-test-strategy/package-test-matrix.md`
- `docs/larv/04-test-strategy/coverage-targets.md`
- `docs/larv/04-test-strategy/acceptance-criteria.md`

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/04-test-strategy/pest-strategy.md
  - docs/larv/04-test-strategy/playwright-flows.md
  - docs/larv/04-test-strategy/package-test-matrix.md
  - docs/larv/04-test-strategy/coverage-targets.md
  - docs/larv/04-test-strategy/acceptance-criteria.md
state_updates: {}
plugin_improvement_notes: (none)
```
