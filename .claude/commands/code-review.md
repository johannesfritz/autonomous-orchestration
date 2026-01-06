---
name: code-review
description: |
  Layered code review using official Anthropic plugin + custom strict protocols.

  Layer 1: Official code-review plugin (4 parallel agents, confidence-filtered)
  Layer 2: shadow-code-reviewer (strict-code-standards.md for major changes)

  Usage:
    /code-review              # Terminal output only
    /code-review --comment    # Post to GitHub PR
    /code-review --strict     # Force strict review even for minor changes
    /code-review --baseline   # Only baseline (skip strict)
---

# Layered Code Review

This command provides a two-layer code review:

1. **Baseline Review** (Official Anthropic Plugin)
   - 4 parallel agents run simultaneously
   - CLAUDE.md compliance check
   - Bug detection with git blame context
   - Confidence-based filtering (threshold: 80)
   - Fast, catches obvious issues

2. **Strict Review** (shadow-code-reviewer)
   - Custom protocols injected (strict-code-standards.md)
   - Major change detection triggers strict mode
   - Function length ≤ 50 lines enforcement
   - Type annotation completeness
   - Schema migration checklist for DB changes

## Execution Flow

```bash
# Step 1: Detect review scope
CHANGED_FILES=$(git diff --name-only HEAD~1 || git diff --name-only --cached)

# Step 2: Check for major changes
MAJOR_CHANGE=$($CLAUDE_PROJECT_DIR/.claude/scripts/detect-major-changes.sh 2>/dev/null && echo "true" || echo "false")

# Step 3: Run baseline review (official plugin, 4 parallel agents)
echo "═══════════════════════════════════════"
echo "📋 LAYER 1: Baseline Review (4 agents)"
echo "═══════════════════════════════════════"

# The official plugin spawns 4 parallel agents:
# - Agent 1: CLAUDE.md compliance
# - Agent 2: CLAUDE.md compliance (redundancy)
# - Agent 3: Bug detection
# - Agent 4: Git history context

# Confidence threshold: 80 (only high-confidence issues reported)
# Smart filtering excludes: pre-existing issues, linter catches, pedantic nitpicks

# Run baseline with confidence filtering
Task(subagent_type="shadow-code-reviewer", model="haiku", prompt='''
  BASELINE REVIEW (fast, confidence-filtered)

  Review these files for obvious issues:
  $CHANGED_FILES

  Focus on:
  - CLAUDE.md compliance
  - Obvious bugs
  - Security vulnerabilities

  Confidence threshold: 80
  Only report issues you are ≥80% confident about.

  Skip:
  - Style nitpicks (linters catch these)
  - Pre-existing issues
  - Pedantic concerns

  Return: BASELINE_PASS or BASELINE_ISSUES with list
''')

# Step 4: If major change OR --strict flag, run strict review
if [ "$MAJOR_CHANGE" = "true" ] || [ "$1" = "--strict" ]; then
    echo ""
    echo "═══════════════════════════════════════"
    echo "🔒 LAYER 2: Strict Review (major change detected)"
    echo "═══════════════════════════════════════"

    # Invoke shadow-code-reviewer with strict protocols
    Task(subagent_type="shadow-code-reviewer", prompt='''
      STRICT MODE REVIEW

      Apply ALL rules from:
      - .claude/protocols/strict-code-standards.md
      - .claude/protocols/code-standards.md

      ABSOLUTE RULES (violation = REJECT):
      1. Function length ≤ 50 lines
      2. No vague variable names (data, info, item, temp, result)
      3. Complete type annotations on all functions
      4. No empty except/catch blocks
      5. No console.log/print in production code
      6. No magic numbers/strings
      7. Tests required for new public functions
      8. New page components MUST have routes

      Check for:
      - Database schema changes → Schema migration checklist
      - Auth changes → Security review
      - New features → UAT required

      Return structured verdict:
      {
        "verdict": "APPROVE" | "REQUEST_CHANGES" | "BLOCK",
        "layer": "strict",
        "critical_issues": [...],
        "blocking_issues": [...],
        "suggestions": [...]
      }
    ''')
fi

# Step 5: If --comment flag, post to GitHub PR
if [ "$1" = "--comment" ] || [ "$2" = "--comment" ]; then
    echo ""
    echo "Posting review to GitHub PR..."
    gh pr review --comment --body "$(cat /tmp/code-review-output.md)"
fi
```

## Output Format

```
═══════════════════════════════════════
📋 LAYER 1: Baseline Review (4 agents)
═══════════════════════════════════════

✅ CLAUDE.md Compliance: PASS
✅ Bug Detection: PASS (2 potential issues filtered, confidence <80)
✅ Security Scan: PASS
⚠️  History Context: 1 issue

  🟡 WARNING (Confidence: 85%)
  File: backend/auth.py:45
  Issue: Function modified without updating tests
  Context: Tests for this function exist at tests/test_auth.py

═══════════════════════════════════════
🔒 LAYER 2: Strict Review (major change)
═══════════════════════════════════════

Applying strict-code-standards.md...

❌ BLOCKING ISSUES:
  1. Line 67: Function `process_data` is 62 lines (max: 50)
  2. Line 23: Variable name `data` is too vague

⚠️  SUGGESTIONS:
  1. Consider early returns to reduce nesting (line 45)

VERDICT: REQUEST_CHANGES
```

## Integration with Existing Workflow

This command complements (does not replace) your existing gates:

| Gate | Tool | When |
|------|------|------|
| Quick baseline | /code-review (Layer 1) | Every commit |
| Strict review | /code-review --strict | Major changes |
| TPM gate | shadow-code-reviewer | Plan execution |
| UAT | Playwright | Before ship |

## Flags

| Flag | Effect |
|------|--------|
| (none) | Terminal output, baseline + strict (if major change) |
| `--comment` | Posts review to GitHub PR |
| `--strict` | Force strict review even for minor changes |
| `--baseline` | Only baseline, skip strict review |
