# larv — Usage Guide

A Claude Code plugin that turns AI into a full Laravel development team. You answer questions, review docs, and click around in a browser. The agent does the rest.

> Companion to the formal design spec at `2026-05-04-larv-plugin-shell-design.md`. This guide is forward-looking — it describes how the plugin behaves once implemented. Treat it as the behavioral reference for sub-project A.

---

## What `larv` is

A bundled-marketplace Claude Code plugin. One install gives you 8 commands that orchestrate four underlying skills (`masterplan`, `superpowers-laravel`, `domain-driven-design`) into a complete Laravel-app workflow — from blank slate to production deploy.

Five things it does that nothing else does together:

1. **End-to-end** — brainstorm → DDD viability → C4 architecture → UI design → tests → premortem → slices → sandbox → deploy. One command, twelve numbered phases (with a pre-flight setup step).
2. **Subagent-driven** — every phase runs in a fresh agent context, so a 3-day project doesn't blow up your conversation buffer.
3. **Resumable** — `docs/larv/STATE.yaml` makes any project recoverable by any teammate at any point.
4. **Self-improving** — every project run can propose edits to the plugin's own skills via PR. The plugin gets smarter with use.
5. **Greenfield AND existing apps** — `/larv:full` for new, `/larv:adopt` for existing.

## Prerequisites

- Claude Code installed
- A cloud VM you can SSH to (the sandbox)
- A Laravel Cloud account (production deploys)
- A GitHub repo for the plugin (private or org-internal — this is where self-improvement PRs land)
- The four bundled upstream plugins are included automatically — no separate install

## Installation

```
claude plugin install <larv-workflow>/larv
```

After install, `/larv:status` works in any directory. New projects default to `docs/larv/` for artifacts.

## Codex CLI compatibility

`larv` also ships Codex plugin metadata in `.codex-plugin/plugin.json` and a local marketplace file at `.agents/plugins/marketplace.json`.

For local Codex testing from this repository root:

```
codex plugin marketplace add .
```

Codex reads the marketplace entry for `larv`, which points to `./plugins/larv`. In this repository that path is a symlink back to the plugin root so the plugin is not duplicated. See `docs/CODEX.md` for details.

## The 8 commands at a glance

| Command | When to use |
|---|---|
| `/larv:full` | Starting a brand-new Laravel app from scratch |
| `/larv:adopt` | You have an existing Laravel app and want to bring it under `larv` management |
| `/larv:feature <name>` | Add a feature to a project already managed by `larv` |
| `/larv:debug <issue>` | Fix a bug in a project already managed by `larv` |
| `/larv:brainstorm` | Just want to think through an idea without committing to building it |
| `/larv:learn` | Manually trigger plugin self-improvement aggregation |
| `/larv:status` | "Where am I in this project?" — prints `STATE.yaml` summary |
| `/larv:resume` | Pick up a project where you (or a teammate) left off |

---

## Example 1 — Greenfield: build a todo app with `/larv:full`

You start in an empty directory. You want a multi-user todo app with shared lists, Filament admin, and Stripe billing.

### Your prompt

```
/larv:full

I want to build a small todo app. Users sign up with email + password,
create todos, organize them in lists, mark them done, and share lists
with other users via email invite. Use Filament for the admin panel.
Eventually we'll add paid tier with Stripe — set it up so we can add
billing later without a rewrite.
```

### What you'll see — Phase −1 (pre-flight)

```
[larv pre-flight]

Project: todo-app  (greenfield, slug: todo-app-2026-05)
Plugin:  larv 0.3.1
Bundles: masterplan 4.2.0 · sp-laravel 0.1.5 · ddd 10.5

VM check:     ✅ vm.example.com reachable
Bundle check: ✅ all 3 bundled plugins present
MCP check:    ✅ context7 ✅ playwright (laravel-mcp not configured — recommend enabling)

LEARNINGS digest loaded — 12 entries from prior runs:
  • Filament 4 schema API change (2026-04)
  • Soft-delete defaults for shared resources (2026-04)
  • DatabaseTransactions over RefreshDatabase by default (2026-03)
  • ... (9 more)

Estimated budget: 4 slices · ~3.5 hours · ~$28
Cap policy: pause at 120%

Proceed to Phase 0 (Discuss)? [Y/n]
```

