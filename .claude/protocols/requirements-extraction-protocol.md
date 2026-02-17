# Requirements Extraction Protocol

**Protocol Name:** `PROTOCOL-REQUIREMENTS-L3`

**Purpose:** Ensure detailed requirements extraction before any development plan executes. This protocol is injected into the Requirements Analyst agent and enforced by hooks.

---

## When This Protocol Applies

This protocol is **MANDATORY** for:
- All plans with complexity ≥ "medium"
- All plans involving modifications to existing code
- All migration projects (framework, language, or architecture changes)
- All plans touching > 5 files

This protocol is **OPTIONAL** for:
- Trivial changes (typos, comments, config)
- Documentation-only changes
- Plans explicitly marked "requirements-complete"

---

## The Two-Loop Clarification System

### Loop 1: Requirements Analyst ↔ Portfolio Manager

**Purpose:** Resolve ambiguities without bothering the user.

```
Requirements Analyst identifies ambiguity
         ↓
Creates Clarification Request
         ↓
Portfolio Manager receives request
         ↓
Portfolio Manager decides:
  - CAN resolve (has authority/knowledge) → Resolves immediately
  - CANNOT resolve (needs human judgment) → Escalates to Loop 2
         ↓
Resolution documented
```

**Portfolio Manager Resolution Authority:**
- Technical defaults (page sizes, cache durations, etc.)
- Framework conventions (naming, structure, etc.)
- Non-breaking implementation details
- Low-impact UI decisions

**Must Escalate to Loop 2:**
- Breaking changes to existing functionality
- User-facing UX decisions
- Architectural decisions with long-term impact
- Anything affecting product philosophy
- Anything involving cost/budget trade-offs

### Loop 2: Portfolio Manager ↔ User (Johannes)

**Purpose:** Get human input for decisions requiring judgment.

```
Portfolio Manager receives escalation from Loop 1
         ↓
Formats question for user clarity
         ↓
Presents options with recommendation
         ↓
User decides
         ↓
Portfolio Manager records decision
         ↓
Returns resolution to Requirements Analyst
```

**User Question Format:**
```markdown
## Decision Needed: [Plan ID]

**Context:** [Brief background]

**Question:** [Clear, specific question]

**Options:**
a) [Option A] - [Pros/Cons]
b) [Option B] - [Pros/Cons]
c) [Option C] - [Pros/Cons]

**Recommendation:** [Which option and why]

**Default if no response:** [What happens if user doesn't respond]

**Blocking:** [Yes/No - can work proceed without this?]
```

---

## Requirements Completeness Checklist

Before marking requirements as complete, verify:

### For Existing Code Modifications

- [ ] **Files inventoried:** All files that will be modified are documented
- [ ] **Functions inventoried:** All functions that will change are documented with current behavior
- [ ] **API contracts documented:** All API endpoints with request/response shapes
- [ ] **Database schema documented:** All tables/models with fields and relationships
- [ ] **UI components documented:** All components with props, state, events
- [ ] **External dependencies documented:** All third-party APIs, libraries, integrations
- [ ] **Error handling documented:** How errors are currently handled
- [ ] **Test coverage documented:** What tests exist, what they cover

### For New Features

- [ ] **User stories complete:** All user stories with acceptance criteria
- [ ] **Functional requirements:** Every feature behavior specified
- [ ] **Non-functional requirements:** Performance, accessibility, security specified
- [ ] **UI specifications:** Every screen, component, interaction documented
- [ ] **API specifications:** Every endpoint with full contract
- [ ] **Data model:** Every entity with fields and relationships
- [ ] **Error states:** Every possible error condition and handling
- [ ] **Edge cases:** Boundary conditions, empty states, max limits

### For Migrations

- [ ] **Source inventory complete:** Every component, route, service in source app(s)
- [ ] **Target mapping complete:** How each source item maps to target
- [ ] **Difference analysis:** What changes between source and target
- [ ] **Data migration plan:** How data moves between systems (if applicable)
- [ ] **Feature parity verification:** Checklist ensuring nothing is lost

---

## Verification Checklist Format

Every requirements analysis MUST produce a verification checklist that QA uses after development:

```markdown
# Verification Checklist: [PLAN-ID]

## Feature: [Feature Name]

### Visual Verification
| Item | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Homepage renders | Chart visible, no errors | | |
| Navigation works | All links functional | | |
| [... one row per visual element ...] | | | |

### Functional Verification
| User Journey | Steps | Expected Result | Actual | Pass/Fail |
|--------------|-------|-----------------|--------|-----------|
| Search for item | 1. Enter term 2. Click search | Results appear | | |
| [... one row per user journey ...] | | | | |

### API Verification
| Endpoint | Request | Expected Response | Actual | Pass/Fail |
|----------|---------|-------------------|--------|-----------|
| GET /api/items | - | 200, Item[] | | |
| [... one row per endpoint ...] | | | | |

### Regression Verification
| Existing Feature | Test | Expected | Actual | Pass/Fail |
|------------------|------|----------|--------|-----------|
| User login | Login with valid creds | Success | | |
| [... one row per existing feature that might be affected ...] | | | | |

### Performance Verification
| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Page load time | < 2s | | |
| API response time | < 500ms | | |

### Accessibility Verification
| Criterion | Requirement | Actual | Pass/Fail |
|-----------|-------------|--------|-----------|
| Color contrast | 4.5:1 minimum | | |
| Keyboard navigation | All interactive elements | | |
```

