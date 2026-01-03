# Semantic Search Protocol

**Purpose:** Define when and how to use semantic documentation search during development workflows.

---

## When to Use Semantic Search

### Use Semantic Search When:

1. **Building on Past Work**
   - Finding related development plans
   - Locating similar features already implemented
   - Discovering existing infrastructure/patterns to reuse

2. **Maintaining Consistency**
   - Verifying alignment with established architectural patterns
   - Checking consistency with existing user journeys
   - Validating adherence to documented standards

3. **Avoiding Duplication**
   - Checking if a feature request already exists
   - Finding past discussions about a topic
   - Locating existing solutions to similar problems

4. **Learning from History**
   - Understanding why past decisions were made
   - Finding lessons learned from similar efforts
   - Reviewing outcomes of related initiatives

### DON'T Use Semantic Search For:

- Finding specific code files (use `Glob` or `Grep` tools)
- Looking up API endpoints (use project documentation directly)
- Checking current file contents (use `Read` tool)
- Real-time system state (search indexes documentation, not live data)

---

## Search Query Patterns

### Effective Query Formulation

**Good queries are:**
- **Specific:** Include key concepts, technologies, or feature names
- **Context-rich:** Mention the domain or subsystem
- **Action-oriented:** Use verbs that describe what you're trying to do

**Examples:**

| Scenario | Poor Query | Good Query |
|----------|------------|------------|
| Finding auth patterns | "authentication" | "How was JWT authentication implemented in Stellaris?" |
| Past API work | "API" | "REST API patterns used for user management endpoints" |
| UI components | "buttons" | "Reusable button components with accessibility support" |
| Database migrations | "migrations" | "Database schema migration strategy and rollback procedures" |

### Query Patterns by Role

**Product Manager:**
```
"User feedback about [feature area]"
"Past prioritization decisions for [feature type]"
"Similar features in [product/system]"
"User journey for [workflow]"
```

**Solutions Architect:**
```
"Architectural decisions about [technology/pattern]"
"Design patterns for [system component]"
"Infrastructure choices for [capability]"
"Trade-offs between [option A] and [option B]"
```

**Technical PM:**
```
"Past development plans for [feature type]"
"Complexity estimates for [similar work]"
"Technical dependencies of [feature/system]"
"Implementation challenges with [technology]"
```

**Developer:**
```
"Code patterns for [functionality]"
"Error handling strategies for [scenario]"
"Testing approaches for [component type]"
"Performance optimization for [bottleneck]"
```

---

## Interpreting Search Results

### Understanding Relevance Scores

Search returns results with relevance scores (0.0 to 1.0):

| Score Range | Interpretation | Action |
|-------------|----------------|--------|
| **0.8 - 1.0** | Highly relevant match | Read in detail, likely what you need |
| **0.6 - 0.8** | Moderately relevant | Skim for applicable insights |
| **0.4 - 0.6** | Tangentially related | Consider context, may have useful links |
| **< 0.4** | Weak match | Likely not useful, refine query |

### Result Structure

Each search result includes:

```json
{
  "id": "2024-01-15-001",
  "title": "JWT Authentication Implementation",
  "bluf": "Implemented JWT-based authentication with refresh tokens...",
  "score": 0.85,
  "source_file": "04 Projects/Stellaris/auth-implementation.md",
  "tags": ["authentication", "security", "jwt"],
  "cross_references": ["2024-01-10-042", "2024-01-12-003"]
}
```

**Key fields:**
- **BLUF:** Quick summary to assess relevance
- **score:** Relevance to your query
- **source_file:** Original document location
- **cross_references:** Related notes to explore

### Exploration Strategy

1. **Start with highest-scoring result**
2. **Read BLUF to confirm relevance**
3. **Check source_file for full context**
4. **Follow cross_references for related information**
5. **Refine query if results aren't helpful**

---

## Integration with Agent Workflows

### Product Manager Integration

**Before proposing new features:**

1. **Search for similar past requests:**
   ```
   Query: "User requests for [feature area]"
   ```

2. **Check if feature already exists:**
   ```
   Query: "[Feature description] implementation in [product]"
   ```

3. **Document findings in feature proposal:**
   ```markdown
   ## Past Related Work
   - Found similar request in 2024-03 (closed as duplicate)
   - Existing partial implementation in Stellaris v2.1
   - Past ADR recommended [approach]
   ```

### Solutions Architect Integration

**Before architectural decisions:**

1. **Search for existing patterns:**
   ```
   Query: "Architectural decisions for [technology/pattern]"
   ```

2. **Check consistency with past decisions:**
   ```
   Query: "Design patterns for [similar component]"
   ```

3. **Reference findings in ADR:**
   ```markdown
   ## Context
   Previous architectural decisions:
   - ADR-005: Chose PostgreSQL for relational data (2024-02)
   - ADR-012: Adopted REST over GraphQL (2024-05)

   This decision builds on ADR-005...
   ```

### Technical PM Integration

**Before creating development plans:**

1. **Search for similar past efforts:**
   ```
   Query: "Development plans for [feature type]"
   ```

2. **Find complexity estimates:**
   ```
   Query: "Complexity and effort for [similar work]"
   ```

