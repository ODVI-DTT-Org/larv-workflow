---
name: larv-design
description: Phase 3 - design recommendation memo, user chooses from Attio-first recommendations or a specific direction, mockup server renders interactive HTML Effectiveness mockups for this app's screens, user converges on one design, brand spec finalized.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-design

Help the user pick a visual design and finalize a brand spec. The user does the taste work in their own browser; the agent does the grounding work and serves a comparison harness for the user's actual screens. For any visual brainstorm, design template recommendation, or mockup template selection, use the bundled Attio Venture HTML Effectiveness gallery (`attio-venture-html-effectiveness/`, alias of `attio-venture-html-effectiveness-design/`) as the primary design reference and single source of truth unless the user explicitly chooses Attio Finance or another supplied direction. Phase 3 mockups are interactive Attio Venture HTML Effectiveness prototypes, not static screenshots or plain page comps.

## Inputs

- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/00-discuss/design-preferences.md`
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/c4-*.md`

## Step sequence

### Mode: impeccable-higgsfield

If `docs/larv/00-discuss/design-preferences.md` records `mode: impeccable-higgsfield`, replace steps 2–8 with the directions round, using `OUT=docs/larv/03-design/directions/` and `D=<larv-plugin-root>/scripts/design-directions.sh`:

1. `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"`: exit 1 stops the phase with `status: failed`; exit 3 continues (say why): comps are generated only when the balance covers the priced round, otherwise the board shows zero-credit wireframe cards.
2. `bash $D context "$PWD" $OUT` (writes PRODUCT.md only; DESIGN.md waits for the pick).
3. `bash $D seed "$PWD" $OUT`; author `$OUT/options.json` and `$OUT/prompts/<id>.txt` exactly as in `skills/larv-redesign-impeccable-higgsfield/SKILL.md` steps 5–6. Add the Attio workspace baseline (`templates/attio-crm-workspace.html`) as the `canonCard`.
4. `LARV_HIGGSFIELD_CREDIT_CAP=<credit_cap from design-preferences.md> bash $D cost "$PWD" $OUT` (exit 4: ask the user, rerun `cost` and `comps` with `LARV_DESIGN_CONFIRMED_SPEND=<total>`). Higgsfield missing or signed out: `cost` records a zero-credit fallback and exits 0. When the user's cap is below the round total, offer to comp only the lead card with `--only <lead-id>`, and leave the other cards as wireframes.
5. Ask for the mockup port as in step 5 below, then `bash $D board "$PWD" $OUT`, `LARV_DESIGN_PORT_KIND=mockup-port bash $D serve "$PWD" $OUT <port|auto>`, `LARV_HIGGSFIELD_CREDIT_CAP=<credit_cap from design-preferences.md> bash $D comps "$PWD" $OUT` (plus the same `LARV_DESIGN_CONFIRMED_SPEND` as `cost`), `bash $D board "$PWD" $OUT`. Print `$OUT/board-url.txt` and the credit balance `comps` printed before and after.
6. User picks (`pick: <id>`); `bash $D pick "$PWD" $OUT <id>`. Copy `$OUT/decision.md` to `docs/larv/03-design/design-decision.md` with the user's rationale.
7. Build one interactive HTML prototype of the picked comp under `docs/larv/03-design/mockups/<pick-slug>/` (`index.html` harness, `interaction-map.md`, working navigation and primary actions, app logo and favicon), plus the mockup root `docs/larv/03-design/mockups/index.html` linking to that pick set's `index.html` with the app logo and favicon links, and serve it with step 7's mockup-server block on the same port (stop the board first: `LARV_DESIGN_PORT_KIND=mockup-port bash $D stop "$PWD" $OUT`). Only one prototype is built: the picked comp's.
8. Continue with step 9. Write `DESIGN.md` from the picked comp and brand spec; do not regenerate it with `impeccable.sh context`.

In this mode the picked comp and its single prototype are the visual source of truth, and DESIGN.md is written from them. Any rule elsewhere in this skill that makes Attio mockups the visual source of truth, derives DESIGN.md from the brand spec with `impeccable.sh context`, or forbids replacing Attio mockups with an Impeccable world roll applies only when the design mode is not `impeccable-higgsfield`.

### 1. Frame the design ask

