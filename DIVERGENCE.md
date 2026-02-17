# Template vs. Production Divergence Report

**Last Verified:** 2026-02-17
**Template Location:** `claude-setup/autonomous-orchestration/`
**Production Location:** `jf-private/jf-dev/.claude/`

## Summary

**IN SYNC** - Template matches the production implementation (software dev elements only).

**Note:** Analytical writing elements (writing-lead, fact-checker, etc.) are intentionally excluded from this template. SGEPT-specific integrations (Qdrant, Stellaris admin MCP) are also excluded.

## Current Status

| Category | Template | Production | Status |
|----------|----------|------------|--------|
| settings.json | 596 lines | 612 lines | Synced (filtered: no Qdrant hooks, no stellaris-admin MCP) |
| Agents | 17 | 17+ | Synced (sw dev only) |
| Commands | 22 | 27+ | Synced (sw dev only; excludes inbox, search-docs, sync-docs) |
| Skills | 12 | 16+ | Synced (sw dev only; excludes deploy-stellaris, local-uat, roam-sync, sancho-review) |
| Protocols | 24 | 32+ | Synced (sw dev only; excludes stellaris-specific UATs) |
| Scripts | 24 | 29+ | Synced (sw dev only; excludes Qdrant-dependent scripts) |
| Hooks (shell) | 4 | 5 | Synced (excludes post-commit-sync-docs.sh - Qdrant dependent) |
| Rules | 10 | 10 | Identical |
| Schemas | 6 | 6 | Identical |
| Docs | 6 | - | Template-specific |

---

## Intentional Exclusions

### Commands (excluded from template)
| File | Reason |
|------|--------|
| `inbox.md` | SGEPT email triage |
| `search-docs.md` | Depends on SGEPT Qdrant instance |
| `sync-docs.md` | Depends on SGEPT Qdrant instance |

### Skills (excluded from template)
| Skill | Reason |
|-------|--------|
| `deploy-stellaris/` | Project-specific deployment |
| `local-uat/` | Stellaris-specific local testing |
| `roam-sync/` | Project-specific integration |
| `sancho-review/` | Project-specific review process |

### Protocols (excluded from template)
| Protocol | Reason |
|----------|--------|
| `stellaris-frontend-uat.md` | Project-specific |
| `stellaris-ui-checklist.md` | Project-specific |
| `uat-bcg-stability-news.md` | Feature-specific UAT |
| `uat-gta-counts-cross-validation.md` | Feature-specific UAT |
| `uat-gta-mnt-mcp-server.md` | Feature-specific UAT |
| `uat-pin-verification.md` | Feature-specific UAT |
| `uat-protokoll-incident-response.md` | Feature-specific UAT |
| `uat-unified-learning-experience.md` | Feature-specific UAT |
| `semantic-search-protocol.md` | Depends on Qdrant |
| `institutional-memory-protocol.md` | Depends on Qdrant |

### Scripts (excluded from template)
| Script | Reason |
|--------|--------|
| `inject-similar-patterns.py` | Depends on Qdrant |
| `index-philosophy.py` | Depends on Qdrant |
| `sync-docs-local.sh` | Depends on Qdrant |
| `search-documentation.py` | Depends on Qdrant |
| `check-mcp-release-needed.sh` | Project-specific |
| `validate-stellaris-schema.sh` | Project-specific |

### Hooks (settings.json differences)
| Hook | Reason |
|------|--------|
| `inject-similar-patterns.py` (SubagentStart) | Depends on Qdrant |
| `sync-docs-local.sh` (PostToolUse git push) | Depends on Qdrant |
| `check-mcp-release-needed.sh` (PostToolUse git push) | Project-specific |
| `validate-stellaris-schema.sh` (PreToolUse git push) | Project-specific |
| `post-commit-sync-docs.sh` (PostToolUse git commit) | Depends on Qdrant |
| Stellaris-admin MCP permissions | Project-specific |

---

## Components

### Rules (10) - Modular Documentation

```
rules/
├── architecture.md                    # Architecture patterns
├── core-patterns.md                   # Cross-cutting patterns
├── development/
│   └── patterns.md                    # paths: **/*.py, **/*.ts, **/*.tsx
├── orchestration/
│   ├── orchestration.md               # Portfolio Manager, TPM execution
│   ├── product-management.md          # Discovery flow, PM/UX/TPM agents
│   └── routing.md                     # paths: inbox/plans/**, .claude/agents/**
├── quality/
│   ├── anti-debt.md                   # Gardener agent, code reduction
│   ├── production-hardening.md        # Major change protocol, UAT gates
│   └── testing.md                     # paths: **/*test*, **/tests/**
└── stellaris/
    └── product-philosophy.md          # Product philosophy alignment
```

### Agents (17)

**Core Orchestration:**
- portfolio-manager.md
- tpm-orchestrator.md
- risk-manager.md

**Product Management Team:**
- product-manager.md
- ux-researcher.md
- technical-pm.md
- solutions-architect.md
- requirements-analyst.md
- gardener.md

**Development:**
- artificial-shadow-dev.md
- artificial-shadow-llm-architect.md
- database-engineer.md
- hybrid-db-architect.md

