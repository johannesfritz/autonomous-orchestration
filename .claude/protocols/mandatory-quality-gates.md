# Mandatory Quality Gates Protocol

**Purpose:** Enforce deterministic quality gates that BLOCK execution when violated.

**Scope:** This protocol applies to ALL development plans executed by TPM Orchestrator.

---

## CRITICAL: These Gates Are BLOCKING, Not Optional

Quality gates are **MANDATORY checkpoints** that prevent broken code from reaching production. Unlike informational hooks, these gates **HALT execution** when criteria are not met.

---

## Gate 1: Tests (BLOCKING)

**Requirement:** All automated tests MUST pass before proceeding.

### Execution Criteria

```bash
# Backend tests
cd hotel-de-ville/backend && pytest -v
EXIT_CODE=$?

# Frontend tests
cd hotel-de-ville/frontend && npm run build
BUILD_EXIT=$?

# E2E tests (if frontend modified)
cd hotel-de-ville/frontend && npx playwright test
E2E_EXIT=$?

# Stellaris tests (if Stellaris modified)
cd stellaris/frontend && npx playwright test
STELLARIS_EXIT=$?
```

### Exit Criteria

- pytest exit code = 0
- npm build exit code = 0
- Playwright exit code = 0 (if applicable)

### On Failure

**DO NOT:**
- ❌ Escalate to user with "tests failed, please fix"
- ❌ Proceed to code review gate
- ❌ Create PR
- ❌ Mark plan as complete

**DO:**
- ✅ Analyze test output
- ✅ Attempt automated fix (max 2 attempts)
- ✅ If fix fails, mark plan status: `FAILED_QUALITY_GATE_TESTS`
- ✅ Write failure report to `00 Inbox/failed-plans/{PLAN_ID}-test-failure.md`
- ✅ Update plan file with failure details
- ✅ Escalate with actionable error report

### No Bypass

This gate **cannot be skipped** for any reason. Plans with failing tests cannot proceed.

---

## Gate 2: Code Review (BLOCKING)

**Requirement:** shadow-code-reviewer agent MUST approve all code changes.

### Execution Criteria

```bash
# Invoke shadow-code-reviewer via Task tool
Task(subagent_type="shadow-code-reviewer", prompt='''
  Review all modified files for plan {PLAN_ID}

  Modified files:
  {list files from git diff}

  Return structured JSON verdict with:
  - verdict: "APPROVE" | "REQUEST_CHANGES" | "BLOCK"
  - issues: [{severity, file, line, description}]
  - blocking_issues: [list]

  Apply strict-code-standards.md for major changes.
''')
```

### Exit Criteria

- Verdict = "APPROVE"

### On REQUEST_CHANGES

- Apply suggested fixes
- Re-run tests
- Re-invoke shadow-code-reviewer (max 1 iteration)
- If still REQUEST_CHANGES after fixes → mark as `FAILED_QUALITY_GATE_REVIEW`

### On BLOCK

- Mark plan status: `FAILED_QUALITY_GATE_REVIEW`
- Write detailed report: `00 Inbox/failed-plans/{PLAN_ID}-review-block.md`
- Escalate with blocking issues list
- **DO NOT** proceed to security gate

### No Bypass

Code review approval is **MANDATORY**. Plans without "APPROVE" verdict cannot ship.

---

## Gate 3: Security Audit (BLOCKING for Critical Issues)

**Requirement:** No CRITICAL severity security vulnerabilities.

### Execution Criteria

```bash
# Run security-audit skill
Skill(skill="security-audit")

# OR run Bandit directly
cd project/backend && bandit -r . -ll --format json > /tmp/security-audit.json
```

### Exit Criteria

- Zero CRITICAL severity issues
- Zero HIGH severity issues in auth/payment/data-loss code

### On Critical Issues Found

- Mark plan status: `FAILED_QUALITY_GATE_SECURITY`
- Write security report: `00 Inbox/failed-plans/{PLAN_ID}-security.md`
- **DO NOT** create PR
- **DO NOT** proceed to UAT gate
- Escalate immediately with vulnerability details

### Medium/Low Issues

- Log warnings
- Include in PR description
- Allow plan to proceed (but flag for follow-up)

---

## Gate 4: UAT (BLOCKING)

**Requirement:** User journeys MUST be tested and documented.

### Execution Criteria

1. **Generate UAT checklist:**
   - File: `00 Inbox/uat-checklists/{PLAN_ID}-uat.md`
   - Template from `.claude/protocols/mandatory-uat-protocol.md`

2. **Execute user journeys:**
   - Manual verification OR Playwright E2E tests
   - Record pass/fail for each journey
   - Test edge cases (empty state, many items, special chars)
   - Test error scenarios (network fail, invalid input)