Read inputs above, including the Phase 0 design preference. Write a one-paragraph design brief and confirm with the user. If `docs/larv/00-discuss/design-preferences.md` says `mode: agent-recommendations`, start from that saved preference instead of asking whether recommendations are wanted again. If it says `mode: user-specified`, restate the saved style/template/brand direction and ask only if it is ambiguous. If it says `mode: decide-later` or the file is missing, ask the normal design preference question in Step 2.

### 2. Recommendation memo (the agent's job)

First honor `docs/larv/00-discuss/design-preferences.md`. If Phase 0 already captured `agent-recommendations`, write recommendations without re-asking this choice. If Phase 0 captured `user-specified`, write a decision memo around the saved direction. Only if Phase 0 captured `decide-later` or no usable preference exists, ask the user whether they want agent recommendations based on the PRD/domain docs or whether they already have a specific direction. Use this prompt:

> "For the visual direction, do you want me to recommend designs based on your idea/PRD, or do you already have a specific style/template in mind? My default recommendation will start with the Attio workspace design, then apply the Attio Venture HTML Effectiveness reference (`attio-venture-html-effectiveness/`) unless Attio Finance or another direction is a better fit."

If the user wants recommendations, write `docs/larv/03-design/recommendations.md` with four sections:

- **Archetype call** - e.g., "B2B SaaS, admin-heavy, table-dense, multi-tenant. Audience: ops teams." (cite the brief)
- **Look for** - concrete criteria for evaluation: "good empty states (your invite flow shows these often)", "table density treatments that don't break at 50 rows"
- **Avoid** - opposites with reasons: "skip playful/whimsical (B2B audience, billing scope)"
- **Starting points** - always put `templates/attio-crm-workspace.html` first as "Attio workspace baseline", then put `attio-venture-html-effectiveness/` as the primary HTML Effectiveness implementation reference, then add Attio Finance or other user-specified/local templates only when the domain fit is stronger. Include the recommended Design Choice System variant and a one-line reason each. Flag each as a starting point only.

If the user already has a specific style/template in mind, still write `recommendations.md`, but make it a short decision memo that records their direction and shows how it compares to the default Attio workspace baseline.

### Bundled Design Choice System

The plugin ships local Attio/Attio Venture HTML Effectiveness galleries that can be used for larv docs preview mockups, new-app design templates, and visual brainstorm recommendations. These local galleries replace external design browsing during Phase 3.

Default to `templates/attio-crm-workspace.html` as the first recommendation for every Phase 3 design selection. It is the Attio workspace baseline and contains reusable primitives for the shell, sidebar, command bar, metric strip, record table, and agent activity rail. Use `attio-venture-html-effectiveness/` as the canonical Attio Venture HTML Effectiveness design reference for generated mockups, and use Attio Finance only when its financial-services fit is stronger or the user chooses it.

| Variant | Brand fit | Palette | Gallery path |
|---|---|---|---|
| Custom | Custom projects that need a neutral Attio-aligned starting point | Purple gradient, `#667eea` to `#764ba2` | Available through each gallery's `setup.html` Design Choice System |
| Attio Finance | Financial services, credit, lending, banking, collections, payment, and risk workflows | Gold `#FAA000` plus blue `#1B5E7F` | `attio-finance-html-effectiveness-design/` |
| Attio Venture | Venture capital, investment, growth, founder, portfolio, advisory, and default B2B SaaS workflows | Brown `#9B6632` plus tan `#ECCDAE` | `attio-venture-html-effectiveness/` (alias of `attio-venture-html-effectiveness-design/`) |

Each gallery contains 23 self-contained templates with a shared Attio design language: restrained surfaces, dense but readable app layouts, tight component states, subtle borders, disciplined spacing, and brand-specific tokens layered over the same structure. Prefer these references when the app archetype matches their domain, when the user asks for a faster mockup path, or when a local visual representation is useful. Especially consider:

- `21-credit-officer-crm.html` for loan, credit, approval, underwriting, and risk dashboards.
- `22-sales-crm.html` for sales pipeline, business development, investor relations, partner, and deal-flow dashboards.
- `23-service-crm.html` for support, servicing, customer success, ticket queue, and SLA workflows.
- `05-design-system.html` and `06-component-variants.html` for brand token and component inventory references.
- `02-exploration-visual-designs.html`, `07-prototype-animation.html`, and `08-prototype-interaction.html` for visual brainstorm and interaction mockup directions.

