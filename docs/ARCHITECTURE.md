# System Architecture

The autonomous orchestration system uses a multi-layer architecture with mandatory safety gates, research-informed execution patterns, and optional discovery.

---

## Overview

```
┌─────────────────────────────────────────────────────────┐
│  DISCOVERY (Optional)                                   │
│  /discovery or /intake → PM → UX → TPM → UAT → plan    │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  EXECUTION PIPELINE                                     │
│  Risk Manager → Portfolio Manager → TPM Orchestrator    │
│     (Layer 0)        (Layer 1)          (Layer 2)       │
│                                    ┌────────────────┐   │
│                                    │ P1: Feature List│   │
│                                    │ P4: Init Session│   │
│                                    │ P5: Test Output │   │
│                                    │ P6: Attention   │   │
│                                    │ P8: Workstreams │   │
│                                    └────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            ↓
                         Shipped
```

Each layer has a distinct responsibility and cannot be bypassed. The TPM Orchestrator (Layer 2) enforces five research-informed principles during execution.

---

## Foundational Principles

Architecture informed by Cursor's FastRender (Jan 2026) and Anthropic's C compiler (Feb 2026) experiments:

| ID | Principle | Implementation |
|----|-----------|----------------|
| P1 | Specs produce their own checking harness | `feature_list.json` per plan |
| P2 | Constraints beat instructions | Hooks/gates, not "MUST" statements |
| P3 | Machine-readable progress (JSON) | Models resist modifying JSON |
| P4 | Fresh context + environmental memory | `init-session.sh` at session start |
| P5 | AI-optimized test output | `pytest --tb=short --no-header -q` |
| P6 | Attention management | Progress file rewrites at checkpoints |
| P7 | Simplify plumbing, not expertise | 17 expert agents, simple coordination |
| P8 | Filesystem-first coordination | Workstream files on disk |

See [README.md](../README.md) for the full 12-principle table including Tier 3 optimization principles.

---

## Discovery Layer (Optional)

**Purpose:** Bridge user needs to technical implementation

```
User Feedback → Product Manager → UX Researcher → Technical PM → UAT Protocol Designer → Plan
                     ↓                 ↓               ↓                  ↓
                ICE/RICE          User Journey    Tech Spec         Test Design +
                 Score              (WCAG)       + Complexity     feature_list.json
```

### Agents

| Agent | Purpose |
|-------|---------|
| **product-manager** | Voice of Customer, ICE/RICE prioritization |
| **ux-researcher** | User journeys, WCAG 2.1 AA compliance |
| **technical-pm** | Business-to-technical translation |
| **uat-protocol-designer** | Pre-dev test design, feature list mapping (P1, P12) |
| **requirements-analyst** | Detailed requirements extraction, verification checklists |
| **solutions-architect** | ADRs for major decisions |
| **gardener** | Refactoring specialist (DELETE/CONDENSE code) |

### Entry Points

| Command | Purpose |
|---------|---------|
| `/discovery <idea>` | Full pipeline (PM → UX → TPM → UAT → plan) |
| `/intake` | Process feedback from production DB |
| `/spike <question>` | Technical investigation |
| `/adr <decision>` | Architecture Decision Record |
| `/prioritize-backlog` | Apply RICE/ICE/MoSCoW scoring |

### Protocols Injected

- `user-centricity.md` → product-manager
- `technical-translation.md` → technical-pm
- `architectural-documentation.md` → solutions-architect

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

Execute a single plan from start to finish. Coordinate workstreams, enforce quality gates, manage feature list verification, and handle shipping.

### Research-Informed Patterns

The TPM Orchestrator implements five key principles:

#### Feature List Verification (P1, P3)

Before execution begins, the TPM reads `inbox/plans/.feature-lists/{PLAN_ID}-features.json` and verifies all features start as `"failing"`. During execution, features change to `"passing"` only when their `test_command` succeeds. The plan is SHIPPED only when ALL features are `"passing"`.

```
Pre-execution:  Read feature_list.json → verify all "failing"
During:         Run test_command per feature → update status
Post-execution: Verify ALL "passing" → ship
```

#### Session Initialization (P4)

Dev agents receive ground truth via `init-session.sh` at startup. The script surveys: git status, feature list progress, active progress files, and a quick test check. This prevents agents from working on stale assumptions.

