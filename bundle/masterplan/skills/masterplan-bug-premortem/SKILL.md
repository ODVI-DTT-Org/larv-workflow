---
name: masterplan-bug-premortem
description: Use when running Phase 3 of MasterPlan — identifying potential bug classes, race conditions, idempotency hazards, migration risks, and failure modes before implementation begins
---

# Bug Pre-Mortem

## Overview

Assume the project shipped with persistent bugs. Run a pre-mortem to prevent that outcome. This is your chance to find problems before they exist.

**Core principle:** Think negatively. What could go wrong will go wrong.

**Announce at start:** "I'm using the masterplan-bug-premortem skill to identify potential bug classes."

## When to Use

**Use this skill:**
- After Master Design is complete
- Before creating implementation plans
- When system reliability is critical
- When failure is expensive

**Do NOT use:**
- For trivial changes
- When bug classes are already documented
- For prototype/experimental code

## The Process

### Step 1: Identify Bug Classes

For each bug class, document:
- Surface Area (Frontend, Backend, Database, Sync/Integration, Configuration, Data, Concurrency, Pagination)
- Likely Root Cause
- Prevention Guardrail
- Mandatory Test
- Runtime Signal
- Recovery Playbook

### Step 2: Create Matrices

**Race Condition Matrix:**
Document all potential race conditions with prevention and tests.

**Idempotency Matrix:**
Document which operations are idempotent and strategies for those that aren't.

**Migration Hazard Matrix:**
Document migration steps with hazards, impacts, mitigations, and rollbacks.

### Step 3: Define Release Gates

"Cannot Ship Unless" checklist covering bug prevention, testing, monitoring, and recovery.

### Step 4: Document Edge Cases

Document boundary cases, data edge cases, time edge cases, and concurrency edge cases.

## Expected Output

This skill generates:
- **Document**: `docs/planning/03-bug-premortem.md`
- **Format**: Markdown with comprehensive tables
- **Size**: ~600 lines
- **Dependencies**: Requires `masterplan-master-design`

## Skill Dependencies

- **Prerequisites**: `masterplan-master-design` (Phase 2)
- **Required Inputs**: System architecture, data flows, integration points
- **Feeds Into**: `masterplan-implementation`
- **Can Run Standalone**: No (requires design context)

## Completion & Next Steps

**After Bug Pre-Mortem is complete:**

1. Display summary (auto-continue to Phase 4)
2. **Continue automatically** to Phase 4

**Next phase:** `/masterplan-implementation`

## Remember

- **Think negatively** - Assume everything will fail
- **Be paranoid** - What could go wrong will go wrong
- **Document everything** - If it's not written down, it will be forgotten
- **Test the failures** - Don't just test success cases
- **Plan for recovery** - Everyone fails, not everyone recovers well
