# RFC: DOX-Inspired Project-Local Contracts for larv

Status: proposed research recommendation
Date: 2026-06-30

## Summary

This RFC evaluates `agent0ai/dox` as an operating pattern for larv-managed Laravel projects. It does not recommend vendoring or installing DOX. The useful idea is smaller and more durable: each project should expose concise, local, current instructions that a fresh agent can discover before editing and that must be reviewed after meaningful workflow or code changes.

Recommendation: pilot a thin DOX-inspired contract in larv's existing generated AI starting-point files first. Add selective nested `AGENTS.md` files only for durable boundaries where pilot data shows fresh agents miss context. Do not generate a full DOX tree unless the pilot proves thin contracts insufficient and the maintenance cost acceptable.

Primary success signals:

- Fresh or external agents reliably find the right project instructions before edits.
- Project-local instructions stay current after workflow, handoff, feature, debug, verification, or deployment changes.
- The contract improves reliability and freshness without turning `AGENTS.md` files into duplicated handoff documents.

## Sources

- `agent0ai/dox`: https://github.com/agent0ai/dox
- DOX README: https://raw.githubusercontent.com/agent0ai/dox/main/README.md
- DOX root contract: https://raw.githubusercontent.com/agent0ai/dox/main/AGENTS.md
- AGENTS.md format: https://agents.md/
- AGENTS.md efficiency study: https://arxiv.org/abs/2601.20404

Key source notes:

- DOX is "no installation, no dependencies, no package, no runtime"; it is a Markdown instruction model centered on root and child `AGENTS.md` files.
- DOX requires agents to read the applicable root-to-target instruction chain before edits, then perform a documentation freshness pass after meaningful changes.
- The AGENTS.md format positions `AGENTS.md` as a predictable README-like file for agents, supports nested files for subprojects, and says the nearest file governs local work when instructions conflict.
- The January/March 2026 arXiv study analyzed 10 repositories and 124 pull requests and found AGENTS.md associated with lower median runtime and output token use while preserving comparable completion behavior. This RFC treats those efficiency results as useful background, but larv's main criteria are reliability and freshness.

## Current larv Instruction Surfaces

larv already generates several project-local contracts:

