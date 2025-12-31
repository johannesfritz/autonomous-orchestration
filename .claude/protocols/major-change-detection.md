# Major Change Detection Protocol

**Purpose:** Identify changes that require mandatory UAT and senior code review before shipping.

## What Constitutes a "Major Change"

### Category 1: Database Changes (ALWAYS MAJOR)

Any modification to:

- **SQLite schema files** (`*.sql`, `alembic/versions/*.py`)
- **SQLAlchemy models** (files containing `class.*Base`, `Column(`, `relationship(`)
- **Qdrant collection definitions** (payload schemas, index configurations)
- **Migration files** (Alembic, Django migrations, Prisma)

**Detection patterns:**
```
# Files
**/migrations/**
**/alembic/**
**/models.py
**/models/*.py
**/schema.py
**/schema/*.py

# Content patterns
CREATE TABLE
ALTER TABLE
DROP TABLE
ADD COLUMN
sqlalchemy.Column
Field(... = Field
```

### Category 2: Authentication/Authorization (ALWAYS MAJOR)

Any modification to:

- **Auth routes** (`/login`, `/logout`, `/register`, `/oauth`)
- **JWT/session handling**
- **Permission checks** (`@requires_auth`, `@admin_only`)
- **Password hashing/verification**
- **API key validation**

**Detection patterns:**
```
# Files
**/auth/**
**/authentication/**
**/authorization/**
**/permissions/**
**/*auth*.py
**/*auth*.ts

# Content patterns
jwt.encode
jwt.decode
password_hash
verify_password
@requires_auth
@admin
current_user
session_token
api_key
bearer
OAuth
```

### Category 3: New Features (ALWAYS MAJOR)

Any new:

- **API endpoint** (new route decorator/handler)
- **React page/view** (new file in `pages/`, `views/`)
- **Background task/job** (Celery, cron, scheduled)
- **External integration** (new API client, webhook)

**Detection patterns:**
```
# New files in these directories
pages/*.tsx (new file)
views/*.tsx (new file)
routes/*.py (new file)
routers/*.py (new file)
api/*.py (new file)
```

### Category 4: Data Deletion/Modification (ALWAYS MAJOR)

Any code that:

- **Deletes records** (`DELETE FROM`, `.delete()`, `remove()`)
- **Bulk updates** (`UPDATE ... WHERE`, `.update_many()`)
- **Data migration** (transforms existing data)
- **Irreversible operations**

**Detection patterns:**
```
DELETE FROM
.delete()
.delete_many()
bulk_delete
truncate
drop_collection
remove_all
purge
```

### Category 5: External Service Changes (ALWAYS MAJOR)

Modifications to:

- **API clients** (Anthropic, OpenAI, external services)
- **Payment processing** (Stripe, PayPal)
- **Email/notification services**
- **File storage** (S3, cloud storage)

**Detection patterns:**
```
# Files
**/services/**
**/integrations/**
**/clients/**

# Content patterns
httpx.AsyncClient
requests.
stripe.
anthropic.
openai.
send_email
send_notification
upload_file
```

## Detection Script

The following script detects major changes:

```bash
#!/bin/bash
# .claude/scripts/detect-major-changes.sh

MAJOR_CHANGE=false
REASONS=()

# Get changed files
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || git diff HEAD --name-only)

for file in $CHANGED_FILES; do
    # Category 1: Database
    if echo "$file" | grep -qE "(migrations|alembic|models\.py|schema\.py)"; then
        MAJOR_CHANGE=true
        REASONS+=("DATABASE: $file")
    fi

    # Category 2: Auth
    if echo "$file" | grep -qiE "(auth|permission|session)"; then
        MAJOR_CHANGE=true
        REASONS+=("AUTH: $file")
    fi

    # Category 3: New features (new files in key directories)
    if git diff --cached --diff-filter=A --name-only 2>/dev/null | grep -qE "(pages|views|routes|routers)/"; then
        MAJOR_CHANGE=true
        REASONS+=("NEW_FEATURE: $file")
    fi
done

# Check content patterns
if git diff --cached 2>/dev/null | grep -qE "(DELETE FROM|\.delete\(|CREATE TABLE|ALTER TABLE)"; then
    MAJOR_CHANGE=true
    REASONS+=("DATA_OPERATION: Detected DELETE/CREATE/ALTER")
fi

if [ "$MAJOR_CHANGE" = true ]; then
    echo "🚨 MAJOR CHANGE DETECTED"
    echo ""
    echo "Reasons:"
    for reason in "${REASONS[@]}"; do
        echo "  - $reason"
    done
    echo ""
    echo "REQUIRED GATES:"
    echo "  1. ✅ All tests pass (pytest, playwright)"
    echo "  2. ✅ UAT: User journey verified manually"
    echo "  3. ✅ Senior code review (shadow-code-reviewer)"
    echo "  4. ✅ Risk assessment (if not already done)"
    echo ""
    exit 0  # Don't block, just inform
else
    echo "✅ Standard change - normal quality gates apply"
fi
```

## Required Gates for Major Changes

When a major change is detected, the following gates are **MANDATORY**:

### Gate 1: Full Test Suite

```bash
# Backend
cd hotel-de-ville/backend && pytest -v

# Frontend
cd hotel-de-ville/frontend && npm run build && npx playwright test

# Stellaris (if modified)
cd stellaris/backend && pytest -v
cd stellaris/frontend && npm run build
```

**Criteria:** Zero failures. No skipped critical tests.

### Gate 2: User Acceptance Testing (UAT)

Construct and execute user journeys:

1. **Identify the feature** - What user capability was added/changed?
2. **Map the journey** - Start state → actions → expected outcomes
3. **Execute manually** - Walk through as a real user
4. **Verify edge cases:**
   - Empty state
   - Error conditions
   - Invalid input
   - Concurrent usage

**Output format:**
```markdown
## UAT: [Feature Name]

**Journey:** User logs in → navigates to X → performs action → sees result

**Steps Verified:**
1. ✅ User can access the feature
2. ✅ Action produces expected result
3. ✅ Error states handled gracefully
4. ✅ Edge cases work (empty, many items, special chars)

**Evidence:** [Screenshot descriptions or test output]
```

### Gate 3: Senior Code Review

Invoke `shadow-code-reviewer` agent with enhanced scrutiny:

```
Review this major change with extra scrutiny:

1. SECURITY: Any vulnerabilities introduced?
2. DATA INTEGRITY: Can this corrupt or lose data?
3. BACKWARDS COMPATIBILITY: Does this break existing functionality?
4. ROLLBACK PLAN: How do we undo this if it fails in production?
5. PERFORMANCE: Any N+1 queries or expensive operations?
```

### Gate 4: Risk Assessment

If not already assessed by Risk Manager:

- User Disruption Risk (1-10)
- Controllability/Reversibility (1-10)
- Liability/Compliance (1-10)
- AI-Specific Risk (1-10)

**Escalation:** Overall risk ≥ 7 OR any dimension ≥ 8 → Requires Johannes approval.

## Integration with Hooks

This protocol is enforced via:

1. **PreToolUse hook on git commit** - Runs detection script
2. **SubagentStart hook for TPM** - Injects major change awareness
3. **PostToolUse hook on Edit/Write** - Tracks files modified

## Bypass (Emergency Only)

For genuine emergencies only (production down, security incident):

```bash
git commit --no-verify -m "EMERGENCY: [description]"
```

Must be followed up within 24 hours with:
- Post-incident review
- Tests added
- Documentation updated
