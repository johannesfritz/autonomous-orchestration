# Autonomous Multi-Plan Orchestration System - Overview

**Purpose:** This document explains the goal, architecture, and workflow of the autonomous development orchestration system.

**Version:** 1.1 (Production-Ready)
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
- Risk assessment (mandatory, cannot be bypassed, includes prompt injection detection)
- Dependency analysis (which plans block which)
- File conflict detection (two plans modifying same file)
- Intelligent prioritization (based on risk, priority, ROI, dependencies)
- Parallel execution (independent plans run simultaneously)
- Quality gates (testing, 5-pass code review, security, static analysis)
- Git workflow (rebase-and-verify protocol, commit, push, PR creation)
- Auto-merge decisions (based on risk score)
- Learning from your overrides (improves over time, persisted to disk)
- State persistence (recovers from crashes, resumes interrupted plans)
- Circuit breakers (prevents infinite retry loops)
- Audit trail logging (full traceability with timestamps)
- Cost control (real-time tracking, budget enforcement)

---

## Three-Layer Architecture Purpose

### Layer 0: Risk Manager (Safety Gate - MANDATORY)

**Real-world role:** Chief Risk Officer

**Why it exists:**
- You need **mandatory risk assessment** before any code ships
- Cannot be bypassed (hook-enforced)
- Ensures you maintain control over high-risk changes
- Protects against malicious plan content (prompt injection)

