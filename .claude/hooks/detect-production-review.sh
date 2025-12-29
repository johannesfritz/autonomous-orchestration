#!/bin/bash
# Hook: Detect review requests and inject appropriate checklist
# Two levels:
#   1. Full UAT: "production ready", "UAT", "final review"
#   2. Quick verify: "does this work", "test this", "verify"

# Read the user prompt from stdin (JSON format)
INPUT=$(cat)

# Level 1: Full production-ready review (UAT + user journeys)
if echo "$INPUT" | grep -qiE "(production.?ready|prod.?ready|UAT|senior.?review|final.?review|ready.?for.?deploy|ready.?to.?deploy|ship.?it|deploy.?ready|full.?review|comprehensive.?review)"; then
    cat "$CLAUDE_PROJECT_DIR/.claude/protocols/production-ready-checklist.md"
    exit 0
fi

# Level 2: Quick verification reminder (for smaller changes)
if echo "$INPUT" | grep -qiE "(does.?this.?work|test.?this|verify.?this|check.?this|is.?this.?correct|did.?it.?work|working\?)"; then
    echo "## Quick Verification Required"
    echo ""
    echo "Before confirming this works, you MUST:"
    echo "1. Run the relevant test: \`pytest -v\` or \`npm run build\`"
    echo "2. Report the actual result (pass/fail count)"
    echo "3. If it's a UI change, verify visually"
    echo ""
    echo "Do NOT say 'should work' - provide evidence it DOES work."
    exit 0
fi

# No trigger - exit silently
exit 0
