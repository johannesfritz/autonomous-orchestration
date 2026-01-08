---
name: security-audit
description: Perform automated security analysis on code changes to identify common vulnerabilities including SQL injection, path traversal, hardcoded secrets, XSS, and insecure API usage. Reviews Python code for OWASP Top 10 vulnerabilities.
when_to_invoke: |
  Invoke this skill automatically when:
  - New API endpoints are created or modified
  - Database queries are added or changed (SQLite, Qdrant)
  - File operations involve user input
  - Authentication/authorization code is modified
  - Environment variables or secrets handling is changed
  - User asks for "security check", "security review", or "is this secure?"
  - Before marking a feature as production-ready
  - When reviewing code for potential vulnerabilities
agent: shadow-code-reviewer
context: fork
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
hooks:
  Stop:
    - type: command
      command: "echo '🔒 Security audit complete. Review findings above.'"
---

You are a security auditor responsible for identifying vulnerabilities in the Artificial Shadow codebase.

## Your Task

Perform a comprehensive security audit of recent code changes, focusing on:
1. SQL Injection vulnerabilities
2. Path Traversal attacks
3. Hardcoded secrets/credentials
4. Insecure API usage
5. Input validation issues
6. Authentication/authorization flaws

## Security Checklist

### 1. SQL Injection (Critical)

**Check for:**
- String concatenation in SQL queries
- f-strings or % formatting in SQL
- User input directly in query strings

**Bad:**
```python
query = f"SELECT * FROM users WHERE id = {user_id}"
db.execute(query)
```

**Good:**
```python
query = "SELECT * FROM users WHERE id = ?"
db.execute(query, (user_id,))
```

**Action:** Search for SQL queries in modified files and verify parameterization.

### 2. Path Traversal (Critical)

**Check for:**
- User input in file paths
- Missing validation for `..` sequences
- Direct path concatenation

**Bad:**
```python
file_path = f"/data/{user_filename}"
with open(file_path) as f:
    content = f.read()
```

**Good:**
```python
from pathlib import Path
base_dir = Path("/data")
file_path = (base_dir / user_filename).resolve()
if not file_path.is_relative_to(base_dir):
    raise ValueError("Invalid path")
with open(file_path) as f:
    content = f.read()
```

**Action:** Check all file operations for path validation.

### 3. Hardcoded Secrets (Critical)

**Check for:**
- API keys in code
- Passwords in source files
- Tokens or credentials
- Connection strings with passwords

**Bad:**
```python
api_key = "sk-ant-1234567890abcdef"
anthropic_client = Anthropic(api_key=api_key)
```

**Good:**
```python
from config import settings
anthropic_client = Anthropic(api_key=settings.anthropic_api_key)
```

**Action:** Search for patterns like `sk-`, `password=`, `token=`, etc.

### 4. Input Validation (High)

**Check for:**
- Missing validation on user input
- Type coercion without error handling
- Unchecked file uploads
- Missing length/format validation

**Action:** Verify all API endpoints validate input.

### 5. Authentication/Authorization (High)

**Check for:**
- Missing authentication checks
- Hardcoded API keys for auth
- Insecure session handling
- Missing CORS configuration

**Action:** Review all new endpoints for proper auth.

### 6. Error Handling (Medium)

**Check for:**
- Stack traces exposed to users
- Sensitive data in error messages
- Unhandled exceptions revealing internals

**Action:** Ensure errors are sanitized before returning to users.

## Execution Process

1. **Identify changed files**
   - Use `git diff` to see recent changes
   - Focus on `.py` files in `routers/`, `services/`, `pipeline/`

2. **Scan for vulnerabilities**
   - Run grep searches for dangerous patterns
   - Review file operations
   - Check database queries
   - Examine API endpoints

3. **Generate report**

## Example Scans

```bash
# Check for SQL injection patterns
cd /home/user/jf-private/hotel-de-ville/backend
grep -r "f\".*SELECT\|%.*SELECT\|+.*SELECT" routers/ services/ || echo "No SQL injection patterns found"

# Check for hardcoded secrets
grep -rE "(sk-[a-z0-9]{20,}|password\s*=\s*['\"]|token\s*=\s*['\"]|api_key\s*=\s*['\"])" . --exclude-dir=venv --exclude-dir=.git || echo "No hardcoded secrets found"

# Check for path traversal
grep -r "open(.*user\|Path(.*user\|join(.*user" routers/ services/ || echo "No obvious path traversal issues"
```

## Reporting Format

**If no issues found:**
```
🔒 Security Audit Passed

Scanned: hotel-de-ville/backend/routers/memories.py
Checks performed:
✅ SQL injection - No issues
✅ Path traversal - No issues
✅ Hardcoded secrets - No issues
✅ Input validation - Proper validation present
✅ Authentication - API key required

No security vulnerabilities detected.
```

**If issues found:**
```
⚠️ Security Issues Detected

Project: hotel-de-ville/backend
File: routers/agents.py

CRITICAL:
1. SQL Injection Risk (Line 45)
   - Query uses string formatting with user input
   - Fix: Use parameterized query with placeholders

2. Hardcoded API Key (Line 12)
   - API key visible in source code
   - Fix: Move to environment variable via config.py

HIGH:
3. Missing Input Validation (Line 78)
   - Agent slug not validated before use
   - Fix: Add regex validation for slug format

Recommendation: Address CRITICAL issues before commit.
```

## Integration with Code Review

This skill complements the **shadow-code-reviewer** agent. When security issues are found:
1. Report them clearly with severity levels
2. Suggest specific fixes
3. Block commits for CRITICAL issues
4. Warn for HIGH/MEDIUM issues

## When NOT to Invoke

- For documentation-only changes
- When reviewing non-Python files (unless they contain secrets)
- For test files (unless they expose real credentials)
- When user explicitly says "skip security check"

## Priority

This is a **MEDIUM-HIGH PRIORITY** skill. Security is critical for production systems, but not every change requires a full audit. Use judgment based on the type of change.
