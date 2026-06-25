# Ponytail Integration Design

**Date:** 2026-06-25
**Status:** Approved — pending implementation
**Scope:** larv plugin repository (`kaito/workflow`)

---

## Overview

Integrate [Ponytail v4.8.3](https://github.com/DietrichGebert/ponytail) into the larv Laravel workflow plugin. Ponytail enforces YAGNI discipline on AI agents — it makes the agent stop at the simplest solution that actually works before writing code. The integration makes this discipline always-on during larv's Phase 8 implementation without requiring a separate plugin install or manual invocation.

Ponytail passed a full security audit (see §Security Audit below). The integration is additive: no existing larv behavior is removed or weakened.

---

## Goals

- Automatically apply Ponytail's YAGNI ladder during every implementation slice.
- Vendor a version-pinned copy of Ponytail's skill in `bundle/` alongside existing bundled skills.
- Document the integration in the README so developers understand the discipline is active.
- Support the standalone plugin path: developers who also install Ponytail as a Claude Code plugin get consistent behavior in and outside larv sessions.

---

## Security Audit — PASSED

Audit performed against commit `main` at v4.8.3 (2026-06-25).

| Check | Result |
|---|---|
| Network calls in hooks | None |
| Dynamic code execution (`eval`, `Function()`) | None |
| Shell injection surface | Mitigated — `isShellSafe()` uses allowlist regex before path embedding |
| Input validation (UserPromptSubmit hook) | All mode values checked against `VALID_MODES` hardcoded array before write |
| File writes | Only `~/.claude/.ponytail-active` (mode flag) and `~/.config/ponytail/config.json` |
| Runtime npm dependencies | None — only Node.js built-ins (`fs`, `path`, `os`) |
| Skill content injection | Plain markdown instructions only — no executable content |
| Supply chain risk | Minimal — zero transitive dependencies |

The `SKILL.md` content explicitly states security must never be simplified away.

---

## What Changes

Four files are touched. No existing larv skills, scripts, templates, or tests are removed.

### 1. `bundle/ponytail/skills/ponytail/SKILL.md` — NEW

Verbatim copy of Ponytail's `skills/ponytail/SKILL.md` at v4.8.3. Serves as:
- Version-pinned snapshot for reproducibility across handoff tools.
- Reference the agent can read when it needs the full specification.
- Update target when larv bumps the Ponytail version pin.

### 2. `bundle/VERSIONS.yaml` — UPDATE

Add one line:

```yaml
ponytail: "4.8.3"
```

Update cadence mirrors existing pins (`superpowers-laravel`, `masterplan`, `domain-driven-design`): manual bump with a CHANGELOG entry.

### 3. `skills/larv-implement/SKILL.md` — UPDATE

Insert a new section **between** "Security scans — mandatory around implementation" and "Execution cadence". Position is deliberate: the discipline is declared before the loop body so it governs every step within the loop.

Section content:

```markdown
## YAGNI discipline — Ponytail (always-on during implementation)

Before writing any code for a slice, stop at the first rung of this ladder
that holds. The ladder runs after you understand the problem — read the
slice spec and trace the real flow first, then climb.

1. **Does this need to exist at all?** The slice handsoff defines scope.
   If the handsoff does not require it, skip it.
2. **Already in this codebase?** Reuse the shared helper, trait, or
   pattern — do not re-implement what is a few files over.
3. **Laravel / PHP stdlib does it?** Eloquent relationships, collections,
   validation rules, middleware, jobs, events, policies — use the framework.
4. **Native Laravel feature covers it?** A DB constraint beats app-code
   validation. A route middleware beats per-controller logic. An attribute
   cast beats a mutator.
5. **Already-installed dependency solves it?** If Filament, Cashier,
   Sanctum, Horizon, or another installed package provides it, use it.
   Never add a new package for what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code the slice spec requires.

Rules:
- No abstractions not required by the slice spec.
- No boilerplate "for later" — the next slice scaffolds for itself.
- Deletion over addition when the slice requires a refactor.
- Mark deliberate simplifications: `// ponytail: <trade-off and upgrade path>`.
- Bug fix = root cause, not symptom. Grep every caller of the function
  you touch and fix it once at the shared path.

Never simplify away: input validation at trust boundaries, security measures,
error handling that prevents data loss, accessibility basics, or anything the
slice spec explicitly requires.

Full specification: `bundle/ponytail/skills/ponytail/SKILL.md`.
```

### 4. `README.md` — UPDATE

Two additions:

**In the "Core Ideas" bullet list**, add:

> `**YAGNI-first implementation**: Ponytail's decision ladder is embedded in the implementation phase — every slice uses only what the spec requires, reaching for Laravel's framework and installed packages before writing new code.`

**New "Ponytail Integration" section** (after "Core Ideas", before "Repository Layout"):

> Documents the bundled version (v4.8.3), activation model (always-on in Phase 8, no separate install required), and notes that installing Ponytail as a standalone Claude Code plugin (`/plugin install ponytail@ponytail`) extends the same YAGNI discipline to non-larv sessions.

---

## Architecture

```
larv-orchestrator (Phase 8 dispatch)
    └── larv-implement/SKILL.md
            ├── Security scan (pre-slice)          [existing]
            ├── YAGNI discipline — Ponytail        [NEW — inline ladder + rules]
            ├── Execution cadence                  [existing]
            └── Loop body → post-slice scan        [existing]

bundle/
    ├── superpowers-laravel/     [existing]
    ├── masterplan/              [existing]
    ├── domain-driven-design/    [existing]
    └── ponytail/                [NEW]
        └── skills/ponytail/SKILL.md  (v4.8.3)
```

The YAGNI section is inline in `larv-implement/SKILL.md` rather than a required file read. This guarantees coverage across all execution paths: direct Phase 8, subagent dispatch, and external handoff tools that call `larv-implement` directly without going through the orchestrator.

---

## What This Does Not Change

- No existing larv skills, scripts, templates, hooks, tests, or commands are removed.
- The security scan cadence (pre/post every slice) is unchanged.
- The handoff document format is unchanged.
- The Ponytail plugin's own lifecycle hooks (`ponytail-activate.js`, etc.) are **not** included in larv. Only the SKILL.md instruction content is vendored. larv does not install or execute Ponytail's Node.js hooks.
- Ponytail's "off" / "lite" / "ultra" mode switches are not supported within larv. The larv integration is always "full" mode — equivalent to Ponytail's default.

---

## Version Upgrade Path

When a new Ponytail version is released:

1. Review the diff between the new `skills/ponytail/SKILL.md` and the bundled copy.
2. Update `bundle/ponytail/skills/ponytail/SKILL.md` with the new content.
3. Update `bundle/VERSIONS.yaml` to the new version string.
4. Check whether the inline ladder section in `larv-implement/SKILL.md` needs syncing (the ladder is stable; the intensity table and worked examples in SKILL.md are filtered out by Ponytail's own runtime — not relevant here).
5. Add a CHANGELOG entry.

---

## Out of Scope

- Installing or bundling Ponytail's Node.js lifecycle hooks inside larv.
- Supporting Ponytail intensity mode switching (`lite` / `ultra`) within larv sessions.
- Automated version upgrade tooling (manual bump is consistent with how larv manages other pins).
- Modifying `larv-security/SKILL.md` or `scripts/security-scan.sh` to scan Ponytail (it carries no executable code in the SKILL.md, so there is nothing to scan).
