---
name: larv:redesign-attio-venture
description: Redesign the current Laravel frontend using the Attio Venture HTML Effectiveness CRM templates.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument: optional focus such as `<page>`, `<role>`, or `<workflow>`. If omitted, redesign the whole frontend UI.

Invoke the `larv-redesign-attio-venture` skill.

## Contract

- Use `attio-venture-html-effectiveness/` as the required design source.
- Prefer the CRM templates first: `21-credit-officer-crm.html`, `22-sales-crm.html`, and `23-service-crm.html`.
- Preserve all backend behavior, routes, policies, validation, migrations, seeders, and user flows unless the user explicitly asks for functional changes.
- Redesign the whole frontend shell and user-facing screens into the Attio Venture CRM language: Attio Venture brown/tan tokens, dense CRM tables, restrained app shell, command/search surfaces, metric strips, filters, drawers/modals, state badges, and high-fidelity empty/loading/error states.
- Keep all roles in one coherent layout. Do not create a separate admin-only layout unless the existing app already requires it and the user approves.
- Run the required frontend build, Laravel cache/view commands, sandbox restart/probe, and screenshot checks. Do not ask the user to run commands manually.
- Show the public sandbox URL where the redesigned app can be tested.

## Required Artifacts

- `docs/larv/redesigns/<timestamp>-attio-venture/design-source.md`
- `docs/larv/redesigns/<timestamp>-attio-venture/screen-inventory.md`
- `docs/larv/redesigns/<timestamp>-attio-venture/implementation-report.md`
- `docs/larv/redesigns/<timestamp>-attio-venture/visual-parity.md`
- update `DOCS.md` or `docs/user-manual/README.md` with the redesign report path when those files exist.
