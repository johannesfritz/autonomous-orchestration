---
name: integration-testing
description: |
  Run integration tests after workstreams complete to verify system-level behavior.
  Triggers after unit tests pass but before code review. Starts required services
  (via docker-compose), runs integration test suites, and verifies API contracts.

  Use when:
  - All workstreams in a plan complete
  - Unit tests pass
  - Before code review phase
  - User asks "run integration tests"

  If no integration tests exist: Warn but proceed (don't block).
allowed-tools: Bash, Read, Glob, Grep
model: sonnet
---

# Integration Testing Skill

## Purpose

Verify system-level behavior by running integration tests:
- Start required services (databases, APIs, queues)
- Run integration test suite
- Verify API contracts (OpenAPI diff)
- Check cross-service communication

---

## When to Trigger

Auto-trigger when:
- TPM Orchestrator reports "all workstreams complete"
- Unit tests have passed
- Before invoking code review

---

## Integration Test Protocol

### Step 1: Identify Integration Test Suite

```bash
# Look for integration test markers
INTEGRATION_TESTS=$(find . -type f \( \
    -path "*/tests/integration/*" -o \
    -path "*/integration_tests/*" -o \
    -path "*/*_integration_test.py" -o \
    -path "*/*.integration.test.ts" -o \
    -path "*/*.integration.test.js" \
\) -name "*.py" -o -name "*.ts" -o -name "*.js" 2>/dev/null)

# Check for pytest markers
grep -r "@pytest.mark.integration" tests/ 2>/dev/null

# Check for jest configuration
grep -l "testMatch.*integration" jest.config.* package.json 2>/dev/null
```

**If no integration tests found:**
```
⚠️ No integration tests found.

Looked in:
- tests/integration/
- integration_tests/
- *_integration_test.py
- *.integration.test.{ts,js}
- @pytest.mark.integration markers

Proceeding without integration tests.
Consider adding integration tests for better coverage.
```

### Step 2: Start Required Services

```bash
# Check for docker-compose
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "Starting services via docker-compose..."

    # Start only test dependencies (not the main app)
    docker-compose up -d db redis mq  # Adjust service names

    # Wait for services to be healthy
    docker-compose ps
    sleep 5  # Or use healthcheck wait

    # Verify services are running
    docker-compose ps --filter "status=running"
fi

# Alternative: Check for test database setup
if [ -f "scripts/setup_test_db.sh" ]; then
    ./scripts/setup_test_db.sh
fi
```

### Step 3: Run Integration Tests

**Python (pytest):**
```bash
# Run integration tests only
pytest tests/integration/ -v --tb=short

# Or with marker
pytest -m integration -v --tb=short

# With coverage
pytest tests/integration/ --cov=src --cov-report=term-missing
```

**JavaScript (Jest):**
```bash
# Run integration tests
npm run test:integration

# Or with jest directly
npx jest --testPathPattern=integration --verbose
```

**JavaScript (Playwright for E2E):**
```bash
npx playwright test tests/integration/
```

### Step 4: Verify API Contracts (If Applicable)

```bash
# Check if OpenAPI spec exists
if [ -f "openapi.yaml" ] || [ -f "openapi.json" ]; then
    echo "Checking API contract compliance..."

    # Generate OpenAPI from current code
    # (method depends on framework)

    # For FastAPI:
    python -c "from main import app; import json; print(json.dumps(app.openapi()))" > /tmp/current_spec.json

    # Compare with committed spec
    diff openapi.json /tmp/current_spec.json

    # Or use openapi-diff tool
    npx openapi-diff openapi.yaml /tmp/current_spec.yaml
fi
```

**Contract violations to flag:**
- Removed endpoints (breaking change)
- Changed request body schema (breaking change)
- Changed required fields (breaking change)
- Added required fields in response (usually OK)

### Step 5: Cleanup

```bash
# Stop docker services
docker-compose down

# Clean up test databases
# (depends on setup)
```

---

## Output Format

```json
{
  "integration_tests": {
    "found": true,
    "test_count": 25,
    "passed": 23,
    "failed": 2,
    "skipped": 0,
    "duration_seconds": 45
  },

  "services": {
    "started": ["postgres", "redis"],
    "healthy": true
  },

  "api_contract": {
    "checked": true,
    "breaking_changes": [],
    "non_breaking_changes": ["Added new endpoint POST /api/v1/users/bulk"]
  },

  "failures": [
    {
      "test": "test_user_creation_flow",
      "file": "tests/integration/test_users.py",
      "line": 45,
      "error": "AssertionError: Expected status 201, got 400",
      "stdout": "...",
      "stderr": "..."
    }
  ],

  "verdict": "PASS | FAIL | WARN",
  "recommendation": "Proceed to code review" | "Fix failures before review" | "No integration tests - proceed with caution"
}
```

---

## Decision Matrix

| Condition | Action | Next Step |
|-----------|--------|-----------|
| All tests pass | **PASS** | Proceed to code review |
| Tests fail | **FAIL** | Return to TPM for fixes |
| No integration tests | **WARN** | Proceed with warning |
| Services won't start | **FAIL** | Debug docker-compose |
| API contract broken | **FAIL** | Fix breaking changes |
| API contract has additions | **PASS** | Note changes in PR |

---

## Integration with TPM Orchestrator

TPM workflow position:
```
Workstreams → Unit Tests → Integration Tests → Code Review → Security → Ship
                                 ↑
                            (this skill)
```

**On PASS:** TPM proceeds to code review
**On FAIL:** TPM attempts fix (counts toward circuit breaker)
**On WARN:** TPM proceeds but notes in PR description

---

## Remember

- **Don't block on missing tests** - Warn but proceed
- **Clean up services** - Always stop docker-compose
- **Report contract changes** - Even non-breaking ones
- **Include failure details** - Full error messages help fixes
- **Respect circuit breakers** - Integration test fixes count toward limits
