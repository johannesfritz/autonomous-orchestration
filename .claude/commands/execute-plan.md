Force-execute a specific development plan, bypassing normal queue logic.

Usage: /execute-plan <plan-id>
Example: /execute-plan PLAN-2025-003

This command:
- Overrides normal prioritization
- Executes the plan immediately (even if lower priority)
- Useful for urgent fixes or user-directed execution

The Portfolio Manager will:
1. Mark the plan as high-priority override
2. Check if it can execute now (no file conflicts with currently executing plans)
3. If conflicts exist, either:
   - Defer conflicting plans (if lower priority)
   - Or ask user to resolve conflict
4. Launch TPM orchestrator for the plan
5. Record this as user override (for learning)

Use the Task tool with subagent_type='portfolio-manager' and prompt='User is force-executing plan {plan_id}. Check for conflicts with currently executing plans, resolve if possible, and launch TPM orchestrator immediately. Record this as user override.'
