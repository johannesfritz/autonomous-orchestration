#!/bin/bash
# Detect major changes that require enhanced review
# Exit 0 always (informational only), but outputs warnings

set -e

MAJOR_CHANGE=false
REASONS=()

# Get changed files (staged or unstaged)
if git diff --cached --name-only 2>/dev/null | grep -q .; then
    CHANGED_FILES=$(git diff --cached --name-only)
else
    CHANGED_FILES=$(git diff HEAD --name-only 2>/dev/null || echo "")
fi

# If no changes, exit quietly
if [ -z "$CHANGED_FILES" ]; then
    exit 0
fi

# Category 1: Database Changes
for file in $CHANGED_FILES; do
    if echo "$file" | grep -qE "(migrations|alembic|models\.py|schema\.py|\.sql$)"; then
        MAJOR_CHANGE=true
        REASONS+=("DATABASE: $file")
    fi
done

# Category 2: Authentication/Authorization
for file in $CHANGED_FILES; do
    if echo "$file" | grep -qiE "(auth|permission|session|login|oauth)"; then
        MAJOR_CHANGE=true
        REASONS+=("AUTH: $file")
    fi
done

# Category 3: New features (new files in key directories)
NEW_FILES=$(git diff --cached --diff-filter=A --name-only 2>/dev/null || echo "")
for file in $NEW_FILES; do
    if echo "$file" | grep -qE "(pages|views|routes|routers|api)/"; then
        MAJOR_CHANGE=true
        REASONS+=("NEW_FEATURE: $file")
    fi
done

# Category 4: Destructive operations in content
DIFF_CONTENT=$(git diff --cached 2>/dev/null || git diff HEAD 2>/dev/null || echo "")
if echo "$DIFF_CONTENT" | grep -qE "(DELETE FROM|\.delete\(|DROP TABLE|DROP COLUMN)"; then
    MAJOR_CHANGE=true
    REASONS+=("DATA_OPERATION: Detected DELETE/DROP operations")
fi

# Category 5: External service changes
for file in $CHANGED_FILES; do
    if echo "$file" | grep -qE "(services|integrations|clients)/"; then
        if echo "$DIFF_CONTENT" | grep -qE "(stripe|anthropic|openai|httpx|requests\.)"; then
            MAJOR_CHANGE=true
            REASONS+=("EXTERNAL_SERVICE: $file")
        fi
    fi
done

if [ "$MAJOR_CHANGE" = true ]; then
    echo ""
    echo "🚨 MAJOR CHANGE DETECTED"
    echo "========================"
    echo ""
    echo "Reasons:"
    for reason in "${REASONS[@]}"; do
        echo "  • $reason"
    done
    echo ""
    echo "REQUIRED GATES (enforced by TPM/reviewer):"
    echo "  1. ✅ All tests pass (pytest, playwright)"
    echo "  2. ✅ UAT: User journey verified manually"
    echo "  3. ✅ Senior code review (shadow-code-reviewer with strict protocol)"
    echo "  4. ✅ Risk assessment (if overall score ≥7, requires Johannes approval)"
    echo ""
    echo "See: .claude/protocols/major-change-detection.md"
    echo ""
fi

exit 0
