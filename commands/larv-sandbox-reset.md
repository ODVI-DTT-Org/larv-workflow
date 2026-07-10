---
name: larv:sandbox-reset
description: Fresh-migrate and reseed the current project's sandbox database, then restart and verify sandbox URLs.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run: `bash scripts/sandbox.sh "$PWD" reset` from the larv plugin root.

The command runs `php artisan migrate:fresh --seed --force`, restarts the sandbox services, probes every generated public URL, and prints the URLs, seeded credentials, and testing guides.
