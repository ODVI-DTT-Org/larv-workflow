---
name: larv:redesign-impeccable-higgsfield
description: Redesign the current Laravel frontend from Impeccable directions with Higgsfield comps, chosen on a public sandbox board.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Argument: optional focus such as `<page>`, `<role>`, or `<workflow>`. If omitted, redesign the whole frontend UI.

Invoke the `larv-redesign-impeccable-higgsfield` skill.

## Contract

- First run `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`. Exit 1: stop and point to `/larv:design-setup`. Exit 3: continue and say why; comps are generated only when the balance covers the priced round, otherwise the board uses zero-credit wireframe cards.
- Directions come from Impeccable; each dealt direction gets one Higgsfield comp (`nano_banana_pro`, 2k, ~2 credits). Declined challengers get no comp.
- All steps run through `bash <larv-plugin-root>/scripts/design-directions.sh <step> "$PWD" <out>`; the options board is served on a public 9000-9499 port and its URL is in `<out>/board-url.txt`.
- The user picks with `pick: <id>`; then the picked comp becomes `DESIGN.md` and the production frontend is redesigned.
- Preserve all backend behavior, routes, policies, validation, migrations, seeders, and user flows unless the user explicitly asks for functional changes.
- Rebuild every screen for every role; run the build, cache/view commands, sandbox restart/probe and desktop + mobile screenshot checks yourself. Show the public sandbox URL.

## Required Artifacts

- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/directions/` (options.json, prompts/, comps/, board/, board-url.txt, decision.md)
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/design-source.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/screen-inventory.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/implementation-report.md`
- `docs/larv/redesigns/<timestamp>-impeccable-higgsfield/visual-parity.md`
- `PRODUCT.md`, `DESIGN.md`
