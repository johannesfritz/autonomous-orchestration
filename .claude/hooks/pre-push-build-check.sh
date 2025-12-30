#!/bin/bash
# Pre-push build verification hook for Claude Code
# Runs builds/tests for modified projects before allowing git push
# Exit code 2 blocks the push and feeds stderr to Claude
#
# CUSTOMIZATION: Edit the PROJECT_CHECKS array below to define your projects.
# Each entry: "path_pattern|build_command|description"

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
cd "$PROJECT_DIR"

# ============================================================================
# PROJECT CONFIGURATION - Customize this section for your project
# ============================================================================
# Format: "path_pattern|build_command|description"
# - path_pattern: Glob pattern for files that trigger this check
# - build_command: Command to run (relative to PROJECT_DIR)
# - description: Human-readable name for output
#
# Examples:
#   "frontend/**|cd frontend && npm run build|Frontend TypeScript"
#   "backend/**|cd backend && ./venv/bin/pytest -q|Backend Tests"
#   "src/**/*.ts|npm run typecheck|TypeScript Check"

PROJECT_CHECKS=(
    # Add your project checks here:
    # "frontend/**|cd frontend && npm run build|Frontend Build"
    # "backend/**|cd backend && pytest -q|Backend Tests"
    # "src/**/*.py|mypy src/|Type Checking"
)

# ============================================================================
# END CONFIGURATION
# ============================================================================

# Get list of files that would be pushed
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_REF="origin/$CURRENT_BRANCH"

# Check if remote branch exists
if ! git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
    REMOTE_REF="origin/main"
    if ! git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
        REMOTE_REF="origin/master"
    fi
fi

# Get changed files
CHANGED_FILES=$(git diff --name-only "$REMOTE_REF"...HEAD 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    echo "No changes detected, skipping build verification."
    exit 0
fi

BUILD_FAILED=0
BUILDS_RUN=0

# Check if no project checks are configured
if [ ${#PROJECT_CHECKS[@]} -eq 0 ]; then
    echo "No project checks configured in pre-push-build-check.sh"
    echo "Edit the PROJECT_CHECKS array to add your build/test commands."
    exit 0
fi

# Run checks for each configured project
for check in "${PROJECT_CHECKS[@]}"; do
    # Skip empty entries
    [ -z "$check" ] && continue

    # Parse the check configuration
    IFS='|' read -r pattern command description <<< "$check"

    # Check if any changed files match the pattern
    # Use git ls-files with the pattern to check for matches
    if echo "$CHANGED_FILES" | grep -qE "^${pattern//\*\*/.*}"; then
        echo "Running: $description..."
        BUILDS_RUN=$((BUILDS_RUN + 1))

        if ! (cd "$PROJECT_DIR" && eval "$command" 2>&1); then
            echo "" >&2
            echo "FAILED: $description" >&2
            echo "Fix the issues before pushing." >&2
            BUILD_FAILED=1
        else
            echo "$description passed"
        fi
    fi
done

if [ $BUILDS_RUN -eq 0 ]; then
    echo "No build-relevant changes detected, skipping build verification."
fi

if [ $BUILD_FAILED -eq 1 ]; then
    echo "" >&2
    echo "PUSH BLOCKED: One or more builds/tests failed." >&2
    echo "Fix the issues above and try again." >&2
    exit 2  # Exit code 2 blocks the action in Claude Code hooks
fi

if [ $BUILDS_RUN -gt 0 ]; then
    echo "All checks passed. Push approved."
fi

exit 0
