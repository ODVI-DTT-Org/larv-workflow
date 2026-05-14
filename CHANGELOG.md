# Changelog

All notable changes to the `larv` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.4.27 (next) - Harden sandbox port ownership

- Adds project-owned runtime metadata for app, docs, and mockup sessions so `/larv:sandbox-stop` only stops sessions created for the current project.
- Makes `/larv:sandbox-start` detect foreign-owned or occupied recorded ports, allocate a fresh port, rewrite the public URL artifact, and verify the new URL before reporting it.
- Fixes a shared allocator flock leak that could deadlock a single process when allocating multiple sandbox ports in sequence.
- Updates generated app sandbox scripts to use slug-scoped app sessions (`larv-app-<slug>-<port>`) and pass `LARV_PROJECT_SLUG`/`LARV_APP_SESSION` through handoff bootstrap.

## 0.4.26 (next) - Project-scoped sandbox lifecycle commands

- Adds `/larv:sandbox`, `/larv:sandbox-start`, `/larv:sandbox-stop`, and `/larv:sandbox-reset` for recovering current project URLs, credentials, testing guides, and sandbox lifecycle state.
- Probes generated public app/docs/mockup URLs before reporting them as ready, and fails with a restart instruction when any generated URL is down.
- Scopes stop/start behavior by project slug and recorded runtime ports so parallel larv projects do not overwrite each other's sandbox, docs, or mockup sessions.

## 0.4.25 (next) - Full browser flow and mockup parity verification

- Requires handoff implementation to browser-check every touched page, role path, state, and flow against the approved `/larv:full` plan before marking a slice complete.
- Adds hard visual parity verification against approved mockups, including screenshots, route-by-route comparison, and no unapproved design drift.
- Extends final verification so Phase 9 fails if planned pages/flows are untested, seeded credential paths are unchecked, or implemented UI contradicts approved mockups and user decisions.

## 0.4.24 (next) - Seeded login credentials instead of demo switcher

- Removes the sandbox demo-mode and navbar user-switcher requirements from generated handoff, seed guides, env guides, and feature planning.
- Requires seeded test credentials for every role/persona, permissions scope, tenant/department, and full-flow browser QA path.
- Keeps seed data mandatory while making normal login the review path for sandbox testing.

## 0.4.23 (next) - PostgreSQL-only sandbox bootstrap

- Makes generated sandbox bootstrap PostgreSQL-only with `DB_CONNECTION=pgsql`, port `5432`, and a default `larv` database password.
- Removes MySQL/MariaDB bootstrap branches so agents cannot silently choose the wrong database engine.
- Updates environment, production, README, allocation checks, and regression tests to treat PostgreSQL as the required larv database.

## 0.4.22 (next) - AI-owned Laravel runtime refresh

- Requires `/larv:full`, `/larv:feature`, `/larv:debug`, and handoff implementation to run necessary Laravel commands instead of asking the user to do them manually.
- Adds a per-slice runtime section covering migrations, seeders, cache clears, asset builds, queue/runtime restarts, sandbox refresh, and public URL probes.
- Requires implementation reports and user testing guides to record runtime commands and sandbox probe status before pausing for browser QA.

## 0.4.21 (next) - Handoff design artifact links

- Makes `larv-handoff` explicitly depend on the Huashu-derived `visual-implementation-contract.md` and approved mockups directory.
- Adds direct visual contract, UI design, and approved mockup links to the generated `docs/Handsoff.md` index.

## 0.4.20 (next) - Demo mode seeders and user switcher

- Adds `DEMO_MODE=true` as a sandbox default and `DEMO_MODE=false` as the production default.
- Requires user-facing slices to create multiple focused seeders so first app review shows populated records across roles/personas and feature states.
- Requires demo-mode no-login access plus a navbar User Switcher for seeded users, with normal email/username + password login restored when `DEMO_MODE=false`.

## 0.4.19 (next) - Strict mockup parity expectation

