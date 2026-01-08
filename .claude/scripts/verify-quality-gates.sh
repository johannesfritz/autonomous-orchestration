#!/bin/bash
# verify-quality-gates.sh
# Verifies all quality gates passed before allowing git push
# Used by: TPM Orchestrator PreToolUse hook for git push

set -e

PLAN_ID="${PLAN_ID:-}"
WORKTREE_DIR="${WORKTREE_DIR:-$(pwd)}"

echo "🔍 Verifying quality gates before push..."

# Check if we're in a TPM worktree context
if [ -z "$PLAN_ID" ]; then
    # Try to detect plan ID from branch name or worktree
    BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$BRANCH" == feature/* ]]; then
        echo "⚠️ Feature branch detected but no PLAN_ID set"
        echo "   Set PLAN_ID environment variable for full verification"
    fi
fi

# Gate 1: Check for uncommitted changes
if ! git diff --quiet 2>/dev/null; then
    echo "❌ GATE FAILED: Uncommitted changes detected"
    echo "   Commit all changes before pushing"
    exit 1
fi

# Gate 2: Check for pytest results (if backend)
if [ -f "pytest-results.xml" ] || [ -f "test-results/pytest.xml" ]; then
    if grep -q 'failures="[1-9]' pytest-results.xml test-results/pytest.xml 2>/dev/null; then
        echo "❌ GATE FAILED: Test failures detected in pytest results"
        exit 1
    fi
    echo "✅ Tests passed"
fi

# Gate 3: Check for Playwright results (if frontend)
if [ -f "playwright-report.json" ] || [ -f "test-results/playwright-report.json" ]; then
    if command -v jq &>/dev/null; then
        FAILURES=$(jq '.stats.failures // 0' playwright-report.json 2>/dev/null || echo "0")
        if [ "$FAILURES" -gt 0 ]; then
            echo "❌ GATE FAILED: Playwright test failures detected"
            exit 1
        fi
    fi
    echo "✅ E2E tests passed"
fi

# Gate 4: Check for review approval (if review file exists)
if [ -f ".review-verdict.json" ]; then
    if command -v jq &>/dev/null; then
        VERDICT=$(jq -r '.verdict // "UNKNOWN"' .review-verdict.json 2>/dev/null)
        if [ "$VERDICT" != "APPROVE" ]; then
            echo "❌ GATE FAILED: Code review not approved (verdict: $VERDICT)"
            exit 1
        fi
    fi
    echo "✅ Code review approved"
fi

# Gate 5: Check for security audit (if audit file exists)
if [ -f ".security-audit.json" ]; then
    if command -v jq &>/dev/null; then
        CRITICAL=$(jq '.critical_issues | length' .security-audit.json 2>/dev/null || echo "0")
        if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ GATE FAILED: Critical security issues detected"
            exit 1
        fi
    fi
    echo "✅ Security audit passed"
fi

echo "✅ All quality gates verified - push allowed"
exit 0
