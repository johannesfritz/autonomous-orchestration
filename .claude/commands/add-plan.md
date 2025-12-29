Add a new development plan to the portfolio queue and trigger auto-execution.

Usage: /add-plan <plan-file>
Example: /add-plan PLAN-2025-006.md

Expects the plan file to exist in 00 Inbox/ or 00 Inbox/plans/ directory.

## What This Command Does

1. Invoke Portfolio Manager to analyze the new plan
2. Portfolio Manager will:
   - Parse plan metadata (dependencies, files, workstreams)
   - Invoke Risk Manager for risk assessment (MANDATORY)
   - Check for conflicts with existing plans
   - Estimate costs and benefits
   - Add to execution queue
   - Update PORTFOLIO_STATUS.md dashboard
   - **Spawn TPM orchestrator in background** for ready plans (risk < 7, no blockers)
3. Return analysis summary immediately (execution continues in background)

## Background Execution

Ready plans (risk < 7, no blocking dependencies) are auto-executed:
- TPM orchestrator spawns asynchronously on feature branch
- Your command line returns immediately
- Execution continues in parallel within the same session
- Check progress via `/portfolio` or `/plan-status <id>`

**IMPORTANT:** "Background" means async within the current Claude session. If you close the terminal or Claude Code, background agents stop. Keep the session active until plans complete, or use tmux/screen for persistence.

High-risk plans (risk ≥ 7) are queued but NOT auto-executed - they require manual approval first.

## Workflow

```
/add-plan PLAN-2025-006.md    → Analyze, queue, auto-execute in background
/portfolio                     → Check progress anytime
```

Use the Task tool with subagent_type='portfolio-manager' and prompt:

'Add plan {plan_file} to the portfolio.

Steps:
1. Read and parse the plan file
2. Invoke Risk Manager for risk assessment (MANDATORY)
3. Check for conflicts with existing plans
4. Update state file (.state.json) and dashboard (PORTFOLIO_STATUS.md)
5. For READY plans (risk < 7, no blocking dependencies):
   - Spawn TPM orchestrator with run_in_background=true
   - Update plan status to EXECUTING
6. Return analysis summary

IMPORTANT: You MUST spawn TPM orchestrators for ready plans BEFORE returning. Use run_in_background=true so execution continues while the command line returns to the user.'