**What it does:**
- **Sanitizes plan content** - Detects and blocks prompt injection attempts
- Assesses 4 risk dimensions:
  1. **User Disruption** - Breaking changes, downtime, data loss
  2. **Controllability** - Can you reverse it? Oversight possible?
  3. **Liability** - GDPR, WCAG (accessibility), COPPA (children's data), security
  4. **AI-Specific** - Bias, hallucination, privacy, prompt injection
- Calculates overall risk score (1-10, weighted average)
- **Decision:** Auto-approve if < 7/10, escalate to you if ≥ 7/10
- Appends risk assessment to plan file

**Prompt Injection Detection:**
- Scans for system prompt overrides ("ignore previous instructions")
- Detects role manipulation attempts
- Identifies encoded/obfuscated instructions
- Blocks plans containing injection patterns

**Your control:** Plans ≥ 7/10 require your explicit approval. System won't auto-execute without your consent.

---

### Layer 1: Portfolio Manager (Coordination)

**Real-world role:** VP Engineering / CTO

**Why it exists:**
- You're submitting **multiple plans simultaneously**
- Need intelligent sequencing (not just FIFO)
- Need conflict resolution (file contention)
- Need learning system (applies your override patterns)
- Need crash recovery (state persistence)

**What it does:**
- Scans `inbox/plans/*.md` for queued plans
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

**State Persistence (v1.1):**
- Saves full portfolio state to `inbox/system_state.json`
- Recovers from crashes - interrupted plans resume automatically
- Tracks learning patterns across sessions
- Maintains audit trail in `inbox/audit_log.jsonl`

**Your control:**
- Override priority via `/prioritize`
- Force execution via `/execute-plan`
- View reasoning via `/portfolio` dashboard
- System learns your patterns (e.g., "user prefers customer-facing features")
- Export learned preferences via `/learning`
- View cost breakdown via `/costs`

---

### Layer 2: TPM Orchestrator (Execution)

**Real-world role:** Technical Program Manager (one per plan)

**Why it exists:**
- Each plan has **multiple workstreams** (backend, frontend, database, tests)
- Need parallel execution of independent workstreams
- Need enforced quality gates (no skipping tests/review)
- Need risk-aware shipping decisions
- Need failure containment (circuit breakers)

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
  2. Static analysis passes
  3. Tests pass (pytest with Docker isolation option)
  4. Integration tests pass
  5. QA Lead review approved (5-pass review)
  6. Security audit clean (security-audit + secrets scanning)
  7. Dependency vetting (typosquatting check)
  8. Git workflow success (rebase-and-verify, commit, push, PR)
  9. **Risk-aware merge:**
     - Risk 1-3 (Low): Auto-merge immediately
     - Risk 4-6 (Medium): Auto-merge after CI verification
     - Risk 7-10 (High): Manual merge required (awaits your approval)
- Reports completion to Portfolio Manager

**Circuit Breakers (v1.1):**
- **3 fix attempts** per individual issue before escalating
- **5 total fix cycles** per plan before marking as BLOCKED
- **60-minute timeout** - plan marked as STALLED if exceeded
- **Context summarization** - compresses history for long-running plans

**Rebase-and-Verify Protocol:**
- Fetches latest from main before merge
- Rebases feature branch cleanly
- Re-runs critical tests after rebase
- Only proceeds if tests still pass

**Your control:** High-risk plans (≥7/10) won't auto-merge. PRs stay open for your manual approval. Use `/rollback` for emergency recovery.

---

### Layer 3: QA Lead (5-Pass Review)

**Real-world role:** Quality Assurance Lead

**Why it exists:**
- Need comprehensive, multi-dimensional code review
- Single-pass review misses category-specific issues
- Need consistent quality standards across all plans

**What it does - 5-Pass Review:**
1. **Correctness Pass** - Logic errors, edge cases, error handling
2. **Standards Pass** - Code style, naming conventions, documentation
3. **Security Pass** - OWASP vulnerabilities, injection risks, auth issues
4. **Performance Pass** - N+1 queries, memory leaks, algorithmic complexity
5. **UX Pass** - Error messages, loading states, accessibility

**Blocking criteria:**
- Any critical issue in any pass blocks the plan
- Issues categorized by severity (critical/major/minor)
- Plan author notified with specific fix instructions

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
- **What it does:** Detects project, runs pytest with optional Docker isolation, reports results
- **Why:** Quality gate - catches regressions before code review

**`security-audit`:**
- **Trigger:** API endpoints or database queries added/changed
- **Purpose:** Catch vulnerabilities early
- **What it does:** Scans for OWASP Top 10 (SQL injection, XSS, hardcoded secrets, etc.)
- **Why:** Compliance and liability risk mitigation

**`static-analysis` (v1.1):**
- **Trigger:** Code changes in Python/TypeScript files
- **Purpose:** Automated code quality
- **What it does:** Runs linters (ruff, mypy, eslint), reports issues with fix suggestions
- **Why:** Consistent code quality, catches common errors early

**`dependency-vetting` (v1.1):**
- **Trigger:** New package added to requirements.txt or package.json
- **Purpose:** Supply chain security
- **What it does:** Checks for typosquatting (e.g., "requets" vs "requests"), known vulnerabilities
- **Why:** Prevents malicious package installation

**`integration-testing` (v1.1):**
- **Trigger:** Cross-component changes detected
- **Purpose:** End-to-end verification
- **What it does:** Runs integration test suite, verifies component interactions
- **Why:** Catches issues that unit tests miss

**`queue-fix`:**
- **Trigger:** Bug fix or hotfix request
- **Purpose:** Background fix execution
- **What it does:** Converts fix request to HOTFIX plan, queues for autonomous execution
- **Why:** Frees command line for other work

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

### PreToolUse Hooks

**`Edit|Write`:**
- **Trigger:** Before any code change
- **What it does:** Injects quality protocols (quality-check.md, code-standards.md)
- **Why:** Ensures code changes follow "Actually Works" protocol and security standards

**`git add/commit` (v1.1):**
- **Trigger:** Before staging or committing files
- **What it does:** Runs secrets scanner (scan-secrets.py)
- **Why:** Prevents accidental commit of API keys, passwords, tokens

**`git push` (v1.1):**
- **Trigger:** Before pushing to remote
- **What it does:** Displays pre-push warning about secrets
- **Why:** Final checkpoint before code leaves local machine

**`rm -rf` (v1.1):**
- **Trigger:** Before recursive deletion
- **What it does:** Displays destructive operation warning
- **Why:** Prevents accidental deletion of important directories

**`chmod` (v1.1):**
- **Trigger:** Before permission changes
- **What it does:** Displays permission change warning
- **Why:** Alerts to potentially dangerous permission modifications

### SubagentStart Hooks

**`portfolio-manager`:**
- **Trigger:** When Portfolio Manager agent starts
- **What it does:** Injects `.claude/protocols/risk-assessment-required.md` into context
- **Why:** **Mandatory** - Portfolio Manager MUST invoke Risk Manager for every plan. Cannot be forgotten or skipped.

**`tpm-orchestrator`:**
- **Trigger:** When TPM Orchestrator agent starts
- **What it does:** Verifies risk assessment exists in plan file before execution
- **Why:** Double-check - blocks execution if Risk Manager was somehow skipped

**`shadow-code-reviewer`:**
- **Trigger:** When code reviewer agent starts
- **What it does:** Injects functional verification protocol
- **Why:** Ensures code review includes functional testing requirements

---

## Your Workflow (As Designed)

### The Happy Path

1. **You:** Have an idea for a feature
2. **You:** Say "I want to build [feature]" → create-plan skill auto-triggers
3. **create-plan:** Interviews you, creates `inbox/plans/PLAN-2025-NNN.md`
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

**Location:** `inbox/plans/PLAN-YYYY-NNN.md`

---

## Slash Commands

### Portfolio Management

| Command | Purpose |
|---------|---------|
| `/add-plan <file>` | Submit plan to portfolio, trigger analysis and execution |
| `/portfolio` | View real-time dashboard of all plans |
| `/prioritize <id> <priority>` | Override plan priority (teaches system) |
| `/plan-status <id>` | View detailed status for one plan |
| `/execute-plan <id>` | Force immediate execution |
| `/show-conflicts` | View all resource conflicts |
| `/queue-fix` | Queue a bug fix for background execution |

### Observability & Control (v1.1)

| Command | Purpose |
|---------|---------|
| `/audit [plan-id]` | View audit trail with timestamps, filter by plan |
| `/costs` | View API cost breakdown by plan, cumulative totals |
| `/budget-override <amount>` | Authorize additional spend beyond default limits |
| `/learning` | View/export learned preferences from your overrides |
| `/rollback <plan-id>` | Emergency rollback with pre-rollback verification |
| `/force-git` | Override git safety checks for edge cases |

---

## Key Benefits

1. **90% reduction in coordination overhead** - No more manual orchestration
2. **Role shift from executor to overseer** - Create plans and approve high-risk changes, system handles the rest
3. **Parallel development at scale** - Multiple plans executing simultaneously
4. **Safety with speed** - Mandatory risk assessment but autonomous execution for low/medium risk
5. **Transparency** - Dashboard shows all plans, reasoning for decisions, learning from overrides
6. **Learning system** - Improves over time by learning from your priority overrides
7. **Crash recovery** - State persistence ensures interrupted plans resume automatically
8. **Cost visibility** - Real-time tracking of API costs per plan
9. **Audit trail** - Full traceability for compliance and debugging
10. **Security-first** - Secrets scanning, dependency vetting, prompt injection detection

---

**End of Document**