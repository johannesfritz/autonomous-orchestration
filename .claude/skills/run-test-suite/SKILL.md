---
name: run-test-suite
description: Automatically run the test suite when code changes are made to ensure all tests pass before proceeding. This skill runs pytest for backend projects and Playwright for frontend projects, and reports test results, coverage, and any failures.
when_to_invoke: |
  Invoke this skill automatically when:
  - Any Python file (.py) is modified in hotel-de-ville/backend/, shadow-api/app/, or stellaris/backend/
  - Any TypeScript/TSX file is modified in hotel-de-ville/frontend/ or stellaris/frontend/
  - User asks to "run tests", "test this", "check if tests pass", or similar
  - Before suggesting a commit if code changes were made
  - After implementing a new feature or fixing a bug
  - When user asks "does this work?" or "is this correct?"
---

You are responsible for running the test suite to verify code quality and correctness.

## Your Task

1. **Identify the project** - Determine if changes are in hotel-de-ville, shadow-api, or stellaris
2. **Identify component** - Backend (pytest) or frontend (Playwright/vitest)
3. **Navigate to project directory**
4. **Activate virtual environment** if backend, or install deps if frontend
5. **Run appropriate tests**
6. **Report results** clearly

## Execution Steps

### For hotel-de-ville/backend

```bash
cd /home/user/jf-private/hotel-de-ville/backend

# Activate venv if exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run tests with coverage
pytest -v --tb=short
```

### For shadow-api

```bash
cd /home/user/jf-private/shadow-api

# Activate venv if exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run tests with coverage
pytest -v --tb=short
```

### For stellaris/backend

```bash
cd /home/user/jf-private/stellaris/backend

# Activate venv if exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run tests with coverage
pytest -v --tb=short
```

### For stellaris/frontend (Playwright E2E tests)

```bash
cd /home/user/jf-private/stellaris/frontend

# Install dependencies if needed
npm install

# Run Playwright tests
npx playwright test --reporter=list
```

**IMPORTANT for Stellaris Frontend:** Playwright tests exist in `stellaris/frontend/tests/` and test:
- Chapter selection behavior
- Training mode navigation
- Session completion
- Stats persistence
- Vocabulary browser

## Reporting Results

After running tests, provide a clear summary:

**If all tests pass:**
```
✅ Test Suite Passed

Project: hotel-de-ville/backend
Tests run: 23
Passed: 23
Failed: 0
Duration: 2.3s

All tests passed successfully. Code is ready for commit.
```

**If tests fail:**
```
❌ Test Suite Failed

Project: shadow-api
Tests run: 15
Passed: 12
Failed: 3

Failed tests:
1. test_pipeline.py::test_atomize_stage - AssertionError: BLUF missing
2. test_retrieval.py::test_dual_embedding - IndexError: list index out of range
3. test_integration.py::test_full_pipeline - ValueError: Invalid source_type

⚠️ Fix these failures before committing.
```

## Additional Checks

If tests pass, you may also:
- Check for warnings in test output
- Note if coverage has decreased (if pytest-cov is available)
- Suggest running specific test files if only partial changes were made

## When NOT to Invoke

- For non-code changes (markdown files, documentation only)
- When user explicitly says "skip tests" or "don't run tests"
- For trivial changes like comment updates or formatting

## Priority

This is a **HIGH PRIORITY** skill. Code quality depends on passing tests. Always run tests before suggesting commits or marking features as complete.
