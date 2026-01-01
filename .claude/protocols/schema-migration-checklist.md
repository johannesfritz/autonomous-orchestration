# Schema Migration Checklist

**This checklist is MANDATORY for all database schema changes.**

---

## Before Writing Code

- [ ] **Document the change:** Why is this column/table needed?
- [ ] **Check existing data:** Will existing rows be affected?
- [ ] **Plan backfill:** If column is NOT NULL, how will existing rows be updated?
- [ ] **Consider NULL handling:** Can queries handle NULL values during migration?

---

## Migration Script

- [ ] **Migration file created:** `migrations/YYYYMMDD_HHMMSS_description.sql`
- [ ] **Migration tested:** Run against copy of production database
- [ ] **Backfill included:** If adding NOT NULL column, backfill existing rows
- [ ] **Idempotent:** Migration can be run multiple times safely
- [ ] **Rollback plan:** Document how to undo the migration

**Example:**
```sql
-- Add column with DEFAULT (handles existing rows)
ALTER TABLE notifications ADD COLUMN target_type TEXT DEFAULT 'user';

-- Backfill existing rows (explicit)
UPDATE notifications SET target_type = 'user' WHERE target_type IS NULL;

-- Make NOT NULL after backfill (optional, for data integrity)
ALTER TABLE notifications ALTER COLUMN target_type SET NOT NULL;
```

---

## Code Changes

- [ ] **All INSERT statements updated:** Include new column with explicit value
- [ ] **All helper functions updated:** Set new column explicitly (don't rely on DEFAULT)
- [ ] **All queries updated:** Handle NULL values gracefully
- [ ] **Indexes added:** For new columns used in WHERE clauses

**Example - UPDATE INSERT:**
```python
# ❌ BEFORE (missing target_type)
notification = Notification(
    user_id=user.id,
    notification_type="achievement",
    title="Badge Unlocked"
)

# ✅ AFTER (explicit target_type)
notification = Notification(
    user_id=user.id,
    notification_type="achievement",
    title="Badge Unlocked",
    target_type="user"  # Explicit value
)
```

**Example - QUERY NULL HANDLING:**
```python
# ❌ BEFORE (excludes NULL)
notifications = session.query(Notification).filter(
    Notification.user_id == user_id,
    Notification.target_type == "user"  # Excludes NULL values!
).all()

# ✅ AFTER (includes NULL for backward compatibility)
notifications = session.query(Notification).filter(
    Notification.user_id == user_id,
    (Notification.target_type == "user") | (Notification.target_type.is_(None))
).all()

# OR (cleaner with SQLAlchemy or_)
from sqlalchemy import or_
notifications = session.query(Notification).filter(
    Notification.user_id == user_id,
    or_(
        Notification.target_type == "user",
        Notification.target_type.is_(None)
    )
).all()
```

---

## Testing

- [ ] **Migration tests added:** `tests/test_migrations.py`
- [ ] **Backward compatibility tests added:** `tests/test_backward_compatibility.py`
- [ ] **Unit tests pass:** All existing tests still pass
- [ ] **Integration tests pass:** E2E tests with migrated data
- [ ] **Tested against production snapshot:** Migration runs successfully on anonymized prod data

---

## Code Review

- [ ] **Schema change flagged:** Reviewer knows this is high-risk
- [ ] **Migration script reviewed:** Backfill logic verified
- [ ] **Query logic reviewed:** NULL handling verified
- [ ] **Helper functions reviewed:** Explicit column values verified
- [ ] **Rollback plan reviewed:** Documented and feasible

---

## Deployment

- [ ] **Database backup created:** Before running migration
- [ ] **Migration timing planned:** Low-traffic window if possible
- [ ] **Monitoring plan:** What to check after migration runs
- [ ] **Rollback ready:** Can revert to previous schema if needed
- [ ] **Smoke tests defined:** Post-migration verification steps

**Post-Migration Smoke Tests:**
1. Verify new column exists: `\d notifications` (PostgreSQL) or `.schema notifications` (SQLite)
2. Check for NULL values: `SELECT COUNT(*) FROM notifications WHERE target_type IS NULL;`
3. Run health check endpoint: `GET /api/notifications/health`
4. Manually test affected user flows

---

## Health Check Verification

After deployment, verify:
- [ ] **No errors in logs:** Check journalctl/application logs
- [ ] **Health check passes:** Endpoint returns 200 OK
- [ ] **User flows work:** Manually test critical paths
- [ ] **No NULL-related errors:** Query logs for NULL pointer exceptions

---

## Failure: What to Do

If migration causes issues:

1. **Immediate:** Check logs for NULL-related errors
2. **Diagnose:** Identify which query/code is failing
3. **Quick fix options:**
   - Hotfix query to handle NULL values
   - Backfill NULL values immediately
   - Rollback migration (if critical)
4. **Document:** Add to postmortem for process improvement

---

## CRITICAL REMINDERS

**Schema changes are HIGH RISK:**
- Existing production data WILL have NULL values for new columns (unless backfilled)
- Queries MUST handle NULL values gracefully
- Helper functions MUST set values explicitly (don't rely on DEFAULT)
- Migration scripts MUST be tested on production-like data

**When in doubt, ASK:**
- Is this backward compatible?
- What happens to existing rows?
- Have I tested with NULL values?

---

**This checklist enforced by:**
- `.claude/scripts/detect-schema-changes.sh` (pre-commit hook)
- shadow-code-reviewer agent (SubagentStart hook)
- Code review process (manual verification)
