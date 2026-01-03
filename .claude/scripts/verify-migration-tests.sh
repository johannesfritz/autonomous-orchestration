#!/bin/bash
# =============================================================================
# verify-migration-tests.sh
# Purpose: Verify that migration files have corresponding tests
# Trigger: PreToolUse hook on git commit when migrations are staged
# Exit: 0 = OK (no migrations or tests found), 1 = BLOCKED (migrations without tests)
# =============================================================================

set -e

# Check for staged migration files
STAGED_MIGRATIONS=$(git diff --cached --name-only 2>/dev/null | grep -E 'migrations/|alembic/' || true)

if [ -z "$STAGED_MIGRATIONS" ]; then
    # No migrations staged - OK
    exit 0
fi

echo "📊 Migration files detected:"
echo "$STAGED_MIGRATIONS" | sed 's/^/   /'
echo ""

# Check if test_migrations.py is also being modified
HAS_MIGRATION_TESTS=$(git diff --cached --name-only 2>/dev/null | grep -E 'test_migrations\.py|test_.*migration.*\.py' || true)

if [ -z "$HAS_MIGRATION_TESTS" ]; then
    echo "❌ BLOCKING: Migration files staged but no migration tests modified"
    echo ""
    echo "Schema migrations require corresponding tests. Please:"
    echo "  1. Add tests to tests/test_migrations.py (or similar)"
    echo "  2. Verify migration applies cleanly"
    echo "  3. Verify migration rollback works"
    echo "  4. Test NULL handling for new columns"
    echo ""
    echo "See: .claude/protocols/schema-migration-checklist.md"
    exit 1
fi

echo "✅ Migration tests found: $HAS_MIGRATION_TESTS"
exit 0
