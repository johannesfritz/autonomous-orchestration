# Workspace Hygiene

Before returning results to the user, verify the workspace is clean:

1. **Delete artefacts from failed or superseded runs.** If a script ran with wrong parameters and produced output before being re-run correctly, delete the wrong output.
2. **No temporary files left behind.** Remove any scratch files, debug logs, or intermediate outputs that were only needed during processing.
3. **No empty directories.** If a directory was created but never populated (e.g. from an aborted run), remove it.
4. **Report what you cleaned.** Briefly note any deletions so the user knows what was removed.

This applies to all workspaces (analytics, writing, code). The principle: the user should never have to manually clean up after an agent session.
