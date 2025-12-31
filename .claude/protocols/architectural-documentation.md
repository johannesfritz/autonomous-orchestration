# Architectural Documentation Protocol

**Injected when:** Solutions Architect agent starts

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
