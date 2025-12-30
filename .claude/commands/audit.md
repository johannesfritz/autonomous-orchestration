# Audit Command

View the audit trail for a specific plan or the entire system.

**Usage:**
- `/audit PLAN-2025-NNN` - Show audit trail for specific plan
- `/audit --recent` - Show last 50 audit events
- `/audit --today` - Show today's events
- `/audit --errors` - Show only errors and failures

## Purpose

Provide full visibility into system decisions and actions:
- Why was a plan prioritized a certain way?
- What quality gates did it pass/fail?
- When did each phase complete?
- Who/what made each decision?

## Audit Log Format

The audit trail is stored in `00 Inbox/audit_log.jsonl` (JSON Lines format):

```json
{"timestamp": "2025-01-15T10:30:00Z", "event": "PLAN_SUBMITTED", "plan_id": "PLAN-2025-001", "source": "user", "details": {"priority": "high", "files": ["src/api/auth.py"]}}
{"timestamp": "2025-01-15T10:30:05Z", "event": "RISK_ASSESSED", "plan_id": "PLAN-2025-001", "source": "risk-manager", "details": {"overall_score": 4, "decision": "APPROVED"}}
{"timestamp": "2025-01-15T10:30:10Z", "event": "EXECUTION_STARTED", "plan_id": "PLAN-2025-001", "source": "tpm-orchestrator", "details": {"workstreams": 3, "tpm_id": "agent-123"}}
```

## Event Types

| Event | Source | When |
|-------|--------|------|
| `PLAN_SUBMITTED` | portfolio-manager | Plan added to queue |
| `RISK_ASSESSED` | risk-manager | Risk assessment complete |
| `PRIORITY_OVERRIDE` | portfolio-manager | User changed priority |
| `CONFLICT_DETECTED` | portfolio-manager | File conflict found |
| `CONFLICT_RESOLVED` | portfolio-manager | Conflict resolution decided |
| `EXECUTION_STARTED` | tpm-orchestrator | TPM begins plan execution |
| `WORKSTREAM_STARTED` | tpm-orchestrator | Workstream agent spawned |
| `WORKSTREAM_COMPLETE` | tpm-orchestrator | Workstream finished |
| `TESTS_PASSED` | tpm-orchestrator | Test suite passed |
| `TESTS_FAILED` | tpm-orchestrator | Test suite failed |
| `FIX_ATTEMPTED` | tpm-orchestrator | Attempted to fix failure |
| `QA_REVIEW_STARTED` | qa-lead | QA Lead review began |
| `QA_REVIEW_COMPLETE` | qa-lead | QA Lead verdict |
| `SECURITY_AUDIT_COMPLETE` | security-audit | Security scan finished |
| `PR_CREATED` | tpm-orchestrator | Pull request created |
| `MERGE_COMPLETE` | tpm-orchestrator | PR merged |
| `AWAITING_APPROVAL` | tpm-orchestrator | High-risk, needs manual merge |
| `CIRCUIT_BREAKER_TRIPPED` | tpm-orchestrator | Fix limit exceeded |
| `PLAN_SHIPPED` | portfolio-manager | Plan successfully deployed |
| `PLAN_FAILED` | portfolio-manager | Plan failed (after circuit breaker) |
| `ROLLBACK_INITIATED` | rollback | Rollback started |
| `ROLLBACK_COMPLETE` | rollback | Rollback finished |

## Output Format

### For Specific Plan