- `docs/Handsoff.md`: universal implementation contract, project context, execution cadence, fresh-session recovery, production handoff, and cross-tool starter prompt.
- `DOCS.md`: root documentation index for users and AI sessions.
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`, `.cursor/rules/larv.mdc`: generated AI starting-point files that point agents to `DOCS.md`, `docs/Handsoff.md`, `STATE.yaml`, the tracker, slice handoffs, user manual, runtime guides, and tool-specific rules.
- `docs/Handsoff/slice-NN-<name>.md`: per-slice execution contracts with required inputs, files, migrations, tests, runtime commands, UI parity checks, tracker updates, implementation reports, seed-data docs, and Definition of Done.
- `docs/larv/features/<feature-slug>/`: feature-local design, YAGNI audit, domain/package/design deltas, premortem, plan, and future slice guidance.
- `docs/larv/08-implementation/reports/`: implementation reports that record slice evidence, security scans, screenshots, and deviations.
- `docs/user-manual/`: user-facing installation, environment, seed data, production deploy, and per-slice testing guides.
- `docs/larv/implementation-tracker.yaml` and `.md`: append-only activity log.
- `docs/larv/local-learnings.md`: local findings staged for later `/larv:learn` aggregation.

Observed gap: larv's contract is strong but centralized. A fresh agent can recover from `DOCS.md` and `docs/Handsoff.md`, but the existing generated `AGENTS.md` does not yet require an explicit root-to-target contract walk, does not name nearest-owner docs for common paths, and does not clearly say which local instruction file must be reviewed or updated after each class of meaningful change.

## DOX Comparison

| DOX pattern | Current larv equivalent | Gap or tension |
|---|---|---|
| Root `AGENTS.md` contains project-wide instructions and child index | Generated root `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`, `.cursor/rules/larv.mdc`; `DOCS.md`; `docs/Handsoff.md` | Root generated files point to the right docs, but do not act as a maintained child index or freshness contract. |
| Child `AGENTS.md` files define local instructions for durable areas | `docs/Handsoff/slice-*`, feature folders, implementation reports, user manual, tracker | larv has local docs, but most are not automatically discovered by generic AGENTS-aware agents unless root instructions route them there. |
| Read root-to-target instruction chain before edits | Fresh-session recovery in `docs/Handsoff.md`; AI starting-point templates | Current flow says "read these files" but not "walk nearest applicable contracts for the paths you will touch." |
| Nearest contract controls local work details | Slice handoff controls slice implementation; feature docs control feature deltas | This rule is implicit. It should be explicit to prevent generic root rules from overriding a slice or feature contract. |
| Update closest owning `AGENTS.md` after meaningful changes | Tracker, STATE, reports, user manual, seed data, local learnings | larv has rich update obligations, but does not have a compact "doc freshness pass" that maps change types to the owning local contract. |
| Keep docs concise and avoid duplication | larv templates are detailed and self-contained for external handoff | A full DOX tree risks duplicating `Handsoff.md` and slice contracts, increasing stale-doc risk. |

## Workflow Coverage

### Greenfield

Current flow: `/larv:full` creates planning docs, renders `docs/Handsoff.md`, runtime guides, slice handoffs, user manual, tracker, and AI starting-point files. `scripts/simulate-full.sh` can produce representative generated artifacts from `tests/fixtures/integration-greenfield`.

DOX-inspired improvement: generated root `AGENTS.md` should tell a fresh agent to read `DOCS.md`, `docs/Handsoff.md`, `docs/larv/STATE.yaml`, the tracker, and the nearest contract for the intended path before edits. For app code paths, it should route to `docs/Handsoff/slice-NN-*.md` until implementation is complete.

### Adopt

Current flow: `/larv:adopt` brings an existing Laravel app under larv management and writes adoption docs with confidence markers. The adoption report distinguishes verified facts from inferred or placeholder guidance.

DOX-inspired improvement: adoption should be able to add root guidance without application code changes. The root contract should warn that adopted docs may contain confidence markers and should route agents to adoption findings before editing inferred areas.

### Feature

Current flow: `/larv:feature` creates `docs/larv/features/<feature-slug>/` with design, Ponytail YAGNI audit, deltas, premortem, plan, tracker/state updates, handoff regeneration, docs index/user manual updates, and gated implementation.

DOX-inspired improvement: root guidance should route feature changes to the feature folder first, then to generated slice handoffs. A selective `docs/larv/features/<feature-slug>/AGENTS.md` is a possible pilot artifact only if agents repeatedly miss the feature-local YAGNI/design/plan chain.

### Debug

Current flow: `/larv:debug` creates root-cause analysis under `docs/larv/05-premortem/`, a regression-test fix slice, tracker entry, regenerated handoff and AI starting-point files, and a gated implementation path.

DOX-inspired improvement: root guidance should make root-cause and regression-test requirements local and discoverable before app code edits. A debug/fix agent should know that `docs/larv/05-premortem/debug-<issue-slug>-rca.md` plus the bug slice handoff is the nearest contract.

### Handoff

Current flow: `larv-handoff` renders `docs/Handsoff.md`, sandbox/deploy/env/ops/package guides, `DOCS.md`, slice handoffs, tracker, user manual directories, and AI starting-point files.

DOX-inspired improvement: handoff generation is the right place to add or refresh thin DOX-style language because it already owns the cross-tool starting files.

### Resume

Current flow: `/larv:resume` runs `scripts/resume.sh` and prioritizes unresolved errors, pending gates, budget caps, phase advancement, or slice continuation. `docs/Handsoff.md` and `templates/ai-starting-point.md.tmpl` also encode fresh-session recovery.

DOX-inspired improvement: resume should add "find nearest applicable contract for the next path you will touch" after state recovery. This matters when a fresh session resumes in feature, bug, verification, or deployment context rather than normal slice implementation.

### Implementation

Current flow: `larv-implement` reads slice handoffs, runs security scans, executes slice commands, applies runtime changes, checks browser/mockup parity, writes reports and testing guides, updates seed-data docs, tracker, local learnings, and state.

DOX-inspired improvement: implementation should perform a doc freshness pass before completion. The pass should ask whether changed app code, tests, views, migrations, routes, seeders, or workflow docs changed local contracts. Most changes should update existing larv docs, not create a new AGENTS file.

### Verification

Current flow: `larv-verify` runs Pint, Pest, Larastan, build, migration status, sandbox smoke, optional Playwright, source/plan parity, browser flow checks, mockup parity, single-layout checks, and writes `docs/larv/09-verification/final-report.md`.

DOX-inspired improvement: final verification should check that generated starting-point files still point to current docs and that any nested contracts introduced by the pilot are not stale or contradictory.

### Deploy

Current flow: `larv-deploy` uses `docs/Handsoff/production-deploy.md`, env and operations guides, verification report, and `STATE.yaml`, then writes production answers and a deploy report.

DOX-inspired improvement: production-specific instructions should remain in `docs/Handsoff/production-deploy.md` and `docs/larv/10-deploy/`, with root guidance routing deploy agents there. Avoid duplicating deploy steps in root `AGENTS.md`.

### Learn

Current flow: `/larv:learn` aggregates plugin improvement notes and local learnings.

DOX-inspired improvement: learning capture should include observed instruction-routing failures from pilots: missed docs, stale contracts, duplicate rules, or agents editing before reading the nearest contract.

## Candidate Integration Levels

### Level 1: Thin DOX-Inspired Contract in Existing Starting Files

Scope:

- Update generated `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`, and `.cursor/rules/larv.mdc`.
- Add a compact "Read Before Editing" section:
  - read `DOCS.md` and `docs/Handsoff.md`
  - identify target paths
  - read `STATE.yaml`, tracker, and nearest owning contract for those paths
  - let closest applicable larv contract control local details
- Add a compact "Doc Freshness Pass" section:
  - after meaningful changes, update existing owning docs such as slice handoff, feature docs, user manual, seed data, tracker, implementation report, deploy report, or local learnings
  - do not duplicate stable rules across tool-specific files
  - record when no doc update was needed
- Add a route table for common paths:
  - `app/`, `routes/`, `database/`, `resources/`, `tests/`: active slice handoff or feature/debug slice, then design/domain/test docs as relevant
  - `docs/larv/features/<slug>/`: feature design, YAGNI audit, plan, deltas
  - `docs/Handsoff/`: root handoff plus specific guide
  - `docs/user-manual/`: relevant testing, seed-data, install, environment, or deploy guide
  - `docs/larv/09-verification/`: final verification contract
  - `docs/larv/10-deploy/`: production deployment contract

Pros:

- Smallest change; uses files larv already generates.
- Low risk of context bloat.
- Compatible with every current larv workflow and tool-specific starting file.
- Easy to test with `scripts/simulate-full.sh`.

Cons:

- Still relies on the root file to route agents correctly.
- Does not give AGENTS-aware tools path-local automatic discovery beyond root.

### Level 2: Selective Nested `AGENTS.md` for Durable Boundaries

Scope:

- Add nested `AGENTS.md` only where a directory is a durable ownership boundary with distinct rules:
  - `docs/larv/AGENTS.md`: planning, state, tracker, features, learnings, verification, deploy docs.
  - `docs/Handsoff/AGENTS.md`: generated handoff guides and slice contracts.
  - `app/AGENTS.md`: Laravel app-code conventions, route/model/policy/service expectations, and pointer to active slice/feature contract.
  - `resources/AGENTS.md`: Blade/Inertia/Livewire/frontend visual parity rules and pointers to design contract/mockups.
  - `tests/AGENTS.md`: Pest/Larastan/browser/regression requirements and pointer to acceptance criteria.
- Keep each nested file concise and mostly referential. It should not copy entire slice or deploy instructions.
- Generate these only when the target directory exists and only if pilot evidence justifies the maintenance overhead.

Pros:

- Better path-local discovery for generic AGENTS-aware agents.
- Keeps high-risk local rules near the edited files.
- Can reduce repeated root-contract scanning for code, UI, and tests.

Cons:

- More generated docs can go stale.
- Requires parent/child index maintenance.
- Risk of conflicting contracts if nested files duplicate `docs/Handsoff.md` or slice handoffs.

### Level 3: Full DOX Tree

Scope:

- Generate a root and deep child `AGENTS.md` hierarchy across project docs, Laravel app code, resources, database, tests, runtime, feature docs, implementation reports, user manual, and deploy docs.

Pros:

- Maximum path-local instruction coverage.
- Most closely mirrors DOX.

Cons:

- Highest stale-doc and duplicate-rule risk.
- More token load for agents that read every parent/child contract.
- Harder to keep generated and human-edited docs coherent.
- May conflict with larv's existing self-contained handoff design.

Recommendation: do not pursue Level 3 unless Stage 1 and Stage 2 pilot data show repeated failures under Level 1 or Level 2 that cannot be fixed with concise routing.

## Risk Analysis

### Context Bloat

Risk: agents read root `AGENTS.md`, tool-specific files, `DOCS.md`, `docs/Handsoff.md`, slice handoff, feature docs, nested `AGENTS.md`, and user manual before small edits.

Mitigation: root and nested contracts must be indexes and routing rules, not copies of handoff content. Require "read nearest owning contract" rather than "read every doc in the repo."

### Stale Generated Docs

Risk: generated `AGENTS.md` files drift from templates, state, handoff, feature plans, or runtime/deploy docs.

Mitigation: make handoff generation own starting-point refresh. Add pilot checks that compare generated files to expected route tables and freshness obligations.

### Conflicting Contracts

Risk: root `AGENTS.md`, `.codex/AGENTS.md`, `.cursor/rules/larv.mdc`, `docs/Handsoff.md`, and nested files disagree.

Mitigation: define precedence explicitly: user request first, then nearest applicable project contract for local details, then parent/root contracts for global rules. No child may weaken mandatory larv safety gates, verification, security, or user-approved scope.

### Duplicate Rules Across Tools

Risk: the same rules are copied into five tool-specific files and become inconsistent.

Mitigation: generate all starting-point files from one template section and keep tool-specific files short. Prefer links to `DOCS.md` and `docs/Handsoff.md` over duplicated instructions.

### Agents Over-Updating Docs

Risk: every small edit triggers noisy `AGENTS.md`, tracker, user manual, or learning updates.

Mitigation: define meaningful changes narrowly: purpose, scope, ownership, workflow, operating rules, required inputs/outputs, constraints, artifacts, or durable user preferences. Small code edits that do not change contracts can record "no contract update needed" in the implementation report or final response rather than editing docs.

### Full DOX Tree Maintenance

Risk: a deep generated tree adds many files that future agents treat as authoritative even when handoff docs have changed.

Mitigation: pilot only thin contracts first. If nested files are added, add a verification check that validates parent child-indexes and disallows stale references to missing docs.

## Pilot Design

### Stage 1: Static and Dry-Run Analysis

Fixtures and commands:

- `tests/fixtures/integration-greenfield`
- `tests/fixtures/existing-blog`
- `scripts/simulate-full.sh`

Procedure:

1. Generate a greenfield handoff with `scripts/simulate-full.sh <tmp-dir> "Loan Ops Test"` and inspect generated `DOCS.md`, `docs/Handsoff.md`, root AI starting files, slice handoff, tracker, and user manual paths.
2. For `tests/fixtures/existing-blog`, simulate or inspect adoption outputs to verify adopted projects can gain root guidance without application code changes.
3. Build a static matrix of scenarios, target paths, required contract chain, and expected doc freshness owner.
4. Check whether generated contracts say when local docs must be updated after meaningful changes.
5. Check whether generated contracts explain closest-contract precedence.

Stage 1 scenarios:

| Scenario | Target path | Expected read chain | Freshness owner |
|---|---|---|---|
| Greenfield first implementation | `app/`, `routes/`, `database/`, `resources/`, `tests/` | `DOCS.md`, `docs/Handsoff.md`, `STATE.yaml`, tracker, active `docs/Handsoff/slice-NN-*.md`, design/domain/test docs as applicable | slice implementation report, tracker, STATE, user testing guide, seed-data guide |
| Adopt existing app | `app/` or `routes/` | `DOCS.md`, `docs/Handsoff.md`, adoption report, confidence-marked domain/architecture/test docs, active slice | adoption report if confidence changes; relevant larv docs if verified facts change |
| Feature addition | `docs/larv/features/<slug>/`, then app paths | feature design, YAGNI audit, plan, deltas, generated feature slice handoff | feature docs, tracker, STATE, handoff, user manual, local learnings |
| Debug/fix | source path and tests | debug RCA, active bug slice handoff, relevant invariant/acceptance docs | RCA, regression test docs, implementation report, tracker, STATE |
| Resume | next incomplete slice path | `DOCS.md`, `docs/Handsoff.md`, `STATE.yaml`, tracker, latest reports, sandbox URL, active slice | same owner as resumed workflow |
| Verification | `docs/larv/09-verification/` and source paths | verification skill/contract, product brief, domain/design/test docs, reports, source | final verification report; starting-point freshness check |
| Deploy | `docs/larv/10-deploy/` | production handoff, env guide, ops guide, verification report, STATE | production answers and deploy report |
| Learn | `docs/larv/local-learnings.md` | local learnings, tracker, command docs | plugin learning notes or local learnings |

Acceptance gates:

- For every scenario, a fresh agent can identify the correct first three files and the nearest owning contract from generated docs alone.
- For every target path, generated docs identify whether a contract update, tracker entry, report, user manual update, or no doc update is expected.
- No generated contract duplicates full slice implementation steps.

### Stage 2: Small Manual Agent Trials

Run fresh-session scenarios with one agent per scenario and no prior chat context:

1. Greenfield handoff: ask the agent where it would start before implementing the first slice.
2. Existing-app adoption/resume: ask the agent what it must read before editing an adopted Laravel route.
3. Feature addition: ask the agent to prepare for a feature and identify the YAGNI/design/plan chain before any code.
4. Debug/fix: ask the agent to identify root-cause and regression-test obligations before editing source.

Record:

- Did the agent read or name the correct contract chain before edits?
- Did the agent identify the nearest owning contract for the target path?
- Did the agent recognize when `AGENTS.md`, starting-point files, feature docs, handoff docs, tracker, implementation report, user manual, or seed-data docs needed updates?
- Did the agent over-read unrelated docs?
- Did the agent over-update docs after a trivial edit?
- Did any tool-specific file conflict with root `AGENTS.md` or `docs/Handsoff.md`?

Stage 2 pass threshold:

- At least 3 of 4 scenarios identify the correct read chain without prompting.
- All 4 scenarios identify a plausible freshness owner.
- No scenario incorrectly bypasses slice/debug/feature gates and starts direct code edits.
- No scenario requires a full DOX tree to find the right docs.

## Test Cases

### Greenfield

Expected behavior: a generated project handoff tells a fresh agent to start at `DOCS.md`, `docs/Handsoff.md`, `STATE.yaml`, tracker, and the active slice handoff. For app code, the active slice controls implementation details. For UI work, the visual implementation contract and mockups are required.

### Adopt

Expected behavior: an existing Laravel app can gain DOX-style guidance by adding generated root starting files and larv docs. No application code changes are required just to add guidance. Agents see confidence markers before trusting inferred docs.

### Feature

Expected behavior: feature planning creates feature-local guidance under `docs/larv/features/<feature-slug>/`, keeps Ponytail/YAGNI visible, regenerates handoff/start files, and prevents direct coding until design and plan gates are complete.

### Debug

Expected behavior: bugfix flow preserves root-cause analysis and regression-test guidance locally, then routes implementation through a bug slice with tracker/state/report updates.

### Resume

Expected behavior: a fresh session recovers from `STATE.yaml`, tracker, handoff, latest reports, sandbox URL, and nearest applicable agent contract. It does not rely on chat history.

### Doc Freshness

Expected behavior: meaningful workflow changes identify the local contract to update. Trivial edits that do not change durable behavior can leave contracts unchanged after an explicit freshness check.

## Proposed Smallest Viable Integration Path

1. Implement Level 1 only:
   - Update `templates/ai-starting-point.md.tmpl` and `templates/cursor-rule.mdc.tmpl` with a DOX-inspired "Read Before Editing", "Nearest Contract", and "Doc Freshness Pass" section.
   - Keep language short and referential.
   - Regenerate the same content into `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`, and `.cursor/rules/larv.mdc`.
2. Add tests that run `scripts/simulate-full.sh` against a temp project and assert generated starting files contain:
   - root-to-target read discipline
   - nearest-contract precedence
   - doc freshness pass
   - route table for app, resources, tests, feature docs, handoff docs, verification, and deploy
3. Add one dry-run fixture check for `tests/fixtures/existing-blog` adoption guidance if the adoption renderer exists in this repo version.
4. Run Stage 2 manual trials.
5. Decide whether Level 2 is needed only for paths where agents still miss context.

## Go/No-Go Recommendation

Go for a Level 1 pilot.

Do not go directly to selective nested `AGENTS.md` or a full DOX tree. larv already has detailed, self-contained handoff and workflow docs. The immediate reliability gap is routing and freshness discipline in generated starting-point files, not lack of documentation volume.

Smallest viable larv integration:

- Add a thin DOX-inspired contract to existing generated AI starting files.
- Treat `docs/Handsoff.md`, active slice handoffs, feature docs, debug RCA, verification report, deploy docs, tracker, user manual, and seed-data guide as the owning contracts.
- Require a doc freshness pass after meaningful changes.
- Pilot with existing fixtures and fresh-agent trials before adding nested `AGENTS.md`.

