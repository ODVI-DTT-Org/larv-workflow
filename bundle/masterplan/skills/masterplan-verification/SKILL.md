---
name: masterplan-verification
description: Use when running Phase 9 of MasterPlan — creating final verification matrix for release readiness including functional, regression, migration, performance, security, documentation, observability, rollback, accessibility, and compliance verification
---

# Final Verification Matrix

## Overview

Generate a comprehensive verification matrix for release readiness. This is the final gate before production deployment.

**Core principle:** Evidence before assertions. Always verify, never assume.

**Announce at start:** "I'm using the masterplan-verification skill to create the final verification matrix."

## When to Use

**Use this skill:**
- After agent handoff is complete
- Before deployment to production
- When releasing new versions
- When sign-off is required

**Do NOT use:**
- For trivial changes
- When verification is already done
- For development environment changes

## The Process

### Step 1: Define Verification Matrix Columns

Requirement, Implemented In, Verification Method, Expected Result, Observed Result, Pass/Fail, Residual Risk, Verifier, Date.

### Step 2: Define Verification Categories

1. Functional Requirements
2. Non-Functional Requirements
3. Regression Tests
4. Migration Tests
5. Performance Tests
6. Security Checks
7. Documentation Checks
8. Observability Checks
9. Rollback Tests
10. Accessibility Checks
11. Cross-Browser/Cross-Device Tests
12. Backup & Recovery Tests
13. Compliance Checks

### Step 3: Define Release Criteria

This release can proceed if all criteria are met.

### Step 4: Define Sign-Off Requirements

Formal approval matrix with roles and dates.

## Expected Output

This skill generates:
- **Document**: `docs/planning/09-verification-matrix.md`
- **Format**: Markdown with verification tables
- **Size**: ~400 lines
- **Dependencies**: Requires all previous phases

## Skill Dependencies

- **Prerequisites**: All previous phases (0-8)
- **Required Inputs**: All planning and implementation documents
- **Feeds Into**: None (final phase)
- **Can Run Standalone**: No (requires full context)

## Final Completion

**After Final Verification is complete:**

Display:
```markdown
*** ALL PHASES COMPLETE ***

MasterPlan Workflow Complete!

Documents generated in docs/planning/:
✅ 00-pre-planning-summary.md
✅ 01-c4-architecture.md
✅ 02-master-design.md
✅ 03-bug-premortem.md
✅ 04-implementation-plan.md
✅ 05-test-strategy.md
✅ 06-doc-governance.md
✅ 07-adversarial-review.md
✅ 08-agent-handoff.md
✅ 09-verification-matrix.md

Next steps:
- Review all documents
- Address any blockers from adversarial review
- Begin implementation using agent handoff
- Use verification matrix for release readiness
```

## Remember

- **Be thorough** - Don't skip verification steps
- **Document everything** - Create a paper trail
- **Be honest** - Report failures accurately
- **Assess risks** - Understand residual risks
- **Get sign-offs** - Formal approval is important
- **Monitor closely** - Watch for issues after deployment
