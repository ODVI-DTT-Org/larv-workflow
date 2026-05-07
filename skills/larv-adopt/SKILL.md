---
name: larv-adopt
description: Adoption controller for /larv:adopt. Read-only on user code. Detects existing Laravel packages and produces docs/larv/ retroactively.
---

# larv-adopt

Bring an existing Laravel app under larv management without changing application code.

## On entry

1. Refuse if `docs/larv/STATE.yaml` already exists.
2. Stay read-only outside `docs/larv/`.
3. Inspect the existing Laravel app and document what is already true.
4. Initialize STATE.yaml with `mode: adopted`, `phase.last_completed: A9`.

## Package detection

Read:

- `composer.json`
- `package.json`
- `config/*.php`
- `routes/*.php`
- `app/Providers/*.php`
- `app/Filament/**`
- `app/Nova/**`
- `app/Jobs/**`
- `app/Events/**`
- `app/Listeners/**`
- `app/Models/**`
- `database/migrations/**`

Detect and document:

- Filament or Nova admin surface
- Sanctum, Fortify, Passport, Socialite auth
- Horizon, Redis, queues, scheduled commands
- Reverb or broadcasting
- Pulse and Telescope
- Octane
- Cashier Stripe/Paddle
- tenancy packages and tenant resolution
- Scout with Meilisearch or Typesense
- storage/upload packages
- mail/notification providers
- Pest, Pint, Larastan, Rector, Playwright

## Required outputs

- `docs/larv/adopt/survey.md`
- `docs/larv/adopt/package-detection.md`
- `docs/larv/adopt/routes-map.md`
- `docs/larv/adopt/data-model.md`
- `docs/larv/adopt/test-reality.md`
- `docs/larv/adopt/risk-register.md`
- `docs/larv/00-discuss/library-decisions.md` inferred from installed packages
- `docs/larv/02-architecture/package-integration-matrix.md`
- `docs/larv/04-test-strategy/package-test-matrix.md`
- `docs/larv/STATE.yaml`

## Read-only guarantee

This skill must not modify files outside `docs/larv/`. Any opt-in code modification is gated behind explicit flags such as `--migrate-to-larv-conventions`; those flags are intentionally not implemented here.
