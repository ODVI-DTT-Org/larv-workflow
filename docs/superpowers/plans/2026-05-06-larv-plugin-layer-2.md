# larv plugin Layer 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Layer 2 to the larv plugin — Phase 0a DDD interview, Phase 0 Discuss Laravel ecosystem checklist, Phase 1 Laravel-DDD mapping, Phase 3 design picker + mockup server, Phase 6.5 Docsify doc-site — by filling existing skill stubs, adding two new skills, and one new shell library.

**Architecture:** Layer 2 builds on the MVP infrastructure shipped at version 0.3.0. New phases reuse `verifier.sh`, `probe.sh`, `handsoff.sh`, `gate.sh`, `git_safe.sh`, `vm.sh`, `tracker.sh`, and the STATE.yaml extensions. One new shared library (`static_server.sh`) supports the mockup server and doc-site. Two new skills (`larv-domain-interview`, `larv-docsite`) are added; three existing stubs (`larv-discuss`, `larv-domain`, `larv-design`) are filled in.

**Tech Stack:** bash, bats, yq, ssh, curl, npx (for `docsify-cli`).

**Spec reference:** `docs/superpowers/specs/2026-05-06-larv-plugin-overhaul-design.md`. Layer 2 scope is §22.2.

**Prerequisites:** MVP merged to `main` at commit `869a23e`. Confirm: `git log --oneline | grep "MVP overhaul"` returns `869a23e merge: larv plugin MVP overhaul ...`. Confirm: `bats tests/` reports 148/148 pass.

---

## File Structure

**New files:**

| Path | Responsibility |
|---|---|
| `scripts/lib/static_server.sh` | Generic static-server lifecycle (start, probe, stop) on the VM — used by mockup server and doc-site |
| `skills/larv-domain-interview/SKILL.md` | NEW — Phase 0a DDD interview |
| `skills/larv-docsite/SKILL.md` | NEW — Phase 6.5 doc-site |
| `templates/ddd-interview-questions.md` | The 9-section question bank (reference doc the skill cites) |
| `tests/static_server.bats` | Coverage for new lib |
| `tests/layer2-skills.bats` | Asserts the four filled/new SKILL.md files match Layer 2 spec sections |

**Modified files:**

| Path | Change |
|---|---|
| `skills/larv-discuss/SKILL.md` | Stub → real prompt with Laravel ecosystem checklist |
| `skills/larv-domain/SKILL.md` | Stub → real prompt with DDD viability gate + Laravel-DDD mapping (WebFetches medium article) |
| `skills/larv-design/SKILL.md` | Stub → real prompt with design picker + mockup server flow |
| `skills/larv-orchestrator/SKILL.md` | Insert Phase 0a in greenfield sequence; insert Phase 6.5 between Phase 6 and Phase 7 |
| `tests/skills.bats` | Remove `larv-discuss`, `larv-domain`, `larv-design` from stub-flags loop; add no-longer-stub assertions |
| `CHANGELOG.md` | New 0.4.0 release section |
| `README.md` | Add "Layer 2 phases" subsection |
| `LEARNINGS.md` | Append entry on the article-runtime-fetch decision |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` | Bump to 0.4.0 |

---

## Task 1: Static server library

**Files:**
- Create: `scripts/lib/static_server.sh`
- Create: `tests/static_server.bats`

- [ ] **Step 1.1: Write failing test**

Create `tests/static_server.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() {
    # Pick a random local port for testing (no real VM)
    PORT=$(awk 'BEGIN{srand(); print 30000 + int(rand()*10000)}')
}

@test "static_server_compose_command produces a php -S command for a path" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 /srv/larv/x/mockups"
    [ "$status" -eq 0 ]
    [[ "$output" == *"php -S 0.0.0.0:8001"* ]]
    [[ "$output" == *"-t /srv/larv/x/mockups"* ]]
}

@test "static_server_url returns http url with VM host and port" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/vm.sh && source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_url 8001"
    [ "$status" -eq 0 ]
    [ "$output" = "http://31.220.79.31:8001" ]
}

@test "static_server_compose_command rejects empty arguments" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command '' /tmp/x"
    [ "$status" -ne 0 ]
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 ''"
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 1.2: Run — expect failure**

`bats tests/static_server.bats`

- [ ] **Step 1.3: Implement `scripts/lib/static_server.sh`**

