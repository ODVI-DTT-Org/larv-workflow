---
name: larv-discuss
description: Phase 0 - Laravel-specific brainstorming, grounded in the DDD interview output. Starts with the user's design-direction preference, then asks about admin panel, auth, async, realtime, observability, performance, payments, multi-tenancy, search, MCPs, and dev tooling.
---

# larv-discuss

Run product brainstorming with Laravel ecosystem grounding. Reads the DDD interview output (Phase 0a) and uses it to ground every recommendation. The first user-facing question must capture how the user wants design handled later in Phase 3, so design is not introduced too late.

## Inputs

- `docs/larv/ddd-interview/*.md` (Phase 0a outputs)
- `docs/larv/STATE.yaml`

## What you do

1. Read all files in `docs/larv/ddd-interview/`.
2. Ask the design-direction starter question before any Laravel package or architecture question. Save the answer to `docs/larv/00-discuss/design-preferences.md`.
3. Walk the Laravel ecosystem checklist below. For each package, print a 2-3 line description and how it would help this specific app, citing DDD interview output. Then ask. Every question is paired with a recommendation block.
4. Write the outputs.

## Required starting question: design direction

Ask this as Q1 in Phase 0, before admin panel, auth, tenancy, or any package choice:

> "Before we choose Laravel packages, how do you want the design phase handled?
> (a) Recommend a visual direction from my PRD/domain answers - default starts with Attio, then adds Attio Venture/Attio Finance if relevant
> (b) I already have a specific style/template/brand direction
> (c) Decide later in Phase 3"

If the user chooses (a), record `mode: agent-recommendations`, `default_starting_point: templates/attio-crm-workspace.html`, and note any domain-fit hints for Attio Venture or Attio Finance.

If the user chooses (b), ask one short follow-up for the style/template/brand reference and record `mode: user-specified`, `raw_direction`, and any paths/URLs/named brands they gave. Do not fetch external sources in Phase 0.

If the user chooses (c), record `mode: decide-later`.

Write `docs/larv/00-discuss/design-preferences.md` with:

- the selected mode
- the raw user answer
- whether Phase 3 should ask again or start from the saved preference
- any recommended starting templates (`templates/attio-crm-workspace.html`, `attio-finance-html-effectiveness-design/...`, `attio-venture-html-effectiveness-design/...`) with rationale
- notes for app logo and favicon/URL logo expectations if the user mentioned branding

Also summarize the design preference in `product-brief.md` and `handoff.md` so later phases see it even if they only read the brief.

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
- `design-preferences.md` - Phase 0 design starter answer that Phase 3 must honor
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
- Do not create mockups, brand specs, UI design docs, or architecture docs; those are later phases. Phase 0 only records the user's design-direction preference.
- Do not change the DDD interview output. It is the source of truth.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/00-discuss/product-brief.md
  - docs/larv/00-discuss/design-preferences.md
  - docs/larv/00-discuss/stakeholder-map.md
  - docs/larv/00-discuss/glossary.md
  - docs/larv/00-discuss/library-decisions.md
  - docs/larv/00-discuss/mcp-decisions.md
  - docs/larv/00-discuss/handoff.md
state_updates: {}
plugin_improvement_notes: (none)
```
