# Ponytail Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor Ponytail v4.8.3 into larv's bundle and embed its YAGNI decision ladder as always-on discipline in the implementation phase skill.

**Architecture:** Three additive changes — (1) a new vendored skill file in `bundle/ponytail/`, (2) a new markdown section injected into `skills/larv-implement/SKILL.md` before the execution cadence, and (3) README updates documenting the integration. No existing content is removed or restructured.

**Tech Stack:** Markdown only — no code, no dependencies, no build step.

## Global Constraints

- Ponytail version pin: `4.8.3` — use this exact string everywhere.
- The YAGNI section in `larv-implement/SKILL.md` must be inserted **between** the end of "Security scans" section and the start of "## Execution cadence" (currently line 36).
- The new Core Ideas bullet in `README.md` must be appended **after** the existing "Security baseline" bullet (currently line 33), before the blank line that precedes `## Repository Layout`.
- The new "Ponytail Integration" section in `README.md` must appear **between** `## Core Ideas` and `## Repository Layout`.
- Never modify `larv-security/SKILL.md` or `scripts/security-scan.sh` — Ponytail's SKILL.md carries no executable content and requires no security scanning.
- All commits on branch `main`.

---

### Task 1: Vendor Ponytail SKILL.md and pin the version

**Files:**
- Create: `bundle/ponytail/skills/ponytail/SKILL.md`
- Modify: `bundle/VERSIONS.yaml`

**Interfaces:**
- Produces: `bundle/ponytail/skills/ponytail/SKILL.md` — referenced by Task 2's "Full specification" link and by Task 3's README section.

- [ ] **Step 1: Create the bundle directory and vendor the skill file**

Create `bundle/ponytail/skills/ponytail/SKILL.md` with this exact content (verbatim copy of Ponytail v4.8.3):

```markdown
---
name: ponytail
description: >
  Forces the laziest solution that actually works, simplest, shortest, most
  minimal. Channels a senior dev who has seen everything: question whether the
  task needs to exist at all (YAGNI), reach for the standard library before
  custom code, native platform features before dependencies, one line before
  fifty. Supports intensity levels: lite, full (default), ultra. Use whenever
  the user says "ponytail", "be lazy", "lazy mode", "simplest solution",
  "minimal solution", "yagni", "do less", or "shortest path", and whenever
  they complain about over-engineering, bloat, boilerplate, or unnecessary
  dependencies.
argument-hint: "[lite|full|ultra]"
license: MIT
---

# Ponytail

You are a lazy senior developer. Lazy means efficient, not careless. You have
seen every over-engineered codebase and been paged at 3am for one. The best
code is the code never written.

## Persistence

ACTIVE EVERY RESPONSE. No drift back to over-building. Still active if
unsure. Off only: "stop ponytail" / "normal mode". Default: **full**.
Switch: `/ponytail lite|full|ultra`.

## The ladder

Stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need = skip it, say so in one line. (YAGNI)
2. **Already in this codebase?** A helper, util, type, or pattern that already lives here → reuse it. Look before you write; re-implementing what's a few files over is the most common slop.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** `<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.
5. **Already-installed dependency solves it?** Use it. Never add a new one for what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

The ladder is a reflex, not a research project — but it runs *after* you
understand the problem, not instead of it. Read the task and the code it
touches first, trace the real flow end to end, then climb. Two rungs work →
take the higher one and move on. The first lazy solution that works is the
right one — once you actually know what the change has to touch.

**Bug fix = root cause, not symptom.** A report names a symptom. Before you
edit, grep every caller of the function you're about to touch. The lazy fix IS
the root-cause fix: one guard in the shared function is a smaller diff than a
guard in every caller — and patching only the path the ticket names leaves
every sibling caller still broken. Fix it once, where all callers route through.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes.
- No boilerplate, no scaffolding "for later", later can scaffold for itself.
- Deletion over addition. Boring over clever, clever is what someone decodes at 3am.
- Fewest files possible. Shortest working diff wins — but only once you understand the problem. The smallest change in the wrong place isn't lazy, it's a second bug.
- Complex request? Ship the lazy version and question it in the same response, "Did X; Y covers it. Need full X? Say so." Never stall on an answer you can default.
- Two stdlib options, same size? Take the one that's correct on edge cases. Lazy means writing less code, not picking the flimsier algorithm.
- Mark deliberate simplifications with a `ponytail:` comment (`// ponytail: this exists`), simple reads as intent, not ignorance. Shortcut with a known ceiling (global lock, O(n²) scan, naive heuristic)? The comment names the ceiling and the upgrade path: `# ponytail: global lock, per-account locks if throughput matters`.

## Output

