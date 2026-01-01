# Anti-Debt Strategy

Technical debt accumulates naturally as systems grow. This document outlines our proactive strategy to prevent and reduce code bloat, complexity, and maintenance burden.

## Philosophy: Code is a Liability, Not an Asset

**Core principle:** Every line of code has a maintenance cost. The best code is code that doesn't exist.

**Counterintuitive truth:** Deleting code is often more valuable than writing it.

**Goal:** Minimize the surface area of the codebase while maximizing functionality.

## The Gardener Agent

The `gardener` agent is a specialized refactoring agent that runs weekly (or after major sprints) with a singular mission:

**Mission: DELETE and CONDENSE code, not add to it.**

**Invocation:** `/refactor` or `/garden`

**Scope:**
- Remove dead code (unused functions, commented code, orphaned files)
- Consolidate duplicates (DRY violations, copy-pasted logic)
- Simplify complex functions (split, early returns, reduce nesting)
- Improve naming (eliminate need for comments)

**Success metric:** Lines of code REMOVED, not added.

### Gardener Rules

The gardener operates under strict rules to reduce code systematically:

#### Rule 1: Rule of Three

**If logic appears 3+ times, extract to utility.**

```python
# ❌ BEFORE: Same validation appears 3 times
def create_user(email):
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email):
        raise ValueError("Invalid email")
    ...

def update_user(email):
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email):
        raise ValueError("Invalid email")
    ...

def invite_user(email):
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email):
        raise ValueError("Invalid email")
    ...

# ✅ AFTER: Extract to utility (3 copies → 1 function)
def validate_email(email: str) -> None:
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email):
        raise ValueError("Invalid email")

def create_user(email):
    validate_email(email)
    ...
```

**Why:** Duplication multiplies maintenance cost. Bug fixes must be applied in N places. Extracting reduces surface area.

#### Rule 2: 50-Line Limit

**Functions >50 lines must be split.**

```python
# ❌ BEFORE: 80-line function (too complex)
def process_registration(data):
    # 15 lines of validation
    # 20 lines of data transformation
    # 15 lines of database operations
    # 10 lines of email sending
    # 20 lines of logging
    ...

# ✅ AFTER: Split into focused functions
def process_registration(data):
    validated = validate_registration(data)
    user = create_user(validated)
    send_welcome_email(user)
    log_registration(user)
    return user

def validate_registration(data):
    # 15 lines
    ...

def create_user(validated):
    # 20 lines
    ...
```

**Why:** Long functions are hard to test, understand, and modify. Each function should do ONE thing.

#### Rule 3: 3-Level Nesting Maximum

**Maximum nesting depth = 3. Use early returns to flatten.**

```python
# ❌ BEFORE: 5-level nesting
def check_access(user, resource, action):
    if user:
        if user.is_active:
            if resource:
                if resource.is_public:
                    return True
                else:
                    if user.has_permission(resource, action):
                        return True
    return False

# ✅ AFTER: 1-level nesting with early returns
def check_access(user, resource, action):
    if not user or not user.is_active:
        return False
    if not resource:
        return False
    if resource.is_public:
        return True
    return user.has_permission(resource, action)
```

**Why:** Deep nesting is cognitively taxing. Early returns make logic linear and easier to follow.

#### Rule 4: Dead Code Deletion

**Remove commented code, unused functions, orphaned files.**

```python
# ❌ BEFORE: Commented "just in case"
def process_data(data):
    result = transform(data)
    # Old implementation (keeping for reference)
    # result = old_transform(data)
    # if legacy_mode:
    #     result = legacy_process(result)
    return result

# ✅ AFTER: Delete it (git history preserves it)
def process_data(data):
    return transform(data)
```

**Why:** Commented code rots and creates confusion. Git history is the archive, not source files.

**Detection:**
```bash
# Find unused functions
vulture .

# Find orphaned files (no imports)
# Manual review + delete
```

#### Rule 5: Naming Over Comments

**Good names eliminate the need for comments.**