You: `Y`

### What you'll see — Phase 0 (Discuss)

The agent asks one question at a time, mostly multiple-choice given evidence:

```
[Phase 0 — Discuss]

Q1. Authentication:
    (a) Email + password (Laravel built-in) ← matches your prompt
    (b) Magic link only
    (c) Social (Google/GitHub) + email fallback
    (d) SSO (SAML)
```

You: `a`

```
Q2. Email invite — when an invitee doesn't have an account yet:
    (a) Email with "create account" link, list appears after signup
    (b) Invite expires after 7 days if not accepted
    (c) Both (a) and (b) ← recommended
```

You: `c`

```
Q3. Soft deletes? (LEARNINGS suggests asking — added 2026-04-12)
    (a) Yes on todos and lists (recoverable)
    (b) No, hard delete only
    (c) Lists only, not todos
```

You: `a`

```
Q4. Multi-tenancy?
    (a) User-scoped (single DB, scoped queries) ← matches your prompt
    (b) Tenant-scoped (organizations)
    (c) No multi-tenancy, flat user model with admin role
```

You: `a`

```
Q5. MCPs to enable on the VM:
    (a) context7 (already on)
    (b) Playwright (recommended for UI tests)
    (c) Laravel MCP (recommended for artisan introspection)
    (d) all of the above ← recommended
```

You: `d`

```
Q6. DDD viability check
    Criteria: complex/fast-changing rules · multi-team collisions ·
              unstable contracts · audit-critical
    
    Assessment: a todo app with sharing meets ≤1 of these.
    Recommendation: skip DDD, use a flat domain model.
    
    Override? [N/y]
```

You: `N`

```
[Phase 0 complete]

Outputs:
  docs/larv/00-discuss/product-brief.md
  docs/larv/00-discuss/stakeholder-map.md
  docs/larv/00-discuss/glossary.md
  docs/larv/00-discuss/handoff.md

Plugin Improvement Notes: 0
Budget consumed: 8min · $1.20  (3% of estimate)

Gate: please review the artifacts above. Approve to proceed to Phase 1.
```

You read the briefs. You: `approved`.

### What you'll see — Phases 1–6 (compressed)

The agent moves through:

- **Phase 1 — Domain.** Flat model: `User`, `List`, `Todo`, `Invite`. Output: `docs/larv/01-domain/`.
- **Phase 2 — Architecture.** C4 levels 1–3. Library policy locked: Laravel 12, Filament 4, Sanctum, MySQL, Redis, no Horizon for v1, Cashier deferred to billing slice. ADRs: 0001-laravel-12, 0002-filament-vs-nova (chose Filament), 0003-defer-billing. Output: `docs/larv/02-architecture/`.
- **Phase 3 — Design.** Data model (4 tables, 3 pivots), API surface (REST + Filament), 7 UI screens, brand spec drafted via local Attio-style references (you upload your logo, agent extracts palette). Output: `docs/larv/03-design/`.
- **Phase 4 — Test strategy.** Pest unit + feature, Playwright for invite flow, 12 acceptance criteria. Output: `docs/larv/04-test-strategy/`.
- **Phase 5 — Premortem.** Two showstoppers found:
  1. Email-invite race condition (two invites for same email + signup → duplicate access)
  2. Soft-delete + sharing — when an owner soft-deletes a list, do collaborators see it gone?
  
  Loops back to Phase 3 to design `Invite` consolidation logic and a `list.deleted_for` policy. Re-runs Phase 4 to add tests for both. Output: `docs/larv/05-premortem/`.
