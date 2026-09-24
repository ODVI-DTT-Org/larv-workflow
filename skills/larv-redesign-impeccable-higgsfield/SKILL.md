---
name: larv-redesign-impeccable-higgsfield
description: Use when the user types /larv:redesign-impeccable-higgsfield or asks to redesign a Laravel frontend using Impeccable directions and Higgsfield comps presented on a sandbox URL.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-redesign-impeccable-higgsfield

Redesign the current Laravel frontend: Impeccable proposes grounded directions, Higgsfield renders one comp per direction, the user picks on a public sandbox board, then you implement the pick. This is a production app redesign command, not a mockup-only command. The same steps work in Claude Code, Grok and Codex: every action is a script call or a question to the user.

`D=<larv-plugin-root>/scripts/design-directions.sh`, `R=docs/larv/redesigns/<YYYYMMDD-HHMM>-impeccable-higgsfield`, `OUT=$R/directions`. When the user states a credit cap, prefix every `cost` and `comps` call with `LARV_HIGGSFIELD_CREDIT_CAP=<cap>` (default 10).

## Workflow

1. **Readiness.** `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`. Exit 1: stop, show the output, point to `/larv:design-setup`. Exit 3: tell the user why (signed out, low credits, or not installed) and that comps are generated only when the balance covers the priced round; otherwise the board uses zero-credit wireframe cards. Then continue. Never install tools or sign in here.
2. **Inventory.** Verify this is a Laravel app. Create `$R/`. Write `$R/screen-inventory.md`: every screen for every role (lists, detail pages, create/edit forms, dashboards, admin/settings, profile, dialogs, public pages, empty/loading/error states). Apply the focus argument only to ordering, not to coverage, unless the user limited scope.
3. **Product context.** `bash $D context "$PWD" $OUT`. On `NEEDS_PRODUCT_MD`, read the Impeccable skill's `reference/init.md` and write `PRODUCT.md` from the app and the user's answers (platform, users, purpose, constraints, brand commitments, what must be preserved), then rerun.
4. **Directions.** `bash $D seed "$PWD" $OUT`. Read `$OUT/seed.txt` and the Impeccable skill's `reference/new-work.md` direction-round rules. Author `$OUT/options.json` (shape: `impeccable serve-question --schema`; fields `id,label,thesis,palette,viewport,risk`, optional `kicker,verdict,kept,case,surface`, plus `canonCard`). Three dealt directions as full cards (lead kicker `THE ROLL`), declined challengers with `verdict: "declined"` and a `kept` line, and the category standard as `canonCard`. If `$OUT/fallback` says `seed-unavailable`, write three directions grounded in PRODUCT.md yourself.
5. **Comp prompts.** For each non-declined card write `$OUT/prompts/<id>.txt`: structure-led description of the app's most important screen in that direction, the real product name, the card's palette and type, fictional sample data labeled "Sample data", no invented features, claims, charts or maps. Frame: desktop 3:2 unless the card's `surface` is `phone` (9:16).
6. **Reference image (optional).** A screenshot of the current app may anchor comps only if it shows seeded or fictional data. Save it as `$OUT/refs/reference.png` and create `$OUT/refs/FICTIONAL-DATA-CONFIRMED` only after checking every visible name, token, and attachment is fictional. Never upload live records, receiver links, tokens or attachments to Higgsfield.
7. **Cost.** `bash $D cost "$PWD" $OUT` (as `LARV_HIGGSFIELD_CREDIT_CAP=<cap> bash $D cost ...` when the user gave a cap). Exit 4: show the total and the cap, ask the user; on approval rerun `cost` and later `comps` with `LARV_DESIGN_CONFIRMED_SPEND=<total>`. Report credits before spending. `comps` refuses to run (exit 4) without a matching, within-cap `cost.json`; when Higgsfield is missing or signed out, `cost` records a zero-credit fallback and `comps` renders wireframe cards.
8. **Board first, then comps.** `bash $D board "$PWD" $OUT` then `bash $D serve "$PWD" $OUT auto` (or the port the user asked for). Print the URL from `$OUT/board-url.txt`. Then `bash $D comps "$PWD" $OUT` (same `LARV_HIGGSFIELD_CREDIT_CAP` / `LARV_DESIGN_CONFIRMED_SPEND` prefix as `cost`) and `bash $D board "$PWD" $OUT` again (the server serves the updated files). `comps` prints the balance before and after; tell the user the comps are in and the credits used. If the balance is below the round total, `comps` spends nothing and the cards stay wireframes (`low-credits`).
9. **Pick.** Ask the user to choose (`pick: <id>`, or the harness question tool listing the cards). Steer/re-roll only on request; every re-roll reruns `bash $D seed "$PWD" $OUT --from <key> --reroll <n>` (`<key>` from the `key:` line of the first `seed.txt`, `<n>` = 1, 2, ...) → options.json and prompts → cost (ask) → comps → board. Cards whose prompt changed are re-priced and regenerated; unchanged cards keep their comp. Then `bash $D pick "$PWD" $OUT <id>`.
10. **DESIGN.md.** Write `DESIGN.md` from the picked card and comp: tokens (color, type, radius, spacing), shell geometry, component patterns, and the rule "every screen is rebuilt". Write `$R/design-source.md` naming the comp file, options.json, and why the pick fits.
11. **Implement.** Apply the redesign to the actual frontend code. Preserve backend behavior, routes, forms, Livewire/Filament actions, validation names, policies, data and workflows. Rebuild every screen in `screen-inventory.md`; a screen on its old markup under new CSS is not redesigned. Keep all roles in one coherent layout. Keep the app logo and favicon.
12. **Verify.** Run dependency install when needed, asset build, Laravel view/cache clears, tests covering touched surfaces, sandbox restart, and public URL probe. Take Playwright desktop and mobile screenshots and compare them with the picked comp; fix drift, broken layouts, inaccessible text and dead actions. Run `bash <larv-plugin-root>/scripts/impeccable.sh detect "$PWD"`.
13. **Report.** Write `$R/visual-parity.md` (screens checked, comp reference, accepted differences, fixes) and `$R/implementation-report.md` (files changed, commands run, sandbox URL, board URL, credits spent, remaining risks). List every screen per role with its coverage. Update `DOCS.md` or `docs/user-manual/README.md` when present.
14. **Board lifetime.** Leave the board running until the user confirms the implementation, then stop it: `bash $D stop "$PWD" $OUT` (reads the slug and port from `$R/run.yaml` or STATE.yaml, stops the server and releases the port).

## Hard Blocks

- Do not stop after the board; the pick must be implemented.
- Do not ask the user to run `npm`, `composer`, `php artisan`, migrations, cache clears, build commands or sandbox restarts. The only user-run step in this whole flow is a Higgsfield sign-in, and that belongs to `/larv:design-setup`.
- Never run `higgsfield auth token`. Never run `higgsfield auth login` yourself.
- Do not spend above the cap without the user's explicit yes; do not re-roll on your own.
- Do not upload live data to Higgsfield (see step 6).
- Do not announce localhost, 127.* or sandbox.example.com URLs.
- Do not change database schema, authorization rules, business logic, seeded credentials, or app workflows unless explicitly requested.
