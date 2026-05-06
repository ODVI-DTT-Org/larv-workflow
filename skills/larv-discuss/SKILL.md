---
name: larv-discuss
description: Phase 0 - Laravel-specific brainstorming, grounded in the DDD interview output. Asks about admin panel, auth, async, realtime, observability, performance, payments, multi-tenancy, search, MCPs, and dev tooling, each with a description and a recommendation citing the DDD interview.
---

# larv-discuss

Run product brainstorming with Laravel ecosystem grounding. Reads the DDD interview output (Phase 0a) and uses it to ground every recommendation.

## Inputs

- `docs/larv/ddd-interview/*.md` (Phase 0a outputs)
- `docs/larv/STATE.yaml`

## What you do

1. Read all files in `docs/larv/ddd-interview/`.
2. Walk the Laravel ecosystem checklist below. For each package, print a 2-3 line description and how it would help this specific app, citing DDD interview output. Then ask. Every question is paired with a recommendation block.
3. Write the outputs.

## Laravel ecosystem checklist

For each package, present description + recommendation + question:

- **Admin panel**: Filament / Nova / none
- **Auth**: Sanctum / Passport / Fortify / Socialite
- **Async**: Horizon + Redis / sync queues
- **Realtime**: Reverb / Pusher / none
- **Observability**: Pulse, Telescope (yes/no for each)
- **Performance**: Octane (Swoole / RoadRunner / FrankenPHP) / none
- **Payments**: Cashier-Stripe / Cashier-Paddle (only if billing was mentioned in DDD interview)
- **Multi-tenancy**: Spatie Multitenancy / Tenancy for Laravel / Stancl / none
- **Search**: Scout + Meilisearch / Scout + Typesense / none
- **MCPs**: context7, playwright, laravel-mcp (yes/no for each)
- **Dev tooling**: Pest, Pint, Larastan, Rector (yes/no for each)

The recommendation cites the DDD interview verbatim. Example: "you said 'audit-critical' -> Pulse + Telescope recommended. you said 'B2B audience' -> Filament recommended. no realtime in core processes -> skip Reverb."

## Required outputs

In `docs/larv/00-discuss/`:

- `product-brief.md` - synthesized one-page brief
- `stakeholder-map.md` - actors and decision authorities
- `glossary.md` - synthesizes ubiquitous-language with canonical terms; cross-links to verbatim version in `docs/larv/ddd-interview/ubiquitous-language.md`
- `library-decisions.md` - every approved package + rationale (feeds ADR creation in Phase 2)
- `mcp-decisions.md` - selected MCPs and reasons
- `handoff.md` - phase summary

## Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 0: discuss approved"
```

## What you do not do

- Do not run any code or scaffold any project.
- Do not write design or architecture docs; those are later phases.
- Do not change the DDD interview output. It is the source of truth.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/00-discuss/product-brief.md
  - docs/larv/00-discuss/stakeholder-map.md
  - docs/larv/00-discuss/glossary.md
  - docs/larv/00-discuss/library-decisions.md
  - docs/larv/00-discuss/mcp-decisions.md
  - docs/larv/00-discuss/handoff.md
state_updates: {}
plugin_improvement_notes: (none)
```
