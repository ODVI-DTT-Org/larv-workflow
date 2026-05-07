---
name: larv-deploy
description: Phase 10 - production deployment guidance and verification. Defaults to Laravel Cloud hosting and Namecheap DNS; deploy instructions are also generated into docs/Handsoff/production-deploy.md for external AI handoff.
---

# larv-deploy

Prepare and guide production deployment. If implementation was handed off to another AI, that AI should follow `docs/Handsoff/production-deploy.md`; this skill mirrors the same contract for Claude Code execution.

## Inputs

- `docs/Handsoff/production-deploy.md`
- `docs/Handsoff/env-guide.md`
- `docs/Handsoff/operations-guide.md`
- `docs/larv/09-verification/final-report.md`
- `docs/larv/STATE.yaml`

## Ask the user

Ask the user these questions before any production action:

```text
Recommendation: Laravel Cloud + Namecheap
Why: That is the larv default and gives the shortest managed Laravel production path.
Tradeoffs: Other hosts or registrars need a custom deployment runbook.

1. Are we deploying to Laravel Cloud? Default: yes.
2. Are you using Namecheap for DNS? Default: yes.
3. What production domain should point to this app?
4. What Laravel Cloud organization, project, and environment should be used?
5. Should Laravel Cloud create/attach the production database?
6. Which mail provider and sender address should production use?
7. Are queue workers, scheduler, Horizon, Reverb, or storage disks needed?
8. Which automation choice should we use: guide-only, Laravel Cloud CLI automation, Laravel Cloud API automation, or mixed?
9. Should DNS stay guide-only, or should we use Namecheap API automation?
```

Record answers in `docs/larv/10-deploy/production-answers.md`.

## What you do

1. Read `docs/larv/09-verification/final-report.md`; stop if it does not recommend production readiness.
2. Walk the user through `docs/Handsoff/production-deploy.md`.
3. Build an env-var checklist from `docs/Handsoff/env-guide.md`.
4. Ask the user to fill Laravel Cloud secrets in Laravel Cloud, not in git.
5. Ask for Namecheap DNS values or Laravel Cloud custom-domain target.
6. After deploy, smoke-test the production URL and configured health path.
7. Write `docs/larv/10-deploy/laravel-cloud.md`.

## Laravel Cloud automation mode

Default is `guide-only` unless the user explicitly requests automation and confirms the Laravel Cloud CLI/API credentials are available.

Supported automation choices:

- `guide-only`: no automated production changes; walk the user through `docs/Handsoff/production-deploy.md`.
- `Laravel Cloud CLI automation`: user authenticates locally with `cloud auth` or `cloud auth:token --add`; then print and run approved `cloud` commands.
- `Laravel Cloud API automation`: user exports `LARAVEL_CLOUD_API_TOKEN`; use API calls with `Authorization: Bearer $LARAVEL_CLOUD_API_TOKEN`.
- `mixed`: automate Laravel Cloud deploy but keep DNS guide-only.

If automation mode is requested:

1. Check whether a Laravel Cloud CLI is installed or whether the user has provided an approved API workflow.
2. Print every production-affecting command before running it.
3. Never read or write raw secrets into git-tracked files.
4. Fall back to `guide-only` if CLI/API capabilities are missing or unclear.

Required Laravel Cloud CLI checks:

```bash
command -v cloud
cloud auth
```

If missing, recommend:

```bash
composer global require laravel/cloud-cli
```

Required Laravel Cloud API check:

```bash
test -n "${LARAVEL_CLOUD_API_TOKEN:-}" || { echo "Missing LARAVEL_CLOUD_API_TOKEN"; exit 1; }
```

Do not print `LARAVEL_CLOUD_API_TOKEN`.

## Namecheap API automation

Default DNS mode is guide-only. Use Namecheap API automation only if the user explicitly asks and provides/export these values outside git:

```bash
NAMECHEAP_API_USER
NAMECHEAP_API_KEY
NAMECHEAP_USERNAME
NAMECHEAP_CLIENT_IP
```

`NAMECHEAP_CLIENT_IP` must be the whitelisted public IPv4 address in Namecheap API Access. Before changing DNS, ask the user to confirm the exact domain, host, record type, value, and TTL.

## Required output

`docs/larv/10-deploy/laravel-cloud.md` must include:

- hosting provider
- DNS provider
- production domain
- Laravel Cloud org/project/environment
- database type and provider
- env vars configured, with secret values redacted
- automation choice and whether DNS automation was used
- build/release commands
- DNS record instructions
- smoke-test result
- rollback instructions

## Completion gate

Do not return `status: complete` until the production URL has been probe-confirmed or the user explicitly chooses `guide-only`.

## Subagent return contract

```yaml
status: complete | guide-only | failed
production_url: "https://<domain>" | null
files_written:
  - docs/larv/10-deploy/production-answers.md
  - docs/larv/10-deploy/laravel-cloud.md
errors_unresolved: []
plugin_improvement_notes: (none)
```
