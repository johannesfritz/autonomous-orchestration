#!/bin/bash
# Pre-push build verification hook for Claude Code
# Runs TypeScript builds for modified projects before allowing git push
# Exit code 2 blocks the push and feeds stderr to Claude

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
cd "$PROJECT_DIR"

# Get list of staged/committed files that would be pushed
# Compare current branch to origin
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_REF="origin/$CURRENT_BRANCH"

# Check if remote branch exists
if ! git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
    # New branch, compare to origin/main
    REMOTE_REF="origin/main"
fi

# Get changed files
CHANGED_FILES=$(git diff --name-only "$REMOTE_REF"...HEAD 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || echo "")

BUILD_FAILED=0
BUILDS_RUN=0

# Check if Stellaris frontend has changes
if echo "$CHANGED_FILES" | grep -q "^stellaris/frontend/"; then
    echo "Building Stellaris frontend..."
    BUILDS_RUN=$((BUILDS_RUN + 1))

    if ! (cd "$PROJECT_DIR/stellaris/frontend" && npm run build 2>&1); then
        echo "" >&2
        echo "BUILD FAILED: Stellaris frontend" >&2
        echo "Fix TypeScript errors before pushing." >&2
        BUILD_FAILED=1
    else
        echo "Stellaris frontend build passed"
    fi
fi

# Check if Hotel de Ville frontend has changes
if echo "$CHANGED_FILES" | grep -q "^hotel-de-ville/frontend/"; then
    echo "Building Hotel de Ville frontend..."
    BUILDS_RUN=$((BUILDS_RUN + 1))

    if ! (cd "$PROJECT_DIR/hotel-de-ville/frontend" && npm run build 2>&1); then
        echo "" >&2
        echo "BUILD FAILED: Hotel de Ville frontend" >&2
        echo "Fix TypeScript errors before pushing." >&2
        BUILD_FAILED=1
    else
        echo "Hotel de Ville frontend build passed"
    fi
fi

# Check if Stellaris backend has changes (run pytest)
if echo "$CHANGED_FILES" | grep -q "^stellaris/backend/"; then
    echo "Testing Stellaris backend..."
    BUILDS_RUN=$((BUILDS_RUN + 1))

    if [ -f "$PROJECT_DIR/stellaris/backend/venv/bin/pytest" ]; then
        if ! (cd "$PROJECT_DIR/stellaris/backend" && ./venv/bin/pytest -q 2>&1); then
            echo "" >&2
            echo "TESTS FAILED: Stellaris backend" >&2
            echo "Fix failing tests before pushing." >&2
            BUILD_FAILED=1
        else
            echo "Stellaris backend tests passed"
        fi
    fi
fi

# Check if Hotel de Ville backend has changes (run pytest)
if echo "$CHANGED_FILES" | grep -q "^hotel-de-ville/backend/"; then
    echo "Testing Hotel de Ville backend..."
    BUILDS_RUN=$((BUILDS_RUN + 1))

    if [ -f "$PROJECT_DIR/hotel-de-ville/backend/venv/bin/pytest" ]; then
        if ! (cd "$PROJECT_DIR/hotel-de-ville/backend" && ./venv/bin/pytest -q 2>&1); then
            echo "" >&2
            echo "TESTS FAILED: Hotel de Ville backend" >&2
            echo "Fix failing tests before pushing." >&2
            BUILD_FAILED=1
        else
            echo "Hotel de Ville backend tests passed"
        fi
    fi
fi

if [ $BUILDS_RUN -eq 0 ]; then
    echo "No build-relevant changes detected, skipping build verification."
fi

if [ $BUILD_FAILED -eq 1 ]; then
    echo "" >&2
    echo "PUSH BLOCKED: One or more builds/tests failed." >&2
    echo "Fix the issues above and try again." >&2
    exit 2  # Exit code 2 blocks the action in Claude Code hooks
fi

echo "All builds passed. Push approved."
exit 0
