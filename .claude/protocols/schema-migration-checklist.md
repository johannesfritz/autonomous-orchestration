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

## Pre-Deployment Verification

**CRITICAL: Verify migration parity BEFORE deploying code changes.**

- [ ] **Check server migration status:** Run `alembic current` on production
- [ ] **Compare with code:** Ensure server migration matches `alembic heads` in codebase
- [ ] **Deployment script verified:** Script includes migration parity check
- [ ] **Migration executed first:** If server is behind, run `alembic upgrade head` BEFORE deploying code

**Why this matters:**
- Deploying code that uses new columns before migration runs causes 500 errors
- Automated deployment scripts will catch this and fail fast
- Manual deployments must verify parity before proceeding

**Verification command:**
```bash
# On production server
cd /var/www/app/backend
source venv/bin/activate
alembic current  # Shows current migration

# Compare to local codebase
alembic heads    # Shows expected migration

# If they don't match:
alembic upgrade head  # Run migrations FIRST
# THEN deploy code changes
```

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

### Migration Mismatch Troubleshooting

If deployment fails due to migration parity check:

**Error:** "Migration mismatch! Server: abc123, Code expects: def456"

**Diagnosis:**
1. Check what changed:
   ```bash
   # On server
   alembic current
   # In codebase
   alembic heads
   ```

2. Check migration history:
   ```bash
   alembic history
   # Look for the difference between server and code
   ```

**Fix:**
1. **Option A: Server is behind (most common)**
   ```bash
   # SSH to production
   ssh root@server
   cd /var/www/app/backend
   source venv/bin/activate

   # Backup database first
   sudo cp database.db database.db.backup

   # Run pending migrations
   alembic upgrade head

   # Verify migration applied
   alembic current

   # Now re-run deployment
   ```

2. **Option B: Code is behind (rare)**
   ```bash
   # Pull latest code
   git pull origin main

   # Verify migrations are up to date
   cd backend && alembic heads

   # Re-run deployment
   ```

3. **Option C: Divergent migrations (conflict)**
   ```bash
   # This is serious - means local and server have different migration paths
   # DO NOT auto-fix
   # Escalate to developer for manual resolution
   ```

---

## Row Conversion Functions (CRITICAL for SQLite)

When migrating SQLite schemas, **row-to-model conversion functions are the most common failure point.**

### sqlite3.Row Does NOT Support .get()

```python
# ❌ WRONG - sqlite3.Row has no .get() method
def row_to_model(row) -> Model:
    return Model(
        name=row.get("name"),  # AttributeError!
        value=row.get("value", "default")
    )

# ✅ CORRECT - Convert to dict first
def row_to_model(row) -> Model:
    row_dict = dict(row)  # Convert sqlite3.Row to dict
    return Model(
        name=row_dict.get("name"),
        value=row_dict.get("value", "default")
    )
```

### Column Name Mapping for Backward Compatibility

When renaming columns, map new schema to old API format:

```python
def row_to_vocab(row) -> VocabItem:
    """Map new v2 schema columns to old API field names."""
    row_dict = dict(row)

    # New schema: lemma, declension_class, lektion_id
    # Old API expects: latin, declension, lektion
    latin = row_dict.get("lemma") or row_dict.get("latin", "")
    declension = row_dict.get("declension_class") or row_dict.get("declension")
    lektion = row_dict.get("lektion_id") or row_dict.get("lektion")

    return VocabItem(
        latin=latin,
        declension=declension,
        lektion=lektion,
        # ... other fields
    )
```

### Checklist for Row Conversion

- [ ] **All `row_to_*` functions updated:** Handle new column names
- [ ] **Dict conversion added:** `row_dict = dict(row)` before `.get()` calls
- [ ] **Backward compatibility mapping:** New columns map to old API field names
- [ ] **Type coercion handled:** Convert string IDs to integers if API expects int

---

## Table Renames and Query Updates

When renaming tables (e.g., `table` → `table_deprecated`):

- [ ] **All SELECT queries updated:** Reference new table name
- [ ] **All INSERT queries updated:** Reference new table name
- [ ] **All ORDER BY clauses updated:** Column names may have changed
- [ ] **All WHERE clauses updated:** Column names may have changed
- [ ] **Search codebase:** `grep -r "FROM old_table" .`

**Example ORDER BY fix:**
```sql
-- ❌ WRONG - old column name
ORDER BY lektion, base_word

-- ✅ CORRECT - new column name
ORDER BY chapter, base_word
-- OR
ORDER BY lektion_id, base_word
```

---

## Production Migration Execution

### Environment Requirements

- [ ] **Use venv Python:** System Python may lack required packages
- [ ] **Check file ownership:** Database may be owned by www-data
- [ ] **Backup with sudo:** `sudo cp` if permission denied

```bash
# ❌ WRONG - system Python
sudo python3 run_migration.py

# ✅ CORRECT - venv Python with environment variables
sudo ANTHROPIC_API_KEY='...' /var/www/app/venv/bin/python run_migration.py
```

### Post-Migration API Testing

Test in this order:
1. Health endpoint
2. List endpoints (most likely to fail on schema mismatch)
3. Detail endpoints
4. Create/update endpoints
5. Auth flow
6. FSRS/learning state (if applicable)

---

## CRITICAL REMINDERS

**Schema changes are HIGH RISK:**
- Existing production data WILL have NULL values for new columns (unless backfilled)
- Queries MUST handle NULL values gracefully
- Helper functions MUST set values explicitly (don't rely on DEFAULT)
- Migration scripts MUST be tested on production-like data
- **Row conversion functions (`row_to_*`) are the #1 failure point**
- **sqlite3.Row objects do NOT support `.get()` method**

**When in doubt, ASK:**
- Is this backward compatible?
- What happens to existing rows?
- Have I tested with NULL values?
- **Are all `row_to_*` functions updated for new column names?**
- **Does the API response format match what the frontend expects?**

---

**This checklist enforced by:**
- `.claude/scripts/detect-schema-changes.sh` (pre-commit hook)
- shadow-code-reviewer agent (SubagentStart hook)
- Code review process (manual verification)
