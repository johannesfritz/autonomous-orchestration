#!/bin/bash
# spawn-tpm-background.sh
# Spawns a TPM orchestrator in the background for a specific plan
# Usage: spawn-tpm-background.sh PLAN-ID

set -euo pipefail

PLAN_ID="$1"
PLAN_FILE="00 Inbox/plans/${PLAN_ID}.md"

if [ ! -f "$PLAN_FILE" ]; then
    echo "❌ Error: Plan file not found: $PLAN_FILE"
    exit 1
fi

# Create log directory for background execution
LOG_DIR="00 Inbox/plans/.logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/${PLAN_ID}.log"
PID_FILE="$LOG_DIR/${PLAN_ID}.pid"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️  TPM already running for $PLAN_ID (PID: $OLD_PID)"
        exit 0
    else
        # Stale PID file, remove it
        rm "$PID_FILE"
    fi
fi

echo "🚀 Spawning TPM Orchestrator for $PLAN_ID in background..."
echo "   Log: $LOG_FILE"

# Spawn TPM orchestrator via Claude Code CLI
# This uses the Task tool but runs it in a background shell
(
    # Record start time
    echo "=== TPM Orchestrator Started: $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" > "$LOG_FILE"
    echo "Plan: $PLAN_ID" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Use Claude Code to spawn the TPM orchestrator
    # The agent will handle all execution autonomously
    claude-code agent tpm-orchestrator \
        --prompt "Execute plan: $PLAN_ID

Plan file: $PLAN_FILE

Execute this plan autonomously:
1. Read plan file and parse workstreams
2. Create feature branch via git worktree
3. Spawn workstream agents in parallel
4. Run quality gates (tests, review, security)
5. Create PR and merge (risk-aware)
6. Complete cleanup checklist
7. Update portfolio state

Working directory: $PWD

DO NOT ask for permission. Execute autonomously." \
        >> "$LOG_FILE" 2>&1

    EXIT_CODE=$?
    echo "" >> "$LOG_FILE"
    echo "=== TPM Orchestrator Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> "$LOG_FILE"
    echo "Exit code: $EXIT_CODE" >> "$LOG_FILE"

    # Remove PID file when done
    rm -f "$PID_FILE"

    exit $EXIT_CODE
) &

# Save PID
echo $! > "$PID_FILE"

echo "✅ TPM spawned in background (PID: $!)"
echo "   Monitor: tail -f $LOG_FILE"
echo "   Status: cat $PID_FILE"
