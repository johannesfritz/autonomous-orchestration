# Quality Check Protocol

## Core Philosophy
- "Should work" ≠ "does work" - Pattern matching isn't enough
- Untested code is just a guess, not a solution
- The user trusts this system with autonomy - don't break that trust
- **EVERY change must be verified, no matter how small**

## MANDATORY: Verify Before Declaring Done

**For EVERY code change, you MUST:**

1. **Run the relevant test command:**
   ```bash
   # Backend change? Run:
   cd hotel-de-ville/backend && pytest -v -k "test_name" # or full suite

   # Frontend change? Run:
   cd hotel-de-ville/frontend && npm run build

   # API change? Test the endpoint:
   curl http://localhost:8000/api/endpoint
   ```

2. **Report the actual result:**
   - ✅ "Tests passed: X passed, 0 failed"
   - ❌ "Tests failed: [specific error]" → Fix before continuing

3. **Never say "this should work" - say "I verified it works because [evidence]"**

## The 30-Second Reality Check

Before claiming something is "done", answer YES to ALL:

1. Did I run/build the code?
2. Did I trigger the exact feature I changed?
3. Did I see the expected result with my own observation?
4. Did I check for error messages?
5. Would I bet $100 this works?

## Red Flag Phrases - NEVER Say These

- "This should work now"
- "I've fixed the issue" (without verification)
- "Try it now" (without trying it myself first)
- "The logic is correct so..."
- "I believe this will..."

## Specific Test Requirements

| Change Type | Required Verification |
|-------------|----------------------|
| Python code | Run pytest or execute the specific function |
| API endpoint | Make the actual API call, check response |
| Database | Query the database, verify data |
| Config | Restart service, verify it loads |
| Frontend | Build succeeds, component renders |
| Import/dependency | Import works, no circular deps |
| Stellaris frontend | `cd stellaris/frontend && npm run build && npx playwright test` |
| Stellaris training modes | Test Stammformen, Kasusendungen, and Vokabeln all load |
| Documentation markdown | TOC freshness verified (pre-commit hook handles this) |
| New markdown files | Add `<!-- START doctoc -->` and `<!-- END doctoc -->` markers |
| Documentation search indexing | Run search tests, verify (a) entries created, (b) entries updated |

## Before Every Edit/Write

Ask yourself:
1. Do I understand what I'm changing?
2. Have I read the existing code first?
3. Am I making the minimal change needed?
4. Will this break anything else?

## Before Every Bash Command

Ask yourself:
1. Is this command safe?
2. Am I in the right directory?
3. Do I understand what this will output?
4. If destructive, is it scoped to the project folder?

## The Embarrassment Test

> "If the user tests this immediately and it fails, will I have wasted their time?"

## Time Reality

- Time saved skipping verification: 30 seconds
- Time wasted when it doesn't work: 30+ minutes
- User trust lost: Hard to regain

## Remember

You have been granted significant autonomy. This trust is earned by:
1. Testing changes before declaring them complete
2. Being honest when something might not work
3. Catching your own mistakes before the user does
4. Running the test suite after significant changes

---

## Documentation Search Testing Checklist

**When modifying documentation search indexing or retrieval:**

### Unit Tests (Parser Logic)
- [ ] Test H2/H3 section extraction from markdown files
- [ ] Test BLUF generation from first paragraph
- [ ] Test tag extraction from section content
- [ ] Test word count calculation accuracy
- [ ] Test section ID format (YYYY-MM-DD-DOC-{file}-{position})
- [ ] Test edge cases: empty files, special characters, very long sections

### Integration Tests (Qdrant Operations)
- [ ] **(a) Requirement:** Test Qdrant entries are created when docs are indexed
  - Run: `pytest -v shadow-api/tests/test_qdrant_sync.py::TestQdrantIndexing::test_section_creates_qdrant_entry`
- [ ] **(b) Requirement:** Test Qdrant entries are updated when docs are modified
  - Run: `pytest -v shadow-api/tests/test_qdrant_sync.py::TestQdrantUpdates::test_section_update_creates_new_version`
- [ ] Test dual embeddings (BLUF + content) are generated
- [ ] Test soft deletion (is_deleted flag)
- [ ] Test versioning (is_current flag)
- [ ] Test search filtering (is_current=True, is_deleted=False, file_exists=True)

### E2E Tests (Full Workflow)
- [ ] Test parse → embed → store → search workflow
- [ ] Test search quality metrics (F2 score >= 0.7)
- [ ] Test BLUF re-ranking improves precision
- [ ] Test documentation collection management

### Commands to Run
```bash
# Run all documentation search tests
cd shadow-api && pytest -v tests/test_documentation_search.py tests/test_qdrant_sync.py

# Run specific requirement validation
pytest -v -k "test_section_creates_qdrant_entry"  # Requirement (a)
pytest -v -k "test_section_update_creates_new_version"  # Requirement (b)

# Run E2E workflow tests
pytest -v tests/test_integration.py::TestDocumentationSearchE2E

# Run search quality tests
pytest -v tests/test_integration.py::TestSearchQualityMetrics
```

### Manual Verification (if real Qdrant available)
- [ ] Index a sample CLAUDE.md file
- [ ] Verify entries appear in Qdrant collection "documentation"
- [ ] Modify the CLAUDE.md file
- [ ] Re-index and verify version increments
- [ ] Search for content and verify relevant sections returned
- [ ] Check F2 score meets >= 0.7 threshold

### Expected Results
- ✅ All unit tests pass (parser extracts sections correctly)
- ✅ All integration tests pass (Qdrant operations work)
- ✅ All E2E tests pass (full workflow completes)
- ✅ F2 score >= 0.7 (search quality threshold)
- ✅ Requirement (a) validated: Entries created on index
- ✅ Requirement (b) validated: Entries updated on modify
