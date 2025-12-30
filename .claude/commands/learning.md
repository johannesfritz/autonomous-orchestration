# Learning Command

View and manage Portfolio Manager's learned patterns.

**Usage:**
- `/learning` - Show all learned patterns and statistics
- `/learning patterns` - Show priority patterns only
- `/learning paths` - Show high scrutiny paths only
- `/learning history` - Show override history
- `/learning adjust <pattern-id> <confidence>` - Manually adjust pattern confidence
- `/learning delete <pattern-id>` - Delete a specific pattern
- `/learning reset` - Reset all learning (requires confirmation)

## Purpose

The Portfolio Manager learns from your behavior to improve future decisions:
- **Priority Patterns:** Keywords that consistently get priority boosts
- **High Scrutiny Paths:** File paths that require extra validation
- **Override History:** Record of all user corrections

## Output Formats

### Summary View (default)

```
Learning Summary
============================================================

📚 Priority Patterns (3 active)

| Pattern | Keywords | Confidence | Applied | Correct |
|---------|----------|------------|---------|---------|
| P-001   | customer, user-facing | 80% | 12 times | 10/12 (83%) |
| P-002   | auth, security | 75% | 8 times | 6/8 (75%) |
| P-003   | hotfix, urgent | 60% | 5 times | 3/5 (60%) |

📁 High Scrutiny Paths (4 paths)

- src/auth/           → Detected 7 times in manual reviews
- src/payments/       → Detected 5 times in manual reviews
- database/migrations/ → Detected 4 times in manual reviews
- src/api/external/   → Detected 3 times in manual reviews

📝 Override History

Total overrides: 23
Last 7 days: 5
Most common: medium → high (12 times)

============================================================
Run '/learning patterns' for detailed pattern info
Run '/learning reset' to clear all learning
```

### Patterns Detail View

```
Priority Patterns (Detailed)
============================================================

Pattern P-001: "customer-facing"
────────────────────────────────
Keywords:       customer, user-facing, client
Boost:          +1 priority level
Confidence:     80%
Created:        2025-01-10
Last applied:   2025-01-15 10:30 UTC

Statistics:
  Applied: 12 times
  Correct: 10 (83%)
  Overridden: 2 (17%)

Recent applications:
  - PLAN-2025-015: customer login flow (correct)
  - PLAN-2025-012: user profile settings (correct)
  - PLAN-2025-008: client dashboard (overridden → user chose lower priority)

────────────────────────────────

Pattern P-002: "security-related"
────────────────────────────────
Keywords:       auth, security, permission
Boost:          +1 priority level
Confidence:     75%
Created:        2025-01-08
Last applied:   2025-01-14 16:20 UTC

Statistics:
  Applied: 8 times
  Correct: 6 (75%)
  Overridden: 2 (25%)

...
```

### Override History View

```
Override History
============================================================

Last 10 Overrides:

1. 2025-01-15 10:30 UTC
   Plan: PLAN-2025-015 "Customer Login Improvements"
   Changed: medium → critical
   Reason: "Customer-facing feature needs to ship"
   Files: src/auth/login.tsx, src/components/LoginForm.tsx

2. 2025-01-14 16:20 UTC
   Plan: PLAN-2025-012 "API Rate Limiting"
   Changed: low → high
   Reason: (none provided)
   Files: src/api/middleware/ratelimit.py

3. 2025-01-14 09:15 UTC
   Plan: PLAN-2025-010 "Database Migration"
   Changed: high → critical
   Reason: "Blocking other work"
   Files: database/migrations/0025_add_indexes.sql

...

Statistics:
  Total overrides: 23
  Priority increases: 18 (78%)
  Priority decreases: 5 (22%)

Most common patterns:
  - "customer" keyword: 7 overrides
  - "auth" files: 5 overrides
  - "database" files: 4 overrides
```

## Managing Patterns

### Adjust Confidence

Manually adjust pattern confidence when you know better:

```
/learning adjust P-001 0.9

Pattern Confidence Updated
============================================================

Pattern: P-001 "customer-facing"
Old confidence: 80%
New confidence: 90%

This pattern will now be applied more assertively.
```

### Delete Pattern

Remove a pattern that's no longer useful:

```
/learning delete P-003

Pattern Deleted
============================================================

Deleted: P-003 "hotfix-related"
Keywords: hotfix, urgent, emergency
Previous confidence: 60%

This pattern will no longer affect prioritization.
```

### Reset All Learning

Clear all learned patterns and start fresh:

```
/learning reset

⚠️ WARNING: This will delete ALL learned patterns

You are about to delete:
- 3 priority patterns
- 4 high scrutiny paths
- 23 override history entries

This action cannot be undone.

Type 'CONFIRM RESET' to proceed:
```

After confirmation:

```
Learning Reset Complete
============================================================

Deleted:
- 3 priority patterns
- 4 high scrutiny paths
- 23 override history entries

The Portfolio Manager will now start learning from scratch.
Your explicit priorities will still be respected.
```

## How Learning Works

### Pattern Creation

Patterns are automatically created when:
1. You override priority 3+ times with similar characteristics
2. The system detects a keyword appearing in multiple overrides
3. File paths consistently require manual attention

### Confidence Levels

| Confidence | Meaning | Behavior |
|------------|---------|----------|
| 90-100% | Very reliable | Applied automatically, shown in summary |
| 60-89% | Moderately reliable | Applied as tiebreaker, logged |
| 30-59% | Uncertain | Applied only with other signals |
| 0-29% | Unreliable | Pattern deleted automatically |

### Confidence Changes

**Increases (+5%):**
- User doesn't override a pattern-based decision
- Plan with pattern-boosted priority succeeds

**Decreases (-15%):**
- User explicitly overrides pattern-based decision
- Plan with pattern-boosted priority fails or is rejected

## Implementation

When `/learning` is invoked:

```bash
1. Read state from 00 Inbox/system_state.json
2. Extract learned_preferences section
3. Format output based on subcommand:
   - (none) → Summary view
   - patterns → Detailed patterns
   - paths → High scrutiny paths
   - history → Override history
4. For mutations (adjust, delete, reset):
   - Validate parameters
   - Update state file (atomic write)
   - Log change to audit trail
```

## State Schema Reference

```json
{
  "learned_preferences": {
    "priority_patterns": [
      {
        "id": "P-001",
        "keywords": ["customer", "user-facing"],
        "boost": 1,
        "confidence": 0.8,
        "examples": 7,
        "correct_predictions": 10,
        "incorrect_predictions": 2,
        "created_at": "2025-01-10T00:00:00Z",
        "last_applied": "2025-01-15T10:30:00Z"
      }
    ],
    "high_scrutiny_paths": [
      {
        "path": "src/auth/",
        "detections": 7,
        "added_at": "2025-01-08T00:00:00Z"
      }
    ],
    "override_history": [
      {
        "timestamp": "2025-01-15T10:30:00Z",
        "plan_id": "PLAN-2025-015",
        "original_priority": "medium",
        "new_priority": "critical",
        "plan_keywords": ["customer", "login"],
        "plan_files": ["src/auth/login.tsx"],
        "user_reason": "Customer-facing feature"
      }
    ]
  }
}
```

## Remember

- Learning is **transparent** - always show when patterns are applied
- Learning is **conservative** - patterns are tiebreakers, not overrides
- Learning is **reversible** - users can adjust, delete, or reset
- Learning **decays** - unused or wrong patterns fade over time
