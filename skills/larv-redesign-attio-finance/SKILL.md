---
name: larv-redesign-attio-finance
description: Use when the user types /larv:redesign-attio-finance or asks to redesign a Laravel frontend into the Attio Finance CRM visual system.
---

# larv-redesign-attio-finance

Redesign the current Laravel frontend using the bundled Attio Finance HTML Effectiveness CRM templates. This is a production app redesign command, not a mockup-only command.

## Required Design Source

- Gallery: `attio-finance-html-effectiveness-design/`
- Primary templates:
  - `21-credit-officer-crm.html`
  - `22-sales-crm.html`
  - `23-service-crm.html`
- Supporting references:
  - `05-design-system.html`
  - `06-component-variants.html`
  - `design-system.css`
  - `DESIGN-TOKENS.md`
  - `LOGO-USAGE.md`

Use the Attio Finance gold/blue brand treatment and the shared Attio CRM layout language. Do not invent a new theme when these templates cover the needed surface.

## Workflow

1. Verify this is a Laravel app. Check for `artisan`, `composer.json`, routes, frontend assets, Blade/Livewire/Inertia/Vue/React/Filament surfaces, and existing `docs/larv/STATE.yaml`.
2. Create `docs/larv/redesigns/<timestamp>-attio-finance/`.
3. Write `design-source.md` with the exact Attio Finance source files used and why the selected CRM template matches the app.
4. Inventory frontend surfaces into `screen-inventory.md`: app shell, auth pages, dashboards, index/list pages, detail pages, create/edit forms, tables, filters, modals/drawers, reports, role-specific menus, empty/loading/error states.
5. Read the Attio Finance CRM templates and extract concrete implementation rules: layout, spacing, typography, tokens, table density, cards, badges, sidebar/header behavior, buttons, inputs, tabs, filters, modals/drawers, logo/favicon treatment.
6. Apply the redesign to the actual frontend code. Preserve backend behavior, routes, forms, Livewire/Filament actions, validation names, policies, and user workflows.
7. Keep every role in one coherent app layout. Admin-only menu items may be conditionally shown/hidden, but the app must not drift into separate visual systems for admin vs normal users.
8. Ensure visible app logo and browser URL logo/favicon are present where the app supports them.
9. Run required commands yourself: dependency install when needed, asset build, Laravel view/cache clears, migrations only if already required by the app, tests that cover touched surfaces, sandbox restart, and public URL probe.
10. Use Playwright or browser screenshots for desktop and mobile checks against the Attio Finance template direction. Fix obvious visual drift, broken layouts, inaccessible text, dead primary actions, and inconsistent navigation.
11. Write `visual-parity.md` with screenshots checked, template references, differences accepted, and fixes made.
12. Write `implementation-report.md` with files changed, commands run, sandbox URL, remaining risks, and where the user should test.
13. Update `DOCS.md` or `docs/user-manual/README.md` when present with a link to the redesign report.

## Hard Blocks

- Do not stop after creating mockups.
- Do not ask the user to run `npm`, `composer`, `php artisan`, migrations, cache clears, build commands, queue/runtime restarts, or sandbox restarts.
- Do not announce completion without a public sandbox URL and verification result.
- Do not change database schema, authorization rules, business logic, seeded credentials, or app workflows unless explicitly requested.
- Do not use a generic Tailwind dashboard. The implemented app must visibly match the Attio Finance HTML Effectiveness CRM source.
