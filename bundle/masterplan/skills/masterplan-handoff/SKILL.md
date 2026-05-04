---
name: masterplan-handoff
description: Use when running Phase 8 of MasterPlan — creating agent execution handoff document with exact scope, ordered tasks, verification after every task, blocked-path decision tree, prohibited actions, and completion evidence format
---

# Agent Execution Handoff

## Overview

Rewrite all previous outputs as an execution-ready handoff for coding agents. This document must be unambiguous and immediately actionable.

**Core principle:** Every task is atomic, verifiable, and reversible.

**Announce at start:** "I'm using the masterplan-handoff skill to create the agent execution handoff."

## When to Use

**Use this skill:**
- After adversarial review is complete
- Before handing off to developers or agents
- When implementation will be done by coding agents
- When execution clarity is critical

**Do NOT use:**
- For already-implemented features
- For trivial changes
- When implementing manually

## The Process

### Step 1: Define Exact Scope

IN Scope, OUT of Scope, and Boundaries.

### Step 2: Create Ordered Tasks

Each task must be atomic, verifiable, and reversible.

### Step 3: Define Verification After Every Task

Specific commands to run after each task with expected output.

### Step 4: Create Blocked-Path Decision Tree

What to do when things go wrong — using Mermaid flowchart.

### Step 5: Define Prohibited Actions

Clear list of what agents MUST NOT do.

### Step 6: Define Development Environment Setup

Local development commands and verification.

### Step 7: Define Completion Evidence Format

Standard format for reporting task completion.

## Expected Output

This skill generates:
- **Document**: `docs/planning/08-agent-handoff.md`
- **Format**: Markdown with task tables and decision trees
- **Size**: ~450 lines
- **Dependencies**: Requires all previous phases

## Skill Dependencies

- **Prerequisites**: All previous phases (0-7)
- **Required Inputs**: All planning documents
- **Feeds Into**: `masterplan-verification`
- **Can Run Standalone**: No (requires full context)

## Completion & Next Steps

**After Agent Handoff is complete:**

1. Display summary (auto-continue to Phase 9)
2. **Continue automatically** to Phase 9

**Next phase:** `/masterplan-verification`

## Remember

- **Follow the order** - Tasks are ordered for a reason
- **Verify everything** - Don't assume, verify
- **Ask for help** - Don't struggle alone
- **Document issues** - Create a paper trail
- **Report progress** - Keep stakeholders informed
