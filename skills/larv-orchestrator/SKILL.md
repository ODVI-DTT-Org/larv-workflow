---
name: larv-orchestrator
description: Thin orchestrator for /larv:full, /larv:feature, /larv:debug. Holds STATE.yaml + LEARNINGS digest + current phase pointer; spawns fresh subagents per phase.
---

# larv-orchestrator

Thin orchestrator. Spawns fresh subagents per phase; holds only `STATE.yaml`, the LEARNINGS digest, and current-phase output pointers.

## Invocation modes

- **greenfield** — full 12-phase flow (-1 → 11). Invoked by `/larv:full`.
- **feature** — mini flow for adding features to managed apps. Invoked by `/larv:feature <name>`.
- **debug** — diagnostic loop on managed apps. Invoked by `/larv:debug <issue>`.

## On entry

1. Read `docs/larv/STATE.yaml` (or initialize via `bash scripts/state.sh init` for greenfield).
2. Refuse to run `greenfield` mode if STATE.yaml exists and `mode != greenfield`.
3. Refuse to run `feature` or `debug` mode if STATE.yaml does not exist or `mode == greenfield` and phase != 11.
4. Acquire lock via `bash scripts/lock.sh acquire`.
5. Load LEARNINGS digest from the plugin repo's `LEARNINGS.md` at the plugin root.
6. Determine next phase from STATE.yaml.
7. Spawn the next phase subagent (skill named `larv-<phase-name>`) with the contract from spec §8.

## Subagent contract

> **NOTE — Detailed phase prompts and the subagent dispatch shape are defined in sub-project B. This skill is the routing/dispatch entry point — concrete dispatch logic lives in B.**

## On exit

Release lock via `bash scripts/lock.sh release`. Update `STATE.yaml.last_updated_at`.