```python
# ❌ BEFORE: Cryptic names need comments
def calc(u, w):  # Calculate user's workspace quota usage
    # Get all files in workspace
    f = get_files(w)
    # Sum file sizes
    total = sum([f.size for f in files])
    # Convert to MB
    mb = total / 1024 / 1024
    return mb

# ✅ AFTER: Names explain intent
def calculate_workspace_storage_usage_mb(user: User, workspace: Workspace) -> float:
    files = workspace.get_all_files()
    total_bytes = sum(file.size_bytes for file in files)
    return bytes_to_megabytes(total_bytes)

def bytes_to_megabytes(bytes: int) -> float:
    return bytes / 1024 / 1024
```

**Why:** Comments go stale. Names are enforced by the compiler and IDE.

## Strict Code Standards (For Major Changes)

For major changes (database, auth, new features), the `shadow-code-reviewer` applies the "Strict Senior" protocol.

**Context:** `.claude/protocols/strict-code-standards.md` (injected via SubagentStart hook)

### Absolute Rules (Violation = Rejection)

These are NON-NEGOTIABLE for critical code:

1. **Function length ≤ 50 lines** - Split longer functions
2. **No vague variable names** - Ban `data`, `info`, `item`, `temp`, `result`, `val`
3. **Complete type annotations** - All parameters and returns typed
4. **No empty except/catch blocks** - Log errors, raise specific exceptions
5. **No console.log/print in production code** - Use structured logger
6. **No magic numbers/strings** - Use named constants
7. **Tests required for new public functions** - At least one test per function

**Enforcement:** shadow-code-reviewer in strict mode will REJECT code that violates any absolute rule.

### Strong Preferences (Violation = Request Changes)

These are strong recommendations but can be overridden with justification:

1. **Early returns over deep nesting** - Flatten control flow
2. **Composition over inheritance** - Prefer has-a over is-a
3. **Explicit parameters over kwargs** - Named parameters for clarity
4. **Fail fast with specific errors** - Don't silently return None

**Enforcement:** shadow-code-reviewer will REQUEST CHANGES but may approve if justified.

### Component Library Restriction (Frontend)

**Problem:** Custom components create inconsistency and maintenance burden.

**Solution:** Use shadcn/ui component library exclusively.

**Forbidden:**
- Custom Button, Input, Select, Dialog, Card components
- Inline modal patterns without Dialog
- Card-like styling without Card component

**Required:**
- Import from `@/components/ui/[component]`
- Use shadcn/ui variants and sizes
- Document exceptions with justification

**Why:** Component libraries provide consistent UX, accessibility, and reduce custom code.

## Anti-Patterns to Detect and Remove

### 1. God Objects

**Symptom:** Single class/module with 1000+ lines, dozens of methods.

**Fix:** Split into focused modules (Single Responsibility Principle).

### 2. Copy-Paste Programming

**Symptom:** Nearly identical blocks of code in multiple places.

**Fix:** Extract to utility, apply Rule of Three.

### 3. Premature Abstraction

**Symptom:** Complex inheritance hierarchies, generic frameworks for single use case.

**Fix:** Inline abstractions, simplify to concrete implementations.

**Quote:** "Duplication is cheaper than the wrong abstraction." - Sandi Metz

### 4. Configuration Hell

**Symptom:** Dozens of environment variables, nested config files.

**Fix:** Use sensible defaults, reduce configuration surface area.

### 5. Over-Engineering

**Symptom:** Design patterns used for no reason, future-proofing that never gets used.

