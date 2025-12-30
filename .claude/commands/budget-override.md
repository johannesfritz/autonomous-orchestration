# Budget Override Command

Temporarily adjust budget limits for the current session.

**Usage:**
- `/budget-override --daily <amount>` - Set daily limit
- `/budget-override --plan <amount>` - Set per-plan limit
- `/budget-override --session <amount>` - Set session limit
- `/budget-override --reset` - Reset to defaults

**Examples:**
```
/budget-override --daily 75
/budget-override --plan 30
/budget-override --session 150
/budget-override --reset
```

## Purpose

Allow temporary budget adjustments when needed:
- Large feature requiring more tokens
- End-of-month budget flexibility
- Testing/development sessions
- Emergency hotfixes

## Default Limits

```json
{
  "limits": {
    "max_daily_usd": 50.0,
    "max_per_plan_usd": 20.0,
    "max_session_usd": 100.0
  }
}
```

## Override Protocol

When the user invokes `/budget-override`:

### 1. Confirm the Override

```
Budget Override Request
============================================================

Current limits:
  Daily:   $50.00
  Plan:    $20.00
  Session: $100.00

Requested change:
  Daily:   $50.00 → $75.00 (+50%)

Current spend:
  Daily:   $40.00 (80% of current limit)

Confirm this override? This will:
- Allow up to $75.00 in daily spending
- Take effect immediately
- Reset at midnight UTC (or use --persist to save)

[yes/no]
```

### 2. Apply the Override

```bash
# Update state file
jq '.cost_tracking.limits.max_daily_usd = 75.0' \
   {project}/00 Inbox/system_state.json > tmp.json && \
   mv tmp.json {project}/00 Inbox/system_state.json

# Log to audit trail
echo '{"timestamp":"...","event":"BUDGET_OVERRIDE","details":{"type":"daily","old":50,"new":75}}' \
   >> {project}/00 Inbox/audit_log.jsonl
```

### 3. Confirm Success

```
Budget Override Applied
============================================================

New limits:
  Daily:   $75.00 ✓ (changed)
  Plan:    $20.00
  Session: $100.00

Remaining budget:
  Daily:   $35.00 (47%)

Note: Override expires at midnight UTC unless --persist is used.
```

## Safety Features

### Maximum Caps

Even with overrides, hard caps apply:

```json
{
  "hard_caps": {
    "max_daily_absolute": 200.0,
    "max_plan_absolute": 100.0,
    "max_session_absolute": 500.0
  }
}
```

If override exceeds hard caps:
```
Error: Cannot set daily limit above $200.00 (hard cap)
Current request: $250.00

To request higher limits, contact your administrator.
```

### Override Logging

All overrides are logged to audit trail:

```json
{
  "timestamp": "2025-01-15T14:30:00Z",
  "event": "BUDGET_OVERRIDE",
  "source": "user",
  "details": {
    "type": "daily",
    "old_limit": 50.0,
    "new_limit": 75.0,
    "reason": "Large feature development",
    "expires": "2025-01-16T00:00:00Z"
  }
}
```

### Persistence Options

- **Default:** Override expires at midnight UTC
- **--persist:** Save as new default (requires confirmation)
- **--duration 4h:** Override lasts for specified duration

## Reset to Defaults

```
/budget-override --reset

Budget Reset
============================================================

Limits restored to defaults:
  Daily:   $50.00
  Plan:    $20.00
  Session: $100.00

Override history cleared.
```

## Output Format

```
Budget Override: SUCCESS
============================================================

Changed:
  - daily: $50.00 → $75.00

Current status:
  Daily:   $40.00 / $75.00 (53%)
  Plan:    $8.50 / $20.00 (43%) [PLAN-2025-003]
  Session: $12.50 / $100.00 (13%)

Expires: 2025-01-16 00:00 UTC (9 hours)

Run '/costs' to monitor spending.
```

## Remember

- Log all overrides for audit
- Enforce hard caps regardless of override
- Default to temporary (expires at midnight)
- Require explicit confirmation for large increases
