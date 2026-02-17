# Portfolio Manager Fixes - 2026-01-03

**Two critical issues resolved:**

1. **Background Execution** - TPMs now execute in background without blocking command line
2. **Mandatory Cleanup Enforcement** - Hook-based verification ensures portfolio state consistency

---

## Issue 1: Background Execution

### Problem

Previously, Portfolio Manager used the `Task` tool to spawn TPM orchestrators, which is synchronous and blocks the command line until all plans complete. This prevented you from interacting with Claude Code while plans executed.

**Old behavior:**
```
Portfolio Manager spawns 3 TPMs via Task tool
→ Command line BLOCKED for 60+ minutes
→ No user interaction possible until all complete
```

### Solution

Portfolio Manager now uses a background spawn script that leverages `Bash(run_in_background=true)`:

**New behavior:**
```bash
Portfolio Manager spawns 3 TPMs in background
→ Command line returns IMMEDIATELY
→ TPMs execute autonomously in background
→ User can continue working
```

### Implementation

**New script:** `.claude/scripts/spawn-tpm-background.sh`
- Launches TPM orchestrator in background Bash process
- Logs progress to `inbox/plans/.logs/{PLAN-ID}.log`
- Tracks PID in `inbox/plans/.logs/{PLAN-ID}.pid`
- Self-cleans on completion

**Portfolio Manager updated:**
- Changed from `Task(subagent_type='tpm-orchestrator', ...)`
- To: `Bash('.claude/scripts/spawn-tpm-background.sh PLAN-ID', run_in_background=true)`
- All ready plans spawn in ONE message (parallel)
- Returns immediately with log file locations

### Usage

**Monitor background execution:**
```bash
# View live logs
tail -f "inbox/plans/.logs/PLAN-2025-001.log"

# Check if TPM is still running
cat "inbox/plans/.logs/PLAN-2025-001.pid"

# List all active TPMs
ls -1 "inbox/plans/.logs/*.pid"
```

**Portfolio Manager output:**
```
🚀 Spawning 3 TPM orchestrators in background: PLAN-001, PLAN-002, PLAN-003

Progress logs: inbox/plans/.logs/{PLAN-ID}.log
Monitor: tail -f inbox/plans/.logs/PLAN-001.log

State updated. Dashboard updated. Command line free.
```

---

## Issue 2: Mandatory Cleanup Enforcement

### Problem

TPM orchestrators were supposed to complete cleanup (move plan files, update state, commit changes), but this was only documented in `.claude/protocols/tpm-completion-checklist.md` and injected as a REMINDER via hooks.

**The reminder was not enforced** - TPMs could skip cleanup steps and return.

This caused:
- Plan files stuck in `inbox/plans/` instead of `completed/`
- `.state.json` showing stale EXECUTING status
- Portfolio dashboard out of sync
- Uncommitted state changes
- Confusion about which plans are actually done

### Solution

Added **mandatory cleanup verification** via `SubagentStop` hook:

**New script:** `.claude/scripts/verify-cleanup-complete.sh PLAN-ID`

This script **verifies** (not just reminds):
1. ✅ Plan file moved to `completed/` folder (or in active/ with AWAITING_MERGE_APPROVAL status)
2. ✅ `.state.json` updated with SHIPPED or AWAITING_MERGE_APPROVAL status
3. ✅ `PORTFOLIO_STATUS.md` updated with plan completion
4. ✅ All state changes committed to git
5. ✅ `audit_log.jsonl` contains completion event
6. ✅ Pull request exists and is merged (or awaiting manual merge)

**Enforcement via hook:**
- `SubagentStop(tpm-orchestrator)` now runs verification script
- Script exits with code 1 if any check fails
- Clear error messages show what's missing
- TPM cannot return until cleanup is complete

### Implementation

**Hook added to `.claude/settings.json`:**
```json
{
  "matcher": "tpm-orchestrator",
  "hooks": [
    {
      "type": "command",
      "command": "echo '🔍 MANDATORY CLEANUP VERIFICATION' && ..."
    }
  ]
}
```

**What TPM sees when completing:**
```
═══════════════════════════════════════
🔍 MANDATORY CLEANUP VERIFICATION
═══════════════════════════════════════

CRITICAL: Before returning, you MUST run cleanup verification:

  .claude/scripts/verify-cleanup-complete.sh PLAN-ID

This script verifies:
  ✓ Plan file moved to completed/
  ✓ .state.json updated with SHIPPED status
  ✓ PORTFOLIO_STATUS.md updated
  ✓ All state changes committed to git
  ✓ Audit log contains completion event
  ✓ PR exists and is merged (or awaiting manual merge)

If verification fails, complete missing steps before returning.
═══════════════════════════════════════
```

