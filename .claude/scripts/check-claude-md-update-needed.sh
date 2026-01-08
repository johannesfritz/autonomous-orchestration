#!/bin/bash
# check-claude-md-update-needed.sh
# Checks if CLAUDE.md needs to be updated based on recent changes
# Used by: shadow-code-reviewer Stop hook

set -e

echo "🔍 Checking if CLAUDE.md updates are needed..."

# Get list of changed files (staged or recent commits)
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || git diff HEAD~3 --name-only 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    echo "ℹ️ No recent file changes detected"
    exit 0
fi

NEEDS_UPDATE=false
UPDATE_REASONS=""

# Check for patterns that typically require CLAUDE.md updates

# 1. New API endpoints
if echo "$CHANGED_FILES" | grep -qE "routers/|routes/|api/.*\.py"; then
    if git diff --cached -U0 2>/dev/null | grep -qE "^\+.*@(router|app)\.(get|post|put|delete|patch)"; then
        NEEDS_UPDATE=true
        UPDATE_REASONS="${UPDATE_REASONS}\n  - New API endpoint detected"
    fi
fi

# 2. Database schema changes
if echo "$CHANGED_FILES" | grep -qE "models\.py|schema\.py|migrations/|alembic/"; then
    NEEDS_UPDATE=true
    UPDATE_REASONS="${UPDATE_REASONS}\n  - Database schema changes detected"
fi

# 3. New services or major refactors
if echo "$CHANGED_FILES" | grep -qE "services/.*\.py" | head -1; then
    NEW_SERVICES=$(echo "$CHANGED_FILES" | grep -E "services/.*\.py" | xargs -I {} sh -c 'git diff --cached --diff-filter=A -- {} 2>/dev/null | head -1' || echo "")
    if [ -n "$NEW_SERVICES" ]; then
        NEEDS_UPDATE=true
        UPDATE_REASONS="${UPDATE_REASONS}\n  - New service files detected"
    fi
fi

# 4. Environment variable changes
if echo "$CHANGED_FILES" | grep -qE "\.env\.template|\.env\.example|config\.py|settings\.py"; then
    NEEDS_UPDATE=true
    UPDATE_REASONS="${UPDATE_REASONS}\n  - Configuration/environment changes detected"
fi

# 5. New agents or skills
if echo "$CHANGED_FILES" | grep -qE "\.claude/agents/|\.claude/skills/"; then
    NEEDS_UPDATE=true
    UPDATE_REASONS="${UPDATE_REASONS}\n  - New agents or skills detected"
fi

# 6. FRIDAY pipeline changes
if echo "$CHANGED_FILES" | grep -qE "pipeline/|friday/"; then
    NEEDS_UPDATE=true
    UPDATE_REASONS="${UPDATE_REASONS}\n  - Pipeline changes detected"
fi

# Output result
echo ""
if [ "$NEEDS_UPDATE" = true ]; then
    echo "══════════════════════════════════════════════════════════"
    echo "⚠️ CLAUDE.md UPDATE MAY BE NEEDED"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "Changes detected that typically require documentation updates:"
    echo -e "$UPDATE_REASONS"
    echo ""
    echo "Please verify the following CLAUDE.md files are up to date:"
    echo "  - Root CLAUDE.md (cross-project concepts)"
    echo "  - Project-specific CLAUDE.md (API, schema, services)"
    echo ""
    echo "Checklist:"
    echo "  □ New API endpoints documented"
    echo "  □ Database schema changes documented"
    echo "  □ New environment variables documented"
    echo "  □ New patterns or conventions documented"
    echo ""
    echo "══════════════════════════════════════════════════════════"
else
    echo "✅ No obvious CLAUDE.md updates needed"
    echo "   (Implementation-only changes detected)"
fi

exit 0
