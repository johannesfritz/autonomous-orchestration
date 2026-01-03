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
| **Agents** | 14 | Custom AI agents for orchestration, development, review, product management |
| **Skills** | 12 | Auto-triggered workflows (plan creation, tests, security, discovery) |
| **Commands** | 19 | Slash commands for portfolio and discovery management |
| **Protocols** | 10 | Quality gates, safety enforcement, and PM protocols |
| **Hooks** | 3 | Lifecycle automation scripts (plus inline hooks in settings.json) |
| **Scripts** | 8 | Shell/Python utilities (indexing, search, secrets, change detection) |
| **Rules** | 9 | Modular documentation (architecture, patterns, testing, etc.) |
| **Templates** | 3 | Plan and hotfix templates with example |

---

## Product Management Team (NEW)

The system now includes a complete discovery-to-delivery pipeline:

```
User Feedback / Feature Ideas
           │
           ▼
┌─────────────────────┐
│ /intake             │  Process feedback from production DB
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Product Manager     │  Validate needs, prioritize (ICE/RICE)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ UX Researcher       │  User journeys, WCAG 2.1 AA compliance
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Technical PM        │  Translate to technical specs
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Solutions Architect │  ADRs for major decisions
└──────────┬──────────┘
           ▼
    EXECUTION PIPELINE
```

Use `/discovery <idea>` to run the full flow, or individual commands for specific phases.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  You (Plan Creator)                                     │
│  Submit plans via /add-plan or /discovery               │
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
| `/audit [plan-id]` | View audit trail and event history |
| `/costs` | View API cost tracking and budget status |
| `/budget-override` | Override daily/session budget limits |
| `/learning` | View and manage learned priority patterns |
| `/rollback <plan-id>` | Rollback a deployed plan |
| `/force-git` | Bypass git safeguards (use with caution) |
| `/sync-state` | Reconcile state files with git truth |
| `/discovery <idea>` | Full discovery flow (PM -> UX -> TPM -> plan) |
| `/intake` | Process user feedback from production DB |
| `/spike <question>` | Technical investigation |
| `/adr <decision>` | Create Architecture Decision Record |
| `/prioritize-backlog` | Apply RICE/ICE/MoSCoW scoring |

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

## Qdrant Integration (Institutional Memory)

The system supports optional Qdrant vector database integration for:

- **Semantic search** across documentation, plans, and decisions
- **Institutional memory** - agents search past work before making decisions
- **Consistency enforcement** - verify alignment with established patterns

**Key features:**
- Dual embeddings (BLUF + content) for high-quality retrieval
- Versioning schema (is_current, is_deleted, file_exists)
- Three-layer sync automation (git hook, CI/CD, weekly cron)
- Mandatory search protocol for PM/TPM/SA agents

See [docs/QDRANT-INTEGRATION.md](docs/QDRANT-INTEGRATION.md) for setup.

---

## Product Philosophy Alignment

Agents follow product values through automated protocol injection:

- **Journey over destination** - Progress metaphors, not fixed ability
- **Input metrics** - Measure effort (controllable), not outcomes
- **Honest feedback** - Safe to fail, encouraging language
- **Adaptive difficulty** - Prevent losing the learner

**Enforcement:**
- `SubagentStart` hooks inject philosophy into relevant agents
- Code review checks for anti-patterns (ability scores, harsh feedback)
- Philosophy indexed in Qdrant for semantic search

See [docs/PRODUCT-PHILOSOPHY.md](docs/PRODUCT-PHILOSOPHY.md) for details.

---

## Important Limitation

**All execution is session-scoped.**

- The Task tool is SYNCHRONOUS - it waits for subagents to complete
- The Bash tool has `run_in_background=true`, but the Task tool does NOT
- If you close the terminal, all agents stop
- Keep your session open until plans complete
- For parallel execution, use multiple Task calls in ONE message

**For true persistence:** Use tmux/screen, or run Claude Code as a daemon.

---

## Documentation

- [SETUP.md](SETUP.md) - Detailed installation guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design
- [docs/QDRANT-INTEGRATION.md](docs/QDRANT-INTEGRATION.md) - Vector database setup
- [docs/PRODUCT-PHILOSOPHY.md](docs/PRODUCT-PHILOSOPHY.md) - Philosophy alignment
- [docs/AGENTS.md](docs/AGENTS.md) - Agent descriptions
- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - Common patterns
- [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Adaptation guide

---

## License

MIT License - Use freely, modify as needed.

---

## Credits

Built for autonomous development with Claude Code.
