---
name: static-analysis
description: "Perform automated static code analysis on modified files. Triggers automatically after code changes to catch common issues before QA Lead review. Checks for: code complexity, dead code, type errors, import issues, and style violations. Use when: code files have been modified, before committing changes, as pre-check for QA Lead review, or user asks 'analyze this code' or 'check for issues'."
allowed-tools: Read, Grep, Glob, Bash
model: haiku
---

# Static Analysis Skill

## Purpose

Run automated static analysis tools on modified code to catch issues early:
- Code complexity warnings
- Dead code detection
- Type errors (Python, TypeScript)
- Import/dependency issues
- Style violations

**Goal:** Surface issues BEFORE the more expensive QA Lead review.

---

## When to Trigger

Auto-trigger when:
- Python files (*.py) modified
- TypeScript/JavaScript files (*.ts, *.tsx, *.js, *.jsx) modified
- User explicitly requests "analyze code" or "static analysis"

---

## Analysis Protocol

### Step 1: Identify Modified Files

```bash
# Get list of modified files
git diff --name-only HEAD~1 HEAD  # Recent commit
git diff --name-only              # Uncommitted changes

# Filter by language
PYTHON_FILES=$(echo "$MODIFIED" | grep -E '\.py$')
TS_FILES=$(echo "$MODIFIED" | grep -E '\.(ts|tsx|js|jsx)$')
```

### Step 2: Python Analysis

```bash
# Run ruff (fast linter)
if command -v ruff &> /dev/null; then
    ruff check $PYTHON_FILES --output-format=json
fi

# Run mypy (type checker)
if command -v mypy &> /dev/null; then
    mypy $PYTHON_FILES --no-error-summary --show-column-numbers
fi

# Run pylint (comprehensive)
if command -v pylint &> /dev/null; then
    pylint $PYTHON_FILES --output-format=json --disable=C0114,C0115,C0116
fi
```

### Step 3: TypeScript/JavaScript Analysis

```bash
# Run eslint
if command -v npx &> /dev/null; then
    npx eslint $TS_FILES --format=json
fi

# Run TypeScript compiler check
if [ -f "tsconfig.json" ]; then
    npx tsc --noEmit --pretty false
fi
```

### Step 4: Complexity Analysis

```bash
# Python complexity (radon)
if command -v radon &> /dev/null; then
    radon cc $PYTHON_FILES -s -j  # Cyclomatic complexity, JSON output
fi

# Check function length manually
for file in $PYTHON_FILES; do
    # Flag functions > 50 lines
    grep -n "def " "$file" | while read line; do
        # Estimate function length
    done
done
```

### Step 5: Dead Code Detection

```bash
# Python (vulture)
if command -v vulture &> /dev/null; then
    vulture $PYTHON_FILES --min-confidence 80
fi

# Check for unused imports
ruff check $PYTHON_FILES --select=F401 --output-format=json
```

---

## Output Format

Report findings in structured format for TPM Orchestrator consumption:

```json
{
  "analysis_complete": true,
  "files_analyzed": 5,
  "tools_run": ["ruff", "mypy", "eslint", "tsc"],

  "summary": {
    "errors": 2,
    "warnings": 8,
    "info": 15
  },

  "findings": [
    {
      "file": "src/api/auth.py",
      "line": 42,
      "column": 10,
      "severity": "error",
      "tool": "mypy",
      "code": "arg-type",
      "message": "Argument 1 has incompatible type 'str'; expected 'int'"
    },
    {
      "file": "src/api/auth.py",
      "line": 67,
      "severity": "warning",
      "tool": "ruff",
      "code": "F401",
      "message": "Unused import: 'json'"
    }
  ],

  "complexity": {
    "high_complexity_functions": [
      {"file": "src/api/handler.py", "function": "process_request", "complexity": 15}
    ]
  },

  "dead_code": [
    {"file": "src/utils.py", "line": 120, "name": "unused_function", "confidence": 90}
  ],

  "recommendation": "FIX_REQUIRED | WARNINGS_ONLY | CLEAN"
}
```

---

## Severity Classification

| Severity | Meaning | Action Required |
|----------|---------|-----------------|
| **error** | Code will fail or has bugs | Must fix before commit |
| **warning** | Potential issues, code smells | Should fix |
| **info** | Style issues, minor improvements | Optional fix |

---

## Integration with QA Lead

Static Analysis runs BEFORE QA Lead:

```
Code Changes → Static Analysis → QA Lead → Tests → Ship
```

Benefits:
- Catches obvious issues cheaply (Haiku model)
- QA Lead can focus on logic and integration
- Faster feedback loop for developers

---

## Tool Installation Check

If tools are missing, report which are unavailable:

```bash
MISSING_TOOLS=()

command -v ruff &> /dev/null || MISSING_TOOLS+=("ruff")
command -v mypy &> /dev/null || MISSING_TOOLS+=("mypy")
command -v pylint &> /dev/null || MISSING_TOOLS+=("pylint")
# ... etc

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "Warning: Some analysis tools not available: ${MISSING_TOOLS[*]}"
    echo "Install with: pip install ruff mypy pylint radon vulture"
fi
```

---

## Remember

- **Run quickly** - Use Haiku model, fast tools only
- **Be actionable** - Include file, line, and fix suggestions
- **Don't block on style** - Info-level issues shouldn't block commit
- **Report unavailable tools** - User can install if desired