```bash
#!/usr/bin/env bash
# Static server lifecycle helpers. Used by Phase 3 mockup server (port range
# 9000-9499) and Phase 6.5 doc-site server (port range 9500-9999). Both rely
# on verifier.sh for port allocation and probe.sh for probe-before-announce.
#
# Requires: scripts/lib/vm.sh sourced first (LARV_VM_HOST).

# static_server_compose_command <port> <doc_root>
# Returns the bash invocation that, when run on the VM, starts a PHP-built-in
# static server bound to all interfaces. The caller backgrounds it.
static_server_compose_command() {
    local port="$1"
    local doc_root="$2"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    [ -n "$doc_root" ] || { echo "ERROR: doc_root required" >&2; return 1; }
    echo "php -S 0.0.0.0:$port -t $doc_root"
}

# static_server_url <port>
# Returns the externally-visible URL for a running static server.
static_server_url() {
    local port="$1"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    echo "http://${LARV_VM_HOST}:$port"
}

# static_server_start <ssh_target> <port> <doc_root> <session_name>
# Starts the server in a tmux session on the VM. Caller MUST then run
# probe-before-announce via probe.sh before announcing the URL.
static_server_start() {
    local ssh_target="$1" port="$2" doc_root="$3" session="$4"
    local cmd
    cmd="$(static_server_compose_command "$port" "$doc_root")" || return 1
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "tmux new-session -d -s '$session' '$cmd'"
}

# static_server_stop <ssh_target> <session_name>
static_server_stop() {
    local ssh_target="$1" session="$2"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "tmux kill-session -t '$session' 2>/dev/null || true"
}

# static_server_open_firewall <ssh_target> <port>
# Opens the port in ufw on the VM.
static_server_open_firewall() {
    local ssh_target="$1" port="$2"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "sudo ufw allow $port/tcp >/dev/null 2>&1 || true"
}
```

- [ ] **Step 1.4: Run tests — expect 3/3 pass**

`bats tests/static_server.bats`

- [ ] **Step 1.5: Commit**

```bash
git add scripts/lib/static_server.sh tests/static_server.bats
git commit -m "feat(lib): add static_server.sh for mockup + doc-site lifecycle"
```

---

## Task 2: DDD interview question bank template

**Files:**
- Create: `templates/ddd-interview-questions.md`

- [ ] **Step 2.1: Create the question bank**

Create `templates/ddd-interview-questions.md`:

```markdown
# DDD Interview — Question Bank

This is a static reference. The `larv-domain-interview` skill reads this file and asks each section's questions one at a time, paired with a recommendation block.

## Constraints

- Business-process only. No tech stack, no library choices, no infrastructure decisions.
- Tech-leak guard: when the user mentions Laravel/Postgres/Filament etc., acknowledge and redirect:
  > "Noted — let's table that for the Discuss phase. Back to the business: ..."
- Record domain nouns and verbs verbatim in `docs/larv/ddd-interview/ubiquitous-language.md`.
- Every question paired with: `Recommendation: <option> · Why: <reason citing prior answers> · Tradeoffs: <one line>`.

## Sections (15–20 questions total)

### 1. Domain experts
- Who knows the domain best?
- Who has decision authority on ambiguities (single name preferred)?

### 2. Core purpose
- "The business exists to ___" (single sentence).
- What job does this app do for the user, independent of any tech?

### 3. Real-world processes
- Walk me through a typical day/transaction in your own words.
- Who does what, when?

### 4. Actors and roles
- List every distinct human (or system) role that interacts with the business.
- Which roles have decision-making power vs. execute-only?

### 5. Things and events
- What nouns come up repeatedly?
- What verbs come up repeatedly?
- (Agent records each verbatim — no canonicalization yet.)

### 6. Business invariants
- What rules MUST always hold? (e.g., "an invoice can never be paid twice")
- Which invariants are legally or contractually required vs. internally chosen?

### 7. Edge cases the business already knows
- Refunds / disputes / chargebacks?
- Holidays / regulatory windows / blackout periods?
- What manual workarounds happen today when the system can't handle something?

### 8. External constraints
- Regulators?
- Partners with hard SLAs?
- Audit requirements?

### 9. What's painful today
- What do people do in spreadsheets that this app should replace?
- What questions take >1 day to answer because the data is scattered?

## Outputs

After the interview, write the following files in `docs/larv/ddd-interview/`:

1. `business-purpose.md` — one paragraph + the single-sentence "the business exists to ___".
2. `domain-experts.md` — names, roles, decision authority.
3. `process-narrative.md` — the user's process description in their own words.
4. `ubiquitous-language.md` — verbatim nouns and verbs (canonicalization happens in Phase 1).
5. `business-invariants.md` — list of MUST-hold rules.
6. `edge-cases.md` — known edge cases.
7. `external-constraints.md` — regulators, partners, audit.
8. `subdomain-candidates.md` — DRAFT clustering of the above into possible subdomains; plain English; no DDD vocabulary.
```

- [ ] **Step 2.2: Commit**

```bash
git add templates/ddd-interview-questions.md
git commit -m "feat(templates): add DDD interview question bank for Phase 0a"
```

---

## Task 3: Create larv-domain-interview skill (Phase 0a)

