#!/bin/bash
# Detect if staged changes include documentation files

# Check staged files
if git diff --cached --name-only | grep -qE '(CLAUDE\.md|\.claude/rules/.*\.md|\.claude/protocols/.*\.md|inbox/plans/completed/.*\.md)'; then
    echo "DOCS_CHANGED"
    exit 0
fi

exit 1
