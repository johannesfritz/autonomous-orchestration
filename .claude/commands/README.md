# Slash Commands

This directory contains command definitions for Claude Code slash commands.

## Documentation Search Commands

### /sync-docs

Re-index all documentation for semantic search.

Triggers the documentation indexing pipeline to:
- Parse all CLAUDE.md files and .claude/rules/*.md files
- Extract completed development plans
- Generate embeddings using OpenAI
- Store in Qdrant "documentation" collection

**Usage:**
```bash
/sync-docs
```

**When to use:**
- After adding new documentation files
- After updating existing CLAUDE.md files
- After completing development plans
- When search results seem stale

### /search-docs

Search documentation using semantic search.

Find relevant documentation sections using natural language queries.

**Usage:**
```bash
# Search all documentation (default)
/search-docs "how to deploy to production"

# Search only CLAUDE.md files
/search-docs "testing strategy" --docs

# Search only completed plans
/search-docs "authentication implementation" --plans
```

**Search modes:**
- `--docs` - Search CLAUDE.md and .claude/rules/*.md files only
- `--plans` - Search completed development plans only
- `--all` - Search everything (default)

**Output format:**
- Relevance score (0-100)
- File path (relative to repo root)
- Section title
- Content snippet (first 100 characters)

## Portfolio Management Commands

### /portfolio
Show the portfolio dashboard (all plans, status, dependencies, conflicts).

### /add-plan
Add a new development plan to the queue and auto-execute if ready.

### /plan-status
Show detailed status for a specific plan.

### /execute-plan
Force-execute a specific plan immediately.

### /prioritize
Override plan priority (critical/high/medium/low).

### /show-conflicts
Display all resource conflicts across plans.

## Product Discovery Commands

### /discovery
Run full discovery flow (Product Manager → UX Researcher → Technical PM → create plan).

### /intake
Process user feedback from Stellaris production database.

### /prioritize-backlog
Apply prioritization framework (RICE/ICE/MoSCoW) to backlog.

### /spike
Start objective-driven technical investigation.

### /adr
Create Architecture Decision Record for a technical decision.

## Development Commands

### /queue-fix
Queue a bug fix or hotfix for background execution.

## Operations Commands

### /rollback
Rollback a deployed change.

### /force-git
Force git operation (bypass hooks).

### /sync-state
Synchronize state files.

### /audit
Generate audit report.

### /costs
Show API cost analysis.

### /learning
Show learning insights from conflict resolution.

### /budget-override
Override budget constraints for a plan.

---

## Adding New Commands

To add a new slash command:

1. Create a markdown file in this directory: `command-name.md`
2. Document the command behavior and usage
3. If the command requires a script, add it to `.claude/scripts/`
4. Update this README with the new command
