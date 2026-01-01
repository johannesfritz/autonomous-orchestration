# Testing Strategy

This document outlines the testing philosophy and approach used across both shadow-api and hotel-de-ville projects.

## Testing Pyramid

Our testing strategy follows the standard testing pyramid:

```
       /\
      /  \   E2E Tests (Playwright)
     /----\
    /      \  Integration Tests (API + DB)
   /--------\
  /          \ Unit Tests (pytest)
 /____________\
```

**Distribution:**
- 70% Unit tests - Fast, isolated, test individual functions
- 20% Integration tests - Test component interactions (API + DB, pipeline stages)
- 10% E2E tests - Test complete user workflows

**Why this ratio:** Unit tests provide rapid feedback during development. Integration and E2E tests catch issues that only emerge when components interact.

## Unit Testing

### Framework: pytest with pytest-asyncio

Use pytest for all Python unit tests:

```python
import pytest
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_embedding_generation():
    # Arrange
    mock_client = AsyncMock()
    mock_client.embeddings.create.return_value = {"data": [{"embedding": [0.1, 0.2]}]}
    service = EmbeddingService(client=mock_client)

    # Act
    result = await service.get_embedding("test text")

    # Assert
    assert len(result) == 2
    mock_client.embeddings.create.assert_called_once()
```

**Key principles:**
- **Mock external services** - Never call real LLM/embedding/Qdrant APIs in unit tests
- **Test each function independently** - One test file per module
- **Use Arrange-Act-Assert pattern** - Makes tests readable and maintainable
- **Test edge cases** - Empty input, None values, error conditions

### Mocking Guidelines

**Always mock:**
- LLM API calls (Claude, OpenAI)
- Embedding API calls (OpenAI)
- Vector database operations (Qdrant)
- External HTTP requests
- File system operations (for deterministic tests)

**Never mock:**
- Business logic functions
- Data transformations
- Validation logic
- Internal utilities

**Why:** Mocking external dependencies makes tests fast, deterministic, and independent of network/service availability.

## Integration Testing

### Test Component Interactions

Integration tests verify that components work together correctly:

```python
@pytest.mark.asyncio
async def test_pipeline_stage_integration():
    """Test that Stage 2 correctly processes Stage 1 output"""
    # Use real Stage 1 and Stage 2, mock only Claude API
    stage1 = CleanupStage(mock_llm_client)
    stage2 = StructureStage(mock_llm_client)

    # Process through both stages
    cleaned = await stage1.process(raw_transcript)
    structured = await stage2.process(cleaned)

    # Verify structure matches expected schema
    assert "decisions" in structured
    assert "action_items" in structured
```

**What to test:**
- Pipeline stage handoffs (output of stage N → input of stage N+1)
- API endpoint + database interactions
- Service layer + repository interactions
- Frontend components + API calls

### Database Integration Tests

Test database operations with a real test database:

```python
@pytest.fixture
async def test_db():
    """Create temporary test database"""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest.mark.asyncio
async def test_user_creation_with_workspace(test_db):
    """Test creating user with associated workspace"""
    async with AsyncSession(test_db) as session:
        user = User(email="test@example.com")
        workspace = Workspace(name="Test", owner=user)
        session.add_all([user, workspace])
        await session.commit()

        # Verify relationship
        result = await session.execute(
            select(User).options(selectinload(User.workspaces))
        )
        loaded_user = result.scalar_one()
        assert len(loaded_user.workspaces) == 1
```

**Why:** Integration tests catch issues that unit tests miss (SQL syntax errors, foreign key violations, transaction handling).

## E2E Testing

### Framework: Playwright (for hotel-de-ville frontend)

Test complete user workflows:

```typescript
test('user can create workspace and invite member', async ({ page }) => {
  // Login
  await page.goto('http://localhost:3000');
  await page.fill('[name="email"]', 'test@example.com');
  await page.click('button:has-text("Login")');

  // Create workspace
  await page.click('button:has-text("New Workspace")');
  await page.fill('[name="workspace_name"]', 'My Team');
  await page.click('button:has-text("Create")');

  // Invite member
  await page.click('button:has-text("Invite")');
  await page.fill('[name="email"]', 'member@example.com');
  await page.click('button:has-text("Send Invitation")');

  // Verify invitation sent
  await expect(page.locator('text=Invitation sent')).toBeVisible();
});
```

**When to use E2E tests:**
- Critical user workflows (authentication, payment, data submission)
- Features that span frontend + backend + database
- Regression prevention for past production bugs

**When NOT to use E2E tests:**
- Testing individual API endpoints (use integration tests)
- Testing business logic (use unit tests)
- Testing every edge case (too slow)

## Test Organization

### Directory Structure

```
project/
├── tests/
│   ├── unit/
│   │   ├── test_services.py
│   │   ├── test_models.py
│   │   └── test_utils.py
│   ├── integration/
│   │   ├── test_pipeline.py
│   │   ├── test_api.py
│   │   └── test_migrations.py
│   └── e2e/
│       ├── test_auth_flow.spec.ts
│       └── test_workspace_management.spec.ts
```

### Naming Conventions

- **Test files:** `test_*.py` or `*.spec.ts`
- **Test functions:** `test_<function_name>_<scenario>`
- **Examples:**
  - `test_validate_email_with_valid_input`
  - `test_validate_email_with_invalid_input`
  - `test_validate_email_with_none_raises_error`

**Why:** Descriptive names make test failures immediately understandable without reading test code.

