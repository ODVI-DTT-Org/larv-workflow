---
name: sandbox
description: Use when the user types /larv:sandbox or asks for current larv sandbox URLs, credentials, and testing instructions.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:sandbox

Run the larv sandbox helper for the current project:

```bash
bash <larv-plugin-root>/scripts/sandbox.sh "$PWD" info
```

Report the app, docs, and mockup URLs, readiness status, seeded credentials, and testing guide paths. If any generated URL is down, suggest `/larv:sandbox-start`.
