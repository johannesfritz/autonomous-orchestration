# Production Hardening Protocol

**Protocol Name:** `PROTOCOL-HARDENING-L5`

This document defines the enhanced review and verification gates required for major changes that carry higher risk of production incidents.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [What is a "Major Change"?](#what-is-a-major-change)
- [Required Gates for Major Changes](#required-gates-for-major-changes)
  - [1. All Tests Pass (Zero Failures)](#1-all-tests-pass-zero-failures)
  - [2. UAT Verified (Manual User Journey)](#2-uat-verified-manual-user-journey)
  - [3. Senior Code Review (shadow-code-reviewer in Strict Mode)](#3-senior-code-review-shadow-code-reviewer-in-strict-mode)
  - [4. Risk Assessment (Mandatory for All Plans)](#4-risk-assessment-mandatory-for-all-plans)
  - [5. Security Scan (SAST - Static Analysis)](#5-security-scan-sast---static-analysis)
  - [6. Dependency Audit (Anti-Hallucination + Vulnerability Scan)](#6-dependency-audit-anti-hallucination--vulnerability-scan)
- [Detection and Enforcement](#detection-and-enforcement)
  - [Automatic Detection](#automatic-detection)
  - [Hook Integration](#hook-integration)
- [Deployment Verification](#deployment-verification)
  - [CI/CD Status Check](#cicd-status-check)
  - [Smoke Tests](#smoke-tests)
- [Rollback Plan](#rollback-plan)
  - [Database Changes](#database-changes)
  - [Feature Flags](#feature-flags)
  - [Deployment Rollback](#deployment-rollback)
- [Example: Major Change Workflow](#example-major-change-workflow)
  - [Step 1: Detection](#step-1-detection)
  - [Step 2: Quality Gates](#step-2-quality-gates)
  - [Step 3: Deployment](#step-3-deployment)
  - [Step 4: Post-Deployment Verification](#step-4-post-deployment-verification)
  - [Result: SHIPPED ✅](#result-shipped-)
- [When to Bypass (RARELY)](#when-to-bypass-rarely)
- [Continuous Improvement](#continuous-improvement)
- [Summary](#summary)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## What is a "Major Change"?

Major changes are automatically detected when code modifications touch sensitive areas of the system. The detection script (`.claude/scripts/detect-major-changes.sh`) scans for:

| Category | Files/Patterns | Why It's Major |
|----------|----------------|----------------|
| **Database** | `migrations/`, `alembic/`, `models.py`, `schema.py` | Schema changes are high-risk and difficult to roll back. Data corruption or loss can occur. |
| **Auth** | `auth/`, `login`, `session`, `permission`, `oauth` | Security vulnerabilities in auth can compromise entire system. Mistakes lock out users. |
| **New Features** | New files in `pages/`, `views/`, `routes/` | New user-facing features introduce unknown edge cases and may have accessibility issues. |
| **Data Operations** | `DELETE`, `DROP`, bulk updates | Irreversible data loss. Production incidents are unrecoverable without backups. |
| **External Services** | `services/`, `integrations/`, API clients | Third-party dependencies can fail unpredictably. Rate limits, API changes, downtime. |

**Philosophy:** Not all code changes are equal in risk. Major changes require proportionally more verification.

## Required Gates for Major Changes

When major changes are detected, ALL of the following gates must pass:

### 1. All Tests Pass (Zero Failures)

**Scope:**
- Unit tests (`pytest`)
- Integration tests (`pytest tests/integration/`)
- E2E tests (`npm run test:e2e` for hotel-de-ville)

**Command:**
```bash
pytest --maxfail=1  # Stop on first failure for fast feedback
```

**Blocking condition:** Any test failure blocks the change. No exceptions.

**Why:** Tests are the first line of defense. If existing tests fail, the change breaks known functionality.

### 2. UAT Verified (Manual User Journey)

**Definition:** User Acceptance Testing - manually execute the user journey affected by the change.

**Process:**
1. Identify the user workflow impacted (e.g., "User creates workspace and invites member")
2. Execute workflow in local development environment
3. Verify all steps complete successfully
4. Check for visual bugs, error messages, unexpected behavior
5. Test edge cases (empty input, max length, special characters)

**Example UAT checklist for auth changes:**
- [ ] User can register with valid email
- [ ] User cannot register with duplicate email
- [ ] User receives email verification
- [ ] User can log in after verification
- [ ] User cannot log in with wrong password
- [ ] User can reset forgotten password
- [ ] Session persists across page refreshes
- [ ] User can log out successfully

**Blocking condition:** Any UAT step fails or produces unexpected behavior.

**Why:** Automated tests can't catch all issues. Manual testing finds UX problems, visual bugs, and integration issues.

### 3. Senior Code Review (shadow-code-reviewer in Strict Mode)

**Trigger:** Major changes automatically inject `.claude/protocols/strict-code-standards.md` into shadow-code-reviewer.

**Review focus:**
- **Absolute rules:** Function length ≤ 50 lines, no vague names, complete type annotations, no empty except blocks, no console.log/print, no magic numbers, tests for new functions
- **Strong preferences:** Early returns over nesting, composition over inheritance, explicit over implicit, fail fast
- **Security:** OWASP Top 10 vulnerabilities
- **Database:** NULL handling, explicit value setting, migration scripts

**Blocking condition:** Any "Absolute Rules" violation = REJECT. Multiple "Strong Preferences" violations = REQUEST CHANGES.

**Why:** Major changes demand higher code quality. Strict review catches issues before they reach production.

### 4. Risk Assessment (Mandatory for All Plans)

**Trigger:** Portfolio Manager MUST invoke Risk Manager for every development plan (enforced via hooks).

**Risk dimensions assessed:**
1. **User Disruption Risk (1-10):** Breaking changes, downtime, data loss
2. **Controllability Risk (1-10):** Reversibility, oversight, critical systems
3. **Liability & Compliance Risk (1-10):** GDPR, WCAG, COPPA, security
4. **AI-Specific Risk (1-10):** Bias, hallucination, privacy, transparency

**Escalation threshold:**
- Overall risk ≥ 7/10 → Requires Johannes approval
- Any dimension ≥ 8/10 → Requires Johannes approval
- Critical systems (auth, payments, data) → Always requires approval
- Irreversible operations → Always requires approval

**Blocking condition:** High-risk changes (≥7) cannot auto-merge. Must wait for manual approval.

**Why:** Risk assessment prevents autonomous execution of potentially dangerous changes.

### 5. Security Scan (SAST - Static Analysis)

**Tool:** `static-analysis` skill (invoked automatically before `git push`)

**Checks:**
- Python security via Bandit (SQL injection, code injection, path traversal)
- Secret detection (API keys, passwords, tokens, hardcoded credentials)
- OWASP Top 10 vulnerabilities

**Command:**
```bash
bandit -r . -ll  # Check for medium+ severity issues
```

**Blocking condition:** Any HIGH severity issue blocks push.

**Why:** Security vulnerabilities in production can lead to data breaches, regulatory fines, and reputational damage.

### 6. Dependency Audit (Anti-Hallucination + Vulnerability Scan)

**Tool:** `dependency-vetting` skill (invoked after `pip install` or `npm install`)

**Checks:**
- Security vulnerabilities (`pip-audit`, `npm audit`)
- Package existence verification (prevents AI "package hallucination")
- License compliance (GPL, AGPL warnings)
- Package trust scores (age, downloads, contributors)

**Blocking condition:** CRITICAL or HIGH vulnerabilities, or hallucinated packages.

**Why:** Supply chain attacks are real. AI can hallucinate non-existent packages. Vulnerable dependencies are entry points for attackers.

## Detection and Enforcement

### Automatic Detection

Major changes are detected by `.claude/scripts/detect-major-changes.sh`, which runs on:
- **PreToolUse hook** for `git commit` - Scans staged changes
- **SubagentStart hook** for `shadow-code-reviewer` - Injects strict protocol

**Detection logic:**
```bash
# Check if any staged files match major change patterns
if git diff --cached --name-only | grep -E "(migrations|alembic|models\.py|schema\.py|auth/|login|session)"; then
    echo "MAJOR_CHANGE_DETECTED"
fi
```

### Hook Integration

When major changes detected:
1. **shadow-code-reviewer** receives `.claude/protocols/strict-code-standards.md`
2. **TPM orchestrator** enforces all 6 quality gates (cannot skip)
3. **Portfolio Manager** verifies risk assessment exists before execution

**These hooks make hardening enforcement automatic and deterministic.**

## Deployment Verification

After all gates pass, final verification before marking plan SHIPPED:

### CI/CD Status Check

**Command:**
```bash
.claude/scripts/wait-for-ci.sh --wait --timeout 300
```

**Checks:**
- All GitHub Actions workflows PASS
- No failing jobs
- Deployment succeeded

**Blocking condition:** Any workflow failure blocks SHIPPED status.

**Why:** CI/CD runs additional checks (linting, formatting, E2E in clean environment). Must verify before considering work complete.

### Smoke Tests

**Definition:** Quick checks that critical functionality still works after deployment.

**Example smoke tests:**
- [ ] Homepage loads without errors
- [ ] Login flow works
- [ ] Database queries return expected results
- [ ] API health check returns 200 OK

**Run on:** Production environment, immediately after deployment.

**Blocking condition:** Any smoke test fails → Rollback deployment.

**Why:** Deployment can fail in production even if dev/staging work. Smoke tests catch environment-specific issues.

## Rollback Plan

Every major change MUST have a documented rollback plan:

### Database Changes

```markdown
## Rollback Plan

**If migration fails:**
1. Run rollback migration: `alembic downgrade -1`
2. Restore database from backup: `pg_restore backup_YYYYMMDD.sql`
3. Verify data integrity: `SELECT COUNT(*) FROM critical_tables`

**Expected downtime:** 5 minutes
**Data loss risk:** None (backup covers period before migration)
```

### Feature Flags

For new features, use feature flags to enable instant rollback:

```python
# In code
if feature_flags.is_enabled("new_dashboard"):
    return render_new_dashboard()
else:
    return render_old_dashboard()

# Rollback = flip flag, no deployment needed
```

### Deployment Rollback

```bash
# Rollback to previous version
git revert HEAD
git push origin main
# GitHub Actions auto-deploys previous version
```

**Why:** Rollback plans reduce decision paralysis during incidents. Pre-documented steps enable fast recovery.

## Example: Major Change Workflow

**Scenario:** Adding `is_favorite` column to `users_workspaces` table.

### Step 1: Detection
```bash
# Modify models.py
git add hotel-de-ville/models.py

# PreToolUse hook detects major change
# Injects strict-code-standards.md into reviewer
```

### Step 2: Quality Gates

#### ✅ Gate 1: Tests Pass
```bash
pytest
# Result: 42 passed, 0 failed
```

#### ✅ Gate 2: UAT Verified
- [ ] User can favorite a workspace
- [ ] Favorite persists after page refresh
- [ ] User can unfavorite a workspace
- [ ] Existing workspaces default to not favorited

#### ✅ Gate 3: Senior Code Review
```
shadow-code-reviewer:
- ✅ Function length ≤ 50 lines
- ✅ Complete type annotations
- ✅ NULL handling in queries
- ✅ Migration script included
APPROVED
```

#### ✅ Gate 4: Risk Assessment
```
Overall Risk: 4/10 (Medium)
- User Disruption: 2/10 (Low - additive change)
- Controllability: 3/10 (Low - reversible)
- Liability: 1/10 (Low - no compliance impact)
- AI Risk: 1/10 (Low - no AI component)

APPROVED for autonomous execution
```

#### ✅ Gate 5: Security Scan
```bash
bandit -r . -ll
# Result: No HIGH severity issues
```

#### ✅ Gate 6: Dependency Audit
```bash
# No new dependencies added
SKIPPED
```

### Step 3: Deployment
```bash
git push origin feature/add-favorite-column
gh pr create --title "Add favorite column to workspaces"

# Auto-merge (risk < 7)
gh pr merge --auto --squash
```

### Step 4: Post-Deployment Verification
```bash
# Wait for CI
.claude/scripts/wait-for-ci.sh --wait

# Run smoke tests
curl https://jfritz.xyz/api/health
# Result: 200 OK

# Verify in production
ssh deploy@jfritz.xyz "psql village_db -c 'SELECT * FROM users_workspaces LIMIT 1'"
# Result: is_favorite column exists
```

### Result: SHIPPED ✅

## When to Bypass (RARELY)

Hardening protocol can be bypassed ONLY for:
1. **Hotfixes during active incidents** (restore service first, review later)
2. **Urgent security patches** (zero-day vulnerabilities)
3. **Rollbacks** (reverting broken changes)

**Process for bypass:**
1. Document reason in commit message
2. Skip automated gates with `--no-verify`
3. Manual review IMMEDIATELY after incident resolved

**Why rare:** Bypassing gates introduces risk. Only justified when NOT bypassing is riskier.

## Continuous Improvement

After each production incident:
1. **Root cause analysis:** What gate failed to catch the issue?
2. **Gate enhancement:** Add new checks to prevent recurrence
3. **Documentation update:** Update this protocol with lessons learned

**Examples:**
- Incident: NULL handling bug → Added NULL check to code-standards.md
- Incident: Flaky test → Added flaky test policy to testing.md
- Incident: Missing migration → Added migration script requirement to schema-migration-checklist.md

**Philosophy:** Hardening protocol evolves based on real production failures, not theoretical risks.

## Summary

Production Hardening Protocol ensures major changes receive proportional verification:

| Change Type | Review Level | Auto-Merge? |
|-------------|--------------|-------------|
| Minor (docs, comments) | Standard | Yes (immediate) |
| Moderate (new feature, low risk) | Standard + Tests | Yes (after CI) |
| **Major (DB, auth, data ops)** | **HARDENING-L5 (all 6 gates)** | **Only if risk < 7** |
| Critical (payments, compliance) | HARDENING-L5 + Manual Approval | No (manual merge) |

**This protocol makes quality gates deterministic and automatic, not manual checklists that get skipped under pressure.**
