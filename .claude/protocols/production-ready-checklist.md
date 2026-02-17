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

### 6. UAT: Automated Local Testing

**CRITICAL: You MUST spin up the local stack and execute user journeys in a real browser.**

#### Option A: Automated UAT Runner (RECOMMENDED)

```bash
# Start local servers + run automated tests
$CLAUDE_PROJECT_DIR/.claude/scripts/start-local-stack.sh hotel-de-ville
python3 $CLAUDE_PROJECT_DIR/.claude/scripts/run-uat.py --project hotel-de-ville
```

This will:
1. Start backend (port 8000) and frontend (port 5173)
2. Execute navigation tests, responsive checks, theme verification
3. Capture screenshots as evidence
4. Generate UAT report in `inbox/UAT-REPORT-*.md`

#### Option B: Manual UAT with Playwright

```bash
# Start servers
$CLAUDE_PROJECT_DIR/.claude/scripts/start-local-stack.sh hotel-de-ville

# Run existing E2E tests
cd hotel-de-ville/frontend && npx playwright test

# Interactive mode - record your own tests
npx playwright codegen http://localhost:5173

# Visual debugging (see the browser)
npx playwright test --headed
```

#### UAT Verification Checklist

- [ ] Local stack started successfully
- [ ] `run-uat.py` completed with no failures
- [ ] UAT report generated in `inbox/`
- [ ] Screenshots captured as evidence
- [ ] Edge cases tested (empty state, many items, special chars)

#### Manual User Journey Verification

After automated tests pass, manually verify the PRIMARY user flow:

**Step 1: Identify What Was Built**

List features added/modified:
```
Features in this development cycle:
1. [Feature A]: [brief description]
2. [Feature B]: [brief description]
```

**Step 2: Execute User Journeys**

For each feature, walk through in the browser:
```
## User Journey: [Feature Name]

**Goal:** What is the user trying to accomplish?

**Steps:**
1. Navigate to: [URL]
   → Expected: [what should render]
2. Action: [click/type]
   → Expected: [result]

**Test Result:** ✅ Pass / ❌ Fail
**Evidence:** [screenshot path from inbox/uat-screenshots/]
```

**Step 3: Edge Case Testing**

For EACH feature test:
- [ ] Empty state (no data)
- [ ] Single item
- [ ] Many items (10+)
- [ ] Long text (500+ chars)
- [ ] Special characters (!@#$%^&*)
- [ ] Rapid actions (double-click, spam)
- [ ] Browser refresh mid-flow
- [ ] Back button

**Step 4: Error Scenarios**

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

## 7. Post-Deployment Verification (MANDATORY)

**After deploying to production, you MUST verify the deployment succeeded.**

### Deployment Smoke Tests

Run these checks immediately after deployment:

```bash
# 1. Health check - API is responding
curl -s https://jfritz.xyz/protokoll-assistent/api/health
# Expected: HTTP 200 with JSON response

# 2. Status endpoint - Service is operational
curl -s https://jfritz.xyz/protokoll-assistent/api/status
# Expected: JSON with status="ok" or similar

# 3. Service status - systemd shows running
ssh root@jfritz.xyz "systemctl status protokoll-assistent --no-pager"
# Expected: "active (running)"

# 4. Recent logs - No critical errors
ssh root@jfritz.xyz "journalctl -u protokoll-assistent -n 20 --no-pager"
# Expected: No ERROR, CRITICAL, or stack traces
```

### Smoke Test Checklist

- [ ] Health check returns HTTP 200
- [ ] API status endpoint responds correctly
- [ ] systemd service shows "active (running)"
- [ ] No critical errors in recent logs (last 20 lines)
- [ ] Frontend loads without errors (manual check in browser)
- [ ] Primary user flow works (quick sanity check)

### On Smoke Test Failure

If ANY smoke test fails:

1. **Execute rollback immediately:**
   ```bash
   ssh root@jfritz.xyz "cd /var/www/protokoll-assistent && git reset --hard HEAD~1"
   ssh root@jfritz.xyz "systemctl restart protokoll-assistent"
   ```

2. **Verify rollback succeeded:**
   - Re-run health check
   - Confirm service is running
   - Test that previous version works

3. **Log deployment failure:**
   - Write to `inbox/failed-plans/{PLAN_ID}-deployment.md`
   - Include error messages from smoke tests
   - Document rollback status

4. **Update plan status:** `FAILED_DEPLOYMENT`

5. **DO NOT mark plan as SHIPPED**

### Audit Trail Requirement

Every deployment MUST be logged to `inbox/audit_log.jsonl`:

**Successful deployment:**
```json
{
  "timestamp": "2026-01-19T15:30:00Z",
  "event": "deployment",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-xxx",
  "files_deployed": ["backend/src/api/routes.py", "frontend/src/App.tsx"],
  "smoke_test_result": "pass",
  "deployed_by": "Claude Code",
  "deployment_method": "scp + systemctl restart"
}
```

**Failed deployment:**
```json
{
  "timestamp": "2026-01-19T15:35:00Z",
  "event": "deployment_failure",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-xxx",
  "files_deployed": ["backend/src/api/routes.py"],
  "error": "Health check returned 502 Bad Gateway",
  "rollback_status": "success",
  "deployed_by": "Claude Code"
}
```

### Deployment Verification Report

Add to your Production Readiness Report:

```
### Deployment Verification
- **Health Check:** ✅ HTTP 200 / ❌ Failed
- **API Status:** ✅ Responding / ❌ Error
- **Service Status:** ✅ Active / ❌ Failed
- **Log Errors:** ✅ None / ❌ [list errors]
- **Audit Log:** ✅ Entry created at inbox/audit_log.jsonl

**Deployment Result:** ✅ VERIFIED / ❌ FAILED (rolled back)
```

---

## 8. End-Development Cleanup

**After all tests pass and code is production-ready:**

### Archive the Development Plan

If there was a development plan for this work (in `inbox/` or elsewhere), archive it:

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

4. **Delete original** from `inbox/` (if applicable)

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
