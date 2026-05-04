---
name: resume
description: Use when the user types /larv:resume or asks to continue a larv-managed project from STATE.yaml.
---

# larv:resume

Run the larv resume helper for the current project:

```bash
bash /home/claude-team/kaito/workflow/scripts/resume.sh "$PWD"
```

Follow the decision tree output: unresolved errors first, then pending gates, budget cap review, phase advancement, or slice continuation.
