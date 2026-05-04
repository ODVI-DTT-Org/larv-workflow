---
name: masterplan-doc-governance
description: Use when running Phase 6 of MasterPlan — creating documentation governance system to prevent documentation drift, define ownership, establish update triggers, and define required templates
---

# Documentation Governance

## Overview

Design a documentation governance system that prevents drift. Documentation that is out of date is worse than no documentation at all.

**Core principle:** Docs are code. Treat documentation with the same rigor.

**Announce at start:** "I'm using the masterplan-doc-governance skill to create the documentation governance system."

## When to Use

**Use this skill:**
- After test strategy is complete
- Before deploying to production
- When documentation is inconsistent
- When onboarding new developers

**Do NOT use:**
- For single-person projects
- For temporary/experimental code
- When documentation is already well-governed

## The Process

### Step 1: Define Canonical Documentation Tree

Define the single source of truth for all documentation structure.

### Step 2: Define Documentation Ownership

Matrix of documentation areas with owners, responsibilities, and review cadence.

### Step 3: Define Update Triggers

What code changes require which documentation updates.

### Step 4: Define Required Templates

Feature spec, ADR, and runbook templates.

### Step 5: Define PR Documentation Checklist

Every PR must include specific documentation updates.

### Step 6: Define Monthly Drift Audit

Regular checks for documentation accuracy.

### Step 7: Define Documentation Metrics

Track documentation quality over time.

## Expected Output

This skill generates:
- **Document**: `docs/planning/06-doc-governance.md`
- **Format**: Markdown with templates and checklists
- **Size**: ~650 lines
- **Dependencies**: Requires `masterplan-test-strategy`

## Skill Dependencies

- **Prerequisites**: `masterplan-test-strategy` (Phase 5)
- **Required Inputs**: Project structure, team roles
- **Feeds Into**: `masterplan-adversarial-review`
- **Can Run Standalone**: No (requires project context)

## Completion & Next Steps

**After Doc Governance is complete:**

1. Display summary (auto-continue to Phase 7)
2. **Continue automatically** to Phase 7

**Next phase:** `/masterplan-adversarial-review`

## Remember

- **Docs are code** - Treat documentation with same rigor as code
- **Update as you go** - Don't let docs get stale
- **Review regularly** - Schedule quarterly reviews
- **Measure drift** - Track how often docs get out of date
- **Hold owners accountable** - Clear ownership means clear responsibility
