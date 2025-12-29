# Customization Guide

How to adapt the orchestration system for your project.

---

## Directory Structure

### Default Structure

```
your-project/
├── .claude/           # Configuration
├── inbox/
│   ├── plans/         # Active plans
│   └── PORTFOLIO_STATUS.md
```

### Changing Plan Location

Edit Portfolio Manager agent (`.claude/agents/portfolio-manager.md`) to scan a different directory:

```markdown
Scan for plans in: `your-custom-path/plans/*.md`
```

Update state file paths accordingly in the agent's instructions.

---

## Adding Custom Agents

### Step 1: Create Agent File

```bash
touch .claude/agents/my-custom-agent.md
```

### Step 2: Add Content

```markdown
---
name: my-custom-agent
description: What this agent does
model: sonnet  # sonnet, opus, or haiku
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---

You are the [Role] agent for [Project].

## Your Responsibilities

1. First responsibility
2. Second responsibility

## Key Behaviors

- Behavior one
- Behavior two

## Technical Knowledge

- Technology stack details
- Project-specific patterns
```

### Step 3: Use in Plans

Reference your agent in workstreams:

```markdown
### Custom Workstream
- Agent: my-custom-agent
- Files: relevant/files.ts
```

---

## Modifying Existing Agents

### Change Model

Edit the `model` field in YAML frontmatter:

```yaml
---
name: artificial-shadow-dev
model: opus  # Changed from sonnet
---
```

### Add Tools

Edit the `tools` list:

```yaml
tools:
  - Read
  - Write
  - Edit
  - Bash
  - WebFetch  # Added
```

### Adjust Instructions

Modify the markdown body to change agent behavior.

---

## Customizing Permissions

### Add Project-Specific Permissions

Edit `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "// Your additions",
      "Bash(your-custom-tool:*)",
      "Bash(./scripts/deploy.sh:*)"
    ]
  }
}
```

### Use Local Overrides

Create `.claude/settings.local.json` for machine-specific permissions (not committed to git):

```json
{
  "permissions": {
    "allow": [
      "Bash(./venv/bin/pytest:*)",
      "Bash(docker compose:*)"
    ]
  }
}
```

---

## Modifying Hooks

### Add New Hook

Edit `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cat $CLAUDE_PROJECT_DIR/.claude/protocols/your-protocol.md"
          }
        ]
      }
    ]
  }
}
```

### Create Custom Hook Script

```bash
# .claude/hooks/my-detector.sh
#!/bin/bash

USER_PROMPT="$CLAUDE_USER_PROMPT"

if echo "$USER_PROMPT" | grep -qi "my-trigger-phrase"; then
    cat "$CLAUDE_PROJECT_DIR/.claude/protocols/my-protocol.md"
fi
```

Make executable:
```bash
chmod +x .claude/hooks/my-detector.sh
```

---

## Customizing Risk Thresholds

Edit `.claude/agents/risk-manager.md`:

### Change Escalation Threshold

Find and modify:

```markdown
## Decision Rules

If Overall >= 6/10 → Requires manual approval  # Changed from 7
```

### Adjust Dimension Weights

```markdown
## Score Calculation

Overall = (Disruption × 0.25) + (Controllability × 0.25) +
          (Liability × 0.30) + (AI × 0.20)

# Adjust weights as needed
```

### Add Domain-Specific Checks

```markdown
## Domain-Specific Considerations

For financial features:
- Check PCI DSS compliance
- Require security team review

For healthcare features:
- Check HIPAA implications
- Require privacy review
```

---

## Customizing Quality Gates

Edit `.claude/agents/tpm-orchestrator.md`:

### Add Custom Gate

```markdown
## Quality Gates

1. All workstreams complete
2. Tests pass
3. Code review approved
4. Security audit clean
5. **YOUR CUSTOM GATE HERE**
6. Git workflow success
```

### Skip Optional Gates

Mark gates as conditional:

```markdown
## Quality Gates

1. All workstreams complete (REQUIRED)
2. Tests pass (REQUIRED)
3. Code review approved (REQUIRED)
4. Security audit (if security-sensitive files changed)
5. Performance test (if performance-critical files changed)
```

---

## Adding New Skills

### Step 1: Create Skill Directory

```bash
mkdir -p .claude/skills/my-skill
```

### Step 2: Create SKILL.md

```markdown
---
name: my-skill
description: What this skill does
triggers:
  - "my trigger phrase"
  - "another trigger"
---

You are executing the my-skill skill.

## What to Do

1. Step one
2. Step two

## Output Format

Provide result in this format...
```

### Step 3: Add to Permissions (if needed)

```json
{
  "permissions": {
    "allow": [
      "Skill(my-skill)"
    ]
  }
}
```

---

## Project-Specific Protocols

### Create New Protocol

```bash
touch .claude/protocols/my-project-standards.md
```

Content example:

```markdown
# My Project Standards

## Before Every Code Change

- [ ] Check logging conventions
- [ ] Verify error handling pattern
- [ ] Ensure metrics are updated

## Code Style

- Use camelCase for functions
- Use PascalCase for classes
- Maximum 100 lines per file
```

### Inject via Hook

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cat $CLAUDE_PROJECT_DIR/.claude/protocols/my-project-standards.md"
          }
        ]
      }
    ]
  }
}
```

---

## Testing Changes

After customization:

1. **Test hooks:**
   ```
   Make a small edit and verify protocols are injected
   ```

2. **Test agents:**
   ```
   Invoke agent directly and verify behavior
   ```

3. **Test full flow:**
   ```
   /add-plan TEST-PLAN.md
   /portfolio
   ```

4. **Check state files:**
   ```bash
   cat inbox/plans/.state.json
   ```
