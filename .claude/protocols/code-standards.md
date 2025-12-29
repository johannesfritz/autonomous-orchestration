# Code Standards Protocol

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
