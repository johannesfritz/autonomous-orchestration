# Force Git Command

Force a git operation that was blocked by the secrets scanner.

**Usage:** `/force-git <git-command>`

**Example:** `/force-git git push origin main`

## Purpose

This command bypasses the pre-git secrets scanner hook. Use ONLY when:
- You've verified the detected "secrets" are false positives
- The flagged content is intentionally included (e.g., example/test data)
- You understand and accept the security risk

## Workflow

1. User runs git command → Secrets scanner blocks it
2. User reviews the findings and determines they're false positives
3. User runs `/force-git <original-command>`
4. Claude executes the git command WITHOUT running the secrets scanner

## What You Should Do

When the user invokes `/force-git`:

1. **Confirm acknowledgment:**
   ```
   You're about to bypass the secrets scanner for: <command>

   This will skip security checks. Have you reviewed the flagged content
   and confirmed it's safe to commit?
   ```

2. **If user confirms, execute the command directly:**
   - Do NOT invoke the scan-secrets.py hook
   - Execute the git command as requested
   - Log the bypass to audit trail (if enabled)

3. **Report the result:**
   ```
   Executed: <command>
   Note: Secrets scanner was bypassed per your request.

   For future reference, consider:
   - Adding false positives to .gitignore
   - Using environment variables for real secrets
   - Updating the scanner's allow-list
   ```

## Security Notes

- This command creates an audit trail entry
- Repeated use may indicate scanner calibration issues
- Consider updating the scanner's ALLOW_LIST_FILES if false positives are frequent
