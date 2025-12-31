#!/bin/bash
# Check for component library violations in TSX files
# Warns when custom components are created instead of using shadcn/ui

set -e

FILE="$1"

# Only check .tsx files
if [[ ! "$FILE" =~ \.tsx$ ]]; then
    exit 0
fi

# Skip if file doesn't exist
if [ ! -f "$FILE" ]; then
    exit 0
fi

VIOLATIONS=()

# Check for custom button implementations
if grep -qE "const\s+\w*Button\w*\s*=" "$FILE" 2>/dev/null; then
    if ! grep -q "from.*@/components/ui/button\|from.*components/ui/button" "$FILE" 2>/dev/null; then
        VIOLATIONS+=("Custom Button component - use shadcn/ui Button instead")
    fi
fi

# Check for custom input implementations
if grep -qE "const\s+\w*Input\w*\s*=" "$FILE" 2>/dev/null; then
    if ! grep -q "from.*@/components/ui/input\|from.*components/ui/input" "$FILE" 2>/dev/null; then
        VIOLATIONS+=("Custom Input component - use shadcn/ui Input instead")
    fi
fi

# Check for inline modal patterns
if grep -qE "fixed\s+inset-0|className.*modal.*overlay" "$FILE" 2>/dev/null; then
    if ! grep -q "from.*@/components/ui/dialog\|from.*components/ui/dialog" "$FILE" 2>/dev/null; then
        VIOLATIONS+=("Custom modal implementation - use shadcn/ui Dialog instead")
    fi
fi

# Check for card-like inline styling
if grep -qE 'className="[^"]*border[^"]*rounded[^"]*shadow' "$FILE" 2>/dev/null; then
    if ! grep -q "from.*@/components/ui/card\|from.*components/ui/card" "$FILE" 2>/dev/null; then
        VIOLATIONS+=("Card-like styling detected - consider using shadcn/ui Card")
    fi
fi

# Check for custom select/dropdown
if grep -qE "const\s+\w*Select\w*\s*=|const\s+\w*Dropdown\w*\s*=" "$FILE" 2>/dev/null; then
    if ! grep -q "from.*@/components/ui/select\|from.*components/ui/select" "$FILE" 2>/dev/null; then
        VIOLATIONS+=("Custom Select/Dropdown - use shadcn/ui Select instead")
    fi
fi

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️ COMPONENT LIBRARY VIOLATION"
    echo "=============================="
    echo ""
    echo "File: $FILE"
    echo ""
    echo "Issues:"
    for v in "${VIOLATIONS[@]}"; do
        echo "  • $v"
    done
    echo ""
    echo "Use shadcn/ui components instead of creating custom ones."
    echo "See: .claude/protocols/component-library-restriction.md"
    echo ""
fi

exit 0
