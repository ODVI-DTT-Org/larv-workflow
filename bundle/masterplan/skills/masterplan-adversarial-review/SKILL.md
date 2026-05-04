---
name: masterplan-adversarial-review
description: Use when running Phase 7 of MasterPlan — hostile review of plans to find ambiguities, assumptions, gaps, single points of failure, cost issues, security blind spots, and developer experience problems
---

# Adversarial Plan Review

## Overview

Act as a hostile reviewer. Try to break this plan. Find weaknesses before they become problems. Be ruthless — this is the last line of defense before implementation.

**Core principle:** Think like an enemy. What would cause this to fail spectacularly?

**Announce at start:** "I'm using the masterplan-adversarial-review skill to find weaknesses in the plan."

## When to Use

**Use this skill:**
- After documentation governance is complete
- Before implementation begins
- Before approving plans
- When risk assessment is critical

**Do NOT use:**
- For trivial changes
- When you lack context to review
- For already-approved plans

## The Process

### Step 1: Find Ambiguities

Statements that could be interpreted multiple ways.

### Step 2: Find Hidden Assumptions

Unstated assumptions that could fail.

### Step 3: Find Missing Acceptance Criteria

Requirements without clear success definitions.

### Step 4: Find Missing Tests

Code/behaviors without test coverage.

### Step 5: Find Rollback Weaknesses

Rollback scenarios that won't work.

### Step 6: Find Migration Risks

Dangerous migration scenarios.

### Step 7: Find Security Blind Spots

Unaddressed security concerns.

### Step 8: Find Single Points of Failure

Components that, if they fail, bring down the system.

### Step 9: Find Performance Bottlenecks

Components that could limit performance.

### Step 10: Find Cost Issues

Areas where costs could spiral.

### Step 11: Find Developer Experience Issues

Things that will make development painful.

## Output Format

### Blockers (Must Fix Before Proceeding)
Issues that will cause failure or significant problems.

### Major Risks (Should Address)
Issues that could cause problems.

### Minor Issues (Nice to Address)
Issues that could cause confusion or delays.

## Expected Output

This skill generates:
- **Document**: `docs/planning/07-adversarial-review.md`
- **Format**: Markdown with findings tables
- **Size**: ~500 lines
- **Dependencies**: Requires all previous phases

## Skill Dependencies

- **Prerequisites**: All previous phases (0-6)
- **Required Inputs**: All planning documents
- **Feeds Into**: `masterplan-handoff`
- **Can Run Standalone**: No (requires full context)

## Completion & Next Steps

**After Adversarial Review is complete:**

1. Display summary to the user with blockers listed
2. Show options: continue / address blockers
3. **WAIT for user input** if blockers exist, otherwise continue

**Next phase:** `/masterplan-handoff`

## Remember

- **Be ruthless** - Nice reviews don't prevent problems
- **Be specific** - Vague feedback isn't actionable
- **Be thorough** - Check every category
- **Think negative** - Assume everything will fail
- **Document clearly** - Every issue needs a fix
- **Prioritize impact** - Fix what matters most
