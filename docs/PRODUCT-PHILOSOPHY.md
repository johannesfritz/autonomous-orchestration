# Product Philosophy Alignment

**Purpose:** Ensure AI agents align with product values through automated protocol injection.

---

## Overview

Product philosophy alignment ensures that autonomous AI agents operate according to established product values, not just technical requirements. This is critical when agents make decisions about user-facing features, feedback language, metrics display, and accessibility.

**Note:** The philosophy itself is defined in `.claude/rules/product-philosophy.md`. This document describes the **enforcement mechanisms** that ensure agents follow it.

---

## Core Principles (Summary)

The full philosophy is documented in `.claude/rules/product-philosophy.md`. Key principles:

| Principle | Summary | Impact on Agents |
|-----------|---------|------------------|
| **Journey Over Destination** | Learning is a journey, not fixed ability | Agents use progress metaphors, not ability scores |
| **Input Metrics Over Output Metrics** | Measure effort (controllable), not outcomes | Agents recommend streaks/volume, not mastery percentages |
| **Honest, Constructive Feedback** | Safe to fail, but not pleasant | Agents use encouraging language, avoid harsh feedback |
| **Adaptive Difficulty** | Prevent losing the learner | Agents can decrease difficulty to prevent frustration |
| **Independence With Support** | Students learn independently | No mandatory parental features |
| **Bauhaus Aesthetics** | Design for beauty (modernist) | Clean, functional interfaces |

---

## Agent Injection Mapping

Philosophy is injected into agents via `SubagentStart` hooks in `.claude/settings.json`. When an agent starts, relevant protocols are automatically prepended to its context.

### Agents Receiving Philosophy

| Agent | Protocol Injected | Why |
|-------|-------------------|-----|
| `product-manager` | `product-philosophy.md` | Makes prioritization decisions affecting users |
| `technical-pm` | `product-philosophy.md` | Translates requirements that affect UX |
| `solutions-architect` | `product-philosophy.md` | Architectural decisions affect user experience |
| `ux-researcher` | `product-philosophy.md` | Directly designs user interactions |
| `artificial-shadow-dev` | `product-philosophy.md` | Implements UI/UX features |
| `qa-engineer` | `product-philosophy.md` | Tests user-facing functionality |
| `database-engineer` | `product-philosophy.md` | Data models affect metrics display |

### Hook Configuration Example

From `.claude/settings.json`:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "product-manager",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'PROTOCOL: @.claude/rules/product-philosophy.md'"
          }
        ]
      },
      {
        "matcher": "artificial-shadow-dev",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'PROTOCOL: @.claude/rules/product-philosophy.md'"
          }
        ]
      }
    ]
  }
}
```

### Protocol Injection Behavior

When a matching agent starts:
1. Hook fires before agent receives task
2. Protocol file content is prepended to agent context
3. Agent now has philosophy as part of its instructions
4. All decisions are informed by philosophy principles

---

## Enforcement Mechanisms

### Layer 1: SubagentStart Hooks (Automatic)

**Mechanism:** Protocols injected when agents start
**Coverage:** All Product Management and development agents
**Enforcement:** Automatic, deterministic

### Layer 2: Code Review (shadow-code-reviewer)

**Mechanism:** Reviewer checks code against philosophy anti-patterns
**Example checks:**
- No percentage-based ability scores in UI
- No "Brain Power" or similar fixed-ability language
- No comparison to other users
- Feedback language is encouraging, not harsh

**Enforcement:** Code rejected if violations found

### Layer 3: SubagentStop Verification

**Mechanism:** When agents complete, hooks verify philosophy alignment
**Example:** After `product-manager` completes, verify recommendations don't include forbidden patterns

### Layer 4: Semantic Search (Qdrant)

**Mechanism:** Philosophy principles indexed in Qdrant for retrieval
**Usage:** Agents search for relevant principles when making decisions
**Script:** `.claude/scripts/index-philosophy.py` (called during `/sync-docs`)

---

## Anti-Patterns (Forbidden)

These patterns are explicitly forbidden and should be detected during code review:

### Forbidden UI/UX Patterns

| Pattern | Why Forbidden | Alternative |
|---------|---------------|-------------|
| `Brain Power: 85%` | Output metric, implies fixed ability | `47 words practiced this week` |
| `MEGA GEHIRN!` | Celebrates intelligence, not effort | `5 days in a row - keep going!` |
| Leaderboards | Comparison to others | Progress relative to self |
| `Mastery: 85%` | Output metric, you don't control "clicking" | Volume/streak metrics |
| `Falsch!` / `Wrong!` | Harsh feedback | `Fast! Try again.` |
| `Du kannst das nicht` | Fixed ability language | `Not yet - try again` |
| Mandatory parent login | Contradicts independence | Optional parent features |

### Forbidden Code Patterns

```typescript
// ❌ FORBIDDEN: Output metric
<ProgressBar label="Mastery" value={user.masteryPercentage} />

