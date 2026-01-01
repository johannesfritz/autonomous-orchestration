# User Request Closure Protocol

**MANDATORY: When a plan addresses user feedback, you MUST notify the user and close the ticket.**

---

## When This Applies

This protocol is REQUIRED when a plan includes a "User Requests" section linking to Stellaris feedback IDs.

If the plan has:
```markdown
## User Requests

**Feedback ID:** 42
**User:** Alice (age: 14, parent: alice@example.com)
```

Then you MUST complete this protocol before marking the plan as SHIPPED.

---

## Step-by-Step Closure Process

### 1. Verify MCP Tool Availability

Check if Stellaris Admin MCP server is available:

```bash
# Quick test - try to call the MCP tool
# If it returns data or an error about feedback ID, MCP is available
# If it says "tool not found", MCP is unavailable
```

### 2a. If MCP Available (Preferred Method)

Use the Stellaris Admin MCP tools to respond and close the ticket:

```bash
# 1. Get feedback details to confirm it's the right request
mcp__stellaris-admin__get_feedback_details(feedback_id=42)

# 2. Respond to the user with implementation details
mcp__stellaris-admin__respond_to_feedback(
  feedback_id=42,
  response="Your request has been implemented! [brief description of what was added]"
)

# 3. Mark as addressed
mcp__stellaris-admin__update_feedback_status(
  feedback_id=42,
  status="addressed"
)
```

### 2b. If MCP Unavailable (SSH Fallback)

Use SSH to directly update the production database:

```bash
# Connect to production server
ssh village

# Run SQL update (example - adapt to actual schema)
sqlite3 /var/lib/stellaris/data/stellaris.db <<EOF
UPDATE feedback
SET status = 'addressed',
    admin_response = 'Your request has been implemented! [description]',
    addressed_at = datetime('now')
WHERE id = 42;
EOF

# Verify update
sqlite3 /var/lib/stellaris/data/stellaris.db \
  "SELECT id, status, admin_response FROM feedback WHERE id = 42;"
```

**CRITICAL:** Always verify the update succeeded before proceeding.

---

## Response Templates (COPPA-Compliant)

Use these templates to respond to users. All templates are COPPA-compliant (no personal data collection, parent-friendly).

### Bug Fix Response

```
Good news! The bug you reported has been fixed.

What was fixed:
[1-2 sentence description]

When it will be available:
[e.g., "Live now" or "Will deploy on [date]"]

Thank you for helping us improve Stellaris!

- The Stellaris Team
```

### Feature Request Response

```
Great idea! We've implemented the feature you requested.

What we added:
[1-2 sentence description]

How to use it:
[Brief usage instructions if needed]

Thank you for your suggestion!

- The Stellaris Team
```

### Improvement Response

```
Thanks for the feedback! We've made the improvement you suggested.

What changed:
[1-2 sentence description]

We appreciate you helping make Stellaris better!

- The Stellaris Team
```

---

## Age-Appropriate Responses

**For users under 13 (verified via parent email):**
- Use simple language (5th grade reading level)
- Keep responses short (under 100 words)
- Avoid technical jargon
- Always thank them for the feedback

**For users 13+ (or parent-submitted feedback):**
- Can use slightly more technical language
- Can include more detailed explanations
- Still keep friendly and encouraging tone

---

## Validation Checklist

Before marking the plan as SHIPPED, verify:

- [ ] Feedback ID exists in Stellaris production database
- [ ] User was notified (via MCP or SSH)
- [ ] Feedback status updated to "addressed"
- [ ] Response is COPPA-compliant (no personal data requests)
- [ ] Response is age-appropriate for the user
- [ ] Response includes brief description of what was implemented
- [ ] Response thanks the user for their feedback

---

## Handling Multiple Feedback IDs

If a plan addresses multiple feedback requests:

```markdown
## User Requests

**Feedback IDs:** 42, 43, 44
```

You MUST notify ALL users and close ALL tickets:

```bash
# Loop through all IDs
for feedback_id in 42 43 44; do
  # Notify and close each one
  mcp__stellaris-admin__respond_to_feedback(
    feedback_id=$feedback_id,
    response="[appropriate template]"
  )
  mcp__stellaris-admin__update_feedback_status(
    feedback_id=$feedback_id,
    status="addressed"
  )
done
```

---

## Error Handling

**If MCP tool fails:**
- Fallback to SSH method immediately
- Do not mark plan as SHIPPED until closure succeeds

**If SSH fails:**
- Escalate to Johannes with error details
- Do not proceed with plan shipment
- User notification is MANDATORY, not optional

**If feedback ID doesn't exist:**
- Check for typos in plan file
- Verify feedback wasn't already closed
- If truly missing, escalate to Johannes

---

## Why This Matters

**For users:**
- Closes the feedback loop ("my voice was heard!")
- Builds trust and engagement
- Encourages future feedback

**For the product:**
- Demonstrates responsiveness to user needs
- Improves retention and satisfaction
- Creates data-driven development culture

**For compliance:**
- COPPA-compliant communication (no data collection)
- Age-appropriate messaging
- Parent-friendly transparency

---

## Integration with TPM Completion Checklist

This protocol is Step 0 (before all other completion steps).

**Updated TPM completion order:**
1. **Step 0:** User notification (THIS PROTOCOL) - if plan has "User Requests" section
2. Step 1: Update `.state.json`
3. Step 2: Move plan file to `completed/`
4. Step 3: Update `PORTFOLIO_STATUS.md`
5. Step 4: Commit portfolio state
6. Step 5: Run Janitor protocol

Do NOT proceed to Step 1 if Step 0 fails.

---

## Quick Reference Commands

```bash
# MCP method (preferred)
mcp__stellaris-admin__get_feedback_details(feedback_id=42)
mcp__stellaris-admin__respond_to_feedback(feedback_id=42, response="...")
mcp__stellaris-admin__update_feedback_status(feedback_id=42, status="addressed")

# SSH fallback
ssh village "sqlite3 /var/lib/stellaris/data/stellaris.db 'UPDATE feedback SET status=\"addressed\", admin_response=\"...\" WHERE id=42;'"

# Verify
ssh village "sqlite3 /var/lib/stellaris/data/stellaris.db 'SELECT status FROM feedback WHERE id=42;'"
```

---

**CRITICAL:** User notification is NOT optional. If a plan has a "User Requests" section, you MUST complete this protocol before shipment.
