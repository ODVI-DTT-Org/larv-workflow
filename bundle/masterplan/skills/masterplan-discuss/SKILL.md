---
name: masterplan-discuss
description: Use when running Phase 0 of MasterPlan — gathering project requirements, scope, stakeholders, success metrics, constraints, edge cases, trade-offs, and risk assessment before creating design documents
---

# Pre-Planning Discussion

## Overview

Establish clarity on the project's foundation through structured dialogue before creating any design documents. This phase is iterative - expect to revisit topics as understanding deepens.

**Core principle:** Good input = good output. Time spent here saves hours later.

**Announce at start:** "I'm using the masterplan-discuss skill to gather project requirements."

## When to Use

**Use this skill:**
- Before creating any design documents
- Before starting implementation planning
- When project scope is unclear
- When requirements need clarification
- When starting a new feature or project

**Do NOT use:**
- For trivial changes (single bug fix, small refactor)
- When requirements are already documented and approved
- For emergency fixes

## The Process

### Step 1: Project Context

Ask about the problem being solved:
- What problem are we solving?
- Who are the users/stakeholders?
- What are the success metrics? (Must be SMART: Specific, Measurable, Achievable, Relevant, Time-bound)
- What is the business impact if this project fails?

### Step 2: Stakeholder Analysis

Identify who needs to be involved:

| Stakeholder | Role | Influence | Interest | Primary Concerns |
|-------------|------|-----------|----------|------------------|
| [Name/Role] | [Product/Engineering/Business/etc] | High/Med/Low | High/Med/Low | [What they care about] |

**Identify:**
- Primary decision maker
- Technical approvers
- Business approvers
- End user representatives
- Operations/maintenance team

### Step 3: Scope & Boundaries

- What features are IN scope?
- What features are explicitly OUT of scope?
- What are the phase boundaries (MVP, v1, v2, etc.)?
- What is the minimum viable product (MVP)?

**Use MoSCoW Analysis for Features:**
| Feature | Priority | Must Have | Should Have | Could Have | Won't Have |
|---------|----------|-----------|-------------|------------|------------|
| [Feature] | P0/P1/P2/P3 | [X] | [X] | [X] | [X] |

### Step 4: Requirements

**Functional Requirements:**
- Core features and their priorities
- User stories and use cases
- Critical paths vs. nice-to-haves
- User roles and permissions

**User Story Template:**
```
As a [user role],
I want [action/capability],
So that [benefit/value].

Acceptance Criteria:
- Given [context]
- When [action]
- Then [outcome]
```

**Non-Functional Requirements:**
- **Performance targets**: API latency (p50, p95, p99), page load time, database query time
- **Scalability requirements**: Concurrent users, data volume, growth rate
- **Availability/SLA**: Uptime percentage, RTO, RPO
- **Security/compliance**: Authentication, authorization, compliance standards (GDPR, SOC2, HIPAA, PCI-DSS)
- **Data residency**: Where data must be stored

### Step 5: Architecture Considerations

**Technology stack constraints:**
- Required languages/frameworks
- Technology restrictions (no X, must use Y)
- Legacy system integration requirements

**Integration points:**
- Existing systems to integrate with
- Third-party services/APIs
- Data synchronization needs

**Data storage preferences:**
- Database preferences
- Caching strategy
- Data retention requirements

**Deployment environment:**
- Target infrastructure (cloud provider, on-premise)
- Deployment regions
- Environment isolation (dev, staging, prod)

### Step 6: Edge Cases & Failure Scenarios

- What happens when X fails?
- What are the worst-case scenarios?
- What are the unlikely but critical edge cases?

**Edge Case Categories:**
- **Boundary cases**: Empty, single, maximum values
- **Failure cases**: Service down, timeout, error responses
- **Concurrency**: Simultaneous operations on same resource
- **Data**: Special characters, unicode, null, very large payloads
- **Time**: Timezone changes, daylight saving, leap seconds
- **Network**: Intermittent connectivity, slow connections

### Step 7: Constraints & Trade-offs

| Type | Constraint | Impact |
|------|------------|--------|
| Time | [deadline] | [impact] |
| Budget | [limit] | [impact] |
| Technical | [limitation] | [impact] |

**Document Trade-offs Made:**
| Decision | Chosen Approach | Trade-off | Rationale |
|----------|-----------------|------------|-----------|
| [Decision] | [What we chose] | [What we're giving up] | [Why] |

### Step 8: Risk Assessment

| Risk | Likelihood | Impact | Mitigation Strategy | Owner |
|------|------------|--------|---------------------|-------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to address] | [Who] |

**Risk Categories:**
- Technical risks
- Business risks
- Resource risks
- Schedule risks
- Dependencies risks

### Step 9: Success Metrics (SMART)

| Metric | Current | Target | How Measured | Frequency |
|--------|---------|--------|--------------|-----------|
| [Metric name] | [Baseline] | [Goal] | [Measurement method] | [Daily/Weekly/Monthly] |

### Step 10: Compliance & Legal

- Data privacy requirements (GDPR, CCPA, etc.)
- Industry-specific regulations (HIPAA, FINRA, etc.)
- Accessibility requirements (WCAG level)
- Security certifications required
- Data retention policies
- Right to be forgotten / data export requirements

### Step 11: Cost Considerations

- Budget constraints
- Cost targets (infrastructure, licensing)
- ROI expectations
- Ongoing operational costs

