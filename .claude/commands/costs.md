# Costs Command

View API cost tracking and budget status.

**Usage:**
- `/costs` - Show current session and daily costs
- `/costs PLAN-2025-NNN` - Show costs for specific plan
- `/costs --breakdown` - Detailed cost breakdown by operation

## Purpose

Track and control API spending:
- Monitor session and daily spend
- Track per-plan costs
- Alert when approaching budget limits
- Provide cost breakdown for optimization

## Cost Tracking

The system tracks costs in `00 Inbox/system_state.json`:

```json
{
  "cost_tracking": {
    "session_start": "2025-01-15T08:00:00Z",
    "session_spend_usd": 12.50,
    "daily_spend_usd": 25.00,
    "plan_costs": {
      "PLAN-2025-001": 8.50,
      "PLAN-2025-002": 4.00
    },
    "limits": {
      "max_daily_usd": 50.0,
      "max_per_plan_usd": 20.0,
      "max_session_usd": 100.0
    }
  }
}
```

## Output Format

### Summary View (default)

```
Cost Summary
============================================================

Session (started 2025-01-15 08:00 UTC):
  Spent:     $12.50
  Limit:     $100.00
  Remaining: $87.50 (87%)

Daily (2025-01-15):
  Spent:     $25.00
  Limit:     $50.00
  Remaining: $25.00 (50%)

Active Plans:
  PLAN-2025-003: $2.35 (in progress)

Completed Plans (today):
  PLAN-2025-001: $8.50
  PLAN-2025-002: $4.00

============================================================
Total Lifetime: $156.78 (since 2025-01-01)
```

### Per-Plan View

```
Cost Breakdown: PLAN-2025-001
============================================================

Total: $8.50

By Phase:
  Risk Assessment:    $0.15
  Workstreams:        $6.20
    - backend-api:    $2.80
    - frontend-ui:    $2.40
    - tests:          $1.00
  QA Review:          $0.85
  Security Audit:     $0.30
  Git Operations:     $0.00 (local only)

By Model:
  Claude Sonnet:      $7.50 (42 requests)
  Claude Haiku:       $0.50 (15 requests)
  OpenAI Embeddings:  $0.50 (100 chunks)

Duration: 16 min 35 sec
Cost/Minute: $0.51
```

### Detailed Breakdown (--breakdown)

```
Detailed Cost Breakdown
============================================================

By Operation Type:
  Code Generation:    $4.20 (48%)
  Code Review:        $1.85 (21%)
  Test Generation:    $1.15 (13%)
  Risk Assessment:    $0.65 (7%)
  Embedding:          $0.50 (6%)
  Other:              $0.35 (5%)

By Model:
  claude-sonnet-4:    $6.80 (78%)
  claude-haiku-3.5:   $0.85 (10%)
  text-embedding-3:   $0.50 (6%)
  gpt-4o-mini:        $0.35 (4%)

Top 5 Expensive Operations:
  1. Generate backend API code    $1.25  (12 min ago)
  2. QA Lead 5-pass review        $0.85  (8 min ago)
  3. Generate frontend component  $0.78  (10 min ago)
  4. Fix test failures (attempt 2)$0.65  (6 min ago)
  5. Risk assessment              $0.45  (15 min ago)
```

## Budget Alerts

When approaching limits:

```
⚠️ BUDGET ALERT

Daily spend is at 80% of limit ($40.00 / $50.00)

Options:
a) Continue (remaining budget: $10.00)
b) Pause execution until tomorrow
c) Increase limit: /budget-override --daily 75

Active plans will be paused if limit is reached.
```

## Cost Estimation

Before executing a plan, the system estimates costs:

```json
{
  "PLAN-2025-003": {
    "estimated_cost_usd": 5.50,
    "breakdown": {
      "risk_assessment": 0.15,
      "workstreams": 4.00,
      "qa_review": 0.85,
      "security_audit": 0.30,
      "buffer": 0.20
    },
    "confidence": "medium",
    "note": "Estimate based on similar past plans"
  }
}
```

## Implementation

When the user invokes `/costs`:

1. Read state from `00 Inbox/system_state.json`
2. Calculate current session duration
3. Format cost summary
4. If specific plan requested, show plan breakdown
5. Check against limits and show warnings

## Remember

- Track costs per operation for optimization insights
- Alert before limits are hit (not after)
- Provide actionable options when near budget
- Show ROI context (value delivered vs. cost)
