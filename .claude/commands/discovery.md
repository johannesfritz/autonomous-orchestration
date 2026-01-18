Run the full product discovery flow: Product Manager → UX Researcher → Technical PM → UAT Protocol Designer → create-plan.

This command orchestrates a complete discovery-to-plan pipeline for new features.

## Flow

1. **Product Manager Phase**
   - Validate the feature idea against user needs
   - Apply prioritization framework (default: ICE)
   - Determine if this is worth building
   - Output: Validated feature with priority score

2. **UX Research Phase** (for UI features)
   - If the feature involves UI, invoke ux-researcher
   - Map user journey
   - Check accessibility requirements (WCAG 2.1 AA)
   - Output: UX specifications and journey map

3. **Technical PM Phase**
   - Translate validated requirements to technical specs
   - Assess complexity (simple/moderate/complex/architectural)
   - Determine if spike needed for unknowns
   - If architectural → recommend solutions-architect
   - Output: Technical specification

4. **Optional: Spike Phase** (if unknowns identified)
   - Conduct objective-driven spike
   - Answer the specific question
   - Output: Knowledge artifact

5. **Optional: Architecture Phase** (if complex)
   - Invoke solutions-architect for significant decisions
   - Create ADR for the decision
   - Output: ADR reference

6. **UAT Protocol Design Phase** (MANDATORY)
   - Invoke uat-protocol-designer with all gathered context
   - Design user journeys with step-by-step verification
   - Define acceptance criteria (Given/When/Then)
   - Specify backend test requirements (API contracts)
   - Create edge case matrix (empty, many, special chars, errors)
   - Identify regression risks and existing tests to run
   - Output: Complete UAT protocol embedded in plan

7. **Plan Creation Phase**
   - Invoke create-plan skill with all gathered context
   - Include: validated requirements, technical spec, UX spec (if any), ADR (if any), UAT protocol
   - Output: Complete development plan ready for portfolio

## Usage

```
/discovery [feature idea or description]
```

## Examples

```
/discovery Add dark mode toggle to settings
/discovery Allow users to export their progress data
/discovery Implement real-time sync between devices
```

## Skip Options

If you've already done some phases:
- `--skip-pm` - Skip Product Manager (requirements already validated)
- `--skip-ux` - Skip UX research (not a UI feature)
- `--technical-only` - Start from Technical PM phase
- `--skip-uat` - Skip UAT protocol design (NOT RECOMMENDED - use only for trivial changes)

## Output

At the end, you will have:
1. Validated feature with priority score
2. UX specifications (if applicable)
3. Technical specification with complexity assessment
4. ADR (if architectural decision made)
5. **UAT Protocol** with user journeys, acceptance criteria, test specs, and regression checklist
6. Complete development plan (PLAN-YYYY-NNN.md) ready for /add-plan

## Diligence-First Principle

The UAT Protocol Design phase is **mandatory** because:
- If we can't define how to test it, we shouldn't build it yet
- User journeys become Playwright tests
- API specs become pytest tests
- Edge cases prevent production bugs
- Regression checklists protect existing features

Rather be slow than sorry.
