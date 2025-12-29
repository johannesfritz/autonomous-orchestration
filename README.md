# Autonomous Multi-Plan Orchestration for Claude Code

A production-ready system that lets you submit multiple development plans and have Claude Code execute them autonomously - handling prioritization, dependency resolution, parallel execution, quality gates, and shipping.

**Your role shifts from executor to overseer:** Create plans, submit them, approve high-risk changes. The system handles everything else.

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
| **Agents** | 9 | Custom AI agents for orchestration, development, review |
| **Skills** | 4 | Auto-triggered workflows (plan creation, tests, security) |
| **Commands** | 7 | Slash commands for portfolio management |
| **Protocols** | 6 | Quality gates and safety enforcement |
| **Hooks** | 2 | Lifecycle automation scripts |
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
│  Assesses 4 risk dimensions, approves or escalates      │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Portfolio Manager                             │
│  Prioritizes, detects conflicts, spawns orchestrators   │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 2: TPM Orchestrator (per plan)                   │
│  Executes workstreams, enforces quality gates, ships    │
└─────────────────────────────────────────────────────────┘
```

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `/add-plan <file>` | Submit plan to queue, trigger auto-execution |
| `/portfolio` | View real-time dashboard |
| `/prioritize <id> <priority>` | Override plan priority |
| `/plan-status <id>` | Detailed status for one plan |
| `/execute-plan <id>` | Force immediate execution |
| `/show-conflicts` | Display resource conflicts |
| `/queue-fix` | Queue a bug fix for background execution |

---

## Quality Gates (Never Skipped)

Every plan goes through:

1. **Risk Assessment** - Mandatory, scores 1-10
2. **Development** - Workstreams execute in parallel
3. **Tests** - pytest/jest must pass
4. **Code Review** - Agent reviews for production readiness
5. **Security Audit** - OWASP Top 10 scan
6. **Git Workflow** - Commit, push, PR creation
7. **Merge Decision** - Based on risk score:
   - Low (1-3): Auto-merge
   - Medium (4-6): Auto-merge after CI
   - High (7-10): Manual approval required

---

## Important Limitation

**Background execution is session-scoped.**

- `run_in_background=true` runs async within the current Claude session
- If you close the terminal, all agents stop
- Keep your session open until plans complete

**For true persistence:** Use tmux/screen, or run Claude Code as a daemon.

---

## Documentation

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
