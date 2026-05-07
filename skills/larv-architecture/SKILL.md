---
name: larv-architecture
description: Phase 2 - C4 architecture, ADRs, and Laravel package integration matrix from Phase 0 library decisions.
---

# larv-architecture

Produce C4 levels 1-3, lock package architecture decisions, and convert Phase 0 Laravel package choices into implementation constraints.

Use the bundled masterplan references:

- `bundle/masterplan/skills/masterplan-c4-architecture/SKILL.md`
- `bundle/masterplan/skills/masterplan-master-design/SKILL.md`

## Inputs

- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/00-discuss/library-decisions.md`
- `docs/larv/00-discuss/mcp-decisions.md`
- `docs/larv/01-domain/*.md`

## What you do

1. Produce C4 context, container, and component diagrams.
2. Write `docs/larv/02-architecture/library-policy.md` with all approved packages and rejected alternatives.
3. Write `docs/larv/02-architecture/package-integration-matrix.md`.
4. Write ADRs for every major package family selected or explicitly deferred.

## Package integration matrix

For each selected package, define concrete downstream obligations:

- **Filament/Nova**: panels, resources, relation managers, widgets, actions, policies, route/auth boundary.
- **Sanctum/Fortify/Passport/Socialite**: guards, providers, token/session model, password/email flows, API scopes.
- **Horizon/queues/Redis**: jobs, events/listeners, retry/backoff policy, worker topology, failed-job handling.
- **Reverb/broadcasting**: events, channels, auth callbacks, websocket deployment shape.
- **Pulse/Telescope**: access policy, environment restrictions, retained data, production posture.
- **Octane**: long-lived-process compatibility, mutable singleton/state audit, reload strategy.
- **Cashier Stripe/Paddle**: billable models, webhook endpoints, subscription states, invoice/customer portal flows.
- **tenancy**: tenant identification, database strategy, tenant-aware models, cache/queue isolation.
- **Scout/Meilisearch/Typesense**: searchable models, indexing jobs, filters, rebuild strategy.
- **Storage/uploads**: disks, visibility, signed URLs, cleanup/retention rules.
- **Mail/notifications**: provider choice, templates, queueing, verified sender.

Every selected package must have:

- implementation files/components
- required tests
- env vars
- production deploy notes
- failure modes

## Required outputs

- `docs/larv/02-architecture/c4-context.md`
- `docs/larv/02-architecture/c4-container.md`
- `docs/larv/02-architecture/c4-component.md`
- `docs/larv/02-architecture/library-policy.md`
- `docs/larv/02-architecture/package-integration-matrix.md`
- `adr/000N-*.md` for selected/deferred package decisions

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/02-architecture/c4-context.md
  - docs/larv/02-architecture/c4-container.md
  - docs/larv/02-architecture/c4-component.md
  - docs/larv/02-architecture/library-policy.md
  - docs/larv/02-architecture/package-integration-matrix.md
  - adr/000N-*.md
state_updates: {}
plugin_improvement_notes: (none)
```
