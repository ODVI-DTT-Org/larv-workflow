---
name: larv:brainstorm
description: Standalone brainstorm — Phase 0 only, exploratory. Produces 00-discuss/* without committing to build.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Invoke the `larv-discuss` skill standalone (no orchestrator).

Outputs land in `docs/larv/00-discuss/` only. STATE.yaml is not initialized — this is exploratory.

## Optional style controls for narrative output

This command participates in the Caveman allowlist for exploratory planning output.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset to normal.
- For an explicit one-shot preference, apply `Caveman full`, `Caveman lite`, or `Caveman ultra`.
- No style output appears for non-allowlisted commands.
