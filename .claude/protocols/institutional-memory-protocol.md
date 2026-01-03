# Institutional Memory Protocol

**Purpose:** Ensure Product Manager and Solutions Architect use Qdrant as institutional memory to maintain consistency and build on past work.

**Enforcement:** Injected via SubagentStart hooks for `product-manager` and `solutions-architect` agents.

---

## Core Principle

**Institutional memory is not optional.**

Every feature proposal, architectural decision, and development plan MUST be informed by past work. Qdrant semantic search is the gateway to institutional knowledge.

**Agents that ignore institutional memory create:**
- Duplicated work
- Inconsistent patterns
- Architectural drift
- Wasted effort reinventing solutions

---

## Product Manager: Search-First Feature Validation

### Mandatory Search Points

**1. Before Proposing New Features**

Search queries to run:

```
"User feedback about [feature area]"
"Past feature requests for [capability]"
"[Feature name] implementation status"
```

**Purpose:** Avoid duplicate proposals, find existing partial implementations, validate user need.

**Example:**

```markdown
Feature Proposal: Dark Mode Toggle

## Background Research (MANDATORY)
Searched: "Dark mode user requests"
Results:
- 8 user requests in Stellaris feedback (2024-Q2)
- 3 requests in Hotel de Ville feedback (2024-Q3)
- No existing implementation found

Searched: "Theme switching implementation"
Results:
- CSS variable pattern used in Stellaris v1.2 (different use case)
- Can adapt pattern for dark mode

Validation: Feature is requested, no duplication, pattern exists ✓
```

**2. During Prioritization**

Search queries to run:

```
"Prioritization decisions for [feature type]"
"ICE scores for [similar features]"
"Impact of [feature area] on users"
```

**Purpose:** Learn from past prioritization decisions, calibrate scoring consistency.

**Example:**

```markdown
Prioritization: Dark Mode Toggle

## Historical Prioritization Context
Searched: "UI customization feature prioritization"
Results:
- Language selector: Impact 8, Confidence 0.9, Ease 7 → ICE 50.4
- Font size toggle: Impact 6, Confidence 0.8, Ease 8 → ICE 38.4

Current Feature: Dark Mode
- Impact: 7 (accessibility + user preference)
- Confidence: 0.9 (clear requirements, proven pattern)
- Ease: 6 (CSS + state management + persistence)
- ICE Score: 37.8

Calibration: Aligned with similar customization features ✓
```

**3. Before Creating User Journeys**

Search queries to run:

```
"User journey for [workflow]"
"User personas for [feature area]"
"Accessibility considerations for [UI element]"
```

**Purpose:** Maintain consistency with existing user journey patterns, follow established personas.

### Documentation Requirements

**Every feature proposal MUST include:**

```markdown
## Institutional Memory Check

### Search Queries Run
1. "[Query 1]" → [Summary of findings]
2. "[Query 2]" → [Summary of findings]
3. "[Query 3]" → [Summary of findings]

### Key Findings
- Past related work: [Summary]
- Existing patterns: [Summary]
- Alignment status: ✓ Aligned / ⚠ Divergence (justified below)

### Divergence Justification (if applicable)
[Explain why this feature diverges from existing patterns]
```

**No institutional memory check = Incomplete proposal**

---

## Solutions Architect: Consistency-First Decision Making

### Mandatory Search Points

**1. Before Making Architectural Decisions**

Search queries to run:

```
"Architectural decisions about [technology/pattern]"
"ADRs for [system component]"
"Design patterns for [capability]"
"Trade-offs between [option A] and [option B]"
```

**Purpose:** Verify consistency with established architecture, avoid contradictory decisions.

**Example:**

