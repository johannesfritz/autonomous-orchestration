# Agentic Project Execution — Session Lifecycle & Architecture

**Context:** Configuration architecture for AI agents executing multi-session tasks without a persistent orchestrator. Informed by the January–February 2026 long-running autonomous coding research (Cursor FastRender, Anthropic C compiler, Manus agent architecture).

**Scope:** This document explains *how* and *why* the configuration in this template works — the session lifecycle, the coordination model, the research findings that shaped it. For *what's included*, see [CLAUDE.md](../CLAUDE.md). For the system architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Architecture at a Glance

```
project/
├── CLAUDE.md                          ← Navigation hub (50-80 lines)
├── .claude/
│   ├── settings.json                  ← Hook configuration
│   ├── settings.local.json            ← Permissions (git-ignored)
│   ├── rules/                         ← Auto-loaded constraints
│   │   ├── [universal rules]          ← Load every session (4 rules)
│   │   └── [domain rules]            ← Load only when touching matching paths (10 rules)
│   ├── protocols/                     ← Hook-injected standards
│   ├── agents/                        ← Specialist sub-agents
│   ├── commands/                      ← Slash commands (user entry points)
│   └── skills/                        ← Model-invoked procedural knowledge
├── inbox/plans/                       ← Plan queue + state files
└── [your project code]
```

### Loading Hierarchy

| Layer | Mechanism | When | Token Cost |
|---|---|---|---|
| **CLAUDE.md** | Auto-loaded | Every session | ~400-700 |
| **Universal rules** | Auto-loaded (no `paths:` frontmatter) | Every session | ~250/KB |
| **Domain rules** | Auto-loaded with `paths:` frontmatter | Only when matching files in scope | 0 when irrelevant |
| **Protocols** | Hook-injected via `settings.json` | When specific tools execute or agents spawn | 0 until triggered |
| **Skills** | Model-invoked | When task matches description | ~100 (description only) until invoked |

**Key optimisation:** Domain-specific rules use `paths:` frontmatter so they only load when working on that domain. A testing rule doesn't consume tokens during a non-testing session.

```markdown
# Example: paths frontmatter on a domain rule
---
paths:
  - "**/*test*"
  - "**/tests/**"
---
# Testing Strategy
...
```

---

## The Session Lifecycle

This is the core of the system. Every session — whether a human typing interactively or an autonomous agent working through a plan — follows the same lifecycle. The 4 universal rules enforce it.

### 1. Session Start — State File Read

**Rule:** `state-file-protocol.md`, Section: Session Start Protocol

For any multi-session task, before doing anything:

1. **Read the state file completely.** Not a skim — every section.
2. **Read every file in the Critical Files Map** relevant to the current step.
3. **Verify Next Agent Instructions match what you're about to do.** If they don't, investigate.
4. **Flag stale state files** (>48h since last session log entry) or contradictions to the human before proceeding.

**Why:** Research finding (Anthropic C compiler, Cursor FastRender) — agents that start from fresh context plus environmental memory outperform agents that inherit stale assumptions. The state file IS the environmental memory.

### 2. Mid-Session — Work Execution

Commands invoke specialist agents. Agents receive domain context via hooks:

```json
// settings.json — hook injection example
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "code-reviewer",
        "hooks": [{
          "type": "command",
          "command": "cat $CLAUDE_PROJECT_DIR/.claude/protocols/code-standards.md",
          "once": true
        }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "cat $CLAUDE_PROJECT_DIR/.claude/protocols/quality-check.md",
          "once": true
        }]
      }
    ]
  }
}
```

**`once: true`** prevents duplicate loading within a session. Without it, every Edit/Write call re-loads the same protocol.

**Echo vs. cat:** Use `echo` summaries for discovery/routing agents (cheap, sufficient). Use `cat` full files for quality-critical agents (reviewers, security audit).

### 3. Mid-Session — Verification Before Marking DONE

**Rule:** `state-file-protocol.md`, Section: Verification Before Completion

NEVER mark a step DONE without verifying outputs. Premature victory declaration was the #1 failure mode across both research experiments.

Before changing any step from IN PROGRESS to DONE:

1. **Outputs exist** at expected paths.
2. **Outputs are non-empty and well-formed.** A 0-byte file or CSV with only headers is not "done."
3. **Spot-check content.** For data-dependent steps, verify at least 3 items against their source.
4. **Step purpose is satisfied.** Re-read the step's description. Does the output actually accomplish it?

If any check fails: keep step at IN PROGRESS, note what failed, fix it.

### 4. Mid-Session — Escalation When Stuck

**Rule:** `escalation-protocol.md`

Hard stops for stuck agents:

| Trigger | Action |
|---|---|
| Same tool fails 3 times with same error | STOP. Document the blocker. Do not retry with minor variations. |
| Entire session with no measurable output | Mark step BLOCKED. Document what was tried + at least one alternative. |
| Human decision needed | Surface in Outstanding Decisions. NEVER guess. |
| Re-doing work a previous session completed | STOP. Re-read the state file. Something was missed. |

