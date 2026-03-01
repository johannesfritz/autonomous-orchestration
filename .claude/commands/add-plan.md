Add one or more development plans to the portfolio queue and trigger auto-execution.

Usage: /add-plan <plan-file> [plan-file2] [plan-file3] ...
Examples:
  /add-plan PLAN-feature-a.md                          # Single plan
  /add-plan PLAN-feature-a.md PLAN-feature-b.md        # Multiple plans
  /add-plan *.md                                        # Glob pattern (all .md in Inbox)

Expects plan files to exist in inbox/ or inbox/plans/ directory.

## Multi-Plan Benefits

Adding multiple plans in one command:
- **No waiting** - Don't need to wait for each plan's ingestion to complete
- **Better conflict detection** - Portfolio Manager sees all plans at once
- **Batch efficiency** - Single risk assessment pass, single dashboard update
- **Intra-batch conflicts** - Detects conflicts between the new plans themselves

## What This Command Does

### Step 0: File Normalization (BEFORE invoking Portfolio Manager)

**For EACH plan file** (processed sequentially to avoid ID collisions):

If the plan file is NOT in `inbox/plans/`:
1. **Check for ID conflicts** - If plan ID already exists in completed/ or plans/, assign next available ID (PLAN-YYYY-NNN)
2. **Move file** to `inbox/plans/PLAN-YYYY-NNN.md`
3. **Update ID** in the plan file header to match filename
4. **Delete the original file** to avoid duplicates
5. **Track the normalized path** for batch submission to Portfolio Manager

**Critical for multi-plan:** Increment the NNN counter after each assignment to prevent ID collisions within the batch.

This ensures all plans follow consistent naming and location conventions.

### Step 1: Invoke Portfolio Manager

Portfolio Manager will:
   - Parse plan metadata (dependencies, files, workstreams)
   - Invoke Risk Manager for risk assessment (MANDATORY)
   - Check for conflicts with existing plans
   - Estimate costs and benefits
   - Add to execution queue
   - Update PORTFOLIO_STATUS.md dashboard
   - **Spawn TPM orchestrator in background** for ready plans (risk < 7, no blockers)
3. Return analysis summary immediately (execution continues in background)

## Background Execution

Ready plans (risk < 7, no blocking dependencies) are auto-executed:
- TPM orchestrator spawns asynchronously on feature branch
- Your command line returns immediately
- Execution continues in parallel within the same session
- Check progress via `/portfolio` or `/plan-status <id>`

**IMPORTANT:** "Background" means async within the current Claude session. If you close the terminal or Claude Code, background agents stop. Keep the session active until plans complete, or use tmux/screen for persistence.

High-risk plans (risk ≥ 7) are queued but NOT auto-executed - they require manual approval first.

## Workflow

```
/add-plan PLAN-feature-a.md                    → Single plan
/add-plan PLAN-a.md PLAN-b.md PLAN-c.md        → Batch of plans
/portfolio                                      → Check progress anytime
```

## Execution Instructions

**BEFORE invoking Portfolio Manager**, perform file normalization for ALL files:

### Step 1: Expand Input (handle globs)

1. Parse the argument(s) to get list of plan files
2. If glob pattern (e.g., `*.md`), expand to matching files in `inbox/`
3. Validate each file exists

### Step 2: Sequential Normalization (prevents ID collisions)

For EACH plan file in order:

1. Check existing plan IDs in `inbox/plans/` and `inbox/plans/completed/`
2. Find max NNN value across all existing PLAN-YYYY-NNN files
3. If plan needs new ID:
   - Assign PLAN-YYYY-(max+1).md
   - Increment max for next file in batch
4. Copy file to `inbox/plans/PLAN-YYYY-NNN.md`
5. Edit the ID in the new file to match filename
6. Delete the original file
7. Add normalized path to `normalized_files` list

### Step 3: Single Portfolio Manager Invocation

Use the Task tool with subagent_type='portfolio-manager' and prompt:

'Add the following plans to the portfolio (BATCH SUBMISSION):

Plans: {comma-separated list of normalized_plan_files}

Steps:
1. Read and parse ALL plan files
2. For EACH plan, invoke Risk Manager for risk assessment (MANDATORY)
3. Check for conflicts:
   - Between new plans and existing plans
   - Between new plans themselves (INTRA-BATCH CONFLICTS)
4. Update state file (.state.json) and dashboard (PORTFOLIO_STATUS.md)
5. For ALL READY plans (risk < 7, no blocking dependencies):
   - Spawn TPM orchestrators with run_in_background=true
   - Launch multiple in SINGLE message for parallelism
   - Update plan status to EXECUTING
6. Return batch analysis summary

IMPORTANT:
- Process ALL plans before returning
- Spawn TPM orchestrators for ready plans BEFORE returning
- Use run_in_background=true so execution continues while command line returns
- Report any intra-batch conflicts found'

### Error Handling

If some files fail normalization:
- Continue with valid files
- Report failures to user
- Don't invoke Portfolio Manager if ALL files fail
