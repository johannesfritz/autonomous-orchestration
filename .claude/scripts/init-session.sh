#!/bin/bash
# Session initialization: establish ground truth before work begins
# Called by SubagentStart hooks for execution agents (P4: Fresh context per session)
#
# Usage: init-session.sh [PLAN_ID]

PLAN_ID="${1:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "=== SESSION INITIALIZATION ==="

# 1. Git status check
echo "--- Git Status ---"
cd "$PROJECT_DIR"
git status --short 2>/dev/null || echo "Not in a git repo"

# 2. Feature list status (if plan specified)
if [ -n "$PLAN_ID" ]; then
    FEATURE_FILE="$PROJECT_DIR/inbox/plans/.feature-lists/${PLAN_ID}-features.json"
    if [ -f "$FEATURE_FILE" ]; then
        echo "--- Feature List: $PLAN_ID ---"
        python3 -c "
import json, sys
with open('$FEATURE_FILE') as f:
    data = json.load(f)
passing = sum(1 for f in data['features'] if f['status'] == 'passing')
total = len(data['features'])
print(f'Progress: {passing}/{total} features passing')
for f in data['features']:
    status = 'PASS' if f['status'] == 'passing' else 'FAIL'
    print(f'  [{status}] {f[\"id\"]}: {f[\"description\"]}')
" 2>/dev/null || echo "Could not parse feature list"
    else
        echo "No feature list found for $PLAN_ID"
    fi
fi

# 3. Check for progress files
if [ -n "$PLAN_ID" ]; then
    PROGRESS_FILE="$PROJECT_DIR/inbox/plans/.progress/${PLAN_ID}-progress.md"
    if [ -f "$PROGRESS_FILE" ]; then
        echo "--- Progress File ---"
        head -20 "$PROGRESS_FILE"
    fi
fi

# 4. Quick test check (if test suite exists)
if [ -f "$PROJECT_DIR/pytest.ini" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    echo "--- Quick Test Check ---"
    cd "$PROJECT_DIR"
    pytest -x --tb=line --no-header -q 2>/dev/null | tail -3 || echo "No tests found or test runner unavailable"
fi

echo "=== INIT COMPLETE ==="