When these galleries are used, copy or adapt the relevant HTML/CSS/JavaScript patterns into `docs/larv/03-design/mockups/<pick-slug>/`. For Attio Venture mockups, record `source_path: attio-venture-html-effectiveness/<template-file>` even though the filesystem alias points to `attio-venture-html-effectiveness-design/`. Do not serve mockups directly from the plugin gallery directory; generated project mockups must still live under `docs/larv/03-design/mockups/` and pass the normal mockup server gate.

Every generated mockup set must preserve product branding in two places:

- **App logo:** visible inside the app shell, header, sidebar, login, or equivalent primary navigation area. Use the selected project logo if the user provided one; otherwise adapt the selected gallery logo (`attio-venture-logo.png` from `attio-venture-html-effectiveness/` or `attio-finance-logo.png`) or create a simple text/mark lockup for custom/Attio projects.
- **URL logo:** browser favicon links in every generated HTML mockup: `<link rel="icon" type="image/png" href="...">` and `<link rel="apple-touch-icon" href="...">`. The favicon asset must resolve from the served mockup directory, not from a plugin-only absolute path.

### 3. User chooses a direction

Print:

> "My first recommendation is the Attio workspace baseline: `templates/attio-crm-workspace.html`, implemented with the Attio Venture HTML Effectiveness reference at `attio-venture-html-effectiveness/`. I also listed any relevant Attio Finance or user-specified options in `docs/larv/03-design/recommendations.md`. Choose one direction with `pick: <path-or-slug>`, ask for `attio plus recommendations`, or tell me a specific style/template you want instead."

Do not force the user to pick three designs. One chosen direction is enough to continue. Do not require any external inspiration site during Phase 3. Local gallery picks are read from the plugin repo only after the user selects them.

### 4. Agent fetches and confirms picks

When the user replies, resolve the selected direction:

- `pick: templates/attio-crm-workspace.html` or any Attio baseline slug: use the Attio workspace baseline.
- `attio plus recommendations`: generate an Attio baseline pick plus the Attio Venture HTML Effectiveness reference and 1-3 domain-relevant Attio Finance/custom recommendations, then ask the user to choose one.
- `pick: attio-venture-html-effectiveness/<file>` or `pick: attio-venture-html-effectiveness-design/<file>`: read the Attio Venture selected HTML file and record the pick using the `attio-venture-html-effectiveness/<file>` source path.
- `pick: attio-finance-html-effectiveness-design/<file>`: read that selected HTML file.
- A specific style/template in free text: summarize the direction and ask only if the source is ambiguous.

For each selected direction, write a short extracted summary at `docs/larv/03-design/picks/<slug>.md`, and include frontmatter with `source_path` when a local file exists, `gallery_variant`, `template_count` when applicable, `attio_unified: true`, and `attribution`. Print a confirmation table summarizing the selected direction(s).

### 5. Ask for and allocate mockup port

Before allocating or exposing the mockup server, ask the user:

> "Which public VM port do you want for the mockup server? Use `auto` for automatic allocation. Valid range: 9000-9499."

If the user chooses a number, use it as `requested_mockup_port`. If they choose `auto`, leave it empty.

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/static_server.sh
. scripts/lib/design_tools.sh

LARV_VM_HOST="$(design_public_host)" || { echo "ERROR: no public host; set LARV_VM_HOST to this server's public address" >&2; exit 1; }
export LARV_VM_HOST

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
requested_mockup_port="${requested_mockup_port:-}"
if [ -n "$requested_mockup_port" ]; then
    case "$requested_mockup_port" in
        ''|*[!0-9]*) echo "ERROR: mockup port must be numeric or auto" >&2; exit 1 ;;
    esac
    if [ "$requested_mockup_port" -lt 9000 ] || [ "$requested_mockup_port" -gt 9499 ]; then
        echo "ERROR: mockup port must be in 9000-9499" >&2
        exit 1
    fi
    if ! verify_allocation "$requested_mockup_port" mockup "$slug"; then
        echo "ERROR: requested mockup port $requested_mockup_port is not available. Ask the user for another port." >&2
        exit 1
    fi
    mockup_port="$requested_mockup_port"
