Display all resource conflicts across plans in the portfolio.

Show:
- File contention (which plans touch the same files)
- Dependency conflicts (circular dependencies)
- Currently executing plans and what they block
- Proposed conflict resolutions and reasoning

Use the Task tool with subagent_type='portfolio-manager' and prompt='Analyze and display all resource conflicts in the portfolio. For each conflict, show the proposed resolution and reasoning. Include file contention map and dependency graph.'