**Fix:** YAGNI (You Aren't Gonna Need It). Delete speculative code.

## Refactoring Workflow

### When to Refactor

**Scheduled refactoring:**
- Weekly gardener runs (automated)
- After major feature sprints
- Before release milestones

**Opportunistic refactoring:**
- When you notice a Rule of Three violation
- When you struggle to understand your own code
- When tests become hard to write

**DON'T refactor:**
- While actively developing a feature (finish first, refactor later)
- Without tests (refactor with safety net only)
- Just because you can (needs business value)

### Refactoring Checklist

Before refactoring:

- [ ] All tests pass (green)
- [ ] Commit current work (clean slate)
- [ ] Identify specific smell (vague "cleanup" is anti-pattern)

During refactoring:

- [ ] Run tests after each small change
- [ ] Commit frequently (atomic refactorings)
- [ ] Keep behavior unchanged (no new features)

After refactoring:

- [ ] All tests still pass
- [ ] Code review (shadow-code-reviewer)
- [ ] Measure: Did lines of code decrease?

### Example Refactoring Session

**Goal:** Reduce complexity of `process_user_registration` function.

**Before:**
- 87 lines
- 5-level nesting
- 12 variable names
- 0 tests

**Gardener actions:**
1. Extract validation → `validate_registration_input` (15 lines)
2. Extract user creation → `create_user_from_registration` (20 lines)
3. Extract email sending → `send_welcome_email` (10 lines)
4. Main function reduced to 8 lines (composition)
5. Add tests for each extracted function

**After:**
- 53 lines total (down from 87)
- 2-level nesting max
- Clear, specific names
- 4 tests (one per function)

**Result:** 34 lines deleted, complexity reduced, test coverage added.

## Metrics and Monitoring

### Code Health Metrics

**Track over time:**

| Metric | Target | Current |
|--------|--------|---------|
| Average function length | < 30 lines | ? |
| Max function length | < 50 lines | ? |
| Cyclomatic complexity | < 10 per function | ? |
| Code duplication | < 3% | ? |
| Test coverage | > 70% | ? |

**Tools:**
- `radon` - Cyclomatic complexity
- `vulture` - Dead code detection
- `pylint` - Code quality
- `pytest --cov` - Coverage

### Weekly Gardener Report

After each gardener run:

```markdown
## Refactoring Report - 2025-01-01

**Lines of Code:**
- Before: 12,453
- After: 11,892
- **Deleted: 561 lines** ✅

**Functions Refactored:**
- Split: 8 functions (over 50 lines)
- Extracted: 12 utilities (Rule of Three violations)
- Deleted: 23 dead functions

**Quality Improvements:**
- Max function length: 87 → 49 lines
- Average nesting: 3.2 → 2.1 levels
- Duplication: 5.2% → 2.8%

**Tests Added:**
- 18 new tests for extracted utilities
- Coverage: 68% → 72%

**Next Focus:**
- auth/ module has high complexity (target next week)
```

## Integration with Development Workflow

### Hook Integration

The gardener is activated via `SubagentStart` hook:

```json
{
  "type": "SubagentStart",
  "matcher": "gardener",
  "protocol": ".claude/protocols/gardener-mission.md"
}
```

**Protocol reminder:** DELETE and CONDENSE, not add.

### When Gardener Runs

1. **Manual invocation:** `/refactor` or `/garden`
2. **After major sprints:** Portfolio Manager schedules weekly
3. **Before releases:** Pre-release cleanup pass

### Gardener Output

The gardener produces:
- List of files modified
- Lines of code deleted
- Complexity reductions
- Test coverage improvements

**No new features added.** If the gardener adds code, it failed its mission.

## Cultural Norms

### Code Review: Praise Deletions

**In code reviews, celebrate:**
- "Great refactor! 200 lines deleted."
- "Nice simplification of this function."
- "Good catch on the duplication."

**Don't just focus on additions.**

### Feature Flags Over Commented Code

**Instead of commenting:**
```python
# def old_implementation():
#     ...

def new_implementation():
    ...
```

**Use feature flags:**
```python
if feature_flags.is_enabled("new_implementation"):
    return new_implementation()
else:
    return old_implementation()

# After rollout, delete old_implementation entirely
```

**Why:** Feature flags enable A/B testing and safe rollback. No code rot.

### The Boy Scout Rule

**"Leave code better than you found it."**

When touching a file:
- Fix one nearby issue (rename variable, add type hint, extract duplication)
- Don't refactor the whole file (out of scope)
- Small improvements compound over time

## Summary

Anti-debt strategy prevents codebase bloat through:

1. **Gardener agent** - Systematic deletion and consolidation (weekly)
2. **Strict code standards** - Enforced for major changes (hooks)
3. **Refactoring rules** - Rule of Three, 50-line limit, 3-level nesting
4. **Cultural norms** - Celebrate deletions, Boy Scout Rule

**Key insight:** Technical debt is prevented, not just paid down. Proactive refactoring is cheaper than reactive firefighting.

**Measurement:** Success = Lines of code deleted per week, not added.
