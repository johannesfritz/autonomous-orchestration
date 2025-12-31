Apply prioritization framework to the product backlog.

## What This Command Does

This command scores and ranks backlog items using RICE, ICE, or MoSCoW frameworks to create a data-driven, prioritized backlog.

## Usage

```
/prioritize-backlog
```

**Framework options:**
```
/prioritize-backlog rice      # Use RICE framework (thorough, strategic)
/prioritize-backlog ice       # Use ICE framework (fast, good enough) - DEFAULT
/prioritize-backlog moscow    # Use MoSCoW for release planning
```

## Workflow

1. **Read current intake items** from `00 Inbox/feedback/`
2. **Read existing backlog** from `00 Inbox/backlog/`
3. **Ask which framework to use** if not specified (default: ICE for quick triage)
4. **Invoke prioritization-framework skill** to score items
5. **Output ranked backlog** to `00 Inbox/backlog/prioritized-backlog.md`
6. **Highlight top 3 items** ready for technical scoping

## Frameworks

### RICE (Strategic, thorough)
- **Reach:** Users affected per quarter
- **Impact:** Value per user (0.25-3 scale)
- **Confidence:** Certainty of estimates (50%-100%)
- **Effort:** Person-days to build
- **Formula:** (Reach × Impact × Confidence) / Effort

**Use when:** Roadmap planning, major decisions, stakeholder alignment needed

### ICE (Fast, good enough)
- **Impact:** User value (1-10)
- **Confidence:** Certainty of success (1-10)
- **Ease:** Inverse of effort (1-10)
- **Formula:** (Impact + Confidence + Ease) / 3

**Use when:** Quick triage, daily prioritization, backlog grooming

### MoSCoW (Categorical)
- **Must Have:** Non-negotiable (60% max capacity)
- **Should Have:** Important but deferrable
- **Could Have:** Nice-to-have (20% buffer)
- **Won't Have:** Out of scope

**Use when:** Release planning, sprint scope definition

## Output

After running `/prioritize-backlog`, you will receive:

- **Ranked backlog:** Sorted by score (highest priority first)
- **Top 3 highlights:** Features ready for Technical PM scoping
- **Deferred items:** Low-priority features with reasoning
- **Backlog file:** `00 Inbox/backlog/prioritized-backlog.md` (RICE/ICE) or `00 Inbox/backlog/release-plan-[name].md` (MoSCoW)

## Example

```
User: /prioritize-backlog ice