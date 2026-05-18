---
name: larv:sandbox-start
description: Start or restart the current project's app sandbox, docs server, and mockup server, then verify public URLs.
---

Before running anything, ask the user which public VM ports they want for:

- app sandbox (`8000-8999`)
- docs (`9500-9999`)
- mockups (`9000-9499`)

If they want automatic allocation, they may say `auto`. If they provide ports, export them before running:

```bash
export LARV_APP_PORT="<app-port>"
export LARV_DOCS_PORT="<docs-port>"
export LARV_MOCKUPS_PORT="<mockups-port>"
```

Run: `bash scripts/sandbox.sh "$PWD" start` from the larv plugin root.

The command restarts the app through `docs/larv/07-runtime/deploy-sandbox.sh`, restarts project-scoped docs/mockup static servers, reallocates recorded ports that are occupied or owned by another project, opens local firewall ports when possible, probes every public URL, and prints the same report as `/larv:sandbox`.
