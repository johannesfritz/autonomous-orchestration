# Mandatory UAT Protocol

**Purpose:** Ensure all features are tested from a user perspective before shipping.

**Scope:** All development plans that modify user-facing functionality.

---

## Why UAT is Mandatory

**Common failure mode:**
- Unit tests pass ✅
- Integration tests pass ✅
- Code review approved ✅
- **User tries the feature → it doesn't work** ❌

**Root cause:** Tests verify implementation, not user experience.

**Solution:** Mandatory user journey testing.

---

## When UAT is Required

UAT is MANDATORY for plans that include:

- New features (user-facing functionality)
- Changes to existing UI workflows
- API endpoint modifications that affect frontend
- Navigation/routing changes
- Form submissions or data entry
- Search/filter functionality
- Authentication/authorization flows

UAT is OPTIONAL for:

- Backend-only refactors (no UI changes)
- Documentation updates
- Infrastructure/deployment changes
- Test code only

---

## UAT Process (BLOCKING)

### Step 1: Generate UAT Checklist (REQUIRED)

**File location:** `00 Inbox/uat-checklists/{PLAN_ID}-uat.md`

**Template:**

```markdown
# UAT Checklist: {PLAN_ID}

**Plan:** {Plan Title}
**Date Generated:** {ISO timestamp}
**Tester:** TPM Orchestrator (or manual: Johannes Fritz)

---

## Features Tested

{List of features added/modified in this plan}

---

## User Journeys

### Journey 1: {Feature Name}

**Goal:** {What is the user trying to accomplish?}

**Steps:**
1. User starts at: {page/state}
   - **Action:** {what user does}
   - **Expected:** {what should happen}
   - **Actual:** {what actually happened}
   - **Result:** ✅ Pass / ❌ Fail

2. User action: {next step}
   - **Action:** {what user does}
   - **Expected:** {what should happen}
   - **Actual:** {what actually happened}
   - **Result:** ✅ Pass / ❌ Fail

3. {Continue for all steps in journey}

**Journey Result:** ✅ PASS / ❌ FAIL
**Evidence:** {Screenshot description, test output, or manual verification notes}

---

### Journey 2: {Another Feature}

{Repeat structure above}

---

## Edge Cases Tested

**Empty State:**
- [ ] Tested with no data → Result: {description}

**Single Item:**
- [ ] Tested with one item → Result: {description}

**Many Items:**
- [ ] Tested with 10+ items → Result: {description}

**Long Text:**
- [ ] Tested with 500+ character input → Result: {description}

**Special Characters:**
- [ ] Tested with !@#$%^&*() → Result: {description}

**Rapid Actions:**
- [ ] Tested double-click, spam click → Result: {description}

**Browser Refresh:**
- [ ] Tested refresh mid-flow → Result: {description}

**Back Button:**
- [ ] Tested browser back button → Result: {description}

---

## Error Scenarios Tested

**Network Disconnect:**
- [ ] Simulated offline mode → Result: {description}

**Invalid Input:**
- [ ] Submitted invalid data → Result: {description}

**API Error:**
- [ ] Forced 500 error response → Result: {description}

**Unauthorized Access:**
- [ ] Accessed without auth → Result: {description}

---

## UAT Completion

**Overall Result:** ✅ PASS / ❌ FAIL

**Summary:**
{1-2 paragraph summary of UAT findings}

**Critical Issues Found:** {number}
- {List any blockers}

**Minor Issues Found:** {number}
- {List non-critical issues}

**Recommendations:**
- {Any follow-up work needed}

**Tester Signature:** {Name}
**Date Completed:** {ISO timestamp}
**Time Spent:** {duration}

---

## Approval

- [ ] All critical user journeys PASS
- [ ] All edge cases tested
- [ ] All error scenarios handled gracefully
- [ ] No critical issues blocking shipment
- [ ] UAT evidence documented

**Status:** APPROVED FOR SHIPMENT / NEEDS FIXES
```

---

### Step 2: Execute User Journeys (REQUIRED)

Two execution methods:

#### Option A: Automated (Playwright E2E)

```typescript
// Example: hotel-de-ville/frontend/tests/uat/{feature}.spec.ts
import { test, expect } from '@playwright/test';

test.describe('UAT: {Feature Name}', () => {
  test('Journey 1: User can {accomplish goal}', async ({ page }) => {
    // Step 1
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

    // Step 2
    await page.getByRole('link', { name: 'Settings' }).click();
    await expect(page).toHaveURL('/settings');

    // Step 3
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('Settings saved')).toBeVisible();
  });

  test('Edge case: Empty state', async ({ page }) => {
    // Clear all data
    // Verify empty state UI shows
  });

  test('Error scenario: API failure', async ({ page }) => {
    // Mock API to return 500
    // Verify error message displays
  });
});
```