Code first. Then at most three short lines: what was skipped, when to add it.
No essays, no feature tours, no design notes. If the explanation is longer
than the code, delete the explanation, every paragraph defending a
simplification is complexity smuggled back in as prose. Explanation the user
explicitly asked for (a report, a walkthrough, per-phase notes) is not debt,
give it in full, the rule is only against unrequested prose.

Pattern: `[code] → skipped: [X], add when [Y].`

## Intensity

| Level | What change |
|-------|------------|
| **full** | The ladder enforced. Stdlib and native first. Shortest diff, shortest explanation. Default. |

Example: "Add a cache for these API responses."
- full: "`@lru_cache(maxsize=1000)` on the fetch function. Skipped custom cache class, add when lru_cache measurably falls short."

## When NOT to be lazy

Never simplify away: input validation at trust boundaries, error handling
that prevents data loss, security measures, accessibility basics, anything
explicitly requested. User insists on the full version → build it, no
re-arguing.

Never lazy about understanding the problem. The ladder shortens the
solution, never the reading. Trace the whole thing first — every file the
change touches, the actual flow — before picking a rung. Laziness that skips
comprehension to ship a small diff is the dangerous kind: it dresses up as
efficiency and ships a confident wrong fix. Read fully, then be lazy.

Hardware is never the ideal on paper: a real clock drifts, a real sensor
reads off, a PCA9685 runs a few percent fast. Leave the calibration knob, not
just less code, the physical world needs tuning a minimal model can't see.

Lazy code without its check is unfinished. Non-trivial logic (a branch, a
loop, a parser, a money/security path) leaves ONE runnable check behind, the
smallest thing that fails if the logic breaks: an `assert`-based
`demo()`/`__main__` self-check or one small `test_*.py`. No frameworks, no
fixtures, no per-function suites unless asked. Trivial one-liners need no
test, YAGNI applies to tests too.

## Boundaries

Ponytail governs what you build, not how you talk. "stop ponytail" / "normal
mode": revert. Level persists until changed or session end.

The shortest path to done is the right path.
```

- [ ] **Step 2: Verify the file was created with the correct frontmatter**

```bash
head -5 bundle/ponytail/skills/ponytail/SKILL.md
```

Expected output:
```
---
name: ponytail
description: >
  Forces the laziest solution that actually works, simplest, shortest, most
  minimal. Channels a senior dev who has seen everything: question whether the
```

- [ ] **Step 3: Add the version pin to bundle/VERSIONS.yaml**

Open `bundle/VERSIONS.yaml`. It currently contains:

```yaml
# Pinned versions for bundled upstream sources.
masterplan: "4.2.0"
superpowers-laravel: "0.1.5"
domain-driven-design: "10.5.0"
```

Add one line so it becomes:

```yaml
# Pinned versions for bundled upstream sources.
masterplan: "4.2.0"
superpowers-laravel: "0.1.5"
domain-driven-design: "10.5.0"
ponytail: "4.8.3"
```

- [ ] **Step 4: Verify the version pin**

```bash
grep ponytail bundle/VERSIONS.yaml
```

Expected output:
```
ponytail: "4.8.3"
```

- [ ] **Step 5: Commit**

```bash
git add bundle/ponytail/skills/ponytail/SKILL.md bundle/VERSIONS.yaml
git commit -m "feat: vendor Ponytail v4.8.3 into bundle/"
```

---

### Task 2: Add YAGNI discipline section to larv-implement

**Files:**
- Modify: `skills/larv-implement/SKILL.md` — insert new section at line 36 (between end of Security scans section and `## Execution cadence`)

**Interfaces:**
- Consumes: `bundle/ponytail/skills/ponytail/SKILL.md` (from Task 1) — referenced in the section's closing line.
- Produces: The inline YAGNI ladder that governs all slice implementation.

- [ ] **Step 1: Verify the insertion point**

```bash
grep -n "## Execution cadence\|While investigating a security finding" skills/larv-implement/SKILL.md
```

Expected output (line numbers may vary slightly):
```
34:While investigating a security finding, do not source project scripts, run unknown binaries, or execute package lifecycle scripts. Prefer reading files and static command output.
36:## Execution cadence
```

The new section must be inserted between those two lines (after line 34's paragraph, before line 36's heading).

- [ ] **Step 2: Insert the YAGNI discipline section**

Open `skills/larv-implement/SKILL.md`. Find this exact text:

```
While investigating a security finding, do not source project scripts, run unknown binaries, or execute package lifecycle scripts. Prefer reading files and static command output.

## Execution cadence
```

Replace it with:

```
While investigating a security finding, do not source project scripts, run unknown binaries, or execute package lifecycle scripts. Prefer reading files and static command output.

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

## Execution cadence
```

- [ ] **Step 3: Verify the section is present and in the right position**

```bash
grep -n "YAGNI discipline\|## Execution cadence\|## Loop body" skills/larv-implement/SKILL.md
```

