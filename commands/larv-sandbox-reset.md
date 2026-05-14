---
name: larv:sandbox-reset
description: Fresh-migrate and reseed the current project's sandbox database, then restart and verify sandbox URLs.
---

Run: `bash scripts/sandbox.sh "$PWD" reset` from the larv plugin root.

The command runs `php artisan migrate:fresh --seed --force`, restarts the sandbox services, probes every generated public URL, and prints the URLs, seeded credentials, and testing guides.
