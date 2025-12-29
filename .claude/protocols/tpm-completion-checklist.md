# TPM Orchestrator Completion Checklist

**MANDATORY: Complete ALL items before returning from plan execution.**

This checklist is injected via `SubagentStop` hook to ensure deterministic portfolio state updates.

---

## Completion Checklist

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

### 4. Verification

Before returning, verify:
- [ ] `.state.json` has correct status
- [ ] Plan file is in `completed/` folder (if shipped)
- [ ] `PORTFOLIO_STATUS.md` reflects current state
- [ ] No stale entries remain

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
