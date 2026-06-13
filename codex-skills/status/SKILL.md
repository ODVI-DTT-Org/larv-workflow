---
name: status
description: Use when the user types /larv:status or asks for the current larv project status.
---

# larv:status

Run the larv status helper for the current project:

```bash
bash <larv-plugin-root>/scripts/status.sh "$PWD"
```

If `docs/larv/STATE.yaml` is missing, explain that the current directory is not yet larv-managed and suggest `/larv:full` for greenfield projects or `/larv:adopt` for existing Laravel apps.
