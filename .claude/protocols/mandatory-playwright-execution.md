# Mandatory Playwright UAT Execution Protocol

**Purpose:** Enforce actual Playwright test execution for every plan with user-facing changes. Checklist-only UAT is INSUFFICIENT.

---

## The Problem This Solves

**Observed failure pattern (protokoll-assistent, 2026-01-06):**

1. Plan executed ✅
2. Tests pass ✅
3. Code review approved ✅
4. UAT checklist created ✅
5. **Audio recording doesn't work** ❌

**Root cause:** UAT gate checked for checklist file, didn't actually execute user journeys.

---

## BLOCKING REQUIREMENT

**For plans with user-facing changes, Playwright tests MUST:**

1. **EXIST** - Test file created for the feature
2. **EXECUTE** - Actually run via `npx playwright test`
3. **PASS** - Zero failures, zero errors
4. **VERIFY CORE FUNCTIONALITY** - Not just page loads, but actual feature behavior

---

## TPM Orchestrator UAT Execution (Step 8)

Replace checklist verification with actual execution:

```bash
### 8. QUALITY GATE: UAT (MANDATORY - BLOCKING)

# STEP 1: Determine UAT requirements from plan
PLAN_HAS_FRONTEND=$(grep -l "frontend\|UI\|page\|component" "$PLAN_FILE" && echo "true" || echo "false")
PLAN_HAS_API=$(grep -l "endpoint\|API\|router" "$PLAN_FILE" && echo "true" || echo "false")

# STEP 2: Generate Playwright test if it doesn't exist
if [ "$PLAN_HAS_FRONTEND" = "true" ]; then
    # Check for existing UAT test
    UAT_TEST_FILE="tests/uat/${PLAN_ID}.spec.ts"

    if [ ! -f "$UAT_TEST_FILE" ]; then
        # Generate test from plan's user journeys
        # (Use qa-engineer agent to create test spec)
        Task(subagent_type="qa-engineer", prompt='''
            Create Playwright UAT test for plan: {PLAN_ID}

            User journeys to test:
            {Extract from plan file}

            Output file: tests/uat/{PLAN_ID}.spec.ts

            CRITICAL: Tests must verify ACTUAL FUNCTIONALITY, not just page loads.
            - If feature is audio recording, test that recording starts/stops
            - If feature is form submission, test that data persists
            - If feature is navigation, test that routes work
        ''')
    fi

    # STEP 3: EXECUTE Playwright tests (BLOCKING)
    cd "$WORKTREE_DIR/frontend"

    # Start local stack if not running
    $CLAUDE_PROJECT_DIR/.claude/scripts/start-local-stack.sh "$PROJECT" &
    STACK_PID=$!
    sleep 10  # Wait for servers

    # Run UAT tests
    npx playwright test tests/uat/${PLAN_ID}.spec.ts --reporter=json > uat-results.json
    UAT_EXIT_CODE=$?

    # Kill local stack
    kill $STACK_PID 2>/dev/null

    # STEP 4: Evaluate results (BLOCKING)
    if [ $UAT_EXIT_CODE -ne 0 ]; then
        # Parse failures from uat-results.json
        FAILURES=$(jq '.stats.failures' uat-results.json)
        FAILED_TESTS=$(jq -r '.suites[].specs[] | select(.ok == false) | .title' uat-results.json)

        echo "❌ UAT FAILED: $FAILURES test(s) failed"
        echo "Failed tests:"
        echo "$FAILED_TESTS"

        # Mark plan status
        STATUS="FAILED_UAT"

        # Create failure report
        cat > "inbox/failed-plans/${PLAN_ID}-uat-failure.md" << EOF
# UAT Failure: $PLAN_ID

**Date:** $(date -Iseconds)
**Failures:** $FAILURES

## Failed Tests
$FAILED_TESTS

## Playwright Output
$(cat uat-results.json | jq '.')

## Next Steps
1. Review failed assertions
2. Fix implementation issues
3. Re-run: npx playwright test tests/uat/${PLAN_ID}.spec.ts
EOF

        # HALT EXECUTION
        RETURN from TPM with UAT failure
    fi

    echo "✅ UAT passed: All Playwright tests successful"
fi

# STEP 5: For backend-only plans, run API integration tests
if [ "$PLAN_HAS_API" = "true" ] && [ "$PLAN_HAS_FRONTEND" = "false" ]; then
    # Start backend
    $CLAUDE_PROJECT_DIR/.claude/scripts/start-backend.sh "$PROJECT" &
    sleep 5

    # Run API tests
    pytest tests/integration/test_${PLAN_ID}.py -v
    API_EXIT_CODE=$?

    if [ $API_EXIT_CODE -ne 0 ]; then
        STATUS="FAILED_API_UAT"
        HALT EXECUTION
    fi
fi
```

---