### Usage

**TPM orchestrators automatically run verification before returning.**

**Manual verification (if needed):**
```bash
.claude/scripts/verify-cleanup-complete.sh PLAN-2025-001
```

**Example output (success):**
```
🧹 MANDATORY CLEANUP VERIFICATION for PLAN-2025-001

## 1. Plan File Location
✅ Plan file in completed/ folder

## 2. Portfolio State (.state.json)
✅ Plan status: SHIPPED

## 3. Portfolio Dashboard (PORTFOLIO_STATUS.md)
✅ Plan appears in dashboard

## 4. Git Commit Status
✅ All portfolio state changes committed

## 5. Audit Log (audit_log.jsonl)
✅ Completion event logged in audit trail

## 6. Pull Request Status
✅ Pull request exists for branch: feature/user-auth
✅ Pull request merged

═══════════════════════════════════════
✅ CLEANUP COMPLETE - All checks passed
```

**Example output (failure):**
```
🧹 MANDATORY CLEANUP VERIFICATION for PLAN-2025-001

## 1. Plan File Location
❌ Plan file still in inbox/plans/ but status is SHIPPED (should be moved to completed/)

## 4. Git Commit Status
❌ Uncommitted portfolio state changes found:
   M inbox/plans/.state.json
   M inbox/PORTFOLIO_STATUS.md

═══════════════════════════════════════
❌ CLEANUP INCOMPLETE - 2 errors found

⚠️  MANDATORY ACTION REQUIRED:
   The TPM Orchestrator did not complete all cleanup steps.
   Review errors above and complete missing steps manually.

Common fixes:
  1. Move plan file: mv 'PLAN-2025-001.md' 'inbox/plans/completed/'
  2. Update .state.json status to SHIPPED
  3. Update PORTFOLIO_STATUS.md
  4. Commit changes: git add -A 00\ Inbox/ && git commit -m 'Update portfolio state: PLAN-2025-001'
```

---

## Files Modified

**New scripts:**
- `.claude/scripts/spawn-tpm-background.sh` - Background TPM spawner
- `.claude/scripts/verify-cleanup-complete.sh` - Mandatory cleanup verification

**Updated configuration:**
- `.claude/settings.json` - Added mandatory verification hook to `SubagentStop(tpm-orchestrator)`

**Updated documentation:**
- `.claude/agents/portfolio-manager.md` - Background execution protocol
- `.claude/protocols/portfolio-manager-fixes.md` - This file

**New directory:**
- `inbox/plans/.logs/` - Background execution logs and PID files

---

## Testing Checklist

Before using the updated Portfolio Manager:

1. **Verify scripts are executable:**
   ```bash
   ls -l .claude/scripts/spawn-tpm-background.sh
   ls -l .claude/scripts/verify-cleanup-complete.sh
   # Should show -rwxr-xr-x (executable)
   ```

2. **Test background spawn (dry run):**
   ```bash
   # Creates a dummy plan for testing
   # (Skip if you have real plans ready)
   ```

3. **Monitor first execution:**
   ```bash
   # After Portfolio Manager spawns TPMs:
   tail -f "inbox/plans/.logs/PLAN-*.log"
   ```

4. **Verify cleanup enforcement:**
   ```bash
   # After plan completes, check verification ran:
   # Should see "MANDATORY CLEANUP VERIFICATION" in TPM logs
   ```

---

## Rollback (If Needed)

If issues occur, revert to synchronous execution:

1. **Temporarily disable background spawn:**
   Edit `.claude/agents/portfolio-manager.md`, change:
   ```python
   # From:
   Bash('.claude/scripts/spawn-tpm-background.sh PLAN-001', run_in_background=true)

   # To (temporary fallback):
   Task(subagent_type='tpm-orchestrator', prompt='Execute PLAN-001...')
   ```

2. **Keep cleanup enforcement** (this is safe and beneficial)

3. **Report issues** to continue debugging background execution

---

## Benefits Summary

**Background Execution:**
- ✅ Command line returns immediately
- ✅ User can continue working while plans execute
- ✅ True parallelism (no sequential blocking)
- ✅ Progress visibility via log files

**Mandatory Cleanup:**
- ✅ Portfolio state always consistent
- ✅ No orphaned plan files
- ✅ No stale EXECUTING statuses
- ✅ Git commits always happen
- ✅ Clear error messages when cleanup fails

**Result:** Portfolio Manager is now truly fire-and-forget with guaranteed state consistency.
