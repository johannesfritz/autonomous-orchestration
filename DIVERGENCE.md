# Template vs. Production Divergence Report

**Last Verified:** 2025-12-31
**Template Location:** `claude-setup/autonomous-orchestration/`
**Production Location:** `jf-private/.claude/`

## Summary

**IN SYNC** - Template matches the production implementation.

## Current Status

| Category | Template | Production | Status |
|----------|----------|------------|--------|
| settings.json | Yes | Yes | Identical |
| Agents | 15 | 15 | Identical |
| Commands | 19 | 19 | Identical |
| Skills | 12 | 12 | Identical |
| Protocols | 12 | 12 | Identical |
| Scripts | 4 | 4 | Identical |
| Hooks (shell) | 3 | 3 | Identical |

---

## Components

### Agents (15)

**Core Orchestration:**
- portfolio-manager.md
- tpm-orchestrator.md
- risk-manager.md

**Product Management Team (NEW):**
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

**Discovery (NEW):**
- discovery.md
- intake.md
- spike.md
- adr.md
- prioritize-backlog.md

### Skills (12)

**Execution:**
- create-plan
- queue-fix
- janitor (NEW)

**Quality & Security:**
- run-test-suite
- security-audit
- static-analysis
- dependency-vetting
- integration-testing

**Discovery (NEW):**
- technical-spike
- user-feedback-intake
- prioritization-framework
- write-adr

### Protocols (12)

**Quality Gates:**
- code-standards.md
- functional-verification.md
- production-ready-checklist.md
- quality-check.md
- risk-assessment-required.md
- tpm-completion-checklist.md

**Enhanced Standards (NEW):**
- strict-code-standards.md
- major-change-detection.md
- component-library-restriction.md

**Product Management (NEW):**
- user-centricity.md
- technical-translation.md
- architectural-documentation.md

### Hooks (3)
- detect-fix-request.sh
- detect-production-review.sh
- pre-push-build-check.sh

### Scripts (4)
- derive-state-from-audit.py
- scan-secrets.py
- detect-major-changes.sh (NEW)
- check-component-usage.sh (NEW)

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

---

## Maintenance

To verify sync status:
```bash
diff -rq .claude/ claude-setup/autonomous-orchestration/.claude/
```

Expected output: No differences (settings.local.json is gitignored in production).