```markdown
ADR: Choose PostgreSQL for Stellaris User Data

## Institutional Memory Check (MANDATORY)
Searched: "Database choices for user data"
Results:
- ADR-005: Chose PostgreSQL for Hotel de Ville (2024-02)
  - Reason: Relational integrity, ACID guarantees
  - Trade-off: Complexity vs. SQLite
- ADR-012: Chose SQLite for Stellaris audio data (2024-05)
  - Reason: Simplicity, embedded, offline-first
  - Trade-off: Scalability limited

Current Decision: PostgreSQL for Stellaris user data
- Aligns with: ADR-005 (same reasoning - relational integrity)
- Diverges from: ADR-012 (different use case - user data needs ACID)

Consistency Status: ✓ Consistent architectural philosophy
```

**2. During Technology Selection**

Search queries to run:

```
"Experience with [technology name]"
"[Technology A] vs [Technology B] comparison"
"Performance of [technology] in [use case]"
```

**Purpose:** Learn from past technology adoption outcomes, avoid repeating mistakes.

**Example:**

```markdown
ADR: Choose WebSockets for Real-Time Updates

## Institutional Memory Check
Searched: "Real-time communication patterns"
Results:
- No existing WebSocket implementations found
- HTTP polling used in Stellaris audio status (2024-04)
  - Lesson: Polling caused battery drain on mobile

Searched: "WebSocket experience"
Results:
- No production WebSocket usage found in jf-private
- Risk: New technology, no institutional knowledge

Decision: Proceed with WebSocket BUT document extensively
Action: Create detailed implementation guide for future reference
```

**3. Before Proposing Design Patterns**

Search queries to run:

```
"Design patterns for [component type]"
"Code structure for [system area]"
"Reusable patterns in [project]"
```

**Purpose:** Reuse proven patterns, maintain consistency across codebase.

### Documentation Requirements

**Every ADR MUST include:**

```markdown
## Architectural Consistency Check

### Related ADRs
- ADR-XXX: [Title] ([Date])
  - Decision: [Summary]
  - Relevance: [How it relates]
  - Alignment: ✓ Consistent / ⚠ Diverges

### Search Queries Run
1. "[Query 1]" → [Findings]
2. "[Query 2]" → [Findings]

### Consistency Analysis
- Pattern alignment: [Analysis]
- Technology alignment: [Analysis]
- Philosophy alignment: [Analysis]

### Divergence Justification (if applicable)
[Explain why this decision diverges from past patterns]
- Reason for divergence: [Explanation]
- Risk mitigation: [How to manage inconsistency]
- Future recommendation: [Should this become new standard?]
```

**No consistency check = Incomplete ADR**

---

## Technical PM: Learning from Past Efforts

### Mandatory Search Points

**1. Before Creating Development Plans**

Search queries to run:

```
"Development plans for [feature type]"
"Complexity estimates for [similar work]"
"Implementation challenges with [technology]"
```

**Purpose:** Learn from past execution, improve estimates, avoid known pitfalls.

**Example:**

```markdown
Development Plan: Audio Waveform Visualization

## Historical Context (MANDATORY)
Searched: "Audio visualization implementation"
Results:
- PLAN-2024-042: Audio playback UI (Q2 2024)
  - Estimated: 8 hours
  - Actual: 12 hours (+50%)
  - Challenge: Browser audio API complexity

Searched: "Canvas rendering performance"
Results:
- PLAN-2024-089: Real-time graph rendering
  - Lesson: Use requestAnimationFrame for smooth updates
  - Lesson: Throttle updates to 60fps max

Current Estimate: 10 hours (based on PLAN-2024-042 + 25% buffer)
Risk Mitigation: Follow Canvas pattern from PLAN-2024-089
```

**2. During Complexity Assessment**

Search queries to run:

```
"Technical dependencies of [feature]"
"Complexity factors for [work type]"
"Unknown unknowns in [area]"
```

**Purpose:** Surface hidden complexity early, trigger spikes for unknowns.

**Example:**

