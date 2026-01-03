#!/bin/bash
# =============================================================================
# detect-architectural-decision.sh
# Purpose: Detect changes that may warrant an Architecture Decision Record (ADR)
# Trigger: PostToolUse hook on git add
# Exit: Always 0 (informational, not blocking)
# =============================================================================

# Check for staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED" ]; then
    exit 0
fi

ADR_SUGGESTED=false

# Check for new dependencies
if echo "$STAGED" | grep -qE 'requirements\.txt|package\.json|pyproject\.toml|Cargo\.toml'; then
    NEW_DEPS=$(git diff --cached -- '*requirements.txt' '*package.json' '*pyproject.toml' 2>/dev/null | grep '^+' | grep -v '^+++' | grep -v '^+#' || true)
    if [ -n "$NEW_DEPS" ]; then
        echo ""
        echo "================================================================"
        echo "  NEW DEPENDENCIES DETECTED - Consider creating an ADR"
        echo "================================================================"
        echo ""
        echo "Dependencies added:"
        echo "$NEW_DEPS" | sed 's/^+/   /'
        echo ""
        echo "If this introduces a new technology or pattern, run:"
        echo "   /adr 'Add [dependency] for [purpose]'"
        echo ""
        ADR_SUGGESTED=true
    fi
fi

# Check for new service/API/integration files
if echo "$STAGED" | grep -qE 'services/.*\.py$|integrations/.*\.py$|api/.*router.*\.py$'; then
    NEW_SERVICES=$(echo "$STAGED" | grep -E 'services/.*\.py$|integrations/.*\.py$|api/.*router.*\.py$' || true)
    if [ -n "$NEW_SERVICES" ]; then
        echo ""
        echo "================================================================"
        echo "  NEW SERVICE/API FILES - Consider architectural implications"
        echo "================================================================"
        echo ""
        echo "Files added:"
        echo "$NEW_SERVICES" | sed 's/^/   /'
        echo ""
        echo "If this represents an architectural decision, run:"
        echo "   /adr 'Add [service/API] for [purpose]'"
        echo ""
        ADR_SUGGESTED=true
    fi
fi

# Check for changes to auth/security files
if echo "$STAGED" | grep -qiE 'auth|login|session|permission|oauth|jwt|security'; then
    AUTH_FILES=$(echo "$STAGED" | grep -iE 'auth|login|session|permission|oauth|jwt|security' || true)
    if [ -n "$AUTH_FILES" ]; then
        echo ""
        echo "================================================================"
        echo "  SECURITY-SENSITIVE FILES MODIFIED"
        echo "================================================================"
        echo ""
        echo "Files modified:"
        echo "$AUTH_FILES" | sed 's/^/   /'
        echo ""
        echo "Security changes often warrant an ADR. Consider:"
        echo "   /adr 'Update authentication approach for [reason]'"
        echo ""
        ADR_SUGGESTED=true
    fi
fi

# Check for database schema changes (reminder to create ADR if significant)
if echo "$STAGED" | grep -qE 'models\.py$|schema\.py$|migrations/'; then
    SCHEMA_FILES=$(echo "$STAGED" | grep -E 'models\.py$|schema\.py$|migrations/' || true)
    if [ -n "$SCHEMA_FILES" ]; then
        echo ""
        echo "================================================================"
        echo "  DATABASE SCHEMA CHANGES - Review architectural impact"
        echo "================================================================"
        echo ""
        echo "Files modified:"
        echo "$SCHEMA_FILES" | sed 's/^/   /'
        echo ""
        echo "Major schema changes may warrant an ADR. Consider if this:"
        echo "   - Introduces a new data model"
        echo "   - Changes relationships between entities"
        echo "   - Affects data migration strategy"
        echo ""
        ADR_SUGGESTED=true
    fi
fi

# Summary
if [ "$ADR_SUGGESTED" = true ]; then
    echo ""
    echo "Tip: View existing ADRs with: ls docs/adr/"
    echo "Create new ADR with: /adr '[title]'"
    echo ""
fi

# Always exit 0 - this is informational only
exit 0
