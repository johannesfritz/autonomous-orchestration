---
name: write-adr
description: Create Architecture Decision Records for significant technical decisions. Use after making architectural choices, when documenting why a technology was selected, or when solutions-architect needs to record a decision.
allowed-tools: Read, Write, Glob, Grep
---

# Write ADR Skill

**Purpose:** Create Architecture Decision Records (ADRs) using MADR (Markdown Any Decision Records) format for significant technical decisions.

**When to use:**
- After making an architectural decision that needs documentation
- When documenting why a technology or pattern was selected
- When Solutions Architect completes a decision-making process
- When a significant trade-off needs to be recorded for future reference

---

## Workflow

### 1. Determine Project

Identify which project this ADR belongs to based on context:

- **Stellaris** → `stellaris/docs/adr/`
- **Hotel de Ville** → `hotel-de-ville/docs/adr/`
- **Repository-wide** → `00 Inbox/adr/` (for tooling, processes, meta-decisions)
- **Cross-project** → Create in both project folders with cross-reference

**Detection heuristics:**
- File paths mentioned → use that project
- Explicit project name → use that project
- Technology specific to one project → use that project
- Claude Code infrastructure → repository-wide

### 2. Determine ADR Number

Scan the target project's `docs/adr/` directory to find the next available number:

```bash
# Example for Stellaris
ls stellaris/docs/adr/ADR-*.md | wc -l
# Result: 3 existing ADRs
# Next number: ADR-004
```

**Numbering rules:**
- Sequential integers starting at 001
- Zero-padded to 3 digits (ADR-001, ADR-002, etc.)
- No gaps in sequence
- If directory doesn't exist, start at ADR-001

### 3. Create ADR from Template

Use the template in `adr-template.md` (see below).

**File naming convention:** `ADR-NNN-kebab-case-title.md`

**Examples:**
- `ADR-001-sqlite-vs-postgresql-for-stellaris.md`
- `ADR-002-zustand-state-management.md`
- `ADR-003-qdrant-vector-database.md`

### 4. Fill in MADR Sections

Required sections (from template):
1. **Status** - Current state of the decision
2. **Context and Problem Statement** - What forces are at play?
3. **Decision Drivers** - What criteria matter for this decision?
4. **Considered Options** - What alternatives were evaluated?
5. **Decision Outcome** - What was chosen and why?
6. **Pros and Cons of Options** - Detailed evaluation of each option

**Quality criteria:**
- **Concise but complete** - No fluff, but don't skip important context
- **Trade-offs explicit** - State both benefits and costs
- **Criteria-linked** - Connect decision to specific drivers
- **Future-friendly** - Someone reading this in 6 months should understand why

### 5. Update ADR Index

Maintain `docs/adr/README.md` with table of all ADRs.

**Format:**
```markdown
# Architecture Decision Records

| ID | Title | Status | Date |
|----|-------|--------|------|
| [ADR-001](ADR-001-example.md) | Example Decision | Accepted | 2025-01-01 |
| [ADR-002](ADR-002-new.md) | New Decision | Accepted | 2025-01-15 |
```

**Update process:**
1. Read existing README.md
2. Add new row for the new ADR
3. Keep rows sorted by ID (newest last)
4. Write back to README.md

If `README.md` doesn't exist, create it with header and first entry.

---

## ADR Template

Location: `.claude/skills/write-adr/adr-template.md`

```markdown
# ADR-[number]: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded by [ADR-XXX]
**Date:** [YYYY-MM-DD]
**Deciders:** [who made this decision - e.g., Johannes, Solutions Architect, Product Team]
**Technical Story:** [link to related plan/issue/spike if applicable]

## Context and Problem Statement

[Describe the context and problem statement in 2-4 paragraphs. What forces are at play? What constraints exist? What requirements drive this decision?]

[Good context answers: Why do we need to make this decision now? What would happen if we didn't decide? What are the key constraints (time, budget, team skills, existing systems)?]

## Decision Drivers

- [driver 1, e.g., "Must support 1000+ concurrent users"]
- [driver 2, e.g., "Team has strong Python experience but limited Go"]
- [driver 3, e.g., "Budget constraint of $100/month for infrastructure"]
- [driver 4, e.g., "Must integrate with existing PostgreSQL database"]
- [driver 5, e.g., "Decision must be reversible within 3 months"]

## Considered Options

1. **[Option 1]** - [1-2 sentence description]
2. **[Option 2]** - [1-2 sentence description]
3. **[Option 3]** - [1-2 sentence description]

[Include at least 3 options. Consider "do nothing" as an option when relevant.]

## Decision Outcome

**Chosen option:** "[Option X]", because [2-3 sentence justification explicitly linking to decision drivers above].

### Positive Consequences

- [e.g., "Improved query performance by 10x"]
- [e.g., "Simplified deployment (no separate database server)"]
- [e.g., "Team can start implementing immediately (familiar technology)"]

### Negative Consequences

- [e.g., "Increased complexity in error handling"]
- [e.g., "Learning curve for team (2 week ramp-up estimated)"]
- [e.g., "Won't scale beyond 10k users without migration"]

## Pros and Cons of the Options

### [Option 1]

- **Good**, because [specific benefit]
- **Good**, because [specific benefit]
- **Bad**, because [specific drawback]
- **Bad**, because [specific drawback]
- **Neutral**, because [neutral consideration]

### [Option 2]

- **Good**, because [specific benefit]
- **Good**, because [specific benefit]
- **Bad**, because [specific drawback]
- **Bad**, because [specific drawback]

### [Option 3]

- **Good**, because [specific benefit]
- **Bad**, because [specific drawback]
- **Bad**, because [specific drawback]

## Links

- [Related ADR-XXX: Title](ADR-XXX-title.md)
- [Related Plan: PLAN-2025-XXX](../../00 Inbox/plans/PLAN-2025-XXX.md)
- [Technical Spike: Topic](../../00 Inbox/spikes/spike-2025-01-15-topic.md)
- [External documentation or research](https://example.com)
```