---

## Ambiguity Detection Patterns

Teach the Requirements Analyst to detect these common ambiguity patterns:

### 1. Implicit Assumptions
**Trigger:** Statements like "the system should..." without specifics
**Example:** "The system should be fast"
**Clarification:** "Define 'fast' - what is acceptable response time in ms?"

### 2. Conflicting Sources
**Trigger:** Different files show different implementations of same thing
**Example:** Date formatted as "YYYY-MM-DD" in one place, "MM/DD/YYYY" in another
**Clarification:** "Which date format should the new feature use?"

### 3. Missing Error Handling
**Trigger:** Happy path documented but not error cases
**Example:** "User clicks submit and data is saved"
**Clarification:** "What happens if save fails? Network error? Validation error?"

### 4. Undefined Boundaries
**Trigger:** No limits specified
**Example:** "User can upload files"
**Clarification:** "What is max file size? Max count? Allowed types?"

### 5. Vague User References
**Trigger:** "Users" without specifying which type
**Example:** "Users can access the dashboard"
**Clarification:** "Which users? All authenticated? Admins only? Specific roles?"

### 6. Technology Ambiguity
**Trigger:** Multiple ways to implement something
**Example:** Two apps use different chart libraries
**Clarification:** "Which library should unified app use?"

---

## Integration with Plan Lifecycle

### When Requirements Analyst Runs

```
Plan Created
    ↓
Technical PM assesses complexity
    ↓
IF complexity >= "medium":
    ├─→ Requirements Analyst invoked (MANDATORY)
    │         ↓
    │   Requirements extracted
    │         ↓
    │   Clarifications identified
    │         ↓
    │   Loop 1: RA ↔ Portfolio Manager
    │         ↓
    │   IF escalation needed:
    │         Loop 2: PM ↔ User
    │         ↓
    │   Requirements marked complete
    │         ↓
    └─→ TPM Orchestrator can execute
ELSE:
    └─→ TPM Orchestrator executes directly
```

### Blocking Behavior

- TPM Orchestrator CANNOT start if requirements status is "incomplete"
- TPM Orchestrator CANNOT start if clarifications are "pending-user-response"
- TPM Orchestrator CAN start if clarifications are "pending-portfolio-manager" (non-blocking items only)

---

## Artifact Locations

| Artifact | Location | Created By |
|----------|----------|------------|
| Requirements document | `inbox/plans/.requirements/{PLAN_ID}.md` | Requirements Analyst |
| Verification checklist | `inbox/plans/.requirements/{PLAN_ID}-checklist.md` | Requirements Analyst |
| Clarification requests | `inbox/plans/.requirements/{PLAN_ID}-clarifications.md` | Requirements Analyst |
| Clarification resolutions | Same file, updated by Portfolio Manager | Portfolio Manager |

---

## Quality Gates

### Requirements Analyst Must Verify

Before marking requirements complete:
- [ ] All source code read (if modifying existing)
- [ ] All inventories complete (no "TODO" items)
- [ ] All ambiguities identified
- [ ] Clarification requests submitted (if needed)
- [ ] Verification checklist produced
- [ ] Checklist has at least one item per feature/component

### Portfolio Manager Must Verify

Before allowing TPM execution:
- [ ] Requirements document exists
- [ ] Verification checklist exists
- [ ] All blocking clarifications resolved
- [ ] Requirements marked "complete"

---

## Failure Modes and Recovery

### Failure: Requirements Incomplete

**Symptom:** TPM execution blocked, plan stuck
**Recovery:**
1. Check `inbox/plans/.requirements/{PLAN_ID}.md`
2. Identify incomplete sections
3. Re-invoke Requirements Analyst with specific focus
4. Complete missing sections
5. Re-verify requirements completeness

### Failure: Clarification Timeout

**Symptom:** Clarification pending > 24 hours
**Recovery:**
1. Apply default resolution (documented in clarification request)
2. Document that default was applied
3. Proceed with execution
4. Flag in completion report: "Default applied for item X"

### Failure: Requirements Drift

**Symptom:** During development, discover requirements were wrong
**Recovery:**
1. HALT development (if major drift)
2. Document discovered discrepancy
3. Re-invoke Requirements Analyst for affected area
4. Update requirements document
5. Update verification checklist
6. Resume development

---

**Remember:** The goal is to catch missing requirements BEFORE development, not after. Every hour spent on thorough requirements analysis saves multiple hours of rework.
