---
name: larv:full
description: Greenfield — design + build a new Laravel app end to end across 12 phases (with pre-flight setup).
---

Invoke the `larv-orchestrator` skill in greenfield mode.

The orchestrator runs Phase −1 (pre-flight), then phases 0–11 sequentially, spawning a fresh subagent per phase. State is persisted to `docs/larv/STATE.yaml`.

Phase −1 includes the shared `/larv:security` repository baseline. It must complete before any planning, dependency installation, generated app bootstrap, or implementation. The scan writes `docs/larv/security/pre-flight-security.md` and records `security.baseline.status` in `STATE.yaml`. If the scan fails, stop the full cycle and surface the report; do not execute repository code or continue to later phases.

If the project is already managed (`STATE.yaml` exists with `mode: adopted`), refuse to run unless the user passes `--re-greenfield`.

The AI owns sandbox execution. After implementation changes, run required Laravel commands, restart/probe the sandbox when needed, and show the public URL from `docs/larv/07-runtime/sandbox-url.txt`. Do not ask the user to run migrations, seeders, build commands, cache clears, queue/runtime restarts, or server restarts for sandbox review.