- **Phase 6 — Slice plan.** Elephant Carpaccio: 4 slices, ~1 day each.
  ```
  slice-01-auth         User signup, login, profile
  slice-02-todos        Lists + todos, CRUD, mark done
  slice-03-sharing      Email invites, collaborator access, deletion policy
  slice-04-admin        Filament admin panel
  ```

You approve each phase as it completes. Total time so far: ~50 minutes, ~$8.

### What you'll see — Phase 7 (provision sandbox)

```
[Phase 7 — Provisioning sandbox]

SSH to vm.example.com as deploy ............. ✅
Generated SSH key larv_todo-app-2026-05_ed25519
Apt update + Docker prerequisites ........... ✅
Docker compose stack:
  - app (php-fpm 8.3)
  - nginx
  - mysql 8.4
  - redis 7
  - mailpit (dev SMTP)
.................................................. ✅
Firewall (ufw): allow 80, 443, 8025 .......... ✅
Reverse proxy: nginx → app:8000 .............. ✅
DNS: A record todo-app-2026-05.vm.example .... ✅
TLS: Let's Encrypt cert + auto-renew ......... ✅
Seeded DB with admin user .................... ✅
Smoke test: GET / returns 200 ................ ✅

App URL:  https://todo-app-2026-05.vm.example
Login:    test@example.com / <generated-by-seeder> (seeded)

Output:   docs/larv/07-runtime/sandbox-runbook.md
```

### What you'll see — Phase 8 (implementation loop)

The agent picks up slice-01-auth. Each slice runs in a fresh subagent:

```
[Phase 8 — Slice 01: Auth]

Subagent spawned (fresh context, budget 60min, $5)
  → reads slice-01/plan.md
  → invokes superpowers-laravel:execute-plan
  → invokes superpowers-laravel:laravel-form-requests (contextual)
  → writes: 14 files (User model, RegisterController, LoginController,
            ProfileController, 8 Pest tests, 2 Playwright tests, 1 migration)
  → rsyncs to vm.example.com:/srv/todo-app-2026-05/
  → runs: docker compose exec app php artisan migrate
  → runs: docker compose exec app php artisan test --parallel
                                                  ✅ 8/8 passing
  → runs: docker compose exec app npx playwright test
                                                  ✅ 2/2 passing
  → produces: slice-01/handoff.md, slice-01/verification.md
  → returns: status=success, budget=42min, $3.80

[Slice 01 ready for QA]

URL:        https://todo-app-2026-05.vm.example/register
Walkthrough:
  1. Open URL above
  2. Sign up with any email + password
  3. Verify redirect to /dashboard
  4. Logout, log back in
  5. Edit profile

After you click around, paste any feedback in the chat in plain English.
Or type "approved" to move to slice 02.
```

You open the URL, click around. You find a bug:

```
The email validation accepts "foo@bar" with no TLD. Should require a real domain.
```

The agent spawns a slice-iterate subagent:

```
[Slice 01 iteration]
  → reads feedback
  → identifies fix: add email DNS validation rule
  → invokes superpowers-laravel:laravel-form-requests
  → writes: 2 files (RegisterRequest update, 1 new test)
  → tests: ✅ 9/9 passing
  → redeploy: ✅
  → updates slice-01/handoff.md with the iteration

Re-test at https://todo-app-2026-05.vm.example/register
```

You re-test. You: `approved`.

The loop continues for slices 02, 03, 04. After slice 02, the agent **auto-fires** `/larv:learn --quick`:

```
[learn --quick]
  → 5 slices boundary reached (counting from project start, plus prior sessions)
  → ⏭ skipped: only 2 plugin notes captured, no clear pattern yet

(continues with slice 03)
```

After slice 04 completes, all slices are done. STATE.yaml shows 4/4 complete.

### What you'll see — Phase 9 (final verification)