// ✅ CORRECT: Input metric
<ProgressBar label="Words Practiced" value={user.wordsPracticed} />
```

```typescript
// ❌ FORBIDDEN: Ability-focused praise
<Toast>You're so smart! 🧠</Toast>

// ✅ CORRECT: Effort-focused praise
<Toast>Great practice session!</Toast>
```

```typescript
// ❌ FORBIDDEN: Comparison to others
<Leaderboard users={allUsers} currentUser={user} />

// ✅ CORRECT: Progress relative to self
<ProgressChart userHistory={user.weeklyProgress} />
```

---

## Integration with Development Workflow

### During Planning

1. **Product Manager** searches Qdrant for relevant philosophy principles
2. Feature requirements include philosophy alignment notes
3. Anti-patterns documented in development plan

### During Development

1. **artificial-shadow-dev** has philosophy injected via hook
2. Agent implements UI/UX following principles
3. No forbidden patterns used

### During Review

1. **shadow-code-reviewer** checks for anti-patterns
2. UI text reviewed for language compliance
3. Metrics checked for input vs. output alignment

### During Testing

1. **qa-engineer** verifies philosophy compliance
2. UAT includes checking feedback language
3. Accessibility verified (WCAG 2.1 AA)

---

## Exception Process

Philosophy exceptions require explicit approval:

**Authority:** Johannes Fritz only

**Requirements:**
1. Documented justification in development plan
2. Exception documented internally
3. Approval before shipping

**Process:**
1. Agent identifies potential philosophy conflict
2. Escalates to user with reasoning
3. User approves exception or suggests alternative
4. Exception documented in plan

---

## Searchable Philosophy (Qdrant Integration)

Philosophy principles are indexed in Qdrant for semantic search:

**Collection:** `documentation`

**Indexed content:**
- Each principle as separate atomic note
- Anti-patterns with examples
- Language patterns (use/avoid)

**Search examples:**
```bash
# Search for metrics guidance
/search-docs "what metrics should we show users"

# Search for feedback language
/search-docs "error message language patterns"

# Search for accessibility
/search-docs "WCAG compliance requirements"
```

**Indexing:**
- Runs during `/sync-docs`
- Included in CI/CD sync workflow
- Auto-indexed via git commit hooks

---

## Verification Checklist

For any user-facing feature, verify:

- [ ] **Metrics:** Input metrics only (streaks, volume, time invested)
- [ ] **Language:** Effort-focused, not ability-focused
- [ ] **Feedback:** Encouraging, not harsh
- [ ] **Progress:** Relative to self, not others
- [ ] **Difficulty:** Adaptive to prevent losing learner
- [ ] **Independence:** No mandatory parental involvement
- [ ] **Accessibility:** WCAG 2.1 AA compliant
- [ ] **Aesthetics:** Clean, functional (Bauhaus)

---

## Further Reading

- `.claude/rules/product-philosophy.md` - Full philosophy document
- `.claude/protocols/user-centricity.md` - Product Manager protocol
- `.claude/settings.json` - Hook configurations
- `docs/QDRANT-INTEGRATION.md` - Semantic search for principles
