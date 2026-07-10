---
name: larv:resume
description: Continue from the last STATE.yaml checkpoint. Handles errors_unresolved, gates_pending, budget caps, and phase advancement.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run: `bash scripts/resume.sh "$@"` from the larv plugin root.

The script implements the decision tree from spec §9: errors_unresolved → gates_pending → budget cap → phase advancement → slice loop continuation.

Pass `--force-unlock` to clear a stale `docs/larv/.lock` from another machine.
