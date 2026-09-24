# larv

AI-driven Laravel application workflow for Claude Code and Codex CLI.

`larv` is an open-source MIT-licensed workflow plugin for developers and teams building Laravel applications with AI coding agents.

`larv` is a plugin that turns a Laravel idea or existing Laravel repository into a structured, reviewable development workflow. It guides the agent through product discovery, domain modeling, Laravel architecture, UI design, test planning, risk review, implementation handoff, sandbox verification, production deployment guidance, and post-project learning.

The plugin is designed for developers who want AI assistance without losing engineering discipline. It writes durable project artifacts under `docs/larv/`, uses explicit gates before implementation, and generates self-contained handoff files that another agent or tool can execute.

## What It Is For

Use `larv` when you want to:

- Plan and build a new Laravel app from a blank directory.
- Adopt an existing Laravel app into a documented workflow without changing app code.
- Add features or fix bugs through a gated design, plan, handoff, and verification loop.
- Generate browser-reviewable design mockups and doc sites.
- Keep implementation resumable across long sessions, different agents, or different tools.
- Produce production runbooks, environment guides, user manuals, seed-data guides, and testing instructions.
- Run a static security baseline before installing, bootstrapping, or executing repository code.

`larv` is not a Laravel package installed with Composer. It is an AI workflow plugin made of commands, skills, scripts, templates, and bundled reference material.

## Core Ideas

- **Docs-first workflow**: durable outputs live in `docs/larv/`, `docs/Handsoff/`, `docs/user-manual/`, and `adr/`.
- **Phase gates**: major decisions are reviewed before the next phase proceeds.
- **DDD before tech**: greenfield projects start with a business-process interview before Laravel package choices.
- **Laravel-aware planning**: selected packages such as Filament, Sanctum/Fortify, Cashier, Horizon, Reverb, Scout, tenancy, uploads, queues, and notifications propagate into architecture, tests, environment docs, and slices.
- **Self-contained handoff**: implementation reads `docs/Handsoff.md` and `docs/Handsoff/slice-NN-*.md`, not hidden chat context.
- **Sandbox-first verification**: generated apps are expected to run in a browser-visible sandbox before production guidance.
- **Security baseline**: static checks run before dependency installation, app bootstrap, and implementation slices.
- **Safe token optimizer gate**: optional Headroom/LeanCTX use must pass `scripts/token-optimizer.sh` version, hash, install-path, telemetry, proxy, shell-hook, and config-mutation checks; otherwise larv continues without an optimizer.
- **Strict Caveman output**: allowlisted larv planning flows default to Caveman `full`; missing dependencies are reported as `full-unavailable` instead of silently falling back to normal style.
- **YAGNI-first implementation**: Ponytail's decision ladder is embedded in the implementation phase — every slice uses only what the spec requires, reaching for Laravel's framework and installed packages before writing new code.

## Ponytail Integration