else
    mockup_port=$(allocate_port mockup "$slug")
fi
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
if ! static_server_check_remote_deps "$ssh_target"; then
    echo "ERROR: runtime missing required static-server tools: php, curl, ss, or setsid" >&2
    release_port_reservation mockup "$mockup_port" "$slug" || true
    exit 1
fi
if ! static_server_open_firewall "$ssh_target" "$mockup_port"; then
    echo "ERROR: firewall rule for mockup port $mockup_port was not confirmed" >&2
    release_port_reservation mockup "$mockup_port" "$slug" || true
    exit 1
fi
```

### 6. Generate Attio-style mockups

Render 5-7 key screens per pick at `docs/larv/03-design/mockups/<pick-slug>/<screen>.html` using the bundled Attio-style galleries and `templates/attio-crm-workspace.html` as reference material.

The mockups must be high-fidelity, interactive Attio Venture HTML Effectiveness product prototypes for this app's actual domain, not generic landing pages, static screenshots, or disconnected page comps. Each mockup set must include realistic navigation, dense states, representative data, and the primary workflows from the domain docs.

Use the Attio Venture HTML Effectiveness templates in `attio-venture-html-effectiveness/` as the concrete structure, interaction, and visual vocabulary source unless the user explicitly selected Attio Finance or another supplied design. Preserve useful density, tables, toolbars, filters, cards, badges, forms, modals, CRM interaction patterns, sidebar/header navigation, tabs, command bars, drawers, empty states, and hover/focus states, but rewrite labels, records, routes, and workflow states for the current app's domain. The Design Choice System variant selected for the mockup must be recorded in `design-decision.md` and reflected in `brand-spec.md`.

In addition to each pick set's own `index.html`, the mockup root `docs/larv/03-design/mockups/index.html` is required. It links to every pick set's `index.html` and carries the app logo and favicon links, so the served root itself resolves instead of 404ing.

Each mockup set must include:

- `index.html` as a clickable navigation harness that links to every screen in the set and names the main workflow paths.
- Working `<a href="...">` navigation between screens. Primary sidebar/header/menu links must not be dead placeholders.
- Clickable primary actions for the app's core workflows. Use either real links to another mockup screen or small JavaScript interactions for tabs, filters, modals, drawers, row selection, status changes, form state, and toast/empty/loading/error states.
- Route-like file names that correspond to planned app routes where possible, so `visual-implementation-contract.md` can map production routes to exact HTML files.
- A short `interaction-map.md` listing each role, start screen, clickable path, expected end screen/state, and which HTML files implement the path.

Do not accept static-only mockups. If a screen contains a primary action, navigation item, tab, filter, or row action, it must either navigate or visibly change state in the prototype.

If the selected direction is Attio Venture or Attio Finance, copy the relevant logo asset into the mockup output and wire it as both the visible app logo and the favicon/URL logo. If the selected direction is Attio/custom and no logo exists, create a lightweight project wordmark or mark in the mockup assets and use that same asset consistently for the app shell and favicon.

**Feasibility fallback (per spec section 9.1 step 6):** if the selected visual direction cannot sustain consistency across all picks x screens, degrade to one interactive mockup per pick (dashboard plus at least one clickable workflow path). Record the decision in `docs/larv/03-design/recommendations.md`. Do not degrade to static images or non-clickable HTML.

### 7. Mockup server (probe-before-announce)

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/static_server.sh
. scripts/lib/probe.sh
. scripts/lib/runtime_gate.sh
. scripts/lib/design_tools.sh

LARV_VM_HOST="$(design_public_host)" || { echo "ERROR: no public host; set LARV_VM_HOST to this server's public address" >&2; exit 1; }
export LARV_VM_HOST

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
mockup_port="$(yq -r '.execution.allocations[] | select(.kind == "mockup-port") | .value' docs/larv/STATE.yaml | tail -1)"
test -n "$mockup_port" && [ "$mockup_port" != "null" ]
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
project_root="$(pwd -P)"
mockups_dir="$project_root/docs/larv/03-design/mockups"
test -d "$mockups_dir"
test -f "$mockups_dir/index.html"
trap 'release_port_reservation mockup "$mockup_port" "$slug" || true' EXIT

if ! verify_allocation "$mockup_port" mockup "$slug"; then
    echo "ERROR: mockup port $mockup_port was taken before server start" >&2
    exit 1
fi
static_server_start "$ssh_target" "$mockup_port" \
    "$mockups_dir" \
    "larv-mockups-$slug"

if ! probe_url_inside "$ssh_target" "$mockup_port" static; then
    echo "ERROR: inside-VM probe failed for mockup port" >&2
    static_server_stop "$ssh_target" "larv-mockups-$slug"
    exit 1
fi
mockup_url="$(static_server_url "$mockup_port")/"
case "$mockup_url" in
    http://127.0.0.1:*|http://localhost:*|http://sandbox.example.com:*)
        echo "ERROR: refusing to announce local-only mockup URL: $mockup_url" >&2
        exit 1
        ;;
esac
if ! probe_with_retries "$mockup_url" static; then
    echo "ERROR: external probe failed" >&2
    static_server_stop "$ssh_target" "larv-mockups-$slug"
    exit 1
fi
release_port_reservation mockup "$mockup_port" "$slug" || true
trap - EXIT
printf "%s\n" "$mockup_url" > docs/larv/03-design/mockup-url.txt
runtime_gate_require_phase_url . design "$LARV_VM_HOST"
echo "Mockups ready at $mockup_url"
```

