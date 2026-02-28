# Escalation Protocol (MANDATORY)

**Applies to:** Every agent session. No exceptions.

Agents that are stuck must escalate, not persist. Retrying the same failing approach wastes sessions and produces no output. These are hard constraints.

## When to Escalate

### Repeated Tool Failure

If the same tool call fails **3 times with the same or substantially similar error** → STOP. Do not retry with minor variations. Document the blocker in the state file (or process log) with:
- The exact tool call and parameters
- The exact error message
- What you already tried

### No Measurable Progress

If a step has been IN PROGRESS for the entire session with **no measurable output produced** → mark it BLOCKED in the state file. Document:
- What was attempted
- Why it produced nothing
- At least one alternative approach for the next session

### Missing CEO Decision

If progress requires a CEO decision that has not been made → surface the question in the state file's Outstanding Decisions section. NEVER guess what the CEO would decide. NEVER proceed on assumptions about strategic choices, budget, scope, or partner selection.

### Circular Work

If you discover you are re-doing work a previous session already completed (check the session log) → STOP. Read the state file again. Something was missed.

## How to Escalate

Every escalation must include:
1. **What was tried** — specific actions, not summaries
2. **Why it failed** — exact errors or logical dead-ends
3. **What alternatives exist** — at least one concrete next approach

NEVER escalate with just "it doesn't work." That is not an escalation; it is a complaint.

## Scope

This protocol does NOT mean "give up after 3 tries on everything." Routine iteration (refining a draft, adjusting parameters, fixing linting errors) is normal work. Escalation applies when the **same fundamental blocker** prevents any forward progress — a broken MCP connection, a missing API key, an ambiguous requirement that only the CEO can resolve.
