# Rollback Command

Rollback a shipped plan by reverting its merge commit.

**Usage:** `/rollback PLAN-2025-NNN [--push]`

**Arguments:**
- `PLAN-2025-NNN` - The plan ID to rollback
- `--push` - Push the revert commit (optional, manual push by default)

## Purpose

Quickly revert a shipped plan that caused issues in production:
- Finds the merge commit from state
- Creates a revert commit
- Runs tests on reverted state
- Optionally pushes the revert

## Workflow

When the user invokes `/rollback PLAN-2025-XXX`:

### Step 1: Find Merge Information

```bash
# Read from state file
STATE=$(cat {project}/00 Inbox/system_state.json)

# Extract merge info for this plan
MERGE_COMMIT=$(echo "$STATE" | jq -r ".completed_plans[\"PLAN-2025-XXX\"].merge_commit")
PR_URL=$(echo "$STATE" | jq -r ".completed_plans[\"PLAN-2025-XXX\"].pr_url")

if [ -z "$MERGE_COMMIT" ] || [ "$MERGE_COMMIT" == "null" ]; then
    echo "Error: No merge commit found for PLAN-2025-XXX"
    echo "This plan may not have been shipped yet."
    exit 1
fi
```

### Step 2: Create Revert Commit

```bash
# Ensure we're on main/master
git checkout main
git pull origin main

# Create revert commit
git revert $MERGE_COMMIT --no-edit

# Or with custom message
git revert $MERGE_COMMIT -m "Rollback: PLAN-2025-XXX

Reverting changes from PR: $PR_URL
Reason: [User should provide reason]

Original merge: $MERGE_COMMIT"
```

### Step 3: Verify Revert

```bash
# Run tests on reverted state
pytest tests/ -v

# Check for issues
if [ $? -ne 0 ]; then
    echo "⚠️ Tests failed after revert!"
    echo "The revert may have introduced issues."
    echo "Review the changes before pushing."
fi
```

### Step 4: Push (If --push Flag)

```bash
if [ "$PUSH_FLAG" == "true" ]; then
    git push origin main
    echo "✅ Rollback pushed to main"
else
    echo "Rollback commit created locally."
    echo "Review and push when ready: git push origin main"
fi
```

### Step 5: Update State

```bash
# Mark plan as rolled back in state
jq '.completed_plans["PLAN-2025-XXX"].rolled_back = true' \
   '.completed_plans["PLAN-2025-XXX"].rollback_commit = "<new-commit>"' \
   '.completed_plans["PLAN-2025-XXX"].rollback_timestamp = "<now>"' \
   {project}/00 Inbox/system_state.json > tmp.json && mv tmp.json {project}/00 Inbox/system_state.json
```

## Output

```
Rollback: PLAN-2025-XXX

Found merge commit: abc123def456
PR: https://github.com/user/repo/pull/42

Creating revert commit...
✅ Revert commit created: fed654cba321

Running tests on reverted state...
✅ All tests pass (45 passed, 0 failed)

[If --push]
Pushing to main...
✅ Rollback pushed

[If no --push]
Rollback commit ready. Push when reviewed:
  git push origin main

State updated:
- Plan PLAN-2025-XXX marked as rolled back
- Rollback commit: fed654cba321
```

## Error Handling

**Plan not found:**
```
Error: PLAN-2025-XXX not found in state.
Check the plan ID and try again.
```

**Plan not shipped:**
```
Error: PLAN-2025-XXX has not been shipped yet.
Current status: EXECUTING
Cannot rollback a plan that hasn't been merged.
```

**Revert conflicts:**
```
Error: Revert has conflicts with current main.

This can happen if:
1. Other changes were made on top of this plan
2. The plan modified files that were later changed

Manual resolution required:
  git revert $MERGE_COMMIT
  # Resolve conflicts
  git add .
  git revert --continue
```

**Tests fail after revert:**
```
⚠️ Tests failed after revert!

This may indicate:
1. Dependencies between this plan and later changes
2. Database migration issues
3. Incomplete revert

Please review before pushing.
```

## Safety Notes

- Rollback creates a revert commit (doesn't rewrite history)
- Original commits are preserved for audit
- Database migrations may need manual rollback
- Consider feature flags for safer deployments
