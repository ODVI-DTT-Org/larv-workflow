---
name: masterplan-c4-architecture
description: Use when running Phase 1 of MasterPlan — creating system architecture documentation with C4 model diagrams (Context, Containers, Components) plus data flow, deployment, security, and sequence diagrams
---

# C4 Architecture Model

## Overview

Create comprehensive architectural visualizations using the C4 model to establish clear system understanding. The C4 model provides multiple levels of zoom, from big-picture to code structure.

**Core principle:** Visual architecture reveals issues that text hides.

**Announce at start:** "I'm using the masterplan-c4-architecture skill to create system diagrams."

## When to Use

**Use this skill:**
- After pre-planning discussion is complete
- Before creating master design document
- When system architecture needs documentation
- When onboarding new developers
- When planning system changes

**Do NOT use:**
- For trivial code changes
- When architecture is already documented and unchanged
- For single-file modifications

## The Process

### Step 1: Level 1 - System Context Diagram

Show the system as a box in the center with all users and external systems.

**Include:**
- Primary users (different user types)
- Secondary users (admins, support, etc.)
- External systems (integrations, dependencies)
- Data flows between entities

**Answer:** "What is this system and how does it relate to the world?"

### Step 2: Level 2 - Container Diagram

Show the major building blocks (web app, mobile app, database, API, cache, etc.).

**Include:**
- Application containers (web, mobile, desktop)
- API containers (REST, GraphQL, gRPC)
- Data stores (databases, caches, file storage)
- Message queues/brokers
- External service boundaries

**Answer:** "How is the system structured at a high level?"

### Step 3: Level 3 - Component Diagram

For key containers, show internal components.

**Create for:**
- The most complex container
- Containers with high business value
- Containers with significant risk

**Answer:** "How is [container] structured internally?"

### Step 4: Additional Diagrams

**Data Flow Diagram (DFD):**
- Data entry points
- Data transformation steps
- Data storage points
- Data exit points

**Deployment Diagram:**
- Physical/virtual servers
- Network boundaries
- Security zones (DMZ, private, public)
- Data centers/regions
- Load balancers

**Security Boundary Diagram:**
- Public zone
- Private zone
- DMZ
- Trust boundaries
- Authentication/authorization boundaries

**Sequence Diagram:**
- Request/response flow
- Authentication flow
- Payment flow
- Data synchronization flow

### Step 5: Documentation

For each diagram, document:
- Technology choices with rationale
- Integration patterns
- Scalability boundaries
- Disaster recovery considerations

## Expected Output

This skill generates:
- **Document**: `docs/planning/01-c4-architecture.md`
- **Format**: Markdown with Mermaid diagrams
- **Size**: ~500 lines
- **Dependencies**: Requires completed `masterplan-discuss`

## Skill Dependencies

- **Prerequisites**: `masterplan-discuss` (Phase 0)
- **Required Inputs**: System context, user types, technology preferences
- **Feeds Into**: `masterplan-master-design`
- **Can Run Standalone**: No (requires context from Phase 0)

## Completion & Next Steps

**After C4 architecture is complete:**

1. Display summary to the user
2. Show options: continue / revise section / restart
3. **WAIT for user input**

**Next phase:** `/masterplan-master-design`

## Remember

- **Start with Context** - Get the big picture first
- **Add detail gradually** - Don't jump to code too fast
- **Use multiple diagram types** - Different views reveal different issues
- **Document rationale** - Why this architecture, not alternatives
- **Think about scale** - Design for current and future needs
- **Consider failure** - What breaks when things go wrong
- **Keep diagrams current** - Update as architecture evolves
