---
name: larv:resume
description: Continue from the last STATE.yaml checkpoint. Handles errors_unresolved, gates_pending, budget caps, and phase advancement.
---

Run: `bash scripts/resume.sh "$@"` from the larv plugin root.

The script implements the decision tree from spec §9: errors_unresolved → gates_pending → budget cap → phase advancement → slice loop continuation.

Pass `--force-unlock` to clear a stale `docs/larv/.lock` from another machine.
