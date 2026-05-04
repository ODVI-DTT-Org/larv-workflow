# larv Plugin — Shell + Composition Strategy (Sub-project A)

**Date:** 2026-05-04
**Author:** itranario@oakdriveventures.com
**Status:** Design — pending user review
**Scope:** Sub-project A of the larv plugin project. Defines the plugin's shell, composition policy, command surface, orchestration model, state management, self-improvement loop, and adoption flow. **Does not** specify the per-phase prompts (sub-project B), the sandbox runtime (sub-project C), Laravel Cloud deployment (sub-project D), or the deep self-improvement governance details (sub-project E).

---

## 1. One-paragraph summary

`larv` is a Claude Code plugin distributed as a **bundled marketplace** that orchestrates four upstream skills (`masterplan`, `superpowers-laravel`, `domain-driven-design`, `huashu-design`) into an opinionated end-to-end Laravel-app workflow. It exposes 8 commands; the flagship is `/larv:full`, which drives 12 numbered phases (0 through 11), preceded by a pre-flight setup step (Phase −1), from brainstorm through Laravel Cloud deployment. Each phase runs in a fresh subagent to keep context bounded; durable state lives in `docs/larv/STATE.yaml` so any team member can `/larv:resume`. A built-in self-improvement loop (`/larv:learn`) captures lessons from every run and proposes edits to the plugin's own skill files via PR. The plugin **wraps and composes** upstream skills — it never forks or duplicates them.

## 2. Goals

1. **End-to-end Laravel app delivery driven by AI** — the user answers questions, reviews docs, and QAs in a browser; never opens an editor.
2. **Bounded context** — `/larv:full` must run a 12-phase project without context death.
3. **Composes, doesn't duplicate** — wrap `masterplan`, `superpowers-laravel`, `domain-driven-design`, `huashu-design`. Track upstream improvements automatically.
4. **Self-improving** — every run can propose edits to the plugin's own skills via PR. Compounds across the team.
5. **Resumable + team-shareable** — durable `STATE.yaml` makes any project resumable by any team member.
6. **Greenfield AND existing apps** — `/larv:full` for new projects, `/larv:adopt` for existing ones.

## 3. Non-goals

- Defining per-phase prompts in detail (deferred to sub-project B).
- Building or describing the cloud VM provisioning runtime (deferred to sub-project C).
- Specifying Laravel Cloud integration mechanics (deferred to sub-project D).
- Open-sourcing the plugin publicly. The plugin is private to the team's GitHub org.
- Supporting non-Laravel projects.

## 4. Composition policy: wrap, never fork

The plugin's own skills are **routing skills** — they invoke upstream skills with additional Laravel-specific context. The plugin never copies upstream skill content into its own files.

| Upstream skill | Used in | larv adds |
|---|---|---|
| `superpowers-laravel:brainstorm` | Phase 0, `/larv:brainstorm` | DDD viability check trigger; library policy questions (Filament/Nova/Horizon/Reverb/Pulse/Cashier); MCP enablement Q's |
| `masterplan-discuss` | Phase 0 | — |
| `huashu-design` (truth-first) | Phases 0, 2, 3 | Forces context7 MCP lookups for any library claim; activates fallback advisor when design direction is missing |
| `domain-driven-design` (gated) | Phase 1 | Gated by larv's viability check (≥2 of 4 criteria) |
| `masterplan-c4-architecture` | Phase 2 | — |
| `masterplan-master-design` | Phases 2, 3 | — |
| `masterplan-test-strategy` | Phase 4 | — |
| `superpowers-laravel:laravel-tdd` | Phase 4 | — |
| `masterplan-bug-premortem` | Phase 5 | — |
| `masterplan-adversarial-review` | Phase 5 | — |
| `superpowers-laravel:write-plan` | Phase 6 | Library policy + MCP context injection |
| `masterplan-implementation` | Phase 6 | — |
| `superpowers-laravel:execute-plan` | Phase 8 | Slice handoff template; auto-deploy to VM via SSH+rsync |
| `superpowers-laravel:laravel-*` (policies, form-requests, eager-loading, etc.) | Phase 8 (contextual) | Invoked by slice subagent when domain matches |
| `masterplan-handoff` | Every phase + every slice | — |
| `masterplan-verification` | Phase 9 | — |
| `masterplan-doc-governance` | Phase 0 init + ongoing | Ensures `docs/larv/` index integrity |

