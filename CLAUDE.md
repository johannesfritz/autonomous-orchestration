# Autonomous Orchestration

**Purpose:** Reusable Claude Code configuration template for autonomous multi-plan development orchestration.
**Status:** Active template (full configuration)
**Type:** Configuration template - copy to target projects
**Last updated:** 2026-02-12

---

## Quick Reference

| Content Type | Count | Description |
|--------------|-------|-------------|
| Agents | 17 | portfolio-manager, tpm-orchestrator, risk-manager, uat-protocol-designer, requirements-analyst, etc. |
| Commands | 25 | /portfolio, /add-plan, /execute-plan, /discovery, /code-review, etc. |
| Protocols | 32 | code-standards, risk-assessment, quality gates, server safeguards |
| Rules | 10 | orchestration, product-management, routing, testing (with `paths:` frontmatter) |
| Skills | 16 | create-plan, queue-fix, run-test-suite, security-audit, local-uat, etc. |
| Hooks | 60+ | PreToolUse, PostToolUse, SubagentStart/Stop, UserPromptSubmit |
| Scripts | 27 | init-session.sh, scan-secrets.py, wait-for-ci.sh, etc. |
| Schemas | 6 | feature-list.json, tpm-reflection.json, handoff-checklist.json, etc. |

---

## What This Is

This is a **configuration template** - not an application. It contains `.claude/` directory contents that enable autonomous multi-plan orchestration when copied to a target project.

**Key capability:** Submit multiple development plans and Claude Code autonomously:
- Generates machine-verifiable feature lists (JSON, not Markdown)
- Prioritizes based on dependencies and ROI
- Executes plans in parallel with filesystem-first coordination
- Enforces quality gates (feature list, tests, UAT, review, security)
- Manages agent attention via progress file rewrites
- Ships completed plans with risk-aware merge decisions
- Escalates high-risk changes for human approval

---

## Foundational Principles (Research-Informed)

Architecture informed by Cursor's FastRender (Jan 2026) and Anthropic's C compiler (Feb 2026) experiments:

| ID | Principle | Implementation |
|----|-----------|----------------|
| P1 | Specs produce their own checking harness | `feature_list.json` per plan |
| P2 | Constraints beat instructions | Hooks/gates, not "MUST" statements |
| P3 | Machine-readable progress (JSON) | Models resist modifying JSON |
| P4 | Fresh context + environmental memory | `init-session.sh` at session start |
| P5 | AI-optimized test output | `pytest -q` (failures only) |
| P6 | Attention management | Progress file rewrites at checkpoints |
| P7 | Simplify plumbing, not expertise | 17 expert agents, simple coordination |
| P8 | Filesystem-first coordination | Workstream files on disk |

---

## Installation

```bash
# Copy .claude directory to target project
cp -r autonomous-orchestration/.claude /path/to/your/project/

# Copy inbox structure
cp -r autonomous-orchestration/inbox /path/to/your/project/

# Initialize state files
cd /path/to/your/project
mv inbox/plans/.state.json.example inbox/plans/.state.json
mv inbox/plans/.conflict_history.json.example inbox/plans/.conflict_history.json
mv inbox/PORTFOLIO_STATUS.md.example inbox/PORTFOLIO_STATUS.md

# Create directories for feature tracking (P1, P3, P6, P8)
mkdir -p inbox/plans/.feature-lists
mkdir -p inbox/plans/.workstreams
mkdir -p inbox/plans/.progress
```

---

## Directory Structure

