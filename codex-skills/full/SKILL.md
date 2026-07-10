---
name: full
description: Use when the user types /larv:full or asks to run the full greenfield larv workflow for a Laravel app.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

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
6. Before context-heavy work, use `bash <larv-plugin-root>/scripts/token-optimizer.sh status "$PWD"` and only use Headroom/LeanCTX through `scripts/token-optimizer.sh run`. If the gate reports fallback, continue without a token optimizer.
7. Continue according to the orchestrator and phase skills in `<larv-plugin-root>/skills/`.

## Notes

Codex CLI does not currently expose local marketplace command files as slash-menu commands in the same way Claude Code does. This skill gives Codex an explicit `larv:full` trigger and maps `/larv:full` to the same repo implementation.

## Caveman style controls

`larv:full` is allowlisted for Caveman output style.

- Use `/larv-caveman full`, `/larv-caveman lite`, or `/larv-caveman ultra` to persist session style.
- Use `/larv-caveman off` or `/larv-caveman normal` to clear/reset.
- One-shot per-command overrides are expressed as `Caveman full`, `Caveman lite`, or `Caveman ultra` in the user request.
