# Common Workflows

This guide covers typical usage patterns for the orchestration system.

---

## Workflow 0: Full Discovery Flow

### When to Use

- New feature ideas that need validation
- Features with unclear requirements
- Features that may need UX research
- Major architectural decisions

### The Flow

```
/discovery Add dark mode to the app
```

This triggers the full pipeline:

1. **Product Manager** - Validates user need, calculates ICE score
2. **UX Researcher** - Maps user journey (if UI feature)
3. **Technical PM** - Translates to technical specs, assesses complexity
4. **Spike** (if needed) - Resolves technical unknowns
5. **Solutions Architect** (if needed) - Creates ADR for major decisions
6. **UAT Protocol Designer** - Designs acceptance tests BEFORE development (P1, P12)
   - Maps each acceptance criterion to a `feature_list.json` entry
   - Requires a `test_command` per criterion
7. **create-plan** - Generates development plan + `feature_list.json`

### Shortcuts

```bash
# Skip UX research (backend-only feature)
/discovery --skip-ux Add caching layer

# Skip PM validation (already validated)
/discovery --skip-pm Implement approved design

# Technical-only (skip PM and UX)
/discovery --technical-only Refactor database queries
```

### Individual Commands

```bash
# Process feedback from production DB
/intake

# Prioritize features with scoring
/prioritize-backlog rice

# Technical investigation
/spike Can we use WebSockets for real-time updates?

# Architecture Decision Record
/adr Choose PostgreSQL for relational data
```

---

## Workflow 1: Submit a New Feature

### Step 1: Create the Plan

```bash
# Start from template
cp inbox/plans/PLAN-TEMPLATE.md inbox/plans/PLAN-2025-001.md
```

### Step 2: Fill in Required Sections

```markdown
# Plan: Add User Authentication

**ID:** PLAN-2025-001
**Priority:** high
**Branch:** feature/user-auth

## File Touchpoints
- src/auth/login.ts
- src/api/users.ts
- src/components/LoginForm.tsx

## Definition of Done
- [ ] Login endpoint returns JWT on valid credentials
- [ ] Invalid credentials return 401 with error message
- [ ] Login form submits and stores token
- [ ] Session persists across page reloads

## Workstreams

### Backend API
- Agent: artificial-shadow-dev
- Files: src/auth/login.ts, src/api/users.ts
- Complexity: Medium

### Frontend
- Agent: artificial-shadow-dev
- Files: src/components/LoginForm.tsx
- Complexity: Low
```

### Step 3: Submit

```
/add-plan PLAN-2025-001.md
```

This triggers:
1. Risk assessment (mandatory)
2. **Feature list generation** - Each "Definition of Done" item becomes a feature in `feature_list.json` with status `"failing"` and a `test_command` (P1)
3. Prioritization and queue placement
4. Auto-execution when ready

### Step 4: Monitor

```
/portfolio
/plan-status PLAN-2025-001
```

---

## Workflow 2: Quick Bug Fix

### Option A: Queue for Background Execution

```
/queue-fix
```

System asks for details, creates `HOTFIX-YYYY-NNN.md`, and queues for execution.

### Option B: Manual Hotfix Plan

```bash
cp inbox/plans/HOTFIX-TEMPLATE.md inbox/plans/HOTFIX-2025-001.md
# Edit with fix details
/add-plan HOTFIX-2025-001.md
```

Hotfixes have **critical priority** - they jump the queue.

---

## Workflow 3: Override Priority

When a less-important plan is blocking something urgent:

```
/prioritize PLAN-2025-005 critical
```

This:
1. Updates the plan's priority
2. Records as user override (for learning)
3. Triggers re-analysis
4. May auto-execute if now highest priority

---

## Workflow 4: Force Execute a Specific Plan

Skip the queue and execute immediately:

```
/execute-plan PLAN-2025-003
```

Use when:
- Plan is stuck in queue
- Dependencies resolved manually
- Urgent requirement

---

## Workflow 5: Check Resource Conflicts

```
/show-conflicts
```

Shows:
- Which plans touch the same files
- Proposed execution order
- Reasoning for prioritization

---

## Workflow 6: View Full Dashboard

```
/portfolio
```

Shows:
- Executive summary (plans, shipped, failed, cost)
- Currently executing plans (with feature list progress)
- Queue with priorities
- Recently shipped
- Dependency graph
- Cost analysis
- System health

---

## Workflow 7: Create Plan Interactively

Say something like:

```
"I want to build a user profile page"
```

The `create-plan` skill auto-triggers:
1. Asks clarifying questions
2. Identifies file touchpoints
3. Suggests agents
4. Creates formatted plan
5. **Generates `feature_list.json`** with all acceptance criteria as `"failing"` (P1)
6. Optionally submits to portfolio

---

## Workflow 8: Handle High-Risk Plan

When risk >= 7/10:

1. Portfolio Manager pauses before execution
2. Shows risk assessment with dimensions
3. Lists recommended mitigations
4. Asks for approval

```
PLAN-2025-005 requires your approval

Risk Score: 8/10 (High)
- User Disruption: 6/10
- Controllability: 9/10
- Liability: 8/10

Mitigations:
- Feature flag for gradual rollout
- Security review
- Manual testing

Approve? [yes/no]
```

After approval:
- Plan executes normally
- PR created but requires manual merge (risk >= 7)

---

## Workflow 9: Review Completed Plans

```bash
ls inbox/plans/completed/
```

Each completed plan contains:
- Original requirements
- Risk assessment
- Feature list (all `"passing"`)
- Execution metadata
- PR link
- Cost breakdown

---

## Workflow 10: Multiple Plans in Parallel

Submit several plans:

```
/add-plan PLAN-2025-001.md
/add-plan PLAN-2025-002.md
/add-plan PLAN-2025-003.md
```

Portfolio Manager:
1. Analyzes dependencies
2. Detects file conflicts
3. Prioritizes order
4. Executes non-conflicting plans in parallel

Check parallel execution:

```
/portfolio
# Shows multiple plans in "Currently Executing"
```

---

## Workflow 11: Monitor Feature Progress

Track how a plan's features are progressing:

```bash
# Read the feature list directly
cat inbox/plans/.feature-lists/PLAN-2025-001-features.json

# Or check the progress file (rewritten at each checkpoint)
cat inbox/plans/.progress/PLAN-2025-001-progress.md
```

The feature list shows machine-verifiable status:
```json
{
  "features": [
    { "id": "F1", "description": "Login endpoint returns JWT", "status": "passing" },
    { "id": "F2", "description": "Invalid credentials return 401", "status": "failing" },
    { "id": "F3", "description": "Login form stores token", "status": "failing" }
  ]
}
```

A plan ships only when ALL features are `"passing"` (P3).

---

## Tips

1. **Be specific in plans** - More detail = better execution
2. **List file touchpoints** - Critical for conflict detection
3. **Set realistic priorities** - Not everything is critical
4. **Check dashboard regularly** - Catch issues early
5. **Review completed plans** - Learn from past executions
6. **Write testable acceptance criteria** - Each criterion needs a `test_command` (P1)
7. **Trust the feature list** - JSON status is the source of truth, not Markdown checklists (P3)
