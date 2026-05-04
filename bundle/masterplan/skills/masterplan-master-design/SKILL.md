---
name: masterplan-master-design
description: Use when running Phase 2 of MasterPlan — creating production-grade Master Design with comprehensive architecture, contracts, migration strategy, failure modes, observability, security, performance, cost, compliance, and rollout plans
---

# Master Design

## Overview

Create a production-grade Master Design document that serves as the single source of truth for implementation. This design addresses everything from architecture to compliance, from performance to disaster recovery.

**Core principle:** A complete design prevents implementation surprises.

**Announce at start:** "I'm using the masterplan-master-design skill to create the comprehensive design document."

## When to Use

**Use this skill:**
- After C4 architecture is complete
- Before creating implementation plans
- When architecture needs formal documentation
- Before major system changes
- When stakeholders require design approval

**Do NOT use:**
- For trivial features (single endpoint, small UI change)
- When design is already documented
- For emergency fixes

## The Process

### Step 1: Objectives and Non-Goals

Define clear, measurable goals and explicitly state what's NOT being addressed.

### Step 2: Current-State Architecture

Reference C4 Level 1-2 from Phase 1.

### Step 3: Target-State Architecture

Reference C4 Level 1-3 from Phase 1.

### Step 4: Invariants

Define what must NEVER break.

### Step 5: Data/API Contracts

Document before/after states.

### Step 6: Migration Strategy

Define the migration approach with rollback procedures.

### Step 7: Failure Modes and Mitigations

Document what could go wrong.

### Step 8: Observability Plan

Define how we'll know what's happening: logs, metrics, traces, alerts.

### Step 9: Security Checklist

Complete security review.

### Step 10: Performance Analysis

Define performance expectations.

### Step 11: Cost Analysis

Document total cost of ownership.

### Step 12: Compliance Requirements

Address legal/compliance needs.

### Step 13: Rollout Plan

Define the deployment strategy.

### Step 14: Backup & Disaster Recovery

Plan for worst case.

## Expected Output

This skill generates:
- **Document**: `docs/planning/02-master-design.md`
- **Format**: Markdown with tables and checklists
- **Size**: ~800 lines
- **Dependencies**: Requires `masterplan-discuss` and `masterplan-c4-architecture`

## Skill Dependencies

- **Prerequisites**: `masterplan-discuss` (Phase 0), `masterplan-c4-architecture` (Phase 1)
- **Required Inputs**: System context, C4 diagrams, requirements
- **Feeds Into**: `masterplan-bug-premortem`
- **Can Run Standalone**: No (requires Phases 0-1)

## Completion & Next Steps

**After Master Design is complete:**

1. Display summary to the user
2. Show options: continue / revise section / restart
3. **WAIT for user input**

**Next phase:** `/masterplan-bug-premortem`

## Remember

- **Be specific** - Vague designs lead to implementation confusion
- **Think about failures** - Assume everything will fail
- **Plan for operations** - Design for operability from day one
- **Consider cost** - Make cost-conscious decisions
- **Document everything** - If it's not written down, it doesn't exist
