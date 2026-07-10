---
name: resume
description: Use when the user types /larv:resume or asks to continue a larv-managed project from STATE.yaml.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:resume

Run the larv resume helper for the current project:

```bash
bash <larv-plugin-root>/scripts/resume.sh "$PWD"
```

Follow the decision tree output: unresolved errors first, then pending gates, budget cap review, phase advancement, or slice continuation.
