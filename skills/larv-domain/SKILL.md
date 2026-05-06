---
name: larv-domain
description: Phase 1 - DDD viability check, then either Laravel-DDD architecture mapping (WebFetches the linked medium article at runtime) or a flat Eloquent-friendly domain model.
---

# larv-domain

Map the Phase 0a DDD interview output to a Laravel architecture. If DDD viability passes, produce a full DDD layout; otherwise, produce a flat Eloquent model that still uses the canonical ubiquitous-language terms.

## Inputs

- `docs/larv/ddd-interview/*.md` (Phase 0a)
- `docs/larv/00-discuss/*.md` (Phase 0)

## DDD viability gate

Pass if >=2 of the following hold. Use the DDD interview output as evidence:

- complex / fast-changing business rules
- multi-team boundary collisions
- unstable upstream contracts
- audit-critical workflows

Pass -> DDD path. Fail -> Flat path.

Print the assessment with citations. Ask the user to confirm or override.

## DDD path

WebFetch the linked Laravel-DDD article at runtime so the mapping reflects current guidance:

```text
https://medium.com/@harryespant/implementing-domain-driven-architecture-in-laravel-setup-advantages-and-practical-use-cases-5eac6dfeffaa
```

Use the article as a reference for Laravel-specific layout decisions: Domain / Application / Infrastructure / Interface layers; where Aggregates live; Repository interface vs concrete; how Eloquent folds in. Each non-trivial decision gets an ADR in `adr/`.

Outputs in `docs/larv/01-domain/`:

- `subdomains.md`
- `bounded-contexts.md`
- `context-map.md` (Mermaid)
- `ubiquitous-language.md` (canonical, distinct from Phase 0a's verbatim version)
- `aggregates.md`
- `domain-events.md`
- `laravel-layout.md` (file/folder shape under `app/Domain/...`, `app/Application/...`, etc.)

## Flat path

Single output:

- `docs/larv/01-domain/domain-model.md` - Eloquent-friendly entities and relationships, still using ubiquitous-language terms.

## Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 1: domain approved"
```

## What you do not do

- Do not bake the article's specific recipe into your output verbatim. Cite it as a reference and synthesize.
- Do not pick libraries or frameworks; those are Phase 0 / Phase 2 decisions.
- Do not change Phase 0a or Phase 0 outputs.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/01-domain/...  # depends on path taken
state_updates: {}
plugin_improvement_notes: (none)
```
