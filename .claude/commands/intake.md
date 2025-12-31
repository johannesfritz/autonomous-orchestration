Process user feedback from the Stellaris production database.

## What This Command Does

This command fetches user feedback from the Stellaris production database via SSH, categorizes it into actionable items, and writes structured intake records for Product Manager review.

## Usage

```
/intake
```

**Optional filters:**
```
/intake bug reports only    # Filter to bug_report category
/intake feature requests    # Filter to feature_request category
/intake last 10            # Limit to most recent 10 items
```

## Workflow

1. **Invoke user-feedback-intake skill** to fetch and categorize open feedback from Stellaris database
2. **Search for duplicates** in existing plans and backlog to avoid redundant work
3. **Extract underlying user needs** (not just stated solutions)
4. **Output structured intake records** to `00 Inbox/feedback/intake-YYYY-MM-DD.md`
5. **Summarize findings** with high-priority items, patterns detected, and recommended next steps

## Output

After running `/intake`, you will receive:

- **Summary:** Total items processed, high-priority count, patterns detected
- **Intake file:** Structured markdown file at `00 Inbox/feedback/intake-YYYY-MM-DD.md`
- **Next steps:** Recommendations for Product Manager (prioritize, escalate, defer)

## Example

```
User: /intake