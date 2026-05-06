---
title: larv plugin overhaul — planning-focused, venue-agnostic, with DDD interview, design picker, verifier, and handsoff
status: approved (pending writing-plans)
date: 2026-05-06
supersedes_partially: 2026-05-04-larv-plugin-shell-design.md
related: 2026-05-04-larv-plugin-usage-guide.md
---

# larv plugin overhaul — design

## 1. Context

The larv plugin today exists as a shell: orchestrator skill, 8 commands, 15 phase-skill stubs, bundled upstreams. It does not yet enforce user approval gates, does not produce a portable handoff artifact, and assumes a single developer on the VM. This spec captures the target behavior of the plugin once the stubs are filled in and the workflow is corrected.

Three problems drive this overhaul:

1. **No approval gates.** The orchestrator advances phases without asking, including across the planning-to-implementation boundary. Users want explicit control before any code is written.
2. **No portable handoff.** The plugin assumes Claude Code runs every phase. Users want to plan in Claude Code and hand the implementation to a different AI session (Codex CLI, Cursor, another Claude session, etc.) at their discretion.
3. **VM is shared.** Multiple developers run larv against the same cloud VM. The plugin must verify port and database availability before allocating, and must verify any service is actually serving before printing a URL.

Two further requirements emerge from the larger workflow:

- **Domain knowledge precedes tech choices.** A dedicated business-process interview (DDD-style, no tech vocabulary) must run before any tech-stack discussion. Its output grounds every subsequent phase.
- **Visual design is a user decision, supported by tooling.** The plugin recommends design starting points but never picks for the user; it visualizes the user's app rendered in the user's chosen styles so the user can converge on one.

## 2. Goals and non-goals

### Goals

- Hard gates at the planning→implementation boundary, soft summaries between purely-additive phases.
- Mandatory generation of `docs/Handsoff.md` and per-slice handsoffs that are self-contained enough for any AI to execute without the plugin.
- Live-scan verification of VM resources (ports, databases, project roots) before any allocation, with auto-pick on conflict and probe-before-announce on any service start.
- A new business-only DDD interview phase (Phase 0a) that runs before Discuss in greenfield mode.
- A design picker flow that has the user browse `https://getdesign.md/` in their own browser and converges on a single design via a mockup server that renders the user's app in each picked style.
- Implementation tracker (`implementation-tracker.yaml` + rendered MD) and AI starting-point files (`CLAUDE.md`, `AGENTS.md`, etc.) so foreign-AI sessions stay synchronized with the plan.
- Identical artifact discipline across `/larv:full`, `/larv:feature`, and `/larv:debug` — feature and debug commands are not lighter-weight escape hatches.

### Non-goals

- Replacing the existing 12-phase orchestration shape. The phase numbering, skill names, and orchestrator entry points stay; this overhaul fills in the stubs and adds Phase 0a / Phase 6.5 without renumbering existing phases.
- Multi-VM or multi-tenant deployment. The VM constant is hardcoded for this team; isolating it to one module is the only generalization.
- Replacing or repackaging bundled upstream skills (masterplan, superpowers-laravel, domain-driven-design, huashu-design). Phase wrappers continue to invoke them.
- A rich registry service for VM allocations. Live-scan only.

## 3. Core invariants

The spec depends on three invariants. Skills and templates that violate any of them are spec violations.

### 3.1 Venue parity

`same-session`, `subagents`, and `handed-off-external` execution venues for Phase 8 read **the exact same handsoff documents**. There is no internal Phase 8 logic distinct from "what we tell a foreign AI to do." If a step works in Codex CLI from `docs/Handsoff/slice-01.md`, it works in same-session by construction.

Implication: the `larv-implement` skill is a thin loop that reads handsoff documents and follows them. It does not call `scripts/state.sh` directly; it executes the inline bash snippets the handsoff document carries.

### 3.2 Handsoff self-containment

Every action a foreign AI must take is encoded as inline bash in the handsoff document. References to plugin scripts (`scripts/state.sh`, `scripts/lock.sh`, `scripts/render-tracker.sh`) are spec violations inside handsoff content. The handsoff carries its own state-update, tracker-append, learnings-append, and report-write snippets.

Same-session and subagents code paths read these same snippets. This makes parity structural rather than aspirational.

### 3.3 Probe-before-announce

