#!/bin/bash
# wait-for-ci.sh - Check GitHub Actions status after push
# Used by PostToolUse hook on git push
#
# Usage: wait-for-ci.sh [--wait] [--timeout SECONDS] [--branch BRANCH]
# Default: Non-blocking (just reports status)
# --wait: Block until CI completes (use for explicit verification)
# Default timeout (when --wait): 300 seconds (5 minutes)

set -e

# Configuration
WAIT_MODE=false
TIMEOUT=300
POLL_INTERVAL=10
BRANCH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_MODE=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Get current branch if not specified
if [ -z "$BRANCH" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Skip if not on a branch
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
    echo "Not on a branch, skipping CI check"
    exit 0
fi

# Get the latest commit SHA
COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
if [ -z "$COMMIT_SHA" ]; then
    echo "Could not get commit SHA"
    exit 0
fi

SHORT_SHA=$(echo "$COMMIT_SHA" | cut -c1-7)

# Check if gh is available
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) not installed, skipping CI check"
    exit 0
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "GitHub CLI not authenticated, skipping CI check"
    exit 0
fi

# Wait a moment for GitHub to register the push
sleep 2

# Function to check CI status once
check_ci_status() {
    local RUNS=$(gh run list --commit "$COMMIT_SHA" --json databaseId,status,conclusion,name,headBranch 2>/dev/null || echo "[]")
    local RUN_COUNT=$(echo "$RUNS" | jq 'length' 2>/dev/null || echo "0")

    if [ "$RUN_COUNT" = "0" ]; then
        echo "no_runs"
        return
    fi

    local IN_PROGRESS=$(echo "$RUNS" | jq '[.[] | select(.status == "in_progress" or .status == "queued" or .status == "waiting")] | length' 2>/dev/null || echo "0")
    local FAILED=$(echo "$RUNS" | jq '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled")] | length' 2>/dev/null || echo "0")
    local SUCCEEDED=$(echo "$RUNS" | jq '[.[] | select(.conclusion == "success")] | length' 2>/dev/null || echo "0")

    if [ "$IN_PROGRESS" != "0" ]; then
        local IN_PROGRESS_NAMES=$(echo "$RUNS" | jq -r '[.[] | select(.status == "in_progress" or .status == "queued" or .status == "waiting") | .name] | join(", ")' 2>/dev/null || echo "workflows")
        echo "in_progress:$IN_PROGRESS_NAMES"
        return
    fi

    if [ "$FAILED" != "0" ]; then
        local FAILED_NAMES=$(echo "$RUNS" | jq -r '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled") | .name] | join(", ")' 2>/dev/null || echo "workflows")
        echo "failed:$FAILED_NAMES"
        return
    fi

    if [ "$SUCCEEDED" != "0" ]; then
        echo "success:$SUCCEEDED"
        return
    fi

    echo "unknown"
}

# Non-blocking mode: just report status and exit
if [ "$WAIT_MODE" = "false" ]; then
    echo ""
    echo "--- GitHub Actions Status (commit $SHORT_SHA) ---"

    STATUS=$(check_ci_status)

    case "$STATUS" in
        no_runs)
            echo "Workflows starting... (check status: gh run list --commit $SHORT_SHA)"
            echo "TPM: Proceed with next plan. Verify CI before marking SHIPPED."
            ;;
        in_progress:*)
            NAMES="${STATUS#in_progress:}"
            echo "CI in progress: $NAMES"
            echo "TPM: Proceed with next plan. Verify CI before marking SHIPPED."
            ;;
        failed:*)
            NAMES="${STATUS#failed:}"
            echo "CI FAILED: $NAMES"
            echo "Fix required before this plan can be SHIPPED."
            ;;
        success:*)
            COUNT="${STATUS#success:}"
            echo "CI PASSED ($COUNT workflow(s))"
            ;;
        *)
            echo "Status unknown. Check: gh run list --commit $SHORT_SHA"
            ;;
    esac

    echo "---"
    exit 0
fi

# Wait mode: block until CI completes
echo "Waiting for GitHub Actions to complete (timeout: ${TIMEOUT}s)..."

START_TIME=$(date +%s)
FOUND_RUN=false

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ""
        echo "Timeout waiting for CI (${TIMEOUT}s). Check manually: gh run list --commit $SHORT_SHA"
        exit 1
    fi

    STATUS=$(check_ci_status)

    case "$STATUS" in
        no_runs)
            if [ "$FOUND_RUN" = "false" ]; then
                echo "Waiting for workflow to start... (${ELAPSED}s/${TIMEOUT}s)"
                sleep $POLL_INTERVAL
                continue
            else
                echo "Runs disappeared - check GitHub manually"
                exit 1
            fi
            ;;
        in_progress:*)
            FOUND_RUN=true
            NAMES="${STATUS#in_progress:}"
            echo "CI in progress: $NAMES (${ELAPSED}s/${TIMEOUT}s)"
            sleep $POLL_INTERVAL
            continue
            ;;
        failed:*)
            NAMES="${STATUS#failed:}"
            echo ""
            echo "CI FAILED: $NAMES"
            echo "View details: gh run list --commit $SHORT_SHA"
            exit 1
            ;;
        success:*)
            COUNT="${STATUS#success:}"
            echo ""
            echo "CI PASSED ($COUNT workflow(s) succeeded)"
            exit 0
            ;;
        *)
            echo "CI completed with unknown state. Check: gh run list --commit $SHORT_SHA"
            exit 0
            ;;
    esac
done
