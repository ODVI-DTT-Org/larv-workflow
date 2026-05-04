---
name: masterplan-test-strategy
description: Use when running Phase 5 of MasterPlan — creating comprehensive test strategy covering unit, integration, E2E, migration, regression, performance, contract, chaos, security, and accessibility tests
---

# Test Strategy

## Overview

Create a complete test strategy to ensure no testing gaps. This strategy defines what will be tested, how it will be tested, and what constitutes passing.

**Core principle:** Test at the lowest level possible. Test business logic, not implementation.

**Announce at start:** "I'm using the masterplan-test-strategy skill to create the test strategy."

## When to Use

**Use this skill:**
- After implementation plan is complete
- Before writing any tests
- When defining quality standards
- When setting up CI/CD pipelines

**Do NOT use:**
- For trivial changes with existing tests
- When test strategy already exists
- For prototype/experimental code

## The Process

### Step 1: Define Unit Tests

Coverage goals and best practices.

### Step 2: Define Integration Tests

API, database, and service boundary testing.

### Step 3: Define Contract Tests

API contracts between services.

### Step 4: Define E2E Tests

Complete user workflows from start to finish.

### Step 5: Define Migration Tests

Data migrations and schema changes.

### Step 6: Define Regression Suite

Historical bug patterns to prevent reintroduction.

### Step 7: Define Performance Tests

Baseline performance and load testing.

### Step 8: Define Security Tests

Authentication, authorization, injection prevention.

### Step 9: Define Chaos Engineering

System resilience under failure conditions.

### Step 10: Define Accessibility Tests

WCAG compliance testing.

### Step 11: Define Test Execution Order

Test stages, timing, and environments.

## Expected Output

This skill generates:
- **Document**: `docs/planning/05-test-strategy.md`
- **Format**: Markdown with test tables and matrices
- **Size**: ~550 lines
- **Dependencies**: Requires `masterplan-implementation`

## Skill Dependencies

- **Prerequisites**: `masterplan-implementation` (Phase 4)
- **Required Inputs**: Implementation tasks, acceptance criteria
- **Feeds Into**: `masterplan-doc-governance`
- **Can Run Standalone**: No (requires implementation context)

## Completion & Next Steps

**After Test Strategy is complete:**

1. Display summary (auto-continue to Phase 6)
2. **Continue automatically** to Phase 6

**Next phase:** `/masterplan-doc-governance`

## Remember

- **Test early, test often** - Don't leave testing to the end
- **Test at the right level** - Unit tests for logic, integration for interactions
- **Keep tests fast** - Slow tests don't get run
- **Test edge cases** - Happy paths aren't enough
- **Measure and track** - You can't improve what you don't measure