**Files:**
- Create: `skills/larv-domain-interview/SKILL.md`

- [ ] **Step 3.1: Create the skill directory and SKILL.md**

Create `skills/larv-domain-interview/SKILL.md`:

```markdown
---
name: larv-domain-interview
description: Phase 0a — business-process-only DDD interview. Runs before Discuss. Outputs ubiquitous language, business invariants, edge cases, and a draft subdomain clustering — all in plain English.
---

# larv-domain-interview

Conduct a structured business-process interview before any tech-stack discussion. The output of this skill grounds every subsequent phase. Pure business: no Laravel, no Postgres, no Filament — if the user mentions tech, acknowledge and redirect.

## Trigger

Always runs in `/larv:full` greenfield mode, immediately after Phase −1 pre-flight, before Phase 0 Discuss.

## Inputs

- `docs/larv/STATE.yaml` (project metadata)
- `templates/ddd-interview-questions.md` (the canonical question bank)

## What you do

1. Read the question bank from `templates/ddd-interview-questions.md` (relative to the plugin repo root).
2. Walk the user through the 9 sections. Ask one question at a time. Pair each with a recommendation block (`Recommendation / Why / Tradeoffs`).
3. Record nouns and verbs verbatim — do not canonicalize yet (Phase 1 Domain handles canonicalization).
4. **Tech-leak guard:** if the user says "Laravel", "Postgres", "Filament", "Redis", or any other tech term, respond:
   > "Noted — let's table that for the Discuss phase. Back to the business: <re-ask the previous question>."
   Append the noted item silently to `docs/larv/00-discuss/library-decisions-pre-input.md`.
5. After the interview, write all 8 output files listed in section 5 of the spec to `docs/larv/ddd-interview/`.
6. Run the auto-commit:
   ```bash
   . scripts/lib/git_safe.sh
   safe_commit_docs "[larv] phase 0a: ddd interview approved"
   ```

## Required outputs

All 8 files in `docs/larv/ddd-interview/`:

- `business-purpose.md`
- `domain-experts.md`
- `process-narrative.md`
- `ubiquitous-language.md`
- `business-invariants.md`
- `edge-cases.md`
- `external-constraints.md`
- `subdomain-candidates.md`

## What you do not do

- Do not ask about libraries, frameworks, hosting, databases, or any tech.
- Do not pre-canonicalize ubiquitous-language terms — record them verbatim.
- Do not invoke other skills.
- Do not write outside `docs/larv/ddd-interview/` (and `docs/larv/00-discuss/library-decisions-pre-input.md` for tech leaks).

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/ddd-interview/business-purpose.md
  - docs/larv/ddd-interview/domain-experts.md
  - docs/larv/ddd-interview/process-narrative.md
  - docs/larv/ddd-interview/ubiquitous-language.md
  - docs/larv/ddd-interview/business-invariants.md
  - docs/larv/ddd-interview/edge-cases.md
  - docs/larv/ddd-interview/external-constraints.md
  - docs/larv/ddd-interview/subdomain-candidates.md
state_updates: {}
plugin_improvement_notes: (none)
```
```

- [ ] **Step 3.2: Commit**

```bash
git add skills/larv-domain-interview/SKILL.md
git commit -m "feat(skill): add larv-domain-interview for Phase 0a"
```

---

## Task 4: Fill larv-discuss skill (Phase 0 enrichment)

**Files:**
- Modify: `skills/larv-discuss/SKILL.md`

- [ ] **Step 4.1: Overwrite `skills/larv-discuss/SKILL.md`**

```markdown
---
name: larv-discuss
description: Phase 0 — Laravel-specific brainstorming, grounded in the DDD interview output. Asks about admin panel, auth, async, realtime, observability, performance, payments, multi-tenancy, search, MCPs, and dev tooling — each with a description and a recommendation citing the DDD interview.
---

# larv-discuss

Run product brainstorming with Laravel ecosystem grounding. Reads the DDD interview output (Phase 0a) and uses it to ground every recommendation.

## Inputs

- `docs/larv/ddd-interview/*.md` (Phase 0a outputs)
- `docs/larv/STATE.yaml`

## What you do

1. Read all files in `docs/larv/ddd-interview/`.
2. Walk the Laravel ecosystem checklist below. For each package, print a 2–3 line description + how it would help **this specific app** (citing DDD interview output), then ask. Every question paired with a recommendation block.
3. Write the outputs.

## Laravel ecosystem checklist

For each package, present description + recommendation + question:

