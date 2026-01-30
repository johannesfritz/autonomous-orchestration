# Autonomous Orchestration

**Purpose:** Reusable Claude Code configuration template for autonomous multi-plan development orchestration.
**Status:** Active template (full configuration)
**Type:** Configuration template - copy to target projects

---

## Quick Reference

| Content Type | Count | Description |
|--------------|-------|-------------|
| Agents | 16 | portfolio-manager, tpm-orchestrator, risk-manager, uat-protocol-designer, etc. |
| Commands | 16 | /portfolio, /add-plan, /execute-plan, etc. |
| Protocols | 12+ | code-standards, risk-assessment, quality gates |
| Rules | 10 | orchestration, product-management, routing, testing, etc. |
| Skills | 6+ | create-plan, queue-fix, user-feedback-intake, etc. |
| Hooks | 3 | fix-request detection, production review, pre-push |

---

## What This Is

This is a **configuration template** - not an application. It contains `.claude/` directory contents that enable autonomous multi-plan orchestration when copied to a target project.

**Key capability:** Submit multiple development plans → Claude Code autonomously:
- Prioritizes based on dependencies and ROI
- Executes plans in parallel
- Enforces quality gates (tests, review, security)
- Ships completed plans
- Escalates high-risk changes

---

## Installation

```bash
# Copy .claude directory to target project
cp -r autonomous-orchestration/.claude /path/to/your/project/

# Copy inbox structure
cp -r autonomous-orchestration/inbox /path/to/your/project/

# Initialize state files
mv inbox/plans/.state.json.example inbox/plans/.state.json
mv inbox/plans/.conflict_history.json.example inbox/plans/.conflict_history.json
mv inbox/PORTFOLIO_STATUS.md.example inbox/PORTFOLIO_STATUS.md
```

---

## Directory Structure

```
autonomous-orchestration/
├── .claude/
│   ├── agents/              # 16 agent definitions
│   │   ├── portfolio-manager.md
│   │   ├── tpm-orchestrator.md
│   │   ├── risk-manager.md
│   │   ├── product-manager.md
│   │   ├── technical-pm.md
│   │   ├── uat-protocol-designer.md  # NEW: Test design before development
│   │   ├── solutions-architect.md
│   │   ├── ux-researcher.md
│   │   ├── artificial-shadow-dev.md
│   │   ├── artificial-shadow-llm-architect.md
│   │   ├── hybrid-db-architect.md
│   │   ├── database-engineer.md
│   │   ├── qa-engineer.md
│   │   ├── qa-lead.md
│   │   ├── shadow-code-reviewer.md
│   │   └── gardener.md
│   │
│   ├── commands/            # 16 slash commands
│   │   ├── portfolio.md     # /portfolio - Dashboard
│   │   ├── add-plan.md      # /add-plan - Submit plans
│   │   ├── execute-plan.md  # Force-execute
│   │   ├── plan-status.md   # Detailed status
│   │   ├── prioritize.md    # Override priority
│   │   ├── show-conflicts.md
│   │   ├── discovery.md     # PM → UX → TPM flow
│   │   ├── intake.md        # User feedback
│   │   ├── spike.md         # Technical investigation
│   │   ├── adr.md           # Architecture decisions
│   │   └── ...
│   │
│   ├── hooks/               # Lifecycle hooks
│   │   ├── detect-fix-request.sh
│   │   ├── detect-production-review.sh
│   │   └── pre-push-build-check.sh
│   │
│   ├── protocols/           # Quality protocols
│   │   ├── code-standards.md
│   │   ├── strict-code-standards.md
│   │   ├── risk-assessment-required.md
│   │   ├── quality-check.md
│   │   └── ...
│   │
│   ├── rules/               # Shared documentation
│   │   ├── orchestration.md
│   │   ├── product-management.md
│   │   ├── product-philosophy.md
│   │   ├── architecture.md
│   │   ├── patterns.md
│   │   ├── testing.md
│   │   ├── production-hardening.md
│   │   ├── anti-debt.md
│   │   └── friday-pipeline.md
│   │
│   ├── skills/              # Auto-invoked capabilities
│   │   ├── create-plan/
│   │   ├── queue-fix/
│   │   ├── user-feedback-intake/
│   │   ├── prioritization-framework/
│   │   ├── technical-spike/
│   │   └── write-adr/
│   │
│   └── settings.json        # Hook configuration
│
├── inbox/                   # Plan inbox structure
│   ├── plans/
│   │   ├── PLAN-TEMPLATE.md
│   │   ├── .state.json.example
│   │   ├── .conflict_history.json.example
│   │   └── completed/
│   └── PORTFOLIO_STATUS.md.example
│
├── docs/                    # Additional documentation
├── scripts/                 # Git helper scripts for nested repos
│   ├── pull-all.sh          # Pull all repos
│   ├── push-all.sh          # Push repos with commits
│   └── git-status-all.sh    # Status of all repos
├── README.md                # Quick start guide
├── SETUP.md                 # Detailed setup
├── DIVERGENCE.md            # Tracking config changes
└── CLAUDE.md               # This file
```

---

## Key Agents

| Agent | Role | Purpose |
|-------|------|---------|
| **portfolio-manager** | VP Engineering | Prioritizes and spawns plans |
| **tpm-orchestrator** | Technical PM | Executes single plan end-to-end |
| **risk-manager** | CRO | Assesses risk, gates high-risk changes |
| **product-manager** | PM | Validates user needs, ICE/RICE scoring |
| **technical-pm** | Technical PM | Translates business → technical |
| **uat-protocol-designer** | QA Architect | Designs tests BEFORE development |
| **solutions-architect** | SA | Architecture decisions, ADRs |

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `/portfolio` | Show dashboard with all plans |
| `/add-plan <file>` | Submit plan for execution |
| `/prioritize <id> <level>` | Override priority |
| `/discovery <idea>` | Full PM → UX → TPM → UAT flow |
| `/queue-fix <description>` | Queue background bug fix |

---

## Workflow

```
1. Create plan (PLAN-YYYY-NNN.md)
           ↓
2. /add-plan → Portfolio Manager
           ↓
3. Risk Manager → Assess risk
           ↓
4. TPM Orchestrator → Execute
   ├── Dev agents (parallel)
   ├── Tests
   ├── Code review
   └── Security audit
           ↓
5. Ship (auto-merge if risk < 7)
```

---

## Divergence Tracking

When you customize this template for a specific project, track your changes in `DIVERGENCE.md`:

- Added agents/commands
- Modified protocols
- Project-specific hooks
- Removed unused components

This enables easier updates when the template evolves.

---

## Git Discipline for Nested Repos

When this template is used in a project with nested git repositories (common in monorepos), the TPM orchestrator enforces:

1. **Pre-Development Pull:** Always sync target repo before spawning agents
2. **Per-Workstream Commits:** Agents commit after each atomic task
3. **Post-Plan Push:** Verify all changes pushed before creating PR

### Helper Scripts

The `scripts/` directory contains utilities for managing multiple nested repos:

| Script | Purpose |
|--------|---------|
| `pull-all.sh` | Pull all repos (auto-discovers, handles divergent branches) |
| `push-all.sh` | Push repos with unpushed commits |
| `git-status-all.sh` | Show dirty/clean/unpushed status for all repos |

These scripts auto-discover git repos in the project tree - no hardcoded list needed.

---

## Integration with jf-private

- **Nested Repo:** This is a nested git repo, gitignored from jf-private
- **Template Source:** The `.claude/` config in jf-private root is based on this template
- **Updates:** Changes here should be manually synced to target projects
- **Related:** Works with cc-data-science-team for analytics-focused config
