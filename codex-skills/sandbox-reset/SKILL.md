---
name: sandbox-reset
description: Use when the user types /larv:sandbox-reset or asks to fresh-migrate and reseed the current larv sandbox.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:sandbox-reset

Run the larv sandbox reset helper for the current project:

```bash
bash <larv-plugin-root>/scripts/sandbox.sh "$PWD" reset
```

It runs `php artisan migrate:fresh --seed --force`, restarts the sandbox services, probes public URLs, and prints the testing report.