No URL is printed to the user until the service it points to responds with HTTP 200 (or the documented non-error status for that service — for example, redirects on root paths). Probes run from inside the VM (`curl -fsS 127.0.0.1:<port>` over SSH) and from outside (`curl -fsS <LARV_VM_HOST>:<port>` from the runner) before the URL is announced.

Per-service timeout policies:

- Static server (mockups, doc-site): 5s × 5 retries
- Laravel app: 60s × 6 retries (cold start)
- Nginx / reverse-proxy: 10s × 5

If probes fail after retries, the agent prints the failure and offers diagnostics; it does not announce the URL.

## 4. System overview

### 4.1 Phase map

Existing phase numbering is preserved. New content slots in as `Phase 0a` and `Phase 6.5` without renumbering. Folder prefixes are stable; new folders use names rather than numeric prefixes when they would collide.

| Phase | Folder | Skill | Status |
|---|---|---|---|
| −1 Pre-flight | `pre-flight.md` | (script) | unchanged |
| **0a DDD Interview** | `ddd-interview/` | `larv-domain-interview` (NEW) | new |
| 0 Discuss | `00-discuss/` | `larv-discuss` | enriched |
| 1 Domain | `01-domain/` | `larv-domain` | enriched |
| 2 Architecture | `02-architecture/` | `larv-architecture` | enriched |
| 3 Design | `03-design/` | `larv-design` | overhauled |
| 4 Test Strategy | `04-test-strategy/` | `larv-tests` | unchanged |
| 5 Premortem | `05-premortem/` | `larv-premortem` | unchanged |
| 6 Plan | `06-implementation/` | `larv-plan` | enriched (13-field slice cards) |
| **6.5 Doc-site Review** | (served only) | `larv-docsite` (NEW) | new (Layer 2) |
| 7 Provision | `07-runtime/` | `larv-provision` | enriched |
| 8 Implementation | `06-implementation/slice-NN/` | `larv-implement` | thin loop |
| 9 Verification | `09-verification/` | `larv-verify` | unchanged |
| 10 Deploy | `10-deploy/` | `larv-deploy` | unchanged |
| 11 Learn | `08-learnings/` | `larv-learn` | unchanged |

### 4.2 Gate model

Hybrid gates:

- **Soft gate after every approved phase.** Two-line summary, list of changed files, "auto-continue in 30s; reply `pause` to review or `back` to redo previous phase."
- **Hard gate before Phase 7** (provisioning). User must type `approved` to advance.
- **Hard gate before Phase 8** (the routing menu — see §4.3). User must choose execution venue explicitly.
- **Loop-back signal from Phase 5** (premortem) is always a hard stop with explicit confirmation.

### 4.3 Routing menu (Phase 7 → 8 hard gate)

After Phase 7 completes and all handsoff documents are written, the orchestrator stops and prints a routing menu:

```
[Phase 7 complete]

Handsoff documents written:
  docs/Handsoff.md                  (index)
  docs/Handsoff/slice-01-<name>.md
  docs/Handsoff/slice-02-<name>.md
  ... (N total)

Where do you want to execute these slices?

  same-session  — this Claude Code session runs Phase 8 slice-by-slice
  subagents     — fresh subagents per slice, parallel where deps allow
  handoff       — stop here; you'll point another AI at docs/Handsoff.md

Recommendation: <option>
Why: <one-sentence reason citing project size / venue tradeoffs>
Tradeoffs: <one-line counterpoint>

> 
```

User input updates `STATE.yaml.mode`:

- `same-session` → `mode: executing-same-session`. Orchestrator continues.
- `subagents` → `mode: executing-subagents`. Orchestrator spawns one subagent per slice.
- `handoff` → `mode: handed-off-external`. Orchestrator marks `/larv:full` complete and exits. The plugin does not run further phases. The user is responsible for invoking another AI tool against `docs/Handsoff.md`.

`mixed` is not offered. A user can pick `same-session` for early slices and switch to `handoff` for later slices by stopping the orchestrator and editing `STATE.yaml.mode`.

## 5. Phase 0a — DDD Interview

### 5.1 Trigger and scope

Always runs in `/larv:full` greenfield mode. Always runs (in mini form) at the start of `/larv:feature` if the new feature introduces business words or invariants not already covered. Skipped in `/larv:debug` unless the user signals the bug uncovers a previously-undocumented business invariant.

**Scope:** business-process only. No tech vocabulary, no library choices, no infrastructure decisions.

### 5.2 Tech-leak guard

