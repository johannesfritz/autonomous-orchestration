# Autonomous Multi-Plan Orchestration

**New capability as of 2025-12-28:** Claude Code can now autonomously manage multiple development plans in parallel using a two-layer orchestration system.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Architecture Overview](#architecture-overview)
- [Layer 1: Portfolio Manager](#layer-1-portfolio-manager)
- [Layer 2: TPM Orchestrator](#layer-2-tpm-orchestrator)
- [Layer 0: Risk Manager (MANDATORY SAFETY GATE)](#layer-0-risk-manager-mandatory-safety-gate)
- [Development Plan Structure](#development-plan-structure)
- [Resource Management](#resource-management)
  - [1. File Contention (Primary Constraint)](#1-file-contention-primary-constraint)
  - [2. Dependency Sequencing](#2-dependency-sequencing)
  - [3. API Rate Limits](#3-api-rate-limits)
- [Workflow: User Perspective](#workflow-user-perspective)
- [Cost/Benefit Analysis](#costbenefit-analysis)
- [Learning System](#learning-system)
- [Dashboard Monitoring](#dashboard-monitoring)
- [Slash Commands](#slash-commands)
- [Escalation Criteria](#escalation-criteria)
- [Getting Started](#getting-started)
- [Example Plan](#example-plan)
- [State Files](#state-files)
- [Multi-Plan Benefits](#multi-plan-benefits)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Architecture Overview

```
User (Plan Creator)
    ↓
Portfolio Manager (VP Engineering role)
    ├─→ TPM Orchestrator #1 (PLAN-001)
    │     ├─→ artificial-shadow-dev (backend)
    │     ├─→ artificial-shadow-dev (frontend)
    │     └─→ hybrid-db-architect (database)
    ├─→ TPM Orchestrator #2 (PLAN-002)
    │     └─→ qa-engineer (tests)
    └─→ TPM Orchestrator #3 (PLAN-003)
          └─→ shadow-code-reviewer (review)
```

## Layer 1: Portfolio Manager

**Real-world role:** VP Engineering / Engineering Manager / CTO
**Location:** `.claude/agents/portfolio-manager.md`

**Responsibilities:**
- Intake multiple plans simultaneously from `00 Inbox/plans/*.md`
- Build dependency graphs (which plans block which)
- Detect resource contention (file conflicts, branch conflicts)
- Estimate costs and benefits (API costs, build time, ROI)
- Prioritize plan execution intelligently
- Auto-execute ready plans (no manual approval needed)
- Learn conflict resolution patterns from user overrides
- Generate real-time dashboard at `00 Inbox/PORTFOLIO_STATUS.md`

**Key behaviors:**
- **FIRE-AND-FORGET:** Spawns ALL ready TPMs at once, returns immediately
- **NEVER ASKS:** Zero permission requests, zero confirmation dialogs
- **NO TRACKING:** Does NOT use TodoWrite (that blocks the command line)
- **PARALLEL:** All ready plans spawn in ONE message for max parallelism

**Execution timing:** The Task tool is synchronous (waits for completion), so command line is occupied while TPMs execute. However, multiple Task calls in ONE message run IN PARALLEL, minimizing total execution time. **The Task tool CAN and MUST be used to spawn TPM orchestrators - this capability is proven and working.**

## Layer 2: TPM Orchestrator

**Real-world role:** Technical Program Manager (per-plan)
**Location:** `.claude/agents/tpm-orchestrator/`

**Responsibilities:**
- Execute a single assigned plan from start to finish
- Coordinate multiple workstreams within that plan
- Spawn workstream agents in parallel (independent work)
- Enforce quality gates: Dev → Tests → Review → Security → Ship
- Handle git workflow (commit, push, PR creation)
- Report completion back to Portfolio Manager

**Quality gates (never skipped):**
1. ✅ All workstreams complete
2. ✅ Tests pass (pytest)
3. ✅ Code review approved (shadow-code-reviewer)
4. ✅ Security audit clean (security-audit)
5. ✅ Git workflow success (commit, push, PR)
6. ✅ **Risk-aware auto-merge:**
   - 🟢 Low risk (1-3): Auto-merge immediately
   - 🟡 Medium risk (4-6): Auto-merge after CI verification
   - 🔴 High risk (7-10): Manual merge required (awaits your approval)

## Layer 0: Risk Manager (MANDATORY SAFETY GATE)

**Real-world role:** Chief Risk Officer / Compliance Officer / Security Lead
**Location:** `.claude/agents/risk-manager/`

**CRITICAL:** Risk Manager invocation is **MANDATORY** and enforced via hooks. Portfolio Manager cannot skip this step.

**Responsibilities:**
- Assess all four risk dimensions for every plan:
  1. **User Disruption Risk** (1-10): Breaking changes, downtime, data loss
  2. **Controllability Risk** (1-10): Reversibility, oversight, critical systems
  3. **Liability & Compliance Risk** (1-10): GDPR, WCAG, COPPA, security
  4. **AI-Specific Risk** (1-10): Bias, hallucination, privacy, transparency
- Calculate overall risk score (weighted average)
- Determine approval requirements (auto-approve if < 7/10, else escalate)
- Recommend risk mitigations (feature flags, testing, compliance checks)
- Append risk assessment to plan file

**Escalation threshold:**
- **Overall risk ≥ 7/10** → Requires Johannes approval
- **Any dimension ≥ 8/10** → Requires Johannes approval
- **Critical systems** (auth, payments, data) → Always requires approval
- **Irreversible operations** → Always requires approval

**Hook enforcement:**
- `SubagentStart(portfolio-manager)` → Injects `.claude/protocols/risk-assessment-required.md`
- `SubagentStart(tpm-orchestrator)` → Verifies risk assessment exists
- Portfolio Manager MUST invoke Risk Manager for every plan
- TPM Orchestrator MUST check risk approval before execution

**Example risk assessment output:**
```markdown
## Risk Assessment
**Overall Risk Score:** 4/10 (Medium) 🟡

- User Disruption: 3/10 (Low)
- Controllability: 2/10 (Low)
- Liability: 5/10 (Medium)
- AI Risk: 1/10 (Low)

✅ APPROVED for autonomous execution
Conditions: WCAG compliance, licensing verification, feature flag
```

## Development Plan Structure

Plans are stored in `00 Inbox/plans/PLAN-YYYY-NNN.md` with this structure:

```markdown
# Plan: [Feature Name]
**ID:** PLAN-2025-001
**Priority:** critical|high|medium|low
**Branch:** feature/descriptive-name
**Dependencies:** Blocks/Blocked by other plans
**File Touchpoints:** List of all files to be modified

## Workstreams
Each workstream specifies:
- Agent to use (artificial-shadow-dev, hybrid-db-architect, etc.)
- Files to modify
- Complexity (low|medium|high)
- Detailed requirements

## Success Criteria
What must be true for plan to be complete

## Cost Estimation
API costs, build time, user benefit, ROI
```

See `00 Inbox/plans/PLAN-TEMPLATE.md` for full template.

## Resource Management

The Portfolio Manager detects and resolves these resource constraints:

### 1. File Contention (Primary Constraint)
```
PLAN-002 modifies: hotel-de-ville/components/UserHeader.tsx
PLAN-003 modifies: hotel-de-ville/components/UserHeader.tsx
→ CONFLICT: Must execute sequentially
```

**Resolution:** Portfolio Manager proposes winner based on:
- Explicit priority (critical > high > medium > low)
- ROI score (benefit / cost)
- Dependency blocking (plans that unblock others go first)
- User overrides (learned patterns)

### 2. Dependency Sequencing
```
PLAN-001 (Auth System) → PLAN-002 (User Profiles)
                       → PLAN-003 (Settings UI)
```

Plans with blocking dependencies execute first. Independent plans run in parallel.

### 3. API Rate Limits
Portfolio Manager monitors Claude API usage and throttles parallel execution if needed.

## Workflow: User Perspective

**Before (Manual Orchestration):**
1. User creates 5 development plans
2. User manually spawns agents for each plan
3. User tracks progress manually
4. User manually runs tests, reviews, deployments
5. User resolves conflicts manually

**After (Autonomous Orchestration):**
1. User creates 5 development plans (markdown files)
2. User runs `/add-plan` for each (or Portfolio Manager auto-scans)
3. **Portfolio Manager autonomously:**
   - Analyzes dependencies and conflicts (fast, ~30 seconds)
   - Spawns ALL ready TPM orchestrators in ONE message (parallel execution)
   - TPMs execute in parallel - total time = slowest plan, not sum
   - Each TPM handles quality gates independently
   - Ships completed plans
4. User only intervenes for high-risk plans (risk ≥ 7)

**Note:** Command line is occupied during TPM execution (SDK limitation), but all plans run in parallel so total time is minimized. No progress bars or prompts - just execution.

## Cost/Benefit Analysis

Each plan includes cost estimation:

```markdown
**Estimated API cost:** $3.50
- Claude Sonnet: 25 requests × $0.10 = $2.50
- OpenAI embeddings: 40 chunks × $0.0001 = $0.004

**Estimated build time:** 9 hours
**User benefit:** High - Critical feature
**ROI:** ★★★★★ (5 stars)
```

**Portfolio Manager uses ROI for prioritization:**
- High ROI plans execute first (when priorities are equal)
- Cost estimates help user make trade-off decisions
- Dashboard shows total portfolio cost

**At current API pricing (Dec 2025), most plans are highly cost-effective** (ROI > 2.0).

## Learning System

Portfolio Manager learns conflict resolution patterns from user overrides:

**Example learning cycle:**
1. Conflict: PLAN-002 vs PLAN-003 (same file)
2. Portfolio Manager proposes: Execute PLAN-002 first (higher priority)
3. User overrides: `/prioritize PLAN-003 critical` (customer-facing feature)
4. Portfolio Manager records: "User prioritizes customer-facing over internal tools"
5. Future conflicts: Portfolio Manager applies learned pattern automatically

**Learning data stored in:** `00 Inbox/plans/.conflict_history.json`

## Dashboard Monitoring

Real-time dashboard at `00 Inbox/PORTFOLIO_STATUS.md` shows:

- **Pipeline overview:** All plans, status, progress, cost, ROI, ETA
- **Dependency graph:** Visual representation of blocking relationships
- **Resource contention:** File conflicts and proposed resolutions
- **Currently executing:** Live progress for each plan's workstreams
- **Next in queue:** Plans ready to auto-execute
- **Cost analysis:** Total portfolio cost, per-plan breakdown
- **Learning insights:** Patterns learned from user overrides

**View dashboard:** `/portfolio` (updates automatically)

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/portfolio` | Show portfolio dashboard |
| `/add-plan <file>` | Add new plan to queue and auto-execute if ready |
| `/prioritize <id> <priority>` | Override plan priority (critical/high/medium/low) |
| `/plan-status <id>` | Show detailed status for one plan |
| `/execute-plan <id>` | Force-execute specific plan immediately |
| `/show-conflicts` | Display all resource conflicts |

## Escalation Criteria

**Portfolio Manager escalates to user when:**
- Ambiguous conflicts (identical priority, ROI, no clear winner)
- Circular dependencies detected (Plan A → B → A)
- Critical plan fails tests/review
- API rate limits exceeded (need throttling guidance)
- User explicitly marked plan "needs approval"

**Portfolio Manager does NOT escalate for:**
- Clear priority differences (just execute higher priority)
- File conflicts with obvious winners (auto-resolve based on criteria)
- Minor test failures (retry automatically)
- Routine execution decisions (that's the point of autonomy!)

## Getting Started

1. **Copy the template:**
   ```bash
   cp "00 Inbox/plans/PLAN-TEMPLATE.md" "00 Inbox/plans/PLAN-2025-001.md"
   ```

2. **Fill in plan details:**
   - Objectives, workstreams, file touchpoints
   - Dependencies, success criteria
   - Cost/benefit estimates

3. **Add to portfolio:**
   ```bash
   /add-plan PLAN-2025-001.md
   ```

4. **Portfolio Manager automatically:**
   - Analyzes the plan (~30 seconds)
   - Checks for conflicts and risk
   - Spawns TPM orchestrator immediately (no asking!)
   - All ready plans execute in parallel

## Example Plan

See `00 Inbox/plans/PLAN-2025-001-EXAMPLE.md` for a complete example (audio pronunciation training for Stellaris app).

## State Files

Portfolio Manager uses these files for tracking:

- `00 Inbox/plans/.state.json` - Plan states (queued, executing, completed)
- `00 Inbox/plans/.conflict_history.json` - Conflict resolution learning
- `00 Inbox/PORTFOLIO_STATUS.md` - Real-time dashboard (auto-updated)
- `00 Inbox/plans/completed/` - Completed plans (auto-moved)

**All state files are auto-generated.** No manual editing required.

## Multi-Plan Benefits

**Autonomy:**
- User role reduces to plan creation + strategic oversight
- No manual coordination, testing, or deployment
- 90% reduction in coordination overhead

**Parallelism:**
- Independent plans execute simultaneously
- Dependency-aware sequencing (foundations before features)
- Maximum throughput within resource constraints

**Learning:**
- System improves over time (learns user preferences)
- Conflict resolution becomes more accurate
- Less user intervention needed as patterns emerge

**Transparency:**
- Real-time dashboard shows all plan states
- Clear reasoning for all prioritization decisions
- Audit trail for user overrides

**Cost awareness:**
- Every plan includes cost/benefit analysis
- Portfolio dashboard shows total costs
- ROI-based prioritization (value-driven development)
