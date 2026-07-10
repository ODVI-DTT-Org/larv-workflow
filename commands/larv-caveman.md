---
name: larv-caveman
description: Inspect and manage strict Caveman output style for opt-in narrative/brainstorming commands.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run this command to manage `execution.caveman_style`.

## Current mode

Check the current mode:

```bash
bash scripts/caveman.sh status "$PWD"
```

Output format:

```text
session-style=<stored> effective-style=<applied> strict=<0|1>
```

`effective-style` defaults to `full`. If the Caveman dependency is missing in strict mode, status reports `full-unavailable` and larv does not silently downgrade to `normal`.

## Change mode

Set a session style:

```bash
bash scripts/caveman.sh set "$PWD" full
bash scripts/caveman.sh set "$PWD" lite
bash scripts/caveman.sh set "$PWD" ultra
```

Return to strict `full`:

```bash
bash scripts/caveman.sh set "$PWD" normal
bash scripts/caveman.sh clear "$PWD"
bash scripts/caveman.sh set "$PWD" off
```

Behavioral notes:

- Session mode persists until explicitly cleared.
- `normal`/`off`/`clear` resolve back to `full`; strict Caveman is the default posture.
- Explicit per-command overrides (for allowlisted commands) take precedence over session mode.
- If requested Caveman mode is unavailable, strict mode reports `full-unavailable` or exits nonzero instead of pretending `normal` was used.
- Set `LARV_CAVEMAN_STRICT=0` only for deterministic compatibility tests that must allow legacy normal fallback.
- This command intentionally controls only opt-in flows listed below.

## Commands that use Caveman when opted in

- `larv-brainstorm`
- `larv-debug`
- `larv-feature`
- `larv-feature-feedback`
- `larv-feature-how-it-works`
- `larv-feature-onboarding-helper`
- `larv-full`

## One-command overrides in allowed flows

Inside an allowlisted command, use a request phrase:

- `Caveman full`
- `Caveman lite`
- `Caveman ultra`
- `Caveman off` (treated as `full`)
- `Caveman normal` (treated as `full`)

Dependency guidance:

```bash
bash scripts/caveman.sh install-hint
```

This prints:

- expected binary (`LARV_CAVEMAN_BIN`, bundled fallback, or `caveman`)
- bundled fallback path (`bundle/caveman/bin/caveman`)
- pinned version (`1.0.0` by default)

## Allowlist source of truth

- Core allowlist is loaded from `scripts/caveman-allowlist.txt`:

```bash
bash scripts/caveman.sh allowlist
```

- Output includes the effective source and list used by the resolver.

- Override temporarily with a compact mode list:

```bash
LARV_CAVEMAN_ALLOWLIST="full,debug,feature" bash scripts/caveman.sh resolve "$PWD" "Caveman full" "$SOME_COMMAND"
```

- Override temporarily with a dedicated allowlist file:

```bash
LARV_CAVEMAN_ALLOWLIST_FILE="/path/to/caveman-allowlist.txt" bash scripts/caveman.sh allowlist
```

For command-scoped resolution, pass the command as the third argument when using `resolve`.
Without command context, the resolver returns `normal`.

Set `LARV_CAVEMAN_ALLOW_UNSCOPED_RESOLVE=1` to restore legacy unscoped behavior temporarily.