larv bundles [Ponytail](https://github.com/DietrichGebert/ponytail) (v4.8.3, MIT) as a vendored skill in `bundle/ponytail/`. Ponytail's YAGNI decision ladder is embedded directly in `skills/larv-implement/SKILL.md` and is active automatically during Phase 8 — no separate plugin install required.

The ladder stops at the first rung that holds before any code is written: Does it need to exist? Is it already in the codebase? Does Laravel's framework cover it? Is it already an installed dependency? Can it be one line? Only then: the minimum the slice spec requires.

Security, validation, error handling, and anything explicitly required by the slice spec are never simplified away.

**Standalone use:** Installing Ponytail as a Claude Code plugin (`/plugin install ponytail@ponytail`) extends the same YAGNI discipline to non-larv sessions.

## Repository Layout

| Path | Purpose |
|---|---|
| `.claude-plugin/` | Claude plugin metadata and local marketplace metadata |
| `.codex-plugin/` | Codex plugin metadata |
| `.agents/plugins/` | Local Codex marketplace entry |
| `commands/` | User-facing `/larv:*` command prompts |
| `codex-skills/` | Codex-visible skill wrappers for `/larv:*` triggers |
| `skills/` | Main larv workflow skills and phase controllers |
| `scripts/` | Runtime helpers for pre-flight, status, resume, sandbox, presentation, scanning, and handoff rendering |
| `templates/` | Generated handoff, runtime, environment, docs, seed-data, and user-manual templates |
| `bundle/` | Vendored upstream reference skills and assets used by larv |
| `tests/` | Bats test suite for commands, skills, templates, scripts, and generated behavior |
| `docs/` | Project design docs and developer notes for this plugin |

## Installation

### Claude Code

For a public repository, install through your plugin source once published:

```bash
claude plugin install <owner>/larv
```

For local development from this repository:

```bash
claude plugin marketplace add .
claude plugin install larv-local/larv
```

Restart Claude Code after installation so commands and skills are reloaded.

### Codex CLI

From this repository root:

```bash
codex plugin marketplace add .
```

Codex may not expose local marketplace commands in the slash-command picker the same way Claude Code does. The repo includes Codex skill wrappers in `codex-skills/`. For local development, expose them as a skill namespace:

```bash
ln -sfn /path/to/larv/codex-skills ~/.agents/skills/larv
```

Restart Codex after adding the marketplace or symlink. Typing prompts such as `/larv:full`, `/larv:status`, or `/larv:resume` should then route through the matching Codex skill wrapper.

## Runtime Setup

`larv` assumes the agent can run shell commands in the project workspace. For full greenfield implementation and sandbox review, the environment should have:

- PHP, Composer, and common Laravel PHP extensions.
- Node.js/npm when the generated Laravel frontend requires asset builds.
- Strict Caveman output styling is controlled separately via `/larv-caveman`.
- PostgreSQL for the default sandbox bootstrap.
- `curl`, `rsync`, `ss`, `flock`, and `setsid`.
- `yq` for YAML state operations.
- `bats` for this plugin's test suite.

larv includes a bundled Caveman-compatible binary at `bundle/caveman/bin/caveman`, so strict `full` works without a global install. For an external reviewed binary, point `LARV_CAVEMAN_BIN` at it.

Legacy npm package install guidance is intentionally not used by default because the original `@larv/caveman` package is not available in the public npm registry.

For external Caveman support:

```bash
export LARV_CAVEMAN_BIN="/path/to/reviewed/caveman"
```

Known compatibility: upgrading/downgrading this dependency can alter exact phrasing and emphasis.

Optional override examples:

```bash
export LARV_CAVEMAN_BIN="path/to/caveman"
export LARV_CAVEMAN_VERSION="1.0.0"
export LARV_CAVEMAN_ALLOWLIST="full,debug,feature"
export LARV_CAVEMAN_WARN_ON_VERSION_MISMATCH="0"
export LARV_CAVEMAN_ALLOWLIST_FILE="scripts/caveman-allowlist.txt"
```

`LARV_CAVEMAN_WARN_ON_VERSION_MISMATCH=0` suppresses version-mismatch warnings when you intentionally pin a fork/version.

`LARV_CAVEMAN_STRICT=0` is reserved for deterministic compatibility tests that need the old normal fallback. Normal larv workflow should leave strict mode enabled.

The default public sandbox host is the placeholder `sandbox.example.com`. Override it for your environment:

```bash
export LARV_VM_HOST="your-public-host.example.com"
export LARV_VM_HOST_SSH_USER="your-runtime-user"
```

Sandbox app, docs, mockup, and presentation ports are selected from dedicated ranges and can be provided explicitly for recovery or firewall-managed environments.

## Quick Start

### New Laravel App

In an empty project directory:

```text
/larv:full Build a small multi-user task manager with team workspaces, email invites, and an admin dashboard.
```

The workflow will:

1. Run pre-flight checks and a static security baseline.
2. Create `docs/larv/STATE.yaml`.
3. Interview the business process.
4. Decide Laravel packages and architecture.
5. Produce design mockups and test strategy.
6. Plan implementation slices.
7. Generate handoff docs.
8. Ask where implementation should run.
9. Implement or hand off slices.
10. Verify the app and prepare production docs.

### Existing Laravel App

In an existing Laravel app:

```text
/larv:adopt
```

Adoption is read-only on application code. It inspects the app and creates `docs/larv/` documentation, state, architecture extraction, test reality notes, risk register, and an adoption report.

### Resume Work

```text
/larv:status
/larv:resume
```

`status` summarizes `docs/larv/STATE.yaml`. `resume` continues from unresolved errors, pending gates, budget caps, or the next phase.

`/larv-caveman` manages strict Caveman output styling for planning commands. The default is `full`.

`/larv-caveman` supports:

- `Caveman full`
- `Caveman lite`
- `Caveman ultra`
- `off` / `normal` / `clear` return to strict `full`

Allowed commands that read this setting:

- `larv:brainstorm`, `larv:debug`, `larv:feature`, `larv:full`
- `larv-feature-feedback`, `larv-feature-how-it-works`, `larv-feature-onboarding-helper`

Example one-shot usage:

```text
larv:feature Improve onboarding flow with Caveman lite
```

For quick status:

```bash
bash scripts/caveman.sh status "$PWD"
```

If the dependency is missing in strict mode, status reports `full-unavailable`. Install or point `LARV_CAVEMAN_BIN` at the pinned binary instead of assuming normal output was used.

To measure Headroom token optimization on a file:

```bash
bash scripts/token-optimizer.sh measure "$PWD" path/to/file
```

For stdin:

```bash
some-command | bash scripts/token-optimizer.sh measure "$PWD" -
```

Measurement reports `tokens_before`, `tokens_after`, `tokens_saved`, `savings_percent`, `compression_ratio`, `target_met`, and `exact_replay`.

The measurement path first tries gated Headroom direct compression. If Headroom protects code or does not meet the 50% savings target, larv applies a local `larv-context-pack` outline for planning, status, and progress reporting. `exact_replay=false` means the optimized artifact is not byte-exact; re-read the original file before editing exact code.

## Commands

### Project Lifecycle

| Command | Purpose |
|---|---|
| `/larv:full` | Run the full greenfield Laravel workflow from idea to implementation, verification, deployment guidance, and learnings |
| `/larv:adopt` | Bring an existing Laravel app under larv management without changing app code |
| `/larv:brainstorm` | Run exploratory Phase 0 discussion only, without initializing a full build |
| `/larv:feature <name>` | Add a feature to a managed project through design, planning, handoff, docs, and implementation gates |
| `/larv:debug <issue>` | Fix a bug through root-cause analysis, regression test planning, handoff, and gated implementation |
| `/larv-caveman` | Inspect or set Caveman style for planning commands |
| `/larv:learn` | Aggregate project learnings and plugin improvement notes |
| `/larv:status` | Print the current `docs/larv/STATE.yaml` summary |
| `/larv:resume` | Continue from the last saved larv checkpoint |

### Runtime And Review

| Command | Purpose |
|---|---|
| `/larv:sandbox` | Show current app, docs, and mockup URLs, readiness, seed credentials, and testing instructions |
| `/larv:sandbox-start` | Start or restart app/docs/mockup servers and verify public URLs |
| `/larv:sandbox-stop` | Stop runtime processes owned by the current project |
| `/larv:sandbox-reset` | Run migrate fresh/seed, restart sandbox services, and verify URLs |
| `/larv:presentation` | Generate and serve visual role workflow, user-flow, and data-flow presentations for the current repo |
| `/larv:security` | Run the static non-executing repository security guard |

### UI And Product Features

| Command | Purpose |
|---|---|
| `/larv:redesign-attio-finance` | Redesign the Laravel frontend with the bundled Attio Finance CRM visual system |
| `/larv:redesign-attio-venture` | Redesign the Laravel frontend with the bundled Attio Venture CRM visual system |
| `/larv:redesign-impeccable-higgsfield` | Redesign the Laravel frontend using Impeccable directions and Higgsfield comps picked from a public sandbox board |
| `/larv:design-setup` | Install and verify the pinned Higgsfield CLI and the vendored Impeccable skill |
| `/larv-feature-how-it-works` | Add an in-app `/guide` or `/how-it-works` feature page |
| `/larv-feature-feedback` | Add authenticated in-app feedback with persistence, admin triage, optional screenshots/context, and email delivery |
| `/larv-feature-onboarding-helper` | Add onboarding/helper UX backed by a full user-flow inventory |

## Greenfield Phases

`/larv:full` drives these phases:

| Phase | Skill | Output |
|---|---|---|
| -1 | pre-flight scripts and security guard | `docs/larv/STATE.yaml`, security baseline, pre-flight report |
| 0a | `larv-domain-interview` | business process, ubiquitous language, invariants, edge cases, subdomain draft |
| 0 | `larv-discuss` | product brief, Laravel package choices, MCP decisions, design preference |
| 1 | `larv-domain` | DDD viability decision and Laravel domain model |
| 2 | `larv-architecture` | C4 diagrams, ADRs, package integration matrix |
| 3 | `larv-design` | design recommendation, mockups, brand spec, visual implementation contract |
| 4 | `larv-tests` | Pest/Playwright/package test matrix and acceptance criteria |
| 5 | `larv-premortem` | risks, adversarial review, possible loop-back decisions |
| 6 | `larv-plan` | Elephant Carpaccio slices, token budget, sandbox deploy script |
| 6.5 | `larv-docsite` | browser-served docs review site |
| 7 | `larv-handoff` | `docs/Handsoff.md`, per-slice handoffs, runtime guides, AI starting points |
| 8 | `larv-implement` | slice execution from handoff docs |
| 9 | `larv-verify` | Pint/Pest/Larastan/build/migration/sandbox final report |
| 10 | `larv-deploy` | production deployment guidance and smoke-check notes |
| 11 | `larv-learn` | project and plugin learnings |

## Skills

The main workflow skills live in `skills/`:

| Skill | Role |
|---|---|
| `larv-orchestrator` | Top-level dispatcher for greenfield, feature, and debug modes |
| `larv-domain-interview` | Business-process DDD interview before technical decisions |
| `larv-discuss` | Laravel ecosystem brainstorming and package decisions |
| `larv-domain` | DDD viability and Laravel domain modeling |
| `larv-architecture` | C4 architecture, ADRs, and package integration matrix |
| `larv-design` | Design direction, mockups, brand spec, visual contract |
| `larv-tests` | Test strategy, package test matrix, acceptance criteria |
| `larv-premortem` | Failure modes and adversarial review |
| `larv-plan` | Implementation slices and sandbox deploy script |
| `larv-docsite` | Browser-served docs review before implementation |
| `larv-handoff` | Universal handoff docs and AI starting points |
| `larv-implement` | Thin implementation loop that executes handoff slices |
| `larv-verify` | Final Laravel verification before deployment guidance |
| `larv-deploy` | Production deployment guidance |
| `larv-learn` | Learnings aggregation |
| `larv-adopt` | Existing-app adoption controller |
| `larv-security` | Static repository guard |
| `larv-presentation` | Visual workflow presentation generator |
| `larv-redesign-attio-finance` | Attio Finance frontend redesign workflow |
| `larv-redesign-attio-venture` | Attio Venture frontend redesign workflow |
| `larv-feature-how-it-works` | In-app guide/how-it-works feature |
| `larv-feature-feedback` | In-app feedback feature |
| `larv-feature-onboarding-helper` | Onboarding/helper feature |
| `larv-hyperframes` | Promo video planning/execution workflow for larv-managed apps |
| `larv-provision` | Legacy reference for sandbox provisioning invariants |
| `larv-full-test` | Full production feature sweep — collects all bugs first, then fixes them in one pass |

Codex wrappers live in `codex-skills/` and map user-visible `/larv:*` style prompts to the relevant command or main workflow skill.

## Generated Artifacts

A larv-managed project typically gets:

```text
docs/larv/
  STATE.yaml
  00-discuss/
  01-domain/
  02-architecture/
  03-design/
  04-test-strategy/
  05-premortem/
  06-implementation/
  07-runtime/
  08-implementation/
  09-verification/
  10-deploy/
  security/
docs/Handsoff.md
docs/Handsoff/
docs/user-manual/
adr/
```

The most important implementation artifacts are:

- `docs/Handsoff.md`: the index another AI or developer should read first.
- `docs/Handsoff/bootstrap-sandbox.md`: self-contained sandbox bootstrap instructions.
- `docs/Handsoff/slice-NN-*.md`: one handoff file per implementation slice.
- `docs/Handsoff/package-guide.md`: package-specific implementation/test/env/deploy guidance.
- `docs/larv/implementation-tracker.yaml`: slice and status tracking.
- `docs/larv/STATE.yaml`: resumable workflow state.

## Design Galleries

`larv` includes local HTML design galleries used for Phase 3 mockups and redesign commands:

| Gallery | Use |
|---|---|
| `attio-finance-html-effectiveness-design/` | Financial services, lending, credit, payment, and risk workflows |
| `attio-venture-html-effectiveness/` | Attio Venture, B2B SaaS, venture, portfolio, advisory, and general CRM-style workflows |

The redesign commands use these galleries as concrete implementation references, not as decorative inspiration. When a production app is redesigned, the agent inventories the real screens, applies the selected design system, runs builds/tests, restarts the sandbox, and records visual parity evidence.

## Impeccable + Higgsfield design directions

`/larv:redesign-impeccable-higgsfield [page|role|workflow]` redesigns an existing Laravel app; Phase 3 offers the same round as design mode `impeccable-higgsfield`.

1. Impeccable (vendored skill 4.3.1) deals three grounded directions from `PRODUCT.md`.
2. Higgsfield renders one comp per direction with `nano_banana_pro` at 2k (about 2 credits each). Declined directions get no comp.
3. `scripts/design-directions.sh` renders the options board and serves it on a public 9000-9499 port (probe before announce). You pick with `pick: <id>` (a dealt direction or the category-standard `canon` card); `design-directions.sh stop` shuts the board down.
4. The pick becomes `DESIGN.md`; the redesign command then rebuilds every screen, Phase 3 builds one clickable prototype.

| Setting | Default |
|---|---|
| `LARV_HIGGSFIELD_CREDIT_CAP` | `10` credits per round; above it larv asks first |
| `LARV_HIGGSFIELD_MODEL` | `nano_banana_pro` |
| `LARV_VM_HOST` | public host for board URLs; falls back to `hostname -I` |

Setup: `/larv:design-setup` runs `scripts/design-setup.sh check|install`. It installs the SHA-256-pinned Higgsfield CLI 1.1.26 into `~/.local/share/larv/higgsfield/` and the Impeccable skill into `~/.claude/skills` and `~/.agents/skills`. Signing in is the one user step (`! ~/.local/share/larv/higgsfield/higgsfield auth login`); larv never runs `auth token`. Comps are generated only after `cost` has priced the round within the cap (or the user confirmed the spend). When Higgsfield is not installed, signed out, or the balance does not cover the round, the board uses zero-credit wireframe cards.

Privacy: only screenshots of seeded or fictional data may be sent to Higgsfield as reference images, and `directions/refs/FICTIONAL-DATA-CONFIRMED` must exist before one is used.

Works in Claude Code and Grok (both load larv's `.claude-plugin` commands and skills) and Codex (`codex-skills/`).

## Security

Before making a repository public, run:

```bash
bash scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/manual-security-scan.md"
```

The scanner is non-executing. It looks for:

- download-and-execute shell patterns
- base64 decode-to-shell patterns
- PHP webshell patterns
- request-controlled command execution
- PowerShell encoded commands
- reverse shell indicators
- cron/systemd persistence indicators
- hardcoded private keys and common cloud token shapes
- package install lifecycle hooks
- Composer/npm/pnpm/Yarn audit issues when lockfiles and tools exist

`larv` also ships guardrails that discourage committing secrets:

- Runtime secrets should live in environment variables or a secret manager.
- Generated production docs use placeholders, not secret values.
- `.gitignore` excludes common env files, keys, local runtime state, caches, nested repos, and logs.

## Development

Run the focused test suite:

```bash
bats tests/vm.bats \
  tests/runtime_gate.bats \
  tests/pre-flight.bats \
  tests/templates.bats \
  tests/commands.bats \
  tests/skills.bats \
  tests/readme.bats \
  tests/handsoff.bats
```

Run everything:

```bash
bats tests/
```

Check shell syntax:

```bash
bash -n scripts/*.sh scripts/lib/*.sh
```

Verify bundled references:

```bash
bash scripts/bundle-update.sh --verify
```

Refresh vendored bundles only when maintaining this plugin. Source paths are intentionally not hardcoded; pass them explicitly:

```bash
MASTERPLAN_COMMANDS_SOURCE=/path/to/masterplan/commands \
MASTERPLAN_SKILLS_SOURCE=/path/to/masterplan/skills \
SUPERPOWERS_LARAVEL_SOURCE=/path/to/superpowers-laravel \
DOMAIN_DRIVEN_DESIGN_SOURCE=/path/to/domain-driven-design \
bash scripts/bundle-update.sh --all
```

## Publishing Checklist

Before publishing:

1. Confirm `.codex-plugin/plugin.json` and `.claude-plugin/plugin.json` still point at the intended public repository URL, maintainer name, license, privacy policy, and terms.
2. Confirm the repository includes the MIT `LICENSE` file and that plugin metadata still declares `MIT`.
3. Run the security scanner.
4. Run the Bats test suite.
5. Confirm no local generated directories are staged: `.larv/`, `.superpowers/`, `.playwright-mcp/`, nested `.git/`, venvs, logs, or `.env` files.
6. Confirm bundled upstream sources remain redistributable and that removed/local-only bundles are not present.

## License

MIT. See [LICENSE](LICENSE).