```
[Phase 9 — Final verification]

Full Pest suite ............ ✅ 47 tests, 142 assertions
Full Playwright suite ...... ✅ 8 flows
Coverage ................... 84% (target: 80%)
Smoke tests on staging URL . ✅
Performance check .......... ⚠ 1 N+1 on /lists endpoint (eager-load Todos)

Auto-fix? [Y/n]
```

You: `Y`. Agent fixes the N+1, re-runs perf check, all green. Output: `docs/larv/09-verification/final-report.md`.

### What you'll see — Phase 10 (deploy)

```
[Phase 10 — Deploy to Laravel Cloud]

Project: todo-app (your Laravel Cloud account)
Branch:  main
Env:     production

Pre-deploy:
  - Pest suite ............... ✅
  - DB migration plan ........ 4 migrations to run
  - Asset build .............. ✅
  - Env vars verified ........ 12/12

Deploy ......................... in progress ... ✅
Post-deploy:
  - Smoke test on prod URL ... ✅
  - DB migrate ............... ✅
  - Queue worker restart ..... ✅

Production URL: https://todo-app.laravel.cloud
Output:         docs/larv/07-runtime/laravel-cloud.md (updated)
```

### What you'll see — Phase 11 (learn)

```
[Phase 11 — /larv:learn --full]

Aggregating Plugin Improvement Notes from this run...
  • 3 [plugin] notes captured across 4 slices
  • 5 [project] notes (kept in docs/larv/08-learnings/)

Clusters identified:
  1. Question gap — "soft-delete cascade across shared resources"
     should be asked during discuss. (cited in slice-03/handoff.md)
  2. Pattern win — using Action classes + DTOs for invite consolidation
     (cited in slice-03/handoff.md)

Proposed plugin edits:
  - LEARNINGS.md: +1 entry under "Discuss-phase questions"
  - skills/larv-discuss/SKILL.md: add Q about shared-resource deletion policy

Branch:  learn/todo-app-2026-05-2026-05-07
PR:      https://github.com/larv-workflow/larv/pull/47
         Status: open, awaiting review

[/larv:full COMPLETE]

Total time: 3h 22min      Total cost: $26.40 (94% of estimate)
Output:    docs/larv/ (40 files), running app at todo-app.laravel.cloud
Plugin PR: https://github.com/larv-workflow/larv/pull/47
```

You're done. The app exists. The docs exist. The plugin got slightly smarter.

### What ended up in `docs/larv/`

```
docs/larv/
├── README.md                          index — current state, links to all docs
├── STATE.yaml                         mode: greenfield, phase 11 complete
├── pre-flight.md
├── 00-discuss/                        product brief, stakeholders, glossary, handoff
├── 01-domain/                         flat domain model
├── 02-architecture/                   c4-context, c4-container, c4-component,
│                                      library-policy, 3 ADRs
├── 03-design/                         data-model, api-surface, ui-design, brand-spec
├── 04-test-strategy/                  pest, coverage, acceptance criteria
├── 05-premortem/                      failure-modes, adversarial-review, risks
├── 06-implementation/                 elephant-carpaccio
├── 06-implementation/slice-01-auth/   plan, handoff, verification
├── 06-implementation/slice-02-todos/  plan, handoff, verification
├── 06-implementation/slice-03-sharing/plan, handoff, verification
├── 06-implementation/slice-04-admin/  plan, handoff, verification
├── 07-runtime/                        sandbox-runbook, laravel-cloud
├── 08-learnings/                      project-lessons.md (5 notes)
└── 09-verification/                   final-report
```

---

## Example 2 — Add a feature to an existing managed app via `/larv:feature`

The todo app from Example 1 is live. You want to add a "due dates with reminder emails" feature.

### Your prompt

```
/larv:feature due-dates-with-reminders

Add a due_at datetime field to todos. When a todo has a due_at,
send the owner a reminder email 24 hours before. If the todo is
shared, all collaborators get notified.
```

