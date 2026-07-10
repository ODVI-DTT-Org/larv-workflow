---
name: larv-caveman
description: Use when the user types /larv-caveman to inspect or manage strict Caveman output style for selected larv commands.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-caveman

This is the Codex-compatible entry point for `/larv-caveman`.

## Behavior

1. Read `commands/larv-caveman.md`.
2. Run `bash <larv-plugin-root>/scripts/caveman.sh` with one of:

```bash
# Show status
bash <larv-plugin-root>/scripts/caveman.sh status "$PWD"

# Persist session mode
bash <larv-plugin-root>/scripts/caveman.sh set "$PWD" full
bash <larv-plugin-root>/scripts/caveman.sh set "$PWD" lite
bash <larv-plugin-root>/scripts/caveman.sh set "$PWD" ultra

# Return to strict full
bash <larv-plugin-root>/scripts/caveman.sh clear "$PWD"
```

3. Treat `normal`, `off`, and `clear` as a return to strict `full`. Do not recommend disabling Caveman for allowlisted larv flows.
4. This setting applies only to allowlisted planning commands (brainstorm, debug, feature, full, feature-feedback, feature-how-it-works, feature-onboarding-helper).
   `larv-caveman` also supports one-shot phrases inside those requests, e.g.:

```bash
... with Caveman full / Caveman lite / Caveman ultra / Caveman normal
```

`Caveman normal` resolves to `full` in strict mode. If status reports `full-unavailable`, the Caveman dependency is missing or unsafe; report that explicitly instead of silently using normal style.

For install guidance in missing-dependency fallback cases, advise:

```bash
bash <larv-plugin-root>/scripts/caveman.sh install-hint
```
