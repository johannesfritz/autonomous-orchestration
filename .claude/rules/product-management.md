# Product Management Team

**New capability as of 2025-12-31:** Claude Code now includes a Product Management Team that bridges user needs to technical implementation, completing the discovery-to-delivery pipeline.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Architecture Overview](#architecture-overview)
- [New Agents](#new-agents)
- [New Skills](#new-skills)
- [New Slash Commands](#new-slash-commands)
- [Workflow: Discovery-to-Delivery](#workflow-discovery-to-delivery)
- [When to Use What](#when-to-use-what)
- [Protocol Files (Injected via Hooks)](#protocol-files-injected-via-hooks)
- [File Locations](#file-locations)
- [Integration with Existing Pipeline](#integration-with-existing-pipeline)
- [Benefits](#benefits)
- [Example: Full Discovery Flow](#example-full-discovery-flow)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Architecture Overview

```
User Feedback / Feature Ideas
           │
           ▼
┌─────────────────────┐
│ /intake             │  Process feedback from Stellaris DB
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Product Manager     │  Validate needs, prioritize (ICE/RICE)
│ (agent)             │  Protocol: user-centricity.md
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ UX Researcher       │  User journeys, accessibility (WCAG 2.1 AA)
│ (agent)             │  (for UI features only)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Technical PM        │  Translate to technical specs
│ (agent)             │  Protocol: technical-translation.md
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌────────┐  ┌────────────┐
│ Spike  │  │ Solutions  │  For unknowns / architecture decisions
│        │  │ Architect  │  Protocol: architectural-documentation.md
└────────┘  └─────┬──────┘
           │      │
           ▼      ▼
┌─────────────────────┐
│ create-plan         │  Generate development plan
│ (skill)             │  With discovery context
└──────────┬──────────┘
           │
           ▼
    EXECUTION PIPELINE
    (Portfolio Manager → TPM Orchestrator → Dev Agents)
```

## New Agents

| Agent | Real-World Role | Protocol Injected | Purpose |
|-------|----------------|-------------------|---------|
| `product-manager` | Product Manager / PM | `user-centricity.md` | Voice of Customer - validates needs, prioritizes features using RICE/ICE scoring |
| `ux-researcher` | UX Designer / Researcher | UX focus message | Maps user journeys, checks WCAG 2.1 AA compliance, creates text-based specifications |
| `technical-pm` | Technical Product Manager / TPM | `technical-translation.md` | Business ↔ Technical bridge - translates requirements to specs, assesses complexity |
| `solutions-architect` | Solutions Architect / SA | `architectural-documentation.md` | Makes architectural decisions, creates ADRs (Architecture Decision Records) |

## New Skills

| Skill | Purpose | When Auto-Invoked |
|-------|---------|-------------------|
| `user-feedback-intake` | Pull feedback from Stellaris production DB | User requests `/intake` |
| `prioritization-framework` | Apply RICE/ICE/MoSCoW scoring | Product Manager needs to prioritize features |
| `technical-spike` | Objective-driven investigation (not time-boxed) | Technical PM identifies unknowns |
| `write-adr` | Create Architecture Decision Records (MADR format) | Solutions Architect makes architectural decision |

## New Slash Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/intake` | Process user feedback from Stellaris | `/intake` |
| `/prioritize-backlog [framework]` | Score and rank features (RICE/ICE/MoSCoW) | `/prioritize-backlog rice` |
| `/spike [question]` | Start technical investigation | `/spike Can we use WebSockets for real-time updates?` |
| `/adr [decision]` | Create Architecture Decision Record | `/adr Choose PostgreSQL for relational data` |
| `/discovery [idea]` | Full discovery flow (PM → UX → TPM → plan) | `/discovery Add dark mode to Stellaris` |

## Workflow: Discovery-to-Delivery

**Full flow (for new features):**

1. **Feedback Intake:** `/intake` pulls open feedback from Stellaris production database
2. **Prioritization:** Product Manager scores features with ICE/RICE framework
3. **Discovery:** `/discovery [feature]` orchestrates the full flow:
   - **Product Manager** validates user need and priority
   - **UX Researcher** maps user journey (if UI feature)
   - **Technical PM** translates to technical specs, assesses complexity
   - **Spike** (if unknowns) resolves technical questions
   - **Solutions Architect** (if architectural) creates ADR
   - **create-plan** generates development plan with all context
4. **Execution:** Portfolio Manager takes over (existing pipeline)

**Shortcuts (skip phases when appropriate):**

- Simple backend feature: `/discovery --skip-ux [idea]`
- Already validated: `/discovery --skip-pm [idea]`
- Technical only: `/discovery --technical-only [idea]`
- Direct spike: `/spike [question]`
- Direct ADR: `/adr [decision]`

## When to Use What

| Scenario | Command/Agent |
|----------|---------------|
| New user feedback to process | `/intake` |
| Need to prioritize backlog | `/prioritize-backlog` |
| New feature idea (full discovery) | `/discovery [idea]` |
| UI feature (needs UX research) | `/discovery [idea]` (auto-invokes ux-researcher) |
| Technical uncertainty | `/spike [question]` or let Technical PM recommend |
| Major technical decision | `/adr [decision]` or let Solutions Architect create |
| Simple bug fix | Skip discovery, use `/queue-fix` |
| Clear requirements | `/discovery --skip-pm [idea]` |
| Backend only | `/discovery --skip-ux [idea]` |

## Protocol Files (Injected via Hooks)

Product Management agents have protocols automatically injected when they start (via `SubagentStart` hooks in `.claude/settings.json`):

| Agent | Protocol File | Key Behaviors |
|-------|---------------|---------------|
| product-manager | `user-centricity.md` | Evidence-based prioritization, RICE/ICE scoring rigor, roadmap alignment |
| technical-pm | `technical-translation.md` | Complexity assessment, spike triggers, architectural awareness |
| solutions-architect | `architectural-documentation.md` | ADR triggers, reversibility checks, trade-off documentation |
| ux-researcher | UX focus message | User journey focus, WCAG 2.1 AA compliance, evidence-based recommendations |

These protocols ensure consistent, high-quality decision-making across all product management workflows.

## File Locations

| Content Type | Location |
|--------------|----------|
| Feedback intake records | `00 Inbox/feedback/` |
| Prioritized backlog | `00 Inbox/backlog/` |
| Technical spikes | `00 Inbox/spikes/` |
| Architecture Decision Records | `[project]/docs/adr/` (project-specific) or `docs/adr/` (cross-project) |
| Development plans (from discovery) | `00 Inbox/plans/` |

## Integration with Existing Pipeline

The Product Management Team sits **upstream** of the existing execution pipeline:

```
[NEW] Discovery → [EXISTING] Execution

Product Management Team        Portfolio Manager
creates plans with context  →  executes plans autonomously
```

**Key integration points:**

1. **create-plan skill enhanced** - Now accepts discovery context from PM/UX/TPM flow
2. **Development plans enriched** - Include priority scores, user journeys, technical assessments, ADR references
3. **Portfolio Manager unchanged** - Receives better-quality plans with more context
4. **Backward compatible** - Old workflow (direct create-plan) still works

## Benefits

**For Johannes:**
- **Data-driven prioritization** - RICE/ICE scoring removes bias
- **User-centric features** - Direct feedback pipeline from production
- **Reduced risk** - UX research, spikes, and ADRs catch issues early
- **Better visibility** - Complete audit trail from feedback → plan → execution

**For the AI system:**
- **Clearer requirements** - Technical specs from Technical PM vs. vague feature ideas
- **Architectural guidance** - ADRs document "why" for future decisions
- **Complexity awareness** - Spikes resolve unknowns before development
- **Accessibility compliance** - UX Researcher ensures WCAG 2.1 AA from the start

## Example: Full Discovery Flow

**User says:** "Add dark mode toggle to Stellaris"

1. **Product Manager** validates:
   - Checks Stellaris feedback DB → 8 users requested this
   - Calculates ICE score: Impact (7) × Confidence (0.9) × Ease (6) = 37.8
   - Decision: Approve for development

2. **UX Researcher** maps journey:
   - User persona: Visual comfort seeker
   - Journey: Settings → Appearance → Toggle dark mode → App refreshes
   - Accessibility: Must maintain 4.5:1 contrast ratio (WCAG 2.1 AA)
   - Deliverable: Text-based specification

3. **Technical PM** translates:
   - Complexity: Medium (CSS variables + state management + persistence)
   - Files affected: `Stellaris.tsx`, `theme.css`, localStorage logic
   - No unknowns → Skip spike
   - Not architectural → Skip ADR
   - Deliverable: Technical specification

4. **create-plan** generates plan:
   - Includes ICE score (37.8), user journey, technical spec
   - Workstreams: (1) CSS theme variables, (2) Toggle component, (3) State persistence
   - Agent: artificial-shadow-dev
   - Deliverable: `PLAN-2025-XXX.md` ready for `/add-plan`

5. **Portfolio Manager** executes (existing pipeline)

**Total time:** ~10 minutes for complete discovery → plan creation
