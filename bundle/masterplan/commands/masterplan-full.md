---
description: Run all 9 MasterPlan phases automatically with pause points at phases 0, 1, 2, and 7. Options: --fast (no pauses), --phases 0,1,2 (specific phases), --resume-from 5 (resume from phase), --resume (resume from last incomplete phase).
argument-hint: [--fast] [--phases 0-9] [--resume-from N] [--resume]
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit, Agent, WebFetch]
---

# MasterPlan: Full Workflow

## Overview

This command runs all 9 MasterPlan phases automatically. The full skill is active — follow its instructions.

**Pause phases (interactive mode):** 0, 1, 2, 7
**Auto-continue phases:** 3, 4, 5, 6, 8, 9

## Options

| Option | Description |
|--------|-------------|
| (none) | Interactive mode — pause at phases 0, 1, 2, 7 |
| `--fast` | Run all phases without pausing |
| `--phases 0,1,2` | Run only specific phases |
| `--resume-from 5` | Resume from phase 5 |
| `--resume` | Resume from last incomplete phase |

## Workflow Table

| Phase | Name | Output | Pause? |
|-------|------|--------|--------|
| 0 | Pre-Planning Discussion | `docs/planning/00-pre-planning-summary.md` | ✅ |
| 1 | C4 Architecture | `docs/planning/01-c4-architecture.md` | ✅ |
| 2 | Master Design | `docs/planning/02-master-design.md` | ✅ |
| 3 | Bug Pre-Mortem | `docs/planning/03-bug-premortem.md` | No |
| 4 | Implementation Plan | `docs/planning/04-implementation-plan.md` | No |
| 5 | Test Strategy | `docs/planning/05-test-strategy.md` | No |
| 6 | Doc Governance | `docs/planning/06-doc-governance.md` | No |
| 7 | Adversarial Review | `docs/planning/07-adversarial-review.md` | ✅ |
| 8 | Agent Handoff | `docs/planning/08-agent-handoff.md` | No |
| 9 | Final Verification | `docs/planning/09-verification-matrix.md` | No |

## Next Steps

Invoke the **masterplan-full** skill to execute this workflow:
