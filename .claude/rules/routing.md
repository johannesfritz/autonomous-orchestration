# Sub-Agent Routing Rules

This document defines when to execute directly, delegate to agents, or dispatch to background.

## Routing Decision Framework

```
Request received
    │
    ├─ Simple & Bounded? ────────────────────→ DIRECT EXECUTION
    │   (single file, quick fix, research)
    │
    ├─ Multi-step but Interactive? ──────────→ SEQUENTIAL AGENTS
    │   (needs user input, incremental)        (agent → agent → agent)
    │
    └─ Complex Development Work? ────────────→ BACKGROUND VIA PORTFOLIO
        (feature, refactor, multi-file)        (Portfolio → TPM → workstreams)
```

## 1. Direct Execution (No Agents)

Execute directly when ALL conditions are met:
- Single file or 2-3 closely related files
- Clear, bounded scope
- Quick completion (<5 minutes estimated)
- No shared state concerns
- Research or information gathering

**Examples:**
- Fix typo in README
- Add single function to existing module
- Search codebase for pattern
- Read and explain code
- Simple refactoring within one file

## 2. Sequential Agent Dispatch

Dispatch sequentially when ANY condition applies:
- Tasks have dependencies (B needs output from A)
- Shared files or state (merge conflict risk)
- User input required between steps
- Unclear scope requiring investigation first

**Common Sequential Chains:**

| Chain | Why Sequential |
|-------|----------------|
| Research → Planning → Implementation | Understanding before execution |
| Schema → API → Frontend | Data structure must exist first |
| Implementation → Testing → Review | Build, validate, then audit |
| Product Manager → Technical PM → create-plan | Requirements before specs |

**Dispatch pattern:**
```
Agent A completes → Review output → Agent B starts → ...
```

## 3. Parallel Agent Dispatch

Dispatch in parallel when ALL conditions are met:
- 3+ unrelated tasks or independent domains
- No shared state between tasks
- Clear file boundaries with no overlap
- All can proceed without waiting for others

**Examples:**
- Update documentation across 3 independent projects
- Run security audit + dependency check + static analysis
- Research 3 different approaches simultaneously

**Dispatch pattern:**
```
Launch Agent A, Agent B, Agent C simultaneously
Wait for all to complete
Synthesize results
```

## 4. Background Dispatch via Portfolio Manager (PRIMARY PATTERN)

**This is the preferred pattern for development work.**

Dispatch to Portfolio Manager for background execution when ANY applies:
- New feature implementation
- Multi-file refactoring
- Database schema changes
- API endpoint additions
- Frontend component development
- Bug fixes requiring investigation
- Any work that would take >10 minutes

**Why Background:**
- **Terminal clearance** - User can continue with other instructions
- **Autonomous execution** - TPM orchestrators handle quality gates
- **Parallel workstreams** - Multiple plans execute concurrently
- **Robust QA** - Built-in testing, review, and UAT requirements

### Background Dispatch Pattern

```
User Request
    │
    ▼
Portfolio Manager (background)
    │
    ├─ Risk Assessment (Layer 0)
    │   └─ Risk ≥7 → Requires approval
    │
    ├─ Conflict Detection
    │   └─ File overlaps → Sequential execution
    │
    └─ TPM Orchestrator(s) spawned (background)
        │
        ├─ Workstream 1 ────→ Development
        ├─ Workstream 2 ────→ Development
        └─ Workstream N ────→ Development
            │
            ▼
        Quality Gates (MANDATORY)
            ├─ Tests pass (pytest/Playwright)
            ├─ Code review (shadow-code-reviewer)
            ├─ Security audit
            ├─ UAT verification
            └─ Risk-aware merge
```

### Triggering Background Execution

**Option A: Create plan and auto-submit**
```
/add-plan "Feature description"
```

**Option B: Queue fix for background**
```
/queue-fix "Bug description"
```

**Option C: Portfolio Manager direct**
```
Task tool → portfolio-manager agent → run_in_background=true
```

### Diligence-First Quality Gates

Background execution does NOT mean lower quality. TPM orchestrators enforce:

1. **Pre-Execution Gates**
   - Risk assessment completed
   - Dependencies resolved
   - No blocking conflicts

2. **Development Gates**
   - Tests written for new code
   - Type annotations complete
   - No magic numbers/strings

3. **Post-Development Gates**
   - `pytest` passes (0 failures)
   - `npm run build` succeeds
   - Playwright E2E tests pass
   - shadow-code-reviewer approves
   - Security audit clean

4. **UAT Gates (MANDATORY)**
   - Local stack verification
   - User journey walkthrough
   - Edge case testing
   - Screenshot evidence captured

5. **Deployment Gates**
   - Risk-aware merge (auto for low/medium, manual for high)
   - CI/CD verification
   - Documentation updated

### Monitoring Background Work

Check status without blocking terminal:
```
/portfolio          # Overview of all plans
/plan-status PLAN-ID  # Specific plan details
```

Read output files:
```
Read tool → 00 Inbox/plans/.logs/PLAN-*.log
```

## Routing Examples

### Example 1: "Fix the login button color"
**Route:** Direct Execution
**Reason:** Single file, bounded scope, quick fix

### Example 2: "Add user authentication to the app"
**Route:** Background via Portfolio Manager
**Reason:** Multi-file, architectural decision, needs tests

### Example 3: "What does the auth middleware do?"
**Route:** Direct Execution
**Reason:** Research/information gathering

### Example 4: "Implement dark mode, update documentation, and add tests"
**Route:** Background via Portfolio Manager
**Reason:** Multiple workstreams, parallel execution opportunity

### Example 5: "First research the options, then implement the best one"
**Route:** Sequential (Research agent → then Background Portfolio)
**Reason:** User needs to review before committing to implementation

## Summary

| Request Type | Route | Quality Gates |
|--------------|-------|---------------|
| Quick fix, research | Direct | Standard |
| Dependent steps | Sequential Agents | Per-agent protocols |
| Independent tasks | Parallel Agents | Per-agent protocols |
| Development work | **Background Portfolio** | **Full TPM gates + UAT** |

**Default to Background Portfolio for development.** This clears your terminal while maintaining rigorous quality standards through autonomous TPM orchestration.
