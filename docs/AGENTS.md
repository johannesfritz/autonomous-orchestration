# Agent Descriptions

This system includes 17 custom agents, each with a specific role.

---

## Core Orchestration Agents

### portfolio-manager

**Role:** VP Engineering / CTO

**Purpose:** Multi-plan coordination and autonomous execution

**Capabilities:**
- Scan inbox for new plans
- Build dependency graphs
- Detect file conflicts
- Prioritize execution order
- Spawn TPM orchestrators
- Learn from user overrides
- Generate real-time dashboard

**Invocation:**
```
Task(subagent_type="portfolio-manager", prompt="...")
```

**Key behaviors:**
- AUTONOMOUS: Auto-executes ready plans
- LEARNING: Tracks overrides to improve decisions
- ESCALATES: Only asks for strategic/ambiguous choices

---

### tpm-orchestrator

**Role:** Technical Program Manager (per-plan)

**Purpose:** Single plan execution from start to finish, with research-informed patterns

**Capabilities:**
- Parse plan workstreams
- **Feature list verification** - Read `feature_list.json`, verify all features start "failing", update status only when `test_command` succeeds (P1, P3)
- **Workstream file protocol** - Write workstream instructions to disk before spawning agents; if session crashes, context persists (P8)
- **Session initialization** - Dev agents receive ground truth via `init-session.sh` (P4)
- Spawn agents in parallel
- **Attention management** - Rewrite progress files at every checkpoint to combat lost-in-the-middle degradation (P6)
- **AI-optimized test output** - Use `pytest --tb=short --no-header -q` showing only failures (P5)
- Enforce quality gates (feature list bookends: all "failing" at start, all "passing" at end)
- Handle git workflow
- Risk-aware merge decisions
- Update state on completion

**Invocation:**
```
Task(subagent_type="tpm-orchestrator", prompt="Execute PLAN-2025-001...")
```

**Quality gates enforced:**
0. Feature list exists with all features "failing" (P1)
1. All workstreams complete
2. Tests pass (`pytest --tb=short --no-header -q`)
3. UAT verified (Playwright, not checklist)
4. Code review approved
5. Security audit clean
6. Git workflow success
7. CI/CD passes
8. ALL features in feature_list.json are "passing" (P3)
9. Appropriate merge decision (risk-aware)

---

### risk-manager

**Role:** Chief Risk Officer / Compliance Officer

**Purpose:** Mandatory safety gate for all plans

**Capabilities:**
- Assess 4 risk dimensions
- Calculate overall risk score
- Determine approval requirements
- Recommend mitigations
- Append assessment to plan file

**Invocation:**
```
Task(subagent_type="risk-manager", prompt="Assess risk for PLAN-2025-001...")
```

**Four dimensions:**
1. User Disruption (1-10)
2. Controllability (1-10)
3. Liability & Compliance (1-10)
4. AI-Specific Risk (1-10)

**Decision rules:**
- Overall >= 7/10 → Requires manual approval
- Any dimension >= 8/10 → Requires manual approval
- Otherwise → Approved for autonomous execution

---

## Pre-Development Agents

### uat-protocol-designer

**Role:** Test Architect

**Purpose:** Design acceptance tests BEFORE development begins, ensuring specs produce their own checking harness (P1, P12)

**Capabilities:**
- Map acceptance criteria to testable feature list entries
- Create user journey verification steps
- Design backend test specifications (API contracts)
- Build edge case matrices
- Create regression checklists to protect existing features
- **Feature list mapping** - Each AC-N maps to F-N in `feature_list.json` with a concrete `test_command`

**Invocation:**
```
Task(subagent_type="uat-protocol-designer", prompt="Design UAT protocol for PLAN-2025-001...")
```

**Key principle:** Tests are designed BEFORE code is written. Each acceptance criterion must have a machine-verifiable test command, not a subjective checklist.

---

### requirements-analyst

**Role:** Requirements Engineer

**Purpose:** Extract detailed requirements before development, preventing scope ambiguity

**Capabilities:**
- Create feature inventories from user descriptions
- Build verification checklists with testable criteria
- Flag ambiguities and missing requirements
- Identify implicit dependencies
- Produce structured requirement documents

**Invocation:**
```
Task(subagent_type="requirements-analyst", prompt="Extract requirements for...")
```

**When invoked:** After Technical PM and before TPM execution. Catches requirement gaps that would otherwise surface during development.

---

## Development Agents

### artificial-shadow-dev

**Role:** Senior Full-Stack Developer

**Purpose:** Full-stack development work

**Tech expertise:**
- Backend: FastAPI, Pydantic, SQLAlchemy, async Python
- Frontend: React 18, TypeScript, Tailwind CSS
- Database: SQLite, PostgreSQL, Qdrant
- APIs: Claude, OpenAI embeddings

**Invocation:**
```
Task(subagent_type="artificial-shadow-dev", prompt="Implement...")
```

**Session initialization (P4):** Receives ground truth via `init-session.sh` at startup (git status, feature progress, quick test check). Reads workstream file from `inbox/plans/.workstreams/` for assignment context (P8).

---

### database-engineer

**Role:** Database Engineer

**Purpose:** Relational database work

**Specialties:**
- SQLite and PostgreSQL
- Schema design
- Query optimization
- Migrations
- Index strategies

**Invocation:**
```
Task(subagent_type="database-engineer", prompt="Design schema for...")
```

