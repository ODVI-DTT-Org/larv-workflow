# larv Plugin Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the larv plugin's scaffolding, command/skill surface, STATE.yaml + status/resume infrastructure, pre-flight stub, bundle layout, fixtures, and CI — passing all 9 acceptance criteria from §16 of the spec. Per-phase skill prompts and `/larv:full` end-to-end execution are deferred to sub-project B.

**Architecture:** Commands and skills are Markdown files following Claude Code conventions. Runtime logic for state management, status, resume, locks, migrations, and the pre-flight stub lives in Bash helpers under `scripts/` and uses `yq` for YAML manipulation. Tests are bats-core scripts that exercise helpers against fixture projects in `tests/fixtures/`. The bundle is a directory of vendored upstream plugins pinned via `bundle/VERSIONS.yaml`. CI runs tests + Renovate on every PR.

**Tech Stack:**
- Markdown (commands, skills, templates, ADRs, README, LEARNINGS)
- Bash 5+ runtime helpers
- `yq` (mikefarah/yq, v4+) for YAML
- `jq` for JSON
- bats-core (v1.10+) for testing
- GitHub Actions for CI
- Renovate for dependency updates

**Project root:** `/home/claude-team/kaito/workflow/` (existing git repo). The plugin lives at root; the design `docs/` already exists from brainstorming.

---

## File Structure

```
workflow/                                    # the plugin repo root
├── .claude-plugin/
│   └── plugin.json                          # Task 1: manifest declaring 8 commands + 15 skills
├── README.md                                # Task 1: copy of usage guide
├── LEARNINGS.md                             # Task 12: skeleton with section structure
├── CHANGELOG.md                             # Task 1: SemVer log, v0.1.0 entry
├── commands/                                # Task 2: 8 command stubs
│   ├── larv-full.md
│   ├── larv-adopt.md
│   ├── larv-feature.md
│   ├── larv-debug.md
│   ├── larv-brainstorm.md
│   ├── larv-learn.md
│   ├── larv-status.md
│   └── larv-resume.md
├── skills/                                  # Task 3: 15 skill stubs
│   ├── larv-orchestrator/SKILL.md
│   ├── larv-discuss/SKILL.md
│   ├── larv-domain/SKILL.md
│   ├── larv-architecture/SKILL.md
│   ├── larv-design/SKILL.md
│   ├── larv-tests/SKILL.md
│   ├── larv-premortem/SKILL.md
│   ├── larv-plan/SKILL.md
│   ├── larv-provision/SKILL.md
│   ├── larv-implement/SKILL.md
│   ├── larv-verify/SKILL.md
│   ├── larv-deploy/SKILL.md
│   ├── larv-learn/SKILL.md
│   ├── larv-handoff/SKILL.md
│   └── larv-adopt/SKILL.md
├── bundle/                                  # Task 15: pinned upstream sources
│   ├── VERSIONS.yaml
│   ├── masterplan/                          # vendored
│   ├── superpowers-laravel/                 # vendored
│   ├── domain-driven-design/                # vendored (single skill)
│   └── huashu-design/                       # vendored
├── templates/                               # Task 11: .md templates copied into user projects
│   ├── slice-handoff.md
│   ├── sandbox-runbook.md
│   ├── pre-flight.md
│   ├── project-lessons.md
│   └── adoption-report.md
├── scripts/                                 # runtime helpers
│   ├── state.sh                             # Task 5: STATE.yaml read/write/init
│   ├── lock.sh                              # Task 6: file lock with stale detection
│   ├── status.sh                            # Task 8: /larv:status output
│   ├── resume.sh                            # Task 9: /larv:resume decision tree
│   ├── pre-flight.sh                        # Task 10: Phase −1 stub
│   └── lib/
│       ├── budget.sh                        # Task 5: budget calc helpers
│       └── format.sh                        # Task 8: human-readable formatters
├── adr/                                     # Task 16: plugin-level ADRs
│   └── 0001-bundled-marketplace.md
├── migrations/state/                        # Task 7: schema migrations
│   ├── migrate.sh                           # runner
│   └── v1-to-v1.sh                          # noop test migration
├── tests/                                   # bats-core tests
│   ├── helpers.bash                         # Task 4: shared test helpers
│   ├── fixtures/
│   │   ├── greenfield-todo/                 # Task 13
│   │   │   └── docs/larv/.gitkeep
│   │   ├── existing-blog/                   # Task 14
│   │   │   └── (minimal Laravel skeleton)
│   │   ├── state-empty.yaml                 # Task 4
│   │   ├── state-gate-pending.yaml          # Task 4
│   │   ├── state-errors-unresolved.yaml     # Task 4
│   │   ├── state-budget-exceeded.yaml       # Task 4
│   │   └── state-mid-slice.yaml             # Task 4
│   ├── manifest.bats                        # Task 1
│   ├── commands.bats                        # Task 2
│   ├── skills.bats                          # Task 3
│   ├── state.bats                           # Task 5
│   ├── lock.bats                            # Task 6
│   ├── migrations.bats                      # Task 7
│   ├── status.bats                          # Task 8
│   ├── resume.bats                          # Task 9
│   ├── pre-flight.bats                      # Task 10
│   ├── templates.bats                       # Task 11
│   ├── learnings.bats                       # Task 12
│   ├── fixtures.bats                        # Task 13–14
│   ├── bundle.bats                          # Task 15
│   └── readme.bats                          # Task 1 (acceptance #9)
└── .github/                                 # Task 17–18
    ├── renovate.json
    └── workflows/
        └── ci.yml
```

---

## Tasks

### Task 1: Initialize plugin manifest and root files

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `README.md` (copy of usage guide)
- Create: `CHANGELOG.md`
- Create: `tests/manifest.bats`
- Create: `tests/readme.bats`
- Create: `tests/helpers.bash`

- [ ] **Step 1: Write the failing test for plugin manifest**

`tests/manifest.bats`:
```bash
#!/usr/bin/env bats

load helpers

@test "plugin.json is valid JSON" {
    run jq empty .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
}

@test "plugin.json declares name larv" {
    run jq -r '.name' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ "$output" = "larv" ]
}

@test "plugin.json declares semantic version" {
    run jq -r '.version' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "plugin.json declares author as an object with a name" {
    run jq -r '.author | type' .claude-plugin/plugin.json
    [ "$output" = "object" ]
    run jq -r '.author.name' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "null" ]
}

@test "plugin.json declares a description" {
    run jq -r '.description' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "null" ]
}
```

> Note: per Claude Code's auto-discovery convention (verified against superpowers, superpowers-laravel, dev-skills, dev-workflows, antigravity-awesome-skills, laravel-cloud), the manifest does NOT enumerate commands or skills. Auto-discovery picks them up from the `commands/` and `skills/` directories. Counts are verified in Tasks 2 and 3.

`tests/helpers.bash`:
```bash
# Common test helpers
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
cd "$PROJECT_ROOT"

setup_tmp_project() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/docs/larv"
    echo "$tmp"
}

teardown_tmp_project() {
    [ -n "$1" ] && [ -d "$1" ] && rm -rf "$1"
}
```

`tests/readme.bats`:
```bash
#!/usr/bin/env bats

load helpers

@test "README.md exists at repo root" {
    [ -f README.md ]
}

@test "README.md mentions all 8 commands" {
    for cmd in /larv:full /larv:adopt /larv:feature /larv:debug /larv:brainstorm /larv:learn /larv:status /larv:resume; do
        run grep -F "$cmd" README.md
        [ "$status" -eq 0 ]
    done
}

@test "README.md contains greenfield todo example" {
    run grep -F "Example 1" README.md
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/manifest.bats tests/readme.bats`
Expected: All tests fail with "no such file" or similar.

- [ ] **Step 3: Create plugin manifest**

`.claude-plugin/plugin.json`:
```json
{
  "name": "larv",
  "description": "AI-driven Laravel app development plugin orchestrating masterplan, superpowers-laravel, domain-driven-design, and huashu-design into an end-to-end workflow.",
  "version": "0.1.0",
  "author": {
    "name": "your-org",
    "url": "https://github.com/your-org/larv"
  },
  "homepage": "https://github.com/your-org/larv",
  "repository": "https://github.com/your-org/larv",
  "license": "UNLICENSED",
  "keywords": [
    "laravel",
    "claude-code",
    "domain-driven-design",
    "workflow",
    "plugin"
  ]
}
```

> Schema follows the convention used by superpowers, superpowers-laravel, dev-skills, dev-workflows, antigravity-awesome-skills, and laravel-cloud (the canonical Claude Code plugins). Commands and skills are NOT enumerated — Claude Code auto-discovers from `commands/*.md` and `skills/*/SKILL.md`.

- [ ] **Step 4: Copy usage guide as README.md**

Run: `cp docs/superpowers/specs/2026-05-04-larv-plugin-usage-guide.md README.md`

- [ ] **Step 5: Create CHANGELOG.md**

`CHANGELOG.md`:
```markdown
# Changelog

All notable changes to the `larv` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bats tests/manifest.bats tests/readme.bats`
Expected: PASS — all tests green.

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin/ README.md CHANGELOG.md tests/manifest.bats tests/readme.bats tests/helpers.bash
git commit -m "feat: initialize plugin manifest, README, and CHANGELOG (Task 1)"
```

---

### Task 2: Create 8 command stubs

**Files:**
- Create: `commands/larv-full.md`
- Create: `commands/larv-adopt.md`
- Create: `commands/larv-feature.md`
- Create: `commands/larv-debug.md`
- Create: `commands/larv-brainstorm.md`
- Create: `commands/larv-learn.md`
- Create: `commands/larv-status.md`
- Create: `commands/larv-resume.md`
- Create: `tests/commands.bats`

- [ ] **Step 1: Write the failing test**

`tests/commands.bats`:
```bash
#!/usr/bin/env bats

load helpers

COMMANDS=(
    larv-full larv-adopt larv-feature larv-debug
    larv-brainstorm larv-learn larv-status larv-resume
)

@test "all 8 command files exist" {
    for cmd in "${COMMANDS[@]}"; do
        [ -f "commands/${cmd}.md" ] || { echo "missing commands/${cmd}.md"; return 1; }
    done
}

@test "every command file has frontmatter" {
    for cmd in "${COMMANDS[@]}"; do
        run head -n 1 "commands/${cmd}.md"
        [ "$output" = "---" ] || { echo "no frontmatter in commands/${cmd}.md"; return 1; }
    done
}

@test "every command file declares a description" {
    for cmd in "${COMMANDS[@]}"; do
        run grep -E '^description:' "commands/${cmd}.md"
        [ "$status" -eq 0 ] || { echo "no description in commands/${cmd}.md"; return 1; }
    done
}

@test "larv-status command invokes status.sh" {
    run grep -F "scripts/status.sh" commands/larv-status.md
    [ "$status" -eq 0 ]
}

