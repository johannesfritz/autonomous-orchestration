# Project Folder Structure (MANDATORY)

**Applies to:** Any new analytical task, research project, or deliverable that produces 3+ files.

## Naming Convention

`YYMMDD-descriptive-name/` — the date is when the project started.

Examples: `260228-alternative-market-mapping/`, `260301-india-fta-analysis/`, `260215-cbam-impact-assessment/`

## Where to Create

In the workspace that owns the domain:
- `jf-ceo/` for CEO operations and business development
- `jf-thought/sgept-analytics/` for analytical work
- `jf-dev/` for software projects

## Standard Subfolders

| Folder | Purpose | Required? |
|---|---|---|
| `code/` | Scripts, notebooks, any programmatic work | If code exists |
| `data/` | Input data (raw and processed). Original files preserved, processed versions alongside. | If data exists |
| `results/` | All outputs: graphs, tables, Excel sheets, writing, deliverables | Yes |
| `lit/` | Literature, references, source documents | Only when relevant material exists |
| `docs/` | Documentation. Must contain `process-log.md`. | Yes |

Do not create empty subfolders preemptively. Create them when the first file goes in.

## Process Log (`docs/process-log.md`)

Required for every project folder. This is the sequential record of the project and the handoff mechanism between sessions.

### Structure

```
# [Project Title]
**Started:** YYYY-MM-DD
**Purpose:** [One sentence — what are we trying to find out / produce?]

## Status
[Current state. What's done, what's next. A human sees the situation in 5 seconds.]

## Log

### YYYY-MM-DD — [Session summary]
- **Attempted:** [What was tried]
- **Produced:** [File paths of outputs]
- **Learned:** [Key findings or dead ends]
- **Next:** [What the next session should do]
```

### Cold-Start Requirement

A fresh agent reads only `docs/process-log.md` and can pick up where the last session left off. Same standard as the state-file-protocol Cold-Start Test. If the log fails this test, it is incomplete.

## When NOT to Create a Project Folder

Single-file tasks (a quick CSV transform, a one-off email draft, a simple lookup) that do not produce multiple artifacts. The threshold is 3+ files — below that, the overhead is not justified.
