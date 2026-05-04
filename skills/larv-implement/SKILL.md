---
name: larv-implement
description: Phase 8 wrapper - slice loop driver. Spawns fresh slice subagents, auto-fires /larv:learn --quick every 5 slices.
---

# larv-implement

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Drive the slice loop:
1. For each slice in `06-implementation/elephant-carpaccio.md`, spawn a fresh slice subagent.
2. After every 5 completed slices, fire `/larv:learn --quick` (parallel, fire-and-forget).
3. Update `STATE.yaml.slices.status[NN]` after each slice.
4. Surface user feedback to slice-iterate subagents.

## Upstream skills invoked (per slice)

- `superpowers-laravel:execute-plan`
- Contextual `superpowers-laravel:laravel-*` skills

## Required outputs (per slice)

- `docs/larv/06-implementation/slice-NN/{plan,handoff,verification}.md`

## Subagent return contract

See spec §8.