- **Admin panel**: Filament / Nova / none
- **Auth**: Sanctum / Passport / Fortify / Socialite
- **Async**: Horizon + Redis / sync queues
- **Realtime**: Reverb / Pusher / none
- **Observability**: Pulse, Telescope (yes/no for each)
- **Performance**: Octane (Swoole / RoadRunner / FrankenPHP) / none
- **Payments**: Cashier-Stripe / Cashier-Paddle (only if billing was mentioned in DDD interview)
- **Multi-tenancy**: Spatie Multitenancy / Tenancy for Laravel / Stancl / none
- **Search**: Scout + Meilisearch / Scout + Typesense / none
- **MCPs**: context7, playwright, laravel-mcp (yes/no for each)
- **Dev tooling**: Pest, Pint, Larastan, Rector (yes/no for each)

The recommendation cites the DDD interview verbatim — for example: "you said 'audit-critical' → Pulse + Telescope recommended. you said 'B2B audience' → Filament recommended. no realtime in core processes → skip Reverb."

## Required outputs

In `docs/larv/00-discuss/`:

- `product-brief.md` — synthesized one-page brief
- `stakeholder-map.md` — actors and decision authorities
- `glossary.md` — synthesizes ubiquitous-language with canonical terms; cross-links to verbatim version in `docs/larv/ddd-interview/ubiquitous-language.md`
- `library-decisions.md` — every approved package + rationale (feeds ADR creation in Phase 2)
- `mcp-decisions.md` — selected MCPs and reasons
- `handoff.md` — phase summary

## Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 0: discuss approved"
```

## What you do not do

- Do not run any code or scaffold any project.
- Do not write design or architecture docs (those are later phases).
- Do not change the DDD interview output (it is the source of truth).

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/00-discuss/product-brief.md
  - docs/larv/00-discuss/stakeholder-map.md
  - docs/larv/00-discuss/glossary.md
  - docs/larv/00-discuss/library-decisions.md
  - docs/larv/00-discuss/mcp-decisions.md
  - docs/larv/00-discuss/handoff.md
state_updates: {}
plugin_improvement_notes: (none)
```
```

- [ ] **Step 4.2: Commit**

```bash
git add skills/larv-discuss/SKILL.md
git commit -m "feat(skill): wire larv-discuss with Laravel ecosystem checklist"
```

---

## Task 5: Fill larv-domain skill (Phase 1 enrichment — Laravel-DDD mapping)

**Files:**
- Modify: `skills/larv-domain/SKILL.md`

- [ ] **Step 5.1: Overwrite `skills/larv-domain/SKILL.md`**

```markdown
---
name: larv-domain
description: Phase 1 — DDD viability check, then either Laravel-DDD architecture mapping (WebFetches the linked medium article at runtime) or a flat Eloquent-friendly domain model.
---

# larv-domain

Map the Phase 0a DDD interview output to a Laravel architecture. If DDD viability passes, produce a full DDD layout; otherwise, produce a flat Eloquent model that still uses the canonical ubiquitous-language terms.

## Inputs

- `docs/larv/ddd-interview/*.md` (Phase 0a)
- `docs/larv/00-discuss/*.md` (Phase 0)

## DDD viability gate

Pass if ≥2 of the following hold (use the DDD interview output as evidence):

- complex / fast-changing business rules
- multi-team boundary collisions
- unstable upstream contracts
- audit-critical workflows

Pass → DDD path. Fail → Flat path.

Print the assessment with citations. Ask the user to confirm or override.

## DDD path

WebFetch the linked Laravel-DDD article at runtime so the mapping reflects current guidance:

```
https://medium.com/@harryespant/implementing-domain-driven-architecture-in-laravel-setup-advantages-and-practical-use-cases-5eac6dfeffaa
```

Use the article as a reference for Laravel-specific layout decisions (Domain / Application / Infrastructure / Interface layers; where Aggregates live; Repository interface vs concrete; how Eloquent folds in). Each non-trivial decision gets an ADR in `adr/`.

Outputs in `docs/larv/01-domain/`:

