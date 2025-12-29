# Common Workflows

This guide covers typical usage patterns for the orchestration system.

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

## Objectives
- [ ] Implement login endpoint
- [ ] Create login form component
- [ ] Add session management

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
- Currently executing plans
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
5. Optionally submits to portfolio

---

## Workflow 8: Handle High-Risk Plan

When risk >= 7/10:

1. Portfolio Manager pauses before execution
2. Shows risk assessment with dimensions
3. Lists recommended mitigations
4. Asks for approval

```
⚠️ PLAN-2025-005 requires your approval

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

## Tips

1. **Be specific in plans** - More detail = better execution
2. **List file touchpoints** - Critical for conflict detection
3. **Set realistic priorities** - Not everything is critical
4. **Check dashboard regularly** - Catch issues early
5. **Review completed plans** - Learn from past executions
