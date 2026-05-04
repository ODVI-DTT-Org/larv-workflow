---
name: larv:status
description: Print docs/larv/STATE.yaml summary. --json flag dumps raw YAML.
---

Run: `bash scripts/status.sh "$@"` from the larv plugin root.

The script reads `docs/larv/STATE.yaml` and outputs a human-readable summary (or raw YAML with `--json`). Exits non-zero if no STATE.yaml is found.
