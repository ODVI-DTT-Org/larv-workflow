# Changelog

All notable changes to the `larv` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

Layer 2 (DDD interview, design picker, mockup server, doc-site, Discuss enrichment) is a separate plan.

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