3. **Document in plan:**
   ```markdown
   ## Historical Context
   - Similar feature implemented in Q2 2024 (PLAN-2024-042)
   - Estimated: 8 hours, Actual: 12 hours
   - Key challenge: Database migration complexity
   - Lesson: Add 50% buffer for schema changes
   ```

### Developer Integration

**During implementation:**

1. **Search for code patterns:**
   ```
   Query: "Implementation patterns for [functionality]"
   ```

2. **Find testing strategies:**
   ```
   Query: "Testing approaches for [component type]"
   ```

3. **Reference in code comments or commit messages:**
   ```python
   # Using pattern from 2024-04-15-023 (async batch processing)
   # Improved for our use case by adding retry logic
   ```

---

## Search API Usage

### API Endpoint

```
POST /api/v1/search
```

### Request Format

```json
{
  "query": "Your search query here",
  "collection": "jf_private",  // or "jf_docs" for technical documentation
  "limit": 10,
  "score_threshold": 0.5
}
```

### Response Format

```json
{
  "results": [
    {
      "id": "2024-01-15-001",
      "title": "Result title",
      "bluf": "Brief summary",
      "score": 0.85,
      "source_file": "path/to/file.md",
      "tags": ["tag1", "tag2"],
      "cross_references": ["2024-01-10-042"]
    }
  ],
  "total_results": 15,
  "query_time_ms": 42
}
```

### Collection Selection

| Collection | Content | When to Use |
|------------|---------|-------------|
| **jf_private** | Knowledge base (projects, decisions, notes) | Default - finding past work, decisions, patterns |
| **jf_docs** | Technical documentation (APIs, libraries, tools) | Looking up technical references, library usage |

**Multi-collection search:**
```json
{
  "query": "Authentication patterns",
  "collections": ["jf_private", "jf_docs"],
  "limit": 10
}
```

---

## Best Practices

### 1. Search Early, Search Often

**Bad workflow:**
```
1. Start implementing feature
2. Realize similar work exists
3. Refactor to align with existing patterns
```

**Good workflow:**
```
1. Search for similar features/patterns
2. Review existing approaches
3. Implement aligned with established patterns
```

### 2. Document Search Findings

**In development plans:**
```markdown
## Background Research
Searched for: "User profile editing workflows"

Key findings:
- Stellaris profile editor (PLAN-2024-031) used optimistic updates
- Hotel de Ville settings page (PLAN-2024-089) used form validation library
- Pattern: Async state management + validation schemas

Decision: Follow Stellaris pattern (better UX)
```

**In ADRs:**
```markdown
## Considered Alternatives

### Option A: Custom Solution
- No existing implementation found
- Risk: Reinventing wheel

### Option B: Adapt Existing Pattern
- Found pattern in 2024-03-15-012
- Proven in production
- Decision: Adapt existing pattern
```

### 3. Refine Queries Iteratively

If first search doesn't yield results:
1. **Broaden:** Remove specific terms, use higher-level concepts
2. **Narrow:** Add more specific technical terms
3. **Rephrase:** Use synonyms or different phrasing
4. **Try both collections:** Check jf_private AND jf_docs

**Example iteration:**
```
Query 1: "JWT refresh token rotation implementation" → 0 results
Query 2: "JWT authentication patterns" → 5 results (too broad)
Query 3: "JWT token refresh strategy" → 2 relevant results ✓
```

### 4. Maintain Search Context

When switching between tasks, re-search to refresh context:
- Agents don't have persistent memory
- Previous search results aren't cached
- Each decision point deserves fresh search

---

## Common Pitfalls

### Pitfall 1: Over-Relying on Memory

**Wrong:**
```
"I remember we used JWT tokens in Stellaris, so I'll use the same approach"
```

**Right:**
```
Search: "JWT authentication in Stellaris"
Result: Found implementation with refresh token rotation
Action: Review and adapt pattern
```

### Pitfall 2: Searching Too Late

**Wrong:**
```
1. Implement feature completely
2. Search for similar work
3. Realize better approach exists
4. Rewrite
```

**Right:**
```
1. Search for similar work
2. Review existing patterns
3. Implement aligned with findings
```

### Pitfall 3: Ignoring Low-Scoring Results

Sometimes low-scoring results have valuable cross-references:
- Check `cross_references` field even in low-scoring results
- May lead to highly relevant related notes

### Pitfall 4: Not Documenting Negative Results

**Document when search finds nothing:**
```markdown
## Background Research
Searched for: "Real-time audio processing patterns"
Results: No existing implementations found in knowledge base

Decision: This is new ground - document extensively for future reference
```

---

## Integration Checklist

Before starting work on any significant task:

- [ ] Formulated specific search query
- [ ] Searched appropriate collection(s)
- [ ] Reviewed top 3-5 results
- [ ] Checked cross-references
- [ ] Documented findings in plan/ADR/comments
- [ ] Aligned approach with existing patterns (or documented divergence)

---

## Summary

**Semantic search is institutional memory made queryable.**

Use it to:
- **Build on past work** instead of starting from scratch
- **Maintain consistency** across the codebase and documentation
- **Learn from history** to avoid repeating mistakes
- **Accelerate development** by reusing proven patterns

**Key principle:** Search before you start, document what you find, align your work with institutional knowledge.