**Rule:** if `larv` ever needs to add behavior that overlaps with an upstream skill, the change goes upstream (PR to the upstream repo) rather than being patched into `bundle/`. The bundle stays as close to vanilla as possible.

## 5. Distribution: bundled marketplace

`larv` ships as a single Claude Code plugin marketplace that pins known-good versions of the four upstream sources in `bundle/`. One install, no missing dependencies.

### Plugin repo structure

```
larv/
├── .claude-plugin/plugin.json
├── README.md                            user-facing entry doc (guide companion to this spec)
├── LEARNINGS.md                         compounding self-knowledge (read by every run)
├── CHANGELOG.md                         SemVer log
├── commands/                            8 thin command wrappers
│   ├── larv-full.md
│   ├── larv-adopt.md
│   ├── larv-feature.md
│   ├── larv-debug.md
│   ├── larv-brainstorm.md
│   ├── larv-learn.md
│   ├── larv-status.md
│   └── larv-resume.md
├── skills/                              larv's routing skills
│   ├── larv-orchestrator/SKILL.md       the /larv:full controller
│   ├── larv-discuss/SKILL.md            Phase 0 wrapper
│   ├── larv-domain/SKILL.md             Phase 1 wrapper
│   ├── larv-architecture/SKILL.md       Phase 2 wrapper
│   ├── larv-design/SKILL.md             Phase 3 wrapper
│   ├── larv-tests/SKILL.md              Phase 4 wrapper
│   ├── larv-premortem/SKILL.md          Phase 5 wrapper
│   ├── larv-plan/SKILL.md               Phase 6 wrapper
│   ├── larv-provision/SKILL.md          Phase 7 wrapper
│   ├── larv-implement/SKILL.md          Phase 8 wrapper (slice loop driver)
│   ├── larv-verify/SKILL.md             Phase 9 wrapper
│   ├── larv-deploy/SKILL.md             Phase 10 wrapper
│   ├── larv-learn/SKILL.md              Phase 11 + on-demand
│   ├── larv-handoff/SKILL.md            slice + phase handoff producer
│   └── larv-adopt/SKILL.md              the /larv:adopt controller
├── bundle/                              pinned upstream sources
│   ├── masterplan/                      vendored, version-pinned
│   ├── superpowers-laravel/             vendored, version-pinned
│   ├── domain-driven-design/            single-skill vendor from antigravity-awesome-skills
│   └── huashu-design/                   vendored, version-pinned
├── templates/                           .md templates copied into user projects
│   ├── slice-handoff.md
│   ├── sandbox-runbook.md
│   ├── pre-flight.md
│   ├── project-lessons.md
│   └── adoption-report.md
├── scripts/                             runtime helpers
│   ├── vm-bootstrap.sh
│   ├── docker-compose.template.yml
│   └── learn-aggregator.sh              gh PR opener used by /larv:learn
├── adr/                                 plugin-level architecture decisions
├── migrations/state/                    STATE.yaml schema migrations
│   └── v1-to-v2.sh
└── tests/                               plugin regression tests on fixture projects
    ├── fixtures/
    │   ├── greenfield-todo/
    │   └── existing-blog/
    └── ...
```

### Maintenance: hybrid Renovate

- Patch versions of bundled upstream auto-merge if CI passes
- Minor/major versions open PR for maintainer review
- CI runs `tests/fixtures/*` against every Renovate PR
- `.github/renovate.json` configures per-dependency rules

## 6. Command surface (8 commands)

| Command | Purpose | Mode |
|---|---|---|
| `/larv:full` | Greenfield: design + build a new Laravel app | Long-running, multi-phase |
| `/larv:adopt` | Bring an existing Laravel app under management | Long-running, read-only on user code |
| `/larv:feature <name>` | Add a feature to a managed app | Mini-flow |
| `/larv:debug <issue>` | Fix a bug in a managed app | Diagnostic loop |
| `/larv:brainstorm` | Standalone brainstorm phase (exploratory) | Single-phase |
| `/larv:learn [--quick\|--full\|--since=<date>\|--dry-run]` | Propose plugin improvements | Auto + manual |
| `/larv:status [--json]` | Print `STATE.yaml` summary | Read-only |
| `/larv:resume [--force-unlock]` | Continue from last `STATE.yaml` checkpoint | Recovery |

## 7. /larv:full phase workflow

12 numbered phases (0–11), preceded by Phase −1 (pre-flight setup). Phase 5 can loop back to 2/3/4 if showstoppers found. All other phases are one-way once approved.

