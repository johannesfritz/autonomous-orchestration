#!/bin/bash
# Hook: Detect explicit fix requests and suggest queueing via queue-fix skill
#
# This hook detects when a user explicitly requests a fix/bug resolution
# and injects context suggesting the queue-fix skill.
#
# Triggers on explicit fix intent patterns, NOT simple keyword mentions.

# Read the user prompt from stdin (JSON format)
INPUT=$(cat)

# Extract the prompt text
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)

# If jq fails or prompt is empty, exit silently
if [ -z "$PROMPT" ]; then
    exit 0
fi

# Pattern 1: Explicit fix requests
# "fix the bug", "fix this issue", "can you fix", "please fix", "need to fix"
FIX_PATTERN="(fix\s+(the|this|that|a)\s+(bug|issue|error|problem)|can\s+you\s+fix|please\s+fix|need\s+to\s+fix|fix\s+this|fix\s+it)"

# Pattern 2: Bug reports with intent to fix
# "there's a bug in", "found a bug", "this is broken", "not working", "bug in"
BUG_PATTERN="(there('s| is)\s+a\s+bug|found\s+a\s+bug|this\s+is\s+broken|is\s+broken|not\s+working\s+(correctly|properly|as expected)|bug\s+in\s+[a-zA-Z])"

# Pattern 3: Hotfix/debug requests
# "hotfix for", "debug and fix", "quick fix", "urgent fix", "resolve the issue"
HOTFIX_PATTERN="(hotfix\s+(for|needed)|debug\s+and\s+fix|quick\s+fix|urgent\s+fix|resolve\s+(the|this)\s+issue)"

# Check for explicit fix patterns (case insensitive)
if echo "$PROMPT" | grep -qiE "$FIX_PATTERN|$BUG_PATTERN|$HOTFIX_PATTERN"; then
    # Don't trigger if user explicitly wants live execution
    if echo "$PROMPT" | grep -qiE "(execute\s+live|don't\s+queue|do\s+not\s+queue|live\s+execution|here\s+and\s+now|fix\s+it\s+now\s+live)"; then
        exit 0
    fi

    # Inject suggestion to use queue-fix skill
    echo ""
    echo "---"
    echo "**Fix Request Detected**"
    echo ""
    echo "This looks like a fix request. Consider using the **queue-fix** skill to:"
    echo "- Queue this as a hotfix (runs in background)"
    echo "- Free your command line for other tasks"
    echo ""
    echo "The skill will ask whether you want to queue (recommended) or execute live."
    echo "---"
    echo ""
    exit 0
fi

# No fix pattern detected - exit silently
exit 0
