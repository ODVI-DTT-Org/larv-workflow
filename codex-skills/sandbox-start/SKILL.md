---
name: sandbox-start
description: Use when the user types /larv:sandbox-start or asks to start the current larv sandbox URLs again.
---

# larv:sandbox-start

Run the larv sandbox start helper for the current project:

Before running it, ask the user which public VM ports they want for app (`8000-8999`), docs (`9500-9999`), and mockups (`9000-9499`). If the user chooses automatic allocation, leave the env vars unset. If they provide ports, export `LARV_APP_PORT`, `LARV_DOCS_PORT`, and `LARV_MOCKUPS_PORT`.

```bash
bash /home/claude-team/kaito/workflow/scripts/sandbox.sh "$PWD" start
```

It restarts the app sandbox plus generated docs/mockup servers, reallocates foreign-owned or occupied recorded ports, probes public URLs, and prints the testing report.