3. **Document results:**
   - Mark all checklist items
   - Add tester name + timestamp
   - Overall result: PASS / FAIL

### Exit Criteria

- UAT checklist file exists
- All critical user journeys marked PASS
- All edge cases tested
- UAT completion section filled
- Overall result = PASS

### On UAT Failure

- Mark plan status: `AWAITING_UAT` (not SHIPPED)
- Write UAT failure details to checklist
- Escalate with failed journey descriptions
- **DO NOT** mark plan as SHIPPED
- **DO NOT** auto-merge PR

### No Bypass

Plans cannot be marked SHIPPED without completed UAT checklist showing PASS.

---

## Gate 5: CI/CD (BLOCKING)

**Requirement:** GitHub Actions workflows MUST pass before marking SHIPPED.

### Execution Criteria

```bash
# After git push, wait for CI to complete
.claude/scripts/wait-for-ci.sh --wait --timeout 600

# Exit code 0 = CI passed
# Exit code 1 = CI failed
```

### Exit Criteria

- All GitHub Actions workflows return conclusion: "success"
- Zero failed workflows
- Zero cancelled workflows

### On CI Failure

- Mark plan status: `FAILED_CI` (not SHIPPED)
- Write CI failure log: `00 Inbox/failed-plans/{PLAN_ID}-ci-failure.md`
- Include failed workflow names
- Include error messages from GitHub Actions
- **DO NOT** auto-merge PR
- **DO NOT** mark plan as SHIPPED
- Escalate with CI failure details

### Timeout Handling

If CI doesn't complete within timeout (default 600s):
- Log timeout event
- Keep plan status as `AWAITING_CI`
- Escalate: "CI taking longer than expected, manual verification required"
- **DO NOT** assume success

---

## Enforcement Mechanisms

### 1. TPM Orchestrator Protocol Injection

When TPM Orchestrator starts, this protocol is injected via SubagentStart hook:

```json
{
  "matcher": "tpm-orchestrator",
  "hooks": [{
    "type": "command",
    "command": "cat $CLAUDE_PROJECT_DIR/.claude/protocols/mandatory-quality-gates.md"
  }]
}
```

### 2. Pre-Push Blocking Hook

Before `git push`, tests are run and BLOCK push if they fail:

```bash
# .claude/hooks/block-on-test-failure.sh
# Returns exit code 1 if tests fail → git push aborted
```

### 3. State Tracking

Plan states track quality gate status:

- `EXECUTING` → All gates pending
- `FAILED_QUALITY_GATE_TESTS` → Tests failed
- `FAILED_QUALITY_GATE_REVIEW` → Review blocked/rejected
- `FAILED_QUALITY_GATE_SECURITY` → Critical vulnerabilities found
- `AWAITING_UAT` → UAT not complete or failed
- `FAILED_CI` → GitHub Actions failed
- `SHIPPED` → All gates passed

### 4. No "Escalate and Continue"

Old pattern (FORBIDDEN):
```
❌ Tests failed → Escalate to user → Continue to next gate
```

New pattern (REQUIRED):
```
✅ Tests failed → Mark plan FAILED → Write failure report → HALT execution → Escalate
```

---

## Verification Checklist (For TPM Orchestrator)

Before marking ANY plan as SHIPPED, verify:

- [ ] Gate 1 (Tests): pytest exit 0, builds succeed, E2E pass
- [ ] Gate 2 (Review): shadow-code-reviewer verdict = "APPROVE"
- [ ] Gate 3 (Security): Zero critical vulnerabilities
- [ ] Gate 4 (UAT): Checklist complete, all journeys PASS
- [ ] Gate 5 (CI/CD): wait-for-ci.sh exit 0, all workflows green

If ANY gate fails, plan status ≠ SHIPPED.

---

## Escalation Format

When escalating failed gates to user:

```markdown
## Quality Gate Failure: {PLAN_ID}

**Gate:** {Tests | Review | Security | UAT | CI}
**Status:** FAILED
**Plan Status:** {FAILED_QUALITY_GATE_*}

### Details
{Specific error messages, failed test names, blocking issues, etc.}

### Options
1. Fix the issues manually and re-run: /execute-plan {PLAN_ID}
2. Abandon plan: /abandon-plan {PLAN_ID}
3. Review failure details: cat 00 Inbox/failed-plans/{PLAN_ID}-*.md

### Next Steps
The plan has been halted and will not proceed until these issues are resolved.
```

---

## Philosophy

> "Quality gates are not suggestions. They are requirements."

- **Deterministic:** Same input → Same output (no randomness in enforcement)
- **Automated:** No manual judgment calls (objective criteria only)
- **Blocking:** Violations halt execution (no "warning and continue")
- **Transparent:** Clear failure reasons (actionable error messages)

Violations of this protocol indicate a system failure, not a plan failure.
