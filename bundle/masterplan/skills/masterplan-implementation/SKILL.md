---
name: masterplan-implementation
description: Use when running Phase 4 of MasterPlan — creating agent-executable implementation plans with tasks, dependencies, verification gates, rollback procedures, feature flags, and code review checkpoints
---

# Implementation Plan

## Overview

Convert the Master Design into an implementation plan optimized for coding-agent execution. This plan must be unambiguous, verifiable, and reversible.

**Core principle:** A task without verification is not complete.

**Announce at start:** "I'm using the masterplan-implementation skill to create the implementation plan."

## When to Use

**Use this skill:**
- After bug pre-mortem is complete
- Before any code is written
- When handing off to developers or agents
- When creating sprint tasks

**Do NOT use:**
- For already-written code
- For trivial one-line changes
- When design is not yet complete

## The Process

### Step 1: Create Task Format

For EACH task, include:
- **Why**: Why this task exists
- **Files**: Exact files likely touched
- **Preconditions**: What must be true before starting
- **Steps**: Step-by-step instructions
- **Verification**: Commands/tests to verify
- **Expected Output**: What success looks like
- **Rollback**: How to revert if something goes wrong
- **Docs**: Documentation to update
- **Estimated Time**: Time estimate
- **Dependencies**: Tasks that must complete first

### Step 2: Create Dependency Graph

Show which tasks depend on which using Mermaid.

### Step 3: Define Stop Points

Natural checkpoints where human review is required.

### Step 4: Define Phase Gates

Each phase MUST NOT continue unless verification passes.

### Step 5: Define Code Review Checkpoints

Built-in review points within phases.

### Step 6: Define Feature Flags

Document feature flags with rollout and removal plans.

### Step 7: Define Final Hardening Phase

Comprehensive verification: code quality, testing, security, performance, documentation.

## Expected Output

This skill generates:
- **Document**: `docs/planning/04-implementation-plan.md`
- **Format**: Markdown with task tables and Mermaid diagrams
- **Size**: ~700 lines
- **Dependencies**: Requires `masterplan-bug-premortem`

## Skill Dependencies

- **Prerequisites**: `masterplan-bug-premortem` (Phase 3)
- **Required Inputs**: Bug analysis, architecture, requirements
- **Feeds Into**: `masterplan-test-strategy`
- **Can Run Standalone**: No (requires previous phases)

## Completion & Next Steps

**After Implementation Plan is complete:**

1. Display summary (auto-continue to Phase 5)
2. **Continue automatically** to Phase 5

**Next phase:** `/masterplan-test-strategy`

## Remember

- **Be specific** - Ambiguous tasks lead to wrong implementations
- **Think about rollback** - Every task should be reversible
- **Verify everything** - Don't assume, verify
- **Plan for review** - Build in review points
- **Track progress** - Know where you are at all times
