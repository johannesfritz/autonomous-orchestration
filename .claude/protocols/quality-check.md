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
