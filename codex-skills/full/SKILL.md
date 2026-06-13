---
name: full
description: Use when the user types /larv:full or asks to run the full greenfield larv workflow for a Laravel app.
---

# larv:full

This is the Codex-compatible entry point for `/larv:full`.

## Behavior

1. Treat the user's request as the `larv` greenfield workflow.
2. Read the plugin command definition at `commands/larv-full.md`.
3. Invoke the `larv-orchestrator` skill in greenfield mode.
4. If no `docs/larv/STATE.yaml` exists, run Phase -1 via:

```bash
bash <larv-plugin-root>/scripts/pre-flight.sh "$PWD" "$(basename "$PWD")" greenfield
```

5. Treat the Phase -1 `larv-security` baseline as a hard gate. If `pre-flight.sh` reports `security check failed`, stop before planning or implementation. Do not inspect, source, install, or execute project code to "see what happens"; read `docs/larv/security/pre-flight-security.md` and ask the user how to handle the finding.
6. Continue according to the orchestrator and phase skills in `<larv-plugin-root>/skills/`.

## Notes

Codex CLI does not currently expose local marketplace command files as slash-menu commands in the same way Claude Code does. This skill gives Codex an explicit `larv:full` trigger and maps `/larv:full` to the same repo implementation.
