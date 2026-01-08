#!/bin/bash
# verify-ci-passed.sh
# Verifies CI has passed before allowing PR merge
# Used by: TPM Orchestrator PreToolUse hook for gh pr merge

set -e

PR_NUMBER="${1:-}"
TIMEOUT="${2:-300}"

echo "🔍 Verifying CI status before merge..."

# Extract PR number from command if not provided
if [ -z "$PR_NUMBER" ]; then
    # Try to get current PR number
    PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null || echo "")
fi

if [ -z "$PR_NUMBER" ]; then
    echo "⚠️ No PR number detected - skipping CI verification"
    echo "   If this is a PR merge, pass the PR number as argument"
    exit 0
fi

echo "📊 Checking CI status for PR #$PR_NUMBER..."

# Get PR check status
CHECK_STATUS=$(gh pr checks "$PR_NUMBER" --json state,name 2>/dev/null || echo "")

if [ -z "$CHECK_STATUS" ]; then
    echo "⚠️ Could not fetch CI status - proceeding with caution"
    exit 0
fi

# Check for failures
FAILED_CHECKS=$(echo "$CHECK_STATUS" | jq -r '.[] | select(.state == "FAILURE") | .name' 2>/dev/null || echo "")

if [ -n "$FAILED_CHECKS" ]; then
    echo "❌ GATE FAILED: CI checks have failed"
    echo ""
    echo "Failed checks:"
    echo "$FAILED_CHECKS" | while read -r check; do
        echo "  - $check"
    done
    echo ""
    echo "Fix the failing checks before merging."
    exit 1
fi

# Check for pending
PENDING_CHECKS=$(echo "$CHECK_STATUS" | jq -r '.[] | select(.state == "PENDING" or .state == "QUEUED" or .state == "IN_PROGRESS") | .name' 2>/dev/null || echo "")

if [ -n "$PENDING_CHECKS" ]; then
    echo "⏳ CI checks still running:"
    echo "$PENDING_CHECKS" | while read -r check; do
        echo "  - $check"
    done
    echo ""
    echo "Wait for CI to complete before merging, or use --wait flag"

    # If WAIT_FOR_CI is set, wait for completion
    if [ "${WAIT_FOR_CI:-false}" = "true" ]; then
        echo "Waiting for CI to complete (timeout: ${TIMEOUT}s)..."
        gh pr checks "$PR_NUMBER" --watch --timeout "$TIMEOUT"
        exit $?
    fi

    exit 1
fi

echo "✅ All CI checks passed - merge allowed"
exit 0
