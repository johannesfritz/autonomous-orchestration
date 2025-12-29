# Production Readiness Protocol

**This checklist was triggered because you requested a production-ready review.**

## MANDATORY: Run These Tests FIRST

Before reviewing ANY code, execute these commands and report results:

### Backend Tests
```bash
cd hotel-de-ville/backend && source .venv/bin/activate && pytest -v
```

### Frontend Build + Tests
```bash
cd hotel-de-ville/frontend && npm run build && npx playwright test
```

## Required Verification Steps

Only proceed with review AFTER tests pass. If tests fail, fix them first.

### 1. Backend Checklist
- [ ] pytest: ALL tests pass (report count)
- [ ] No import errors or syntax issues
- [ ] API endpoints return correct status codes
- [ ] Error responses don't expose internals

### 2. Frontend Checklist
- [ ] `npm run build` succeeds
- [ ] Playwright E2E tests pass (report count)
- [ ] No TypeScript errors
- [ ] No console errors in normal operation

### 3. Integration Checklist
- [ ] Frontend connects to backend
- [ ] Data persists correctly
- [ ] Page refresh doesn't break state

### 4. Security Checklist
- [ ] No hardcoded secrets
- [ ] Parameterized SQL queries
- [ ] Input validation present
- [ ] Error messages sanitized

### 5. Documentation Checklist
- [ ] CLAUDE.md updated if needed
- [ ] No stale TODO comments
- [ ] No debug print/console.log

### 6. UAT: Construct & Execute User Journeys

**Step 1: Identify What Was Built**

Before testing, list the features added/modified:
```
Features in this development cycle:
1. [Feature A]: [brief description]
2. [Feature B]: [brief description]
...
```

**Step 2: Construct User Journeys**

For EACH feature, document the user journey:
```
## User Journey: [Feature Name]

**Goal:** What is the user trying to accomplish?

**Steps:**
1. User starts at: [page/state]
2. User action: [click/type/etc]
   → Expected: [what should happen]
3. User action: [next step]
   → Expected: [result]
...

**Test Result:** ✅ Pass / ❌ Fail
**Evidence:** [screenshot description or test output]
```

**Step 3: Execute Journeys**

Run through each journey:
- [ ] Start from clean state (refresh, clear data if needed)
- [ ] Follow steps exactly as user would
- [ ] Verify each expected result
- [ ] Record actual vs expected

**Step 4: Edge Case Testing**

For EACH feature test:
- [ ] Empty state (no data)
- [ ] Single item
- [ ] Many items (10+)
- [ ] Long text (500+ chars)
- [ ] Special characters (!@#$%^&*)
- [ ] Rapid actions (double-click, spam)
- [ ] Browser refresh mid-flow
- [ ] Back button

**Step 5: Error Scenarios**

Force and verify graceful handling:
- [ ] Network disconnect
- [ ] Invalid input
- [ ] API error responses
- [ ] Unauthorized access

## Output Format

Report your findings as:
```
## Production Readiness Report

**Backend Tests:** ✅ X passed / ❌ Y failed
**Frontend Build:** ✅ Success / ❌ Failed
**Playwright Tests:** ✅ X passed / ❌ Y failed

### Issues Found
1. [CRITICAL] ...
2. [IMPORTANT] ...

### Fixes Applied
1. ...

### Remaining Items
- [ ] ...
```

## IMPORTANT

Do NOT declare "production ready" until:
1. All tests pass (0 failures)
2. All critical issues fixed
3. All checklist items verified

---

## 7. End-Development Cleanup

**After all tests pass and code is production-ready:**

### Archive the Development Plan

If there was a development plan for this work (in `00 Inbox/` or elsewhere), archive it:

1. **Create archive file:** `docs/development-plans/YYYY-MM-feature-name.md`

2. **Add required header:**
```markdown
# [Feature Name] - Development Plan

**Status:** ✅ Completed
**Development Period:** [Start Date] - [End Date]
**Developer(s):** Claude Code
**Related PR(s):** #[number]

## Objective
[What this development aimed to achieve]

## Outcome
[What was actually delivered]

## User Journeys Verified
- [Journey 1]: ✅ Pass
- [Journey 2]: ✅ Pass

---
[Original plan content below]
```

3. **Copy original plan content** below the header

4. **Delete original** from `00 Inbox/` (if applicable)

### Cleanup Checklist
- [ ] Development plan archived to `docs/development-plans/`
- [ ] Original plan removed from inbox/working location
- [ ] All temporary test files removed
- [ ] No orphaned branches (delete merged feature branches)
- [ ] PR merged and closed

### Final Summary

Add to your Production Readiness Report:
```
### Development Archive
- **Plan archived to:** docs/development-plans/YYYY-MM-feature-name.md
- **Original location:** [where it was]
- **Branches cleaned:** [list any deleted branches]
```
