---
name: larv:learn
description: Aggregate Plugin Improvement Notes from handoffs and propose plugin edits via PR. Modes - --quick, --full, --since=DATE, --dry-run.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument flags:
- `--quick` — last 5 slices, `[plugin]` notes only, only if patterns clear
- `--full` — all `[plugin]` notes since last `--full` invocation
- `--since=YYYY-MM-DD` — explicit date range
- `--dry-run` — print proposed diffs to stdout, no branch, no PR

Invoke the `larv-learn` skill with the chosen mode.

Requires `STATE.yaml` to exist (or aggregates across all projects in the user's working directory if invoked without one — see skill prompt for details).
