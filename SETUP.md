# Detailed Setup Guide

This guide covers complete installation and configuration of the autonomous orchestration system.

---

## Prerequisites

- Claude Code CLI installed and configured
- Git repository for your project
- API keys: `ANTHROPIC_API_KEY` (required), `OPENAI_API_KEY` (optional, for embeddings)

---

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/johannesfritz/autonomous-orchestration.git
cd autonomous-orchestration
```

### Step 2: Copy to Your Project

```bash
# Set your project path
PROJECT_DIR="/path/to/your/project"

# Copy .claude directory (contains all configuration)
cp -r .claude "$PROJECT_DIR/"

# Copy inbox structure (plan templates and state files)
cp -r inbox "$PROJECT_DIR/"

# Copy docs for reference (optional)
cp -r docs "$PROJECT_DIR/"
```

### Step 3: Initialize State Files

```bash
cd "$PROJECT_DIR"

# Remove .example suffix from state files
mv inbox/plans/.state.json.example inbox/plans/.state.json
mv inbox/plans/.conflict_history.json.example inbox/plans/.conflict_history.json
mv inbox/PORTFOLIO_STATUS.md.example inbox/PORTFOLIO_STATUS.md
```

### Step 4: Make Scripts Executable

```bash
chmod +x .claude/hooks/*.sh
chmod +x .claude/scripts/*.py
```

### Step 5: Customize settings.local.json (Optional)

```bash
# Create local settings from example
cp .claude/settings.local.json.example .claude/settings.local.json

# Edit to add project-specific permissions
```

---

## Configuration

### Adjusting Permissions

The `settings.json` file contains pre-approved tool permissions. Add or remove as needed:

```json
{
  "permissions": {
    "allow": [
      "Bash(your-custom-tool:*)",
      "// Add project-specific tools here"
    ]
  }
}
```

### Customizing Hooks

Hooks in `settings.json` trigger at specific lifecycle events:

| Hook | When | Purpose |
|------|------|---------|
| `PreToolUse(Edit\|Write)` | Before code changes | Inject quality protocols |
| `PreToolUse(git add/commit)` | Before git staging | Run secrets scanner (v1.1) |
| `PreToolUse(git push)` | Before push | Pre-push secrets warning (v1.1) |
| `PreToolUse(rm -rf)` | Before deletion | Destructive op warning (v1.1) |
| `PreToolUse(chmod)` | Before permission change | Permission warning (v1.1) |
| `PostToolUse(Edit\|Write)` | After code changes | Remind to test |
| `SubagentStart(portfolio-manager)` | PM starts | Inject risk requirements |
| `SubagentStart(tpm-orchestrator)` | TPM starts | Verify risk assessment |
| `SubagentStart(shadow-code-reviewer)` | Reviewer starts | Inject verification protocol |
| `SubagentStop(tpm-orchestrator)` | TPM ends | Trigger state updates |

### Adjusting Risk Thresholds

In `.claude/agents/risk-manager.md`, you can adjust:

- Escalation threshold (default: risk >= 7/10)
- Auto-approval threshold (default: risk < 7/10)
- Individual dimension weights

---

## Directory Structure After Installation

```
your-project/
├── .claude/
│   ├── settings.json           # Main config (hooks, permissions)
│   ├── settings.local.json     # Local overrides (optional)
│   ├── agents/                 # 10 agent definitions
│   ├── skills/                 # 7 skill directories
│   ├── commands/               # 13 slash commands
│   ├── protocols/              # 6 quality protocols
│   ├── hooks/                  # 2 detection scripts
│   └── scripts/                # 1 Python secrets scanner
├── inbox/
│   ├── plans/
│   │   ├── PLAN-TEMPLATE.md
│   │   ├── HOTFIX-TEMPLATE.md
│   │   ├── .state.json
│   │   ├── .conflict_history.json
│   │   └── completed/
│   ├── system_state.json       # State persistence (v1.1)
│   ├── audit_log.jsonl         # Audit trail (v1.1)
│   └── PORTFOLIO_STATUS.md
└── docs/                       # Reference documentation
```

---

## Verification

### Test the Setup

1. **Check hooks are configured:**
   ```bash
   cat .claude/settings.json | grep -A5 "hooks"
   ```

2. **Verify agents exist:**
   ```bash
   ls .claude/agents/
   # Should show: portfolio-manager.md, tpm-orchestrator.md, risk-manager.md, etc.
   ```

3. **Test a slash command:**
   ```
   /portfolio
   ```
   Should display the empty dashboard.

4. **Create a test plan:**
   ```bash
   cp inbox/plans/PLAN-TEMPLATE.md inbox/plans/PLAN-TEST-001.md
   # Edit with a simple task
   /add-plan PLAN-TEST-001.md
   ```

---

## Troubleshooting

### "Command not found" for hooks

```bash
# Make hooks executable
chmod +x .claude/hooks/*.sh
```

### "Protocol file not found"

Check that `$CLAUDE_PROJECT_DIR` environment variable is set correctly, or update paths in `settings.json`.

### Plans not auto-executing

1. Check risk score - plans with risk >= 7 require manual approval
2. Check for blocking dependencies
3. Verify Portfolio Manager agent is correctly configured

### State file sync issues

```bash
# Reset state files
rm inbox/plans/.state.json
cp inbox/plans/.state.json.example inbox/plans/.state.json
```

---

## Next Steps

1. Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand the system
2. Review [AGENTS.md](docs/AGENTS.md) to see agent capabilities
3. Check [WORKFLOWS.md](docs/WORKFLOWS.md) for common patterns
4. See [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) to adapt for your project
