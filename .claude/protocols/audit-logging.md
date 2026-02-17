# Audit Logging Protocol

**Purpose:** Track all significant system events for compliance, debugging, and security monitoring.

**Location:** `inbox/audit_log.jsonl` (JSON Lines format - one JSON object per line)

---

## Why Audit Logging

Audit logs provide:
1. **Traceability** - Know who did what and when
2. **Compliance** - Required for production systems
3. **Debugging** - Reconstruct event sequences for incident response
4. **Security** - Detect unauthorized access or suspicious patterns

---

## Log Format

**File format:** JSON Lines (.jsonl) - each line is a valid JSON object

**Required fields:**
- `timestamp` - ISO 8601 format with timezone (e.g., "2026-01-19T15:30:00Z")
- `event` - Event type (lowercase, underscore-separated)
- `deployed_by` or `initiated_by` - Actor performing the action

**Optional fields:**
- `project` - Project name (e.g., "protokoll-assistent", "stellaris")
- `plan_id` - Related development plan ID
- `error` - Error message (for failure events)
- `user_id` - User identifier (for user-initiated actions)
- Additional context fields specific to event type

---

## Event Types

### Deployment Events

**Successful deployment:**
```json
{
  "timestamp": "2026-01-19T15:30:00Z",
  "event": "deployment",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-protokoll-incident-phase4-quality-gates",
  "files_deployed": ["backend/src/api/routes.py", "frontend/src/App.tsx"],
  "smoke_test_result": "pass",
  "deployed_by": "Claude Code",
  "deployment_method": "scp + systemctl restart"
}
```

**Failed deployment:**
```json
{
  "timestamp": "2026-01-19T15:35:00Z",
  "event": "deployment_failure",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-protokoll-incident-phase4-quality-gates",
  "files_deployed": ["backend/src/api/routes.py"],
  "error": "Health check returned 502 Bad Gateway",
  "rollback_status": "success",
  "deployed_by": "Claude Code"
}
```

**Rollback:**
```json
{
  "timestamp": "2026-01-19T15:36:00Z",
  "event": "rollback",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-protokoll-incident-phase4-quality-gates",
  "from_commit": "abc123",
  "to_commit": "def456",
  "reason": "Deployment smoke tests failed",
  "rollback_status": "success",
  "initiated_by": "Claude Code"
}
```

### Migration Events

**Migration executed:**
```json
{
  "timestamp": "2026-01-19T14:00:00Z",
  "event": "migration_executed",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-db-schema-update",
  "migration_file": "versions/abc123_add_user_preferences.py",
  "direction": "upgrade",
  "result": "success",
  "executed_by": "Claude Code"
}
```

**Migration rolled back:**
```json
{
  "timestamp": "2026-01-19T14:05:00Z",
  "event": "migration_rollback",
  "project": "protokoll-assistent",
  "plan_id": "PLAN-db-schema-update",
  "migration_file": "versions/abc123_add_user_preferences.py",
  "direction": "downgrade",
  "reason": "Deployment verification failed",
  "result": "success",
  "executed_by": "Claude Code"
}
```

### Security Events

**Authentication failure:**
```json
{
  "timestamp": "2026-01-19T16:20:00Z",
  "event": "auth_failure",
  "project": "protokoll-assistent",
  "user_email": "user@example.com",
  "ip_address": "192.168.1.100",
  "reason": "invalid_password",
  "attempt_count": 3
}
```

**Unauthorized access attempt:**
```json
{
  "timestamp": "2026-01-19T16:25:00Z",
  "event": "unauthorized_access",
  "project": "protokoll-assistent",
  "user_id": "user-123",
  "resource": "/api/admin/users",
  "ip_address": "192.168.1.100",
  "action": "DELETE",
  "blocked": true
}
```

### Data Events

**Bulk data deletion:**
```json
{
  "timestamp": "2026-01-19T17:00:00Z",
  "event": "data_deletion",
  "project": "protokoll-assistent",
  "user_id": "user-123",
  "resource_type": "protocols",
  "count": 15,
  "soft_delete": true,
  "initiated_by": "user-123"
}
```

**Data export:**
```json
{
  "timestamp": "2026-01-19T17:30:00Z",
  "event": "data_export",
  "project": "protokoll-assistent",
  "user_id": "user-123",
  "export_type": "protocols_csv",
  "record_count": 150,
  "file_size_bytes": 45000,
  "initiated_by": "user-123"
}
```

### System Events

**Service start:**
```json
{
  "timestamp": "2026-01-19T10:00:00Z",
  "event": "service_start",
  "project": "protokoll-assistent",
  "version": "1.2.3",
  "environment": "production",
  "initiated_by": "systemd"
}
```

**Service crash:**
```json
{
  "timestamp": "2026-01-19T18:45:00Z",
  "event": "service_crash",
  "project": "protokoll-assistent",
  "error": "Unhandled exception: NullPointerError",
  "stack_trace_file": "/var/log/protokoll-assistent/crash-2026-01-19.log",
  "restart_status": "auto_restarted"
}
```

---

## Writing Audit Logs

### From Bash Scripts