When the user mentions tech mid-interview (Postgres, Filament, "we'll use Laravel for X"), the agent acknowledges and redirects:

> "Noted — let's table that for the Discuss phase. Back to the business: when X happens, who is responsible for Y?"

The mention is recorded silently in `00-discuss/library-decisions-pre-input.md` for Discuss to surface later.

### 5.3 Question shape

Structured: 15–20 questions across 9 sections. Each question is paired with the recommendation block (see §15.1).

Sections:

1. **Domain experts** — who knows the domain best, who has decision authority on ambiguities
2. **Core purpose** — one-sentence "the business exists to ___"
3. **Real-world processes** — walk through a typical day/transaction in the user's words
4. **Actors and roles** — who does what (role names matter; permissions are downstream)
5. **Things and events** — nouns and verbs that come up repeatedly (ubiquitous-language harvest, recorded verbatim)
6. **Business invariants** — rules that *must* always hold
7. **Edge cases the business already knows** — refunds, disputes, holidays, regulatory windows
8. **External constraints** — regulators, partners, SLAs, audit requirements
9. **What's painful today** — manual / spreadsheet processes the app should replace

### 5.4 Outputs

All in `docs/larv/ddd-interview/`:

- `business-purpose.md`
- `domain-experts.md`
- `process-narrative.md`
- `ubiquitous-language.md` (verbatim user terms; canonicalization happens in Phase 1)
- `business-invariants.md`
- `edge-cases.md`
- `external-constraints.md`
- `subdomain-candidates.md` (draft, plain English, no DDD vocabulary)

### 5.5 Soft gate

Lists changed files, prints a one-paragraph summary of what the business does, auto-continues in 30s.

## 6. Phase 0 — Discuss (enriched)

### 6.1 Reads

`docs/larv/ddd-interview/*.md` so every question is grounded in the user's own business language.

### 6.2 Laravel ecosystem checklist

For each package below, the agent prints a 2–3 line description of what it is and how it would help *this specific app* (citing DDD interview output), then asks. No bare ask is allowed; every question carries the recommendation block (§15.1).

Coverage:

- Admin panel: Filament / Nova / none
- Auth: Sanctum / Passport / Fortify / Socialite
- Async: Horizon + Redis / sync queues
- Realtime: Reverb / Pusher / none
- Observability: Pulse, Telescope
- Performance: Octane (Swoole / RoadRunner / FrankenPHP)
- Payments: Cashier-Stripe / Cashier-Paddle (if billing in scope from DDD interview)
- Multi-tenancy: Spatie Multitenancy / Tenancy for Laravel / Stancl / none
- Search: Scout + Meilisearch / Typesense
- MCPs: context7, playwright, laravel-mcp
- Dev tooling: Pest, Pint, Larastan, Rector

### 6.3 Outputs

- `00-discuss/product-brief.md`
- `stakeholder-map.md`
- `glossary.md` (synthesizes ubiquitous-language with canonical terms; cross-links to the verbatim version in `ddd-interview/`)
- `library-decisions.md`
- `mcp-decisions.md`
- `handoff.md`

Library decisions feed ADR creation in Phase 2.

## 7. Phase 1 — Domain (Laravel-DDD mapping)

### 7.1 DDD viability gate

≥2 of: complex/fast-changing rules · multi-team collisions · unstable contracts · audit-critical. Pass → DDD path. Fail → flat path.

### 7.2 DDD path

Agent WebFetches `https://medium.com/@harryespant/implementing-domain-driven-architecture-in-laravel-setup-advantages-and-practical-use-cases-5eac6dfeffaa` at runtime so the mapping reflects current Laravel-DDD guidance rather than baking specifics into this spec.

Maps Phase 0a outputs to standard Laravel-DDD layout: Domain / Application / Infrastructure / Interface layers; Entities, Value Objects, Aggregates, Repositories, Domain Events, Application Services. Each non-trivial layout decision (where aggregates live, repository interface vs concrete, how Eloquent folds in) gets an ADR in `adr/`.

Outputs in `01-domain/`:

- `subdomains.md`
- `bounded-contexts.md`
- `context-map.md` (Mermaid)
- `ubiquitous-language.md` (canonical)
- `aggregates.md`
- `domain-events.md`
- `laravel-layout.md` (file/folder shape under `app/Domain/…`, `app/Application/…`)

### 7.3 Flat path

Single `01-domain/domain-model.md` with Eloquent-friendly entities, still using ubiquitous-language terms.