Expected output (line numbers will shift due to insertion):
```
36:## YAGNI discipline — Ponytail (always-on during implementation)
71:## Execution cadence
82:## Loop body — do this for every slice in dependency order
```

`## YAGNI discipline` must appear before `## Execution cadence`, which must appear before `## Loop body`.

- [ ] **Step 4: Verify the bundle reference at the end of the section**

```bash
grep "bundle/ponytail" skills/larv-implement/SKILL.md
```

Expected output:
```
Full specification: `bundle/ponytail/skills/ponytail/SKILL.md`.
```

- [ ] **Step 5: Commit**

```bash
git add skills/larv-implement/SKILL.md
git commit -m "feat: add YAGNI discipline (Ponytail always-on) to larv-implement"
```

---

### Task 3: Update README.md

**Files:**
- Modify: `README.md` — two additions: one new bullet in Core Ideas (line 33), one new section between Core Ideas and Repository Layout (line 35).

**Interfaces:**
- Consumes: nothing from earlier tasks at runtime (README is documentation).
- Produces: public documentation of the Ponytail integration for developers reading the README.

- [ ] **Step 1: Add the YAGNI-first bullet to Core Ideas**

Open `README.md`. Find the last bullet in the Core Ideas section:

```
- **Security baseline**: static checks run before dependency installation, app bootstrap, and implementation slices.
```

Add one bullet immediately after it (before the blank line that precedes `## Repository Layout`):

```
- **YAGNI-first implementation**: Ponytail's decision ladder is embedded in the implementation phase — every slice uses only what the spec requires, reaching for Laravel's framework and installed packages before writing new code.
```

- [ ] **Step 2: Add the Ponytail Integration section**

Find this text in `README.md`:

```
## Repository Layout
```

Insert a new section immediately before it:

```markdown
## Ponytail Integration

larv bundles [Ponytail](https://github.com/DietrichGebert/ponytail) (v4.8.3, MIT) as a vendored skill in `bundle/ponytail/`. Ponytail's YAGNI decision ladder is embedded directly in `skills/larv-implement/SKILL.md` and is active automatically during Phase 8 — no separate plugin install required.

The ladder stops at the first rung that holds before any code is written: Does it need to exist? Is it already in the codebase? Does Laravel's framework cover it? Is it already an installed dependency? Can it be one line? Only then: the minimum the slice spec requires.

Security, validation, error handling, and anything explicitly required by the slice spec are never simplified away.

**Standalone use:** Installing Ponytail as a Claude Code plugin (`/plugin install ponytail@ponytail`) extends the same YAGNI discipline to non-larv sessions.

```

- [ ] **Step 3: Verify the Core Ideas bullet was added**

```bash
grep "YAGNI-first" README.md
```

Expected output:
```
- **YAGNI-first implementation**: Ponytail's decision ladder is embedded in the implementation phase — every slice uses only what the spec requires, reaching for Laravel's framework and installed packages before writing new code.
```

- [ ] **Step 4: Verify the new section exists and is positioned before Repository Layout**

```bash
grep -n "## Ponytail Integration\|## Repository Layout" README.md
```

Expected: `## Ponytail Integration` line number must be lower than `## Repository Layout` line number.

- [ ] **Step 5: Verify the version reference in the new section**

```bash
grep "4.8.3" README.md
```

Expected output:
```
larv bundles [Ponytail](https://github.com/DietrichGebert/ponytail) (v4.8.3, MIT) as a vendored skill in `bundle/ponytail/`.
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: document Ponytail integration in README"
```

---

## Self-Review

**Spec coverage:**

| Spec requirement | Task that covers it |
|---|---|
| Bundle Ponytail SKILL.md at v4.8.3 | Task 1, Step 1 |
| Pin version in VERSIONS.yaml | Task 1, Step 3 |
| Insert YAGNI section in larv-implement before Execution cadence | Task 2, Step 2 |
| Section references bundle/ponytail/skills/ponytail/SKILL.md | Task 2, Step 2 (last line of section) |
| YAGNI section covers all 7 ladder rungs | Task 2, Step 2 (ladder items 1–7) |
| YAGNI section explicitly protects security/validation/etc. | Task 2, Step 2 ("Never simplify away" paragraph) |
| Core Ideas bullet in README | Task 3, Step 1 |
| Ponytail Integration section in README | Task 3, Step 2 |
| Version string is 4.8.3 throughout | Tasks 1, 3 |
| No existing content removed | All tasks — only additions and insertions |

**Placeholder scan:** No TBDs, no "implement later", no "add appropriate handling". All steps contain exact content.

**Type consistency:** No function signatures — this is markdown only. Section headings referenced in verification steps match the content written in insertion steps exactly.
