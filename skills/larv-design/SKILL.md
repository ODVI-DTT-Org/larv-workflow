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

mockup_port=$(allocate_port mockup)
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
static_server_open_firewall "$ssh_target" "$mockup_port"
```

### 6. Huashu generates mockups

Invoke the bundled `huashu-design` skill for each pick. Render 5-7 key screens per pick at `docs/larv/03-design/mockups/<pick-slug>/<screen>.html`.

**Feasibility fallback (per spec section 9.1 step 6):** if huashu cannot sustain consistency across all picks x screens, degrade to one mockup per pick (hero/dashboard only). Record the decision in `docs/larv/03-design/recommendations.md`.

### 7. Mockup server (probe-before-announce)

```bash
. scripts/lib/probe.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
ssh "$ssh_target" "mkdir -p /srv/larv/$slug/mockups"
rsync -avz docs/larv/03-design/mockups/ "$ssh_target:/srv/larv/$slug/mockups/"

static_server_start "$ssh_target" "$mockup_port" \
    "/srv/larv/$slug/mockups" \
    "larv-mockups-$slug"

if ! probe_url_inside "$ssh_target" "$mockup_port" static; then
    echo "ERROR: inside-VM probe failed for mockup port" >&2
    return 1
fi
if ! probe_with_retries "$(static_server_url "$mockup_port")" static; then
    echo "ERROR: external probe failed" >&2
    return 1
fi
echo "Mockups ready at $(static_server_url "$mockup_port")"
```

### 8. User picks one (or hybrid)

User replies in chat: `pick: <slug>` or `hybrid: <slug-A> layout + <slug-B> palette`. If hybrid, regenerate via huashu and re-probe; iterate until the user commits with a single slug.

Record decision at `docs/larv/03-design/design-decision.md` with rationale (free-text from the user; the picks not chosen and why if the user volunteered).

### 9. Finalize brand spec

Invoke huashu-design with the chosen pick only. Outputs:

- `docs/larv/03-design/brand-spec.md`
- `docs/larv/03-design/ui-design.md`

### 10. Server lifetime

Stays up through Phase 6 for reference. Released by Phase 7 provisioning, or `/larv:design teardown-server`.

### 11. Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 3: design approved (pick=$(grep -oE 'pick: [^ ]+' docs/larv/03-design/design-decision.md | head -1 | sed 's/pick: //'))"
```

## What you do not do

- Do not WebFetch from getdesign.md before the user provides explicit picks.
- Do not announce the mockup URL until both inside and outside probes succeed.
- Do not pick the design for the user. Provide recommendations, never decisions.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/03-design/recommendations.md
  - docs/larv/03-design/picks/<slug>.md  # one per pick
  - docs/larv/03-design/mockups/<slug>/...
  - docs/larv/03-design/design-decision.md
  - docs/larv/03-design/brand-spec.md
  - docs/larv/03-design/ui-design.md
state_updates:
  execution.allocations: [..., { kind: mockup-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