**Quality:**
- qa-engineer.md
- qa-lead.md
- shadow-code-reviewer.md
- uat-protocol-designer.md

### Commands (22)

**Portfolio Management:**
- add-plan.md, audit.md, budget-override.md, costs.md, execute-plan.md
- force-git.md, learning.md, plan-status.md, portfolio.md, prioritize.md
- queue-fix.md, rollback.md, show-conflicts.md, sync-state.md

**Quality:**
- code-review.md

**Discovery:**
- discovery.md, intake.md, spike.md, adr.md, prioritize-backlog.md

**Utilities:**
- setup-gitignore.md, README.md

### Protocols (24)

**Quality Gates:**
- code-standards.md, functional-verification.md, mandatory-playwright-execution.md
- mandatory-quality-gates.md, mandatory-uat-protocol.md, production-ready-checklist.md
- quality-check.md, risk-assessment-required.md, tpm-completion-checklist.md
- schema-migration-checklist.md, user-request-closure.md

**Enhanced Standards:**
- strict-code-standards.md, major-change-detection.md, component-library-restriction.md

**Product Management:**
- user-centricity.md, technical-translation.md, architectural-documentation.md
- navigation-flow.md

**Operational:**
- audit-logging.md, requirements-extraction-protocol.md
- server-operation-safeguards.md, portfolio-manager-fixes.md

### Schemas (6)
- feature-list.json, tpm-reflection.json, session-reflection.json
- handoff-checklist.json, data-science-audit.json, writing-audit.json

### Hooks (4 shell scripts)
- detect-fix-request.sh
- detect-production-review.sh
- pre-push-build-check.sh
- block-on-test-failure.sh

### Scripts (24)
- check-claude-md-update-needed.sh, check-component-usage.sh
- derive-state-from-audit.py, detect-architectural-decision.sh
- detect-doc-changes.sh, detect-major-changes.sh, detect-schema-changes.sh
- generate-toc.sh, index-documentation.py, init-session.sh
- run-uat.py, scan-secrets.py, spawn-tpm-background.sh
- start-local-stack.sh, verify-ci-passed.sh, verify-cleanup-complete.sh
- verify-migration-tests.sh, verify-plan-state-updated.sh
- verify-quality-gates.sh, verify-review-verdict.sh
- verify-uat-evidence.sh, verify-uat-executed.sh, wait-for-ci.sh
- search-documentation.py

### Skills (12)
- create-plan, queue-fix, janitor
- run-test-suite, security-audit, static-analysis, dependency-vetting, integration-testing
- technical-spike, user-feedback-intake, prioritization-framework, write-adr

---

## Project-Specific Files (Not in Template)

| File | Reason |
|------|--------|
| `settings.local.json` | Machine-specific permissions (gitignored) |
| `inbox/plans/*.md` | Actual development plans |
| `inbox/plans/.state.json` | Runtime state |
| `inbox/audit_log.jsonl` | Event history |
| `inbox/PORTFOLIO_STATUS.md` | Generated dashboard |
| `inbox/feedback/` | Processed user feedback |
| `inbox/backlog/` | Prioritized backlog items |
| `inbox/spikes/` | Technical spike reports |

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-28 | Initial template created |
| 2025-12-30 | Full backport from production |
| 2025-12-31 | Product Management Team (+5 agents, +5 commands, +5 skills, +6 protocols) |
| 2026-01-01 | Modular CLAUDE.md Migration (+8 rules, +2 protocols, +2 scripts) |
| 2026-01-03 | 12-Gap Fix Sync (+8 scripts, updated settings.json) |
| 2026-01-07 | UAT Enforcement + Code Review Integration |
| 2026-01-08 | Agent-Scoped Hooks & Skill Improvements (+6 verification scripts) |
| 2026-02-17 | **Major Sync: 5-week catch-up** |
|            | +1 agent: requirements-analyst.md |
|            | +6 schemas: feature-list.json, tpm-reflection.json, session-reflection.json, handoff-checklist.json, data-science-audit.json, writing-audit.json |
|            | +1 hook: block-on-test-failure.sh |
|            | +4 protocols: audit-logging.md, requirements-extraction-protocol.md, server-operation-safeguards.md, portfolio-manager-fixes.md |
|            | +2 commands: setup-gitignore.md, README.md |
|            | +3 scripts: init-session.sh, run-uat.py, start-local-stack.sh |
|            | Rules restructure: patterns.md → development/, testing.md → quality/, routing.md → orchestration/, +core-patterns.md |
|            | settings.json: +83 lines (SubagentStart/Stop hooks, build hooks, UI checklist hooks, TPM reflection prompt, handoff checklist prompt) |
|            | Updated agents: tpm-orchestrator, uat-protocol-designer, portfolio-manager |
|            | Updated protocols: mandatory-quality-gates, production-ready-checklist, strict-code-standards, schema-migration-checklist, code-standards |
|            | Removed stellaris-admin MCP permissions from template |
|            | Fixed product-philosophy.md paths in hooks (now rules/stellaris/product-philosophy.md) |

---

## Maintenance

To verify sync status:
```bash
diff -rq jf-dev/.claude/ claude-setup/autonomous-orchestration/.claude/ --exclude='*.local.*'
```