## What Makes a Valid UAT Test

### WRONG: Page load test only

```typescript
test('feature works', async ({ page }) => {
  await page.goto('/recording');
  await expect(page).toHaveURL('/recording');  // ❌ Only tests route exists
});
```

### CORRECT: Functional test

```typescript
test('audio recording captures audio', async ({ page }) => {
  await page.goto('/recording');

  // Start recording
  await page.getByRole('button', { name: 'Record' }).click();

  // Verify recording indicator active
  await expect(page.getByTestId('recording-indicator')).toBeVisible();
  await expect(page.getByTestId('recording-indicator')).toHaveClass(/recording/);

  // Wait for some recording time
  await page.waitForTimeout(2000);

  // Stop recording
  await page.getByRole('button', { name: 'Stop' }).click();

  // Verify recording was created
  await expect(page.getByTestId('recording-preview')).toBeVisible();

  // Verify audio blob exists (actual functionality)
  const audioElement = page.getByTestId('audio-preview');
  await expect(audioElement).toHaveAttribute('src', /.+/);  // Has audio data
});
```

---

## Database Migration Verification

For plans with database changes:

```bash
# STEP 6: Verify migrations work on production-like data

if [ "$PLAN_HAS_MIGRATION" = "true" ]; then
    # Create test database with snapshot
    sqlite3 :memory: ".read $MIGRATION_FILE"
    MIGRATION_EXIT_CODE=$?

    if [ $MIGRATION_EXIT_CODE -ne 0 ]; then
        STATUS="FAILED_MIGRATION"
        HALT EXECUTION
    fi

    # Verify idempotency (run twice)
    sqlite3 :memory: ".read $MIGRATION_FILE"
    sqlite3 :memory: ".read $MIGRATION_FILE"  # Second run
    IDEMPOTENT_EXIT_CODE=$?

    if [ $IDEMPOTENT_EXIT_CODE -ne 0 ]; then
        STATUS="FAILED_MIGRATION_IDEMPOTENCY"
        HALT EXECUTION
    fi

    # For production verification (optional, high-risk plans only)
    if [ "$RISK_SCORE" -ge 6 ]; then
        ssh deploy@jfritz.xyz "sqlite3 /var/lib/stellaris/data/stellaris.db '.schema'" > production_schema.sql
        # Diff against expected
    fi
fi
```

---

## Feature Detection from Plan

The qa-engineer agent MUST extract testable features:

```python
# Example extraction from plan file

PLAN_FEATURE_PATTERNS = {
    "audio_recording": ["audio", "record", "microphone", "voice"],
    "form_submission": ["form", "submit", "save", "create"],
    "navigation": ["route", "page", "navigate", "link"],
    "data_display": ["list", "table", "display", "show"],
    "authentication": ["login", "logout", "auth", "session"],
    "file_upload": ["upload", "file", "attachment"],
    "search": ["search", "filter", "find"],
    "export": ["export", "download", "docx", "pdf"],
}

# Generate test based on detected features
for feature, keywords in PLAN_FEATURE_PATTERNS.items():
    if any(kw in plan_content.lower() for kw in keywords):
        generate_feature_test(feature, plan_content)
```

---

## Enforcement via SubagentStop Hook

Add to `.claude/settings.json`:

```json
{
  "matcher": "tpm-orchestrator",
  "hooks": [
    {
      "type": "command",
      "command": "$CLAUDE_PROJECT_DIR/.claude/scripts/verify-uat-executed.sh"
    }
  ]
}
```

**verify-uat-executed.sh:**

```bash
#!/bin/bash
# Verify UAT was actually executed, not just checklist created

PLAN_ID=$(cat /tmp/current-plan-id 2>/dev/null || echo "unknown")

# Check for Playwright execution evidence
if [ ! -f "inbox/uat-evidence/${PLAN_ID}/playwright-report.json" ]; then
    echo "❌ BLOCKING: No Playwright execution evidence found"
    echo "UAT gate requires actual test execution, not just checklist"
    exit 1
fi

# Check execution was successful
FAILURES=$(jq '.stats.failures' "inbox/uat-evidence/${PLAN_ID}/playwright-report.json" 2>/dev/null)

if [ "$FAILURES" != "0" ] && [ "$FAILURES" != "null" ]; then
    echo "❌ BLOCKING: UAT had $FAILURES failures"
    exit 1
fi

echo "✅ UAT execution verified: Playwright tests passed"
```

---

## Summary

**Before (broken):**
1. Check if checklist file exists
2. Check if file contains "✅ PASS"
3. Proceed

**After (enforced):**
1. Generate Playwright test from plan features
2. Start local stack
3. Execute `npx playwright test`
4. Parse JSON results
5. Block if ANY test fails
6. Store execution evidence
7. Verify evidence exists before marking SHIPPED

**No file check = no pass. Actual execution required.**
