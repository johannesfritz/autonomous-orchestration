Override the priority of a development plan.

Usage: /prioritize <plan-id> <priority>
Example: /prioritize PLAN-2025-003 critical

Valid priorities: critical, high, medium, low

This command allows the user to manually override the auto-prioritization logic.
The Portfolio Manager will:
1. Update the plan's priority
2. Record this as a user override (for learning)
3. Re-analyze the execution sequence
4. Auto-execute the new sequence if plans become ready

Use the Task tool with subagent_type='portfolio-manager' and prompt='User is overriding priority for {plan_id} to {priority}. Record this decision, re-analyze the portfolio, and update execution sequence. Auto-execute any newly ready plans.'
