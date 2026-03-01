#!/bin/bash
#
# verify-uat-executed.sh
#
# Verifies that UAT was actually EXECUTED (not just checklist created).
# Called by SubagentStop hook for tpm-orchestrator.
#
# Exit codes:
#   0 - UAT execution verified
#   1 - UAT execution evidence missing
#   2 - UAT execution failed (tests didn't pass)
#

set -e

REPO_ROOT="${CLAUDE_PROJECT_DIR:-/home/user/jf-private}"
PLAN_ID="${1:-$(cat /tmp/current-tpm-plan-id 2>/dev/null || echo '')}"

if [ -z "$PLAN_ID" ]; then
    echo "⚠️ No PLAN_ID provided, skipping UAT verification"
    exit 0
fi

echo "🔍 Verifying UAT execution for $PLAN_ID..."

# Check for evidence directory
EVIDENCE_DIR="$REPO_ROOT/inbox/uat-evidence/$PLAN_ID"

if [ ! -d "$EVIDENCE_DIR" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "❌ BLOCKING: UAT EXECUTION EVIDENCE NOT FOUND"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Expected evidence at: $EVIDENCE_DIR"
    echo ""
    echo "This means Playwright tests were NOT actually run."
    echo "A checklist file alone is INSUFFICIENT."
    echo ""
    echo "Required evidence:"
    echo "  - uat-evidence/$PLAN_ID/playwright-report.json"
    echo "  - uat-evidence/$PLAN_ID/ (screenshots, traces)"
    echo ""
    echo "To fix:"
    echo "  1. Start local stack: .claude/scripts/start-local-stack.sh [project]"
    echo "  2. Run UAT tests: npx playwright test tests/uat/${PLAN_ID}.spec.ts"
    echo "  3. Save evidence to uat-evidence/${PLAN_ID}/"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    exit 1
fi

# Check for Playwright report
REPORT_FILE="$EVIDENCE_DIR/playwright-report.json"

if [ ! -f "$REPORT_FILE" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "❌ BLOCKING: PLAYWRIGHT REPORT NOT FOUND"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Evidence directory exists but no playwright-report.json"
    echo ""
    echo "This could mean:"
    echo "  - Tests were started but didn't complete"
    echo "  - Wrong output format used"
    echo "  - Report not copied to evidence directory"
    echo ""
    echo "To fix:"
    echo "  npx playwright test tests/uat/${PLAN_ID}.spec.ts --reporter=json > $REPORT_FILE"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    exit 1
fi

# Parse report for failures
FAILURES=$(jq '.stats.failures // 0' "$REPORT_FILE" 2>/dev/null || echo "-1")
TESTS_RUN=$(jq '.stats.expected // 0' "$REPORT_FILE" 2>/dev/null || echo "0")

if [ "$FAILURES" = "-1" ]; then
    echo "⚠️ Could not parse Playwright report (invalid JSON?)"
    echo "   Report file: $REPORT_FILE"
    exit 1
fi

if [ "$TESTS_RUN" = "0" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "❌ BLOCKING: NO TESTS WERE RUN"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Playwright report exists but shows 0 tests executed."
    echo "This could mean:"
    echo "  - Test file is empty"
    echo "  - Test patterns didn't match"
    echo "  - Test file has syntax errors"
    echo ""
    echo "To fix:"
    echo "  1. Check test file exists: tests/uat/${PLAN_ID}.spec.ts"
    echo "  2. Run: npx playwright test tests/uat/${PLAN_ID}.spec.ts --debug"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    exit 2
fi

if [ "$FAILURES" != "0" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "❌ BLOCKING: UAT TESTS FAILED ($FAILURES failures)"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Playwright tests were run but $FAILURES test(s) failed."
    echo ""
    echo "Failed tests:"
    jq -r '.suites[]?.specs[]? | select(.ok == false) | "  - \(.title)"' "$REPORT_FILE" 2>/dev/null || echo "  (parse error)"
    echo ""
    echo "To debug:"
    echo "  npx playwright test tests/uat/${PLAN_ID}.spec.ts --headed --debug"
    echo ""
    echo "Do NOT mark plan as SHIPPED until all UAT tests pass."
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    exit 2
fi

# Success!
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ UAT EXECUTION VERIFIED"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Plan: $PLAN_ID"
echo "Tests run: $TESTS_RUN"
echo "Failures: $FAILURES"
echo "Evidence: $EVIDENCE_DIR"
echo ""
echo "UAT gate passed. Plan may proceed to shipment."
echo "═══════════════════════════════════════════════════════════════════"

exit 0
