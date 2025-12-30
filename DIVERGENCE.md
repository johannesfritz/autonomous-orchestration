# Template vs. Production Divergence Report

**Last Verified:** 2025-12-30
**Template Location:** `claude-setup/autonomous-orchestration/`
**Production Location:** `jf-private/.claude/`

## Summary

✅ **IN SYNC** - Template matches the production implementation.

## Current Status

| Category | Template | Production | Status |
|----------|----------|------------|--------|
| settings.json | ✓ | ✓ | ✅ Identical |
| Agents | 10 | 10 | ✅ Identical |
| Commands | 14 | 14 | ✅ Identical |
| Skills | 7 | 7 | ✅ Identical |
| Protocols | 6 | 6 | ✅ Identical |
| Scripts | 2 | 2 | ✅ Identical |
| Hooks (shell) | 3 | 3 | ✅ Identical |

---

## Components

### Agents (10)
- artificial-shadow-dev.md
- artificial-shadow-llm-architect.md
- database-engineer.md
- hybrid-db-architect.md
- portfolio-manager.md
- qa-engineer.md
- qa-lead.md
- risk-manager.md
- shadow-code-reviewer.md
- tpm-orchestrator.md

### Commands (14)
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

### Skills (7)
- create-plan
- dependency-vetting
- integration-testing
- queue-fix
- run-test-suite
- security-audit
- static-analysis

### Protocols (6)
- code-standards.md
- functional-verification.md
- production-ready-checklist.md
- quality-check.md
- risk-assessment-required.md
- tpm-completion-checklist.md

### Hooks (3)
- detect-fix-request.sh
- detect-production-review.sh
- pre-push-build-check.sh

### Scripts (2)
- derive-state-from-audit.py
- scan-secrets.py

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

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-28 | Initial template created |
| 2025-12-30 | Full backport from production - all components synchronized |
| 2025-12-30 | Updated settings.local.json.example with all skill permissions |

---

## Maintenance

To verify sync status:
```bash
diff -rq .claude/ claude-setup/autonomous-orchestration/.claude/
```

Expected output: No differences (settings.local.json is gitignored in production).