Run: `npx playwright test tests/uat/{feature}.spec.ts`

#### Option B: Manual (Human Verification)

- Open application in browser
- Follow each step in UAT checklist exactly
- Record actual results vs expected
- Take screenshots for evidence
- Mark pass/fail for each step

---

### Step 3: Document Results (REQUIRED)

Fill in the UAT checklist:

1. For each journey step, record:
   - What action was taken
   - What actually happened (vs expected)
   - Pass or fail

2. For each edge case, record:
   - What was tested
   - Result description

3. For error scenarios, record:
   - How error was triggered
   - Whether it was handled gracefully

4. Complete the UAT Completion section:
   - Overall result (PASS/FAIL)
   - Summary of findings
   - Any issues found

5. Sign off:
   - Tester name
   - Date completed
   - Approval status

---

### Step 4: Verify Completion (BLOCKING GATE)

**Before marking plan SHIPPED, TPM Orchestrator MUST verify:**

```bash
# Check UAT checklist exists
if [ ! -f "00 Inbox/uat-checklists/${PLAN_ID}-uat.md" ]; then
    echo "❌ UAT checklist not found"
    exit 1
fi

# Check for completion markers
if ! grep -q "Overall Result: ✅ PASS" "00 Inbox/uat-checklists/${PLAN_ID}-uat.md"; then
    echo "❌ UAT not passed"
    exit 1
fi

# Check for signature
if ! grep -q "Tester Signature:" "00 Inbox/uat-checklists/${PLAN_ID}-uat.md"; then
    echo "❌ UAT not signed off"
    exit 1
fi

echo "✅ UAT complete and passed"
```

**If verification fails:**
- Mark plan status: `AWAITING_UAT`
- **DO NOT** mark plan as SHIPPED
- **DO NOT** auto-merge PR
- Escalate to user: "UAT incomplete or failed"

---

## UAT Failure Handling

### If Critical Journey Fails

1. **Document failure:**
   - Record exact steps that failed
   - Record expected vs actual result
   - Add screenshots if available

2. **Determine severity:**
   - **Critical:** Core feature doesn't work → BLOCK shipment
   - **Major:** Feature works but buggy → Fix before ship
   - **Minor:** Edge case issue → Can ship with known issue

3. **Mark plan status:**
   - Critical/Major failures → `FAILED_UAT`
   - Minor failures → `PASSED_WITH_ISSUES`

4. **Escalate:**
   - Provide failure details
   - Suggest fixes
   - Wait for user decision (fix or ship anyway)

### Retry After Fixes

If UAT fails and fixes are applied:

1. Re-run failed journey only (not full UAT)
2. Update UAT checklist with retry results
3. If retry passes → mark overall PASS
4. If retry fails again → escalate for manual intervention

---

## Integration with Quality Gates

UAT is **Gate 4** in the mandatory quality gates sequence:

```
Gate 1: Tests → Gate 2: Code Review → Gate 3: Security → Gate 4: UAT → Gate 5: CI/CD
```

**UAT cannot be skipped.** If a plan doesn't require UAT (backend-only), document why:

```markdown
## UAT Exemption

**Reason:** Backend-only refactor, no UI changes
**Verified by:** {Name}
**Date:** {ISO timestamp}
```

---

## UAT Evidence Storage

All UAT artifacts stored in:

- **Checklists:** `00 Inbox/uat-checklists/{PLAN_ID}-uat.md`
- **Screenshots:** `00 Inbox/uat-evidence/{PLAN_ID}/`
- **Test recordings:** `00 Inbox/uat-evidence/{PLAN_ID}/recordings/`
- **Playwright reports:** `hotel-de-ville/frontend/playwright-report/`

Keep evidence for:
- 30 days after plan shipped
- Permanently for plans marked FAILED_UAT (for debugging)

---

## Example: Complete UAT Checklist

See: `00 Inbox/uat-checklists/PLAN-2025-001-uat.md` (example)

---

## Remember

> "Tests verify the code. UAT verifies the feature."

UAT catches bugs that tests miss:
- User settings ignored
- Filters don't filter
- Data flow broken despite "correct" logic
- UI states missing
- Error messages unclear

**Mandatory UAT prevents these bugs from reaching production.**
