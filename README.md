# Autonomous Multi-Plan Orchestration for Claude Code

A production-ready system that lets you submit multiple development plans and have Claude Code execute them autonomously - handling prioritization, dependency resolution, parallel execution, quality gates, and shipping.

**Your role shifts from executor to overseer:** Create plans, submit them, approve high-risk changes. The system handles everything else.

**v1.1 Now with:** State persistence, circuit breakers, secrets scanning, audit trails, cost control, and learning persistence.

---

## Quick Start (3 Steps)

### 1. Copy to Your Project

```bash
# Unzip the package
unzip autonomous-orchestration-v1.0.zip

# Copy .claude directory to your project root
cp -r autonomous-orchestration/.claude /path/to/your/project/

# Copy inbox structure (or customize location)
cp -r autonomous-orchestration/inbox /path/to/your/project/
```

### 2. Initialize State Files

```bash
cd /path/to/your/project

# Rename example files
mv inbox/plans/.state.json.example inbox/plans/.state.json
mv inbox/plans/.conflict_history.json.example inbox/plans/.conflict_history.json
mv inbox/PORTFOLIO_STATUS.md.example inbox/PORTFOLIO_STATUS.md
```

### 3. Create Your First Plan

```bash
# Copy the template
cp inbox/plans/PLAN-TEMPLATE.md inbox/plans/PLAN-2025-001.md

# Edit with your feature details
# Then submit:
/add-plan PLAN-2025-001.md
```

That's it! The Portfolio Manager will analyze, prioritize, and auto-execute your plan.

---

## What's Included

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 10 | Orchestration, development, review, QA leadership |
| **Skills** | 7 | Tests, security, static analysis, dependency vetting, integration |
| **Commands** | 13 | Portfolio, costs, audit, rollback, learning, git override |
| **Protocols** | 6 | Quality gates and safety enforcement |
| **Hooks** | 6 | Secrets scanning, destructive op warnings, quality injection |
| **Scripts** | 1 | Python secrets scanner with pattern detection |
| **Templates** | 3 | Plan and hotfix templates with example |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  You (Plan Creator)                                     │
│  Submit plans via /add-plan                             │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 0: Risk Manager (MANDATORY)                      │
│  Assesses 4 risk dimensions + prompt injection detection│
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Portfolio Manager                             │
│  Prioritizes, detects conflicts, persists state,        │
│  spawns orchestrators, learns from overrides            │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 2: TPM Orchestrator (per plan)                   │
│  Circuit breakers, rebase-and-verify, quality gates     │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 3: QA Lead (5-pass review)                       │
│  Correctness → Standards → Security → Performance → UX  │
└─────────────────────────────────────────────────────────┘
```

---

## Key Commands

### Portfolio Management
| Command | Purpose |
|---------|---------|
| `/add-plan <file>` | Submit plan to queue, trigger auto-execution |
| `/portfolio` | View real-time dashboard |
| `/prioritize <id> <priority>` | Override plan priority |
| `/plan-status <id>` | Detailed status for one plan |
| `/execute-plan <id>` | Force immediate execution |
| `/show-conflicts` | Display resource conflicts |
| `/queue-fix` | Queue a bug fix for background execution |

### Observability & Control
| Command | Purpose |
|---------|---------|
| `/audit [plan-id]` | View audit trail with timestamps |
| `/costs` | View API cost breakdown by plan |
| `/budget-override <amount>` | Authorize additional spend |
| `/learning` | View/export learned preferences |
| `/rollback <plan-id>` | Emergency rollback with verification |
| `/force-git` | Override git safety for edge cases |

---

## Quality Gates (Never Skipped)

Every plan goes through:

1. **Risk Assessment** - Mandatory, scores 1-10, prompt injection detection
2. **Development** - Workstreams execute in parallel with circuit breakers
3. **Static Analysis** - Automated code quality checks
4. **Tests** - pytest/jest with Docker isolation option
5. **Integration Tests** - Cross-component verification
6. **QA Lead Review** - 5-pass review (correctness, standards, security, performance, UX)
7. **Security Audit** - OWASP Top 10 + secrets scanning
8. **Dependency Vetting** - Typosquatting detection for new packages
9. **Git Workflow** - Rebase-and-verify protocol, commit, push, PR
10. **Merge Decision** - Based on risk score:
    - Low (1-3): Auto-merge
    - Medium (4-6): Auto-merge after CI
    - High (7-10): Manual approval required

---

## Production-Ready Features (v1.1)

### Resilience
- **State Persistence** - System recovers from crashes, resumes interrupted plans
- **Circuit Breakers** - 3 fix attempts per issue, 5 total per plan, 60-min timeout
- **Context Summarization** - Handles long-running plans without context overflow
- **Rollback Command** - Emergency recovery with verification

### Security
- **Secrets Scanning** - Hook-enforced before git operations (API keys, passwords, tokens)
- **Dependency Vetting** - Detects typosquatting in package names
- **Prompt Injection Detection** - Sanitizes plan content before execution
- **Destructive Op Warnings** - Alerts for rm -rf, chmod changes

### Observability
- **Audit Trail** - Full logging with timestamps, exportable via `/audit`
- **Cost Control** - Real-time cost tracking via `/costs`, budget overrides
- **Learning Persistence** - System improves from your overrides via `/learning`

### Quality
- **QA Lead Agent** - 5-pass code review (correctness, standards, security, performance, UX)
- **Static Analysis Skill** - Automated linting and code quality
- **Integration Testing** - Cross-component test coordination
- **Docker Isolation** - Secure test execution environment

---

## Important Limitation

**Background execution is session-scoped.**

- `run_in_background=true` runs async within the current Claude session
- If you close the terminal, all agents stop
- Keep your session open until plans complete

**For true persistence:** Use tmux/screen, or run Claude Code as a daemon.

---

## Documentation

- [docs/ABOUT.md](docs/ABOUT.md) - **System overview and design philosophy**
- [SETUP.md](SETUP.md) - Detailed installation guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design
- [docs/AGENTS.md](docs/AGENTS.md) - Agent descriptions
- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - Common patterns
- [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Adaptation guide

---

## License

MIT License - Use freely, modify as needed.

---

## Credits

Built for autonomous development with Claude Code.
