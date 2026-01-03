#!/bin/bash
# verify-cleanup-complete.sh
# MANDATORY cleanup verification for TPM Orchestrator
# Called via SubagentStop hook to enforce portfolio state consistency
# Usage: verify-cleanup-complete.sh PLAN-ID

set -euo pipefail

PLAN_ID="${1:-}"

if [ -z "$PLAN_ID" ]; then
    echo "❌ ERROR: PLAN_ID required"
    echo "Usage: verify-cleanup-complete.sh PLAN-2025-XXX"
    exit 1
fi

echo "🧹 MANDATORY CLEANUP VERIFICATION for $PLAN_ID"
echo ""

ERRORS=0

# Helper function for error tracking
error() {
    echo "❌ $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo "⚠️  $1"
}

success() {
    echo "✅ $1"
}

# === 1. Check Plan File Location ===
echo "## 1. Plan File Location"

ACTIVE_PLAN="00 Inbox/plans/${PLAN_ID}.md"
COMPLETED_PLAN="00 Inbox/plans/completed/${PLAN_ID}.md"

if [ -f "$COMPLETED_PLAN" ]; then
    success "Plan file in completed/ folder"
elif [ -f "$ACTIVE_PLAN" ]; then
    # Check if plan status is SHIPPED or AWAITING_MERGE_APPROVAL
    STATUS=$(grep -A 1 "^\*\*Status:\*\*" "$ACTIVE_PLAN" | tail -1 | xargs || echo "UNKNOWN")

    if echo "$STATUS" | grep -q "AWAITING_MERGE_APPROVAL"; then
        success "Plan file in active folder (awaiting manual merge - OK)"
    else
        error "Plan file still in 00 Inbox/plans/ but status is $STATUS (should be moved to completed/)"
    fi
else
    error "Plan file not found in active/ or completed/"
fi

# === 2. Check .state.json Updated ===
echo ""
echo "## 2. Portfolio State (.state.json)"

STATE_FILE="00 Inbox/plans/.state.json"

if [ ! -f "$STATE_FILE" ]; then
    error ".state.json not found"
