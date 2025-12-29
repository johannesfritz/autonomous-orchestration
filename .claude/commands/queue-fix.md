Queue a bug fix or hotfix to the portfolio manager pipeline for background execution.

Usage: /queue-fix [optional description]
Example: /queue-fix the vocabulary search is returning duplicate results
Example: /queue-fix

This command activates the **queue-fix** skill, which:

1. Asks whether to queue (default) or execute live
2. Gathers minimal fix details if needed
3. Creates a HOTFIX-YYYY-NNN.md plan
4. Submits to Portfolio Manager for autonomous execution
5. Frees your command line immediately

**Hotfixes are critical priority** - they jump the queue ahead of regular plans.

---

If a description is provided, use it as the initial context. Otherwise, ask the user what needs to be fixed.

Invoke the queue-fix skill using:
```
Use the Skill tool with skill='queue-fix'
```

The skill will handle the rest: gathering details, creating the plan, and submitting to the portfolio.