- Tightens UI implementation from design inspiration to route-by-route mockup parity.
- Requires UI slices to map routes to exact chosen mockup files, save desktop/mobile screenshots under `docs/larv/08-implementation/screenshots/<slice-id>/`, and fix or document every non-trivial visual difference.
- Clarifies that selected mockups are the visual source of truth and production screens should look like them unless a difference is explicitly approved.

## 0.4.18 (next) - Design-to-implementation visual parity gates

- Makes Huashu design output a mandatory `docs/larv/03-design/visual-implementation-contract.md` that bridges approved mockups to production UI.
- Requires UI implementation slices to read the approved design contract and mockups, capture desktop/mobile screenshots, and document visual parity before completion.
- Updates `/larv:feature`, handoff, implementation, planning, docs index, and AI starting-point guidance so UI work cannot silently fall back to plain starter screens.

## 0.4.17 (next) - Organized implementation reports and docs index

- Moves per-slice implementation reports from the project root to `docs/larv/08-implementation/reports/`.
- Adds generated root `DOCS.md` as the documentation index for users and fresh AI sessions.
- Updates handoff, implementation, feature, learn, doc-site, and AI starting-point guidance to reference the organized report and docs-index paths.

## 0.4.16 (next) - User manual testing guides and seed data gates

- Adds `docs/user-manual/` generation for user-facing install, environment, production, package, seed/reset, and per-slice testing guides.
- Makes each slice hard-require `docs/user-manual/testing/<slice>.md` with end-to-end browser QA instructions before completion, including sandbox URL, navigation, testable features, and terminal verification.
- Makes seeders a hard slice obligation: at least 10 realistic records per feature, seeded personas/roles, reset commands, demo credentials, and demo-data removal notes in `docs/user-manual/seed-data.md`.
- Updates doc-site staging to include `docs/user-manual/` so guides are browsable alongside handoff docs.

## 0.4.15 (next) - Feature workflow and execution cadence

- Makes `/larv:feature` a full mini-flow: Laravel Superpowers brainstorming, saved feature design, Laravel Superpowers writing plan, saved feature plan, deltas, handoff, tracker, STATE, learnings, doc-site, and implementation routing.
- Adds execution review cadence to routing and STATE: `auto-all`, `manual-slice`, `manual-adr`, and `manual-phase`.
- Updates handoff and slice docs so manual modes show sandbox URL, terminal verification, and browser QA before continuing; auto mode proceeds until full verification or a blocker.
- Hardens sandbox bootstrap with VM package auto-install checks for PHP/composer/tmux/curl/rsync/system tools and Docker/Compose when the deploy script needs Docker.

## 0.4.14 (next) - Greenfield handoff scaffold bootstrap

- Fixes greenfield handoff bootstrap ordering by creating a bare Laravel scaffold when `artisan` is missing before starting the sandbox.
- Clarifies handoff, AI starting-point, Cursor, routing menu, implementation, provision, and plan guidance so bootstrap-before-slice is not contradicted by a docs-only repo.
- Updates the deploy-script fallback error to point back to `docs/Handsoff/bootstrap-sandbox.md` instead of implying a copy failure.

## 0.4.13 (next) - Doc-site and handoff render hardening

- Fixes Docsify review sites that could stay stuck on `Loading...` by always generating a root `README.md`, `_sidebar.md`, explicit HTTPS CDN URLs, and a served markdown probe.
- Hardens AI starting-point generation so missing or empty templates fail instead of overwriting `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.codex/AGENTS.md`, or Cursor rules with comment-only files.
- Adds regression coverage for non-empty handoff starting-point bodies and no-overwrite behavior on render failure.

## 0.4.12 (next) - Parallel port reservation hardening

- Adds VM-local port reservations under a shared flock so parallel larv runs cannot choose the same app, mockup, or doc-site port before servers bind.
- Updates Phase 3 mockup and Phase 6.5 Docsify flows to allocate ports with the project slug, re-verify before start, and release reservations only after probe-confirmed bind.
- Hardens generated sandbox bootstrap with the same app-port reservation logic for handoff implementation runs.
- Makes static server startup fail if the tmux session exists but the requested port never actually binds.

