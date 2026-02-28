# State File Protocol (MANDATORY)

**Applies to:** Every multi-step task that spans or may span multiple sessions. No exceptions.

State files are the coordination mechanism between agents. There is no other handoff. A fresh agent in a new session must be able to read the state file and execute the next step without any briefing from the CEO.

## When a State File Is Required

Any task with 3+ steps, any pipeline with sequential stages. If the work might outlive your context window, it needs a state file.

**Convention:** `drafts/[project]-STATE.md` for multi-session work. Each workspace defines domain-specific naming in its CLAUDE.md.

## Session Start Protocol

Before any work on a multi-session project:

1. **Read the state file completely.** Not a skim — read every section.
2. **Read every file in the Critical Files Map** that is relevant to the current step. Do not assume you know what they contain from a previous session.
3. **Verify the Next Agent Instructions match what you are about to do.** If they don't, something changed between sessions. Investigate before proceeding.
4. **If the state file is stale** (last session log entry >48h ago) **or contradicts observable state** (e.g. a file listed as "not yet created" already exists), flag to the CEO before proceeding. Do not silently resolve the discrepancy.

## What the State File Must Contain

1. **Status line** (line 3-4): Current step, what's blocked, what's next. A human scanning the file sees the situation in 5 seconds.
2. **Steps table**: Every step with status (DONE / IN PROGRESS / BLOCKED / PENDING), date, and notes. The notes must say what was produced, not just "done."
3. **Outstanding decisions**: Unresolved questions that block progress. Mark resolved ones with strikethrough when the CEO decides.
4. **Known data issues**: Anything a future agent would waste time rediscovering.
5. **Next Agent Instructions**: Explicit, executable instructions for the next session. Tool names, file paths, field mappings, parameter values. A cold-start agent follows these like a recipe.
6. **Critical files map**: Every file the next agent needs, with its purpose. No tribal knowledge.
7. **Session log**: One row per session. What happened, what was produced, what changed.

## When to Update

Update the state file **immediately** after each of these events. Do not batch updates.

- A step changes status (PENDING → IN PROGRESS, IN PROGRESS → DONE, etc.)
- The CEO makes a decision that resolves an outstanding question
- A blocker is discovered
- New files are created that a future agent will need
- The session is ending (update Next Agent Instructions for the successor)

## Verification Before Completion

NEVER mark a step DONE without verifying its outputs. Premature victory declaration is the most common agent failure mode.

Before changing any step from IN PROGRESS to DONE:

1. **Outputs exist.** Every file, record, or artifact the step was supposed to produce actually exists at the expected path.
2. **Outputs are non-empty and well-formed.** A 0-byte file or a CSV with only headers is not "done."
3. **Spot-check content.** For data-dependent steps, verify at least 3 items against their source (e.g. 3 of 70 emails for correct salutation, language, GTA finding link). For file-producing steps, confirm row/item count matches expectations.
4. **Step purpose is satisfied.** Re-read the step's description in the state file. Does the output actually accomplish what the step says? Not "close enough" — actually?

If any check fails: keep the step at IN PROGRESS, note what failed in the steps table, and fix it. Do not mark DONE and create a follow-up step to "clean up."

## The Cold-Start Test

Before ending any session, re-read your own state file and ask: **could a different agent, with zero context about this conversation, execute the next step by reading only this file and the files it references?** If the answer is no, the state file is incomplete. Fix it before stopping.

## Anti-Patterns

- **Tribal knowledge**: "We decided to use Brazil as the hook" without saying where that decision is recorded or what the GTA intervention ID is.
- **Stale next-agent instructions**: Instructions that reference a step already completed. Always update these to point to the actual next step.
- **Missing tool names**: Saying "use the Gmail tool" instead of the exact MCP tool name. The next agent needs exact names.
- **Dangling file references**: Mentioning a file that doesn't exist or was renamed.
- **Aspirational instructions instead of constraints**: "Try to verify data before sending" instead of "NEVER send with unverified data. This is a blocking error." Constraints are followed; aspirations are forgotten. Write state file specs and next-agent instructions as constraints with failure actions, not as suggestions.
