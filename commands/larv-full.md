---
name: larv:full
description: Greenfield — design + build a new Laravel app end to end across 12 phases (with pre-flight setup).
---

Invoke the `larv-orchestrator` skill in greenfield mode.

The orchestrator runs Phase −1 (pre-flight), then phases 0–11 sequentially, spawning a fresh subagent per phase. State is persisted to `docs/larv/STATE.yaml`.

If the project is already managed (`STATE.yaml` exists with `mode: adopted`), refuse to run unless the user passes `--re-greenfield`.
