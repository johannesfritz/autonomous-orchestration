# Autonomous Multi-Plan Orchestration System - Overview

**Purpose:** This document explains the goal, architecture, and workflow of the autonomous development orchestration system for the Artificial Shadow project.

**Date:** December 29, 2025

---

## Your Goal

You want to **transform your development workflow from manual orchestration to autonomous execution** while maintaining safety and control.

### Current Pain Point

You're running multiple Claude Code agents simultaneously for different development plans, then manually:
- Sequencing their execution
- Running tests
- Coordinating code reviews
- Managing deployments
- Resolving conflicts between plans
- Deciding priorities

**This coordination work is bottlenecking your development velocity.**

### Desired End State

**Your role shifts from executor to overseer:**
- You create development plans (markdown files with what to build)
- You submit them to the system via `/add-plan`
- The system autonomously handles everything else
- You only intervene for high-risk approvals or strategic decisions

**The system handles:**
- Risk assessment (mandatory, cannot be bypassed)
- Dependency analysis (which plans block which)
- File conflict detection (two plans modifying same file)
- Intelligent prioritization (based on risk, priority, ROI, dependencies)
- Parallel execution (independent plans run simultaneously)
- Quality gates (testing, code review, security)
- Git workflow (commit, push, PR creation)
- Auto-merge decisions (based on risk score)
- Learning from your overrides (improves over time)

---

## Three-Layer Architecture Purpose

### Layer 0: Risk Manager (Safety Gate - MANDATORY)

**Real-world role:** Chief Risk Officer

**Why it exists:**
- You need **mandatory risk assessment** before any code ships
- Cannot be bypassed (hook-enforced)
- Ensures you maintain control over high-risk changes