Every escalation must include: what was tried, why it failed, what alternatives exist. "It doesn't work" is not an escalation.

**Scope:** This does NOT mean "give up after 3 tries on everything." Routine iteration (refining drafts, adjusting parameters) is normal work. Escalation applies when the same fundamental blocker prevents forward progress.

### 5. Session End — Cold-Start Test

**Rule:** `state-file-protocol.md`, Section: The Cold-Start Test

Before stopping, re-read your own state file: **could a different agent, with zero context about this conversation, execute the next step by reading only this file and the files it references?**

If no — the state file is incomplete. Fix it before stopping.

### 6. Session End — Workspace Hygiene

**Rule:** `workspace-hygiene.md`

Delete failed-run artifacts, temp files, empty directories. Report what was cleaned. The human should never have to manually clean up after an agent session.

---

## State Files

State files are the coordination mechanism between agents across sessions. There is no other handoff.

### Required Contents

1. **Status line** (lines 3-4): Current step, what's blocked, what's next. Readable in 5 seconds.
2. **Steps table**: Every step with status (DONE / IN PROGRESS / BLOCKED / PENDING), date, and notes saying what was produced.
3. **Outstanding decisions**: Unresolved questions blocking progress.
4. **Known data issues**: Anything a future agent would waste time rediscovering.
5. **Next Agent Instructions**: Explicit, executable — tool names, file paths, parameter values. A cold-start agent follows these like a recipe.
6. **Critical files map**: Every file the next agent needs, with its purpose.
7. **Session log**: One row per session — what happened, what was produced.

### When to Update

Immediately after:
- A step changes status
- The human makes a decision
- A blocker is discovered
- New files are created
- The session is ending

### Anti-Patterns

- **Tribal knowledge**: References to decisions without saying where they're recorded or what the data source is.
- **Stale next-agent instructions**: Pointing to a step already completed.
- **Missing tool names**: "Use the Gmail tool" instead of the exact MCP tool name. The next agent needs exact names.
- **Dangling file references**: Mentioning files that don't exist or were renamed.
- **Aspirational instructions instead of constraints**: "Try to verify data before sending" instead of "NEVER send with unverified data. This is a blocking error." Constraints are followed; aspirations are forgotten.

---

## Project Folder Structure

**Rule:** `project-folder-structure.md`

For any task producing 3+ files:

```
YYMMDD-descriptive-name/
├── code/           ← Scripts, notebooks (if code exists)
├── data/           ← Raw + processed inputs (if data exists)
├── results/        ← All outputs, deliverables
├── lit/            ← References (only when relevant)
└── docs/
    └── process-log.md  ← Sequential record + cold-start handoff
```

**Process log** (`docs/process-log.md`):

```markdown
# [Project Title]
**Started:** YYYY-MM-DD
**Purpose:** [One sentence — what are we trying to find out / produce?]

## Status
[Current state. What's done, what's next.]

## Log

### YYYY-MM-DD — [Session summary]
- **Attempted:** [What was tried]
- **Produced:** [File paths of outputs]
- **Learned:** [Key findings or dead ends]
- **Next:** [What the next session should do]
```

Same cold-start requirement: a fresh agent reads only this file and picks up where the last session left off.

---

## Constraint Enforcement

The research finding: **constraints beat instructions.** Hard enforcement (hooks, blocking checklists, failure actions) is more reliable than soft instructions ("always remember to...").

### Enforcement Mechanisms

| Mechanism | How It Works | Example |
|---|---|---|
| **PreToolUse hook** | Blocks or injects context before a tool executes | Inject quality protocol before Edit/Write |
| **SubagentStart hook** | Injects context when a specialist agent spawns | Load code standards for code reviewer |
| **Blocking checklist** | Table with numbered checks, each with a BLOCK/HOLD failure action | Quality gate: 10 checks, any failure blocks the merge |
| **Procedural gate** | Rule that mandates a verification step before proceeding | Spot-check 3 items before marking DONE |

### Audit Rule

For every "MUST" or "NEVER" in a rule or protocol: verify there is a corresponding enforcement mechanism (hook, checklist, or gate). If not, either add enforcement or downgrade the statement to a recommendation. Unenforceable MUSTs erode trust in the system.

---

## CLAUDE.md — The Navigation Hub

The workspace CLAUDE.md is the operating system, not documentation. It defines how the agent operates. Keep it to 50-80 lines.

### What It Should Contain

| Content | Purpose |
|---|---|
| **Domain routing table** | Which directory and commands handle which domain |
| **Execution model** | How coordination works (state files, feature lists) |
| **Agent architecture** | Pipeline stages (who invokes whom) |
| **Rules summary** | Which rules are universal vs. domain-scoped |
| **Key constraints** | The 4-5 hardest constraints, as one-liners |