- `subdomains.md`
- `bounded-contexts.md`
- `context-map.md` (Mermaid)
- `ubiquitous-language.md` (canonical — distinct from Phase 0a's verbatim version)
- `aggregates.md`
- `domain-events.md`
- `laravel-layout.md` (file/folder shape under `app/Domain/…`, `app/Application/…`, etc.)

## Flat path

Single output:

- `docs/larv/01-domain/domain-model.md` — Eloquent-friendly entities and relationships, still using ubiquitous-language terms.

## Auto-commit

```bash
. scripts/lib/git_safe.sh
safe_commit_docs "[larv] phase 1: domain approved"
```

## What you do not do

- Do not bake the article's specific recipe into your output verbatim — cite it as a reference and synthesize.
- Do not pick libraries or frameworks (those are Phase 0 / Phase 2 decisions).
- Do not change Phase 0a or Phase 0 outputs.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/01-domain/...  # depends on path taken
state_updates: {}
plugin_improvement_notes: (none)
```
```

- [ ] **Step 5.2: Commit**

```bash
git add skills/larv-domain/SKILL.md
git commit -m "feat(skill): wire larv-domain with Laravel-DDD mapping"
```

---

## Task 6: Fill larv-design skill (Phase 3 — design picker + mockup server)

**Files:**
- Modify: `skills/larv-design/SKILL.md`

- [ ] **Step 6.1: Overwrite `skills/larv-design/SKILL.md`**

```markdown
---
name: larv-design
description: Phase 3 — design recommendation memo, user browses getdesign.md in their own browser to pick ≥3 designs, agent fetches picks, mockup server renders this app's screens in each picked style, user converges on one design, brand spec finalized.
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

- **Archetype call** — e.g., "B2B SaaS, admin-heavy, table-dense, multi-tenant. Audience: ops teams." (cite the brief)
- **Look for** — concrete criteria for evaluation: "good empty states (your invite flow shows these often)", "table density treatments that don't break at 50 rows"
- **Avoid** — opposites with reasons: "skip playful/whimsical (B2B audience, billing scope)"
- **Starting points on getdesign.md** — 3–5 specific page URLs that match the archetype, plus 2–3 search keywords. Flag each as a starting point only.

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

Invoke the bundled `huashu-design` skill for each pick. Render 5–7 key screens per pick at `docs/larv/03-design/mockups/<pick-slug>/<screen>.html`.

**Feasibility fallback (per spec §9.1 step 6):** if huashu cannot sustain consistency across all picks × screens, degrade to one mockup per pick (hero/dashboard only). Record the decision in `docs/larv/03-design/recommendations.md`.

### 7. Mockup server (probe-before-announce)

```bash
. scripts/lib/probe.sh

ssh "$ssh_target" "mkdir -p /srv/larv/$(yq -r .project.slug docs/larv/STATE.yaml)/mockups"
# rsync the mockups dir to the VM (left as exercise — use rsync -avz)

static_server_start "$ssh_target" "$mockup_port" \
    "/srv/larv/$(yq -r .project.slug docs/larv/STATE.yaml)/mockups" \
    "larv-mockups-$(yq -r .project.slug docs/larv/STATE.yaml)"

if ! probe_url_inside "$ssh_target" "$mockup_port" static; then
    echo "ERROR: inside-VM probe failed for mockup port" >&2; return 1
fi
if ! probe_with_retries "$(static_server_url "$mockup_port")" static; then
    echo "ERROR: external probe failed" >&2; return 1
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
- Do not pick the design for the user — provide recommendations, never decisions.

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
```

- [ ] **Step 6.2: Commit**

```bash
git add skills/larv-design/SKILL.md
git commit -m "feat(skill): wire larv-design with picker + mockup server"
```

---

## Task 7: Create larv-docsite skill (Phase 6.5)

**Files:**
- Create: `skills/larv-docsite/SKILL.md`

- [ ] **Step 7.1: Create the skill**

```markdown
---
name: larv-docsite
description: Phase 6.5 — Docsify-served review of the entire plan before the Phase 7 hard gate. Verifier allocates a port from the docsite range; firewall opened; probe-before-announce.
---

# larv-docsite

Serve `docs/larv/` as a navigable Docsify site so the user can review the full plan in their browser before the implementation gate.

## Trigger

Runs automatically after Phase 6 (Plan) approval, before the Phase 7 hard gate.

## Inputs

- All files under `docs/larv/`
- `docs/Handsoff.md` (if it exists at this point)

## What you do

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/probe.sh
. scripts/lib/static_server.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
project_root="/srv/larv/$slug"

# 1. Allocate port from docsite range (9500-9999)
docsite_port=$(allocate_port docsite)
bash scripts/state.sh record-allocation . docsite-port "$docsite_port"
static_server_open_firewall "$ssh_target" "$docsite_port"

# 2. Stage docs/ and a Docsify index.html on the VM
ssh "$ssh_target" "mkdir -p $project_root/docsite"
rsync -avz docs/larv/ "$ssh_target:$project_root/docsite/"
ssh "$ssh_target" "cat > $project_root/docsite/index.html" <<'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>larv plan</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css">
</head><body><div id="app">Loading…</div>
<script>
  window.$docsify = { name: 'larv plan', loadSidebar: false, search: 'auto' };
</script>
<script src="//cdn.jsdelivr.net/npm/docsify@4"></script>
<script src="//cdn.jsdelivr.net/npm/docsify@4/lib/plugins/search.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/docsify-mermaid@latest/dist/docsify-mermaid.js"></script>
<script src="//cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>mermaid.initialize({ startOnLoad: true });</script>
</body></html>
HTML

# 3. Start static server (Docsify is client-side only; static server is enough)
static_server_start "$ssh_target" "$docsite_port" "$project_root/docsite" \
    "larv-docsite-$slug"

# 4. Probe-before-announce
if ! probe_url_inside "$ssh_target" "$docsite_port" static; then
    echo "ERROR: inside-VM probe failed for docsite port" >&2; return 1
fi
if ! probe_with_retries "$(static_server_url "$docsite_port")" static; then
    echo "ERROR: external probe failed" >&2; return 1
fi

# 5. Announce
echo "Plan available for review at $(static_server_url "$docsite_port")"
```

## Server lifetime

Stays up through the Phase 7 hard gate. Released after the routing menu is answered, or `/larv:docsite teardown-server`.

## Required outputs

- The doc-site is browsable at `http://31.220.79.31:<port>`.
- `STATE.yaml.execution.allocations` includes a `docsite-port` entry.

## What you do not do

- Do not modify any `docs/larv/` content — this skill is read-only on the plan.
- Do not announce the URL until both probes succeed.
- Do not require the user to install anything on their machine — the doc-site loads Docsify from CDN in their browser.

## Subagent return contract

```yaml
status: complete
files_written: []
state_updates:
  execution.allocations: [..., { kind: docsite-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
```

- [ ] **Step 7.2: Commit**

```bash
git add skills/larv-docsite/SKILL.md
git commit -m "feat(skill): add larv-docsite for Phase 6.5 plan review"
```

---

## Task 8: Wire Phase 0a and Phase 6.5 into the orchestrator

**Files:**
- Modify: `skills/larv-orchestrator/SKILL.md`

- [ ] **Step 8.1: Extend the phase sequence in the orchestrator**

Read the current `skills/larv-orchestrator/SKILL.md`. Find the "Per-phase loop" section. Add this paragraph just before the "Hard gates" section:

```markdown
## Phase sequence (greenfield)

The greenfield mode dispatches phases in this exact order:

1. **Phase −1**: pre-flight (script, not a skill)
2. **Phase 0a**: dispatch `larv-domain-interview`
3. **Phase 0**: dispatch `larv-discuss`
4. **Phase 1**: dispatch `larv-domain`
5. **Phase 2**: dispatch `larv-architecture`
6. **Phase 3**: dispatch `larv-design`
7. **Phase 4**: dispatch `larv-tests`
8. **Phase 5**: dispatch `larv-premortem`
9. **Phase 6**: dispatch `larv-plan`
10. **Phase 6.5**: dispatch `larv-docsite` (writes nothing; serves the doc-site)
11. **Phase 7 hard gate** (provisioning approval)
12. **Phase 7**: dispatch `larv-provision`
13. **larv-handoff** (mandatory)
14. **Phase 8 hard gate** (routing menu)
15. **Phase 8**: dispatch `larv-implement` (or stop, if `handoff` was chosen)
16. **Phase 9**: dispatch `larv-verify`
17. **Phase 10**: dispatch `larv-deploy`
18. **Phase 11**: dispatch `larv-learn`
```

- [ ] **Step 8.2: Commit**

```bash
git add skills/larv-orchestrator/SKILL.md
git commit -m "feat(skill): orchestrator wires Phase 0a + Phase 6.5 sequence"
```

---

## Task 9: Tests for filled and new skills

**Files:**
- Modify: `tests/skills.bats`

- [ ] **Step 9.1: Update the existing stub-flag loop**

In `tests/skills.bats`, find the "every skill stub flags itself" test. Remove these from the loop list:

- `larv-discuss`
- `larv-domain`
- `larv-design`

(Three skills have moved from stub → real prompt in this layer.)

- [ ] **Step 9.2: Add new tests**

Append these tests:

```bash
@test "larv-domain-interview SKILL.md exists with valid frontmatter" {
    [ -f skills/larv-domain-interview/SKILL.md ]
    grep -q "^name: larv-domain-interview" skills/larv-domain-interview/SKILL.md
    grep -q "Phase 0a" skills/larv-domain-interview/SKILL.md
    grep -qi "tech-leak guard" skills/larv-domain-interview/SKILL.md
}

@test "larv-discuss SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-discuss/SKILL.md
    # Asserts the ecosystem checklist is present
    grep -q "Filament" skills/larv-discuss/SKILL.md
    grep -q "Horizon" skills/larv-discuss/SKILL.md
    grep -q "Pulse" skills/larv-discuss/SKILL.md
    grep -q "Cashier" skills/larv-discuss/SKILL.md
}

@test "larv-domain SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-domain/SKILL.md
    # Asserts WebFetch of the medium article is described
    grep -q "medium.com/@harryespant" skills/larv-domain/SKILL.md
    grep -qi "viability" skills/larv-domain/SKILL.md
}

@test "larv-design SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-design/SKILL.md
    grep -q "getdesign.md" skills/larv-design/SKILL.md
    grep -q "allocate_port mockup" skills/larv-design/SKILL.md
    grep -qi "probe-before-announce" skills/larv-design/SKILL.md
}

@test "larv-docsite SKILL.md exists for Phase 6.5" {
    [ -f skills/larv-docsite/SKILL.md ]
    grep -q "^name: larv-docsite" skills/larv-docsite/SKILL.md
    grep -q "Phase 6.5" skills/larv-docsite/SKILL.md
    grep -q "allocate_port docsite" skills/larv-docsite/SKILL.md
    grep -q "docsify" skills/larv-docsite/SKILL.md
}

@test "larv-orchestrator describes Phase 0a and Phase 6.5 in greenfield sequence" {
    grep -q "Phase 0a" skills/larv-orchestrator/SKILL.md
    grep -q "Phase 6.5" skills/larv-orchestrator/SKILL.md
    grep -q "larv-domain-interview" skills/larv-orchestrator/SKILL.md
    grep -q "larv-docsite" skills/larv-orchestrator/SKILL.md
}
```

- [ ] **Step 9.3: Run tests — expect all green**

`bats tests/skills.bats`

If "all 15 skill files exist" test fails because we added two new skills (now 17), update the assertion. Read tests/skills.bats and adjust the count assertion to match the new count.

- [ ] **Step 9.4: Commit**

```bash
git add tests/skills.bats
git commit -m "test: assert Layer 2 skill prompts are wired correctly"
```

---

## Task 10: Update `.claude-plugin/marketplace.json` skill list

**Files:**
- Modify: `.claude-plugin/marketplace.json` (if it enumerates skills)
- Modify: `.claude-plugin/plugin.json` (if it does)

- [ ] **Step 10.1: Inspect the manifests**

Run:

```bash
cat .claude-plugin/plugin.json
cat .claude-plugin/marketplace.json
```

If neither manifest enumerates skill names (auto-discovery), no change is required — proceed to Task 11.

If either manifest lists skills, add `larv-domain-interview` and `larv-docsite` to the list. Run:

```bash
bats tests/manifest.bats
```

Expect all green. If a test count assertion needs updating, fix it.

- [ ] **Step 10.2: Commit (if changed)**

```bash
git add .claude-plugin/
git commit -m "chore(manifest): register larv-domain-interview and larv-docsite skills"
```

---

## Task 11: Update CHANGELOG, README, LEARNINGS

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `README.md`
- Modify: `LEARNINGS.md`

- [ ] **Step 11.1: Append to `CHANGELOG.md`**

Insert at top of changelog entries (above the 0.3.0 entry):

```markdown
## 0.4.0 (next) — Layer 2

- **Phase 0a — DDD interview** (new skill `larv-domain-interview`): business-process-only interview before Discuss. 9 sections, ~15–20 questions, tech-leak guard, 8 output files in `docs/larv/ddd-interview/`.
- **Phase 0 enrichment**: `larv-discuss` filled with the full Laravel ecosystem checklist (Filament/Nova, Sanctum/Passport/Fortify, Horizon, Reverb, Pulse, Telescope, Octane, Cashier, multi-tenancy options, Scout, MCPs, Pest/Pint/Larastan/Rector). Each ask paired with a recommendation citing the DDD interview.
- **Phase 1 — Laravel-DDD mapping** (`larv-domain` filled): WebFetches the linked medium article at runtime for current Laravel-DDD guidance; produces full DDD layout when viability passes, flat Eloquent model otherwise.
- **Phase 3 — design picker + mockup server** (`larv-design` filled): recommendation memo, user browses getdesign.md in their own browser, agent fetches picks, huashu renders this app's screens in each picked style, comparison harness served on a verifier-allocated port; user converges on one design (or hybrid).
- **Phase 6.5 — doc-site review** (new skill `larv-docsite`): Docsify served on a docsite-range port (9500–9999), client-side rendering from CDN, no server-side build; allows browsing the entire plan before the Phase 7 hard gate.
- **New shared lib `static_server.sh`**: shared lifecycle for any static server on the VM (mockups, doc-site).
```

- [ ] **Step 11.2: Append to `README.md`**

After the existing "How the MVP enforces venue parity" section, add:

```markdown
## Layer 2 phases

Layer 2 adds richer per-phase content:

- **Phase 0a** runs a business-process DDD interview *before* tech is discussed. Tech mentions are politely tabled.
- **Phase 0 (Discuss)** uses the DDD interview to ground every Laravel ecosystem question — descriptions and recommendations cite your own answers.
- **Phase 1 (Domain)** WebFetches a current Laravel-DDD reference and produces either a full DDD layout or a flat Eloquent model based on a viability gate.
- **Phase 3 (Design)** asks you to browse https://getdesign.md/ in your own browser and pick ≥3 designs. The agent then renders *your app's screens* in each picked style and serves a comparison harness at `http://31.220.79.31:<port>` so you can pick one (or merge two).
- **Phase 6.5 (Doc-site)** spins up a Docsify-rendered version of your entire plan at `http://31.220.79.31:<port>` for a final read-through before implementation begins.
```

- [ ] **Step 11.3: Append to `LEARNINGS.md`**

```markdown
## 2026-05-06 — Article-driven mapping vs frozen baked-in mapping

[plugin] When a skill's behavior depends on a third-party reference (Phase 1's Laravel-DDD mapping cites a medium article), prefer WebFetch at skill runtime over baking the article's specifics into the spec. The article evolves; our spec freezes the moment it's pasted in. Runtime fetch keeps the mapping current at the cost of needing internet during Phase 1.

