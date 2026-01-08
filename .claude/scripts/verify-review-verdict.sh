#!/bin/bash
# verify-review-verdict.sh
# Verifies code review produced a clear verdict before completing
# Used by: shadow-code-reviewer Stop hook

set -e

echo "🔍 Verifying code review completion..."

# Check if review output was generated
# The reviewer should have output a structured verdict

# Look for verdict markers in recent output
# This is a reminder to ensure the review was thorough

echo ""
echo "══════════════════════════════════════════════════════════"
echo "📋 REVIEW COMPLETION CHECKLIST"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "Before completing this review, verify you have:"
echo ""
echo "  ✓ Provided a clear verdict: APPROVE | REQUEST_CHANGES | BLOCK"
echo "  ✓ Listed all critical issues (if any)"
echo "  ✓ Listed all important issues (if any)"
echo "  ✓ Provided fix suggestions for each issue"
echo "  ✓ Checked for security vulnerabilities"
echo "  ✓ Verified type annotations are complete"
echo "  ✓ Verified error handling is appropriate"
echo "  ✓ Checked user input flow (settings actually used)"
echo ""
echo "══════════════════════════════════════════════════════════"
echo ""

# This script serves as a reminder; actual enforcement is through protocol
exit 0