## Test Coverage

### Primary Metric: F2 Score (Retrieval Quality)

For vector search/retrieval systems, F2 score is more important than code coverage:

**F2 Score = (5 × Precision × Recall) / (4 × Precision + Recall)**

- Precision: What % of retrieved results are relevant?
- Recall: What % of relevant results were retrieved?
- F2 weights recall 2x higher than precision

**Why F2:** In knowledge retrieval, missing relevant information (low recall) is worse than including some irrelevant information (low precision).

**Target:** F2 ≥ 0.7 for production retrieval

### Code Coverage

**Targets:**
- Unit tests: 80%+ coverage
- Integration tests: 60%+ coverage for critical paths
- Overall: 70%+ coverage

**Measurement:**
```bash
pytest --cov=shadow_api --cov-report=html
```

**What NOT to test:**
- Trivial getters/setters
- Third-party library wrappers (unless complex logic)
- Auto-generated code (migrations, Pydantic models)

## Running Tests

### Local Development

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/unit/test_services.py

# Run with coverage
pytest --cov=shadow_api --cov-report=term-missing

# Run integration tests only
pytest tests/integration/

# Run E2E tests (hotel-de-ville)
npm run test:e2e
```

### CI/CD (GitHub Actions)

Tests run automatically on every push:
- All unit tests must pass
- All integration tests must pass
- E2E tests must pass (for hotel-de-ville)
- Coverage must not decrease

**Failing tests block deployment.**

## Test Data Management

### Use Fixtures for Reusable Test Data

```python
@pytest.fixture
def sample_note():
    return Note(
        title="Test Note",
        bluf="This is a test note",
        body="Detailed content here",
        tags=["test", "example"],
        priority="medium"
    )

def test_note_validation(sample_note):
    assert sample_note.validate() is True
```

**Why:** Fixtures reduce duplication and make tests more maintainable.

### Factory Pattern for Complex Objects

```python
class UserFactory:
    @staticmethod
    def create(
        email: str = "test@example.com",
        is_active: bool = True,
        **kwargs
    ) -> User:
        defaults = {"email": email, "is_active": is_active}
        defaults.update(kwargs)
        return User(**defaults)

def test_active_user_can_login():
    user = UserFactory.create(is_active=True)
    assert user.can_login() is True

def test_inactive_user_cannot_login():
    user = UserFactory.create(is_active=False)
    assert user.can_login() is False
```

**Why:** Factories provide flexible, readable test data creation without boilerplate.

## Best Practices

### 1. Test Behavior, Not Implementation

```python
# ❌ WRONG - Tests implementation details
def test_user_validation_calls_check_email():
    user = User(email="test@example.com")
    with patch.object(user, 'check_email') as mock:
        user.validate()
        mock.assert_called_once()

# ✅ CORRECT - Tests behavior
def test_user_validation_rejects_invalid_email():
    user = User(email="invalid")
    with pytest.raises(ValidationError):
        user.validate()
```

**Why:** Implementation tests break when refactoring, even if behavior is unchanged.

### 2. Each Test Should Test One Thing

```python
# ❌ WRONG - Tests multiple things
def test_user_lifecycle():
    user = create_user()
    assert user.is_active is True
    user.deactivate()
    assert user.is_active is False
    user.delete()
    assert user.is_deleted is True

# ✅ CORRECT - Separate tests
def test_new_user_is_active():
    user = create_user()
    assert user.is_active is True

def test_deactivate_sets_active_to_false():
    user = create_user()
    user.deactivate()
    assert user.is_active is False

def test_delete_sets_deleted_flag():
    user = create_user()
    user.delete()
    assert user.is_deleted is True
```

**Why:** Single-concern tests make failures easier to diagnose.

### 3. Use Descriptive Assertions

```python
# ❌ WRONG - Unclear failure message
assert len(results) == 5

# ✅ CORRECT - Clear failure message
assert len(results) == 5, f"Expected 5 search results, got {len(results)}"
```

**Why:** Descriptive assertions reduce time spent debugging test failures.

## When Tests Fail

### Test-Driven Bug Fixes

1. **Write a failing test** that reproduces the bug
2. **Fix the code** until test passes
3. **Verify** no other tests broke
4. **Commit** both test and fix together

**Why:** Ensures the bug stays fixed and adds regression protection.

### Flaky Tests

If a test fails intermittently:
1. **Investigate immediately** - Flaky tests erode trust
2. **Common causes:**
   - Race conditions (missing `await`)
   - Non-deterministic test data (random values, timestamps)
   - External dependencies (real API calls)
   - Shared state between tests
3. **Fix or disable** - Don't ignore

**Why:** Flaky tests train developers to ignore test failures, defeating the purpose of testing.

## Integration with Development Workflow

### Pre-Commit Testing

The `run-test-suite` skill automatically runs tests when code changes:
- Detects which project was modified
- Runs appropriate test suite
- Blocks commits if tests fail

### Quality Gates

Tests are enforced at multiple stages:
1. **Development:** run-test-suite skill
2. **Code Review:** shadow-code-reviewer checks test coverage
3. **CI/CD:** GitHub Actions runs full test suite
4. **Deployment:** Tests must pass before deploy

**No test failures reach production.**

## Further Reading

- pytest documentation: https://docs.pytest.org/
- pytest-asyncio: https://pytest-asyncio.readthedocs.io/
- Playwright: https://playwright.dev/
- F-Score: https://en.wikipedia.org/wiki/F-score
