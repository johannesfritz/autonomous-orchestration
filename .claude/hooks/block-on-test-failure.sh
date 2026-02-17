#!/bin/bash
# block-on-test-failure.sh
# Pre-push hook that BLOCKS git push if tests fail
#
# Purpose: Enforce quality gate - tests MUST pass before code can be pushed
# Used by: PreToolUse hook on Bash(git push *)
# Exit code: 0 = tests pass (allow push), 1 = tests fail (block push)

set -e

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY QUALITY GATE: Running Tests Before Push"
echo "════════════════════════════════════════════════════════"
echo ""

# Navigate to repo root
cd "$CLAUDE_PROJECT_DIR" || { echo -e "${RED}❌ Could not find project directory${NC}"; exit 1; }

# Track whether any tests failed
TESTS_FAILED=false

# Detect which files are being pushed (staged changes)
MODIFIED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

if [ -z "$MODIFIED_FILES" ]; then
    echo -e "${YELLOW}⚠️  No staged changes detected${NC}"
    echo "If you're pushing already-committed code, tests will run in CI/CD"
    echo "Allowing push to proceed..."
    exit 0
fi

echo "Modified files:"
echo "$MODIFIED_FILES"
echo ""

# =========================================
# Check: hotel-de-ville Backend
# =========================================
if echo "$MODIFIED_FILES" | grep -q "^hotel-de-ville/backend/"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: hotel-de-ville/backend"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "hotel-de-ville/backend" ]; then
        echo -e "${YELLOW}⚠️  hotel-de-ville/backend directory not found${NC}"
    else
        cd hotel-de-ville/backend

        # Activate virtual environment if it exists
        if [ -d "venv" ]; then
            source venv/bin/activate
        elif [ -d ".venv" ]; then
            source .venv/bin/activate
        fi

        # Run pytest
        echo "Running: pytest --tb=short --no-header -q"
        if pytest --tb=short --no-header -q; then
            echo -e "${GREEN}✅ hotel-de-ville/backend tests PASSED${NC}"
        else
            echo -e "${RED}❌ hotel-de-ville/backend tests FAILED${NC}"
            TESTS_FAILED=true
        fi

        cd "$CLAUDE_PROJECT_DIR"
    fi
    echo ""
fi

# =========================================
# Check: hotel-de-ville Frontend
# =========================================
if echo "$MODIFIED_FILES" | grep -q "^hotel-de-ville/frontend/"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: hotel-de-ville/frontend"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "hotel-de-ville/frontend" ]; then
        echo -e "${YELLOW}⚠️  hotel-de-ville/frontend directory not found${NC}"
    else
        cd hotel-de-ville/frontend

        # Run build (verifies TypeScript compiles)
        echo "Running: npm run build"
        if npm run build; then
            echo -e "${GREEN}✅ hotel-de-ville/frontend build PASSED${NC}"
        else
            echo -e "${RED}❌ hotel-de-ville/frontend build FAILED${NC}"
            TESTS_FAILED=true
        fi

        # Run Playwright E2E tests
        echo ""
        echo "Running: npx playwright test"
        if npx playwright test; then
            echo -e "${GREEN}✅ hotel-de-ville/frontend E2E tests PASSED${NC}"
        else
            echo -e "${RED}❌ hotel-de-ville/frontend E2E tests FAILED${NC}"
            TESTS_FAILED=true
        fi

        cd "$CLAUDE_PROJECT_DIR"
    fi
    echo ""
fi

# =========================================
# Check: shadow-api
# =========================================
if echo "$MODIFIED_FILES" | grep -q "^shadow-api/"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: shadow-api"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "shadow-api" ]; then
        echo -e "${YELLOW}⚠️  shadow-api directory not found${NC}"
    else
        cd shadow-api

        # Activate virtual environment if it exists
        if [ -d "venv" ]; then
            source venv/bin/activate
        elif [ -d ".venv" ]; then
            source .venv/bin/activate
        fi

        # Run pytest
        echo "Running: pytest --tb=short --no-header -q"
        if pytest --tb=short --no-header -q; then
            echo -e "${GREEN}✅ shadow-api tests PASSED${NC}"
        else
            echo -e "${RED}❌ shadow-api tests FAILED${NC}"
            TESTS_FAILED=true
        fi

        cd "$CLAUDE_PROJECT_DIR"
    fi
    echo ""
fi

# =========================================
# Check: stellaris Backend
# =========================================
if echo "$MODIFIED_FILES" | grep -q "^stellaris/backend/"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: stellaris/backend"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "stellaris/backend" ]; then
        echo -e "${YELLOW}⚠️  stellaris/backend directory not found${NC}"
    else
        cd stellaris/backend

        # Activate virtual environment if it exists
        if [ -d "venv" ]; then
            source venv/bin/activate
        elif [ -d ".venv" ]; then
            source .venv/bin/activate
        fi

        # Run pytest
        echo "Running: pytest --tb=short --no-header -q"
        if pytest --tb=short --no-header -q; then
            echo -e "${GREEN}✅ stellaris/backend tests PASSED${NC}"
        else
            echo -e "${RED}❌ stellaris/backend tests FAILED${NC}"
            TESTS_FAILED=true
        fi

        cd "$CLAUDE_PROJECT_DIR"
    fi
    echo ""
fi

# =========================================
# Check: stellaris Frontend
# =========================================
if echo "$MODIFIED_FILES" | grep -q "^stellaris/frontend/"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: stellaris/frontend"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "stellaris/frontend" ]; then
        echo -e "${YELLOW}⚠️  stellaris/frontend directory not found${NC}"
    else
        cd stellaris/frontend

        # Run build
        echo "Running: npm run build"
        if npm run build; then
            echo -e "${GREEN}✅ stellaris/frontend build PASSED${NC}"
        else
            echo -e "${RED}❌ stellaris/frontend build FAILED${NC}"
            TESTS_FAILED=true
        fi

        # Run Playwright E2E tests
        echo ""
        echo "Running: npx playwright test"
        if npx playwright test; then
            echo -e "${GREEN}✅ stellaris/frontend E2E tests PASSED${NC}"
        else
            echo -e "${RED}❌ stellaris/frontend E2E tests FAILED${NC}"
            TESTS_FAILED=true
        fi

        cd "$CLAUDE_PROJECT_DIR"
    fi
    echo ""
fi

# =========================================
# Final Verdict
# =========================================
echo "════════════════════════════════════════════════════════"
if [ "$TESTS_FAILED" = true ]; then
    echo -e "${RED}❌ BLOCKING PUSH: Tests must pass before pushing${NC}"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Fix the failing tests and try pushing again."
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ All tests passed - push allowed${NC}"
    echo "════════════════════════════════════════════════════════"
    echo ""
    exit 0
fi
