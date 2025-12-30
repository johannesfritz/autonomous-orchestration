# Template vs. Production Divergence Report

**Generated:** 2025-12-30
**Template Location:** `claude-setup/autonomous-orchestration/`
**Production Location:** `jf-private/.claude/`

## Summary

The production setup in `jf-private/.claude/` is a **superset** of this template. The template serves as a "starter kit" while the production setup contains additional features developed during active use.

## Divergence Status

| Category | Template | Production | Status |
|----------|----------|------------|--------|
| Agents | 9 | 10 | Production has more |
| Commands | 7 | 12 | Production has more |
| Skills | 4 | 6 | Production has more |
| Scripts | 0 | 1 | Production has more |
| Hooks | 6 | 11 | Production has more |

---

## Detailed Differences

### Agents

#### Present in Both (9)
- artificial-shadow-dev.md
- artificial-shadow-llm-architect.md
- database-engineer.md
- hybrid-db-architect.md
- portfolio-manager.md
- qa-engineer.md
- risk-manager.md
- shadow-code-reviewer.md
- tpm-orchestrator.md

#### Production Only (1)
| Agent | Purpose |
|-------|---------|
| **qa-lead.md** | Multi-pass code review with 5 review passes: correctness, integration, security, maintainability, regression risk. Outputs structured JSON verdicts (APPROVE/REQUEST_CHANGES/BLOCK) for automation. |

#### Content Enhancements (Same file, more content in production)

| Agent | Template Lines | Production Lines | Added Protocols |
|-------|---------------|------------------|-----------------|
| portfolio-manager.md | 258 | 565 | State Persistence Protocol, Audit Logging Protocol, Learning System Persistence |
| tpm-orchestrator.md | 286 | 510 | Circuit Breaker Protocol, Rebase-and-Verify Before Merge, Context Summarization Protocol |
| risk-manager.md | 297 | 422 | Plan Content Sanitization (prompt injection protection) |

---

### Commands

#### Present in Both (7)
- add-plan.md
- execute-plan.md
- plan-status.md
- portfolio.md
- prioritize.md
- queue-fix.md
- show-conflicts.md

#### Production Only (5)
| Command | Purpose |
|---------|---------|
| **audit.md** | View audit trail for plans or system. Shows event history, decisions, and outcomes. |
| **costs.md** | API cost tracking and budget status. Per-plan breakdown and alerts. |
| **budget-override.md** | Override daily/session/per-plan budget limits. |
| **force-git.md** | Bypass git safeguards (secrets scan, etc.) when needed. |
| **learning.md** | View and manage Portfolio Manager's learned patterns. Adjust confidence, delete patterns, reset learning. |
| **rollback.md** | Rollback deployments and revert changes. |

---

### Skills

#### Present in Both (4)
- create-plan/SKILL.md
- queue-fix/SKILL.md
- run-test-suite/SKILL.md
- security-audit/SKILL.md

#### Production Only (3)
| Skill | Purpose |
|-------|---------|
| **dependency-vetting/SKILL.md** | Vet dependencies for security and licensing |
| **integration-testing/SKILL.md** | Integration test automation |
| **static-analysis/SKILL.md** | Static code analysis |

---

### Scripts

#### Production Only (1)
| Script | Purpose |
|--------|---------|
| **scripts/scan-secrets.py** | Pre-commit secrets scanner. Detects API keys, private keys, passwords, JWT tokens. Blocks git operations on critical/high severity findings. |

---

### Settings.json Differences

#### Additional Permissions in Production
```json
// MCP Tools
"mcp__filesystem__read_file",
"mcp__filesystem__read_multiple_files",
"mcp__filesystem__write_file",
"mcp__filesystem__edit_file",
"mcp__filesystem__list_directory",
"mcp__filesystem__directory_tree",
"mcp__filesystem__search_files",
"mcp__filesystem__get_file_info",
"mcp__filesystem__list_allowed_directories",

// Additional utilities
"Bash(tldr:*)",
"Bash(history:*)",
"Bash(clear)",
"Bash(reset)",
"Bash(true)",
"Bash(false)",
"Bash(test:*)",
"Bash([:*)",
"Bash(watch:*)",
"Bash(nohup:*)",
"Bash(bg)",
"Bash(fg)",
"Bash(jobs)",
"Bash(top:*)",
"Bash(htop:*)",
"Bash(lsof:*)",
"Bash(netstat:*)",
"Bash(ss:*)",
"Bash(nc:*)",
"Bash(telnet:*)",
"Bash(traceroute:*)",
"Bash(nslookup:*)"
```

#### Deny List (Production Only)
```json
"deny": [
  "Bash(rm -rf /)",
  "Bash(rm -rf .claude)",
  "Bash(rm -rf .git)",
  "Bash(git push --force origin main)",
  "Bash(git push --force origin master)",
  "Bash(git push -f origin main)",
  "Bash(git push -f origin master)"
]
```

#### Additional Hooks in Production
| Hook | Matcher | Purpose |
|------|---------|---------|
| PreToolUse | `Bash(git add *)` | Run scan-secrets.py |
| PreToolUse | `Bash(git commit *)` | Run scan-secrets.py |
| PreToolUse | `Bash(git push *)` | Pre-push warning |
| PreToolUse | `Bash(rm -rf *)` | Destructive operation warning |
| PreToolUse | `Bash(chmod *)` | Permission change warning |

---

### Files Only in Template (Missing from Production)

| File | Purpose |
|------|---------|
| settings.local.json.example | Example file for local setting overrides |

---

## Recommendations

### Option 1: Backport to Template (Recommended)
Update this template to match production, making it the authoritative source for the orchestration system.

**Benefits:**
- Single source of truth
- Template becomes reusable for other projects
- Easier maintenance

**Plan:** See `PLAN-2025-XXX-backport-orchestration.md`

### Option 2: Keep Diverged
Keep the template as a "minimal starter kit" and production as the "full implementation."

**Benefits:**
- Simpler template for new users
- Production can evolve independently

**Drawbacks:**
- Two sources of truth
- Risk of template becoming stale
- Harder to track what's in production vs. template

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-30 | Initial divergence report created |