```markdown
Complexity Assessment: Database Migration for User Profiles

## Complexity Research
Searched: "Database migration challenges"
Results:
- PLAN-2024-031: Schema change with backfill
  - Complexity: HIGH (data migration + zero-downtime)
  - Actual effort: 2x estimate
  - Lesson: Always include rollback plan

Searched: "Schema change patterns"
Results:
- Pattern: Blue-green deployment for schema changes
- Pattern: Backfill in background job

Current Assessment: MEDIUM → HIGH (based on findings)
Recommendation: Spike on zero-downtime migration strategy
```

**3. Before Assigning Agents**

Search queries to run:

```
"Agent performance for [task type]"
"[Agent name] success rate"
"Workstream allocation patterns"
```

**Purpose:** Assign work to agents with proven track record for similar tasks.

### Documentation Requirements

**Every development plan MUST include:**

```markdown
## Historical Learning

### Similar Past Plans
- PLAN-YYYY-NNN: [Title]
  - Estimate: [Hours]
  - Actual: [Hours]
  - Variance: [%]
  - Key lesson: [Summary]

### Applied Learnings
1. [Lesson from past plan] → [How applied to current plan]
2. [Lesson from past plan] → [How applied to current plan]

### Risk Mitigation
Based on historical challenges:
- Risk: [Historical issue]
  - Mitigation: [Strategy]
```

---

## Enforcement via Hooks

### SubagentStart Hook Configuration

**In `.claude/settings.json`:**

```json
{
  "type": "SubagentStart",
  "matcher": "product-manager",
  "protocol": ".claude/protocols/institutional-memory-protocol.md"
}
```

```json
{
  "type": "SubagentStart",
  "matcher": "solutions-architect",
  "protocol": ".claude/protocols/institutional-memory-protocol.md"
}
```

**Effect:** Every time Product Manager or Solutions Architect agent starts, this protocol is injected into their context.

**Reminder text:**

```
🔍 INSTITUTIONAL MEMORY PROTOCOL ACTIVE

You MUST search Qdrant before making decisions:
- Product Manager: Search for similar features, past prioritization
- Solutions Architect: Search for related ADRs, existing patterns

Document search findings in your output. No search = incomplete work.
```

---

## Search Query Library

### Product Manager Queries

```
# Feature validation
"User feedback about [feature area]"
"Past feature requests for [capability]"
"[Feature name] implementation status"

# Prioritization
"Prioritization decisions for [feature type]"
"ICE scores for [similar features]"
"Impact of [feature area] on users"

# User journey
"User journey for [workflow]"
"User personas for [feature area]"
"Accessibility considerations for [UI element]"
```

### Solutions Architect Queries

```
# Architectural decisions
"Architectural decisions about [technology/pattern]"
"ADRs for [system component]"
"Design patterns for [capability]"

# Technology selection
"Experience with [technology name]"
"[Technology A] vs [Technology B] comparison"
"Performance of [technology] in [use case]"

# Pattern discovery
"Design patterns for [component type]"
"Code structure for [system area]"
"Reusable patterns in [project]"
```

### Technical PM Queries

```
# Plan creation
"Development plans for [feature type]"
"Complexity estimates for [similar work]"
"Implementation challenges with [technology]"

# Complexity assessment
"Technical dependencies of [feature]"
"Complexity factors for [work type]"
"Unknown unknowns in [area]"

# Agent assignment
"Agent performance for [task type]"
"Workstream allocation patterns"
```

---

## Quality Gate: Institutional Memory Check

**Before approving any:**
- Feature proposal
- Architectural decision (ADR)
- Development plan

**Verify:**

- [ ] Search queries documented
- [ ] Search results summarized
- [ ] Alignment with past work analyzed
- [ ] Divergence justified (if applicable)
- [ ] Learnings from past efforts applied

**If any checkbox is unchecked → REJECT with reason:**

```
⚠ Institutional Memory Check Failed

Missing: [What's missing]
Required: [What's needed]

Please search Qdrant and document findings before proceeding.
```

---

## Examples: Complete Workflows