### What happens

```
[/larv:feature — due-dates-with-reminders]

Reading existing docs/larv/ ........ ✅ project mode: greenfield (managed)
Loading LEARNINGS digest ........... ✅ now 13 entries (1 added since last run)

[Phase F0 — Feature brief]

Q1. Reminder timing — exactly 24h before, or "morning of"?
    (a) Exactly 24h before due_at
    (b) 9am the day before due_at
    (c) Both, configurable per user
You: a

Q2. What if the user is in a different timezone than UTC?
    (a) Store all due_at in UTC, send reminders based on user.timezone
    (b) Store user-local time, ignore timezone
You: a

Q3. Recurring todos? (LEARNINGS suggests asking — added 2026-05-07)
    (a) Yes, support daily/weekly/monthly recurrence
    (b) No, one-shot todos only ← simpler
You: b

[Phase F1 — Domain delta]
  → No new bounded context needed
  → Modifying existing Todo aggregate
  Output: docs/larv/features/due-dates-with-reminders/01-domain-delta.md

[Phase F2 — Design delta]
  → +1 column on todos table (due_at, nullable timestamp)
  → +1 user column (timezone, default UTC)
  → +1 model: TodoReminder (job-tracking)
  → +1 mailable: TodoDueReminderMail
  → +1 scheduled job: SendDueReminders (hourly)
  → UI: due_at picker on todo create/edit, badge on overdue
  Output: docs/larv/features/due-dates-with-reminders/02-design-delta.md

[Phase F3 — Tests delta]
  Acceptance:
    1. Setting due_at on a todo persists in UTC
    2. SendDueReminders dispatches one mail per recipient at T-24h
    3. Sharing — all collaborators receive the mail
    4. Timezone — user in PT receives mail at correct local time
    5. No duplicate sends if scheduler runs twice in same hour
  Output: docs/larv/features/due-dates-with-reminders/03-tests-delta.md

[Phase F4 — Mini-premortem]
  Risks:
    - Scheduler missing a run → reminders late or skipped
    - Email provider rate limit on bulk sends
  Mitigations:
    - Idempotency key on TodoReminder (todo_id + due_at)
    - Queue with retry for mail jobs
  Output: docs/larv/features/due-dates-with-reminders/04-premortem.md

[Phase F5 — Slice plan]
  1 slice (estimated):
    slice-feat-due-dates: column + UI + job + tests
  Output: docs/larv/features/due-dates-with-reminders/05-slices.md

[Phase F6 — Implementation loop]
  Subagent spawned ...
  → 11 files written, 8 Pest tests, 2 Playwright tests
  → ✅ 8/8 + 2/2 passing on VM
  → URL: https://todo-app-2026-05.vm.example/lists/1/todos/new

  Ready for QA. Walkthrough:
    1. Create a new todo with due_at set to tomorrow
    2. Run: docker compose exec app php artisan schedule:run
    3. Check mailpit at https://todo-app-2026-05.vm.example:8025
       for the reminder mail
    4. Share the list with another seeded user, repeat — should get 2 mails
```

You QA, approve, deploy:

```
[Phase F7 — Handoff + Deploy]
  → docs/larv/features/due-dates-with-reminders/handoff.md written
  → Laravel Cloud deploy ........ ✅ live in production
  → /larv:learn --full triggered ... 1 plugin note → PR #48

Total: 1h 12min, $7.40
```

---

## Example 3 — Bugfix on a managed app via `/larv:debug`

A user reports: "Sometimes when I share a list, the collaborator can't see todos created before the invite was sent."

### Your prompt

```
/larv:debug list-sharing-todos-missing

Bug: when a list is shared, todos created before the invite was sent
are sometimes not visible to the collaborator. It works for some lists
and not others. Repro is intermittent.
```

### What happens