#### AI-Optimized Test Output (P5)

Tests use `pytest --tb=short --no-header -q` instead of verbose mode. Only failures are shown, saving agent context window for productive work.

Three test modes:
- **Standard:** `pytest --tb=short --no-header -q` (default)
- **Fast:** `pytest -m fast --tb=line --no-header -q` (rapid iteration)
- **Full:** `pytest -v --tb=short --json-report` (quality gates)

#### Attention Management (P6)

At every significant checkpoint (workstream started, test passing, workstream complete), the TPM rewrites `inbox/plans/.progress/{PLAN_ID}-progress.md`. This forces re-statement of the objective and current status, combating the "lost-in-the-middle" problem where agents forget early objectives during long sessions.

#### Workstream File Protocol (P8)

Instead of embedding instructions in Task tool prompts, the TPM writes workstream files to `inbox/plans/.workstreams/{PLAN_ID}-ws{N}.md` before spawning agents. If the session crashes, context persists on disk. Dev agents read their workstream file + feature_list.json to understand their assignment.

### Responsibilities

1. **Verify Feature List** - Read feature_list.json, confirm all features "failing" (P1)
2. **Write Workstream Files** - Create per-workstream instruction files on disk (P8)
3. **Initialize Agents** - Run init-session.sh for dev agents (P4)
4. **Parallel Execution** - Spawn workstream agents simultaneously
5. **Update Progress** - Rewrite progress file at each checkpoint (P6)
6. **Verify Features** - Run test_commands, update feature status (P3)
7. **Quality Gates** - Enforce mandatory checks (cannot skip)
8. **Git Workflow** - Commit, push, create PR
9. **Merge Decision** - Based on risk score
10. **State Update** - Update `.state.json` and dashboard

### Quality Gates

```
0. Feature list exists with ALL features "failing" (P1) ✓
1. All workstreams complete ✓
2. Tests pass (pytest --tb=short --no-header -q) (P5) ✓
3. UAT verified (Playwright, not checklist) ✓
4. Code review approved ✓
5. Security audit clean ✓
6. Git workflow success ✓
7. CI/CD passes ✓
8. ALL features in feature_list.json are "passing" (P3) ✓
9. Merge decision:
   - Risk 1-3: Auto-merge immediately
   - Risk 4-6: Auto-merge after CI passes
   - Risk 7-10: Manual merge required
```

### Completion Checklist

On completion, TPM must:
1. Verify ALL features are "passing" in feature_list.json
2. Update plan status in `.state.json`
3. Move plan to `completed/` folder
4. Update `PORTFOLIO_STATUS.md`

This is enforced by `SubagentStop(tpm-orchestrator)` hook.

---

## Hook Enforcement

| Hook | Target | Purpose |
|------|--------|---------|
| `PreToolUse(Edit\|Write)` | All agents | Inject quality protocols |
| `PostToolUse(Edit\|Write)` | All agents | Remind to test |
| `SubagentStart(portfolio-manager)` | PM | Inject risk requirements |
| `SubagentStart(tpm-orchestrator)` | TPM | Verify risk + feature list exists |
| `SubagentStart(artificial-shadow-dev)` | Dev | Run init-session.sh (P4) |
| `SubagentStart(shadow-code-reviewer)` | Reviewer | Inject verification protocol |
| `SubagentStop(tpm-orchestrator)` | TPM | Inject completion checklist + feature verification |

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

### Feature List Files: `.feature-lists/{PLAN_ID}-features.json` (P1, P3)

```json
{
  "plan_id": "PLAN-2025-001",
  "created_at": "2026-02-12T10:00:00Z",
  "features": [
    {
      "id": "F1",
      "description": "Login endpoint returns JWT on valid credentials",
      "status": "failing",
      "test_command": "pytest tests/test_auth.py::test_login_success -x",
      "last_verified": null,
      "workstream": "backend-api"
    }
  ]
}
```

Features start as `"failing"` and change to `"passing"` only when `test_command` succeeds. Models resist modifying JSON compared to Markdown, preventing premature victory declarations.

### Workstream Files: `.workstreams/{PLAN_ID}-ws{N}.md` (P8)

Written by TPM before spawning agents. Contains workstream objective, files to modify, feature list references, and test commands.