```bash
# Helper function
log_audit_event() {
    local event="$1"
    local project="$2"
    local plan_id="$3"
    local additional_fields="$4"  # JSON string

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Base log entry
    local log_entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg evt "$event" \
        --arg proj "$project" \
        --arg plan "$plan_id" \
        '{timestamp: $ts, event: $evt, project: $proj, plan_id: $plan}'
    )

    # Merge with additional fields if provided
    if [ -n "$additional_fields" ]; then
        log_entry=$(echo "$log_entry" | jq ". + $additional_fields")
    fi

    # Append to audit log
    echo "$log_entry" >> "$CLAUDE_PROJECT_DIR/inbox/audit_log.jsonl"
}

# Usage example - deployment
log_audit_event "deployment" "protokoll-assistent" "PLAN-123" \
    '{"smoke_test_result": "pass", "deployed_by": "Claude Code"}'

# Usage example - deployment failure
log_audit_event "deployment_failure" "protokoll-assistent" "PLAN-123" \
    '{"error": "Health check failed", "rollback_status": "success", "deployed_by": "Claude Code"}'
```

### From Python Code

```python
import json
from datetime import datetime, timezone
from pathlib import Path

def log_audit_event(
    event: str,
    project: str,
    plan_id: str | None = None,
    initiated_by: str = "system",
    **additional_fields
) -> None:
    """
    Write an audit log entry to inbox/audit_log.jsonl

    Args:
        event: Event type (e.g., "deployment", "migration_executed")
        project: Project name (e.g., "protokoll-assistent")
        plan_id: Optional plan ID
        initiated_by: Who triggered the event
        **additional_fields: Additional context fields
    """
    log_entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event": event,
        "project": project,
        "initiated_by": initiated_by,
    }

    if plan_id:
        log_entry["plan_id"] = plan_id

    # Merge additional fields
    log_entry.update(additional_fields)

    # Append to audit log
    audit_log_path = Path(__file__).parent.parent / "inbox" / "audit_log.jsonl"
    with open(audit_log_path, "a") as f:
        f.write(json.dumps(log_entry) + "\n")

# Usage example - deployment
log_audit_event(
    event="deployment",
    project="protokoll-assistent",
    plan_id="PLAN-123",
    initiated_by="Claude Code",
    smoke_test_result="pass",
    files_deployed=["backend/routes.py"]
)

# Usage example - migration
log_audit_event(
    event="migration_executed",
    project="protokoll-assistent",
    plan_id="PLAN-456",
    initiated_by="Claude Code",
    migration_file="versions/abc123_add_column.py",
    direction="upgrade",
    result="success"
)
```

---

## Querying Audit Logs

### View recent events

```bash
# Last 10 events
tail -10 inbox/audit_log.jsonl | jq '.'

# Last 10 deployment events
grep '"event":"deployment"' inbox/audit_log.jsonl | tail -10 | jq '.'
```

### Filter by project

```bash
jq 'select(.project == "protokoll-assistent")' inbox/audit_log.jsonl
```

### Filter by date range

```bash
# Events after specific timestamp
jq 'select(.timestamp >= "2026-01-19T00:00:00Z")' inbox/audit_log.jsonl

# Events today
TODAY=$(date -u +"%Y-%m-%d")
jq "select(.timestamp | startswith(\"$TODAY\"))" inbox/audit_log.jsonl
```

### Find failures

```bash
# All failure events
jq 'select(.event | endswith("_failure"))' inbox/audit_log.jsonl

# Deployments that failed
jq 'select(.event == "deployment_failure")' inbox/audit_log.jsonl
```

### Aggregate statistics

```bash
# Count events by type
jq -r '.event' inbox/audit_log.jsonl | sort | uniq -c

# Count deployments by project
jq -r 'select(.event == "deployment") | .project' inbox/audit_log.jsonl | sort | uniq -c
```

---

## Retention Policy

**Current policy:** Rotate audit logs monthly

```bash
# Rotate logs (run monthly via cron)
MONTH=$(date -u +"%Y-%m")
mv inbox/audit_log.jsonl "inbox/audit_logs/audit_log_${MONTH}.jsonl"
touch inbox/audit_log.jsonl
```

**Archive retention:** Keep for 12 months minimum (compliance requirement)

---

## Security Considerations

1. **Never log sensitive data:**
   - ❌ Passwords or tokens
   - ❌ Full email addresses (hash or truncate)
   - ❌ API keys
   - ❌ Personal identifiable information (PII) beyond user_id

2. **Protect audit log file:**
   ```bash
   chmod 600 inbox/audit_log.jsonl  # Read/write for owner only
   ```

3. **Append-only writes:**
   - Never edit or delete existing entries
   - Use log rotation for cleanup
   - Keep archived logs immutable

4. **Tamper detection:**
   - Consider checksumming rotated logs
   - Store checksums separately

---

## Integration with Quality Gates

**Gate 6 (Deployment Verification) requires:**
- ✅ Successful deployment logged to audit trail
- ✅ Smoke test result recorded
- ✅ If deployment fails, failure + rollback logged

**See:** `.claude/protocols/mandatory-quality-gates.md` Gate 6 for enforcement details.