```
[/larv:debug — list-sharing-todos-missing]

Reading existing docs/larv/ ........ ✅
Loading LEARNINGS digest ........... ✅

[Phase D0 — Triage]
  → Reading recent logs from VM ............... last 24h
  → Recent commits ............................ 3 in last week
  → Reproducing on sandbox .................... 

  Reproduced: only fails when invite is created BEFORE the list has
  any todos, then todos are added after.

[Phase D1 — Hypothesis]
  Invoking superpowers:systematic-debugging.
  
  Ranked causes:
    1. (likely) Eager-loading on List uses cached relationship
       at invite time; new todos not in cache
    2. (possible) ListPolicy::view denies based on stale
       collaborators relation
    3. (unlikely) Race in InviteAcceptedListener

  Most likely: #1. Will test by writing a failing Pest case.

[Phase D2 — Bisect / characterize]
  Failing test written:
    tests/Feature/SharedListVisibilityTest.php::it_shows_todos_added_after_invite

  Run on VM ........................... ❌ fails as expected (bug reproduced)

  Root cause confirmed:
    app/Models/List.php:42 — collaborators relation is loaded with
    ->load() at invite time, then the result is implicitly cached on
    the model instance and reused. New todos added later don't
    refresh until the model is re-fetched.

[Phase D3 — Fix]
  Approach: refactor InviteController to not pass the eagerly-loaded
            instance through; instead re-fetch in the listener.

  Change minimal: 1 file, 4 lines.
  
  Test: ✅ 1/1 (the new failing case now passes)
  Full Pest suite: ✅ 47/47 (no regressions)
  Playwright: ✅ 8/8

[Phase D4 — Handoff]

  Output: docs/larv/debug/2026-05-09-list-sharing-todos-missing/
            ├── hypothesis.md
            ├── bisect.md
            ├── fix.md
            └── handoff.md

  Plugin Improvement Notes:
    [plugin] failure mode — implicit relation caching after ->load()
             through a controller-passed instance is a recurring
             Laravel footgun. Add to LEARNINGS.

  Deploy to production? [Y/n]
```

You: `Y`. Agent deploys. `/larv:learn --full` runs. PR #49 opened with a new entry under "Failure modes prevented" in `LEARNINGS.md`.

Next time anyone runs `/larv:full`, that LEARNINGS entry is in the context — the discuss phase can ask better questions about relation caching, and the implementation phase will avoid the pattern.

---

## Anatomy of the artifacts

### Slice handoff template (Phase 8 / Feature impl)

```markdown
# Slice 02 — Todos CRUD

## Status: ✅ Ready for QA

## What was built
- New: app/Models/Todo.php, app/Models/List.php, TodoController, ListController
- Migrations: 2026_05_05_000001_create_lists_table.php, ..._create_todos_table.php
- Filament: app/Filament/Resources/{List,Todo}Resource.php
- Tests: 12 Pest, 4 Playwright (all green)

## How to QA
URL:        https://todo-app-2026-05.vm.example/lists
Login:      test@example.com / <generated-by-seeder>
Walkthrough:
  1. Click "New list" → name it "Groceries"
  2. Click into it → click "New todo" → text "Milk"
  3. Mark it done → verify it shows strikethrough
  4. Delete the list → confirm soft-delete (still in DB with deleted_at)

## Sandbox controls
SSH:    ssh deploy@vm.example.com
Logs:   docker compose -f /srv/todo-app-2026-05/docker-compose.yml logs -f app
Reset:  docker compose exec app php artisan migrate:fresh --seed

## Tests
Pest:        ✅ 12/12   coverage 87%
Playwright:  ✅ 4/4

## Plugin Improvement Notes
- (none)

## Next: slice-03-sharing
```

### Sandbox runbook template (Phase 7)

