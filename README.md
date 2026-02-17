# Autonomous Multi-Plan Orchestration for Claude Code

A production-ready system that lets you submit multiple development plans and have Claude Code execute them autonomously - handling prioritization, dependency resolution, parallel execution, quality gates, and shipping.

**Your role shifts from executor to overseer:** Create plans, submit them, approve high-risk changes. The system handles everything else.

**Research-validated:** Architecture informed by Cursor's FastRender experiment (hundreds of GPT-5.2 agents building a browser) and Anthropic's C compiler project (16 Claude Opus 4.6 agents, $20K, 100K lines of Rust). See [Foundational Principles](#foundational-principles) below.

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

# Create directories for feature tracking
mkdir -p inbox/plans/.feature-lists
mkdir -p inbox/plans/.workstreams
mkdir -p inbox/plans/.progress
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
| **Agents** | 17 | Orchestration, development, review, product management, QA |
| **Skills** | 12 | Auto-triggered workflows (plan creation, tests, security, discovery) |
| **Commands** | 22 | Slash commands for portfolio, discovery, and deployment management |
| **Protocols** | 24 | Quality gates, safety enforcement, PM protocols, server safeguards |
| **Hooks** | 47 | Lifecycle automation (PreToolUse, PostToolUse, SubagentStart/Stop) |
| **Scripts** | 24 | Shell/Python utilities (init, secrets, change detection, CI verification) |
| **Rules** | 10 | Modular docs with conditional loading via `paths:` frontmatter |
| **Schemas** | 6 | JSON schemas for feature lists, reflections, handoffs |
| **Templates** | 3 | Plan and hotfix templates with example |

---

## Foundational Principles

The system is built on 12 research-informed principles from long-term autonomous coding experiments (Jan-Feb 2026):

### Tier 1: Structural (highest impact)

| ID | Principle | Implementation |
|----|-----------|----------------|
| P1 | Specs must produce their own checking harness | `feature_list.json` per plan with testable criteria |
| P2 | Constraints beat instructions | Hooks/gates enforce rules, not "MUST" statements |
| P3 | Machine-readable progress (JSON, not Markdown) | Feature status tracked in JSON (models resist modifying JSON) |
| P4 | Fresh context per session + environmental memory | `init-session.sh` surveys state at every session start |

### Tier 2: Operational

| ID | Principle | Implementation |
|----|-----------|----------------|
| P5 | AI-optimized test output | `pytest --tb=short --no-header -q` (failures only) |
| P6 | Attention management | Progress files rewritten at checkpoints to refresh objectives |
| P7 | Simplify coordination plumbing, not expertise layers | 17 expert agents, simple git-based coordination |
| P8 | Filesystem-first coordination | Workstream files on disk, not embedded in prompts |

### Tier 3: Optimization

| ID | Principle | Implementation |
|----|-----------|----------------|
| P9 | KV-cache optimization | Stable prompt prefixes, `once: true` on hooks |
| P10 | Delta-debugging for parallelism | Oracle compiler pattern for monolithic failures |
| P11 | Drift detection | Circuit breakers, max fix attempts per workstream |
| P12 | Spec testability validation | UAT protocol designer requires test_command per criterion |

---

## Product Management Team

The system includes a complete discovery-to-delivery pipeline:

```
User Feedback / Feature Ideas
           |
           v
+---------------------+
| /intake             |  Process feedback from production DB
+----------+----------+
           v
+---------------------+
| Product Manager     |  Validate needs, prioritize (ICE/RICE)
+----------+----------+
           v
+---------------------+
| UX Researcher       |  User journeys, WCAG 2.1 AA compliance
+----------+----------+
           v
+---------------------+
| Technical PM        |  Translate to technical specs
+----------+----------+
           v
+---------------------+
| UAT Protocol        |  Design tests BEFORE development (P1, P12)
| Designer            |  Map criteria -> feature_list.json entries
+----------+----------+
           v
+---------------------+
| Solutions Architect |  ADRs for major decisions
+----------+----------+
           v
    EXECUTION PIPELINE
```

Use `/discovery <idea>` to run the full flow, or individual commands for specific phases.

---

## Architecture

```
+----------------------------------------------------------+
|  You (Plan Creator)                                       |
|  Submit plans via /add-plan or /discovery                 |
+----------------------------+-----------------------------+
                             |
                             v
+----------------------------------------------------------+
|  Layer 0: Risk Manager (MANDATORY)                        |
|  Assesses 4 risk dimensions, approves or escalates        |
+----------------------------+-----------------------------+
                             |
                             v
+----------------------------------------------------------+
|  Layer 1: Portfolio Manager                               |
|  Prioritizes, detects conflicts, spawns orchestrators     |
+----------------------------+-----------------------------+
                             |
                             v
+----------------------------------------------------------+
|  Layer 2: TPM Orchestrator (per plan)                     |
|  Feature list verification -> Workstreams -> Quality gates|
|  Attention management -> Ship                             |
+----------------------------------------------------------+
```

### What's New in the TPM Orchestrator

The TPM now enforces several research-informed patterns:

1. **Feature List Verification (P1, P3):** Reads `feature_list.json` before execution, verifies all features start as `"failing"`, and updates status only when `test_command` succeeds.

2. **Session Initialization (P4):** Dev agents receive ground truth via `init-session.sh` at startup -- git status, feature progress, quick test check.

3. **Attention Management (P6):** Rewrites `inbox/plans/.progress/{PLAN_ID}-progress.md` at every checkpoint, forcing re-statement of the objective to combat lost-in-the-middle degradation.

4. **Workstream File Protocol (P8):** Writes workstream instructions to `inbox/plans/.workstreams/` before spawning agents. If a session crashes, context persists on disk.

5. **AI-Optimized Test Output (P5):** Uses `pytest --tb=short --no-header -q` instead of verbose mode. Only failures are shown, saving agent context.

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
| `/discovery <idea>` | Full discovery flow (PM -> UX -> TPM -> UAT -> plan) |
| `/intake` | Process user feedback from production DB |
| `/spike <question>` | Technical investigation |
| `/adr <decision>` | Create Architecture Decision Record |
| `/code-review` | Layered code review (baseline + strict for major changes) |
| `/audit [plan-id]` | View audit trail and event history |
| `/costs` | View API cost tracking and budget status |

---

## Quality Gates (Never Skipped)

Every plan goes through:

0. **Feature List Generated** - `feature_list.json` exists with all criteria marked `"failing"` (P1)
1. **Risk Assessment** - Mandatory, scores 1-10 across 4 dimensions
2. **Development** - Workstreams execute in parallel via filesystem-first coordination (P8)
3. **Tests** - pytest/Playwright must pass (AI-optimized output, P5)
4. **UAT Executed** - Playwright tests run against actual functionality, not checklist
5. **Code Review** - shadow-code-reviewer verdict: APPROVE required
6. **Security Audit** - OWASP Top 10 scan
7. **CI/CD Pass** - GitHub Actions must succeed
8. **Feature List Complete** - ALL features in JSON are `"passing"` (P3)
9. **Merge Decision** - Based on risk score:
   - Low (1-3): Auto-merge
   - Medium (4-6): Auto-merge after CI
   - High (7-10): Manual approval required

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

This means `testing.md` (15 KB) only loads when test-related files are in context, saving ~3,800 tokens per non-testing session. Three rules use this pattern, saving ~7,400 tokens combined per typical session.

---

## JSON Feature Tracking

The system uses JSON (not Markdown) for progress tracking because **models are less likely to inappropriately modify JSON than Markdown** (Anthropic research, Nov 2025).

### Schema: `.claude/schemas/feature-list.json`

```json
{
  "plan_id": "PLAN-user-auth",
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

- **create-plan** generates the feature list alongside the plan markdown
- **UAT protocol designer** maps each acceptance criterion to a feature entry
- **TPM orchestrator** verifies features before, during, and after execution
- Plan is SHIPPED only when ALL features are `"passing"`

---

## Qdrant Integration (Institutional Memory)

The system supports optional Qdrant vector database integration for:

- **Semantic search** across documentation, plans, and decisions
- **Institutional memory** - agents search past work before making decisions
- **Consistency enforcement** - verify alignment with established patterns

See [docs/QDRANT-INTEGRATION.md](docs/QDRANT-INTEGRATION.md) for setup.

---

## Important Limitation

**All execution is session-scoped.**

- The Task tool is SYNCHRONOUS - it waits for subagents to complete
- If you close the terminal, all agents stop
- Keep your session open until plans complete
- For parallel execution, use multiple Task calls in ONE message
- **Crash recovery:** Feature lists and workstream files persist on disk (P8), so progress isn't lost even if the session ends

**For true persistence:** Use tmux/screen, or run Claude Code as a daemon.

---

## Documentation

- [SETUP.md](SETUP.md) - Detailed installation guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design and research principles
- [docs/QDRANT-INTEGRATION.md](docs/QDRANT-INTEGRATION.md) - Vector database setup
- [docs/PRODUCT-PHILOSOPHY.md](docs/PRODUCT-PHILOSOPHY.md) - Philosophy alignment
- [docs/AGENTS.md](docs/AGENTS.md) - Agent descriptions (17 agents)
- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - Common patterns
- [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Adaptation guide

---

## License

MIT License - Use freely, modify as needed.

---

## Credits

Built for autonomous development with Claude Code. Architecture informed by research from Cursor, Anthropic, Manus, and the Ralph Wiggum community (Jan-Feb 2026).
