---
name: larv-domain
description: Phase 1 wrapper - DDD viability check, then either DDD strategic model or flat domain model.
---

# larv-domain

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run DDD viability check (≥2 of 4 criteria - complex/fast-changing rules, multi-team collisions, unstable contracts, audit-critical). If viable, invoke `domain-driven-design`. Else, produce a flat Eloquent-friendly domain model.

## Upstream skills invoked

- `domain-driven-design` (gated on viability)

## Required outputs

- `docs/larv/01-domain/ddd-viability.md`
- `docs/larv/01-domain/{subdomains,bounded-contexts,context-map,ubiquitous-language}.md` (if DDD viable)
  OR `docs/larv/01-domain/domain-model.md` (if not)

## Subagent return contract

See spec §8.
