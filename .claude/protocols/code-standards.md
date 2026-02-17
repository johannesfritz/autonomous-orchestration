# Code Standards Protocol

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Python (PEP-8 + Project Conventions)](#python-pep-8--project-conventions)
  - [Required for ALL Python code:](#required-for-all-python-code)
  - [Error Handling:](#error-handling)
  - [Qdrant Queries - CRITICAL:](#qdrant-queries---critical)
- [TypeScript/React](#typescriptreact)
  - [Required:](#required)
  - [CSS Positioning Rules (CRITICAL for dropdowns/modals):](#css-positioning-rules-critical-for-dropdownsmodals)
  - [New Page Components Must Have Routes:](#new-page-components-must-have-routes)
- [Security Checklist (OWASP Top 10)](#security-checklist-owasp-top-10)
- [Avoid Over-Engineering](#avoid-over-engineering)
- [Claude Model Selection](#claude-model-selection)
- [Git Discipline](#git-discipline)
- [Database Changes (CRITICAL)](#database-changes-critical)
  - [When This Applies](#when-this-applies)
  - [Mandatory Requirements](#mandatory-requirements)
  - [NULL Handling Pattern](#null-handling-pattern)
  - [Helper Function Pattern](#helper-function-pattern)
  - [Checklist Reference](#checklist-reference)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Python (PEP-8 + Project Conventions)

### Required for ALL Python code:
- Complete type hints on all functions (use `-> None` for void returns)
- Async functions: Use `async def` with `await`, never mix sync calls
- Pydantic models: Use `Field()` for documentation and validation
- Import ordering: stdlib → third-party → local (separated by blank lines)

### Error Handling:
```python
# Always wrap LLM/embedding calls
try:
    result = await llm_service.process(content)
except anthropic.APIError as e:
    logger.error(f"Claude API error: {e}")
    # Implement retry or graceful degradation
```

### Qdrant Queries - CRITICAL:
```python
# ALWAYS filter for current, non-deleted notes
filter = Filter(must=[
    FieldCondition(key="is_current", match=MatchValue(value=True)),
    FieldCondition(key="is_deleted", match=MatchValue(value=False)),
    FieldCondition(key="file_exists", match=MatchValue(value=True))
])
```

## TypeScript/React

### Required:
- Explicit types on all function parameters and returns
- Use interfaces over types where appropriate
- Tailwind CSS for styling (no inline styles)
- Proper error boundaries for components

### CSS Positioning Rules (CRITICAL for dropdowns/modals):

**Position modes use different coordinate systems:**

| Position | Coordinates | Use |
|----------|-------------|-----|
| `fixed` | Viewport | `getBoundingClientRect()` directly |
| `absolute` | Document | `rect + window.scrollX/Y` |

```tsx
// ❌ WRONG: Adding scroll offset to fixed positioning
const top = rect.bottom + window.scrollY;
<div style={{ position: 'fixed', top }}>...</div>

// ✅ CORRECT: Viewport coords for fixed positioning
const top = rect.bottom;
<div style={{ position: 'fixed', top }}>...</div>
```

### New Page Components Must Have Routes:

When creating a new page component:
- [ ] Add route to `App.tsx` (or router config)
- [ ] Wrap in `RequireAuth` if protected
- [ ] Verify `navigate()` calls use correct path

## Security Checklist (OWASP Top 10)

Before writing code that handles:
- User input → Validate and sanitize
- Database queries → Use parameterized queries
- File paths → Prevent path traversal
- API responses → Don't expose internal errors
- Secrets → Never hardcode, use environment variables

## Avoid Over-Engineering

- Only make changes directly requested
- Don't add features beyond what was asked
- Don't add comments to code you didn't change
- Don't refactor surrounding code unless asked
- Keep solutions simple and focused

## Claude Model Selection

| Task | Model |
|------|-------|
| Stage 1 cleanup, simple extractions | claude-3-5-haiku-20241022 |
| Pipeline stages, most processing | claude-sonnet-4-20250514 |
| Complex queries, critical decisions | claude-opus-4-20250514 |

## Git Discipline

- Never commit untested code
- Run tests before suggesting commits
- Clear, descriptive commit messages
- Never push to main without review

## Database Changes (CRITICAL)

**Schema changes are HIGH RISK and require enhanced verification.**

### When This Applies

Schema changes include:
- ALTER TABLE (add/drop/modify columns)
- CREATE TABLE / DROP TABLE
- CREATE INDEX / DROP INDEX
- Changes to models.py (new columns, new tables)
- Changes to WHERE clauses in queries

### Mandatory Requirements

1. **Migration Script**
   - File: `migrations/YYYYMMDD_HHMMSS_description.sql`
   - Includes backfill for existing rows
   - Tested against production snapshot
   - Rollback plan documented

2. **Migration Tests**
   - Added to `tests/test_migrations.py`
   - Tests verify NULL handling
   - Tests verify backward compatibility

3. **Code Updates**
   - All INSERT statements include new column
   - All helper functions set value explicitly
   - All queries handle NULL gracefully
   - Indexes added for new query patterns

4. **Code Review**
   - Schema-migration-checklist.md completed
   - Senior review (shadow-code-reviewer in strict mode)
   - Major change detection triggered

5. **Deployment**
   - Database backup created
   - Smoke tests defined
   - Monitoring plan documented

### NULL Handling Pattern

**Always handle NULL values in queries:**

```python
# ❌ WRONG - Excludes NULL
items = session.query(Model).filter(Model.column == "value").all()

# ✅ CORRECT - Includes NULL
from sqlalchemy import or_
items = session.query(Model).filter(
    or_(Model.column == "value", Model.column.is_(None))
).all()
```

### Helper Function Pattern

**Always set values explicitly:**

```python
# ❌ WRONG - Relies on DEFAULT
obj = Model(field1="value")  # field2 omitted

# ✅ CORRECT - Explicit values
obj = Model(field1="value", field2="default_value")
```

### Checklist Reference

See `.claude/protocols/schema-migration-checklist.md` for complete requirements.