## 0.4.11 (next) - PRD-assisted DDD interview guard

- Clarifies that a complete PRD reduces Phase 0a question count but never replaces the DDD interview.
- Adds PRD-assisted interview mode: summarize inferred business answers, then ask at least five targeted confirmation or gap questions before completing Phase 0a.
- Prevents `status: complete` for the domain interview until the user answers those targeted questions or explicitly accepts all inferred answers.

## 0.4.10 (next) - Full-flow interruption hardening

- Slugifies human project names before writing `STATE.yaml`, preventing spaces and punctuation from leaking into paths, database names, URLs, and generated handoff files.
- Safely quotes project names in `STATE.yaml`, including names with punctuation or quotes.
- Records the current plugin version in `STATE.yaml` and pre-flight reports instead of the legacy `0.1.0` placeholder.
- Keeps implementation slices rooted in the current project directory, so code edits, tracker updates, git commits, resume, and the sandbox process all operate on the same app tree.
- Runs sandbox bootstrap directly from the current project root instead of copying the app to `/srv/larv`.
- Serves mockups from the project docs and stages the Docsify review site under `/tmp`, avoiding `/srv` ownership and sudo failures during `/larv:full`.

## 0.4.9 (next) - Local VM runtime default

- Changes the sandbox runtime model to default to local execution on the VM instead of SSHing to `31.220.79.31`.
- Sets the default runtime user metadata to `claude-team` and keeps SSH-only behavior behind explicit `LARV_RUNTIME_MODE=remote`.
- Updates mockup, doc-site, verifier, probe, pre-flight, and handoff bootstrap flows to execute locally while still serving browser URLs at `http://31.220.79.31:<port>`.
- Updates generated handoff, starting-point, runbook, and README guidance to warn agents not to SSH for the normal larv flow.

## 0.4.8 (next) - Deployment automation and continuation

- Adds a production deployment mode chooser for `guide-only`, Laravel Cloud CLI automation, Laravel Cloud API automation, mixed automation, and Namecheap DNS automation.
- Documents required Laravel Cloud and Namecheap automation credentials while keeping secrets out of git-tracked handoff files.
- Adds fresh-session recovery instructions to generated handoff and AI starting-point files so Codex CLI, Claude Code, Cursor, Gemini, or another AI can continue from `STATE.yaml`, tracker, reports, and slice handoffs instead of chat history.
- Adds new-feature guidance for fresh sessions through `/larv:feature` when commands are available, with a file-based fallback for external AI tools.

## 0.4.7 (next) - Package env expansion

- Expands the handoff environment guide with package-specific production values for Cashier/Stripe, Cashier/Paddle, Reverb, Scout/Meilisearch, Scout/Typesense, S3 uploads, Socialite/OAuth, Horizon/Redis queues, and Octane.
- Adds template coverage so future changes keep the package env guide visible in generated handoff docs.

## 0.4.6 (next) - Guardrails and simulation hardening

- Adds Claude Code hooks for session reminders, secret-edit blocking, implementation-before-bootstrap blocking, and tracker/STATE/report reminders after app edits.
- Adds `scripts/simulate-full.sh` dry-run fixture generation for a loan approval system, covering package matrices and handoff docs.
- Adds package-specific slice snippets for Filament, Cashier, Horizon, tenancy, Scout, observability, Reverb, and uploads.
- Adds a happy-path guide template and README happy-path/hooks documentation for Claude Code planning, Codex CLI handoff, and Laravel Cloud deployment.
- Adds optional `DB_INSTALL_MODE=apt` handling in sandbox bootstrap for missing MySQL/MariaDB/PostgreSQL tooling, while keeping fail-fast as the default.
- Fills `larv-learn` with concrete aggregation of implementation reports, local learnings, dry-run mode, and `LEARNINGS.md` proposals.
- Adds Laravel Cloud guide-only vs automation-mode guidance.

## 0.4.5 (next) - Laravel package deepening