| # | Phase | Skills invoked | User does | Agent does | Outputs |
|---|---|---|---|---|---|
| −1 | Pre-flight | (larv) | confirm budget | load `LEARNINGS.md` digest, ping VM, verify bundle, check MCPs, estimate budget | `pre-flight.md`, init `STATE.yaml` |
| 0 | Discuss | `superpowers-laravel:brainstorm` + `masterplan-discuss` + huashu truth-first | answer Qs | brainstorm; library/MCP Qs; DDD viability check | `00-discuss/{product-brief,stakeholder-map,glossary,handoff}.md` |
| 1 | Domain | `domain-driven-design` (gated) | review | DDD model OR flat domain model | `01-domain/*` |
| 2 | Architecture | `masterplan-c4-architecture` + `masterplan-master-design` | review | C4 levels 1–3, **library policy locked**, ADRs | `02-architecture/*` |
| 3 | Design | `masterplan-master-design` + `huashu-design` | review | data model, API surface, UI screens, brand spec | `03-design/*` |
| 4 | Test strategy | `masterplan-test-strategy` + `superpowers-laravel:laravel-tdd` | review | Pest layers, Playwright flows, acceptance criteria per feature | `04-test-strategy/*` |
| 5 | Premortem | `masterplan-bug-premortem` + `masterplan-adversarial-review` | review | failure modes, adversarial pass, risks register; **may loop back to 2/3/4** | `05-premortem/*` |
| 6 | Slice plan | `superpowers-laravel:write-plan` + `masterplan-implementation` | approve slice list | Elephant Carpaccio: ~1-day vertical slices | `06-implementation/elephant-carpaccio.md` |
| 7 | Provision sandbox | (larv) | confirm VM + domain | SSH to VM, docker compose up, firewall, reverse proxy, TLS, seeded DB | `07-runtime/sandbox-runbook.md` |
| 8 | Implementation loop | `superpowers-laravel:execute-plan` + contextual `laravel-*` | QA in browser, give feedback in English | per slice: code → rsync to VM → migrate → test → Playwright → iterate → notify | `slice-NN/{plan,handoff,verification}.md` |
| 9 | Final verification | `masterplan-verification` | sign off | full suite, smoke, perf | `09-verification/final-report.md` |
| 10 | Deploy | (sub-project D) | confirm cutover | Laravel Cloud deploy | `07-runtime/laravel-cloud.md` updated |
| 11 | Learn | `/larv:learn --full` | review PR (optional) | aggregate `[plugin]` notes, open PR on plugin repo | plugin's `LEARNINGS.md` + skill edits |

Phase 8 auto-fires `/larv:learn --quick` every 5 completed slices, in parallel with the next slice.

## 8. Subagent orchestration model