```
Audit Trail: PLAN-2025-001
============================================================

2025-01-15 10:30:00 UTC  PLAN_SUBMITTED
  Source: user (via /add-plan)
  Priority: high
  Files: src/api/auth.py, src/models/user.py, tests/test_auth.py

2025-01-15 10:30:05 UTC  RISK_ASSESSED
  Source: risk-manager
  Overall Score: 4/10 (Medium)
  - User Disruption: 3/10
  - Controllability: 2/10
  - Liability: 5/10
  - AI Risk: 1/10
  Decision: APPROVED for autonomous execution

2025-01-15 10:30:10 UTC  EXECUTION_STARTED
  Source: tpm-orchestrator (agent-123)
  Workstreams: 3 (backend-api, frontend-ui, tests)
  Branch: feature/auth-improvements

2025-01-15 10:35:00 UTC  WORKSTREAM_COMPLETE
  Workstream: backend-api
  Duration: 4m 50s
  Files modified: 2

2025-01-15 10:40:00 UTC  WORKSTREAM_COMPLETE
  Workstream: frontend-ui
  Duration: 9m 50s
  Files modified: 3

2025-01-15 10:42:00 UTC  WORKSTREAM_COMPLETE
  Workstream: tests
  Duration: 11m 50s
  Files modified: 1

2025-01-15 10:43:00 UTC  TESTS_PASSED
  Test suite: pytest
  Passed: 45, Failed: 0, Skipped: 2
  Duration: 32s

2025-01-15 10:44:00 UTC  QA_REVIEW_COMPLETE
  Source: qa-lead
  Verdict: APPROVE
  Passes: correctness=PASS, integration=PASS, security=PASS,
          maintainability=PASS, regression_risk=3/10

2025-01-15 10:45:00 UTC  SECURITY_AUDIT_COMPLETE
  Findings: 0 critical, 0 high, 1 medium, 2 low
  Verdict: PASS

2025-01-15 10:46:00 UTC  PR_CREATED
  PR: #42 https://github.com/user/repo/pull/42
  Title: Implement auth improvements (PLAN-2025-001)

2025-01-15 10:46:30 UTC  MERGE_COMPLETE
  Merge commit: abc123def456
  Auto-merged: Yes (risk score 4/10)

2025-01-15 10:46:35 UTC  PLAN_SHIPPED
  Duration: 16m 35s
  Total cost: $3.50

============================================================
Summary: SHIPPED in 16m 35s | Risk 4/10 | Cost $3.50
```

### For System Overview (--recent)

```
Recent Audit Events (last 50)
============================================================

2025-01-15 10:46:35  PLAN_SHIPPED        PLAN-2025-001
2025-01-15 10:30:00  PLAN_SUBMITTED      PLAN-2025-002
2025-01-15 10:25:00  CIRCUIT_BREAKER     PLAN-2024-099  (fix_limit)
2025-01-15 10:20:00  TESTS_FAILED        PLAN-2024-099
...
```

## Implementation

When the user invokes `/audit`:

1. **Read audit log:**
   ```bash
   cat 00 Inbox/audit_log.jsonl
   ```

2. **Filter by plan ID (if provided):**
   ```bash
   grep "PLAN-2025-XXX" 00 Inbox/audit_log.jsonl
   ```

3. **Format output:**
   - Parse JSON lines
   - Group by plan (if specific plan)
   - Sort by timestamp
   - Pretty print with formatting

4. **Generate summary:**
   - Total duration
   - Final status
   - Key metrics (risk, cost, test results)

## Audit Logging Protocol (For Agents)

All agents MUST log to `00 Inbox/audit_log.jsonl`:

```python
def log_audit_event(event: str, plan_id: str, source: str, details: dict):
    entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "event": event,
        "plan_id": plan_id,
        "source": source,
        "details": details
    }
    with open("00 Inbox/audit_log.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")
```

**Required events to log:**
- Portfolio Manager: PLAN_SUBMITTED, PRIORITY_OVERRIDE, CONFLICT_*, PLAN_SHIPPED/FAILED
- Risk Manager: RISK_ASSESSED
- TPM Orchestrator: EXECUTION_*, WORKSTREAM_*, TESTS_*, PR_*, MERGE_*, CIRCUIT_BREAKER_*
- QA Lead: QA_REVIEW_*
- Security Audit: SECURITY_AUDIT_*
