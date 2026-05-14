---
name: larv:sandbox-start
description: Start or restart the current project's app sandbox, docs server, and mockup server, then verify public URLs.
---

Run: `bash scripts/sandbox.sh "$PWD" start` from the larv plugin root.

The command restarts the app through `docs/larv/07-runtime/deploy-sandbox.sh`, restarts project-scoped docs/mockup static servers, reallocates recorded ports that are occupied or owned by another project, opens local firewall ports when possible, probes every public URL, and prints the same report as `/larv:sandbox`.
