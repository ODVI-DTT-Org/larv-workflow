---
name: larv:sandbox-stop
description: Stop the current project's app sandbox, docs server, and mockup server sessions.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run: `bash scripts/sandbox.sh "$PWD" stop` from the larv plugin root.

The command stops only runtime processes with owner metadata for the current project root and slug, such as `larv-app-<slug>-<port>`, `larv-docsite-<slug>-<port>`, and `larv-mockups-<slug>-<port>`. URL files alone are not enough to stop a process, which prevents one project from killing another project's sandbox.