```markdown
# Sandbox Runbook — todo-app

## App URL
https://todo-app-2026-05.vm.example
Login: test@example.com / <generated-by-seeder>   (seeded)

## VM
Host:  vm.example.com   user: deploy
SSH:   ssh deploy@vm.example.com
Key:   ~/.ssh/larv_todo-app-2026-05_ed25519

## Docker stack
Compose:  ~/apps/todo-app-2026-05/docker-compose.yml
Services: app · nginx · mysql · redis · mailpit
Up:       docker compose up -d
Logs:     docker compose logs -f app
Reset:    docker compose exec app php artisan migrate:fresh --seed

## Firewall (already configured)
ufw allow from any to any port 80,443,8025

## Reverse proxy
nginx → app:8000   TLS: Let's Encrypt (auto-renew)
DNS: A record todo-app-2026-05.vm.example → VM

## How to QA
1. Open https://todo-app-2026-05.vm.example
2. Login with seeded creds
3. After each slice, read slice-NN/handoff.md for the walkthrough
4. File feedback in plain English in the chat — no code needed
```

---

## STATE.yaml + status / resume

`docs/larv/STATE.yaml` is the single source of truth for "where am I."

### `/larv:status`

```
$ /larv:status
Project: todo-app  (greenfield, started 2026-05-04)
Plugin:  larv 0.3.1  bundles: masterplan 4.2.0 · sp-laravel 0.1.5 · ddd 10.5

Phase 8 — Implementation loop  (in progress)
  ✅ Phases 0–7 done   ⏳ Slices 2/4 done · 1 in progress · 1 pending

Sandbox:  https://todo-app-2026-05.vm.example   (running · tests ✅ at 15:35)

Budget:   252min / 480min   $19.30 / $42.00   53% consumed
Learn:    --quick at 14:30 → PR #42 (open) · 3 pending notes

Next: continue slice 03 (sharing)
```

`--json` for tooling.

### `/larv:resume`

You closed your laptop yesterday mid-slice. Today, in the same project directory:

```
$ /larv:resume
Reading docs/larv/STATE.yaml ...
Last completed: slice 02 verification (2026-05-04 15:35)
Resuming: slice 03 (sharing) — was in_progress, 1 attempt prior

Spawning slice subagent ...
```

If a teammate started the project, you can run the same command on your machine — STATE.yaml is in git, the lock file is per-machine, and the VM is shared. You pick up exactly where they left off.

---

## Self-improvement loop

Every project run can teach the plugin. The mechanism:

1. **During the run**, every slice/phase handoff has a `## Plugin Improvement Notes` section. The agent fills it when something is worth saving (API drift, question gap, pattern win, failure mode). Notes are tagged `[plugin]` (general lesson) or `[project]` (specific to this app).

2. **At end of project** (and every 5 slices for `--quick`), `/larv:learn` aggregates `[plugin]`-tagged notes, clusters by theme, drafts edits to the plugin's own skill files, and opens a PR on the plugin repo via `gh`.

3. **A maintainer reviews and merges** the PR. CI runs the plugin's fixture tests against every PR — anything that breaks an existing fixture is blocked.

4. **Next project run** loads the updated `LEARNINGS.md` digest into pre-flight context. Every project gets smarter.

The PR has citations: every edit links to the slice handoff that motivated it. No silent self-mutation.

You can also run it manually:

```
/larv:learn --since=2026-05-01     # aggregate everything since this date
/larv:learn --dry-run              # see proposed diffs without committing
```

---

## What user does vs what agent does

The contract:

| Phase | You | Agent |
|---|---|---|
| Pre-flight | confirm budget | check env, load LEARNINGS, estimate cost |
| Discuss | answer Qs | ask Qs (multiple choice mostly), validate via MCPs |
| Domain → Premortem | review docs, approve gates | produce docs |
| Slice plan | approve slice list | break into 1-day slices |
| Provision | confirm VM + domain | SSH, docker, firewall, TLS |
| Implementation | **QA in browser, give feedback in English** | code, deploy, test, iterate, notify |
| Verification | sign off | full suite + smoke + perf |
| Deploy | confirm cutover | Laravel Cloud deploy |
| Learn | review plugin PR (optional) | propose plugin edits |