```
autonomous-orchestration/
├── .claude/
│   ├── agents/              # 17 agent definitions
│   │   ├── portfolio-manager.md
│   │   ├── tpm-orchestrator.md        # Feature list verification, attention mgmt
│   │   ├── risk-manager.md
│   │   ├── product-manager.md
│   │   ├── technical-pm.md
│   │   ├── uat-protocol-designer.md   # Maps criteria -> feature_list.json
│   │   ├── requirements-analyst.md    # Detailed requirements extraction
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
│   ├── commands/            # 25 slash commands
│   │   ├── portfolio.md     # /portfolio - Dashboard
│   │   ├── add-plan.md      # /add-plan - Submit plans
│   │   ├── discovery.md     # /discovery - PM → UX → TPM → UAT flow
│   │   ├── code-review.md   # /code-review - Layered review
│   │   └── ...
│   │
│   ├── hooks/               # Lifecycle hooks
│   │   ├── detect-fix-request.sh
│   │   ├── detect-production-review.sh
│   │   ├── block-on-test-failure.sh    # AI-optimized pytest flags
│   │   └── post-commit-sync-docs.sh
│   │
│   ├── protocols/           # 32 quality protocols
│   │   ├── code-standards.md
│   │   ├── strict-code-standards.md
│   │   ├── risk-assessment-required.md
│   │   ├── mandatory-quality-gates.md
│   │   ├── tpm-completion-checklist.md
│   │   ├── server-operation-safeguards.md
│   │   └── ...
│   │
│   ├── rules/               # Conditional docs (paths: frontmatter)
│   │   ├── orchestration/
│   │   │   ├── orchestration.md
│   │   │   └── routing.md           # paths: inbox/plans/**, .claude/agents/**
│   │   ├── development/
│   │   │   └── patterns.md          # paths: **/*.py, **/*.ts, **/*.tsx
│   │   ├── quality/
│   │   │   └── testing.md           # paths: **/*test*, **/tests/**
│   │   └── ...
│   │
│   ├── schemas/             # JSON schemas
│   │   ├── feature-list.json         # Per-plan feature tracking (P1, P3)
│   │   ├── tpm-reflection.json
│   │   ├── handoff-checklist.json
│   │   └── ...
│   │
│   ├── scripts/             # 27 utilities
│   │   ├── init-session.sh           # Session initialization (P4)
│   │   ├── scan-secrets.py
│   │   ├── wait-for-ci.sh
│   │   ├── detect-major-changes.sh
│   │   ├── inject-similar-patterns.py
│   │   └── ...
│   │
│   ├── skills/              # 16 auto-invoked capabilities
│   │   ├── create-plan/              # Generates plan + feature_list.json
│   │   ├── run-test-suite/           # AI-optimized test modes (P5)
│   │   ├── queue-fix/
│   │   ├── local-uat/
│   │   ├── security-audit/
│   │   └── ...
│   │
│   └── settings.json        # Hook configuration (60+ hooks)
│
├── inbox/                   # Plan inbox structure
│   ├── plans/
│   │   ├── PLAN-TEMPLATE.md
│   │   ├── .state.json.example
│   │   ├── .conflict_history.json.example
│   │   ├── .feature-lists/           # Per-plan JSON feature tracking
│   │   ├── .workstreams/             # Per-workstream instruction files
│   │   ├── .progress/                # Attention management files
│   │   └── completed/
│   └── PORTFOLIO_STATUS.md.example
│
├── docs/                    # Documentation
├── scripts/                 # Git helper scripts for nested repos
├── README.md                # Quick start guide
├── SETUP.md                 # Detailed setup
├── DIVERGENCE.md            # Tracking config changes
└── CLAUDE.md                # This file
```

---

## Agent Hierarchy

| Layer | Agent | Role |
|-------|-------|------|
| 0 | risk-manager | Safety gate (mandatory for all plans) |
| 1 | portfolio-manager | Multi-plan coordination, conflict detection |
| 2 | tpm-orchestrator | Single-plan execution with feature list verification |
| - | uat-protocol-designer | Pre-dev test design, feature list mapping |
| - | requirements-analyst | Detailed requirements extraction |
| - | product-manager | User need validation, ICE/RICE scoring |
| - | technical-pm | Business-to-technical translation |
| - | solutions-architect | ADRs, technology decisions |
| - | ux-researcher | User journeys, WCAG 2.1 AA |
| - | artificial-shadow-dev | Full-stack implementation |
| - | artificial-shadow-llm-architect | LLM pipeline design |
| - | hybrid-db-architect | SQLite + Qdrant dual-store |
| - | database-engineer | Relational DB specialist |
| - | qa-engineer | Test creation (pytest, Playwright) |
| - | qa-lead | Multi-pass code review with JSON verdicts |
| - | shadow-code-reviewer | Production readiness review |
| - | gardener | Code refactoring (DELETE and CONDENSE) |

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `/portfolio` | Show dashboard with all plans |
| `/add-plan <file>` | Submit plan for execution |
| `/discovery <idea>` | Full PM -> UX -> TPM -> UAT flow |
| `/queue-fix <description>` | Queue background bug fix |
| `/code-review` | Layered review (baseline + strict) |
| `/prioritize <id> <level>` | Override priority |

---

## Quality Gates (Never Skip)

0. **Feature List Generated** - `feature_list.json` with all criteria `"failing"` (P1)
1. **Risk Assessment** - 4-dimension scoring, >=7 requires approval
2. **Development** - Workstreams via filesystem-first coordination (P8)
3. **Tests** - AI-optimized output (P5), blocking on failure
4. **UAT Executed** - Playwright, not checklist
5. **Code Review** - APPROVE verdict required
6. **Security Audit** - OWASP Top 10
7. **CI/CD Pass** - GitHub Actions
8. **Feature List Complete** - ALL features `"passing"` (P3)
9. **Risk-Aware Merge** - Auto (low/medium) or manual (high)

---

## Workflow

```
1. Create plan (PLAN-[name].md)
          |
2. /add-plan -> Portfolio Manager
          |
3. Risk Manager -> Assess risk
          |
4. create-plan -> Generate feature_list.json (P1)
          |
5. TPM Orchestrator -> Execute
   |-- Write workstream files (P8)
   |-- init-session.sh for each agent (P4)
   |-- Dev agents (parallel)
   |-- Rewrite progress files (P6)
   |-- Tests (pytest -q, P5)
   |-- UAT (Playwright)
   |-- Code review
   |-- Security audit
   |-- Verify ALL features "passing" (P3)
          |
6. Ship (auto-merge if risk < 7)
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

## Integration with jf-private

- **Nested Repo:** This is a nested git repo, gitignored from jf-private
- **Template Source:** The `.claude/` config in jf-private/jf-dev is based on this template
- **Updates:** Changes here should be manually synced to target projects
