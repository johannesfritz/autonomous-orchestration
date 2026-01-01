# TPM Orchestrator Completion Checklist

**MANDATORY: Complete ALL items before returning from plan execution.**

This checklist is injected via `SubagentStop` hook to ensure deterministic portfolio state updates.

---

## MANDATORY Ground Truth Verification

**CRITICAL:** Before updating ANY state files, verify ground truth matches your claims.

### Pre-Execution Verification (BEFORE marking EXECUTING)

Before updating `.state.json` to EXECUTING status:

1. **Branch Verification:**
   ```bash
   git branch -a | grep "feature/[plan-branch-name]"
   ```
   - MUST find the branch before proceeding
   - If branch doesn't exist, DO NOT mark as EXECUTING

2. **No False Starts:**
   - Never mark a plan as EXECUTING based on intent alone
   - Actual git branch creation is the ground truth
   - If TPM says "starting execution" but no branch → status stays QUEUED

### Completion Verification (BEFORE marking SHIPPED)

**Do NOT report completion until ALL verification steps pass:**

1. **Verify Branch Exists:**
   ```bash
   git branch -a | grep "feature/[plan-branch-name]"
   ```
   If branch doesn't exist, something is wrong. Investigate before proceeding.

2. **Verify PR Status (if claiming SHIPPED):**
   ```bash
   gh pr view [branch-name] --json state,mergedAt
   ```
   - State must be "MERGED" or an open PR must exist
   - If no PR found, status cannot be SHIPPED (create PR first)

3. **Verify State Transition is Valid:**
   - Read last event for this plan in `audit_log.jsonl`
   - Valid transitions: QUEUED → READY → EXECUTING → SHIPPED
   - Do not skip states (e.g., cannot go QUEUED → SHIPPED directly)

4. **Verify CI/GitHub Actions Passed:**

   **IMPORTANT:** CI verification is NON-BLOCKING. After `git push`, you'll see a status message.
   You CAN proceed to the next plan while CI runs. However, you MUST verify CI passed before marking SHIPPED.

   ```bash
   # Quick status check (non-blocking, runs automatically after push)
   $CLAUDE_PROJECT_DIR/.claude/scripts/wait-for-ci.sh

   # Full blocking wait (use when ready to mark SHIPPED)
   $CLAUDE_PROJECT_DIR/.claude/scripts/wait-for-ci.sh --wait --timeout 300

   # Manual check
   gh run list --commit $(git rev-parse HEAD) --json status,conclusion,name
   ```

   **Requirements before marking SHIPPED:**
   - ALL workflows must show `conclusion: "success"`
   - If any workflow failed, DO NOT mark as SHIPPED - fix the issue first
   - Use `gh run watch <run-id>` to monitor a specific run if needed

---

## Atomic State Update Order

**CRITICAL:** Update state files in this exact order to maintain consistency:

1. **audit_log.jsonl** (append event FIRST - this is the source of truth)
2. **.state.json** (update status)
3. **PORTFOLIO_STATUS.md** (update dashboard)
4. **Commit all three together**

If any step fails, do not proceed to the next. Investigate and fix the issue.

---

## Completion Checklist

### 0. Notify Users and Close Tickets (MANDATORY IF APPLICABLE)

**CRITICAL:** If the plan file contains a "User Requests" section with feedback IDs, you MUST complete this step BEFORE any other completion steps.

**Check for User Requests section:**
```bash
grep -A 5 "## User Requests" "00 Inbox/plans/$PLAN_ID.md"
```

If the section exists AND contains feedback IDs, complete the user notification protocol:

1. **Read the protocol:**
   ```bash
   cat .claude/protocols/user-request-closure.md
   ```

2. **Notify users and close tickets:**
   - Preferred: Use Stellaris Admin MCP tools (`mcp__stellaris-admin__respond_to_feedback`, `mcp__stellaris-admin__update_feedback_status`)
   - Fallback: Use SSH to update production database directly (`ssh village "sqlite3 /var/lib/stellaris/data/stellaris.db ..."`)

3. **Verify closure succeeded:**
   ```bash
   # Via MCP
   mcp__stellaris-admin__get_feedback_details(feedback_id=42)

   # Via SSH
   ssh village "sqlite3 /var/lib/stellaris/data/stellaris.db 'SELECT status FROM feedback WHERE id=42;'"
   ```

4. **Use COPPA-compliant response templates** (see protocol for templates)

**If this step fails, DO NOT proceed to Step 1.** User notification is MANDATORY when applicable.

**If plan has NO "User Requests" section or section is blank, skip to Step 1.**

---

### 1. Update Plan Status in `.state.json`

```bash
# File: 00 Inbox/plans/.state.json
# Update the plan entry:
{
  "PLAN-YYYY-NNN": {
    "status": "SHIPPED",           # or "AWAITING_MERGE_APPROVAL" for high-risk
    "completed_at": "ISO-timestamp",
    "pr_url": "https://github.com/..."
  }
}

# Update arrays:
- Remove from "currently_executing": []
- Add to "shipped": [] (or leave in currently_executing if awaiting merge)

# Update metadata:
- Increment "total_plans_shipped" (if shipped)
- Update "last_updated" timestamp
```

### 2. Move Plan File to `completed/`

```bash
# Only if status is SHIPPED (not AWAITING_MERGE_APPROVAL)
mv "00 Inbox/plans/PLAN-YYYY-NNN.md" "00 Inbox/plans/completed/PLAN-YYYY-NNN.md"

# Update the plan file header with:
- **Status:** SHIPPED
- **Shipped:** ISO timestamp
- **PR:** URL
```

### 3. Update Portfolio Dashboard

```bash
# File: 00 Inbox/PORTFOLIO_STATUS.md
# Update sections:
1. Executive Summary - decrement "Currently Executing", increment "Shipped"
2. Currently Executing - remove this plan
3. Recently Shipped - add this plan with PR link
4. Update "Last Updated" timestamp
```

### 4. Commit Portfolio State Changes

**CRITICAL: Always commit state files after plan completion.**

```bash
git add -A "00 Inbox/plans/" "00 Inbox/PORTFOLIO_STATUS.md" "00 Inbox/system_state.json" "00 Inbox/audit_log.jsonl"
git commit -m "Update portfolio state: PLAN-YYYY-NNN shipped"
git push
```

This ensures:
- State is persisted in Git (source of truth)
- Other sessions see accurate portfolio state
- No orphaned uncommitted state files

### 5. Verification

Before returning, verify:
- [ ] `.state.json` has correct status
- [ ] Plan file is in `completed/` folder (if shipped)
- [ ] `PORTFOLIO_STATUS.md` reflects current state
- [ ] No stale entries remain
- [ ] **All state changes are committed and pushed to Git**
- [ ] **CI/GitHub Actions passed** (all workflows green)

---

## Quick Commands

```python
# Read current state
state = json.load(open("00 Inbox/plans/.state.json"))

# Update plan status
state["plans"][plan_id]["status"] = "SHIPPED"
state["plans"][plan_id]["completed_at"] = datetime.now().isoformat() + "Z"
state["plans"][plan_id]["pr_url"] = pr_url

# Move from executing to shipped
state["currently_executing"].remove(plan_id)
state["shipped"].append(plan_id)

# Update metadata
state["metadata"]["total_plans_shipped"] += 1
state["metadata"]["last_updated"] = datetime.now().isoformat() + "Z"

# Write back
json.dump(state, open("00 Inbox/plans/.state.json", "w"), indent=2)
```

---

**CRITICAL:** Do not return until all checklist items are complete. This ensures the Portfolio Manager has accurate state for future plan executions.