## 8. Phase 2 — Architecture

C4 diagrams as Mermaid only. Files in `02-architecture/`:

- `c4-context.md` (Level 1)
- `c4-container.md` (Level 2)
- `c4-component.md` (Level 3)
- `library-pins.md` (versions for every package decided in Phase 0)

ADRs are created in `adr/` (one per decision). A flat aggregator `docs/larv/decisions.md` indexes every ADR with title, date, status, and link — regenerated at the end of every phase that adds an ADR.

## 9. Phase 3 — Design (overhauled)

### 9.1 Step sequence

1. **Frame.** Read `00-discuss/product-brief.md` + `01-domain/*`; emit a one-paragraph design brief; confirm with user.
2. **Recommendation memo** to `03-design/recommendations.md` with sections: Archetype call · Look-for criteria · Avoid criteria · 3–5 starting-point URLs from `https://getdesign.md/` + 2–3 search keywords. Starting points are flagged "starting point only, not a pre-pick."
3. **User browses on their own** at `https://getdesign.md/` in their browser. Agent does not WebFetch yet. User returns with ≥3 picks as URLs or slugs (e.g., `picked: vercel/design-md, stripe/design-md, linear/design-md`).
4. **Agent fetches and confirms.** WebFetches each pick from getdesign.md, caches at `03-design/picks/<slug>.md` with frontmatter (`source_url`, `fetched_at`, `attribution`). Prints a 1-line summary per pick. User confirms (`yes` / `swap A for X` / `add Y`).
5. **Verifier allocates mockup port** in range 9000–9499 (live-scan, auto-pick on conflict, firewall opened, probe-verified per §3.3).
6. **Huashu generates this app's screens in each picked style.** 5–7 key screens per pick. Output: `03-design/mockups/<pick-slug>/<screen>.html`. **Feasibility fallback:** if huashu cannot sustain consistency across the full set, runtime degrades to one mockup per pick (hero/dashboard only). Decision is made by the skill at runtime and recorded in the design log.
7. **Mockup server.** Static server at `http://<LARV_VM_HOST>:<port>` (PHP `php -S 0.0.0.0:<port>` against `03-design/mockups/`), where `<port>` is the value allocated in step 5. Index page is a comparison harness: top tabs (Pick A / Pick B / Pick C / Compare) · left sidebar (your app's screens) · main area (selected screen in selected style). Compare tab shows side-by-side per screen.
8. **User picks one or hybrids.** `pick: B` or `hybrid: B layout + A palette` — agent regenerates a "Hybrid" tab and iterates until the user commits with `pick: hybrid` (or any single slug).
9. **Finalize brand spec** from the winner only: `03-design/brand-spec.md` and `ui-design.md`.
10. **Server lifetime.** Stays up through Phase 6 (so test-strategy and plan can link back). Released by Phase 7 provisioning, or `/larv:design teardown-server`.

### 9.2 Outputs

`03-design/recommendations.md` · `picks/<slug>.md` · `mockups/<slug>/<screen>.html` · `design-decision.md` (with rationale and picks-not-chosen) · `brand-spec.md` · `ui-design.md`.

## 10. Phase 6 — Plan (enriched)

### 10.1 Slice card schema

Every slice in `06-implementation/elephant-carpaccio.md` carries 13 fields:

1. Slice ID + name + one-line goal
2. Why this slice — the user-visible business value it ships
3. Files to create — exact paths
4. Files to modify — exact paths and what changes
5. Migrations — exact filenames and tables/columns
6. Tests to write — Pest test files, test names, acceptance criteria
7. API endpoints — added/modified, with request/response examples
8. UI screens touched — Filament resource, Blade view, or Inertia page paths
9. Dependencies — `depends_on: [slice-id]` graph
10. Parallelism flag — `parallel: true | false`
11. Definition of Done — checklist (tests pass, migration runs forward + backward, smoke test passes, no N+1 queries on listed endpoints, IMPLEMENTATION-REPORT.md written)
12. Estimated tokens / minutes
13. VM commands the implementer must run — exact bash, including `docker compose exec app php artisan …`

### 10.2 Auto-commit

After Phase 6 approval, the orchestrator commits per §13.

## 11. Phase 6.5 — Doc-site review (Layer 2)

Docsify served at `http://<LARV_VM_HOST>:<port>` in range 9500–9999. Static index reads from `docs/larv/`. Mermaid renders via the docsify-mermaid plugin. Search is built-in.

The agent runs `npx docsify-cli serve docs/larv/` (probe-verified per §3.3) and prints the URL. User reviews the entire plan as a navigable site before the Phase 7 hard gate.

This is the last review surface before provisioning. Server is released after the Phase 7 hard gate is passed (or `/larv:docsite teardown-server`).

## 12. Phase 7 — Provision

### 12.1 Verifier-driven allocation

For this project, allocate (live-scan, see §14):

- App port (range 8000–8999)
- DB name (`larv_<slug>`) and DB user
- Project root (`/srv/larv/<slug>/`)
- Redis prefix (`larv:<slug>:`) — unique by construction, no scan needed
- Subdomain on the VM's base domain (if reverse proxy is enabled)

### 12.2 Stack

Docker compose stack (Laravel app + MySQL + Redis + Mailhog + nginx). Per-service probes per §3.3 before any URL is announced.

### 12.3 Outputs

- `07-runtime/sandbox-runbook.md` (concrete, with allocated values inlined)
- `docs/Handsoff.md` (regenerated to reflect runtime info — see §15)
- All AI starting-point files (regenerated — see §17)

### 12.4 Hard gate

User reviews the runbook and the routing menu (§4.3).

## 13. Phase 8 — Implementation (thin loop)

### 13.1 Loop body

For each slice in `06-implementation/elephant-carpaccio.md`:

1. Read `docs/Handsoff/slice-NN-<name>.md` (NN is zero-padded to two digits; slug `<name>` matches the slice card's `name` field, slugified — for example `slice-01-auth-scaffold.md`).
2. Execute the inline bash snippets in order.
3. Run tests per the slice's DoD checklist.
4. Append a tracker entry (§16) using the inline snippet from the handsoff.
5. Append learnings to `docs/larv/local-learnings.md` if any (using the inline snippet).
6. Write IMPLEMENTATION-REPORT.md (using the inline snippet).
7. Update `STATE.yaml.slices.NN.status` (using the inline snippet).
8. Soft gate to user.

The same-session, subagents, and handed-off-external venues all execute exactly this loop. The only difference is who runs it.

### 13.2 Failure handling

If a slice fails (test failure, exception, etc.), the implementer writes a failed IMPLEMENTATION-REPORT.md, marks `STATE.yaml.slices.NN.status: failed`, and the orchestrator prompts the user: retry · skip · stop.

## 14. Cross-cutting: verifier and probe-before-announce

### 14.1 Strategy

Live-scan only, no central registry. Implementations live in `scripts/lib/verifier.sh`.

Probes:

- Ports: `ssh $LARV_VM_HOST "ss -tlnp 2>/dev/null"` → grep for port number
- DBs: `mysql -h $LARV_VM_HOST -e "SHOW DATABASES"` → grep `larv_`
- Project roots: `ssh $LARV_VM_HOST "ls /srv/larv/ 2>/dev/null"`

### 14.2 Allocation algorithm

Walk the candidate range from low end (mockup 9000–9499; doc-site 9500–9999; app 8000–8999), pick the first free value, bind immediately. On bind-fail (TOCTOU race), re-scan and retry up to 3 times. Auto-pick silently on conflict. The chosen value is recorded in `STATE.yaml.allocations` and inlined into handsoff documents.

### 14.3 Probe-before-announce

See §3.3. Implemented in `scripts/lib/probe.sh` with per-service timeout policies.

### 14.4 VM constant

`scripts/lib/vm.sh` exports `LARV_VM_HOST=31.220.79.31`. Single point of change for future generalization. Hardcoded as a known team-locked constant; spec explicitly notes this limitation.

## 15. Cross-cutting: handsoff system

### 15.1 Recommendation block (referenced by every interactive question)

```
Recommendation: <option>
Why: <one-sentence reason citing a specific earlier-phase artifact>
Tradeoffs: <one-line counterpoint>
```

This is a strong norm, not a hard rule. Skill prompts include the rule and an example. Reviewers (and the user) can call out violations. True validation requires parsing skill output, which is out of scope.

### 15.2 Files (always written before Phase 8 hard gate)

- `docs/Handsoff.md` — index. Sections:
  1. Project identity (name, slug, plugin version, git SHA, date)
  2. Mission (one paragraph)
  3. Decisions log — full ADR aggregator inlined (not linked-only)
  4. DDD model — subdomains, bounded contexts, ubiquitous language, aggregates inlined
  5. Architecture — C4 L1+L2+L3 inlined as Mermaid
  6. Data model — tables, relationships, soft-delete posture
  7. API surface — endpoint table, auth posture, response shapes
  8. UI / Brand — link to chosen design pick + brand-spec, key screen list
  9. Test strategy — what's tested how, acceptance criteria, fixtures
  10. Slice plan — full Elephant Carpaccio breakdown with depends_on graph
  11. Sandbox info — VM IP, allocated app port + DB name + project root + Redis prefix, SSH key location, exact verification commands
  12. Verification commands — exact bash to run after implementation
  13. Constraints for the implementer — "do not change schema without consulting plan", "do not skip tests", reporting format
  14. Foreign-AI notes — "ignore any superpowers/skills references; treat this as a plain spec"

- `docs/Handsoff/slice-NN-<name>.md` per slice. The 13-field slice card from §10.1, plus inline bash snippets for: state update, tracker append, learnings append, report write.

### 15.3 Self-containment discipline

Hard rule. Every action a foreign AI must take is encoded as inline bash. No references to plugin scripts. Same-session and subagents read these same snippets — this enforces parity by construction.

Example tracker-append snippet inlined in every slice handsoff:

```bash
cat <<'EOF' | yq eval '. + [{ ... }]' docs/larv/implementation-tracker.yaml -i
EOF
```

The exact yq syntax is generated at handsoff-write time.

## 16. Cross-cutting: implementation tracker

### 16.1 Files

- `docs/larv/implementation-tracker.yaml` — canonical, machine-parseable
- `docs/larv/implementation-tracker.md` — auto-rendered human view

### 16.2 Schema

```yaml
schema_version: 1
entries:
  - id: ENT-NNNN
    title: <short title>
    description: <one-paragraph description>
    type: feature | bug | hotfix | refactor | migration
    created_by:
      tool: claude-code | cursor | codex-cli | gemini-cli | other
      model: <model name, e.g. claude-opus-4-7>
    created_at: <ISO 8601>
    slices_touched: [<slice-id>, ...]
    files_changed: [<path>, ...]
    status: planned | in-progress | completed | reverted
    related_adr: [<adr-id>, ...]
    related_handsoff: docs/Handsoff/slice-NN-<name>.md
    learnings_appended: true | false
```

### 16.3 Update protocol

Every venue is *instructed via handsoff* to append an entry on completion using inline yq from the handsoff document. After append, regenerate the markdown view via the inline render snippet.

The `created_by.tool` and `created_by.model` fields are filled in by the implementing AI (not the planner). Foreign AIs are instructed in their starting-point file (CLAUDE.md, AGENTS.md, etc.) to identify themselves accurately.

## 17. Cross-cutting: AI starting-point files

Generated by `larv-handoff` before the Phase 8 hard gate. All point to `docs/Handsoff.md` and the tracker. Regenerated at every Phase 7 run and at every `/larv:feature` / `/larv:debug` boundary.

### 17.1 Files

- `CLAUDE.md` — Claude Code memory
- `AGENTS.md` — universal convention (Cursor, Aider, Codex CLI, Cody)
- `.cursor/rules/larv.mdc` — Cursor-specific rule
- `GEMINI.md` — Gemini CLI
- `.codex/AGENTS.md` — Codex CLI

### 17.2 Common content

- Project identity (name, slug, plugin version, git SHA)
- "This project uses larv" banner with one-paragraph context
- Pointers to: `docs/Handsoff.md`, `docs/Handsoff/`, `docs/larv/implementation-tracker.yaml`, `docs/larv/local-learnings.md`, `adr/`
- Mandatory post-change checklist:
  1. Append tracker entry (instructions inline)
  2. Update `STATE.yaml.slices.NN.status`
  3. Append `local-learnings.md` if a learning was discovered
  4. Run tests per the slice's DoD
  5. Write IMPLEMENTATION-REPORT.md per slice
  6. Identify yourself accurately in `created_by.tool` / `created_by.model`
- Code conventions (Pint, Pest, Larastan, ubiquitous-language terms)
- Probe-before-announce rule for any service started
- Recommendation-with-every-question expectation when the AI prompts the user

Generated from one template (`templates/ai-starting-point.md.tmpl`) with tool-specific prepends.

## 18. Cross-cutting: git commit policy

After every approved phase: `git add docs/ adr/ && git commit -m "[larv] phase <N>: <name> approved"`.

Safety rules:

- Detect default branch (do not assume `main`). Use `git symbolic-ref refs/remotes/origin/HEAD` or fallback to `git config --get init.defaultBranch`.
- Refuse to commit if there are uncommitted user changes outside `docs/` or `adr/`. Print the dirty paths and prompt the user to commit them first.
- If the default branch is push-protected (commit succeeds locally but push would fail), fall back to a `larv/<slug>` branch and surface that to the user. Detection: try `git push --dry-run` and parse stderr.
- Auto-commit operates only on `docs/` and `adr/` paths. Other paths require explicit user action.

The handsoff doc's "git SHA" field cites the commit SHA at handsoff-write time so any venue can `git checkout <sha>` to the same state.

## 19. /larv:feature and /larv:debug parity

Both preserve full discipline: gates, recommendations, handsoff, tracker, AI-starting-points refresh, doc-site rebuild, git commit per phase.

`/larv:adopt` (existing-app onboarding) is out of scope for this overhaul and continues to behave as it does today. A future revision should bring `/larv:adopt` under the same disciplines, but this spec does not require it.

### 19.1 /larv:feature \<name\>

Mini-flow:

1. Mini DDD interview — only for new business words / invariants the feature introduces (≈5 questions, may be skipped if user asserts "no new domain language"). Outputs append to `ddd-interview/`.
2. Mini Discuss — only for new tech needs. Outputs append to `00-discuss/library-decisions.md`.
3. Architecture delta — new ADR if a previous decision changes.
4. Data / API / UI deltas.
5. Mini premortem (1–2 questions).
6. Mini plan — 1–N new slices with `depends_on` linking to existing slices.
7. Per-slice handsoff written to `docs/Handsoff/slice-NN-<name>.md`.
8. Tracker entry appended per slice.
9. AI starting-point files regenerated.
10. Doc-site rebuild (Layer 2).
11. Git commits per phase.
12. Routing-menu hard gate before implementation.

`STATE.yaml` gains a `features: [<feature-name>, ...]` array.

### 19.2 /larv:debug \<issue\>

Mini-flow:

1. Domain-context check — does this bug imply a missing invariant? If yes, route through a mini DDD interview append.
2. Root-cause investigation — diff of current behavior vs documented invariants.
3. Fix slice + regression test.
4. IMPLEMENTATION-REPORT.md.
5. Per-fix-slice handsoff (yes, even debug gets a handsoff).
6. Tracker entry (`type: bug` or `type: hotfix`).
7. AI starting-point files regenerated.
8. Doc-site rebuild (Layer 2).
9. Git commit.

`STATE.yaml` gains a `debugs: [<issue-id>, ...]` array.

## 20. File and folder layout (final)

```
docs/
  Handsoff.md                              (index — always written)
  Handsoff/
    slice-NN-<name>.md                     (per-slice — always written)
  larv/
    STATE.yaml
    pre-flight.md
    ddd-interview/                         (Phase 0a — Layer 2)
    00-discuss/
      product-brief.md  stakeholder-map.md  glossary.md
      library-decisions.md  library-decisions-pre-input.md
      mcp-decisions.md  handoff.md
    01-domain/
    02-architecture/
      c4-context.md  c4-container.md  c4-component.md
      library-pins.md
    03-design/
      recommendations.md
      picks/<slug>.md
      mockups/<slug>/<screen>.html
      design-decision.md
      brand-spec.md  ui-design.md
    04-test-strategy/
    05-premortem/
    06-implementation/
      elephant-carpaccio.md
      slice-NN/{plan,handoff,verification}.md
    07-runtime/
    08-learnings/
    09-verification/
    decisions.md                           (ADR aggregator)
    implementation-tracker.yaml
    implementation-tracker.md
    local-learnings.md
adr/                                       (one ADR per decision)
CLAUDE.md  AGENTS.md  GEMINI.md
.cursor/rules/larv.mdc
.codex/AGENTS.md
```

Plugin internals unchanged in shape — `skills/`, `commands/`, `scripts/`, `templates/`, `bundle/` keep their current roles; content gets filled in.

## 21. Discipline rules (spec-level)

These rules apply across all phases and skills. Violations are spec violations.

1. **Venue parity (§3.1).** No internal Phase 8 logic distinct from foreign-AI instructions.
2. **Handsoff self-containment (§3.2).** No references to plugin scripts inside handsoff content.
3. **Probe-before-announce (§3.3).** No URL printed without a verified probe.
4. **Recommendation block (§15.1) as a strong norm.** Every interactive question pairs with `Recommendation / Why / Tradeoffs`.
5. **Auto-commit safety (§18).** No commits to dirty paths outside `docs/` and `adr/`. Branch detection before assumption.
6. **VM constant isolation (§14.4).** `LARV_VM_HOST` lives in one module.

## 22. MVP vs Layer 2 split

### 22.1 MVP

A single implementation plan covering:

- Hybrid gates (§4.2) and routing menu (§4.3)
- Handsoff system (§15) — mandatory, self-contained
- Verifier (§14) and probe-before-announce
- Auto-commit policy (§18)
- Implementation tracker (§16)
- AI starting-point files (§17)
- `/larv:feature` and `/larv:debug` parity (§19)
- Spec discipline rules (§21)

After MVP execution, the plugin can be used to brainstorm Layer 2 against itself.

### 22.2 Layer 2

A second implementation plan covering:

- Phase 0a DDD interview (§5)
- Phase 0 Discuss Laravel ecosystem checklist enrichment (§6.2)
- Phase 1 Laravel-DDD mapping (§7.2)
- Phase 3 design picker + huashu mockup server (§9)
- Phase 6.5 doc-site review (§11)

### 22.3 Order of execution

MVP plan written and executed end-to-end, including a working `/larv:full` against the MVP scope. Then Layer 2 plan written and executed.

## 23. Open questions (runtime feasibility checks)

Items the spec acknowledges but defers to implementation-time validation:

1. **Huashu cross-pick consistency.** Can huashu produce 5–7 screens × 3 picks (15–21 mockups) while keeping screen shape consistent? If not, fallback per §9.1 step 6 (one mockup per pick). Decision recorded in design log at runtime.
2. **Push-protected default branch detection.** The `git push --dry-run` heuristic in §18 is approximate. Implementation may need refinement based on CI/branch-protection conventions in the team's GitHub setup.
3. **Foreign-AI tooling assumptions.** Handsoff inline snippets assume the foreign-AI venue has `bash`, `yq`, `git`, `curl`, `ssh`, and `docker` available. Spec assumes typical developer machines satisfy this; implementation may need to add a "preflight check for foreign AI" snippet at the top of `docs/Handsoff.md`.

## 24. Approved decisions (decision log)

This brainstorm session resolved the following decisions:

- DDD interview placement: separate phase before Discuss; business-process only with tech-leak guard (§5).
- Gate model: hybrid — soft inter-phase, hard at Phase 7 and 8 (§4.2).
- Design picker: user browses getdesign.md in their own browser; agent provides recommendation memo and fetches selected picks; mockup server shows the user's app in each picked style (§9).
- Mockup storage: WebFetch on pick (no full vendored catalog); cached under `03-design/picks/<slug>.md`.
- Verifier strategy: live-scan only with auto-pick on conflict and probe-before-announce (§14, §3.3).
- VM IP: hardcoded to `31.220.79.31` in `scripts/lib/vm.sh`.
- Handsoff: mandatory, venue-agnostic, per-slice + index, self-contained (§15).
- Routing menu: same-session / subagents / handoff; mixed dropped (§4.3).
- Phase numbering: preserved; insert Phase 0a and Phase 6.5 without renumbering.
- C4 diagrams: Mermaid only.
- Decisions log: ADRs in `adr/` plus aggregator in `docs/larv/decisions.md`.
- Slice cards: 13 fields (§10.1).
- LEARNINGS path for foreign AI: project-local `local-learnings.md`; harvest by `/larv:learn` is Claude-Code-only.
- Git commits: per approved phase, default-branch-aware, `docs/`+`adr/` only (§18).
- Doc-site generator: Docsify (zero-build, npx).
- Recommendation rule: every interactive question (strong norm).
- Discuss Laravel ecosystem checklist: full coverage (§6.2).
- Phase 1 DDD-to-Laravel mapping: WebFetch the medium article URL at runtime; do not bake article content into spec.
- /larv:feature and /larv:debug: full parity with /larv:full disciplines (§19).
- Implementation tracker: yaml + rendered md (§16).
- AI starting-point files: CLAUDE.md, AGENTS.md, .cursor, GEMINI.md, .codex (§17).
- MVP-first execution; Layer 2 after MVP is usable.
