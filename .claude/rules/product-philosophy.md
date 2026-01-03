# Product Philosophy

**Purpose:** Non-negotiable principles guiding all feature development. These are product values, not code standards.

---

## Core Principles

### 1. Journey Over Destination

**BLUF:** Learning is a journey with many paths - frame everything as progress, not fixed ability.

**Philosophy:**
- There is no such thing as a setback, only new challenges
- "Many ways to Rome" - different learners take different paths
- Selective mastery is acceptable; not everyone masters everything
- Adapt to different learning speeds - one-size-fits-all contradicts growth mindset

**Implementation:**
- Show progress relative to self, never compared to others
- Use journey metaphors (road to Rome, milestones)
- Respect prior knowledge - meet learners where they are

---

### 2. Input Metrics Over Output Metrics

**BLUF:** Measure what users control (effort), not what they don't (outcomes).

**Philosophy:**
> "You are only in competition with yourself. There is no point in comparing yourself to others because you don't have any control over their performance."

**Preferred metrics (controllable inputs):**
- Streaks (days practiced)
- Volume (words attempted, sessions completed)
- Consistency (practice frequency)
- Time invested

**Avoided metrics (uncontrollable outputs):**
- ❌ Mastery percentages ("85% mastered")
- ❌ Ability scores ("Brain Power")
- ❌ Rankings against others
- ❌ Perfect score celebrations

**Rationale:** "You don't control whether it clicks."

---

### 3. Honest, Constructive Feedback

**BLUF:** Safe to fail, but not pleasant - users should notice mistakes without feeling bad.

**Tone:** Friendly, candid, encouraging. Non-violent communication always.

**Feedback principles:**
- Mistakes are expected - "this is the place to make errors"
- Orient learners about where they are, don't judge
- Minimize symmetric positive/negative feedback
- Stay positive and constructive at all times

**Language patterns:**

| Use ✅ | Avoid ❌ |
|--------|---------|
| "Fast! Probier nochmal." | "Falsch!" / "Wrong!" |
| "Noch nicht - versuch's nochmal" | "Du kannst das nicht" |
| "Jede Übung zählt" | "Du bist schlau/dumm" |
| Effort-focused praise | Ability-focused praise |

**Visual feedback:**
- Colors show accomplishment upward, remain neutral downward
- Don't get "darker" as difficulty increases
- Animations orient (road to Rome), don't judge

---

### 4. Adaptive Difficulty

**BLUF:** The worst outcome is losing the learner.

**Philosophy:**
- Decrease difficulty to prevent frustration - acceptable
- Learning should feel hard sometimes - that's educational rigor
- Keep portions manageable (this supplements other schoolwork)
- Exception: gaming the system is not acceptable - must be genuine learning

**Balance:** Hard enough to learn, not so hard they quit.

---

### 5. Independence With Support

**BLUF:** Students learn independently; parents have access but aren't required.

**Implementation:**
- No mandatory parental involvement
- Parent-facing features (progress reports, settings) available but optional
- All data visible to both child and parent
- Supplements school, doesn't replace it

---

### 6. Bauhaus Aesthetics

**BLUF:** Design for beauty in a modernist sense.

**Philosophy:** Inspired by Le Corbusier, Toyo Ito - form follows function, clear visual identity.

**Application:**
- Clean, functional interfaces
- Clear visual hierarchy
- Consistent aesthetic across all projects
- Beauty through simplicity, not decoration

---

## Anti-Patterns

### Forbidden Patterns

| Pattern | Why Forbidden |
|---------|---------------|
| Percentage-based ability scores | Output metric, implies ceiling |
| "Brain Power" or similar | Frames ability as fixed capacity |
| Comparison to other users | Only compete with yourself |
| "Unable by nature" language | Static thinking |
| Symmetric harsh feedback | Don't punish difficulty |
| Mandatory parental involvement | Independence is key |
| Celebrating intelligence | Celebrate effort instead |

### Examples

**❌ Violation:**
```
Brain Power: 85%
MEGA GEHIRN!
```

**✅ Correct:**
```
47 Wörter diese Woche geübt
5 Tage am Stück - weiter so!
```

---

## Stellaris-Specific Guidance

### Target Users
- Age: 11-17 years (current: 11-12)
- Context: Latin vocabulary, supplements school
- Future: Multi-player capability

### Educational Rigor
- Difficulty should increase and feel hard
- Cognitive load can be significant but manageable
- This is learning, not a game

### Content Boundaries
- Age-appropriate (11-12 year olds)
- Subject-appropriate (Rome, Latin)
- No specific topics forbidden within these bounds

---

## Privacy

### Data Collection
- Learning progress data: ✅
- Error patterns: ✅ (helps understand struggles)
- Timing for learning insights: ✅
- Time-of-day usage patterns: ❌

### Data Access
- All collected data visible to users (child and parent)
- Export and deletion available via settings
- Future consideration: user-key encryption for production scale

---

## Exception Process

**Authority:** Johannes Fritz only

**Requirements:**
1. Documented justification in development plan
2. Internal documentation of exception
3. Approval before shipping

**Resolution for conflicts:** Case-by-case. When philosophy conflicts with user requests, find alternative ways to address the underlying need within philosophy bounds.

---

## Integration

This document is:
- Imported into `CLAUDE.md` via `@.claude/rules/product-philosophy.md`
- Injected into agents via SubagentStart hooks
- Indexed in Qdrant as atomic principles via `.claude/scripts/index-philosophy.py`
- Auto-indexed during `/sync-docs` (included in DocumentationParser.DOCUMENTATION_FILES)
- Searchable via `/search-docs` with semantic queries
