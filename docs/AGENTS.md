# Agent Descriptions

This system includes 10 custom agents, each with a specific role.

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

**Purpose:** Single plan execution from start to finish

**Capabilities:**
- Parse plan workstreams
- Spawn agents in parallel
- Enforce quality gates
- Handle git workflow
- Risk-aware merge decisions
- Update state on completion

**Invocation:**
```
Task(subagent_type="tpm-orchestrator", prompt="Execute PLAN-2025-001...")
```

**Quality gates enforced:**
1. All workstreams complete
2. Tests pass
3. Code review approved
4. Security audit clean
5. Git workflow success
6. Appropriate merge decision

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