### What Does NOT Belong

| Content | Where It Belongs |
|---|---|
| Full protocol text | Rules or protocols (auto-loaded or hook-injected) |
| Detailed procedures | Commands (loaded on invocation) |
| Domain knowledge | Skills (loaded on demand) |
| Agent instructions | Agent definition files |

---

## Token Budget

| Session Type | Expected Tokens | What Loads |
|---|---|---|
| Quick task (no domain match) | ~2,850 | CLAUDE.md + universal rules |
| Single domain (e.g. testing) | ~4,500 | + matching domain rules |
| Cross-domain | ~6,350 | + multiple domain rules |
| Full pipeline (plan execution) | ~8,000 | + hook-injected protocols + agent context |

### Optimisation Techniques

| Technique | How |
|---|---|
| **`paths:` frontmatter** | Domain rules only load when matching files in scope |
| **`once: true` on hooks** | Prevents duplicate protocol loading within session |
| **Echo vs. cat** | Summary for discovery agents, full file for quality-critical |
| **CLAUDE.md as hub** | Summaries with references, not full imports |

---

## Research Foundations

This setup implements findings from three research sources:

| Source | Key Lesson | Implementation |
|---|---|---|
| **Cursor FastRender** (Jan 2026) | Constraints beat instructions | Blocking checklists with failure actions |
| **Anthropic C Compiler** (Feb 2026) | Fresh context + environmental memory | Session Start Protocol + state files |
| **Anthropic C Compiler** | Premature victory = #1 failure mode | Verification Before Completion gate |
| **Both experiments** | Drift without escalation wastes sessions | Escalation Protocol (3-strike, no-progress) |
| **Manus agent architecture** | Filesystem as coordination channel | State files, process logs, workstream files on disk |
| **Cursor FastRender** | Specs before scale execution | Feature lists + plan templates before execution |

### Key Takeaways

1. **Agents forget.** Context windows are finite. State files, process logs, and progress file rewrites (P6) exist because agents will lose track of objectives mid-session.

2. **Agents declare victory prematurely.** The Verification Before Completion gate exists because both Cursor and Anthropic found this was their #1 autonomous failure mode. The spot-check requirement (verify 3 items against source) catches the most common false positives.

3. **Agents retry forever.** Without an explicit escalation protocol, a stuck agent will burn an entire session retrying the same failing approach with minor variations. The 3-strike rule with mandatory documentation forces it to stop and leave useful information for the next session.

4. **"MUST" without enforcement is a suggestion.** Constraints written in CLAUDE.md or rules are only as reliable as their enforcement mechanism. If there's no hook, gate, or checklist backing a "MUST" statement, it will eventually be violated. This is why the system uses 47 hooks in `settings.json`.

5. **Filesystem beats prompts for coordination.** Embedding state in prompt chains creates fragile, opaque coordination. Writing state to disk (`.state.json`, workstream files, progress files) means: state survives session crashes, state is inspectable by humans, and multiple agents can read the same source of truth.

---

## Multi-Workspace Configuration

When a single repository contains multiple workspaces with independent `.claude/` configs, shared configuration avoids duplication and drift.

### The Shared-Rules Pattern

Universal rules that apply to every workspace live in a canonical location and are symlinked into each workspace's `.claude/rules/`:

```
project-root/
├── .claude/
│   ├── shared-rules/                    ← Canonical source (edit here)
│   │   ├── state-file-protocol.md
│   │   ├── escalation-protocol.md
│   │   ├── project-folder-structure.md
│   │   └── workspace-hygiene.md
│   ├── shared-commands/                 ← Canonical shared commands
│   └── shared-scripts/                  ← Canonical shared scripts
│
├── workspace-a/.claude/
│   ├── rules/
│   │   ├── state-file-protocol.md       → ../../.claude/shared-rules/state-file-protocol.md
│   │   ├── escalation-protocol.md       → (symlink)
│   │   ├── domain-specific-rule.md      ← Workspace-only rule
│   │   └── ...
│   └── commands/
│       ├── shared-cmd.md               → ../../.claude/shared-commands/shared-cmd.md
│       └── workspace-specific-cmd.md    ← Workspace-only command
│
└── workspace-b/.claude/
    ├── rules/
    │   ├── state-file-protocol.md       → (symlink)
    │   └── ...
    └── ...
```

### Principle: Edit Once, Propagate Everywhere

- **Canonical sources** live in `project-root/.claude/shared-*/` directories
- **Symlinks** in each workspace's `.claude/` point to the canonical source
- Edit the canonical file — changes propagate to all workspaces automatically
- Each workspace can also have its own non-symlinked files for domain-specific config

For standalone projects or templates distributed to others (like this template), copy the files directly instead of symlinking — users won't have the canonical source directory.

---

*Last updated: 2026-02-28*
