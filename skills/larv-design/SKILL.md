---
name: larv-design
description: Phase 3 - design recommendation memo, user browses getdesign.md in their own browser to pick >=3 designs, agent fetches picks, mockup server renders this app's screens in each picked style, user converges on one design, brand spec finalized.
---

# larv-design

Help the user pick a visual design and finalize a brand spec. The user does the taste work in their own browser; the agent does the grounding work and serves a comparison harness for the user's actual screens.

## Inputs

- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/c4-*.md`

## Step sequence

### 1. Frame the design ask

Read inputs above. Write a one-paragraph design brief and confirm with the user.

### 2. Recommendation memo (the agent's job)

Write `docs/larv/03-design/recommendations.md` with four sections:

- **Archetype call** - e.g., "B2B SaaS, admin-heavy, table-dense, multi-tenant. Audience: ops teams." (cite the brief)
- **Look for** - concrete criteria for evaluation: "good empty states (your invite flow shows these often)", "table density treatments that don't break at 50 rows"
- **Avoid** - opposites with reasons: "skip playful/whimsical (B2B audience, billing scope)"
- **Starting points on getdesign.md** - 3-5 specific page URLs that match the archetype, plus 2-3 search keywords. Flag each as a starting point only.

### 3. User browses on their own

Print:

> "Open https://getdesign.md/ in your browser, use the suggestions in `docs/larv/03-design/recommendations.md` as starting points, and come back with **at least 3 picks** (URLs or slugs). Reply `picked: <urls>` when ready, or `more recommendations` if my suggestions don't fit."

Do NOT WebFetch yet.

### 4. Agent fetches and confirms picks

When the user replies, WebFetch each pick's `.md` from getdesign.md and cache at `docs/larv/03-design/picks/<slug>.md` with frontmatter (`source_url`, `fetched_at`, `attribution`). Print a confirmation table summarizing each pick.

### 5. Allocate mockup port

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/static_server.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
mockup_port=$(allocate_port mockup "$slug")
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
if ! static_server_check_remote_deps "$ssh_target"; then
    echo "ERROR: runtime missing required static-server tools: php, tmux, curl, or ss" >&2
    release_port_reservation mockup "$mockup_port" "$slug" || true
    exit 1
fi
if ! static_server_open_firewall "$ssh_target" "$mockup_port"; then
    echo "ERROR: firewall rule for mockup port $mockup_port was not confirmed" >&2
    release_port_reservation mockup "$mockup_port" "$slug" || true
    exit 1
fi
```

### 6. Huashu generates mockups

Read and follow the bundled `huashu-design` skill for each pick (`bundle/huashu-design/SKILL.md`). Render 5-7 key screens per pick at `docs/larv/03-design/mockups/<pick-slug>/<screen>.html`.

The mockups must be high-fidelity product screens for this app's actual domain, not generic landing pages. Each mockup set must include realistic navigation, dense states, representative data, and the primary workflows from the domain docs.

**Feasibility fallback (per spec section 9.1 step 6):** if huashu cannot sustain consistency across all picks x screens, degrade to one mockup per pick (hero/dashboard only). Record the decision in `docs/larv/03-design/recommendations.md`.

### 7. Mockup server (probe-before-announce)

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/static_server.sh
. scripts/lib/probe.sh
. scripts/lib/runtime_gate.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
mockup_port="$(yq -r '.execution.allocations[] | select(.kind == "mockup-port") | .value' docs/larv/STATE.yaml | tail -1)"
test -n "$mockup_port" && [ "$mockup_port" != "null" ]
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
project_root="$(pwd -P)"
mockups_dir="$project_root/docs/larv/03-design/mockups"
test -d "$mockups_dir"
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
    exit 1
fi
mockup_url="$(static_server_url "$mockup_port")/"
case "$mockup_url" in
    http://127.0.0.1:*|http://localhost:*)
        echo "ERROR: refusing to announce local-only mockup URL: $mockup_url" >&2
        exit 1
        ;;