---

## Status Values

ADRs have a lifecycle tracked in the **Status** field:

| Status | Meaning |
|--------|---------|
| **Proposed** | Decision drafted but not yet approved |
| **Accepted** | Decision approved and in effect |
| **Deprecated** | Decision no longer recommended but not replaced |
| **Superseded by ADR-XXX** | Decision replaced by newer ADR |

**Status transitions:**
- New ADR → Proposed (unless immediately accepted)
- After approval → Accepted
- When better approach found → Superseded by ADR-XXX
- When no longer relevant but no replacement → Deprecated

---

## Quality Checklist

Before finalizing an ADR, verify:

- [ ] **Title is descriptive** - Clear what decision is about
- [ ] **Status is set** - Proposed or Accepted
- [ ] **Context is sufficient** - Someone unfamiliar can understand the problem
- [ ] **Decision drivers are explicit** - Clear what criteria mattered
- [ ] **At least 3 options considered** - Shows thorough evaluation
- [ ] **Decision outcome links to drivers** - Justification references specific criteria
- [ ] **Pros and cons are balanced** - Not just selling the chosen option
- [ ] **Consequences are honest** - Both positive and negative listed
- [ ] **Links are provided** - Related ADRs, plans, spikes referenced
- [ ] **File naming is correct** - ADR-NNN-kebab-case.md format
- [ ] **Index is updated** - README.md includes new entry

---

## Examples

### Example 1: Database Selection

**File:** `stellaris/docs/adr/ADR-001-sqlite-vs-postgresql.md`

**Key sections:**
- **Context:** "Stellaris needs persistent storage for user progress..."
- **Drivers:** "Single-user app, deployment simplicity, cost..."
- **Options:** SQLite, PostgreSQL, Cloud Firestore
- **Decision:** SQLite
- **Rationale:** "Eliminates separate database server, sufficient for single-user workload, team familiarity with SQL"
- **Trade-off:** "Won't scale to multi-tenant SaaS, but acceptable because Stellaris is single-user by design"

### Example 2: Architectural Pattern

**File:** `stellaris/docs/adr/ADR-005-zustand-state-management.md`

**Key sections:**
- **Context:** "React Context becoming unwieldy for complex state..."
- **Drivers:** "TypeScript support, migration ease, bundle size..."
- **Options:** Redux Toolkit, Zustand, Refactor Context
- **Decision:** Zustand
- **Rationale:** "Simpler than Redux, better TS support, minimal bundle impact, gradual migration"
- **Trade-off:** "Less ecosystem than Redux, team learning curve"

---

## Error Handling

**If ADR directory doesn't exist:**
1. Create it: `mkdir -p {project}/docs/adr/`
2. Start numbering at ADR-001
3. Create README.md with initial structure

**If numbering collision (concurrent ADRs):**
1. Check for highest existing number
2. Use next available
3. Log warning if gap detected (manual resolution needed)

**If project can't be determined:**
1. Ask user which project
2. Default to repository-wide (00 Inbox/adr/) if unclear
3. Document assumption in ADR metadata

---

## Integration Points

**This skill is used by:**
- `solutions-architect` agent - Primary user for architectural decisions
- `technical-pm` agent - For process/workflow decisions
- Manual `/adr` command - User-initiated ADR creation

**This skill uses:**
- `Read` - Scan existing ADRs for numbering
- `Write` - Create new ADR file
- `Glob` - Find all ADR files
- `Grep` - Search for related ADRs

---

## Continuous Improvement

Update this skill when:
- MADR format evolves
- New ADR patterns emerge
- Quality issues identified in generated ADRs
- Integration needs change

Document significant changes to this skill in repository CLAUDE.md.
