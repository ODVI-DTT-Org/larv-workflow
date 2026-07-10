---
name: sandbox-stop
description: Use when the user types /larv:sandbox-stop or asks to stop current larv sandbox servers.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:sandbox-stop

Run the larv sandbox stop helper for the current project:

```bash
bash <larv-plugin-root>/scripts/sandbox.sh "$PWD" stop
```

It stops only runtime processes with owner metadata for the current larv project root and slug, preventing one project from killing another project's sandbox.
