# LEARNINGS

This file is the larv plugin's compounding self-knowledge. It is loaded by every `/larv:full` run during pre-flight so each project benefits from prior projects.

## How Entries Get Here

Slice and phase handoffs include a `## Plugin Improvement Notes` section. Notes prefixed `[plugin]` are generalizable; `[project]` notes remain project-specific. `/larv:learn` aggregates `[plugin]` notes and opens a PR with proposed edits.

## Sections

Entries are indexed by topic, not chronology. Add to the matching section.

## Library version notes

<!-- API drift, version-specific gotchas, and supported versions. -->

## Discuss-phase questions

<!-- Questions to add to Phase 0 based on missing-information incidents. -->

## Patterns promoted

<!-- Non-obvious approaches that worked cleanly and should become defaults. -->

## Failure modes prevented

<!-- Recurring failure modes and the guards added for them. -->

## Composition lessons

<!-- How upstream skills interact in practice. -->

## Maintenance

When this file approaches 500 lines, `/larv:learn` should propose a split into per-section files under `learnings/`.

## 2026-05-06 — Discipline rules from MVP design

[plugin] Three invariants hold all design choices together:

1. **Venue parity**: same-session, subagents, and foreign-AI all read the same handsoff. No special internal-only Phase 8 logic.
2. **Handsoff self-containment**: every action a foreign AI takes is inline bash inside the handsoff document. No `scripts/lib/*` references.
3. **Probe-before-announce**: no URL is printed until both inside-VM and outside curl confirm the service responds.

Bake these into every future skill prompt; they're easy to forget and load-bearing.

[project] When asking the user a question, always pair it with `Recommendation / Why / Tradeoffs`. Strong norm, not enforced — easy for skills to drift.
