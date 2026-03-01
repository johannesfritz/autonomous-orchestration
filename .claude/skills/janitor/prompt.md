# Janitor Protocol

**Purpose:** Clean up the development environment after work sessions - remove temporary files, orphaned artifacts, and ensure all changes are committed and pushed.

## When This Skill Auto-Invokes

- After TPM orchestrator completes a plan (via SubagentStop hook)
- When user explicitly requests cleanup (`/cleanup`, `/janitor`)
- Before session end if uncommitted changes exist

## Cleanup Checklist

### 1. Temporary File Removal

Identify and remove:

```bash
# Python artifacts
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null
find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null
find . -type f -name ".coverage" -delete
find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null

# Node.js artifacts (but NOT node_modules - those are needed)
find . -type d -name ".next" -exec rm -rf {} + 2>/dev/null
find . -type d -name ".turbo" -exec rm -rf {} + 2>/dev/null
find . -type f -name "*.log" -path "*/node_modules/*" -prune -o -name "*.log" -delete

# Build artifacts in wrong locations
find . -type d -name "dist" -path "*/node_modules/*" -prune -o -type d -name "dist" -print

# SQLite temp files
find . -type f -name "*.db-journal" -delete
find . -type f -name "*.db-shm" -delete
find . -type f -name "*.db-wal" -delete

# Editor artifacts
find . -type f -name "*.swp" -delete
find . -type f -name "*.swo" -delete
find . -type f -name "*~" -delete
find . -type f -name ".DS_Store" -delete
```

### 2. Orphaned Plan Files

Check for plan files that should be archived:

```bash
# Plans with SHIPPED status still in active plans/
ls "inbox/plans/"*.md 2>/dev/null | while read plan; do
  if grep -q "Status.*SHIPPED\|Status.*completed" "$plan"; then
    echo "ORPHANED: $plan should be in completed/"
  fi
done
```

### 3. Git Status Check

```bash
# Check for uncommitted changes
git status --porcelain

# Check for untracked files that should be tracked
git status --porcelain | grep "^??" | grep -E "\.(py|ts|tsx|md|json)$"

# Check for staged but uncommitted changes
git diff --cached --name-only
```

### 4. State File Consistency

Verify `.state.json` matches actual plan files:

```python
import json
from pathlib import Path

state_path = Path("inbox/plans/.state.json")
if state_path.exists():
    state = json.loads(state_path.read_text())
    plans_dir = Path("inbox/plans")

    # Check for plans in state that don't exist as files
    for plan_id in state.get("plans", {}):
        plan_file = plans_dir / f"{plan_id}.md"
        if not plan_file.exists():
            print(f"ORPHANED STATE: {plan_id} in state but file missing")

    # Check for SHIPPED plans not moved to completed/
    for plan_id, plan_state in state.get("plans", {}).items():
        if plan_state.get("status") == "SHIPPED":
            if not (plans_dir / "completed" / f"{plan_id}.md").exists():
                print(f"UNARCHIVED: {plan_id} is SHIPPED but not in completed/")
```

### 5. Commit and Push

If changes exist:

```bash
# Stage all relevant changes
git add -A

# Commit with janitor message
git commit -m "chore: janitor cleanup - remove temp files, sync state"

# Push to remote
git push
```

## Output Format

```
## Janitor Report

### Cleaned Up
- Removed: 15 __pycache__ directories
- Removed: 3 .pyc files
- Removed: 2 SQLite journal files

### Archived
- Moved PLAN-2025-023.md to completed/
- Moved PLAN-2025-024.md to completed/

### Git Operations
- Committed: 5 files
- Pushed to: origin/main

### Warnings
- ⚠️ Found 2 orphaned state entries (cleaned)
- ⚠️ Found uncommitted changes in stellaris/ (committed)

### Status
✅ Environment clean
```

## Safety Rules

**NEVER delete:**
- `node_modules/` directories (required for builds)
- `.venv/` or `venv/` directories (Python environments)
- `.git/` directory
- Any file in `inbox/` unless explicitly orphaned
- Production database files (`.db` without temp suffixes)
- Configuration files (`.env`, `*.json`, `*.toml`, `*.yaml`)

**ALWAYS preserve:**
- Source code files (`.py`, `.ts`, `.tsx`, `.js`, `.jsx`)
- Documentation (`.md`)
- Test files
- Migration files
- Git history

## Integration with TPM Completion

When invoked after TPM orchestrator completes:

1. **Archive the completed plan** to `inbox/plans/completed/`
2. **Update `.state.json`** with completion timestamp
3. **Clean up branch** if feature branch was used
4. **Remove any temp files** created during execution
5. **Commit and push** all changes
