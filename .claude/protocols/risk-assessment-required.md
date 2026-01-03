# MANDATORY RISK ASSESSMENT PROTOCOL

## ⚠️ CRITICAL REQUIREMENT

**NO DEVELOPMENT PLAN SHALL EXECUTE WITHOUT RISK ASSESSMENT**

This is a **MANDATORY** safety gate enforced by hooks. You CANNOT skip this step.

---

## When This Protocol Applies

This protocol is triggered when:
- Portfolio Manager is analyzing new plans
- TPM Orchestrator is about to execute a plan
- Any agent is working with development plans in `00 Inbox/plans/`

---

## Required Action: Invoke Risk Manager

Before proceeding with plan analysis or execution, you MUST:

### 1. Check for Existing Risk Assessment

Read the plan file and check if it has a `## Risk Assessment` section.

```bash
# Check if risk assessment exists
grep -q "## Risk Assessment" "00 Inbox/plans/PLAN-XXXX.md"

# If not found, risk assessment is missing
```

### 2. If Missing: Invoke Risk Manager IMMEDIATELY

```bash
# Use Task tool to invoke Risk Manager
Task(
  subagent_type='risk-manager',
  description='Assess risk for PLAN-XXXX',
  prompt='Perform comprehensive risk assessment for plan file: 00 Inbox/plans/PLAN-XXXX.md

Assess all four risk dimensions:
- User Disruption Risk
- Controllability Risk
- Liability & Compliance Risk
- AI-Specific Risk

Provide risk score, mitigation recommendations, and approval decision.
Append full risk assessment to the plan file.',
  model='sonnet'
)
```

### 3. Wait for Risk Assessment Completion

DO NOT PROCEED until Risk Manager completes the assessment and appends it to the plan file.

### 4. Read Risk Assessment Results

After Risk Manager completes:

```bash
# Re-read the plan file
Read: 00 Inbox/plans/PLAN-XXXX.md

# Extract risk assessment section
# Look for:
# - Overall Risk Score
# - Approval Decision (APPROVED or REQUIRES APPROVAL)
```

### 5. Act Based on Risk Decision

**If APPROVED (risk < 7/10):**
- Proceed with normal workflow (Portfolio Manager schedules, TPM executes)
- Include risk score in dashboard
- Apply recommended mitigations

**If REQUIRES APPROVAL (risk ≥ 7/10):**
- STOP auto-execution
- Escalate to Johannes with risk assessment summary
- Wait for manual approval before proceeding
- DO NOT execute the plan autonomously

---

## Enforcement

This protocol is enforced via hooks:

**Hook 1: SubagentStart (portfolio-manager)**
- Triggers when Portfolio Manager starts
- Injects this protocol as a reminder
- Portfolio Manager MUST invoke Risk Manager for each plan

**Hook 2: SubagentStart (tpm-orchestrator)**
- Triggers when TPM Orchestrator starts
- Verifies risk assessment exists in plan file
- BLOCKS execution if risk assessment missing
- ESCALATES if risk assessment shows REQUIRES APPROVAL

---

## Why This Cannot Be Optional

**Safety reasons:**
1. **User Protection** - Prevents breaking changes without assessment
2. **Controllability** - Ensures Johannes has veto power over high-risk changes
3. **Compliance** - GDPR, WCAG, COPPA violations could create legal liability
4. **AI Safety** - Prevents deployment of biased or harmful AI features
5. **Audit Trail** - Every plan has documented risk assessment for compliance

**Without Risk Manager:**
- Portfolio Manager could auto-execute dangerous changes
- No visibility into compliance violations
- No opportunity to prevent harm
- No audit trail for regulatory review

---

## Consequences of Skipping

If you attempt to skip Risk Manager invocation:

1. **Hooks will remind you** - This protocol will appear again
2. **TPM Orchestrator will block** - Execution fails without risk assessment
3. **Audit trail violation** - Plan cannot be completed without risk docs
4. **User notification** - Johannes will be notified of protocol violation

**DO NOT SKIP RISK ASSESSMENT**

---

## Example: Correct Workflow

### Portfolio Manager Workflow