esac
if ! probe_with_retries "$mockup_url" static; then
    echo "ERROR: external probe failed" >&2
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
- `mockup_port` was allocated through `allocate_port mockup "$slug"` and recorded as `mockup-port` in `STATE.yaml.execution.allocations`.
- `verify_allocation "$mockup_port" mockup "$slug"` succeeded immediately before server start.
- `static_server_check_remote_deps "$ssh_target"` passed for `php`, `tmux`, `curl`, and `ss` on the local VM runtime.
- `static_server_open_firewall "$ssh_target" "$mockup_port"` succeeded or no local `ufw` is installed.
- The mockups are served from `docs/larv/03-design/mockups` in the current project.
- `static_server_start` succeeded.
- `probe_url_inside "$ssh_target" "$mockup_port" static` succeeded.
- `probe_with_retries "$mockup_url" static` succeeded.
- `release_port_reservation mockup "$mockup_port" "$slug"` ran after the server bound and probes succeeded.
- `docs/larv/03-design/mockup-url.txt` exists and contains the external URL.
- `runtime_gate_require_phase_url . design "$LARV_VM_HOST"` succeeded.
- The URL was printed to the user.

If any item fails or cannot be performed, stop immediately and return:

```yaml
status: failed
mockup_url: null
errors_unresolved:
  - "Phase 3 mockup server was not started and probe-confirmed."
```

### 8. User picks one (or hybrid)

User replies in chat: `pick: <slug>` or `hybrid: <slug-A> layout + <slug-B> palette`. If hybrid, regenerate via huashu and re-probe; iterate until the user commits with a single slug.

Record decision at `docs/larv/03-design/design-decision.md` with rationale (free-text from the user; the picks not chosen and why if the user volunteered).

### 9. Finalize brand spec

Read and follow `bundle/huashu-design/SKILL.md` with the chosen pick only. Outputs:

- `docs/larv/03-design/brand-spec.md`
- `docs/larv/03-design/ui-design.md`
- `docs/larv/03-design/visual-implementation-contract.md`

`visual-implementation-contract.md` is mandatory. It is the bridge from mockups to production implementation and must include:

- chosen mockup path(s) and the exact screens each app route should match
- typography scale, font choices, color tokens, spacing, radius, borders, shadows, and icon rules
- layout shell requirements: navigation, sidebar/header behavior, max widths, density, empty/loading/error states
- component inventory: buttons, cards, tables, forms, filters, badges, charts, modals, toasts, and their visual states
- implementation notes for Laravel Blade/Livewire/Inertia/Filament as applicable
- screenshot parity checklist for desktop and mobile
- forbidden generic defaults, including unstyled starter pages, default Tailwind gray panels, oversized marketing heroes for app dashboards, and placeholder-only empty screens

### 10. Server lifetime

Stays up through Phase 6 for reference. Released after handoff/docsite review, or `/larv:design teardown-server`.

### 11. Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 3: design approved (pick=$(grep -oE 'pick: [^ ]+' docs/larv/03-design/design-decision.md | head -1 | sed 's/pick: //'))"
```

## What you do not do

- Do not WebFetch from getdesign.md before the user provides explicit picks.
- Do not announce the mockup URL until both inside and outside probes succeed.
- Do not announce `127.0.0.1` or `localhost`; always print the external URL `http://31.220.79.31:<port>/`.
- Do not pick the design for the user. Provide recommendations, never decisions.
- Do not mark Phase 3 complete without a probe-confirmed `mockup_url`.
- Do not mark Phase 3 complete without `docs/larv/03-design/visual-implementation-contract.md`.

## Subagent return contract

```yaml
status: complete
mockup_url: "http://31.220.79.31:<port>/"
files_written:
  - docs/larv/03-design/recommendations.md
  - docs/larv/03-design/picks/<slug>.md  # one per pick
  - docs/larv/03-design/mockups/<slug>/...
  - docs/larv/03-design/mockup-url.txt
  - docs/larv/03-design/design-decision.md
  - docs/larv/03-design/brand-spec.md
  - docs/larv/03-design/ui-design.md
  - docs/larv/03-design/visual-implementation-contract.md
state_updates:
  execution.allocations: [..., { kind: mockup-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