[plugin] When two phases need a static server (Phase 3 mockups, Phase 6.5 doc-site), share a lib (`static_server.sh`). Don't duplicate the start/probe/stop dance per skill.
```

- [ ] **Step 11.4: Commit**

```bash
git add CHANGELOG.md README.md LEARNINGS.md
git commit -m "docs: record Layer 2 behaviors and reference-fetch pattern"
```

---

## Task 12: Bump plugin version to 0.4.0

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.codex-plugin/plugin.json`

- [ ] **Step 12.1: Bump versions**

In each of the three files, change `"version": "0.3.0"` to `"version": "0.4.0"`.

- [ ] **Step 12.2: Run `bats tests/manifest.bats`**

Expect all tests pass.

- [ ] **Step 12.3: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json
git commit -m "chore: bump plugin version to 0.4.0 (Layer 2)"
```

---

## Task 13: Final regression run

- [ ] **Step 13.1: Run the full bats suite**

```bash
bats tests/
```

Expect ALL tests pass (148 from MVP plus the new tests added in this Layer 2 plan — count varies based on how many test asserts were added).

- [ ] **Step 13.2: If any test fails, debug and fix**

Common likely failures:

- `tests/skills.bats` "all 15 skill files exist" — change to "all 17 skill files exist" since `larv-domain-interview` and `larv-docsite` were added.
- `tests/skills.bats` "every skill stub flags itself" — confirm the loop list now excludes `larv-discuss`, `larv-domain`, `larv-design` in addition to the four already excluded by MVP.
- `tests/manifest.bats` — confirm version is `0.4.0`.

Don't move on with any failing test. The Layer 2 work isn't complete until the suite is green.

---

## Self-Review

**1. Spec coverage:**

| Spec section | Plan task |
|---|---|
| §5 Phase 0a DDD Interview | Task 2 (question bank) + Task 3 (skill) + Task 9 test |
| §6 Phase 0 Discuss enrichment (Laravel checklist) | Task 4 (skill) + Task 9 test |
| §7 Phase 1 Laravel-DDD mapping | Task 5 (skill, WebFetches article) + Task 9 test |
| §9 Phase 3 Design picker + mockup server | Task 6 (skill) + Task 1 (static_server.sh) + Task 9 test |
| §11 Phase 6.5 Doc-site | Task 7 (skill) + Task 1 (static_server.sh) + Task 9 test |
| Phase sequence integration | Task 8 (orchestrator wiring) + Task 9 test |
| Documentation & version bump | Task 11, Task 12 |

All Layer 2 spec sections are covered.

**2. Placeholder scan:**

- No "TBD", "TODO", "implement later" inside step bodies.
- The slice-handsoff template's `(see slice plan)` defaults are unchanged from MVP — those are runtime values filled by `larv-plan`, not plan placeholders.
- Step 6.1 leaves the rsync command "as exercise" in narrative — this is acceptable because the user can substitute their preferred file-copy method (rsync, scp, sftp); the surrounding bash is complete.

**3. Type / API consistency:**

- `static_server_compose_command(port, doc_root)` — used in `static_server_start` (Task 1) and consumed by Tasks 6 (mockups), 7 (docsite). Consistent.
- `static_server_url(port)` — used in Tasks 6, 7. Consistent.
- `allocate_port` roles `mockup`, `docsite`, `app` — consistent with MVP's verifier.sh.
- `record-allocation` kinds `mockup-port`, `docsite-port`, `app-port` — consistent.
- The `larv-domain-interview` skill is referenced by name in Task 8 (orchestrator wiring) and Task 9 (test) — same identifier.
- The `larv-docsite` skill is referenced by name in Task 8 and Task 9 — same identifier.

No issues.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-06-larv-plugin-layer-2.md`. Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task with two-stage review.
2. **Inline Execution** — execute tasks in the active session with batch checkpoints.

For Layer 2 specifically, the user explicitly requested subagent-driven execution in a fresh session (separate from MVP delivery). To begin: open a new session with this repo as the working directory, then invoke `superpowers:subagent-driven-development` against this plan file.
