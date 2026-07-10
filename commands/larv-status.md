---
name: larv:status
description: Print docs/larv/STATE.yaml summary. --json flag dumps raw YAML.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run: `bash scripts/status.sh "$@"` from the larv plugin root.

The script reads `docs/larv/STATE.yaml` and outputs a human-readable summary (or raw YAML with `--json`). Exits non-zero if no STATE.yaml is found.

The summary includes the current active `Caveman` mode line:

- `Caveman style: normal` when style is not active.
- `Caveman style: full`, `Caveman style: lite`, or `Caveman style: ultra` when one is active.
