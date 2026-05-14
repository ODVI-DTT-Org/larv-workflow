---
name: larv:sandbox-stop
description: Stop the current project's app sandbox, docs server, and mockup server sessions.
---

Run: `bash scripts/sandbox.sh "$PWD" stop` from the larv plugin root.

The command stops only tmux sessions derived from the current project's slug and recorded runtime ports, such as `larv-app-<port>`, `larv-docsite-<slug>`, and `larv-mockups-<slug>`.
