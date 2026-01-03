# Architectural Documentation Protocol

**Injected when:** Solutions Architect agent starts

---

## Mandatory Search Before ADR Creation

**Before creating any ADR, you MUST search Qdrant for related architectural decisions.**

Search for:
- [ ] **Related past ADRs** - Check for similar technology/pattern decisions
- [ ] **Existing architectural patterns** - Verify consistency with established approaches
- [ ] **Past trade-off analyses** - Learn from similar evaluations
- [ ] **Lessons learned** - Discover challenges from related decisions

**Query patterns:**
```
"Architectural decisions about [technology/pattern]"
"ADRs for [system component]"
"Design patterns for [capability]"
"[Technology A] vs [Technology B] comparison"
```

**Document findings in every ADR:**
```markdown
## Related ADRs
- ADR-XXX: [Title] ([Date]) - [How it relates]
- ADR-YYY: [Title] ([Date]) - [How it relates]

## Consistency Analysis
This decision [aligns with / diverges from] established patterns:
- [Analysis of consistency with past decisions]

## Divergence Justification (if applicable)
[If this diverges from past patterns, explain why]
```

See `.claude/protocols/institutional-memory-protocol.md` for complete requirements.

---

## ADR Triggers

Create an ADR (Architecture Decision Record) when:

### 1. Technology Decisions

- [ ] **Introducing a new library or framework**
- [ ] **Choosing between competing technologies**
- [ ] **Deprecating existing technology**

### 2. Pattern Decisions

- [ ] **Establishing a new architectural pattern**
- [ ] **Changing how systems communicate**
- [ ] **Modifying data flow**

### 3. Significant Trade-offs

- [ ] **Security vs. usability decisions**
- [ ] **Performance vs. maintainability decisions**
- [ ] **Cost vs. capability decisions**

### 4. Reversibility Check

- [ ] **Is this decision hard to reverse?**
- [ ] **Will future developers need to know why?**
- [ ] **Does this constrain future options?**

## ADR Quality Checklist

- [ ] Context explains the "why" clearly
- [ ] At least 2-3 options were considered
- [ ] Decision drivers are explicit
- [ ] Consequences (positive and negative) are documented
- [ ] Links to related decisions included

## Remember

- ADRs are for decisions, not descriptions
- Document the "why" more than the "what"
- Future you will thank present you

---

## Integration with Workflow

This protocol is automatically injected when the Solutions Architect agent starts (via SubagentStart hook in `.claude/settings.json`).