## Mandatory completion gate

The mockup server is not optional. Do not proceed to brand finalization, `design-decision.md`, `brand-spec.md`, `ui-design.md`, auto-commit, or `status: complete` until all of these are true:

- At least one HTML mockup exists under `docs/larv/03-design/mockups/`.
- `docs/larv/03-design/mockups/index.html` exists at the mockup root, links to every pick set's `index.html`, and carries the app logo and favicon links.
- The mockups are explicitly based on the Attio Venture HTML Effectiveness reference (`attio-venture-html-effectiveness/`) unless the user chose Attio Finance or another supplied direction, and include `index.html` as a clickable navigation harness.
- `docs/larv/03-design/mockups/<pick-slug>/interaction-map.md` exists for every pick and lists role/workflow click paths.
- Every primary navigation item, primary action, tab, filter, modal trigger, and row action in the mockups either links to another mockup HTML file or visibly changes state with JavaScript.
- A click-through smoke check was performed on the served mockup URL for the main workflow paths; broken links, dead primary actions, and disconnected screens were fixed before user review.
- Every served HTML mockup includes a visible app logo and browser URL logo links (`rel="icon"` and `rel="apple-touch-icon"`) whose assets resolve from the mockup directory.
- The user was asked for the mockup port before allocation/exposure. If they provided a port, it was verified before use; otherwise `mockup_port` was allocated through `allocate_port mockup "$slug"`.
- `mockup_port` was recorded as `mockup-port` in `STATE.yaml.execution.allocations`.
- `verify_allocation "$mockup_port" mockup "$slug"` succeeded immediately before server start.
- `static_server_check_remote_deps "$ssh_target"` passed for `php`, `curl`, `ss`, and `setsid` on the local VM runtime.
- `static_server_open_firewall "$ssh_target" "$mockup_port"` succeeded or no local `ufw` is installed.
- The mockups are served from `docs/larv/03-design/mockups` in the current project.
- `static_server_start` succeeded.
- `probe_url_inside "$ssh_target" "$mockup_port" static` succeeded.
- `probe_with_retries "$mockup_url" static` succeeded.
- `release_port_reservation mockup "$mockup_port" "$slug"` ran after the server bound and probes succeeded.
- `docs/larv/03-design/mockup-url.txt` exists and contains the external URL.
- `runtime_gate_require_phase_url . design "$LARV_VM_HOST"` succeeded.
- The URL was printed to the user.
- In mode `impeccable-higgsfield`: `docs/larv/03-design/directions/board-url.txt` was probe-confirmed and shown, `directions/decision.md` exists, the picked comp sidecar has `approved: true` (unless the pick was a wireframe card), and the single prototype of the picked comp satisfies every mockup bullet above.

If any item fails or cannot be performed, stop immediately and return:

```yaml
status: failed
mockup_url: null
errors_unresolved:
  - "Phase 3 mockup server was not started and probe-confirmed."
```