### Progress Files: `.progress/{PLAN_ID}-progress.md` (P6)

Rewritten at every checkpoint. Forces re-statement of the objective, combating lost-in-the-middle degradation.

### Learning File: `.conflict_history.json`

Stores conflict resolutions and user overrides to improve future decisions.

### Dashboard: `PORTFOLIO_STATUS.md`

Human-readable markdown dashboard showing portfolio health.

---

## Data Flow

```
1.  User creates plan → inbox/plans/PLAN-*.md
2.  /add-plan triggers Portfolio Manager
3.  Portfolio Manager invokes Risk Manager
4.  Risk Manager assesses → appends to plan file
5.  create-plan skill generates feature_list.json (P1)
    → ALL features start as "failing"
6.  Portfolio Manager updates .state.json
7.  If ready: PM spawns TPM Orchestrator
8.  TPM verifies feature_list.json (all "failing") (P1)
9.  TPM writes workstream files to disk (P8)
10. TPM spawns dev agents with init-session.sh (P4)
11. Dev agents execute workstreams in parallel
12. TPM rewrites progress file at each checkpoint (P6)
13. TPM runs test_commands, updates feature status (P3)
14. TPM enforces quality gates (tests use -q flag, P5)
15. TPM verifies ALL features "passing" (P3)
16. TPM completes git workflow
17. TPM updates state, moves plan to completed/
18. Dashboard auto-updates
```

---

## Token Optimization

Rules files use `paths:` frontmatter for conditional loading:

```yaml
---
paths:
  - "**/*test*"
  - "**/tests/**"
---
# Testing Strategy
...
```

This means large rules files only load when relevant files are in context. Three rules use this pattern, saving ~7,400 tokens per non-matching session.

---

## Qdrant Integration (Institutional Memory)

**Purpose:** Use vector database as institutional memory to maintain consistency and build on past work.

### Architecture

```
Documentation/Plans/Notes
         ↓
    FRIDAY Pipeline
         ↓
   Dual Embeddings
   (BLUF + Content)
         ↓
      Qdrant
         ↓
  Semantic Search
         ↓
   Agent Decisions
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **Dual Embeddings** | BLUF (precision) + Content (recall), 3072 dimensions |
| **Versioning Schema** | is_current, is_deleted, file_exists flags |
| **Collections** | jf_private (knowledge), jf_docs (references), documentation (rules) |
| **Sync Automation** | Git hook → CI/CD → Weekly cron (3-layer) |

### Agent Integration

Product Management agents MUST search Qdrant before decisions:
- **Product Manager** → Search for related features, past prioritization
- **Solutions Architect** → Search for related ADRs, patterns
- **Technical PM** → Search for similar plans, complexity estimates

Enforced via `SubagentStart` and `SubagentStop` hooks.

**Full documentation:** [QDRANT-INTEGRATION.md](QDRANT-INTEGRATION.md)

---

## Product Philosophy Alignment

**Purpose:** Ensure AI agents operate according to product values, not just technical requirements.

### Injection Mechanism

Philosophy is injected via `SubagentStart` hooks:

| Agent | Protocol | Purpose |
|-------|----------|---------|
| product-manager | product-philosophy.md | User-facing decisions |
| technical-pm | product-philosophy.md | Requirement translation |
| ux-researcher | product-philosophy.md | User journey design |
| artificial-shadow-dev | product-philosophy.md | UI/UX implementation |
| qa-engineer | product-philosophy.md | User-facing testing |

### Core Principles

- **Journey Over Destination** - Progress, not fixed ability
- **Input Metrics** - Effort (controllable) over outcomes
- **Honest Feedback** - Safe to fail, encouraging language
- **Adaptive Difficulty** - Prevent losing the learner
- **Independence** - No mandatory parental involvement
- **Bauhaus Aesthetics** - Clean, functional design

### Enforcement Layers

1. **SubagentStart hooks** - Automatic protocol injection
2. **Code review** - shadow-code-reviewer checks anti-patterns
3. **SubagentStop hooks** - Verify philosophy alignment
4. **Semantic search** - Philosophy indexed in Qdrant

**Full documentation:** [PRODUCT-PHILOSOPHY.md](PRODUCT-PHILOSOPHY.md)
