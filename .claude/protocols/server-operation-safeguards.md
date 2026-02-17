# Server Operation Safeguards Protocol

**Purpose:** Prevent data loss and unintended overwrites when syncing between local and production environments.

**Scope:** ALL operations involving server files (rsync, scp, ssh commands that modify files).

**Philosophy:** Diligence first, speed is a high secondary.

---

## CRITICAL: The Near-Miss That Created This Protocol

On Jan 19, 2026, we almost lost significant development work by blindly syncing local files to the server. The server had evolved (crypto module, API keys, migrations) while local was behind. A naive `rsync local→server` would have **deleted production features**.

**This protocol exists because:**
- Servers can have work that isn't in git yet
- Local repos can be stale
- Either direction can cause data loss
- Understanding WHAT will change is mandatory BEFORE changing it

---

## Gate 0: Comparison BEFORE Any Sync (BLOCKING)

**Requirement:** You MUST compare and understand differences before ANY file transfer to/from a server.

### For Local → Server Sync

**NEVER do this:**
```bash
# DANGEROUS - Overwrites without understanding
rsync -avz local/ server:/path/
scp -r local/ server:/path/
```

**ALWAYS do this:**
```bash
# Step 1: DRY RUN - See what WOULD change
rsync -avzn --delete local/ server:/path/ 2>&1 | tee /tmp/sync-preview.txt

# Step 2: REVIEW the preview
# Look for:
# - Files that would be DELETED (exist on server, not local)
# - Files that would be OVERWRITTEN (different on server)
# - New files being added (probably safe)

# Step 3: TRIAGE
# For each file that would be deleted/overwritten:
# - Is this intentional?
# - Does server have newer/better version?
# - Should we pull from server first?

# Step 4: ONLY AFTER understanding, execute
rsync -avz --delete local/ server:/path/
```

### For Server → Local Sync

Same principle applies:
```bash
# Step 1: DRY RUN
rsync -avzn server:/path/ local/ 2>&1 | tee /tmp/sync-preview.txt

# Step 2: REVIEW
# Look for local changes that would be lost

# Step 3: TRIAGE
# Step 4: Execute only after understanding
```

---

## Gate 1: Impact Assessment (BLOCKING)

Before executing ANY sync, you must answer:

### Questions to Answer

| Question | Must Have Answer |
|----------|-----------------|
| What files will be DELETED? | List them explicitly |
| What files will be OVERWRITTEN? | List them explicitly |
| Is the server version newer/better for any files? | Check timestamps, content |
| Does the server have work not yet in git? | Compare against repo |
| Will this affect the LIVE site? | Yes → Extra caution |
| Can changes be reversed? | Have rollback plan |

### Decision Matrix

| Scenario | Action |
|----------|--------|
| Only additions (local has new files) | Usually safe, proceed |
| Deletions on server | **STOP** - verify these should be deleted |
| Server has newer timestamps | **STOP** - likely server has updates not in local |
| Server files not in git | **STOP** - pull first, then decide |
| Config files (.env, etc.) | **NEVER** overwrite - server configs are authoritative |

---

## Gate 2: Server-Side Verification (BLOCKING)

After any sync to a server, verify:

```bash
# 1. Service still works
curl -s https://site.example/health || echo "HEALTH CHECK FAILED"

# 2. Build succeeds (if applicable)
ssh server "cd /path && npm run build"
echo "Exit code: $?"

# 3. No errors in logs
ssh server "journalctl -u service-name -n 20 --no-pager"
```

If ANY verification fails, **immediately rollback**.

---

## Rollback Procedure

Before syncing, always capture the "before" state:

```bash
# Create timestamped backup on server
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ssh server "cp -r /var/www/app /var/www/app.backup.$TIMESTAMP"

# Or create a tar archive
ssh server "cd /var/www && tar -czf app-backup-$TIMESTAMP.tar.gz app/"
```

To rollback:
```bash
ssh server "rm -rf /var/www/app && mv /var/www/app.backup.$TIMESTAMP /var/www/app"
ssh server "systemctl restart service-name"
```

---

## Config Files: Special Handling

**NEVER sync these from local to server:**
- `.env`, `.env.production`, `.env.local`
- `config/production.*`
- Database files (`*.sqlite`, `*.db`)
- Secret files (`*.key`, `*.pem`, credentials.*)
- Server-specific configs (`postcss.config.mjs` if server-generated)

**Why:** These contain environment-specific settings that are CORRECT on the server.

**Pattern for config sync:**
```bash
# Exclude sensitive/config files
rsync -avz \
  --exclude '.env*' \
  --exclude '*.sqlite' \
  --exclude 'node_modules' \
  --exclude '__pycache__' \
  --exclude 'dist' \
  local/ server:/path/
```

---

## Live Site Awareness

**Before ANY operation on a live site:**

1. **Check if site is actively being used**
   ```bash
   # Check recent access logs
   ssh server "tail -5 /var/log/nginx/access.log"
   ```

2. **Consider timing**
   - Is this during business hours?
   - Are users actively on the site?
   - Can this wait for a maintenance window?

3. **Communicate if needed**
   - Major changes may need user notification
   - Consider "under maintenance" page for extended work

---

## Enforcement

### Pre-Sync Checklist (MUST complete before any sync)

```markdown
## Pre-Sync Verification for [project] [direction: local→server / server→local]

### Comparison
- [ ] Ran dry-run sync command
- [ ] Reviewed files that would be DELETED: [list or "none"]
- [ ] Reviewed files that would be OVERWRITTEN: [list or "none"]
- [ ] Checked server timestamps vs local timestamps

### Triage
- [ ] For each deletion: verified this is intentional
- [ ] For each overwrite: verified local version is correct/newer
- [ ] No server-only work would be lost

### Safety
- [ ] Created backup of server state
- [ ] Have rollback procedure ready
- [ ] Excluded config/env files from sync

### Authorization
- [ ] Understand impact on live site: [description]
- [ ] Sync is appropriate at this time: [yes/no, reason]

**Ready to proceed:** [ ] YES - All items checked
```

### Hook Integration

This protocol should be injected before any:
- `rsync` command involving a remote server
- `scp` command involving a remote server
- `ssh` command that modifies files
- Deployment script execution

---

## Examples

### Good: Intentional, Understood Sync
```
✅ "After comparing, I see 3 new frontend files would be added,
   and PrivacyCenterPage.tsx would be overwritten. The local version
   removes the encryption wizard as intended. Server backup created.
   Proceeding with sync."
```

### Bad: Blind Sync
```
❌ "Running rsync to update the server..."
   [No comparison, no understanding of what changes, potential data loss]
```

### Good: Detected Problem, Stopped
```
✅ "Dry run shows 4 files would be DELETED on server:
   crypto/__init__.py, crypto/encryption.py, etc.
   These don't exist locally. STOPPING - need to pull these first."
```

---

## Philosophy

> "Understand what will change BEFORE you change it."

- **Diligence first:** Speed is valuable, but not at the cost of data loss
- **Comparison mandatory:** Never sync blind
- **Server respect:** Production may have evolved; don't assume local is authoritative
- **Reversibility:** Always have a rollback path
- **Transparency:** Document what changed and why

This near-miss taught us: a few minutes of comparison saves hours of recovery.