### 8. User picks one (or hybrid)

User replies in chat: `pick: <slug>` or `hybrid: <slug-A> layout + <slug-B> palette`. If hybrid, regenerate the mockups from the selected local references and re-probe; iterate until the user commits with a single slug.

Record decision at `docs/larv/03-design/design-decision.md` with rationale (free-text from the user; the picks not chosen and why if the user volunteered).

### 9. Finalize brand spec

Finalize the chosen local design direction. Outputs:

- `docs/larv/03-design/brand-spec.md`
- `docs/larv/03-design/ui-design.md`
- `docs/larv/03-design/visual-implementation-contract.md`

`visual-implementation-contract.md` is mandatory. It is the bridge from mockups to production implementation and must include:

- chosen mockup path(s) and the exact screens each app route should match
- app logo and favicon/URL logo asset paths, including the final Laravel implementation location and required Blade/Inertia/Filament `<link rel="icon">` and `<link rel="apple-touch-icon">` tags
- interaction-map path and interaction parity requirements: navigation links, role-specific entry points, primary actions, tabs, filters, modals/drawers, row actions, loading/empty/error states, and expected end states
- typography scale, font choices, color tokens, spacing, radius, borders, shadows, and icon rules
- layout shell requirements: navigation, sidebar/header behavior, max widths, density, empty/loading/error states
- component inventory: buttons, cards, tables, forms, filters, badges, charts, modals, toasts, and their visual states
- implementation notes for Laravel Blade/Livewire/Inertia/Filament as applicable
- route-to-mockup parity matrix with columns: route, viewport, reference mockup file, required seeded state, required interactions, screenshot output path, pass/fail criteria
- screenshot parity checklist for desktop and mobile. The expectation is same visual output as the chosen mockups: same layout composition, typography hierarchy, color system, spacing rhythm, component styling, interaction states, and populated-data feel. Small differences are allowed only for real framework constraints, dynamic content, or accessibility fixes, and must be documented.
- forbidden generic defaults, including unstyled starter pages, default Tailwind gray panels, oversized marketing heroes for app dashboards, and placeholder-only empty screens

### 10. Server lifetime

Stays up through Phase 6 for reference. Released after handoff/docsite review, or `/larv:design teardown-server`.

### 11. Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 3: design approved (pick=$(grep -oE 'pick: [^ ]+' docs/larv/03-design/design-decision.md | head -1 | sed 's/pick: //'))"
```

## What you do not do

- Do not ask the user to browse external inspiration sites during Phase 3.
- Do not create static-only mockups, screenshot boards, or disconnected HTML pages. Mockups must be interactive, clickable, navigable Attio Venture HTML Effectiveness prototypes unless the user explicitly selected Attio Finance or another supplied design.
- Do not announce the mockup URL until both inside and outside probes succeed.
- Do not announce `127.0.0.1` or `localhost`; always print the external URL `http://sandbox.example.com:<port>/`.
- Do not pick the design for the user. Provide recommendations, never decisions.
- Do not mark Phase 3 complete without a probe-confirmed `mockup_url`.
- Do not mark Phase 3 complete without `docs/larv/03-design/visual-implementation-contract.md`.

## Subagent return contract

```yaml
status: complete
mockup_url: "http://sandbox.example.com:<port>/"
files_written:
  - docs/larv/03-design/recommendations.md
  - docs/larv/03-design/picks/<slug>.md  # one per pick
  - docs/larv/03-design/mockups/<slug>/...
  - docs/larv/03-design/mockups/<slug>/interaction-map.md
  - docs/larv/03-design/mockup-url.txt
  - docs/larv/03-design/design-decision.md
  - docs/larv/03-design/brand-spec.md
  - docs/larv/03-design/ui-design.md
  - docs/larv/03-design/visual-implementation-contract.md
  - docs/larv/03-design/directions/options.json      # mode impeccable-higgsfield
  - docs/larv/03-design/directions/comps/<id>.png    # mode impeccable-higgsfield
  - docs/larv/03-design/directions/board-url.txt     # mode impeccable-higgsfield
  - docs/larv/03-design/directions/decision.md       # mode impeccable-higgsfield
state_updates:
  execution.allocations: [..., { kind: mockup-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