You never open an editor. You answer, review, click, and respond.

---

## FAQ / common gotchas

**"My budget cap fired at 120% — what now?"**
You'll see a pause with three options: bump the cap, tighten scope, or halt. Tightening scope means dropping low-priority slices (the agent suggests which).

**"Two of us are running the same project."**
First one in wins via `docs/larv/.lock`. The other gets a clear message with the lock holder's name + machine. Stale locks (>30 min) auto-clear. `--force-unlock` for emergencies.

**"My existing app has Laravel 8 — can I `/larv:adopt`?"**
The Phase A0 health check will flag this and recommend remediation (upgrade to ≥9) before adoption can produce reliable docs. You can override but the docs will be marked low-confidence.

**"Can I edit `docs/larv/02-architecture/c4-container.md` by hand?"**
Yes, but only inside the `<!-- HUMAN NOTES -->` section at the bottom. Sections above are agent-owned and may be regenerated. The plugin preserves human notes verbatim across regenerations.

**"Slice 03 has failed 3 times. What happens?"**
You'll see a halt with 4 options: retry once more, rollback to the last green slice, mark this slice blocked and skip to the next non-dependent one, or abandon the project. Default is halt-and-ask; you can change the default via `STATE.yaml.policies.slice_failure`.

**"I want to skip the premortem on a tiny project."**
Not currently supported in v1. The premortem is a quality gate, not a feature gate. A `--cheap` mode that compresses some phases is in the roadmap (sub-project E).

**"Where do learnings I want to keep private to my project go?"**
Tag them `[project]`. They land in `docs/larv/08-learnings/project-lessons.md` in your repo. Only `[plugin]`-tagged notes are aggregated by `/larv:learn`.

**"My team wants stricter budget controls."**
Set `STATE.yaml.budget.cap_policy: pause_at_100pct` per project, or change the plugin default in `LEARNINGS.md` for the team.

**"Can I see what `/larv:learn` would propose without it actually opening a PR?"**
Yes: `/larv:learn --dry-run`. Prints diffs to stdout, no branch, no PR.

**"What if the LEARNINGS file gets too big?"**
At ~500 lines, `/larv:learn` will propose a structural split (per-section files). Auto-managed.

---

## Glossary

- **Bundled marketplace** — A Claude Code plugin that vendors pinned versions of upstream plugins/skills inside its own `bundle/` directory, exposed as a single install.
- **Phase subagent** — A fresh-context Claude subagent spawned by the orchestrator to handle one phase of `/larv:full`, returning structured output that the orchestrator merges into `STATE.yaml`.
- **Slice** — A vertical implementation increment (~1 day of work) produced by Phase 6's Elephant Carpaccio plan.
- **Greenfield mode / adopted mode** — `STATE.yaml` flag distinguishing projects built by `/larv:full` (greenfield) from existing apps brought under management by `/larv:adopt` (adopted). Determines which commands are allowed.
- **Plugin Improvement Notes** — A section in every handoff doc capturing tagged learnings (`[plugin]` or `[project]`) for later aggregation by `/larv:learn`.
- **Composition stops at the phase** — A phase subagent invokes upstream skills in its own single context; we don't fan out a third level of subagents per skill invocation.
- **Confidence flag** — Marker on adoption-produced docs indicating how reliable each section is (`high`/`medium — inferred`/`low — placeholder`).

---

## Where to go next

- See `2026-05-04-larv-plugin-shell-design.md` for the formal spec (what's being built and why).
- After sub-project A is implemented, sub-project B (per-phase prompts and document model) gets its own design + plan cycle.
- File improvement requests as PRs to `<larv-workflow>/larv` — the plugin improves itself, but humans still drive intent.
