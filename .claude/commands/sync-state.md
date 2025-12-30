# Sync State Command

Reconcile portfolio state files from ground truth sources (git branches, completed/ folder, merged PRs).

**Use this command when:** State files appear out of sync, after manual interventions, or to verify portfolio state accuracy.

---

## Execution Steps

### 1. Scan Ground Truth Sources

```bash
# List all feature branches (indicates EXECUTING plans)
git branch -a | grep "feature/"

# List completed plans (indicates SHIPPED plans)
ls -la "00 Inbox/plans/completed/"

# Check recent merged PRs
gh pr list --state merged --limit 20 --json number,title,headRefName,mergedAt
```

### 2. Cross-Reference with .state.json

For each plan in `00 Inbox/plans/.state.json`:

| Current Status | Ground Truth Finding | Correct Status |
|----------------|---------------------|----------------|
| QUEUED | Branch exists | EXECUTING |
| QUEUED | Plan in completed/ | SHIPPED |
| EXECUTING | No branch exists | QUEUED (desync!) |
| EXECUTING | Plan in completed/ | SHIPPED |
| READY | Branch exists | EXECUTING |
| Any | Merged PR exists | SHIPPED |

### 3. Rebuild PORTFOLIO_STATUS.md

After correcting `.state.json`:
- Regenerate executive summary counts
- Update "Currently Executing" section
- Update "Queue" section
- Update "Recently Shipped" section
- Update dependency graph
- Set "Last Updated" timestamp

### 4. Log Reconciliation Event

Append to `00 Inbox/audit_log.jsonl`:

```json
{
  "timestamp": "ISO-8601-timestamp",
  "event": "STATE_RECONCILIATION",
  "plan_id": "ALL",
  "source": "manual",
  "details": {
    "reason": "Description of why reconciliation was needed",
    "corrected": ["list of corrected plans"],
    "discrepancies": ["list of discrepancies found"]
  }
}
```

### 5. Report Summary

Output a summary showing:
- Total plans checked
- Discrepancies found and corrections made
- Any anomalies requiring investigation
- Confirmation that all state files are now in sync

---

## Quick Reconciliation Checklist

- [ ] Run `python3 .claude/scripts/derive-state-from-audit.py` to see audit-derived state
- [ ] Compare derived state with `.state.json`
- [ ] Check git branches match EXECUTING plans
- [ ] Check completed/ folder matches SHIPPED plans
- [ ] Update any mismatched statuses
- [ ] Regenerate PORTFOLIO_STATUS.md
- [ ] Append STATE_RECONCILIATION event to audit log
- [ ] Commit all state file changes together

---

## Example Usage

```
User: /sync-state
Assistant: I'll reconcile the portfolio state files from ground truth...

[Scans git branches, completed/ folder, merged PRs]
[Compares with .state.json]
[Reports discrepancies]
[Updates state files]
[Commits changes]
```

---

## Related Commands

- `/portfolio` - View current portfolio status
- `/plan-status <plan-id>` - View detailed status for a specific plan
- `/audit` - View audit log entries