```markdown
1. User adds plan via /add-plan
2. Portfolio Manager receives plan
3. **BEFORE ANALYSIS:** Check for risk assessment
4. **IF MISSING:** Invoke Risk Manager (Task tool)
5. **WAIT:** Risk Manager completes assessment
6. **READ:** Risk assessment results
7. **IF APPROVED:** Add to queue, proceed with scheduling
8. **IF REQUIRES APPROVAL:** Escalate to Johannes, wait for manual approval
9. Continue with dependency analysis, conflict detection, etc.
```

### TPM Orchestrator Workflow

```markdown
1. Portfolio Manager assigns plan to TPM Orchestrator
2. TPM Orchestrator starts
3. **BEFORE EXECUTION:** Verify risk assessment exists in plan file
4. **READ:** Risk assessment results
5. **IF APPROVED:** Proceed with workstream execution
6. **IF REQUIRES APPROVAL:** Check if Johannes approved
   - If approved: Proceed
   - If not approved: BLOCK execution, escalate
7. Continue with normal execution workflow
```

---

## Escalation Process for High-Risk Plans (≥7/10)

This section documents the complete escalation workflow when risk assessment returns a score of 7 or higher.

### Step 1: Mark for Approval

When Risk Manager determines overall risk ≥ 7/10, it MUST:

1. Set plan status to `AWAITING_APPROVAL` in `00 Inbox/plans/.state.json`
2. Update plan file header with escalation metadata

```bash
# Risk Manager updates .state.json
{
  "PLAN-XXXX": {
    "status": "AWAITING_APPROVAL",
    "risk_score": X,
    "escalation_timestamp": "2025-01-XX..."
  }
}
```

### Step 2: Notify Johannes

The plan file header is updated with:

```markdown
---
**Status:** AWAITING_APPROVAL
**Risk Score:** [X]/10
**Escalation Reason:** [dimension(s) that triggered escalation]
**Approval Required By:** @johannes
**Escalated At:** [ISO timestamp]
---
```

Portfolio Manager MUST NOT schedule this plan until approval is received.

### Step 3: Approval Mechanism

**How Johannes approves:**

1. Johannes reviews the plan file and risk assessment section
2. Johannes adds an approval comment directly in the plan file:

```markdown
## Manual Approval

**Decision:** APPROVED | CHANGES_REQUESTED | REJECTED

**Approved by:** Johannes Fritz
**Approved at:** 2025-01-XX HH:MM UTC
**Approval notes:** [any constraints, conditions, or required modifications]
```

**If CHANGES_REQUESTED:**
- Plan must be modified according to feedback
- Risk Manager re-assesses after changes
- Process repeats until APPROVED or REJECTED

### Step 4: Execution After Approval

Once approved:

1. Portfolio Manager detects `## Manual Approval` section with `APPROVED` decision
2. Portfolio Manager updates `.state.json` status from `AWAITING_APPROVAL` to `QUEUED`
3. Normal execution proceeds with the noted conditions/constraints
4. TPM Orchestrator must honor any approval conditions

---

## How to Check for Johannes Approval

If a plan shows `REQUIRES APPROVAL`, check for approval:

```markdown
# Look for approval marker in plan file
grep -q "## Manual Approval" "00 Inbox/plans/PLAN-XXXX.md"

# If found, check for:
# **Decision:** APPROVED
# **Approved by:** Johannes Fritz
# **Approved at:** [timestamp]
# **Approval notes:** [any constraints or conditions]
```

If no approval marker found, DO NOT EXECUTE.

---

## Summary

**MANDATORY STEPS:**
1. ✅ Check for risk assessment in plan file
2. ✅ If missing, invoke Risk Manager immediately
3. ✅ Wait for completion
4. ✅ Read risk assessment results
5. ✅ If high risk, escalate to Johannes
6. ✅ If approved (by risk score OR manual approval), proceed
7. ✅ If not approved, BLOCK execution

**FORBIDDEN:**
- ❌ Skipping Risk Manager invocation
- ❌ Proceeding without risk assessment
- ❌ Auto-executing high-risk plans
- ❌ Ignoring "REQUIRES APPROVAL" decisions

---

**This protocol is non-negotiable. Risk assessment is mandatory for every plan.**