- Adds generated `docs/Handsoff/package-guide.md` so external handoff tools get a Laravel package implementation/test/env/deploy matrix.
- Fills `larv-architecture` with concrete package propagation from `library-decisions.md` into `package-integration-matrix.md` and ADRs.
- Fills `larv-tests` with package-specific test obligations for Filament/Nova, auth, Horizon, Reverb, Pulse/Telescope, Octane, Cashier, tenancy, Scout/search, uploads, and notifications.
- Strengthens `larv-plan` so every approved Laravel package must appear in at least one implementation slice or be explicitly deferred by ADR.
- Strengthens `larv-adopt` to detect installed Laravel packages from `composer.json`, config, routes, providers, app folders, migrations, and test tooling.

## 0.4.4 (next) - Runtime guides and production handoff

- Adds generated handoff guides for production deployment, environment variables, and user operations: `docs/Handsoff/production-deploy.md`, `docs/Handsoff/env-guide.md`, and `docs/Handsoff/operations-guide.md`.
- Hardens the sandbox bootstrap handoff to detect/start MySQL, MariaDB, or PostgreSQL, create the app database when missing, configure a database user, write `.env` database/app values, and record database details in `STATE.yaml`.
- Fills `larv-verify` with concrete Pint, Pest, Larastan, asset build, migration, Playwright-if-present, and sandbox smoke checks.
- Fills `larv-deploy` with Laravel Cloud and Namecheap defaults, user questions, env-var handling, DNS instructions, production smoke checks, and rollback reporting.
- Adds explicit bundled-skill references for domain-driven-design, masterplan, huashu-design, and superpowers-laravel in the phase prompts.

## 0.4.3 (next) - Handoff sandbox flow

- Moves app sandbox startup out of `/larv:full` planning and into the implementation handoff via generated `docs/Handsoff/bootstrap-sandbox.md`.
- Makes `larv-handoff` generate the bootstrap file before per-slice execution, and makes `larv-implement` require it before the first slice.
- Serves the Docsify plan site after handoff generation so the doc-site includes `docs/Handsoff.md`, `docs/Handsoff/bootstrap-sandbox.md`, and per-slice handoffs.
- Updates the Phase 8 routing menu and AI starting-point files to show the exact next-step paths for external handoff.
- Retires `larv-provision` from the active `/larv:full` sequence; it now documents legacy invariants only.

## 0.4.2 (next) - Server reliability hardening

- Adds `runtime_gate.sh` so mockup, doc-site, and sandbox URL artifacts can be validated as real external VM URLs instead of `TBD`/`null`/local placeholders.
- Hardens static server startup with VM dependency checks (`php`, `tmux`, `curl`, `rsync`), session verification, and non-silent firewall failures.
- Extends pre-flight with a VM runtime dependency check.
- Fills `larv-plan` enough to require an executable `docs/larv/07-runtime/deploy-sandbox.sh`, removing the Phase 7 placeholder deployment path.
- Updates Phase 3, Phase 6.5, and Phase 7 prompts to use `exit 1` in executable snippets and call the runtime gate before announcing completion.

## 0.4.1 (next) - Runtime URL gates

- Tightens Phase 3 mockups, Phase 6.5 doc-site, and Phase 7 sandbox so a phase cannot complete unless its server is started, inside/outside probes pass, the URL is written to a doc artifact, and the URL is returned in the subagent contract.
- Adds orchestrator-level runtime URL enforcement for `mockup_url`, `docsite_url`, and `sandbox_url`.

## 0.4.0 (next) - Layer 2