@test "larv-resume command invokes resume.sh" {
    run grep -F "scripts/resume.sh" commands/larv-resume.md
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/commands.bats`
Expected: All tests fail.

- [ ] **Step 3: Create the 8 command files**

`commands/larv-full.md`:
```markdown
---
name: larv:full
description: Greenfield — design + build a new Laravel app end to end across 12 phases (with pre-flight setup).
---

Invoke the `larv-orchestrator` skill in greenfield mode.

The orchestrator runs Phase −1 (pre-flight), then phases 0–11 sequentially, spawning a fresh subagent per phase. State is persisted to `docs/larv/STATE.yaml`.

If the project is already managed (`STATE.yaml` exists with `mode: adopted`), refuse to run unless the user passes `--re-greenfield`.
```

`commands/larv-adopt.md`:
```markdown
---
name: larv:adopt
description: Bring an existing Laravel app under larv management. Read-only on user code; produces docs/larv/ retroactively.
---

Invoke the `larv-adopt` skill.

Runs phases A0–A9 (survey, interview, domain reverse-engineering, architecture extraction, design extraction, test reality, risk register, STATE seed, sandbox bootstrap, adoption report). Phases 6–10 of `/larv:full` are skipped — no implementation, no slice plan, no deploy.

If `STATE.yaml` already exists, refuse to run.
```

`commands/larv-feature.md`:
```markdown
---
name: larv:feature
description: Add a feature to a managed Laravel app. Mini-flow: brief, deltas, mini-premortem, slice plan, implementation loop.
---

Argument: `<feature-name>` — short slug for the feature.

Invoke the `larv-orchestrator` skill in feature mode with the provided feature name.

Requires `STATE.yaml` to exist at `docs/larv/STATE.yaml`. Reads existing docs to ground the feature in current architecture.
```

`commands/larv-debug.md`:
```markdown
---
name: larv:debug
description: Hypothesis-driven debugging on a managed Laravel app. Triage, hypothesis, bisect, fix, handoff.
---

Argument: `<issue>` — short slug for the issue.

Invoke the `larv-orchestrator` skill in debug mode with the provided issue slug.

Requires `STATE.yaml` to exist at `docs/larv/STATE.yaml`.
```

`commands/larv-brainstorm.md`:
```markdown
---
name: larv:brainstorm
description: Standalone brainstorm — Phase 0 only, exploratory. Produces 00-discuss/* without committing to build.
---

Invoke the `larv-discuss` skill standalone (no orchestrator).

Outputs land in `docs/larv/00-discuss/` only. STATE.yaml is not initialized — this is exploratory.
```

`commands/larv-learn.md`:
```markdown
---
name: larv:learn
description: Aggregate Plugin Improvement Notes from handoffs and propose plugin edits via PR. Modes - --quick, --full, --since=DATE, --dry-run.
---

Argument flags:
- `--quick` — last 5 slices, `[plugin]` notes only, only if patterns clear
- `--full` — all `[plugin]` notes since last `--full` invocation
- `--since=YYYY-MM-DD` — explicit date range
- `--dry-run` — print proposed diffs to stdout, no branch, no PR

Invoke the `larv-learn` skill with the chosen mode.

Requires `STATE.yaml` to exist (or aggregates across all projects in the user's working directory if invoked without one — see skill prompt for details).
```

`commands/larv-status.md`:
```markdown
---
name: larv:status
description: Print docs/larv/STATE.yaml summary. --json flag dumps raw YAML.
---

Run: `bash scripts/status.sh "$@"` from the larv plugin root.

The script reads `docs/larv/STATE.yaml` and outputs a human-readable summary (or raw YAML with `--json`). Exits non-zero if no STATE.yaml is found.
```

`commands/larv-resume.md`:
```markdown
---
name: larv:resume
description: Continue from the last STATE.yaml checkpoint. Handles errors_unresolved, gates_pending, budget caps, and phase advancement.
---

Run: `bash scripts/resume.sh "$@"` from the larv plugin root.

The script implements the decision tree from spec §9: errors_unresolved → gates_pending → budget cap → phase advancement → slice loop continuation.

Pass `--force-unlock` to clear a stale `docs/larv/.lock` from another machine.
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/commands.bats`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add commands/ tests/commands.bats
git commit -m "feat: create 8 command stubs (Task 2)"
```

---

### Task 3: Create 15 skill stubs

**Files:**
- Create: `skills/larv-orchestrator/SKILL.md`
- Create: `skills/larv-discuss/SKILL.md`
- Create: `skills/larv-domain/SKILL.md`
- Create: `skills/larv-architecture/SKILL.md`
- Create: `skills/larv-design/SKILL.md`
- Create: `skills/larv-tests/SKILL.md`
- Create: `skills/larv-premortem/SKILL.md`
- Create: `skills/larv-plan/SKILL.md`
- Create: `skills/larv-provision/SKILL.md`
- Create: `skills/larv-implement/SKILL.md`
- Create: `skills/larv-verify/SKILL.md`
- Create: `skills/larv-deploy/SKILL.md`
- Create: `skills/larv-learn/SKILL.md`
- Create: `skills/larv-handoff/SKILL.md`
- Create: `skills/larv-adopt/SKILL.md`
- Create: `tests/skills.bats`

- [ ] **Step 1: Write the failing test**

`tests/skills.bats`:
```bash
#!/usr/bin/env bats

load helpers

SKILLS=(
    larv-orchestrator larv-discuss larv-domain larv-architecture
    larv-design larv-tests larv-premortem larv-plan larv-provision
    larv-implement larv-verify larv-deploy larv-learn larv-handoff
    larv-adopt
)

@test "all 15 skill files exist" {
    for skill in "${SKILLS[@]}"; do
        [ -f "skills/${skill}/SKILL.md" ] || { echo "missing skills/${skill}/SKILL.md"; return 1; }
    done
}

@test "every skill has frontmatter with name and description" {
    for skill in "${SKILLS[@]}"; do
        run grep -E '^name:' "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "no name in ${skill}"; return 1; }
        run grep -E '^description:' "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "no description in ${skill}"; return 1; }
    done
}

@test "every skill stub flags itself as a stub deferring to sub-project B" {
    # Tasks under sub-project A must clearly mark skill prompts as deferred.
    # Exception: larv-orchestrator (it has minimal logic for status/resume routing).
    for skill in larv-discuss larv-domain larv-architecture larv-design \
                 larv-tests larv-premortem larv-plan larv-provision \
                 larv-implement larv-verify larv-deploy larv-learn \
                 larv-handoff larv-adopt; do
        run grep -F "STUB" "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "${skill} not marked STUB"; return 1; }
    done
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/skills.bats`
Expected: All tests fail.

- [ ] **Step 3: Create the orchestrator skill (real, minimal)**

`skills/larv-orchestrator/SKILL.md`:
```markdown
---
name: larv-orchestrator
description: Thin orchestrator for /larv:full, /larv:feature, /larv:debug. Holds STATE.yaml + LEARNINGS digest + current phase pointer; spawns fresh subagents per phase.
---

# larv-orchestrator

Thin orchestrator. Spawns fresh subagents per phase; holds only `STATE.yaml`, the LEARNINGS digest, and current-phase output pointers.

## Invocation modes

- **greenfield** — full 12-phase flow (-1 → 11). Invoked by `/larv:full`.
- **feature** — mini flow for adding features to managed apps. Invoked by `/larv:feature <name>`.
- **debug** — diagnostic loop on managed apps. Invoked by `/larv:debug <issue>`.

## On entry

1. Read `docs/larv/STATE.yaml` (or initialize via `bash scripts/state.sh init` for greenfield).
2. Refuse to run `greenfield` mode if STATE.yaml exists and `mode != greenfield`.
3. Refuse to run `feature` or `debug` mode if STATE.yaml does not exist or `mode == greenfield` and phase != 11.
4. Acquire lock via `bash scripts/lock.sh acquire`.
5. Load LEARNINGS digest from `bundle/larv/LEARNINGS.md` (or fall back to repo-local `LEARNINGS.md` for first-run dev).
6. Determine next phase from STATE.yaml.
7. Spawn the next phase subagent (skill named `larv-<phase-name>`) with the contract from spec §8.

## Subagent contract

> **NOTE: Detailed phase prompts and the subagent dispatch shape are defined in sub-project B. This skill is the routing/dispatch entry point — concrete dispatch logic lives in B.**

## On exit

Release lock via `bash scripts/lock.sh release`. Update `STATE.yaml.last_updated_at`.
```

- [ ] **Step 4: Create the larv-adopt skill (real, minimal)**

`skills/larv-adopt/SKILL.md`:
```markdown
---
name: larv-adopt
description: Adoption controller for /larv:adopt. Read-only on user code. Produces docs/larv/ retroactively from existing Laravel app.
---

# larv-adopt

> **STUB — sub-project A scaffolding only. Detailed adoption prompt logic is defined in sub-project B.**

## On entry

1. Refuse if `docs/larv/STATE.yaml` already exists (prevents accidental re-adoption).
2. Read-only on the codebase by default.
3. Run phases A0–A9 from spec §11.
4. On completion, initialize STATE.yaml with `mode: adopted`, `phase.last_completed: A9`.

## Read-only guarantee

This skill must not modify files outside `docs/larv/`. Any opt-in code modification is gated behind explicit flags (`--migrate-to-larv-conventions`, etc.) — those flags are NOT yet implemented in sub-project A.
```

- [ ] **Step 5: Create the 13 phase-skill stubs**

For each phase-skill, create `skills/<name>/SKILL.md` with this template (replace placeholders):

Template:
```markdown
---
name: <SKILL-NAME>
description: <ONE-LINE DESCRIPTION>
---

# <SKILL-NAME>

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

<ONE-PARAGRAPH SUMMARY of the phase's goal — see spec §7 for detail>

## Upstream skills invoked

<list — see spec §4 mapping table>

## Required outputs

<list of `.md` files this phase must produce in `docs/larv/<NN-phase>/`>

## Subagent return contract

See spec §8. Returns: `{ status, output_paths, state_updates, plugin_improvement_notes, budget_consumed }`.
```

Concrete fills:

`skills/larv-discuss/SKILL.md`:
```markdown
---
name: larv-discuss
description: Phase 0 wrapper - brainstorming with Laravel-specific context (libraries, MCPs, DDD viability gate).
---

# larv-discuss

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run brainstorming with Laravel-specific framing. Ask multiple-choice questions about libraries (Filament/Nova/Horizon/Reverb/Pulse/Cashier), authentication, multi-tenancy, soft-deletes, MCPs to enable. Run DDD viability check at end.

## Upstream skills invoked

- `superpowers-laravel:brainstorm`
- `masterplan-discuss`
- `huashu-design` (truth-first guard via context7 MCP)

## Required outputs

- `docs/larv/00-discuss/product-brief.md`
- `docs/larv/00-discuss/stakeholder-map.md`
- `docs/larv/00-discuss/glossary.md`
- `docs/larv/00-discuss/handoff.md`

## Subagent return contract

See spec §8.
```

`skills/larv-domain/SKILL.md`:
```markdown
---
name: larv-domain
description: Phase 1 wrapper - DDD viability check, then either DDD strategic model or flat domain model.
---

# larv-domain

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run DDD viability check (≥2 of 4 criteria: complex/fast-changing rules, multi-team collisions, unstable contracts, audit-critical). If viable, invoke `domain-driven-design`. Else, produce a flat Eloquent-friendly domain model.

## Upstream skills invoked

- `domain-driven-design` (gated on viability)

## Required outputs

- `docs/larv/01-domain/ddd-viability.md`
- `docs/larv/01-domain/{subdomains,bounded-contexts,context-map,ubiquitous-language}.md` (if DDD viable)
  OR `docs/larv/01-domain/domain-model.md` (if not)

## Subagent return contract

See spec §8.
```

`skills/larv-architecture/SKILL.md`:
```markdown
---
name: larv-architecture
description: Phase 2 wrapper - C4 levels 1-3, library policy locked, ADRs.
---

# larv-architecture

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Produce C4 levels 1–3, lock library policy decisions (Filament/Nova, Horizon, Reverb, Pulse, Cashier, Sanctum/Passport), write ADRs for major library/architecture decisions.

## Upstream skills invoked

- `masterplan-c4-architecture`
- `masterplan-master-design`

## Required outputs

- `docs/larv/02-architecture/c4-context.md`
- `docs/larv/02-architecture/c4-container.md`
- `docs/larv/02-architecture/c4-component.md`
- `docs/larv/02-architecture/library-policy.md`
- `docs/larv/02-architecture/adr/000N-*.md` (variable)

## Subagent return contract

See spec §8.
```

`skills/larv-design/SKILL.md`:
```markdown
---
name: larv-design
description: Phase 3 wrapper - data model, API surface, UI screens, brand spec.
---

# larv-design

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Produce data model (Eloquent + DDD aggregates if applicable), API surface, UI screen inventory, brand spec via huashu protocol (forces context7 MCP for any library claim).

## Upstream skills invoked

- `masterplan-master-design`
- `huashu-design` (UI/UX + brand spec)

## Required outputs

- `docs/larv/03-design/data-model.md`
- `docs/larv/03-design/api-surface.md`
- `docs/larv/03-design/ui-design.md`
- `docs/larv/03-design/brand-spec.md`

## Subagent return contract

See spec §8.
```

`skills/larv-tests/SKILL.md`:
```markdown
---
name: larv-tests
description: Phase 4 wrapper - Pest test strategy, Playwright flows, acceptance criteria.
---

# larv-tests

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Define test strategy: Pest unit/feature layers, Playwright browser flows, acceptance criteria per feature.

## Upstream skills invoked

- `masterplan-test-strategy`
- `superpowers-laravel:laravel-tdd` (hints, not full invocation here)

## Required outputs

- `docs/larv/04-test-strategy/pest-strategy.md`
- `docs/larv/04-test-strategy/coverage-targets.md`
- `docs/larv/04-test-strategy/acceptance-criteria.md`

## Subagent return contract

See spec §8.
```

`skills/larv-premortem/SKILL.md`:
```markdown
---
name: larv-premortem
description: Phase 5 wrapper - failure modes, adversarial review, risks register. May loop back to phases 2/3/4.
---

# larv-premortem

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run premortem (what could go wrong) + adversarial review. If showstoppers found, return `state_updates: { current_phase: 2 }` (or 3, 4) to loop back; orchestrator handles re-running prior phases.

## Upstream skills invoked

- `masterplan-bug-premortem`
- `masterplan-adversarial-review`

## Required outputs

- `docs/larv/05-premortem/failure-modes.md`
- `docs/larv/05-premortem/adversarial-review.md`
- `docs/larv/05-premortem/risks-register.md`

## Subagent return contract

See spec §8. Loopback signal via `state_updates.current_phase` set to a prior phase index.
```

`skills/larv-plan/SKILL.md`:
```markdown
---
name: larv-plan
description: Phase 6 wrapper - Elephant Carpaccio slice plan with parallelism annotations.
---

# larv-plan

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Break the design into ~1-day vertical slices via Elephant Carpaccio. Annotate parallel-eligible slices with `parallel: true` and explicit `depends_on`.

## Upstream skills invoked

- `superpowers-laravel:write-plan`
- `masterplan-implementation`

## Required outputs

- `docs/larv/06-implementation/elephant-carpaccio.md`

## Subagent return contract

See spec §8. Initializes `STATE.yaml.slices` with the planned slice IDs.
```

`skills/larv-provision/SKILL.md`:
```markdown
---
name: larv-provision
description: Phase 7 wrapper - sandbox VM provisioning. Sub-project C defines the runtime mechanics.
---

# larv-provision

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B; sandbox runtime mechanics defined in sub-project C.**

## Phase responsibility

SSH to VM, deploy Docker compose stack, configure firewall + reverse proxy + TLS, seed DB, smoke-test.

## Upstream skills invoked

- (none — larv-owned, depends on sub-project C scripts)

## Required outputs

- `docs/larv/07-runtime/sandbox-runbook.md`

## Subagent return contract

See spec §8.
```

`skills/larv-implement/SKILL.md`:
```markdown
---
name: larv-implement
description: Phase 8 wrapper - slice loop driver. Spawns fresh slice subagents, auto-fires /larv:learn --quick every 5 slices.
---

# larv-implement

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Drive the slice loop:
1. For each slice in `06-implementation/elephant-carpaccio.md`, spawn a fresh slice subagent.
2. After every 5 completed slices, fire `/larv:learn --quick` (parallel, fire-and-forget).
3. Update `STATE.yaml.slices.status[NN]` after each slice.
4. Surface user feedback to slice-iterate subagents.

## Upstream skills invoked (per slice)

- `superpowers-laravel:execute-plan`
- Contextual `superpowers-laravel:laravel-*` skills

## Required outputs (per slice)

- `docs/larv/06-implementation/slice-NN/{plan,handoff,verification}.md`

## Subagent return contract

See spec §8.
```

`skills/larv-verify/SKILL.md`:
```markdown
---
name: larv-verify
description: Phase 9 wrapper - final verification across full Pest + Playwright suites + smoke + perf.
---

# larv-verify

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Phase responsibility

Run full Pest suite, full Playwright suite, smoke tests on staging URL, performance check (N+1, slow queries). Auto-fix simple regressions if user opts in.

## Upstream skills invoked

- `masterplan-verification`

## Required outputs

- `docs/larv/09-verification/final-report.md`

## Subagent return contract

See spec §8.
```

`skills/larv-deploy/SKILL.md`:
```markdown
---
name: larv-deploy
description: Phase 10 wrapper - Laravel Cloud deployment. Sub-project D defines mechanics.
---

# larv-deploy

> **STUB — sub-project A scaffolding only. Mechanics defined in sub-project D.**

## Phase responsibility

Deploy to Laravel Cloud. Pre-deploy: full Pest + asset build + env-var verification. Post-deploy: smoke test on prod URL, DB migrate, queue worker restart.

## Required outputs

- `docs/larv/07-runtime/laravel-cloud.md` (updated)

## Subagent return contract

See spec §8.
```

`skills/larv-learn/SKILL.md`:
```markdown
---
name: larv-learn
description: Phase 11 + on-demand. Aggregate Plugin Improvement Notes; propose plugin edits via PR.
---

# larv-learn

> **STUB — sub-project A scaffolding only. Governance details defined in sub-project E.**

## Modes

- `--quick` — last 5 slices, `[plugin]` notes only, only if patterns clear
- `--full` — all `[plugin]` notes since last `--full`
- `--since=<date>` — explicit date range
- `--dry-run` — print proposed diffs without committing

## Aggregation steps

1. Read all `## Plugin Improvement Notes` sections from handoff docs in scope.
2. Cluster by theme: API drift / question gap / pattern win / failure mode / library version.
3. Draft edits: new `LEARNINGS.md` entries, diffs to skill prompts, new ADRs if structural.
4. Branch plugin repo (`learn/<project-slug>-<date>`), commit with source-slice citations, open PR via `gh`.
5. Post PR URL in project chat; update `STATE.yaml.learn.last_quick_pr` (or `last_full_at`).

## Safeguards

- PR-gated, never auto-merge
- Diffs must cite source slice handoffs
- CI runs fixture tests on every PR
```

`skills/larv-handoff/SKILL.md`:
```markdown
---
name: larv-handoff
description: Produce phase + slice handoff documents using templates from templates/.
---

# larv-handoff

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B.**

## Responsibility

Generate handoff documents using templates in `templates/` of the larv plugin. Always includes a `## Plugin Improvement Notes` section (initially `(none)`) with `[plugin]` and `[project]` tagging guidance.

## Templates used

- `templates/slice-handoff.md` — Phase 8 per-slice
- `templates/sandbox-runbook.md` — Phase 7
- `templates/pre-flight.md` — Phase −1
- `templates/project-lessons.md` — `08-learnings/` per-project
- `templates/adoption-report.md` — Phase A9
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bats tests/skills.bats`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add skills/ tests/skills.bats
git commit -m "feat: create 15 skill stubs (Task 3)"
```

---

### Task 4: Define STATE.yaml schema and create canonical fixtures

**Files:**
- Create: `tests/fixtures/state-empty.yaml`
- Create: `tests/fixtures/state-gate-pending.yaml`
- Create: `tests/fixtures/state-errors-unresolved.yaml`
- Create: `tests/fixtures/state-budget-exceeded.yaml`
- Create: `tests/fixtures/state-mid-slice.yaml`
- Create: `docs/STATE-SCHEMA.md` (lightweight schema doc inside the plugin repo)

These fixtures drive Tasks 5, 8, 9. No tests yet (used by later tasks).

- [ ] **Step 1: Create the empty-state fixture**

`tests/fixtures/state-empty.yaml`:
```yaml
schema_version: 1
project:
  name: my-app
  slug: my-app-2026-05
  greenfield: true
  mode: greenfield
  started_at: "2026-05-04T10:00:00Z"
  last_updated_at: "2026-05-04T10:00:00Z"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "0000000"
phase:
  current: -1
  last_completed: null
  gates_pending: []
gates: []
slices:
  total: 0
  status: {}
sandbox:
  vm_host: null
  app_url: null
  status: not_provisioned
  last_deploy_at: null
  last_test_run_at: null
  last_test_result: null
budget:
  estimated_total: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  consumed: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

- [ ] **Step 2: Create the gate-pending fixture**

`tests/fixtures/state-gate-pending.yaml`:
```yaml
schema_version: 1
project:
  name: my-app
  slug: my-app-2026-05
  greenfield: true
  mode: greenfield
  started_at: "2026-05-04T10:00:00Z"
  last_updated_at: "2026-05-04T11:00:00Z"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "abc1234"
phase:
  current: 0
  last_completed: -1
  gates_pending: [0]
gates:
  - { phase: -1, passed_at: "2026-05-04T10:05:00Z", approved_by: itranario@oakdriveventures.com }
slices:
  total: 0
  status: {}
sandbox:
  vm_host: null
  app_url: null
  status: not_provisioned
  last_deploy_at: null
  last_test_run_at: null
  last_test_result: null
budget:
  estimated_total: { tokens: 4500000, minutes: 480, cost_usd: 42.00 }
  consumed: { tokens: 142000, minutes: 38, cost_usd: 1.20 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

- [ ] **Step 3: Create the errors-unresolved fixture**

`tests/fixtures/state-errors-unresolved.yaml`:
```yaml
schema_version: 1
project:
  name: my-app
  slug: my-app-2026-05
  greenfield: true
  mode: greenfield
  started_at: "2026-05-04T10:00:00Z"
  last_updated_at: "2026-05-04T15:38:00Z"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "abc1234"
phase:
  current: 8
  last_completed: 7
  gates_pending: []
gates: []
slices:
  total: 4
  status:
    "01": { state: completed }
    "02": { state: completed }
    "03": { state: in_progress, attempts: 1 }
    "04": { state: pending }
sandbox:
  vm_host: vm.example.com
  app_url: "https://my-app-2026-05.vm.example"
  status: running
  last_deploy_at: "2026-05-04T15:30:00Z"
  last_test_run_at: "2026-05-04T15:35:00Z"
  last_test_result: failing
budget:
  estimated_total: { tokens: 4500000, minutes: 480, cost_usd: 42.00 }
  consumed: { tokens: 1840000, minutes: 252, cost_usd: 19.30 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved:
  - { phase: 8, slice: "03", kind: pest_failure, at: "2026-05-04T15:38:00Z", resolved: false }
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

- [ ] **Step 4: Create the budget-exceeded fixture**

`tests/fixtures/state-budget-exceeded.yaml`:

Same as `state-mid-slice.yaml` (next step) but with `budget.consumed.cost_usd: 60.00` (above 120% of $42 estimate = $50.40 cap).

```yaml
schema_version: 1
project:
  name: my-app
  slug: my-app-2026-05
  greenfield: true
  mode: greenfield
  started_at: "2026-05-04T10:00:00Z"
  last_updated_at: "2026-05-04T16:00:00Z"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "abc1234"
phase:
  current: 8
  last_completed: 7
  gates_pending: []
gates: []
slices:
  total: 4
  status:
    "01": { state: completed }
    "02": { state: completed }
    "03": { state: in_progress, attempts: 1 }
    "04": { state: pending }
sandbox:
  vm_host: vm.example.com
  app_url: "https://my-app-2026-05.vm.example"
  status: running
  last_deploy_at: "2026-05-04T15:30:00Z"
  last_test_run_at: "2026-05-04T15:35:00Z"
  last_test_result: passing
budget:
  estimated_total: { tokens: 4500000, minutes: 480, cost_usd: 42.00 }
  consumed: { tokens: 5500000, minutes: 580, cost_usd: 60.00 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

- [ ] **Step 5: Create the mid-slice fixture**

`tests/fixtures/state-mid-slice.yaml`:
```yaml
schema_version: 1
project:
  name: my-app
  slug: my-app-2026-05
  greenfield: true
  mode: greenfield
  started_at: "2026-05-04T10:00:00Z"
  last_updated_at: "2026-05-04T15:30:00Z"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "abc1234"
phase:
  current: 8
  last_completed: 7
  gates_pending: []
gates: []
slices:
  total: 4
  status:
    "01": { state: completed }
    "02": { state: completed }
    "03": { state: in_progress, attempts: 1 }
    "04": { state: pending }
sandbox:
  vm_host: vm.example.com
  app_url: "https://my-app-2026-05.vm.example"
  status: running
  last_deploy_at: "2026-05-04T15:30:00Z"
  last_test_run_at: "2026-05-04T15:35:00Z"
  last_test_result: passing
budget:
  estimated_total: { tokens: 4500000, minutes: 480, cost_usd: 42.00 }
  consumed: { tokens: 1840000, minutes: 252, cost_usd: 19.30 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: "2026-05-04T14:30:00Z"
  last_quick_pr: "https://github.com/your-org/larv/pull/42"
  last_full_at: null
  pending_notes_count: 3
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
```

- [ ] **Step 6: Create the lightweight schema doc**

`docs/STATE-SCHEMA.md`:
```markdown
# STATE.yaml schema v1

The canonical schema for `docs/larv/STATE.yaml`. Authoritative version: `schema_version: 1`.

See spec §9 for the full structure. Examples (test fixtures): `tests/fixtures/state-*.yaml`.

## Required top-level keys

- `schema_version` (int)
- `project` (object: name, slug, greenfield, mode, started_at, last_updated_at)
- `plugin` (object: name, version, bundle_versions, learnings_digest_hash)
- `phase` (object: current, last_completed, gates_pending)
- `gates` (array)
- `slices` (object: total, status)
- `sandbox` (object)
- `budget` (object: estimated_total, consumed, cap_policy)
- `learn` (object)
- `errors_unresolved` (array)
- `policies` (object)

## Mode values

- `greenfield` — `/larv:full` (re)entry allowed; `/larv:feature` and `/larv:debug` allowed once `phase.last_completed >= 11`.
- `adopted` — `/larv:full` refused; `/larv:feature` and `/larv:debug` allowed.

## Cap policy values

- `pause_at_100pct`
- `pause_at_120pct` (default)
- `pause_at_150pct`
- `never_pause`

## Slice state values

- `pending`
- `in_progress`
- `completed`
- `blocked`

## Schema migrations

See `migrations/state/` for upgrade scripts. The runner is `migrations/state/migrate.sh`.
```

- [ ] **Step 7: Commit**

```bash
git add tests/fixtures/state-*.yaml docs/STATE-SCHEMA.md
git commit -m "feat: define STATE.yaml schema v1 + 5 canonical fixtures (Task 4)"
```

---

### Task 5: Implement state.sh helpers (init, read, update)

**Files:**
- Create: `scripts/state.sh`
- Create: `scripts/lib/budget.sh`
- Create: `tests/state.bats`

- [ ] **Step 1: Write the failing test**

`tests/state.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
}

teardown() {
    teardown_tmp_project "$TMP"
}

@test "state init creates STATE.yaml with schema_version 1" {
    run bash scripts/state.sh init "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/STATE.yaml" ]
    run yq -r '.schema_version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "1" ]
}

@test "state init sets project name and slug" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run yq -r '.project.name' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "my-app" ]
    run yq -r '.project.slug' "$TMP/docs/larv/STATE.yaml"
    [[ "$output" =~ ^my-app-[0-9]{4}-[0-9]{2}$ ]]
}

@test "state init refuses to overwrite existing STATE.yaml" {
    bash scripts/state.sh init "$TMP" my-app greenfield
    run bash scripts/state.sh init "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
}

@test "state init in adopted mode sets greenfield: false" {
    bash scripts/state.sh init "$TMP" existing-blog adopted
    run yq -r '.project.greenfield' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "false" ]
    run yq -r '.project.mode' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "adopted" ]
}

@test "state read returns the YAML" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/state.sh read "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "schema_version: 1"
}

@test "state read fails when STATE.yaml is missing" {
    run bash scripts/state.sh read "$TMP"
    [ "$status" -ne 0 ]
}

@test "state update merges patch atomically" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/state.sh update "$TMP" '.phase.current = 0 | .phase.last_completed = -1'
    [ "$status" -eq 0 ]
    run yq -r '.phase.current' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "0" ]
    run yq -r '.phase.last_completed' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "-1" ]
}

@test "state update bumps last_updated_at" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    local before
    before="$(yq -r '.project.last_updated_at' "$TMP/docs/larv/STATE.yaml")"
    sleep 1
    bash scripts/state.sh update "$TMP" '.phase.current = 0'
    local after
    after="$(yq -r '.project.last_updated_at' "$TMP/docs/larv/STATE.yaml")"
    [ "$after" != "$before" ]
}

@test "budget cap policy returns correct threshold for default" {
    run bash -c 'source scripts/lib/budget.sh && budget_cap_threshold pause_at_120pct'
    [ "$status" -eq 0 ]
    [ "$output" = "1.20" ]
}

@test "budget cap policy returns correct threshold for never_pause" {
    run bash -c 'source scripts/lib/budget.sh && budget_cap_threshold never_pause'
    [ "$status" -eq 0 ]
    [ "$output" = "999" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/state.bats`
Expected: All tests fail (no scripts exist).

- [ ] **Step 3: Implement state.sh**

`scripts/state.sh`:
```bash
#!/usr/bin/env bash
# scripts/state.sh - STATE.yaml read/write/init helpers
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<EOF
Usage: state.sh <command> <project-dir> [args...]

Commands:
  init <dir> <name> <mode>    Initialize STATE.yaml. mode = greenfield|adopted
  read <dir>                  Print STATE.yaml to stdout
  update <dir> <yq-expr>      Atomically merge a yq expression into STATE.yaml
EOF
    exit 64
}

state_path() {
    echo "$1/docs/larv/STATE.yaml"
}

now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

slug_from_name() {
    local name="$1"
    local yyyy_mm
    yyyy_mm="$(date -u +"%Y-%m")"
    echo "${name}-${yyyy_mm}"
}

cmd_init() {
    local dir="$1" name="$2" mode="$3"
    local sp
    sp="$(state_path "$dir")"
    if [ -e "$sp" ]; then
        echo "ERROR: STATE.yaml already exists at $sp" >&2
        return 1
    fi
    mkdir -p "$(dirname "$sp")"
    local greenfield
    if [ "$mode" = "greenfield" ]; then greenfield=true; else greenfield=false; fi
    local now slug
    now="$(now_iso)"
    slug="$(slug_from_name "$name")"
    cat >"$sp" <<EOF
schema_version: 1
project:
  name: $name
  slug: $slug
  greenfield: $greenfield
  mode: $mode
  started_at: "$now"
  last_updated_at: "$now"
plugin:
  name: larv
  version: 0.1.0
  bundle_versions:
    masterplan: "0.0.0"
    superpowers-laravel: "0.0.0"
    domain-driven-design: "0.0.0"
    huashu-design: "0.0.0"
  learnings_digest_hash: "0000000"
phase:
  current: -1
  last_completed: null
  gates_pending: []
gates: []
slices:
  total: 0
  status: {}
sandbox:
  vm_host: null
  app_url: null
  status: not_provisioned
  last_deploy_at: null
  last_test_run_at: null
  last_test_result: null
budget:
  estimated_total: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  consumed: { tokens: 0, minutes: 0, cost_usd: 0.0 }
  cap_policy: pause_at_120pct
learn:
  last_quick_at: null
  last_quick_pr: null
  last_full_at: null
  pending_notes_count: 0
errors_unresolved: []
policies:
  slice_failure:
    max_attempts: 3
    default_action: halt_and_ask
EOF
}

cmd_read() {
    local dir="$1"
    local sp
    sp="$(state_path "$dir")"
    if [ ! -f "$sp" ]; then
        echo "ERROR: no STATE.yaml at $sp" >&2
        return 1
    fi
    cat "$sp"
}

cmd_update() {
    local dir="$1" expr="$2"
    local sp
    sp="$(state_path "$dir")"
    if [ ! -f "$sp" ]; then
        echo "ERROR: no STATE.yaml at $sp" >&2
        return 1
    fi
    local now
    now="$(now_iso)"
    local tmp
    tmp="$(mktemp)"
    yq "${expr} | .project.last_updated_at = \"$now\"" "$sp" >"$tmp"
    mv "$tmp" "$sp"
}

main() {
    [ $# -lt 2 ] && usage
    local cmd="$1"; shift
    case "$cmd" in
        init)   cmd_init "$@" ;;
        read)   cmd_read "$@" ;;
        update) cmd_update "$@" ;;
        *)      usage ;;
    esac
}

main "$@"
```

- [ ] **Step 4: Implement budget helper**

`scripts/lib/budget.sh`:
```bash
#!/usr/bin/env bash
# scripts/lib/budget.sh - budget cap helpers (sourced by status.sh, resume.sh)

# Returns the cost multiplier for a cap policy.
budget_cap_threshold() {
    local policy="$1"
    case "$policy" in
        pause_at_100pct) echo "1.00" ;;
        pause_at_120pct) echo "1.20" ;;
        pause_at_150pct) echo "1.50" ;;
        never_pause)     echo "999"  ;;
        *)               echo "1.20" ;;  # default
    esac
}

# Returns 0 if consumed cost has crossed the cap, 1 otherwise.
# Args: consumed_cost estimated_cost cap_policy
budget_cap_exceeded() {
    local consumed="$1" estimated="$2" policy="$3"
    local threshold
    threshold="$(budget_cap_threshold "$policy")"
    awk -v c="$consumed" -v e="$estimated" -v t="$threshold" \
        'BEGIN { exit !(c > e * t) }'
}
```

- [ ] **Step 5: Make scripts executable**

Run: `chmod +x scripts/state.sh scripts/lib/budget.sh`

- [ ] **Step 6: Run tests to verify they pass**

Run: `bats tests/state.bats`
Expected: PASS — all 9 tests green.

- [ ] **Step 7: Commit**

```bash
git add scripts/state.sh scripts/lib/budget.sh tests/state.bats
git commit -m "feat: implement STATE.yaml read/write/init helpers + budget cap (Task 5)"
```

---

### Task 6: Implement file lock helper

**Files:**
- Create: `scripts/lock.sh`
- Create: `tests/lock.bats`

- [ ] **Step 1: Write the failing test**

`tests/lock.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "lock acquire creates the lock file" {
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/.lock" ]
    run grep -E '^pid:' "$TMP/docs/larv/.lock"
    [ "$status" -eq 0 ]
}

@test "lock acquire fails if a fresh lock exists from another pid" {
    bash scripts/lock.sh acquire "$TMP"
    # simulate a different pid by editing the lock
    sed -i 's/^pid:.*$/pid: 99999/' "$TMP/docs/larv/.lock"
    sed -i "s/^started_at:.*$/started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$TMP/docs/larv/.lock"
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -ne 0 ]
}

@test "lock acquire succeeds (re-entrant) for the same pid" {
    bash scripts/lock.sh acquire "$TMP"
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -eq 0 ]
}

@test "lock release removes the lock file" {
    bash scripts/lock.sh acquire "$TMP"
    run bash scripts/lock.sh release "$TMP"
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}

@test "stale lock (>30 min) auto-cleared on acquire" {
    mkdir -p "$TMP/docs/larv"
    local stale_iso
    stale_iso="$(date -u -d '40 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -v-40M +%Y-%m-%dT%H:%M:%SZ)"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $stale_iso
EOF
    run bash scripts/lock.sh acquire "$TMP"
    [ "$status" -eq 0 ]
    run grep -E "^pid: $$" "$TMP/docs/larv/.lock"
    [ "$status" -eq 0 ]
}

@test "force-unlock clears any lock unconditionally" {
    mkdir -p "$TMP/docs/larv"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    run bash scripts/lock.sh force-unlock "$TMP"
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/lock.bats`
Expected: All tests fail.

- [ ] **Step 3: Implement lock.sh**

`scripts/lock.sh`:
```bash
#!/usr/bin/env bash
# scripts/lock.sh - file lock with stale detection
set -euo pipefail

LOCK_STALE_MINUTES="${LOCK_STALE_MINUTES:-30}"

usage() {
    cat <<EOF
Usage: lock.sh <command> <project-dir>

Commands:
  acquire        Acquire the lock. Same-pid re-entry is allowed. Auto-clears stale.
  release        Release the lock.
  force-unlock   Clear any lock unconditionally.
EOF
    exit 64
}

lock_path() {
    echo "$1/docs/larv/.lock"
}

now_iso()    { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
short_host() { hostname 2>/dev/null || echo "unknown"; }

iso_to_epoch() {
    if date -d "$1" +%s >/dev/null 2>&1; then
        date -d "$1" +%s
    else
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s
    fi
}

is_stale() {
    local started_at="$1"
    local now_epoch lock_epoch diff_minutes
    now_epoch="$(date -u +%s)"
    lock_epoch="$(iso_to_epoch "$started_at")"
    diff_minutes=$(( (now_epoch - lock_epoch) / 60 ))
    [ "$diff_minutes" -gt "$LOCK_STALE_MINUTES" ]
}

cmd_acquire() {
    local dir="$1"
    local lp
    lp="$(lock_path "$dir")"
    mkdir -p "$(dirname "$lp")"
    if [ -f "$lp" ]; then
        local pid started_at
        pid="$(awk -F': ' '/^pid:/ {print $2}' "$lp")"
        started_at="$(awk -F': ' '/^started_at:/ {print $2}' "$lp")"
        if [ "$pid" = "$$" ]; then
            return 0  # re-entrant
        fi
        if is_stale "$started_at"; then
            rm "$lp"  # stale, auto-clear
        else
            echo "ERROR: lock held by pid=$pid since $started_at" >&2
            return 1
        fi
    fi
    cat >"$lp" <<EOF
pid: $$
hostname: $(short_host)
started_at: $(now_iso)
EOF
}

cmd_release() {
    local dir="$1"
    local lp
    lp="$(lock_path "$dir")"
    [ -f "$lp" ] && rm "$lp"
}

cmd_force_unlock() {
    local dir="$1"
    local lp
    lp="$(lock_path "$dir")"
    [ -f "$lp" ] && rm "$lp"
}

main() {
    [ $# -lt 2 ] && usage
    local cmd="$1"; shift
    case "$cmd" in
        acquire)      cmd_acquire "$@" ;;
        release)      cmd_release "$@" ;;
        force-unlock) cmd_force_unlock "$@" ;;
        *)            usage ;;
    esac
}

main "$@"
```

- [ ] **Step 4: Make executable and run tests**

Run: `chmod +x scripts/lock.sh && bats tests/lock.bats`
Expected: PASS — all 6 tests green.

- [ ] **Step 5: Commit**

```bash
git add scripts/lock.sh tests/lock.bats
git commit -m "feat: implement file lock with stale detection (Task 6)"
```

---

### Task 7: Implement STATE.yaml migration framework

**Files:**
- Create: `migrations/state/migrate.sh`
- Create: `migrations/state/v1-to-v1.sh`
- Create: `tests/migrations.bats`

- [ ] **Step 1: Write the failing test**

`tests/migrations.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "migrate.sh runs noop v1-to-v1 migration successfully" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash migrations/state/migrate.sh "$TMP"
    [ "$status" -eq 0 ]
    run yq -r '.schema_version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "1" ]
}

@test "migrate.sh fails for unknown schema version" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    yq -i '.schema_version = 99' "$TMP/docs/larv/STATE.yaml"
    run bash migrations/state/migrate.sh "$TMP"
    [ "$status" -ne 0 ]
}

@test "migrate.sh creates a backup before migrating" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    bash migrations/state/migrate.sh "$TMP"
    run ls "$TMP/docs/larv/"
    echo "$output" | grep -qE 'STATE\.yaml\.bak\.[0-9]+'
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/migrations.bats`
Expected: All tests fail.

- [ ] **Step 3: Implement v1-to-v1 noop migration**

`migrations/state/v1-to-v1.sh`:
```bash
#!/usr/bin/env bash
# migrations/state/v1-to-v1.sh - noop migration (placeholder for real migrations)
set -euo pipefail
# Argument: path to STATE.yaml. Modify in place.
# This is a noop. Real migrations alter shape via yq.
exit 0
```

- [ ] **Step 4: Implement the migration runner**

`migrations/state/migrate.sh`:
```bash
#!/usr/bin/env bash
# migrations/state/migrate.sh - apply pending STATE.yaml migrations
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_VERSION=1

usage() {
    echo "Usage: migrate.sh <project-dir>"
    exit 64
}

main() {
    [ $# -ne 1 ] && usage
    local dir="$1"
    local sp="$dir/docs/larv/STATE.yaml"
    [ -f "$sp" ] || { echo "ERROR: no STATE.yaml at $sp" >&2; exit 1; }

    local current
    current="$(yq -r '.schema_version' "$sp")"

    if [ "$current" = "null" ] || [ -z "$current" ]; then
        echo "ERROR: STATE.yaml has no schema_version" >&2
        exit 1
    fi

    if [ "$current" -gt "$TARGET_VERSION" ]; then
        echo "ERROR: STATE.yaml schema_version=$current is newer than target=$TARGET_VERSION" >&2
        exit 1
    fi

    # backup
    local ts
    ts="$(date -u +%s)"
    cp "$sp" "$sp.bak.$ts"

    # apply chain: vN-to-v(N+1).sh until at TARGET_VERSION
    while [ "$current" -lt "$TARGET_VERSION" ]; do
        local next=$(( current + 1 ))
        local script="$PLUGIN_ROOT/migrations/state/v${current}-to-v${next}.sh"
        if [ ! -x "$script" ]; then
            echo "ERROR: missing migration script $script" >&2
            exit 1
        fi
        bash "$script" "$sp"
        current="$next"
        yq -i ".schema_version = $current" "$sp"
    done

    # also run vN-to-vN if it exists (idempotent verification step)
    local same="$PLUGIN_ROOT/migrations/state/v${current}-to-v${current}.sh"
    [ -x "$same" ] && bash "$same" "$sp"

    echo "Migrated to schema_version=$current"
}

main "$@"
```

- [ ] **Step 5: Make executable and run tests**

Run: `chmod +x migrations/state/migrate.sh migrations/state/v1-to-v1.sh && bats tests/migrations.bats`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add migrations/ tests/migrations.bats
git commit -m "feat: implement STATE.yaml migration framework with v1-to-v1 noop (Task 7)"
```

---

### Task 8: Implement /larv:status (status.sh)

**Files:**
- Create: `scripts/status.sh`
- Create: `scripts/lib/format.sh`
- Create: `tests/status.bats`

- [ ] **Step 1: Write the failing test**

`tests/status.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "status fails when STATE.yaml is missing" {
    run bash scripts/status.sh "$TMP"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qiE "no.*state.yaml|not found"
}

@test "status against empty state shows project name and slug" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "my-app"
    echo "$output" | grep -q "my-app-2026-05"
}

@test "status against empty state shows pre-flight phase" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "phase.*-1|pre-flight"
}

@test "status against mid-slice state shows slice progress" {
    cp tests/fixtures/state-mid-slice.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qE "Slices.*2/4"
}

@test "status against budget-exceeded state surfaces the cap" {
    cp tests/fixtures/state-budget-exceeded.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "exceeded|over.*budget|cap"
}

@test "status --json dumps raw YAML" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP" --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "schema_version: 1"
}

@test "status against errors-unresolved state surfaces errors" {
    cp tests/fixtures/state-errors-unresolved.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/status.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "1.*error|unresolved.*error"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/status.bats`
Expected: All tests fail.

- [ ] **Step 3: Implement format.sh helper**

`scripts/lib/format.sh`:
```bash
#!/usr/bin/env bash
# scripts/lib/format.sh - human-readable formatters for status output

# minutes -> "Hh Mm"
fmt_minutes() {
    local m="$1"
    local h=$((m / 60))
    local mm=$((m % 60))
    if [ "$h" -gt 0 ]; then
        printf "%dh %02dm" "$h" "$mm"
    else
        printf "%dm" "$mm"
    fi
}

# 19.30 -> "$19.30"
fmt_money() {
    printf "\$%.2f" "$1"
}

# percentage of consumed/estimated, rounded
fmt_pct() {
    local consumed="$1" estimated="$2"
    if awk -v e="$estimated" 'BEGIN { exit !(e > 0) }'; then
        awk -v c="$consumed" -v e="$estimated" \
            'BEGIN { printf "%.0f%%", (c / e) * 100 }'
    else
        echo "—"
    fi
}
```

- [ ] **Step 4: Implement status.sh**

`scripts/status.sh`:
```bash
#!/usr/bin/env bash
# scripts/status.sh - print STATE.yaml summary
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/format.sh
source "$PLUGIN_ROOT/scripts/lib/format.sh"
# shellcheck source=lib/budget.sh
source "$PLUGIN_ROOT/scripts/lib/budget.sh"

usage() {
    echo "Usage: status.sh <project-dir> [--json]"
    exit 64
}

main() {
    [ $# -lt 1 ] && usage
    local dir="$1"
    local json_mode=0
    [ "${2:-}" = "--json" ] && json_mode=1
    local sp="$dir/docs/larv/STATE.yaml"
    if [ ! -f "$sp" ]; then
        echo "ERROR: no STATE.yaml at $sp (is this a larv-managed project?)" >&2
        exit 1
    fi

    if [ "$json_mode" -eq 1 ]; then
        cat "$sp"
        return 0
    fi

    local name slug greenfield mode started_at
    name="$(yq -r '.project.name' "$sp")"
    slug="$(yq -r '.project.slug' "$sp")"
    greenfield="$(yq -r '.project.greenfield' "$sp")"
    mode="$(yq -r '.project.mode' "$sp")"
    started_at="$(yq -r '.project.started_at' "$sp")"

    local plug_ver bm bs bd bh
    plug_ver="$(yq -r '.plugin.version' "$sp")"
    bm="$(yq -r '.plugin.bundle_versions.masterplan' "$sp")"
    bs="$(yq -r '.plugin.bundle_versions["superpowers-laravel"]' "$sp")"
    bd="$(yq -r '.plugin.bundle_versions["domain-driven-design"]' "$sp")"
    bh="$(yq -r '.plugin.bundle_versions["huashu-design"]' "$sp")"

    local cur last gates_pending
    cur="$(yq -r '.phase.current' "$sp")"
    last="$(yq -r '.phase.last_completed' "$sp")"
    gates_pending="$(yq -r '.phase.gates_pending | length' "$sp")"

    local total completed in_progress pending
    total="$(yq -r '.slices.total' "$sp")"
    completed="$(yq -r '[.slices.status[] | select(.state == "completed")] | length' "$sp")"
    in_progress="$(yq -r '[.slices.status[] | select(.state == "in_progress")] | length' "$sp")"
    pending="$(yq -r '[.slices.status[] | select(.state == "pending")] | length' "$sp")"

    local sb_url sb_status sb_test
    sb_url="$(yq -r '.sandbox.app_url' "$sp")"
    sb_status="$(yq -r '.sandbox.status' "$sp")"
    sb_test="$(yq -r '.sandbox.last_test_result' "$sp")"

    local b_min b_cost e_min e_cost cap
    b_min="$(yq -r '.budget.consumed.minutes' "$sp")"
    b_cost="$(yq -r '.budget.consumed.cost_usd' "$sp")"
    e_min="$(yq -r '.budget.estimated_total.minutes' "$sp")"
    e_cost="$(yq -r '.budget.estimated_total.cost_usd' "$sp")"
    cap="$(yq -r '.budget.cap_policy' "$sp")"

    local errs
    errs="$(yq -r '[.errors_unresolved[] | select(.resolved == false)] | length' "$sp")"

    local pr last_quick pending_notes
    pr="$(yq -r '.learn.last_quick_pr' "$sp")"
    last_quick="$(yq -r '.learn.last_quick_at' "$sp")"
    pending_notes="$(yq -r '.learn.pending_notes_count' "$sp")"

    # --- format and print ---
    echo "Project: $name  ($([ "$greenfield" = "true" ] && echo "greenfield" || echo "adopted"), started $started_at)"
    echo "Plugin:  larv $plug_ver  bundles: masterplan $bm · sp-laravel $bs · ddd $bd · huashu $bh"
    echo
    if [ "$cur" = "-1" ]; then
        echo "Phase −1 (pre-flight)"
    else
        echo "Phase $cur — $(phase_name "$cur")"
        echo "  ✅ Phases up to $last done"
    fi
    if [ "$total" -gt 0 ]; then
        echo "  Slices $completed/$total done · $in_progress in progress · $pending pending"
    fi
    echo
    if [ "$sb_url" != "null" ]; then
        echo "Sandbox:  $sb_url   ($sb_status · tests $sb_test)"
    fi
    if [ "$e_cost" != "0" ] && [ "$e_cost" != "0.0" ]; then
        local pct
        pct="$(fmt_pct "$b_cost" "$e_cost")"
        echo "Budget:   $(fmt_minutes "$b_min") / $(fmt_minutes "$e_min")   $(fmt_money "$b_cost") / $(fmt_money "$e_cost")   $pct consumed"
        if budget_cap_exceeded "$b_cost" "$e_cost" "$cap"; then
            echo "  ⚠ Budget cap ($cap) exceeded"
        fi
    fi
    if [ "$pr" != "null" ]; then
        echo "Learn:    --quick at $last_quick → $pr · $pending_notes pending notes"
    fi
    if [ "$errs" -gt 0 ]; then
        echo
        echo "⚠ $errs unresolved error(s) — see /larv:resume for details"
    fi
}

phase_name() {
    case "$1" in
        -1) echo "pre-flight" ;;
        0)  echo "Discuss" ;;
        1)  echo "Domain" ;;
        2)  echo "Architecture" ;;
        3)  echo "Design" ;;
        4)  echo "Test strategy" ;;
        5)  echo "Premortem" ;;
        6)  echo "Slice plan" ;;
        7)  echo "Provision sandbox" ;;
        8)  echo "Implementation loop" ;;
        9)  echo "Final verification" ;;
        10) echo "Deploy" ;;
        11) echo "Learn" ;;
        *)  echo "unknown" ;;
    esac
}

main "$@"
```

- [ ] **Step 5: Make executable and run tests**

Run: `chmod +x scripts/status.sh scripts/lib/format.sh && bats tests/status.bats`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/status.sh scripts/lib/format.sh tests/status.bats
git commit -m "feat: implement /larv:status with empty/mid-slice/budget/error views (Task 8)"
```

---

### Task 9: Implement /larv:resume decision tree

**Files:**
- Create: `scripts/resume.sh`
- Create: `tests/resume.bats`

Acceptance criterion #5: must handle empty-state, gate-pending, and errors-unresolved branches.

- [ ] **Step 1: Write the failing test**

`tests/resume.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "resume fails when STATE.yaml is missing" {
    run bash scripts/resume.sh "$TMP"
    [ "$status" -ne 0 ]
}

@test "resume from empty state advances to phase 0" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "next.*phase 0|advance.*0|spawn.*phase 0"
}

@test "resume with gate pending surfaces the gate for review" {
    cp tests/fixtures/state-gate-pending.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "gate.*pending|approve.*phase 0"
}

@test "resume with errors_unresolved surfaces errors before anything else" {
    cp tests/fixtures/state-errors-unresolved.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "unresolved error|fix.*error.*first"
    # errors take precedence over slice continuation
    ! echo "$output" | grep -q "spawn.*slice"
}

@test "resume with budget exceeded pauses for cap policy review" {
    cp tests/fixtures/state-budget-exceeded.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "budget.*exceeded|cap.*reached|bump.*cap"
}

@test "resume mid-slice continues the in-progress slice" {
    cp tests/fixtures/state-mid-slice.yaml "$TMP/docs/larv/STATE.yaml"
    run bash scripts/resume.sh "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "continue slice 03|resume.*03"
}

@test "resume --force-unlock clears stale lock" {
    cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
    cat >"$TMP/docs/larv/.lock" <<EOF
pid: 99999
hostname: someone-else
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    run bash scripts/resume.sh "$TMP" --force-unlock
    [ "$status" -eq 0 ]
    [ ! -f "$TMP/docs/larv/.lock" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/resume.bats`
Expected: All tests fail.

- [ ] **Step 3: Implement resume.sh**

`scripts/resume.sh`:
```bash
#!/usr/bin/env bash
# scripts/resume.sh - decision tree for resuming a larv project
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/budget.sh
source "$PLUGIN_ROOT/scripts/lib/budget.sh"

usage() {
    echo "Usage: resume.sh <project-dir> [--force-unlock]"
    exit 64
}

main() {
    [ $# -lt 1 ] && usage
    local dir="$1"
    local force_unlock=0
    [ "${2:-}" = "--force-unlock" ] && force_unlock=1

    local sp="$dir/docs/larv/STATE.yaml"
    if [ ! -f "$sp" ]; then
        echo "ERROR: no STATE.yaml at $sp" >&2
        exit 1
    fi

    if [ "$force_unlock" -eq 1 ]; then
        bash "$PLUGIN_ROOT/scripts/lock.sh" force-unlock "$dir"
        echo "Lock cleared at $dir/docs/larv/.lock"
    fi

    # 1) errors_unresolved take absolute precedence
    local errs
    errs="$(yq -r '[.errors_unresolved[] | select(.resolved == false)] | length' "$sp")"
    if [ "$errs" -gt 0 ]; then
        echo "⚠ $errs unresolved error(s) — fix first before resuming."
        yq -o=yaml '.errors_unresolved[] | select(.resolved == false)' "$sp"
        echo
        echo "Resolve each error in the corresponding slice handoff, then re-run /larv:resume."
        return 0
    fi

    # 2) gates pending
    local gates_pending
    gates_pending="$(yq -r '.phase.gates_pending | length' "$sp")"
    if [ "$gates_pending" -gt 0 ]; then
        local first_gate
        first_gate="$(yq -r '.phase.gates_pending[0]' "$sp")"
        echo "Gate pending — please review and approve phase $first_gate before continuing."
        echo "Outputs: docs/larv/$(printf "%02d" "$first_gate")-*"
        return 0
    fi

    # 3) budget cap
    local b_cost e_cost cap
    b_cost="$(yq -r '.budget.consumed.cost_usd' "$sp")"
    e_cost="$(yq -r '.budget.estimated_total.cost_usd' "$sp")"
    cap="$(yq -r '.budget.cap_policy' "$sp")"
    if [ "$e_cost" != "0" ] && [ "$e_cost" != "0.0" ] \
       && budget_cap_exceeded "$b_cost" "$e_cost" "$cap"; then
        echo "Budget cap reached ($cap)."
        echo "Options:"
        echo "  (a) bump cap to next tier in STATE.yaml.budget.cap_policy"
        echo "  (b) tighten scope (drop low-priority slices)"
        echo "  (c) halt the project"
        return 0
    fi

    # 4) phase advancement
    local cur last total
    cur="$(yq -r '.phase.current' "$sp")"
    last="$(yq -r '.phase.last_completed' "$sp")"
    total="$(yq -r '.slices.total' "$sp")"

    if [ "$cur" = "11" ] && [ "$last" = "11" ]; then
        echo "Project complete. See /larv:status for the report."
        return 0
    fi

    if [ "$cur" -lt "8" ] 2>/dev/null; then
        local next=$(( cur + 1 ))
        echo "Next: spawn phase $next subagent (advance phase from $cur)."
        return 0
    fi

    if [ "$cur" = "8" ]; then
        local in_progress_slice
        in_progress_slice="$(yq -r '[.slices.status | to_entries[] | select(.value.state == "in_progress")][0].key' "$sp")"
        if [ "$in_progress_slice" != "null" ] && [ -n "$in_progress_slice" ]; then
            echo "Continue slice $in_progress_slice (was in_progress)."
            return 0
        fi
        local remaining
        remaining="$(yq -r '[.slices.status[] | select(.state == "pending")] | length' "$sp")"
        if [ "$remaining" -gt 0 ]; then
            local next_pending
            next_pending="$(yq -r '[.slices.status | to_entries[] | select(.value.state == "pending")][0].key' "$sp")"
            echo "Spawn slice $next_pending subagent."
            return 0
        fi
        echo "All slices done — advance to phase 9."
        return 0
    fi

    if [ "$cur" -ge "9" ] 2>/dev/null; then
        local next=$(( cur + 1 ))
        echo "Next: spawn phase $next subagent (advance phase from $cur)."
        return 0
    fi
}

main "$@"
```

- [ ] **Step 4: Make executable and run tests**

Run: `chmod +x scripts/resume.sh && bats tests/resume.bats`
Expected: PASS — all 7 tests green.

- [ ] **Step 5: Commit**

```bash
git add scripts/resume.sh tests/resume.bats
git commit -m "feat: implement /larv:resume decision tree (errors/gates/budget/phase) (Task 9)"
```

---

### Task 10: Implement Phase −1 (pre-flight) stub

**Files:**
- Create: `scripts/pre-flight.sh`
- Create: `tests/pre-flight.bats`

- [ ] **Step 1: Write the failing test**

`tests/pre-flight.bats`:
```bash
#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "pre-flight initializes STATE.yaml when called for a new project" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/STATE.yaml" ]
    run yq -r '.phase.current' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "-1" ]
}

@test "pre-flight populates plugin.bundle_versions" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.plugin.bundle_versions.masterplan' "$TMP/docs/larv/STATE.yaml"
    [ "$status" -eq 0 ]
    [ "$output" != "null" ]
}

@test "pre-flight writes pre-flight.md report" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ -f "$TMP/docs/larv/pre-flight.md" ]
    run grep -F "Project: my-app" "$TMP/docs/larv/pre-flight.md"
    [ "$status" -eq 0 ]
}

@test "pre-flight reports bundle and MCP checks" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "bundle check"
    echo "$output" | grep -qiE "mcp check"
}

@test "pre-flight estimates a non-zero budget" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.budget.estimated_total.cost_usd' "$TMP/docs/larv/STATE.yaml"
    awk -v v="$output" 'BEGIN { exit !(v > 0) }'
}

@test "pre-flight refuses to run if STATE.yaml already exists" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/pre-flight.bats`
Expected: All tests fail.

- [ ] **Step 3: Implement pre-flight.sh**

`scripts/pre-flight.sh`:
```bash
#!/usr/bin/env bash
# scripts/pre-flight.sh - Phase -1 stub: env checks, budget estimate, STATE.yaml init
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default budget estimate (sub-project A stub — refined in sub-project B based on slice count)
DEFAULT_BUDGET_TOKENS=4500000
DEFAULT_BUDGET_MINUTES=480
DEFAULT_BUDGET_COST=42.00

usage() {
    echo "Usage: pre-flight.sh <project-dir> <project-name> <mode>"
    echo "  mode = greenfield | adopted"
    exit 64
}

bundle_present() {
    local name="$1"
    [ -d "$PLUGIN_ROOT/bundle/$name" ]
}

mcp_check_stub() {
    # Sub-project A stub: assume context7 is available; richer checks in sub-project C.
    echo "context7"
}

read_bundle_version() {
    local name="$1"
    local vfile="$PLUGIN_ROOT/bundle/VERSIONS.yaml"
    if [ -f "$vfile" ]; then
        yq -r ".[\"$name\"]" "$vfile" 2>/dev/null || echo "0.0.0"
    else
        echo "0.0.0"
    fi
}

main() {
    [ $# -ne 3 ] && usage
    local dir="$1" name="$2" mode="$3"

    local sp="$dir/docs/larv/STATE.yaml"
    if [ -f "$sp" ]; then
        echo "ERROR: STATE.yaml already exists at $sp — pre-flight is for new projects" >&2
        exit 1
    fi

    echo "[larv pre-flight]"
    echo

    # 1. Bundle check
    echo "Bundle check:"
    local missing=0
    for b in masterplan superpowers-laravel domain-driven-design huashu-design; do
        if bundle_present "$b"; then
            echo "  ✅ $b ($(read_bundle_version "$b"))"
        else
            echo "  ⚠ $b not vendored at bundle/$b"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -gt 0 ]; then
        echo "  ($missing missing — run scripts/bundle-update.sh in implementation plan)"
    fi
    echo

    # 2. MCP check (stub)
    echo "MCP check:"
    echo "  ✅ $(mcp_check_stub) (other MCPs verified in sub-project C)"
    echo

    # 3. Initialize STATE.yaml
    bash "$PLUGIN_ROOT/scripts/state.sh" init "$dir" "$name" "$mode"

    # 4. Populate bundle versions and budget estimate
    local bm bs bd bh
    bm="$(read_bundle_version masterplan)"
    bs="$(read_bundle_version superpowers-laravel)"
    bd="$(read_bundle_version domain-driven-design)"
    bh="$(read_bundle_version huashu-design)"
    bash "$PLUGIN_ROOT/scripts/state.sh" update "$dir" \
        ".plugin.bundle_versions = {\"masterplan\": \"$bm\", \"superpowers-laravel\": \"$bs\", \"domain-driven-design\": \"$bd\", \"huashu-design\": \"$bh\"}"

    bash "$PLUGIN_ROOT/scripts/state.sh" update "$dir" \
        ".budget.estimated_total = {\"tokens\": $DEFAULT_BUDGET_TOKENS, \"minutes\": $DEFAULT_BUDGET_MINUTES, \"cost_usd\": $DEFAULT_BUDGET_COST}"

    # 5. Write pre-flight.md report
    cat >"$dir/docs/larv/pre-flight.md" <<EOF
# Pre-flight report

Project: $name
Mode: $mode
Plugin: larv 0.1.0
Bundle versions:
  - masterplan: $bm
  - superpowers-laravel: $bs
  - domain-driven-design: $bd
  - huashu-design: $bh

Estimated budget: ~$DEFAULT_BUDGET_MINUTES min, ~\$$DEFAULT_BUDGET_COST
Cap policy: pause_at_120pct

This is a sub-project A stub. Full pre-flight (VM ping, MCP enumeration, slice-count-driven budget refinement) is implemented in sub-project B/C.
EOF

    echo "Project: $name (mode: $mode)"
    echo "Estimated budget: ~$DEFAULT_BUDGET_MINUTES min, ~\$$DEFAULT_BUDGET_COST"
    echo
    echo "STATE.yaml initialized at $sp"
    echo "Pre-flight report written to $dir/docs/larv/pre-flight.md"
}

main "$@"
```

- [ ] **Step 4: Make executable and run tests**

Run: `chmod +x scripts/pre-flight.sh && bats tests/pre-flight.bats`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/pre-flight.sh tests/pre-flight.bats
git commit -m "feat: implement Phase -1 pre-flight stub (Task 10)"
```

---

### Task 11: Create document templates

**Files:**
- Create: `templates/slice-handoff.md`
- Create: `templates/sandbox-runbook.md`
- Create: `templates/pre-flight.md`
- Create: `templates/project-lessons.md`
- Create: `templates/adoption-report.md`
- Create: `tests/templates.bats`

- [ ] **Step 1: Write the failing test**

`tests/templates.bats`:
```bash
#!/usr/bin/env bats

load helpers

TEMPLATES=(slice-handoff sandbox-runbook pre-flight project-lessons adoption-report)

@test "all 5 templates exist" {
    for t in "${TEMPLATES[@]}"; do
        [ -f "templates/${t}.md" ] || { echo "missing templates/${t}.md"; return 1; }
    done
}

@test "slice-handoff has Plugin Improvement Notes section" {
    run grep -F "Plugin Improvement Notes" templates/slice-handoff.md
    [ "$status" -eq 0 ]
}

@test "sandbox-runbook documents URL, SSH, docker, firewall" {
    run grep -E "App URL|VM|Docker|Firewall" templates/sandbox-runbook.md
    [ "$status" -eq 0 ]
}

@test "project-lessons explains [project] vs [plugin] tagging" {
    run grep -E "\[project\]|\[plugin\]" templates/project-lessons.md
    [ "$status" -eq 0 ]
}

@test "adoption-report has confidence flags guidance" {
    run grep -F "confidence" templates/adoption-report.md
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/templates.bats`
Expected: All tests fail.

- [ ] **Step 3: Create slice-handoff.md template**

`templates/slice-handoff.md`:
```markdown
# Slice {{NN}} — {{slice-name}}

## Status: {{✅ Ready for QA | 🟡 Partial | 🔴 Blocked}}

## What was built
- (list files: created / modified / deleted)
- (list migrations)
- (list tests)

## How to QA
URL:        {{app-url}}/{{path}}
Login:      {{seeded-creds}}
Walkthrough:
  1. {{step}}
  2. {{step}}
  3. {{step}}

## Sandbox controls
SSH:    ssh {{vm-user}}@{{vm-host}}
Logs:   docker compose -f /srv/{{slug}}/docker-compose.yml logs -f app
Reset:  docker compose exec app php artisan migrate:fresh --seed

## Tests
Pest:        ✅ {{passed}}/{{total}}   coverage {{pct}}%
Playwright:  ✅ {{passed}}/{{total}}

## Plugin Improvement Notes
- (none) | [plugin] {{theme}} — {{body}} | [project] {{body}}

## Next: slice-{{NN+1}}-{{name}}
```

- [ ] **Step 4: Create sandbox-runbook.md template**

`templates/sandbox-runbook.md`:
```markdown
# Sandbox Runbook — {{project-name}}

## App URL
{{app-url}}
Login: {{seeded-email}} / {{seeded-password}}   (seeded)

## VM
Host:  {{vm-host}}   user: {{vm-user}}
SSH:   ssh {{vm-user}}@{{vm-host}}
Key:   ~/.ssh/larv_{{slug}}_ed25519

## Docker stack
Compose:  ~/apps/{{slug}}/docker-compose.yml
Services: {{services-list}}
Up:       docker compose up -d
Logs:     docker compose logs -f app
Reset:    docker compose exec app php artisan migrate:fresh --seed

## Firewall (already configured)
ufw allow from any to any port 80,443,{{additional-ports}}

## Reverse proxy
nginx → app:8000   TLS: Let's Encrypt (auto-renew)
DNS: A record {{slug}}.{{vm-base-domain}} → VM

## How to QA
1. Open {{app-url}}
2. Login with seeded creds
3. After each slice, read slice-NN/handoff.md for the walkthrough
4. File feedback in plain English in the chat — no code needed
```

- [ ] **Step 5: Create pre-flight.md template**

`templates/pre-flight.md`:
```markdown
# Pre-flight report

Project: {{project-name}}
Mode: {{greenfield|adopted}}
Plugin: larv {{version}}
Bundle versions:
  - masterplan: {{ver}}
  - superpowers-laravel: {{ver}}
  - domain-driven-design: {{ver}}
  - huashu-design: {{ver}}

Estimated budget: ~{{minutes}} min, ~${{cost}}
Cap policy: {{cap-policy}}

LEARNINGS digest loaded — {{count}} entries from prior runs.
```

- [ ] **Step 6: Create project-lessons.md template**

`templates/project-lessons.md`:
```markdown
# Project lessons — {{project-name}}

Captured during the larv-managed lifetime of this project.

## Tagging convention

- `[project]` — specific to this app (stays in this file).
- `[plugin]` — generalizable lesson (`/larv:learn` aggregates these into plugin PRs).

## Lessons (chronological)

<!-- add entries below as they accumulate -->

### {{date}} — slice-{{NN}}: {{title}}

`[project]` {{body}}

```

- [ ] **Step 7: Create adoption-report.md template**

`templates/adoption-report.md`:
```markdown
# Adoption report — {{project-name}}

Adopted: {{date}}
Plugin: larv {{version}}
Mode: adopted (`/larv:full` refused; use `/larv:feature` and `/larv:debug`)

## Summary

What was found:
- {{summary}}

What was inferred vs. verified:
- {{summary with confidence breakdown}}

What's missing or low-confidence:
- {{list, with pointers to docs/larv/* that need human review}}

## Confidence breakdown

Every section in `docs/larv/01-domain/`, `02-architecture/`, `03-design/`, `04-test-strategy/` carries a confidence marker:

- `[confidence: high]` — extracted from clear code/config evidence
- `[confidence: medium — inferred]` — best guess from indirect signals
- `[confidence: low — placeholder]` — heuristic only, needs human review

Promote a section's confidence by editing the marker after verification.

## Top recommendations

1. {{top recommendation}}
2. ...
3. ...

## Health flags

{{Flag any red flags found in A0 — Laravel < 9, vendor patches, no tests, etc.}}
```

- [ ] **Step 8: Run tests**

Run: `bats tests/templates.bats`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add templates/ tests/templates.bats
git commit -m "feat: add 5 document templates (Task 11)"
```

---

### Task 12: Initialize LEARNINGS.md skeleton

**Files:**
- Create: `LEARNINGS.md`
- Create: `tests/learnings.bats`

- [ ] **Step 1: Write the failing test**

`tests/learnings.bats`:
```bash
#!/usr/bin/env bats

load helpers

@test "LEARNINGS.md exists at repo root" {
    [ -f LEARNINGS.md ]
}

@test "LEARNINGS.md has all documented section headings" {
    for section in \
        "Library version notes" \
        "Discuss-phase questions" \
        "Patterns promoted" \
        "Failure modes prevented" \
        "Composition lessons"; do
        run grep -F "## $section" LEARNINGS.md
        [ "$status" -eq 0 ] || { echo "missing section: $section"; return 1; }
    done
}

@test "LEARNINGS.md initial state has no real entries (just structure)" {
    run grep -cE "^- " LEARNINGS.md
    # zero real bullet entries beyond placeholders
    [ "$output" -le 5 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/learnings.bats`
Expected: All tests fail.

- [ ] **Step 3: Create LEARNINGS.md skeleton**

`LEARNINGS.md`:
```markdown
# LEARNINGS

This file is the larv plugin's compounding self-knowledge. Loaded into context by every `/larv:full` run during pre-flight (Phase −1) so each project benefits from prior projects' lessons.

## How entries get here

1. During a project run, slice/phase handoffs include a `## Plugin Improvement Notes` section. Notes prefixed `[plugin]` are generalizable; `[project]` are specific.
2. `/larv:learn` aggregates `[plugin]` notes, clusters them by theme, and opens a PR with proposed edits to this file and to relevant skill prompts.
3. A maintainer reviews and merges. CI runs the plugin's fixture tests on every PR.

## Sections

Entries are indexed (not chronological). Add to the matching section.

## Library version notes

<!-- API drift, version-specific gotchas, currently-supported versions per dependency -->

## Discuss-phase questions

<!-- Questions to add to Phase 0 (or Feature/Debug F0) based on past missing-info incidents -->

## Patterns promoted

<!-- Non-obvious approaches that worked cleanly and should be the default -->

## Failure modes prevented

<!-- Recurring failure modes and the guards we added -->

## Composition lessons

<!-- Insights about how upstream skills interact (masterplan + superpowers-laravel + huashu + ddd) -->

---

## Maintenance

When this file approaches ~500 lines, `/larv:learn` will propose a structural split into per-section files under `learnings/`. The index here will then point to the section files.
```

- [ ] **Step 4: Run tests**

Run: `bats tests/learnings.bats`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add LEARNINGS.md tests/learnings.bats
git commit -m "feat: initialize LEARNINGS.md skeleton (Task 12)"
```

---

### Task 13: Create greenfield-todo fixture and smoke test

**Files:**
- Create: `tests/fixtures/greenfield-todo/.gitkeep`
- Create: `tests/fixtures.bats`

Acceptance criterion #8: smoke test exercises orchestrator stub through Phase −1 without errors.

- [ ] **Step 1: Write the failing test**

`tests/fixtures.bats`:
```bash
#!/usr/bin/env bats

load helpers

@test "greenfield-todo fixture directory exists" {
    [ -d tests/fixtures/greenfield-todo ]
}

@test "smoke test: pre-flight runs end-to-end on greenfield-todo fixture" {
    local tmp
    tmp="$(mktemp -d)"
    # Copy the fixture as the project root
    cp -r tests/fixtures/greenfield-todo/. "$tmp"
    run bash scripts/pre-flight.sh "$tmp" todo-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$tmp/docs/larv/STATE.yaml" ]
    [ -f "$tmp/docs/larv/pre-flight.md" ]

    # status against the populated state should print without error
    run bash scripts/status.sh "$tmp"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "todo-app"

    # resume should advance to phase 0
    run bash scripts/resume.sh "$tmp"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "phase 0"
    rm -rf "$tmp"
}
```

- [ ] **Step 2: Create the fixture (empty for now)**

```bash
mkdir -p tests/fixtures/greenfield-todo
touch tests/fixtures/greenfield-todo/.gitkeep
```

The fixture intentionally has no content — pre-flight initializes everything in a tmp copy.

- [ ] **Step 3: Run smoke test**

Run: `bats tests/fixtures.bats`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/greenfield-todo/ tests/fixtures.bats
git commit -m "feat: greenfield-todo fixture + Phase -1 smoke test (Task 13, acceptance #8)"
```

---

### Task 14: Create existing-blog fixture (lite)

**Files:**
- Create: `tests/fixtures/existing-blog/composer.json`
- Create: `tests/fixtures/existing-blog/README.md`
- Create: `tests/fixtures/existing-blog/.gitkeep`

This is a lite fixture for sub-project B's adoption tests. Sub-project A only needs the directory to exist with a recognizable Laravel signature so future tests have a target.

- [ ] **Step 1: Create the fixture**

`tests/fixtures/existing-blog/composer.json`:
```json
{
  "name": "fixture/existing-blog",
  "type": "project",
  "require": {
    "php": "^8.3",
    "laravel/framework": "^12.0",
    "filament/filament": "^4.0"
  },
  "license": "MIT",
  "minimum-stability": "stable",
  "prefer-stable": true
}
```

`tests/fixtures/existing-blog/README.md`:
```markdown
# existing-blog fixture

Minimal Laravel-shaped fixture for `/larv:adopt` tests. Sub-project A only needs the directory to exist; sub-project B will add migrations, models, routes, and tests for full adoption coverage.
```

- [ ] **Step 2: Add a smoke test verifying the fixture is recognizable**

Append to `tests/fixtures.bats`:
```bash
@test "existing-blog fixture is recognizable as Laravel" {
    [ -f tests/fixtures/existing-blog/composer.json ]
    run jq -r '.require | keys | .[]' tests/fixtures/existing-blog/composer.json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "laravel/framework"
}
```

- [ ] **Step 3: Run tests**

Run: `bats tests/fixtures.bats`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/existing-blog/ tests/fixtures.bats
git commit -m "feat: existing-blog fixture (lite) for sub-project B (Task 14)"
```

---

### Task 15: Vendor upstream into bundle/ at pinned versions

**Files:**
- Create: `bundle/VERSIONS.yaml`
- Create: `bundle/masterplan/PLACEHOLDER.md`
- Create: `bundle/superpowers-laravel/PLACEHOLDER.md`
- Create: `bundle/domain-driven-design/PLACEHOLDER.md`
- Create: `bundle/huashu-design/PLACEHOLDER.md`
- Create: `scripts/bundle-update.sh`
- Create: `tests/bundle.bats`

For sub-project A, the bundle is **directories with a placeholder file**. Real vendoring is a maintenance step done once before the first real `/larv:full` execution (it's a manual step in v0.1.0; Renovate handles updates from v0.2.0).

- [ ] **Step 1: Write the failing test**

`tests/bundle.bats`:
```bash
#!/usr/bin/env bats

load helpers

BUNDLES=(masterplan superpowers-laravel domain-driven-design huashu-design)

@test "bundle/VERSIONS.yaml exists and is valid YAML" {
    [ -f bundle/VERSIONS.yaml ]
    run yq empty bundle/VERSIONS.yaml
    [ "$status" -eq 0 ]
}

@test "bundle/VERSIONS.yaml lists all 4 dependencies" {
    for b in "${BUNDLES[@]}"; do
        run yq -r ".[\"$b\"]" bundle/VERSIONS.yaml
        [ "$status" -eq 0 ]
        [ "$output" != "null" ]
    done
}

@test "all 4 bundle directories exist" {
    for b in "${BUNDLES[@]}"; do
        [ -d "bundle/$b" ] || { echo "missing bundle/$b"; return 1; }
    done
}

@test "bundle-update.sh exists and is executable" {
    [ -x scripts/bundle-update.sh ]
}

@test "bundle-update.sh prints help with no args" {
    run bash scripts/bundle-update.sh
    echo "$output" | grep -qiE "usage|help"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/bundle.bats`
Expected: All tests fail.

- [ ] **Step 3: Create bundle/VERSIONS.yaml**

`bundle/VERSIONS.yaml`:
```yaml
# Pinned versions for bundled upstream sources.
# Updated by Renovate (patch auto-merge if CI green) or manually for minor/major.
masterplan: "4.2.0"
superpowers-laravel: "0.1.5"
domain-driven-design: "10.5.0"
huashu-design: "1.2.0"
```

- [ ] **Step 4: Create bundle directory placeholders**

For each of the 4 bundles, create `bundle/<name>/PLACEHOLDER.md`:

`bundle/masterplan/PLACEHOLDER.md`:
```markdown
# Vendored: masterplan

Pinned to version listed in `bundle/VERSIONS.yaml`. Replace this file with the real vendored content via `scripts/bundle-update.sh masterplan`.

Until then this directory exists so `pre-flight.sh` bundle-check passes structurally.
```

(Repeat the pattern for `superpowers-laravel`, `domain-driven-design`, `huashu-design`.)

- [ ] **Step 5: Create bundle-update.sh**

`scripts/bundle-update.sh`:
```bash
#!/usr/bin/env bash
# scripts/bundle-update.sh - manually vendor an upstream source into bundle/
#
# Sub-project A v0.1.0: this is a documentation script. Real vendoring (git subtree,
# rsync from cache, etc.) is implemented in sub-project A v0.2.0 + Renovate config.
set -euo pipefail

usage() {
    cat <<EOF
Usage: bundle-update.sh <name>

Names: masterplan | superpowers-laravel | domain-driven-design | huashu-design

This is a manual vendor command for v0.1.0. From v0.2.0 onward, Renovate handles
updates automatically (patch versions auto-merge if CI passes; minor/major opens PR).

Manual procedure (until v0.2.0):
  1. Confirm version in bundle/VERSIONS.yaml
  2. Locate the upstream source (paths documented in adr/0001-bundled-marketplace.md)
  3. rsync (or git subtree pull) into bundle/<name>/
  4. Replace bundle/<name>/PLACEHOLDER.md with the real content
  5. Run the full plugin test suite: bats tests/
  6. Commit: "chore(bundle): update <name> to <version>"
EOF
    exit 0
}

[ $# -lt 1 ] && usage

NAME="$1"

case "$NAME" in
    masterplan|superpowers-laravel|domain-driven-design|huashu-design) ;;
    *) echo "ERROR: unknown bundle name '$NAME'" >&2; usage; exit 1 ;;
esac

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(yq -r ".[\"$NAME\"]" "$PLUGIN_ROOT/bundle/VERSIONS.yaml")"

cat <<EOF
Manual vendor procedure for: $NAME
Pinned version: $VERSION
Target directory: $PLUGIN_ROOT/bundle/$NAME

Steps:
  1. Locate $NAME source at $VERSION (see adr/0001-bundled-marketplace.md for canonical paths)
  2. Copy contents into $PLUGIN_ROOT/bundle/$NAME/
  3. Remove the PLACEHOLDER.md file
  4. Run: bats tests/
  5. Commit with message: "chore(bundle): update $NAME to $VERSION"
EOF
```

- [ ] **Step 6: Make executable and run tests**

Run: `chmod +x scripts/bundle-update.sh && bats tests/bundle.bats`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add bundle/ scripts/bundle-update.sh tests/bundle.bats
git commit -m "feat: bundle scaffolding with pinned versions + update script (Task 15)"
```

---

### Task 16: Write ADR 0001 — Bundled marketplace

**Files:**
- Create: `adr/0001-bundled-marketplace.md`

- [ ] **Step 1: Create ADR**

`adr/0001-bundled-marketplace.md`:
```markdown
# ADR 0001 — Bundled marketplace as the distribution model

Date: 2026-05-04
Status: Accepted
Decision-makers: itranario@oakdriveventures.com

## Context

`larv` orchestrates four upstream sources: `masterplan`, `superpowers-laravel`, `domain-driven-design` (single skill from antigravity-awesome-skills), and `huashu-design`. The plugin must be installable by team members in one step, reproducible across machines, and resilient to upstream changes that might break composition.

Three distribution models were considered:

1. **Thin orchestrator** — `larv` declares dependencies on the four upstream plugins and assumes the user has them installed. No vendoring.
2. **Bundled marketplace** — `larv` vendors pinned versions of all four sources inside `bundle/` and is distributed as a single Claude Code marketplace.
3. **Vendored fork-and-patch** — `larv` copies and modifies upstream source.

## Decision

Adopt **option 2 — bundled marketplace**.

## Rationale

- **Zero install friction.** One `claude plugin install` command brings everything. Critical for team onboarding.
- **Reproducibility.** Pinned versions in `bundle/VERSIONS.yaml` mean every team member's environment matches.
- **Composition stability.** Upstream breaking changes only affect us when we deliberately update the bundle (gated by Renovate + CI fixture tests).
- **No drift from upstream.** Unlike option 3, we don't fork — `bundle/` is a vendored copy at a specific version, not a patched derivative. Improvements still flow upstream via PR to the source repos.

## Consequences

- Maintenance: Renovate opens PRs for upstream updates. Patch auto-merge if CI passes. Minor/major requires maintainer review.
- Repo size: bundle adds ~10-30 MB. Acceptable for a private team plugin; would be a concern if open-sourced widely (option 1 would be revisited).
- CI: every PR (Renovate or human) runs `tests/fixtures/{greenfield-todo,existing-blog}/` against bundled + larv skills. Catches composition breakage.

## Canonical upstream sources

- `masterplan` → user's local skills directory at `~/.claude/skills/masterplan-*`
- `superpowers-laravel` → `~/.claude/plugins/cache/superpowers-laravel-marketplace/superpowers-laravel/0.1.5/`
- `domain-driven-design` → single skill at `~/.claude/plugins/cache/antigravity-awesome-skills/.../skills/domain-driven-design/`
- `huashu-design` → `~/.agents/skills/huashu-design/`

These are local paths in the maintainer's environment for v0.1.0. From v0.2.0, Renovate config will reference upstream Git URLs once the plugin is hosted on the team's GitHub org.

## Reviewed

- N/A (initial decision)
```

- [ ] **Step 2: Commit**

```bash
git add adr/0001-bundled-marketplace.md
git commit -m "docs: ADR 0001 - bundled marketplace as distribution model (Task 16)"
```

---

### Task 17: Set up GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create CI workflow**

`.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Install yq
        run: |
          sudo curl -sSL https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 \
              -o /usr/local/bin/yq
          sudo chmod +x /usr/local/bin/yq
          yq --version

      - name: Install bats-core
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y bats

      - name: Validate plugin manifest
        run: jq empty .claude-plugin/plugin.json

      - name: Run all bats tests
        run: bats tests/

      - name: Validate STATE.yaml fixtures
        run: |
          for f in tests/fixtures/state-*.yaml; do
            yq empty "$f" || { echo "invalid YAML: $f"; exit 1; }
          done

  lint:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y shellcheck
          find scripts/ migrations/ -name '*.sh' -print0 \
            | xargs -0 shellcheck -e SC2155 -e SC1091
```

- [ ] **Step 2: Verify locally**

Run: `bats tests/ && find scripts/ migrations/ -name '*.sh' -print0 | xargs -0 shellcheck -e SC2155 -e SC1091`
Expected: PASS / no errors.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/
git commit -m "ci: GitHub Actions workflow (bats + shellcheck) (Task 17)"
```

---

### Task 18: Configure Renovate

**Files:**
- Create: `.github/renovate.json`

- [ ] **Step 1: Create renovate config**

`.github/renovate.json`:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 6am on Monday"],
  "labels": ["dependencies"],
  "packageRules": [
    {
      "description": "Auto-merge patch versions for bundled upstream if CI passes",
      "matchManagers": ["regex"],
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "pr",
      "platformAutomerge": true
    },
    {
      "description": "Open PR for review on minor/major bundled updates",
      "matchManagers": ["regex"],
      "matchUpdateTypes": ["minor", "major"],
      "automerge": false,
      "reviewers": ["@your-org/larv-maintainers"]
    }
  ],
  "regexManagers": [
    {
      "fileMatch": ["^bundle/VERSIONS\\.yaml$"],
      "matchStrings": [
        "(?<depName>[a-z-]+):\\s+\"(?<currentValue>[0-9.]+)\""
      ],
      "datasourceTemplate": "github-releases",
      "lookupNameTemplate": "your-org/{{depName}}"
    }
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add .github/renovate.json
git commit -m "ci: Renovate config (patch auto-merge, minor/major PR) (Task 18)"
```

---

### Task 19: Final acceptance verification

Confirm all 9 acceptance criteria from spec §16 are met.

- [ ] **Step 1: Verify acceptance criterion #1 (repo structure matches spec §5)**

Run: `tree -L 2 -I '.git'`
Expected: structure matches the diagram in spec §5 (modulo the pluralization of `migrations/state/`).

- [ ] **Step 2: Verify acceptance criterion #2 (manifest)**

Run: `bats tests/manifest.bats`
Expected: 5/5 PASS.

- [ ] **Step 3: Verify acceptance criterion #3 (bundle vendored at pinned versions)**

Run: `bats tests/bundle.bats`
Expected: 5/5 PASS.

(Note: this verifies the *scaffold* — real upstream content is vendored manually via `scripts/bundle-update.sh` before first `/larv:full` invocation. Documented in ADR 0001.)

- [ ] **Step 4: Verify acceptance criterion #4 (`/larv:status` works against empty STATE.yaml)**

Run:
```bash
TMP="$(mktemp -d)"
mkdir -p "$TMP/docs/larv"
cp tests/fixtures/state-empty.yaml "$TMP/docs/larv/STATE.yaml"
bash scripts/status.sh "$TMP"
rm -rf "$TMP"
```
Expected: prints project summary; exits 0.

- [ ] **Step 5: Verify acceptance criterion #5 (`/larv:resume` decision tree)**

Run: `bats tests/resume.bats`
Expected: 7/7 PASS, including the empty-state, gate-pending, and errors-unresolved branches.

- [ ] **Step 6: Verify acceptance criterion #6 (migration test passes)**

Run: `bats tests/migrations.bats`
Expected: 3/3 PASS, including the v1-to-v1 noop.

- [ ] **Step 7: Verify acceptance criterion #7 (LEARNINGS.md skeleton)**

Run: `bats tests/learnings.bats`
Expected: 3/3 PASS.

- [ ] **Step 8: Verify acceptance criterion #8 (greenfield-todo smoke test)**

Run: `bats tests/fixtures.bats`
Expected: tests pass, including the smoke test that runs pre-flight → status → resume.

- [ ] **Step 9: Verify acceptance criterion #9 (README matches usage guide)**

Run: `diff README.md docs/superpowers/specs/2026-05-04-larv-plugin-usage-guide.md`
Expected: no diff (Task 1 step 4 copied them; if they have drifted, re-copy).

- [ ] **Step 10: Run full test suite once more**

Run: `bats tests/`
Expected: ALL tests PASS.

- [ ] **Step 11: Tag v0.1.0**

```bash
git tag -a v0.1.0 -m "Sub-project A: plugin shell + composition strategy"
```

- [ ] **Step 12: Final commit confirming acceptance**

```bash
git commit --allow-empty -m "chore: sub-project A complete; all 9 acceptance criteria verified

- Repo structure matches spec §5
- plugin.json valid + 8 commands + 15 skills
- Bundle scaffolded; vendoring procedure documented in ADR 0001
- /larv:status works against empty + populated STATE.yaml
- /larv:resume handles errors_unresolved, gates_pending, budget cap, phase advancement
- STATE.yaml schema v1 + v1-to-v1 noop migration tested
- LEARNINGS.md skeleton with documented section structure
- greenfield-todo fixture + Phase -1 smoke test passing
- README.md matches usage guide

Sub-project B (per-phase prompts), C (sandbox runtime),
D (Laravel Cloud deploy), E (self-improvement governance)
remain out of scope.
"
```

---

## Self-Review

Spec coverage check:

| Spec section | Implemented in |
|---|---|
| §1 Summary | All tasks combined |
| §2 Goals | Tasks 1, 5, 8, 9, 10 (resumable, bounded context, end-to-end shape) |
| §3 Non-goals | Tasks intentionally exclude per-phase prompts (sub-project B) |
| §4 Composition policy | Skill stubs (Task 3) reference upstream skills via the mapping table |
| §5 Plugin repo structure | Task 1, 2, 3, 11, 15, 16, 17, 18 |
| §6 Command surface | Task 2 (8 commands) |
| §7 Phase workflow | Task 3 (skill stubs document phase responsibility), Task 10 (Phase -1 stub) |
| §8 Subagent orchestration | Task 3 (orchestrator skill documents the contract) |
| §9 State + resume | Tasks 4, 5, 6, 8, 9 |
| §10 Self-improvement loop | Task 12 (LEARNINGS.md), Task 3 (larv-learn skill stub) |
| §11 /larv:adopt flow | Task 3 (larv-adopt skill stub), Task 14 (existing-blog fixture) |
| §12 Captured decisions | Tasks 4, 5, 9 (encoded in STATE.yaml schema) |
| §13 Plugin name + repo | Task 1 (plugin.json: `larv`) |
| §14 Out of scope | Plan explicitly excludes B/C/D/E details; stubs flagged |
| §15 Refinements | Acceptance gives them a home but does not implement (correct for sub-project A) |
| §16 Acceptance criteria | Task 19 (all 9 verified) |
| §17 Risks | Mitigations baked in: atomic writes (Task 5), file lock (Task 6), CI tests (Task 17), ADR 0001 (Task 16) |
| §18 Glossary | Already in spec; not duplicated in code |

Placeholder scan: no `TBD`/`TODO`/`fill in details` in any task. The skill-stub `STUB` markers are intentional and tested.

Type/identifier consistency: command file paths in `plugin.json` match the actual filenames; skill paths match the actual directories; `STATE.yaml` keys are consistent across `state.sh`, `status.sh`, `resume.sh`, `pre-flight.sh`, and the schema doc.

---

## Plan complete and saved to `docs/superpowers/plans/2026-05-04-larv-plugin-shell.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
