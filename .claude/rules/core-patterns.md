---
paths:
  - "**/*.py"
---

# Core Development Patterns (Critical)

**These patterns prevent production bugs. Apply always.**

## Qdrant Queries - CRITICAL

Every Qdrant query MUST filter for active notes:

```python
filter = Filter(must=[
    FieldCondition(key="is_current", match=MatchValue(value=True)),
    FieldCondition(key="is_deleted", match=MatchValue(value=False)),
    FieldCondition(key="file_exists", match=MatchValue(value=True))
])
```

## NULL Handling - CRITICAL

Always handle NULL values explicitly in WHERE clauses:

```python
# WRONG - Excludes NULL values
items = session.query(Model).filter(Model.column == "value").all()

# CORRECT - Includes NULL values
from sqlalchemy import or_
items = session.query(Model).filter(
    or_(Model.column == "value", Model.column.is_(None))
).all()
```

## Error Handling

```python
try:
    result = await llm_service.process(content)
except anthropic.APIError as e:
    logger.error(f"Claude API error: {e}")
    # Implement retry or graceful degradation
```

## Type Safety

- Complete type hints on all functions
- Pydantic models with `Field()` for API contracts
- Import order: stdlib -> third-party -> local

**Full patterns:** `.claude/rules/development/patterns.md` (injected via hooks)
