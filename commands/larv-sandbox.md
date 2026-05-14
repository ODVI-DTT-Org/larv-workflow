---
name: larv:sandbox
description: Show current project sandbox URLs, probe readiness, seeded credentials, and browser testing instructions.
---

Run: `bash scripts/sandbox.sh "$PWD" info` from the larv plugin root.

The command reads the current project's `docs/larv/STATE.yaml`, runtime URL files, seed guide, and user testing guides, then prints:

- app sandbox URL
- docs URL
- mockups URL
- readiness/probe status for every generated URL
- seeded test credentials and role coverage from `docs/user-manual/seed-data.md`
- per-slice browser testing guides and what can be tested

If any generated URL is down, report it and recommend `/larv:sandbox-start`.
