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
- [Related Plan: PLAN-2025-XXX](../../inbox/plans/PLAN-2025-XXX.md)
- [Technical Spike: Topic](../../inbox/spikes/spike-2025-01-15-topic.md)
- [External documentation or research](https://example.com)
