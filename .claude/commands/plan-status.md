Show detailed status for a specific development plan.

Usage: /plan-status <plan-id>
Example: /plan-status PLAN-2025-001

Display:
- Plan metadata (title, priority, dependencies, branch)
- Current status and progress
- Workstream completion status
- Quality gate results (tests, review, security)
- Timeline (started, ETA, completed)
- Blockers or issues (if any)

If the plan is currently executing, show live progress from the TPM orchestrator.

Use the Task tool with subagent_type='portfolio-manager' and prompt='Show detailed status for plan {plan_id} including workstream progress, quality gates, and any blockers.'
