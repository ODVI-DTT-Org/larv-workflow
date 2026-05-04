---
name: larv-premortem
description: Phase 5 wrapper - failure modes, adversarial review, risks register. May loop back to phases 2/3/4.
---

# larv-premortem

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run premortem (what could go wrong) + adversarial review. If showstoppers found, return `state_updates: { current_phase: 2 }` (or 3, 4) to loop back; orchestrator handles re-running prior phases.

## Upstream skills invoked

- `masterplan-bug-premortem`
- `masterplan-adversarial-review`

## Required outputs

- `docs/larv/05-premortem/failure-modes.md`
- `docs/larv/05-premortem/adversarial-review.md`
- `docs/larv/05-premortem/risks-register.md`

## Subagent return contract

See spec §8. Loopback signal via `state_updates.current_phase` set to a prior phase index.
