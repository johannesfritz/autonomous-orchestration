Run the full product discovery flow: Product Manager → UX Researcher → Technical PM → create-plan.

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

6. **Plan Creation Phase**
   - Invoke create-plan skill with all gathered context
   - Include: validated requirements, technical spec, UX spec (if any), ADR (if any)
   - Output: Complete development plan ready for portfolio

## Usage

```
/discovery [feature idea or description]
```

## Examples

```
/discovery Add dark mode toggle to Stellaris settings
/discovery Allow users to export their vocabulary progress
/discovery Implement real-time sync between devices
```

## Skip Options

If you've already done some phases:
- `--skip-pm` - Skip Product Manager (requirements already validated)
- `--skip-ux` - Skip UX research (not a UI feature)
- `--technical-only` - Start from Technical PM phase

## Output

At the end, you will have:
1. Validated feature with priority score
2. UX specifications (if applicable)
3. Technical specification with complexity assessment
4. ADR (if architectural decision made)
5. Complete development plan (PLAN-YYYY-NNN.md) ready for /add-plan