`/larv:full` runs as a **thin orchestrator**. Each phase spawns a fresh subagent. Within Phase 8, each slice spawns a fresh subagent. Composition stops at the phase level — a phase subagent invokes upstream skills in its own context (we don't go 3 deep).

### Orchestrator steady-state context

| Item | Size | Notes |
|---|---|---|
| `STATE.yaml` | ~50 lines | regenerated each phase |
| `LEARNINGS digest` | ~200 lines | summarized from `LEARNINGS.md` at pre-flight |
| Current phase output paths | list of strings | populated as phases complete |
| Active gate state | a few lines | "phase 5 awaiting user review" |

### Subagent contract

Inputs (orchestrator → subagent):

```yaml
skill_invocations: [...]
goal: |
  <one paragraph>
inputs:
  prior_artifacts: [paths only]
  learnings_digest: docs/larv/.cache/learnings.md
  user_prompt: "<inline if Phase 0>"
outputs_required: [absolute paths]
constraints:
  token_budget: <int>
  time_budget_minutes: <int>
  mcps_required: [...]
escalate_to_user_on:
  - <list of triggers>
```

Returns (subagent → orchestrator):

```yaml
status: success | partial | blocked
output_paths: [...]
state_updates: { ... }
plugin_improvement_notes: [{ tag, theme, body }]
budget_consumed: { tokens, minutes }
```

The orchestrator atomic-merges `state_updates` into `STATE.yaml` and discards everything else from the subagent's transcript. Pure handoff via files.

### Phase 8 special handling

```
loop slice in slice_plan:
    spawn slice_subagent(slice)
    update STATE.yaml
    if completed_count % 5 == 0:
        spawn /larv:learn --quick      (fire-and-forget, parallel)
    if user_feedback_pending:
        spawn slice_iterate_subagent(slice, feedback)
```

Slices are **sequential by default**. Parallelism is opt-in per slice via `parallel: true` annotation in the slice plan, with explicit `depends_on` declarations.

### Failure handling

| Failure | Behavior |
|---|---|
| Phase subagent returns `blocked` | Orchestrator pauses, surfaces issue, awaits user |
| Phase subagent returns `partial` | Orchestrator records gap, asks user accept-and-continue or re-run |
| Slice fails 3× on VM | Halt and ask user (4 options: retry, rollback, skip, abandon). Configurable via `STATE.yaml.policies.slice_failure` |
| Orchestrator dies (token limit, crash, terminal closed) | `STATE.yaml` is source of truth. `/larv:resume` continues |

## 9. State + resume model

Single source of truth: `docs/larv/STATE.yaml`. Committed to git. Atomic writes (write-temp + rename). File-locked at `docs/larv/.lock` to prevent concurrent runs (stale locks >30 min auto-cleared).

### Schema (v1)

```yaml
schema_version: 1

project:
  name: <string>
  slug: <project-name>-<YYYY-MM>
  greenfield: <bool>                       # false for /larv:adopt
  mode: greenfield | adopted               # determines which command can run
  started_at: <ISO8601>
  last_updated_at: <ISO8601>

plugin:
  name: larv
  version: <semver>
  bundle_versions:
    masterplan: <semver>
    superpowers-laravel: <semver>
    domain-driven-design: <semver>
    huashu-design: <semver>
  learnings_digest_hash: <hash>

phase:
  current: <int|str>                       # int for /larv:full, "Ax" for adopt
  last_completed: <int|str>
  gates_pending: [phase_ids]

gates:                                     # append-only audit trail
  - { phase, passed_at, approved_by }

slices:                                    # populated after Phase 6
  total: <int>
  status:
    "01": { state: pending|in_progress|completed|blocked, attempts: <int>, ... }

sandbox:
  vm_host: <string>
  app_url: <url>
  status: running|stopped
  last_deploy_at: <ISO8601>
  last_test_run_at: <ISO8601>
  last_test_result: passing|failing

budget:
  estimated_total: { tokens, minutes, cost_usd }
  consumed: { tokens, minutes, cost_usd }
  cap_policy: pause_at_120pct              # default

learn:
  last_quick_at: <ISO8601>
  last_quick_pr: <url>
  last_full_at: <ISO8601>
  pending_notes_count: <int>

errors_unresolved:
  - { phase, slice, kind, at, resolved: bool }

policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

### `/larv:status` behavior

Reads `STATE.yaml`, prints human-readable summary. `--json` flag dumps raw YAML.

### `/larv:resume` decision tree

```
read STATE.yaml
if errors_unresolved:                 → surface errors, await direction
elif gates_pending:                   → ask user to approve/reject pending gate
elif budget.consumed > 1.2 × estimate → pause + ask cap policy
elif phase.current == 11 done         → "project complete"
elif phase.current < 8                → spawn next phase subagent
elif phase.current == 8:
    if slice in_progress              → resume that slice subagent
    elif slices remaining             → spawn next slice subagent
    else                              → advance to phase 9
elif phase.current >= 9               → spawn next phase subagent
```

## 10. Self-improvement loop

Three layers, two storage targets, one governance gate.

### Storage targets

| Target | Lives in | Owns |
|---|---|---|
| `[project]` learnings | user app `docs/larv/08-learnings/project-lessons.md` | "specific to this app" |
| `[plugin]` learnings | plugin repo `LEARNINGS.md` + skill edits | "every Laravel project under larv should know" |

Tagging happens at capture time. Slice/phase handoffs include `## Plugin Improvement Notes` section with `[plugin]` or `[project]` prefix.

### Layer 1 — Passive capture

Every slice and phase handoff has the section. Filled when:

- API drift (model corrected about a library API)
- Question gap (user repeated themselves during discuss)
- Pattern win (non-obvious approach worked cleanly)
- Failure mode (something broke twice)
- Project quirk (specific to this app)

### Layer 2 — Active aggregation (`/larv:learn`)

| Mode | Trigger | Scope |
|---|---|---|
| `--quick` | Auto every 5 slices in Phase 8 | last 5 slices, `[plugin]` only, only if patterns clear |
| `--full` | Mandatory at end of `/larv:full`, `/larv:feature`, `/larv:debug` | all `[plugin]` notes since last learn |
| `--since=<date>` | User-invoked | as specified |
| `--dry-run` | Any of the above + `--dry-run` | print proposed diffs without committing |

Aggregator (runs as fresh subagent):

1. Reads all `[plugin]`-tagged notes in scope
2. Reads current `LEARNINGS.md` and relevant `skills/*/SKILL.md`
3. Clusters by theme: API drift, question gap, pattern win, failure mode, library version
4. Drafts edits: new `LEARNINGS.md` entries, diffs to skill prompts, new ADRs if structural
5. Branches plugin repo (`learn/<project-slug>-<date>`), commits with source-slice citations, opens PR via `gh`
6. Posts PR URL in project chat

### Layer 3 — Plugin self-context

`LEARNINGS.md` is loaded in pre-flight as the FIRST context input for every run. Indexed (not chronological). Sections:

```
# LEARNINGS

## Library version notes
## Discuss-phase questions (added)
## Patterns promoted
## Failure modes prevented
## Composition lessons
```

When file grows past ~500 lines, `/larv:learn` proposes a structural split.

### Safeguards

1. **PR-gated, never auto-merge.** Human reviewer required for every plugin edit.
2. **Diffs must cite source.** Every proposed edit links to the slice handoffs that motivated it.
3. **Skill regression tests in CI.** `tests/fixtures/*` exercises bundled + larv skills on canonical inputs. PRs that break tests are blocked.

## 11. /larv:adopt — adoption flow for existing apps

Read-only-first. Produces `docs/larv/` retroactively from code + targeted user interview. Zero code changes by default.

### Phases (mirror `/larv:full` but inverted)

| # | Phase | Source | Outputs |
|---|---|---|---|
| A0 | Survey (read-only, automated) | composer.json, routes, models, migrations, tests, README, docker-compose.yml, CI | `00-discuss/inventory.md` |
| A1 | Interview | targeted Qs the survey couldn't answer | `00-discuss/{product-brief,decisions-history}.md` |
| A2 | Domain reverse-engineering | namespace/module structure, Eloquent relationships | `01-domain/*` (or flat model) |
| A3 | Architecture extraction | docker-compose + app structure + composer.json | `02-architecture/*` (with as-built ADRs) |
| A4 | Design extraction | migrations, routes, Filament/Nova resources, Blade | `03-design/*` |
| A5 | Test reality | existing test inventory + coverage | `04-test-strategy/*` (gaps flagged) |
| A6 | Risk register | static analysis (N+1, mass assignment, exposed routes) + adversarial review | `05-premortem/risks-register.md` only |
| A7 | STATE.yaml seed | `mode: adopted`, `greenfield: false` | `STATE.yaml` |
| A8 | Sandbox bootstrap (optional) | mirror prod stack, seeded DB | `07-runtime/sandbox-runbook.md` |
| A9 | Adoption report | summary + top 3–5 `/larv:feature` recommendations | `docs/larv/ADOPTION-REPORT.md` |

Phases 6–10 of `/larv:full` are **skipped** (no implementation, no slice plan, no deploy).

### Confidence flags

Every section produced by adopt carries a confidence marker:

```markdown
### Orders [confidence: high]
Extracted from `app/Modules/Orders` namespace; clear aggregate root.

### Reports [confidence: low — placeholder, needs human review]
Heuristic extraction from controllers.
```

### Edge case: codebase too gnarly

If A0 detects red flags (Laravel < 9, vendor-patched core, no tests, custom autoloader), adoption returns a **health report** instead of full docs and recommends remediation before retrying.

### Post-adoption mode

`STATE.yaml` flips to `mode: adopted`. From then on:

- `/larv:feature <name>` reads existing docs, proposes deltas, runs slice loop
- `/larv:debug <issue>` reads existing docs, runs diagnostic loop
- `/larv:full` **refuses to run**. Override `--re-greenfield` exists but is destructive and warns loudly
- `/larv:learn` continues as normal

## 12. Captured decisions (smaller defaults)

| # | Decision | Default | Override knob |
|---|---|---|---|
| 4 | Slice-failure escalation | 3 attempts → halt + ask user (retry/rollback/skip/abandon) | `STATE.yaml.policies.slice_failure.{max_attempts,default_action}` |
| 5 | Sandbox VM multi-tenancy | One VM, many projects, subdomain routing per slug `<name>-<YYYY-MM>` | `--vm-mode=per-project` (future) |
| 6 | Budget cap policy | `pause_at_120pct` | `STATE.yaml.budget.cap_policy` ∈ {`pause_at_100pct`, `pause_at_150pct`, `never_pause`} |
| 7 | Bundle maintenance | Hybrid Renovate: patch auto-merge if CI green, minor/major opens PR | `.github/renovate.json` |

## 13. Plugin name + repo

- **Name:** `larv`
- **Repo:** single private GitHub repo owned by the team's org (e.g., `<your-org>/larv`)
- **License:** internal/proprietary (private)
- **Versioning:** SemVer

## 14. Out of scope (future sub-projects)

| Sub-project | Coverage |
|---|---|
| **B** Phase workflow + document model | Detailed prompts for each phase skill; the actual `docs/larv/` document templates and cross-references; gate review checklists |
| **C** Sandbox runtime | VM provisioning script, Docker Compose template, reverse proxy + TLS automation, SSH key management, secrets handling, multi-project isolation hardening |
| **D** Laravel Cloud deployment | Phase 10 mechanics, environment management, cutover runbook |
| **E** Self-improvement governance | Reviewer rotation, merge cadence, breaking-change policy for skill edits, telemetry-driven prioritization |

## 15. Refinements deferred to implementation plan

These were called out during brainstorm but don't block the spec:

- **Doc collision strategy** — agent-owned sections vs `<!-- HUMAN NOTES -->` blocks preserved verbatim. Implementation detail in `larv-orchestrator` skill.
- **Run telemetry** — `runs/<run-id>.jsonl` event log per project to feed `/larv:learn` with quantitative signal (time-per-phase, retry counts, etc.).
- **Huashu fallback advisor** — auto-trigger in Phase 3 when user gives no design direction.
- **Plugin CI** — `tests/fixtures/{greenfield-todo,existing-blog}/` exercise the bundled + larv skills. CI pipeline definition in implementation plan.
- **STATE.yaml schema migrations** — `migrations/state/` scripts; tested in CI.

## 16. Acceptance criteria for sub-project A

The implementation of this spec is "done" when:

1. The plugin repo is initialized with the structure in §5
2. `.claude-plugin/plugin.json` is valid and lists all 8 commands + 15 skills
3. The four upstream sources are vendored into `bundle/` at pinned versions (versions chosen in implementation plan)
4. `/larv:status` works against an empty `STATE.yaml`
5. `/larv:resume` correctly handles the empty-state, gate-pending, and errors-unresolved branches of the decision tree
6. `STATE.yaml` schema v1 has at least one passing migration test (v1-to-v1 noop)
7. `LEARNINGS.md` exists with the documented section structure (initial empty)
8. `tests/fixtures/greenfield-todo/` has a smoke test that exercises the orchestrator stub through Phase −1 (pre-flight) without errors
9. `README.md` matches the usage guide in this design package

Subagent skills, prompts, and `/larv:full` end-to-end execution are **NOT** required for sub-project A's implementation — those are sub-project B.

## 17. Risks (specific to this sub-project)

| Risk | Mitigation |
|---|---|
| Bundle drift breaks composition silently | CI runs fixture tests on every Renovate PR |
| `STATE.yaml` corruption during crash | Atomic writes (write-temp + rename); committed to git for history |
| Concurrent team runs race on same project | File lock; stale-lock auto-clear; `--force-unlock` override |
| LEARNINGS.md grows unbounded | `/larv:learn` proposes structural split past ~500 lines; sectioned index, not chronological |
| Adoption produces lying docs for messy codebases | Confidence flags per section; A0 health-report short-circuit for unsupportable codebases |
| Self-improvement loop degrades skills over time | PR-gated; source-citing diffs required; skill regression tests in CI |

## 18. Glossary

- **Bundled marketplace:** A Claude Code plugin that vendors pinned versions of upstream plugins/skills inside its own `bundle/` directory, exposed as a single install.
- **Phase subagent:** A fresh-context Claude subagent spawned by the orchestrator to handle one phase of `/larv:full`, returning structured output that the orchestrator merges into `STATE.yaml`.
- **Slice:** A vertical implementation increment (~1 day of work) produced by Phase 6's Elephant Carpaccio plan.
- **Greenfield mode / adopted mode:** STATE.yaml flag distinguishing projects built by `/larv:full` (greenfield) from existing apps brought under management by `/larv:adopt` (adopted). Determines which commands are allowed.
- **Plugin Improvement Notes:** A section in every handoff doc capturing tagged learnings (`[plugin]` or `[project]`) for later aggregation by `/larv:learn`.
- **Composition stops at the phase:** A phase subagent invokes upstream skills in its own single context; we don't fan out a third level of subagents per skill invocation.