## When to Stop and Ask

**STOP and ask for clarification when:**
- User provides vague or conflicting requirements
- Success metrics are not measurable
- Scope boundaries are unclear
- Architecture has major contradictions
- Stakeholders are unidentified
- Risks are unaddressed

**Ask rather than assume.**

## Expected Output

This skill generates:
- **Document**: `docs/planning/00-pre-planning-summary.md`
- **Format**: Markdown with tables
- **Size**: ~400 lines
- **Dependencies**: None

## Skill Dependencies

- **Prerequisites**: None
- **Required Inputs**: Project concept, basic problem statement
- **Feeds Into**: `masterplan:c4-architecture`
- **Can Run Standalone**: Yes

## Completion & Next Steps

**After discussion is complete, you MUST:**

1. **Generate the Pre-Planning Summary** using the Output Template below
2. **Display the summary to the user** with this exact format:
   ```
   *** PHASE 0: PRE-PLANNING COMPLETE ***

   I've generated the Pre-Planning Summary based on our discussion.

   **Key Points:**
   - [Bullet 1: Main requirement]
   - [Bullet 2: Success metric]
   - [Bullet 3: Key constraint]
   - [Bullet 4: Major risk]

   Full summary saved to: docs/planning/00-pre-planning-summary.md

   *** OPTIONS ***
   - "continue" - Proceed to Phase 1 (C4 Architecture)
   - "revise [section]" - Make changes to the summary
   - "restart" - Start discussion over
   ```

3. **WAIT for user input** - Do NOT proceed automatically

## Output Template

```markdown
# Pre-Planning Summary

> Project: [Name] | Date: [Date] | Version: 1.0

---

## Project Overview

**Problem Statement**:
[Clear description of the problem being solved]

**Target Users**:
[Primary and secondary user groups]

**Success Metrics** (SMART):
1. [Metric]: [Current] → [Target] by [Date]
2. [Metric]: [Current] → [Target] by [Date]

---

## Stakeholder Analysis

| Stakeholder | Role | Influence | Interest | Primary Concerns |
|-------------|------|-----------|----------|------------------|
[Stakeholder table]

---

## Scope Definition

### In Scope (Must Have)
- [feature 1] - Priority: P0
- [feature 2] - Priority: P1

### Out of Scope
- [feature X] - Reason: [why not now]

### Phase Boundaries
- **MVP**: [what defines minimum viable product]
- **v1**: [what defines first full release]

---

## Requirements Summary

### Functional Requirements
1. [FR-001] [Requirement description]
2. [FR-002] [Requirement description]

### User Stories
1. As a [user], I want [action], so that [benefit]
   - Acceptance Criteria: [criteria]

### Non-Functional Requirements
- **Performance**: API latency p50 < Xms, p95 < Yms, p99 < Zms
- **Scalability**: Support X concurrent users
- **Availability**: Uptime target X%
- **Security**: Authentication [method], Authorization [model]

---

## Architecture Context

### Technology Stack
- **Backend**: [languages/frameworks]
- **Frontend**: [frameworks]
- **Database**: [primary/secondary]
- **Infrastructure**: [cloud provider, regions]

### Integrations
- [External System 1]: [integration type, protocol]

---

## Known Edge Cases & Failure Scenarios

| Edge Case | Handling Strategy |
|-----------|-------------------|
| [case 1] | [handling strategy] |

---

## Constraints & Trade-offs

| Type | Constraint | Impact |
|------|------------|--------|
| Time | [deadline] | [impact] |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| [risk] | High/Med/Low | High/Med/Low | [strategy] | [who] |

---

## Compliance & Legal Requirements

- [X] Data privacy: [requirements]
- [X] Accessibility: [WCAG level]
- [X] Industry regulations: [standards]

---

## Cost Considerations

- **Budget**: [amount]
- **Infrastructure cost target**: [amount/month]
- **ROI expectation**: [expected return]

---

## Assumptions

| Assumption | Validation Method | Owner | Due Date |
|------------|-------------------|-------|----------|
| [assumption 1] | [how to validate] | [who] | [when] |

---

## Open Questions / TBDs

| Question | Importance | Owner | Due Date |
|----------|------------|-------|----------|
| [question 1] | High/Med/Low | [who] | [when] |

---

## Ready for Next Phase Checklist

- [ ] All critical questions answered or documented as TBD
- [ ] Scope boundaries clear and agreed upon
- [ ] Architecture direction established
- [ ] Stakeholders identified and consulted
- [ ] Key risks documented with mitigation plans
- [ ] Success metrics defined and measurable
- [ ] Trade-offs documented and decisions made
- [ ] Compliance requirements identified
- [ ] Open questions have owners and due dates

---

## Phase 0 Complete

**Next Steps**:
- Review and approve this summary
- Proceed to `/masterplan-c4-architecture` for system visualization
- Revisit this phase if new information emerges
```

## Remember

- **Be thorough** - Time spent here saves time later
- **Document assumptions** - Make them explicit, not implicit
- **Identify decision makers** - Know who can resolve conflicts
- **Think about failures** - Plan for what could go wrong
- **Consider constraints** - They shape the solution space
- **Define measurable success** - Otherwise you won't know when you're done
- **Embrace iteration** - It's OK to come back and revise
- **ALWAYS show summary before continuing** - Never auto-proceed to next phase
