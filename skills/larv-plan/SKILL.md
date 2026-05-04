---
name: larv-plan
description: Phase 6 wrapper - Elephant Carpaccio slice plan with parallelism annotations.
---

# larv-plan

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Break the design into ~1-day vertical slices via Elephant Carpaccio. Annotate parallel-eligible slices with `parallel: true` and explicit `depends_on`.

## Upstream skills invoked

- `superpowers-laravel:write-plan`
- `masterplan-implementation`

## Required outputs

- `docs/larv/06-implementation/elephant-carpaccio.md`

## Subagent return contract

See spec §8. Initializes `STATE.yaml.slices` with the planned slice IDs.
