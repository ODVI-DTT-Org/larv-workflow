---
name: larv-provision
description: Legacy helper reference for sandbox provisioning. The current /larv:full flow does not dispatch this skill; app sandbox startup is generated as docs/Handsoff/bootstrap-sandbox.md and run by the implementation venue.
---

# larv-provision

Do not dispatch this during `/larv:full`.

The app sandbox belongs to implementation handoff so another AI tool can execute it without the larv plugin. The canonical runtime path is:

1. `larv-plan` writes executable `docs/larv/07-runtime/deploy-sandbox.sh`.
2. `larv-handoff` writes `docs/Handsoff/bootstrap-sandbox.md`.
3. `larv-docsite` serves the plan and generated handoff for review.
4. The selected implementation venue runs `docs/Handsoff/bootstrap-sandbox.md` before the first slice.
5. In greenfield docs-only repos, that bootstrap creates the bare Laravel scaffold first when `artisan` is missing; Slice 01 then applies app-specific packages and domain work.

Keep this skill only as a reference for the required invariants in the bootstrap document.

## Bootstrap Invariants

`docs/Handsoff/bootstrap-sandbox.md` must:

- Be self-contained and not require plugin libraries.
- Refuse to continue unless `docs/larv/07-runtime/deploy-sandbox.sh` exists and is executable.
- Create a bare Laravel scaffold in the current project root when `artisan` is missing, unless `LARV_SCAFFOLD_ON_BOOTSTRAP=never`.
- Allocate a free app port from the app range.
- Open the selected app port in the VM firewall before the external probe.
- Allocate a database name from the project slug.
- Use the current project directory as the local VM project root.
- Run `docs/larv/07-runtime/deploy-sandbox.sh` locally with `APP_PORT` and `DB_DATABASE`.
- Probe the app from inside the VM before any announcement.
- Probe the external app URL before any announcement.
- Write `docs/larv/07-runtime/sandbox-url.txt`.
- Write `docs/larv/07-runtime/sandbox-runbook.md`.
- Update `STATE.yaml.execution.allocations`.
- Update `STATE.yaml.sandbox.app_url` and `STATE.yaml.sandbox.status`.
- Print the sandbox URL only after both probes pass.
- Never SSH to `31.220.79.31` in the default flow; the AI is expected to already be running on that VM. Remote SSH is only for explicit `LARV_RUNTIME_MODE=remote` workflows.

## What You Do Not Do

- Do not start the app sandbox during `/larv:full`.
- Do not open a provisioning hard gate before the routing menu.
- Do not dispatch this skill from `larv-orchestrator`.
- Do not ask the user to manually invent ports, database names, or project roots.

## Failure Contract

If a model tries to use this skill as an active phase, stop and redirect to the generated bootstrap file:

```yaml
status: failed
errors_unresolved:
  - "App sandbox startup must run from docs/Handsoff/bootstrap-sandbox.md during implementation, not from larv-provision during /larv:full."
next_step: "Run docs/Handsoff/bootstrap-sandbox.md before the first slice."
```
