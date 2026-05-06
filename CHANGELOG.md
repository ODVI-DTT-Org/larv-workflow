# Changelog

All notable changes to the `larv` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
