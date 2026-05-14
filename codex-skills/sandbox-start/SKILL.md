---
name: sandbox-start
description: Use when the user types /larv:sandbox-start or asks to start the current larv sandbox URLs again.
---

# larv:sandbox-start

Run the larv sandbox start helper for the current project:

```bash
bash /home/claude-team/kaito/workflow/scripts/sandbox.sh "$PWD" start
```

It restarts the app sandbox plus generated docs/mockup servers when their URL artifacts exist, probes public URLs, and prints the testing report.
