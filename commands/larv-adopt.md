---
name: larv:adopt
description: Bring an existing Laravel app under larv management. Read-only on user code; produces docs/larv/ retroactively.
---

Invoke the `larv-adopt` skill.

Runs phases A0–A9 (survey, interview, domain reverse-engineering, architecture extraction, design extraction, test reality, risk register, STATE seed, sandbox bootstrap, adoption report). Phases 6–10 of `/larv:full` are skipped — no implementation, no slice plan, no deploy.

If `STATE.yaml` already exists, refuse to run.