---

### hybrid-db-architect

**Role:** Hybrid Database Architect

**Purpose:** SQLite + Vector DB dual-store architecture

**Specialties:**
- Data consistency between stores
- Versioning payload schema
- Embedding strategies
- Retrieval optimization

**Invocation:**
```
Task(subagent_type="hybrid-db-architect", prompt="Design storage for...")
```

---

### artificial-shadow-llm-architect

**Role:** LLM Application Architect

**Purpose:** Multi-model AI pipeline design

**Expertise:**
- Claude API integration
- OpenAI embeddings/Whisper
- Pipeline architecture
- Prompt engineering
- Cost optimization
- Context window management

**Invocation:**
```
Task(subagent_type="artificial-shadow-llm-architect", prompt="Design pipeline...")
```

---

## Product Management Agents

### product-manager

**Role:** Product Manager / Voice of Customer

**Purpose:** Validate user needs and prioritize features

**Capabilities:**
- User need validation with evidence
- ICE/RICE prioritization scoring
- Roadmap alignment
- Feature scoping

**Invocation:**
```
Task(subagent_type="product-manager", prompt="Validate need for...")
```

**Protocol injected:** `user-centricity.md`

---

### ux-researcher

**Role:** UX Designer / Researcher

**Purpose:** User journey mapping and accessibility compliance

**Capabilities:**
- User persona identification
- Journey mapping
- WCAG 2.1 AA compliance checking
- Text-based specifications (no images)

**Invocation:**
```
Task(subagent_type="ux-researcher", prompt="Map user journey for...")
```

---

### technical-pm

**Role:** Technical Product Manager

**Purpose:** Bridge business requirements to technical specs

**Capabilities:**
- Complexity assessment (Low/Medium/High)
- Spike identification for unknowns
- Technical specification writing
- Dependency mapping

**Invocation:**
```
Task(subagent_type="technical-pm", prompt="Translate requirements for...")
```

**Protocol injected:** `technical-translation.md`

---

### solutions-architect

**Role:** Solutions Architect

**Purpose:** Architecture decisions and documentation

**Capabilities:**
- Architecture Decision Records (ADRs)
- Technology selection
- Trade-off analysis
- Reversibility assessment

**Invocation:**
```
Task(subagent_type="solutions-architect", prompt="Document decision for...")
```

**Protocol injected:** `architectural-documentation.md`

---

### gardener

**Role:** Refactoring Specialist

**Purpose:** Reduce code complexity and technical debt

**Capabilities:**
- Delete duplicate code
- Consolidate similar patterns
- Simplify over-engineered solutions
- Enforce Rule of Three

**Invocation:**
```
Task(subagent_type="gardener", prompt="Refactor and simplify...")
```

**Key mission:** DELETE and CONDENSE code, not add to it.

---

## Quality Agents

### shadow-code-reviewer

**Role:** Senior Code Reviewer

**Purpose:** Production-readiness verification

**Checks:**
- Code quality standards
- Security (OWASP Top 10)
- User input flow verification
- Test coverage
- Documentation

**Invocation:**
```
Task(subagent_type="shadow-code-reviewer", prompt="Review code in...")
```

**Key protocol:** Functional verification - ensures user settings are actually applied, not ignored.

---

### qa-engineer

**Role:** Senior QA Engineer

**Purpose:** Test creation and coverage analysis

**Expertise:**
- pytest for Python
- React Testing Library
- Playwright E2E tests
- Integration tests
- UAT gap analysis

**Invocation:**
```
Task(subagent_type="qa-engineer", prompt="Create tests for...")
```

---

### qa-lead

**Role:** QA Lead / Senior Technical Reviewer

**Purpose:** Multi-pass code review with structured verdicts

**Capabilities:**
- 5-pass review methodology:
  1. Correctness pass
  2. Integration pass
  3. Security pass
  4. Maintainability pass
  5. Regression risk pass
- Structured JSON output for automation
- Verdict types: APPROVE, REQUEST_CHANGES, BLOCK
- Confidence scores and specific line references

**Invocation:**
```
Task(subagent_type="qa-lead", prompt="Review PR for...")
```

**Output format:** Returns structured JSON with verdicts, enabling automated decision-making in CI/CD pipelines.

---

## Agent Selection Guide

| Task | Recommended Agent |
|------|-------------------|
| Multi-plan coordination | portfolio-manager |
| Single plan execution | tpm-orchestrator |
| Risk assessment | risk-manager |
| Pre-dev test design | uat-protocol-designer |
| Requirements extraction | requirements-analyst |
| Feature prioritization | product-manager |
| User journey mapping | ux-researcher |
| Requirements translation | technical-pm |
| Architecture decisions | solutions-architect |
| Code refactoring/cleanup | gardener |
| Backend/Frontend development | artificial-shadow-dev |
| Database design | database-engineer |
| Vector + SQL architecture | hybrid-db-architect |
| LLM pipeline design | artificial-shadow-llm-architect |
| Code review | shadow-code-reviewer |
| Test creation | qa-engineer |
| Multi-pass PR review | qa-lead |

---

## Customization

Each agent is a single `.md` file with YAML frontmatter:

```markdown
---
name: agent-name
description: What this agent does
model: sonnet  # or opus, haiku
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Task
---

You are the [Role] agent...

## Your Responsibilities
...

## Key Behaviors
...
```

You can modify agents to fit your project needs.
