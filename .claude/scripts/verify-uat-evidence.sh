#!/bin/bash
# verify-uat-evidence.sh
# Verifies UAT produced actual evidence (not just checklist)
# Used by: local-uat skill Stop hook

set -e

PLAN_ID="${PLAN_ID:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/user/jf-private}"
EVIDENCE_BASE="$PROJECT_DIR/00 Inbox/uat-evidence"

echo "🔍 Verifying UAT evidence..."

# If PLAN_ID is set, check specific evidence
if [ -n "$PLAN_ID" ]; then
    EVIDENCE_DIR="$EVIDENCE_BASE/$PLAN_ID"

    if [ ! -d "$EVIDENCE_DIR" ]; then
        echo "⚠️ Evidence directory not found: $EVIDENCE_DIR"
        echo "   UAT may not have been executed yet"
        echo ""
        echo "Expected evidence:"
        echo "  - $EVIDENCE_DIR/playwright-report.json"
        echo "  - $EVIDENCE_DIR/screenshots/"
        exit 0
    fi

    echo "✅ Evidence directory exists: $EVIDENCE_DIR"

    # Check for Playwright report
    if [ -f "$EVIDENCE_DIR/playwright-report.json" ]; then
        echo "✅ Playwright report found"

        if command -v jq &>/dev/null; then
            TOTAL=$(jq '.stats.expected // 0' "$EVIDENCE_DIR/playwright-report.json" 2>/dev/null || echo "0")
            PASSED=$(jq '.stats.expected - .stats.failures // 0' "$EVIDENCE_DIR/playwright-report.json" 2>/dev/null || echo "0")
            FAILED=$(jq '.stats.failures // 0' "$EVIDENCE_DIR/playwright-report.json" 2>/dev/null || echo "0")

            echo "   Tests: $PASSED passed, $FAILED failed (total: $TOTAL)"

            if [ "$FAILED" -gt 0 ]; then
                echo "⚠️ Some tests failed - review before shipping"
            fi
        fi
    else
        echo "⚠️ No Playwright report found"
        echo "   Expected: $EVIDENCE_DIR/playwright-report.json"
    fi

    # Check for screenshots
    SCREENSHOT_COUNT=$(find "$EVIDENCE_DIR" -name "*.png" 2>/dev/null | wc -l)
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        echo "✅ Screenshots found: $SCREENSHOT_COUNT files"
    else
        echo "ℹ️ No screenshots found (optional)"
    fi

else
    # No PLAN_ID - general verification
    echo "ℹ️ No PLAN_ID set - checking for any recent evidence..."

    if [ -d "$EVIDENCE_BASE" ]; then
        RECENT_DIRS=$(ls -t "$EVIDENCE_BASE" 2>/dev/null | head -3)
        if [ -n "$RECENT_DIRS" ]; then
            echo "Recent UAT evidence directories:"
            echo "$RECENT_DIRS" | while read -r dir; do
                echo "  - $dir"
            done
        else
            echo "⚠️ No evidence directories found"
        fi
    else
        echo "⚠️ Evidence base directory not found: $EVIDENCE_BASE"
    fi
fi

echo ""
echo "══════════════════════════════════════════════════════════"
echo "📋 UAT EVIDENCE CHECKLIST"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "Before completing UAT, verify:"
echo ""
echo "  □ Playwright tests were EXECUTED (not just written)"
echo "  □ All critical user journeys tested"
echo "  □ Evidence stored in 00 Inbox/uat-evidence/{PLAN_ID}/"
echo "  □ Test results reviewed for failures"
echo "  □ Screenshots captured for visual verification"
echo ""
echo "Checklist-only UAT is INSUFFICIENT for shipping."
echo "══════════════════════════════════════════════════════════"
echo ""

exit 0
