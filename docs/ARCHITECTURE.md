# System Architecture

The autonomous orchestration system uses a three-layer architecture with mandatory safety gates.

---

## Overview

```
User → Risk Manager → Portfolio Manager → TPM Orchestrator → Shipped
        (Layer 0)        (Layer 1)           (Layer 2)
```

Each layer has a distinct responsibility and cannot be bypassed.

---

## Layer 0: Risk Manager (MANDATORY)

**Role:** Chief Risk Officer / Compliance Officer

### Purpose

Every plan MUST be assessed for risk before execution. This is enforced via hooks and cannot be skipped.

### Four Risk Dimensions

1. **User Disruption Risk (1-10)**
   - Breaking changes
   - Downtime potential
   - Data loss risk
   - Migration complexity

2. **Controllability Risk (1-10)**
   - Reversibility
   - Oversight capability
   - Critical system exposure
   - Feature flag availability

3. **Liability & Compliance Risk (1-10)**
   - GDPR implications
   - WCAG accessibility
   - Security vulnerabilities
   - Licensing concerns

4. **AI-Specific Risk (1-10)**
   - Bias potential
   - Hallucination risk
   - Privacy concerns
   - Transparency requirements

### Decision Logic

```
Overall Score = Weighted Average of 4 Dimensions

If Overall >= 7 OR Any Dimension >= 8:
    → REQUIRES MANUAL APPROVAL
    → Escalate to user

Else:
    → APPROVED for autonomous execution
    → Proceed to Portfolio Manager
```

### Enforcement

- `SubagentStart(portfolio-manager)` hook injects risk requirements
- `SubagentStart(tpm-orchestrator)` hook verifies assessment exists
- TPM Orchestrator blocks execution without risk approval

---

## Layer 1: Portfolio Manager

**Role:** VP Engineering / CTO

### Purpose

Coordinate multiple plans simultaneously. Handle prioritization, conflict detection, and orchestration.

### Responsibilities

1. **Intake** - Scan `inbox/plans/*.md` for new plans
2. **Risk Invocation** - Call Risk Manager for each plan (mandatory)
3. **Dependency Analysis** - Build dependency graph (blocks/blocked-by)
4. **Conflict Detection** - Identify file contention between plans
5. **Prioritization** - Order by risk, priority, ROI, dependencies
6. **Execution** - Spawn TPM Orchestrators for ready plans
7. **Learning** - Track user overrides to improve decisions
8. **Dashboard** - Update `PORTFOLIO_STATUS.md` in real-time

### Prioritization Criteria

```
1. Explicit priority (critical > high > medium > low)
2. Risk score (lower risk first when equal priority)
3. ROI score (benefit / cost)
4. Dependency blocking (foundations before features)
5. Learned patterns (from user overrides)
```

### Conflict Resolution

When two plans touch the same file:
1. Higher priority wins
2. If equal priority, higher ROI wins
3. If still tied, older plan wins
4. User can override via `/prioritize`

---

## Layer 2: TPM Orchestrator

**Role:** Technical Program Manager (one per plan)

### Purpose

Execute a single plan from start to finish. Coordinate workstreams, enforce quality gates, handle shipping.

### Responsibilities

1. **Parse Plan** - Extract workstreams, agents, files
2. **Parallel Execution** - Spawn workstream agents simultaneously
3. **Quality Gates** - Enforce mandatory checks (cannot skip)
4. **Git Workflow** - Commit, push, create PR
5. **Merge Decision** - Based on risk score
6. **State Update** - Update `.state.json` and dashboard

### Quality Gates

```
1. All workstreams complete ✓
2. Tests pass (pytest) ✓
3. Code review approved ✓
4. Security audit clean ✓
5. Git workflow success ✓
6. Merge decision:
   - Risk 1-3: Auto-merge immediately
   - Risk 4-6: Auto-merge after CI passes
   - Risk 7-10: Manual merge required
```

### Completion Checklist

On completion, TPM must:
1. Update plan status in `.state.json`
2. Move plan to `completed/` folder
3. Update `PORTFOLIO_STATUS.md`

This is enforced by `SubagentStop(tpm-orchestrator)` hook.

---

## Hook Enforcement

| Hook | Target | Purpose |
|------|--------|---------|
| `PreToolUse(Edit\|Write)` | All agents | Inject quality protocols |
| `PostToolUse(Edit\|Write)` | All agents | Remind to test |
| `SubagentStart(portfolio-manager)` | PM | Inject risk requirements |
| `SubagentStart(tpm-orchestrator)` | TPM | Verify risk exists |
| `SubagentStart(shadow-code-reviewer)` | Reviewer | Inject verification protocol |
| `SubagentStop(tpm-orchestrator)` | TPM | Inject completion checklist |

---

## State Management

### Primary State File: `.state.json`

```json
{
  "plans": {
    "PLAN-2025-001": {
      "id": "PLAN-2025-001",
      "title": "Feature Name",
      "status": "QUEUED|EXECUTING|SHIPPED|FAILED",
      "priority": "high",
      "risk_score": 4,
      "risk_status": "APPROVED",
      "file_touchpoints": ["src/file.ts"],
      "dependencies": { "blocks": [], "blocked_by": [] }
    }
  },
  "currently_executing": ["PLAN-2025-001"],
  "queue": ["PLAN-2025-002"],
  "shipped": [],
  "failed": []
}
```

### Learning File: `.conflict_history.json`

Stores conflict resolutions and user overrides to improve future decisions.

### Dashboard: `PORTFOLIO_STATUS.md`

Human-readable markdown dashboard showing portfolio health.

---

## Data Flow

```
1. User creates plan → inbox/plans/PLAN-*.md
2. /add-plan triggers Portfolio Manager
3. Portfolio Manager invokes Risk Manager
4. Risk Manager assesses → appends to plan file
5. Portfolio Manager updates .state.json
6. If ready: PM spawns TPM Orchestrator
7. TPM executes workstreams in parallel
8. TPM enforces quality gates
9. TPM completes git workflow
10. TPM updates state, moves plan to completed/
11. Dashboard auto-updates
```
