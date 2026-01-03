# Template vs. Production Divergence Report

**Last Verified:** 2026-01-03
**Template Location:** `claude-setup/autonomous-orchestration/`
**Production Location:** `jf-private/.claude/`

## Summary

**IN SYNC** - Template matches the production implementation (software dev elements only).

**Note:** Analytical writing elements (writing-lead, fact-checker, etc.) are intentionally excluded from this template.

## Current Status

| Category | Template | Production | Status |
|----------|----------|------------|--------|
| settings.json | 518 lines | 641 lines | Synced (filtered) |
| Agents | 14 | 25+ | Synced (sw dev only) |
| Commands | 19 | 19+ | Synced (sw dev only) |
| Skills | 12 | 12+ | Synced (sw dev only) |
| Protocols | 10 | 14+ | Synced (sw dev only) |
| Scripts | 8 | 10+ | Synced (sw dev only) |
| Hooks (shell) | 3 | 3 | Identical |
| **Rules** | 9 | 10 | Synced (sw dev only) |
| **Docs** | 6 | - | Template-specific |

---

## Components

### Rules (8) - NEW: Modular Documentation

The `.claude/rules/` directory contains modular documentation extracted from the monolithic CLAUDE.md:

- architecture.md - FRIDAY pipeline, atomic notes, dual embeddings
- anti-debt.md - Gardener agent, code reduction strategies
- friday-pipeline.md - 6-stage content processing workflow
- orchestration.md - Portfolio Manager, TPM Orchestrator, multi-plan execution
- patterns.md - Error handling, async patterns, Qdrant queries
- product-management.md - Discovery flow, PM/UX/TPM agents
- production-hardening.md - Major change protocol, UAT gates
- testing.md - Test pyramid, pytest, Playwright, F2 scoring

**Purpose:** Reduced root CLAUDE.md by 72% (1210 → 335 lines) while preserving all functionality through hierarchical context inheritance.

### Agents (15)

**Core Orchestration:**
- portfolio-manager.md
- tpm-orchestrator.md
- risk-manager.md

**Product Management Team:**
- product-manager.md
- ux-researcher.md
- technical-pm.md
- solutions-architect.md
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

### Commands (19)

**Portfolio Management:**
- add-plan.md
- audit.md
- budget-override.md
- costs.md
- execute-plan.md
- force-git.md
- learning.md
- plan-status.md
- portfolio.md
- prioritize.md
- queue-fix.md
- rollback.md
- show-conflicts.md
- sync-state.md

**Discovery:**
- discovery.md
- intake.md
- spike.md
- adr.md
- prioritize-backlog.md

### Skills (12)

**Execution:**
- create-plan
- queue-fix
- janitor

**Quality & Security:**
- run-test-suite
- security-audit
- static-analysis
- dependency-vetting
- integration-testing

**Discovery:**
- technical-spike
- user-feedback-intake
- prioritization-framework
- write-adr

### Protocols (14)

**Quality Gates:**
- code-standards.md
- functional-verification.md
- production-ready-checklist.md
- quality-check.md
- risk-assessment-required.md
- tpm-completion-checklist.md
- schema-migration-checklist.md (NEW)
- user-request-closure.md (NEW)

**Enhanced Standards:**
- strict-code-standards.md
- major-change-detection.md
- component-library-restriction.md

**Product Management:**
- user-centricity.md
- technical-translation.md
- architectural-documentation.md

### Hooks (3)
- detect-fix-request.sh
- detect-production-review.sh
- pre-push-build-check.sh

### Scripts (6)
- derive-state-from-audit.py
- scan-secrets.py
- detect-major-changes.sh
- check-component-usage.sh
- detect-schema-changes.sh (NEW)
- wait-for-ci.sh (NEW)

---

## Project-Specific Files (Not in Template)

The following files exist in production but are intentionally excluded from the template:

| File | Reason |
|------|--------|
| `settings.local.json` | Machine-specific permissions (gitignored) |
| `00 Inbox/plans/*.md` | Actual development plans |
| `00 Inbox/plans/.state.json` | Runtime state |
| `00 Inbox/audit_log.jsonl` | Event history |
| `00 Inbox/PORTFOLIO_STATUS.md` | Generated dashboard |
| `00 Inbox/feedback/` | Processed user feedback |
| `00 Inbox/backlog/` | Prioritized backlog items |
| `00 Inbox/spikes/` | Technical spike reports |

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-28 | Initial template created |
| 2025-12-30 | Full backport from production - all components synchronized |
| 2025-12-30 | Updated settings.local.json.example with all skill permissions |
| 2025-12-31 | **Major Update:** Added Product Management Team |
|            | +5 agents: gardener, product-manager, ux-researcher, technical-pm, solutions-architect |
|            | +5 commands: discovery, intake, spike, adr, prioritize-backlog |
|            | +5 skills: technical-spike, user-feedback-intake, prioritization-framework, write-adr, janitor |
|            | +6 protocols: strict-code-standards, major-change-detection, component-library-restriction, technical-translation, architectural-documentation, user-centricity |
|            | +2 scripts: detect-major-changes.sh, check-component-usage.sh |
| 2026-01-01 | **Major Update:** Modular CLAUDE.md Migration |
|            | +8 rule files: architecture.md, anti-debt.md, friday-pipeline.md, orchestration.md, patterns.md, product-management.md, production-hardening.md, testing.md |
|            | +2 protocols: schema-migration-checklist.md, user-request-closure.md |
|            | +2 scripts: detect-schema-changes.sh, wait-for-ci.sh |
|            | Updated settings.json with new hook configurations |
| 2026-01-03 | **Major Update:** 12-Gap Fix Sync + Documentation |
|            | Synced 14 agent files with updated versions |
|            | Added 8 new scripts: index-documentation.py, search-documentation.py, detect-architectural-decision.sh, verify-migration-tests.sh, generate-toc.sh, detect-doc-changes.sh, spawn-tpm-background.sh, verify-cleanup-complete.sh |
|            | Updated settings.json (518 lines) - filtered analytical writing hooks |
|            | Synced 10 protocols (added mandatory-quality-gates.md, mandatory-uat-protocol.md) |
|            | Synced 9 rules (added product-philosophy.md) |
|            | Created docs/QDRANT-INTEGRATION.md - Institutional memory patterns |
|            | Created docs/PRODUCT-PHILOSOPHY.md - Philosophy alignment mechanisms |
|            | Updated docs/ARCHITECTURE.md, README.md, SETUP.md |
|            | **Scope:** Software development only (excluded analytical writing) |

---

## Maintenance

To verify sync status:
```bash
diff -rq .claude/ claude-setup/autonomous-orchestration/.claude/
```

Expected output: No differences (settings.local.json is gitignored in production).
