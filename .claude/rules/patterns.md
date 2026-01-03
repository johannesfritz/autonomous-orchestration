# Common Development Patterns

This document captures reusable code patterns used across both shadow-api and hotel-de-ville projects.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Error Handling](#error-handling)
- [Async Patterns](#async-patterns)
  - [Batch Operations](#batch-operations)
  - [Async Context Managers](#async-context-managers)
- [Qdrant Query Patterns](#qdrant-query-patterns)
  - [Always Filter for Current, Non-Deleted Notes](#always-filter-for-current-non-deleted-notes)
- [Database Query Patterns](#database-query-patterns)
  - [NULL Handling](#null-handling)
  - [Explicit Value Setting](#explicit-value-setting)
- [Logging Patterns](#logging-patterns)
  - [Structured Logging](#structured-logging)
- [Import Organization](#import-organization)
- [Type Safety Patterns](#type-safety-patterns)
  - [Complete Type Hints](#complete-type-hints)
  - [Pydantic Validation](#pydantic-validation)
- [Performance Patterns](#performance-patterns)
  - [Lazy Loading](#lazy-loading)
- [Security Patterns](#security-patterns)
  - [Input Validation](#input-validation)
- [When to Use These Patterns](#when-to-use-these-patterns)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Error Handling

Always wrap LLM and embedding calls with proper error handling:

```python
# Always wrap LLM/embedding calls
try:
    result = await llm_service.process(content)
except anthropic.APIError as e:
    logger.error(f"Claude API error: {e}")
    # Implement retry or graceful degradation
```

**Why:** LLM APIs can fail due to rate limits, network issues, or service outages. Graceful degradation ensures the system remains usable even when external services fail.

## Async Patterns

### Batch Operations

Process multiple items concurrently using `asyncio.gather`:

```python
# Batch operations where possible
embeddings = await asyncio.gather(*[
    get_embedding(note.bluf) for note in notes
])
```

**Why:** Batching reduces total execution time by parallelizing I/O-bound operations. Critical for performance when processing large document sets.

### Async Context Managers

Use async context managers for resource management:

```python
# Use async context managers
async with httpx.AsyncClient() as client:
    response = await client.post(...)
```

**Why:** Ensures proper cleanup of connections and resources, preventing memory leaks and connection pool exhaustion.

## Qdrant Query Patterns

### Always Filter for Current, Non-Deleted Notes

Every Qdrant query MUST filter for active notes only:

```python
# Always filter for current, non-deleted notes
filter = Filter(must=[
    FieldCondition(key="is_current", match=MatchValue(value=True)),
    FieldCondition(key="is_deleted", match=MatchValue(value=False)),
    FieldCondition(key="file_exists", match=MatchValue(value=True))
])
```

**Why:** Qdrant stores versioned data with soft deletes. Failing to filter returns stale/deleted content, causing incorrect retrieval results and user confusion.

## Database Query Patterns

### NULL Handling

Always handle NULL values explicitly in WHERE clauses:

```python
# ❌ WRONG - Excludes NULL values
items = session.query(Model).filter(Model.column == "value").all()

# ✅ CORRECT - Includes NULL values
from sqlalchemy import or_
items = session.query(Model).filter(
    or_(Model.column == "value", Model.column.is_(None))
).all()
```

**Why:** SQL's three-valued logic means `column = 'value'` excludes NULL rows. This caused production bugs (e.g., missing users_workspaces rows after adding `is_favorite` column).

### Explicit Value Setting

Always set column values explicitly in helper functions:

```python
# ❌ WRONG - Relies on DEFAULT
obj = Model(field1="value")  # field2 omitted

# ✅ CORRECT - Explicit values
obj = Model(field1="value", field2="default_value")
```

**Why:** Database DEFAULT values only apply to INSERT statements, not ORM object creation. Explicit values ensure consistency across all code paths.

## Logging Patterns

### Structured Logging

Use structured logging for production code:

```python
# ❌ WRONG - Unstructured print
print(f"Processing user {user_id}")

# ✅ CORRECT - Structured logger
logger.info("Processing user", extra={"user_id": user_id, "action": "registration"})
```

**Why:** Structured logs enable filtering, aggregation, and alerting in production monitoring systems.

## Import Organization

Organize imports in three blocks separated by blank lines:

```python
# Standard library
import asyncio
import logging
from typing import Optional

# Third-party
import anthropic
from fastapi import HTTPException
from pydantic import BaseModel

# Local
from .services import EmbeddingService
from .models import Note
```

**Why:** Consistent import ordering improves readability and reduces merge conflicts.

## Type Safety Patterns

### Complete Type Hints

Provide complete type hints on all functions:

```python
# ❌ WRONG - Missing types
def process(items, config):
    ...

# ✅ CORRECT - Complete types
def process(items: list[Item], config: ProcessConfig) -> ProcessResult:
    ...
```

**Why:** Type hints enable IDE autocomplete, catch bugs at development time, and serve as living documentation.

### Pydantic Validation

Use Pydantic models with `Field()` for API contracts:

```python
from pydantic import BaseModel, Field

class UserRegistration(BaseModel):
    email: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    age: int = Field(..., ge=0, le=150)

    class Config:
        json_schema_extra = {
            "example": {
                "email": "user@example.com",
                "age": 25
            }
        }
```

**Why:** Pydantic validates input at runtime, generates OpenAPI schemas, and provides clear error messages for API consumers.

## Performance Patterns

### Lazy Loading

Defer expensive operations until actually needed:

```python
# ❌ WRONG - Loads everything upfront
class Pipeline:
    def __init__(self):
        self.embeddings = load_all_embeddings()  # Expensive!

# ✅ CORRECT - Lazy initialization
class Pipeline:
    def __init__(self):
        self._embeddings = None

    @property
    def embeddings(self):
        if self._embeddings is None:
            self._embeddings = load_all_embeddings()
        return self._embeddings
```

**Why:** Lazy loading reduces startup time and memory usage, especially for resources that may not be needed in all code paths.

## Security Patterns

### Input Validation

Always validate and sanitize user input:

```python
from pathlib import Path

def read_user_file(filename: str) -> str:
    # ❌ WRONG - Path traversal vulnerability
    with open(f"/data/{filename}") as f:
        return f.read()

    # ✅ CORRECT - Validated path
    safe_path = Path("/data") / filename
    if not safe_path.resolve().is_relative_to(Path("/data")):
        raise ValueError("Invalid file path")
    with open(safe_path) as f:
        return f.read()
```

**Why:** Unvalidated input enables path traversal attacks, allowing access to sensitive files outside the intended directory.

## When to Use These Patterns

These patterns are **principles**, not checklists. Use them as:
- **Design guides** when architecting new features
- **Reference examples** when unsure of best approach
- **Teaching tools** for code reviews

For enforcement checklists, see `.claude/protocols/*.md` files.