- **Phase 0a - DDD interview** (new skill `larv-domain-interview`): business-process-only interview before Discuss. 9 sections, about 15-20 questions, tech-leak guard, 8 output files in `docs/larv/ddd-interview/`.
- **Phase 0 enrichment**: `larv-discuss` filled with the full Laravel ecosystem checklist (Filament/Nova, Sanctum/Passport/Fortify, Horizon, Reverb, Pulse, Telescope, Octane, Cashier, multi-tenancy options, Scout, MCPs, Pest/Pint/Larastan/Rector). Each ask is paired with a recommendation citing the DDD interview.
- **Phase 1 - Laravel-DDD mapping** (`larv-domain` filled): WebFetches the linked medium article at runtime for current Laravel-DDD guidance; produces full DDD layout when viability passes, flat Eloquent model otherwise.
- **Phase 3 - design picker + mockup server** (`larv-design` filled): recommendation memo, user browses getdesign.md in their own browser, agent fetches picks, huashu renders this app's screens in each picked style, comparison harness served on a verifier-allocated port; user converges on one design or hybrid.
- **Phase 6.5 - doc-site review** (new skill `larv-docsite`): Docsify served on a docsite-range port (9500-9999), client-side rendering from CDN, no server-side build; allows browsing the entire plan before the Phase 7 hard gate.
- **New shared lib `static_server.sh`**: shared lifecycle for any static server on the VM (mockups, doc-site).
- **MVP follow-ups**: added bats coverage for `allocate_db`, `verify_allocation`, and `probe_url_inside`; fixed multi-line file inlining in `handsoff_collect_tokens`.

## 0.3.0 (2026-05-06) — MVP overhaul

- **Workflow control**: hybrid gates added; soft gate after every approved phase, hard gate before Phase 7 and Phase 8.
- **Routing menu** before Phase 8: `same-session` | `subagents` | `handoff`. Sets `STATE.yaml.execution.mode`.
- **Handsoff system**: mandatory generation of `docs/Handsoff.md` (index) and `docs/Handsoff/slice-NN-<name>.md` (per slice). Self-contained — no plugin script references inside handsoff content.
- **Verifier**: live-scan port/db/project-root allocation, auto-pick on conflict.
- **Probe-before-announce**: per-service retry policies (`static`, `laravel`, `nginx`); inside + outside curl confirms before any URL is announced.
- **Auto-commit**: per approved phase, `docs/` + `adr/` only, default-branch-aware.
- **Implementation tracker**: `implementation-tracker.yaml` (canonical) + rendered `.md` view. Append protocol inlined in every slice handsoff.
- **AI starting-point files**: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/larv.mdc`, `.codex/AGENTS.md` — generated before the Phase 8 hard gate.
- **/larv:feature** and **/larv:debug** preserve full discipline (gates, handsoff, tracker, starting-point regen).
- **VM constant** `LARV_VM_HOST=31.220.79.31` isolated to `scripts/lib/vm.sh`.

Layer 2 shipped in 0.4.0.

## [0.2.2] — 2026-05-04

### Added
- Codex-native `larv:*` skill namespace so `/larv:*` prompts are model-visible in Codex CLI.

## [0.2.1] — 2026-05-04

### Added
- Claude Code local marketplace manifest so `larv` can be installed from the repository path.

## [0.2.0] — 2026-05-04

### Added
- Codex CLI compatibility metadata via `.codex-plugin/plugin.json`.
- Local Codex marketplace entry via `.agents/plugins/marketplace.json`.
- `docs/CODEX.md` with local Codex install and verification notes.

## [0.1.0] — 2026-05-04

### Added
- Initial plugin scaffolding (sub-project A).
- 8 commands: `/larv:full`, `/larv:adopt`, `/larv:feature`, `/larv:debug`,
  `/larv:brainstorm`, `/larv:learn`, `/larv:status`, `/larv:resume`.
- 15 skills (stubs; per-phase prompts deferred to sub-project B).
- `STATE.yaml` schema v1 with read/write/init helpers.
- `/larv:status` and `/larv:resume` working against empty and populated states.
- Pre-flight (Phase −1) stub: VM ping, bundle check, MCP check, budget estimate.
- Bundle directory with pinned upstream sources.
- Document templates: slice handoff, sandbox runbook, pre-flight, project lessons, adoption report.
- LEARNINGS.md skeleton.
- Test fixtures: `greenfield-todo`, `existing-blog`.
- GitHub Actions CI + Renovate.
