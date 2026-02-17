#!/bin/bash
# verify-plan-state-updated.sh
# Verifies plan state has been properly updated before TPM completes
# Used by: TPM Orchestrator Stop hook

set -e

PLAN_ID="${PLAN_ID:-}"
STATE_FILE="${CLAUDE_PROJECT_DIR:-/home/user/jf-private}/inbox/plans/.state.json"
DASHBOARD_FILE="${CLAUDE_PROJECT_DIR:-/home/user/jf-private}/inbox/PORTFOLIO_STATUS.md"

echo "🔍 Verifying plan state updates..."

# If no PLAN_ID, try to detect from environment or recent activity
if [ -z "$PLAN_ID" ]; then
    echo "⚠️ No PLAN_ID set - skipping state verification"
    echo "   Set PLAN_ID environment variable for full verification"
    exit 0
fi

ERRORS=0

# Check 1: State file exists
if [ ! -f "$STATE_FILE" ]; then
    echo "❌ State file not found: $STATE_FILE"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ State file exists"

    # Check 2: Plan exists in state file
    if command -v jq &>/dev/null; then
        PLAN_STATUS=$(jq -r --arg id "$PLAN_ID" '.plans[$id].status // "NOT_FOUND"' "$STATE_FILE" 2>/dev/null || echo "NOT_FOUND")

        if [ "$PLAN_STATUS" = "NOT_FOUND" ]; then
            echo "❌ Plan $PLAN_ID not found in state file"
            ERRORS=$((ERRORS + 1))
        else
            echo "✅ Plan $PLAN_ID found in state (status: $PLAN_STATUS)"

            # Check 3: Status is terminal (SHIPPED, FAILED_*, or AWAITING_*)
            case "$PLAN_STATUS" in
                SHIPPED|FAILED_*|AWAITING_*)
                    echo "✅ Plan has terminal status"
                    ;;
                EXECUTING)
                    echo "⚠️ Plan still marked as EXECUTING - update status before completing"
                    ERRORS=$((ERRORS + 1))
                    ;;
                *)
                    echo "⚠️ Unexpected status: $PLAN_STATUS"
                    ;;
            esac

            # Check 4: Timestamp updated recently
            LAST_UPDATED=$(jq -r --arg id "$PLAN_ID" '.plans[$id].last_updated // "NEVER"' "$STATE_FILE" 2>/dev/null || echo "NEVER")
            if [ "$LAST_UPDATED" = "NEVER" ]; then
                echo "⚠️ No last_updated timestamp in state"
            else
                echo "✅ Last updated: $LAST_UPDATED"
            fi
        fi
    else
        echo "⚠️ jq not available - skipping detailed state checks"
    fi
fi

# Check 5: Dashboard exists and is recent
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "⚠️ Dashboard file not found: $DASHBOARD_FILE"
else
    echo "✅ Dashboard file exists"

    # Check if plan is mentioned in dashboard
    if grep -q "$PLAN_ID" "$DASHBOARD_FILE" 2>/dev/null; then
        echo "✅ Plan $PLAN_ID found in dashboard"
    else
        echo "⚠️ Plan $PLAN_ID not found in dashboard - update dashboard"
    fi
fi

# Summary
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ State verification found $ERRORS issue(s)"
    echo "   Complete the following before finishing:"
    echo "   1. Update plan status in .state.json"
    echo "   2. Update PORTFOLIO_STATUS.md dashboard"
    echo "   3. Move plan file to completed/ if shipped"
    exit 1
else
    echo ""
    echo "✅ Plan state verification passed"
    exit 0
fi