**What it does:**
- Assesses 4 risk dimensions:
  1. **User Disruption** - Breaking changes, downtime, data loss
  2. **Controllability** - Can you reverse it? Oversight possible?
  3. **Liability** - GDPR, WCAG (accessibility), COPPA (children's data), security
  4. **AI-Specific** - Bias, hallucination, privacy, prompt injection
- Calculates overall risk score (1-10, weighted average)
- **Decision:** Auto-approve if < 7/10, escalate to you if ≥ 7/10
- Appends risk assessment to plan file

**Your control:** Plans ≥ 7/10 require your explicit approval. System won't auto-execute without your consent.

---

### Layer 1: Portfolio Manager (Coordination)

**Real-world role:** VP Engineering / CTO

**Why it exists:**
- You're submitting **multiple plans simultaneously**
- Need intelligent sequencing (not just FIFO)
- Need conflict resolution (file contention)
- Need learning system (applies your override patterns)

**What it does:**
- Scans `00 Inbox/plans/*.md` for queued plans
- For each plan:
  - **Invokes Risk Manager** (mandatory, first step)
  - Reads risk assessment results
  - Checks for file conflicts with other plans
  - Analyzes dependencies (blocks/blocked by)
  - Estimates API costs, build time, ROI
- **Prioritizes** based on:
  - Risk score (lower risk goes first when equal priority)
  - Explicit priority (critical > high > medium > low)
  - ROI score (benefit/cost)
  - Dependency blocking (foundations before features)
  - Your learned preferences (from overrides)
- **Auto-executes** ready plans by spawning TPM Orchestrators
- **Learns** from your `/prioritize` overrides to improve future decisions
- **Generates** real-time dashboard showing all plans, conflicts, reasoning

**Your control:**
- Override priority via `/prioritize`
- Force execution via `/execute-plan`
- View reasoning via `/portfolio` dashboard
- System learns your patterns (e.g., "user prefers customer-facing features")

---

### Layer 2: TPM Orchestrator (Execution)

**Real-world role:** Technical Program Manager (one per plan)

**Why it exists:**
- Each plan has **multiple workstreams** (backend, frontend, database, tests)
- Need parallel execution of independent workstreams
- Need enforced quality gates (no skipping tests/review)
- Need risk-aware shipping decisions

**What it does:**
- Reads assigned plan file
- Parses workstreams (what agents to spawn)
- **Executes workstreams in parallel:**
  - Backend API (artificial-shadow-dev)
  - Frontend UI (artificial-shadow-dev)
  - Database schema (hybrid-db-architect)
  - Tests (qa-engineer)
- **Enforces quality gates** (cannot skip):
  1. All workstreams complete
  2. Tests pass (pytest)
  3. Code review approved (shadow-code-reviewer)
  4. Security audit clean (security-audit)
  5. Git workflow success (commit, push, PR)
  6. **Risk-aware merge:**
     - Risk 1-3 (Low): Auto-merge immediately
     - Risk 4-6 (Medium): Auto-merge after CI verification
     - Risk 7-10 (High): Manual merge required (awaits your approval)
- Reports completion to Portfolio Manager

**Your control:** High-risk plans (≥7/10) won't auto-merge. PRs stay open for your manual approval.

---

## Skills and Permissions

### Skills (Auto-Triggered Automation)

**`create-plan`:**
- **Trigger:** You say "I want to build [feature]"
- **Purpose:** Streamlines plan creation
- **What it does:** Interviews you for critical info (files, priority, dependencies), auto-assigns PLAN-YYYY-NNN ID, formats plan, optionally submits to portfolio
- **Why:** Ensures plans have required metadata for orchestration

**`run-test-suite`:**
- **Trigger:** Python files modified
- **Purpose:** Automatic testing
- **What it does:** Detects project, runs pytest, reports results
- **Why:** Quality gate - catches regressions before code review

**`security-audit`:**
- **Trigger:** API endpoints or database queries added/changed
- **Purpose:** Catch vulnerabilities early
- **What it does:** Scans for OWASP Top 10 (SQL injection, XSS, hardcoded secrets, etc.)
- **Why:** Compliance and liability risk mitigation

### Permissions (High Autonomy Mode)

**Pre-approved operations:**
- All Python/Node.js/Git/Docker commands
- File operations within project folder
- Read-only exploration anywhere

**Why:** Eliminates constant confirmation prompts while agents are working. Quality is maintained via:
- PreToolUse hooks (inject quality protocols before every edit)
- PostToolUse hooks (remind to test after changes)
- Quality gates (tests, review, security)

**You still control:** What plans execute (via risk assessment thresholds)

---

## Hooks (Safety Enforcement)

**`SubagentStart (portfolio-manager)`:**
- **Trigger:** When Portfolio Manager agent starts
- **What it does:** Injects `.claude/protocols/risk-assessment-required.md` into context
- **Why:** **Mandatory** - Portfolio Manager MUST invoke Risk Manager for every plan. Cannot be forgotten or skipped.

**`SubagentStart (tpm-orchestrator)`:**
- **Trigger:** When TPM Orchestrator agent starts
- **What it does:** Verifies risk assessment exists in plan file before execution
- **Why:** Double-check - blocks execution if Risk Manager was somehow skipped

**`PreToolUse (Edit|Write)`:**
- **Trigger:** Before any code change
- **What it does:** Injects quality protocols (quality-check.md, code-standards.md)
- **Why:** Ensures code changes follow "Actually Works" protocol and security standards

---

## Your Workflow (As Designed)

### The Happy Path

1. **You:** Have an idea for a feature
2. **You:** Say "I want to build [feature]" → create-plan skill auto-triggers
3. **create-plan:** Interviews you, creates `00 Inbox/plans/PLAN-2025-NNN.md`
4. **You:** `/add-plan PLAN-2025-NNN.md` (or let create-plan auto-submit)
5. **Portfolio Manager:**
   - Invokes Risk Manager (mandatory)
   - Reads risk assessment (e.g., 4/10 - Medium)
   - Checks for conflicts (none found)
   - Adds to queue as READY
   - Auto-executes immediately (spawns TPM Orchestrator)
6. **TPM Orchestrator:**
   - Parses workstreams
   - Spawns agents in parallel
   - Waits for all workstreams to complete
   - Runs tests → pass
   - Runs code review → approved
   - Runs security audit → clean
   - Commits, pushes, creates PR
   - Risk is 4/10 (Medium) → waits 5 min for CI → auto-merges
   - Plan marked as SHIPPED
7. **You:** Check `/portfolio` dashboard → see plan SHIPPED ✅

**Total intervention:** Just creating the plan and submitting it. ~2 minutes of your time.

### The High-Risk Path

1. **You:** Submit a plan that touches authentication system
2. **Portfolio Manager:**
   - Invokes Risk Manager
   - Risk Manager assesses: 8/10 (High) - critical system, affects all users
   - **Decision:** REQUIRES APPROVAL
   - Portfolio Manager marks plan as AWAITING_MANUAL_APPROVAL
   - **Escalates to you:**
     ```
     ⚠️ PLAN-2025-005 requires your approval

     Risk Score: 8/10 (High)
     - User Disruption: 6/10 (affects all users)
     - Controllability: 9/10 (critical auth system)
     - Liability: 8/10 (GDPR, security)

     Mitigations recommended:
     - Feature flag for gradual rollout
     - Security review by external auditor
     - Manual testing with production snapshot

     Approve? [yes/no]
     ```
3. **You:** Review risk assessment, verify mitigations are in plan
4. **You:** "Yes, approved. The mitigations address the concerns."
5. **Portfolio Manager:** Marks plan as READY, auto-executes
6. **TPM Orchestrator:** Executes (same as happy path)
7. **TPM Orchestrator:** PR created, but risk is 8/10 (High) → **does NOT auto-merge**
8. **TPM Orchestrator:** Adds comment to PR: "⚠️ High-risk plan - requires manual merge approval from @johannesfritz"
9. **You:** Review PR, verify quality gates passed, manually merge when ready

**Total intervention:** Initial approval (~5 min) + manual merge review (~10 min). Still way less than manually orchestrating everything.

---

## What You're Trying to Avoid

**❌ Manual Orchestration:**
- "Run agent A for backend"
- "Run agent B for frontend"
- "Wait for both to finish"
- "Run tests manually"
- "Run code review manually"
- "Create PR manually"
- "Decide whether to merge manually"
- Repeat for next plan...

**✅ Autonomous Orchestration:**
- Submit plan
- System handles everything
- You approve high-risk changes
- Done

---

## Why Three Layers?

**One layer (just execute plans)** → No safety, no prioritization, no learning

**Two layers (execute + prioritize)** → No mandatory risk assessment, you lose control

**Three layers (risk + prioritize + execute)** → Safety + intelligence + autonomy

The three layers give you:
- **Safety** (Risk Manager - mandatory gate)
- **Intelligence** (Portfolio Manager - smart sequencing, learning)
- **Throughput** (TPM Orchestrator - parallel execution, quality gates)

---

## Current State vs. Goal

**What's working:**
- Agent structure corrected (single-file .md format)
- Hooks configured (SubagentStart for risk enforcement, SubagentStop for completion)
- Slash commands created
- Documentation comprehensive
- All 5 plans shipped successfully (100% success rate)

**Session Requirement (Important):**
- "Background execution" means async within the current Claude session
- If you close the terminal or Claude Code, background agents stop
- Keep the session active until plans complete
- For true persistence: use tmux/screen, or consider server-side orchestration

**Once set up, you should be able to:**
- `/add-plan PLAN-2025-006.md`
- Portfolio Manager analyzes → Risk Manager assesses → TPM Orchestrator executes
- You monitor via `/portfolio` dashboard
- Only intervene for high-risk approvals
- Keep session active (or use tmux) until execution completes

---

## Key Benefits

1. **90% reduction in coordination overhead** - No more manual orchestration
2. **Role shift from executor to overseer** - Create plans and approve high-risk changes, system handles the rest
3. **Parallel development at scale** - Multiple plans executing simultaneously
4. **Safety with speed** - Mandatory risk assessment but autonomous execution for low/medium risk
5. **Transparency** - Dashboard shows all plans, reasoning for decisions, learning from overrides
6. **Learning system** - Improves over time by learning from your priority overrides

---

## Required Plan Elements

For the system to work, each plan needs:

**Critical (required):**
- **ID** - PLAN-YYYY-NNN format
- **Priority** - critical/high/medium/low
- **File Touchpoints** - List of files to modify (for conflict detection)
- **Dependencies** - Blocks/blocked by which plans

**Helpful (optional):**
- Workstreams (which agents to use)
- Success criteria
- Cost estimation
- Branch name

**Location:** `00 Inbox/plans/PLAN-YYYY-NNN.md`

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/add-plan <file>` | Submit plan to portfolio, trigger analysis and execution |
| `/portfolio` | View real-time dashboard of all plans |
| `/prioritize <id> <priority>` | Override plan priority (teaches system) |
| `/plan-status <id>` | View detailed status for one plan |
| `/execute-plan <id>` | Force immediate execution |
| `/show-conflicts` | View all resource conflicts |

---

**End of Document**