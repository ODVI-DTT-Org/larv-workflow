---
name: larv-adopt
description: Adoption controller for /larv:adopt. Read-only on user code. Produces docs/larv/ retroactively from existing Laravel app.
---

# larv-adopt

> **STUB — sub-project A scaffolding only. Detailed adoption prompt logic is defined in sub-project B.**

## On entry

1. Refuse if `docs/larv/STATE.yaml` already exists (prevents accidental re-adoption).
2. Read-only on the codebase by default.
3. Run phases A0–A9 from spec §11.
4. On completion, initialize STATE.yaml with `mode: adopted`, `phase.last_completed: A9`.

## Read-only guarantee

This skill must not modify files outside `docs/larv/`. Any opt-in code modification is gated behind explicit flags (`--migrate-to-larv-conventions`, etc.) — those flags are NOT yet implemented in sub-project A.
