---
name: masterplan-full
description: Use when running the complete MasterPlan workflow from requirements through verification — runs all 9 phases with interactive pause points at phases 0, 1, 2, and 7. Also handles --fast, --phases, --resume-from, and --resume options.
---

# MasterPlan: Full Planning Workflow

## Overview

The complete MasterPlan workflow for creating production-ready Master Design and Implementation Plan documents. Run all 9 phases with interactive pauses at critical decision points.

**Core principle:** Good planning prevents implementation surprises.

**Announce at start:** "I'm using the masterplan-full skill to run the complete planning workflow."

## When to Use

**Use this skill:**
- Starting any new project or major feature
- When comprehensive planning is required
- When stakeholder approval is needed
- When creating production-ready designs

**Do NOT use:**
- For trivial changes (single bug fix, small refactor)
- When planning is already complete
- For emergency fixes

## The Workflow

| Phase | Name | Output | Pause for Review? |
|-------|------|--------|-------------------|
| 0 | Pre-Planning Discussion | `docs/planning/00-pre-planning-summary.md` | ✅ Yes |
| 1 | C4 Architecture | `docs/planning/01-c4-architecture.md` | ✅ Yes |
| 2 | Master Design | `docs/planning/02-master-design.md` | ✅ Yes |
| 3 | Bug Pre-Mortem | `docs/planning/03-bug-premortem.md` | No |
| 4 | Implementation Plan | `docs/planning/04-implementation-plan.md` | No |
| 5 | Test Strategy | `docs/planning/05-test-strategy.md` | No |
| 6 | Documentation Governance | `docs/planning/06-doc-governance.md` | No |
| 7 | Adversarial Review | `docs/planning/07-adversarial-review.md` | ✅ Yes |
| 8 | Agent Handoff | `docs/planning/08-agent-handoff.md` | No |
| 9 | Final Verification | `docs/planning/09-verification-matrix.md` | No |

## Options

| Option | Behavior |
|--------|----------|
| (default) | Interactive mode — pause at phases 0, 1, 2, 7 |
| `--fast` | Run all phases without pausing |
| `--phases 0,1,2` | Run only specified phases (comma-separated) |
| `--resume-from 5` | Resume from phase 5 onward |
| `--resume` | Resume from last incomplete phase |

## AI Execution Instructions

### At Start
1. Announce: "I'm using the masterplan-full skill to run the complete planning workflow."
2. Display the workflow table above
3. Parse any command-line options
4. Say: "Let's start with Phase 0: Pre-Planning Discussion."

### For Pause Phases (0, 1, 2, 7)

1. **Generate the output** using the phase-specific skill
2. **Display a summary** of what was generated (3-5 bullet points)
3. **Show these exact options**:
   ```
   *** PHASE [N] COMPLETE ***

   Review complete. Options:
   - "continue" or "next" - Proceed to next phase
   - "revise [section]" - Make changes to current output
   - "revise all" - Re-generate current phase
   - "skip [phase]" - Skip next phase (use caution)
   - "status" - Show workflow progress
   - "quit" - Save and exit (resume with --resume flag)
   ```
4. **Wait for user input** before proceeding

### For Auto-Continue Phases (3, 4, 5, 6, 8, 9)

1. Generate the output using the phase-specific skill
2. Display brief summary (1-2 sentences)
3. Automatically continue to next phase
4. Say: "*** Phase [N] complete. Continuing to Phase [N+1]... ***"

### At Final Completion

Display the completion summary with all generated documents listed.

## Resuming Workflow

If user quits and resumes:
1. Check for existing documents in `docs/planning/`
2. Identify which phases are complete
3. Resume from the first incomplete phase
4. Display: "Resuming from Phase [N]..."

## Expected Output

This skill generates all 10 planning documents in `docs/planning/`:
- `00-pre-planning-summary.md`
- `01-c4-architecture.md`
- `02-master-design.md`
- `03-bug-premortem.md`
- `04-implementation-plan.md`
- `05-test-strategy.md`
- `06-doc-governance.md`
- `07-adversarial-review.md`
- `08-agent-handoff.md`
- `09-verification-matrix.md`

## Remember

- **Be thorough in Phase 0** - Good input = good output
- **Review each C4 diagram** - Visuals reveal architectural issues
- **Don't skip Adversarial Review** - It catches critical gaps
- **Update as you go** - If requirements change, re-run earlier phases
- **Keep docs in sync** - Use the governance system from Phase 6
- **Save progress** - You can always resume later