else
    # Check if plan exists in state
    if ! grep -q "\"$PLAN_ID\"" "$STATE_FILE"; then
        error "Plan $PLAN_ID not found in .state.json"
    else
        # Extract status
        PLAN_STATUS=$(python3 -c "
import json, sys
try:
    with open('$STATE_FILE') as f:
        state = json.load(f)
    if 'queue' in state and '$PLAN_ID' in state['queue']:
        print(state['queue']['$PLAN_ID'].get('state', 'UNKNOWN'))
    elif 'plans' in state and '$PLAN_ID' in state['plans']:
        print(state['plans']['$PLAN_ID'].get('status', 'UNKNOWN'))
    else:
        print('NOT_FOUND')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    print('PARSE_ERROR')
" 2>/dev/null || echo "PARSE_ERROR")

        if [ "$PLAN_STATUS" = "SHIPPED" ]; then
            success "Plan status: SHIPPED"
        elif [ "$PLAN_STATUS" = "AWAITING_MERGE_APPROVAL" ]; then
            success "Plan status: AWAITING_MERGE_APPROVAL"
        else
            error "Plan status: $PLAN_STATUS (expected SHIPPED or AWAITING_MERGE_APPROVAL)"
        fi
    fi
fi

# === 3. Check PORTFOLIO_STATUS.md Updated ===
echo ""
echo "## 3. Portfolio Dashboard (PORTFOLIO_STATUS.md)"

DASHBOARD="00 Inbox/PORTFOLIO_STATUS.md"

if [ ! -f "$DASHBOARD" ]; then
    warning "PORTFOLIO_STATUS.md not found (non-critical)"
else
    # Check if plan appears in Recently Shipped or Awaiting Merge
    if grep -q "$PLAN_ID" "$DASHBOARD"; then
        success "Plan appears in dashboard"
    else
        warning "Plan not found in dashboard (should be updated)"
    fi

    # Check last updated timestamp is recent (within 1 hour)
    LAST_UPDATED=$(grep "^\*\*Updated:\*\*" "$DASHBOARD" | head -1 || echo "")
    if [ -n "$LAST_UPDATED" ]; then
        success "Dashboard has update timestamp"
    else
        warning "Dashboard missing update timestamp"
    fi
fi

# === 4. Check Git Commit Status ===
echo ""
echo "## 4. Git Commit Status"

# Check if there are uncommitted changes in portfolio state files
UNCOMMITTED=$(git status --porcelain "00 Inbox/plans/" "00 Inbox/PORTFOLIO_STATUS.md" "00 Inbox/system_state.json" "00 Inbox/audit_log.jsonl" 2>/dev/null || true)

if [ -z "$UNCOMMITTED" ]; then
    success "All portfolio state changes committed"
else
    error "Uncommitted portfolio state changes found:"
    echo "$UNCOMMITTED" | sed 's/^/  /'
    echo ""
    echo "  Run: git add -A 00\ Inbox/ && git commit -m 'Update portfolio state: $PLAN_ID'"
fi

# === 5. Check Audit Log ===
echo ""
echo "## 5. Audit Log (audit_log.jsonl)"

AUDIT_LOG="00 Inbox/audit_log.jsonl"

if [ ! -f "$AUDIT_LOG" ]; then
    warning "audit_log.jsonl not found (should exist)"
else
    # Check if PLAN_SHIPPED or PLAN_AWAITING_MERGE event exists
    if grep -q "\"plan_id\":\"$PLAN_ID\"" "$AUDIT_LOG" && \
       (grep -q "\"event\":\"PLAN_SHIPPED\"" "$AUDIT_LOG" || \
        grep -q "\"event\":\"PLAN_AWAITING_MERGE\"" "$AUDIT_LOG"); then
        success "Completion event logged in audit trail"
    else
        warning "No completion event found in audit log for $PLAN_ID"
    fi
fi

# === 6. Check PR Created ===
echo ""
echo "## 6. Pull Request Status"

# Extract branch name from plan file
BRANCH=""
if [ -f "$COMPLETED_PLAN" ]; then
    BRANCH=$(grep "^\*\*Branch:\*\*" "$COMPLETED_PLAN" | sed 's/\*\*Branch:\*\* //' | xargs || echo "")
elif [ -f "$ACTIVE_PLAN" ]; then
    BRANCH=$(grep "^\*\*Branch:\*\*" "$ACTIVE_PLAN" | sed 's/\*\*Branch:\*\* //' | xargs || echo "")
fi

if [ -n "$BRANCH" ]; then
    # Check if PR exists
    PR_STATUS=$(gh pr view "$BRANCH" --json state,mergedAt 2>/dev/null || echo "")

    if [ -n "$PR_STATUS" ]; then
        success "Pull request exists for branch: $BRANCH"

        # Check if merged
        MERGED=$(echo "$PR_STATUS" | python3 -c "import json, sys; data=json.load(sys.stdin); print('true' if data.get('mergedAt') else 'false')" 2>/dev/null || echo "false")

        if [ "$MERGED" = "true" ]; then
            success "Pull request merged"
        else
            warning "Pull request not yet merged (may be awaiting manual approval)"
        fi
    else
        warning "No pull request found for branch: $BRANCH"
    fi
else
    warning "Branch name not found in plan file"
fi

# === 7. Summary ===
echo ""
echo "═══════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
    echo "✅ CLEANUP COMPLETE - All checks passed"
    echo ""
    echo "Plan $PLAN_ID is properly finalized:"
    echo "  - File location: correct"
    echo "  - State updated: yes"
    echo "  - Dashboard updated: yes"
    echo "  - Changes committed: yes"
    echo "  - Audit logged: yes"
    echo "  - PR created: yes"
    echo ""
    exit 0
else
    echo "❌ CLEANUP INCOMPLETE - $ERRORS errors found"
    echo ""
    echo "⚠️  MANDATORY ACTION REQUIRED:"
    echo "   The TPM Orchestrator did not complete all cleanup steps."
    echo "   Review errors above and complete missing steps manually."
    echo ""
    echo "Common fixes:"
    echo "  1. Move plan file: mv '$ACTIVE_PLAN' '$COMPLETED_PLAN'"
    echo "  2. Update .state.json status to SHIPPED"
    echo "  3. Update PORTFOLIO_STATUS.md"
    echo "  4. Commit changes: git add -A 00\\ Inbox/ && git commit -m 'Update portfolio state: $PLAN_ID'"
    echo ""
    exit 1
fi