### Example 1: Product Manager Feature Validation

**Scenario:** User requests "Export chat history" feature

**Workflow:**

1. **Search for similar features:**
   ```
   Query: "Export functionality in Stellaris"
   Results:
   - Export audio files (implemented in v1.3)
   - Export progress reports (planned in PLAN-2024-067)
   ```

2. **Search for user requests:**
   ```
   Query: "User requests for export capabilities"
   Results:
   - 5 requests for chat export (2024-Q3)
   - 12 requests for data export (general, 2024-Q2)
   ```

3. **Search for implementation patterns:**
   ```
   Query: "Data export patterns in Stellaris"
   Results:
   - CSV export used for progress reports
   - JSON download for audio metadata
   ```

4. **Document findings:**
   ```markdown
   Feature Proposal: Chat History Export

   ## Institutional Memory Check ✓

   ### Search Results
   1. Similar features: Export audio (v1.3), Export progress (planned)
   2. User demand: 5 direct requests + 12 general export requests
   3. Pattern: CSV export for tabular data, JSON for structured data

   ### Decision
   - Format: CSV (aligns with progress report pattern)
   - Delivery: Download button (aligns with audio export UX)
   - Priority: MEDIUM (validated user need, pattern exists)

   ICE Score: 6 (Impact) × 0.8 (Confidence) × 7 (Ease) = 33.6
   ```

### Example 2: Solutions Architect Technology Decision

**Scenario:** Choose database for new analytics feature

**Workflow:**

1. **Search for database decisions:**
   ```
   Query: "Database architectural decisions"
   Results:
   - ADR-005: PostgreSQL for Hotel de Ville (relational integrity)
   - ADR-012: SQLite for Stellaris audio (offline-first, simplicity)
   ```

2. **Search for analytics patterns:**
   ```
   Query: "Analytics data storage patterns"
   Results:
   - Time-series data stored in PostgreSQL (Hotel de Ville metrics)
   - Aggregated stats in SQLite (Stellaris progress tracking)
   ```

3. **Search for performance learnings:**
   ```
   Query: "Database performance challenges"
   Results:
   - PostgreSQL: Complex queries slow without indexes (lesson from HdV)
   - SQLite: Write contention under load (lesson from Stellaris)
   ```

4. **Create ADR with findings:**
   ```markdown
   ADR-XXX: Choose PostgreSQL for Analytics Data

   ## Context
   Need to store user analytics: sessions, events, metrics

   ## Institutional Memory Check ✓

   ### Related ADRs
   - ADR-005: PostgreSQL for Hotel de Ville
     - Reason: Relational integrity, complex queries
     - Alignment: ✓ Similar use case (relational analytics)
   - ADR-012: SQLite for Stellaris audio
     - Reason: Offline-first, simplicity
     - Alignment: ✗ Different use case (online analytics)

   ### Search Findings
   - Pattern: Time-series in PostgreSQL (proven in HdV)
   - Lesson: Requires proper indexing (avoid slow queries)
   - Trade-off: Complexity acceptable for analytics use case

   ## Decision
   PostgreSQL for analytics data

   Rationale:
   - Aligns with ADR-005 (relational data pattern)
   - Time-series pattern proven in production
   - Complexity justified by query requirements

   ## Implementation Notes
   - Add indexes from day 1 (lesson from HdV)
   - Use connection pooling (lesson from HdV scaling)
   - Monitor query performance (pg_stat_statements)
   ```

---

## Summary

**Institutional memory is the foundation of consistent, efficient development.**

**Product Manager:** Search validates features, calibrates prioritization, maintains UX consistency

**Solutions Architect:** Search ensures architectural alignment, reuses proven patterns, documents divergence

**Technical PM:** Search improves estimates, surfaces hidden complexity, applies past learnings

**Enforcement:** Hooks inject this protocol automatically - no manual reminder needed

**Key principle:** Every decision is informed by history. Search first, decide second, document always.
