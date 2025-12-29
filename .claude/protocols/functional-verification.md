# Functional Verification Protocol

## Purpose

This protocol ensures that features actually work as designed - not just that the code compiles or tests pass. It specifically targets bugs where:
- User settings are ignored
- Filters don't filter
- Selections don't select
- Data flow is broken despite "correct" logic

## Core Principle

> "A test that passes doesn't mean the feature works."

Many bugs survive because tests verify the _wrong thing_:
- ❌ "Button is visible" (UI test)
- ✅ "Clicking button with filter X produces data from filter X" (functional test)

## MANDATORY: User Input Flow Verification

### When Code Uses User Settings

Whenever code reads from user settings (selected chapters, filters, preferences, etc.), verify the FULL FLOW:

1. **Trace the setting from UI to effect**
   - Where is the setting stored? (state, localStorage, URL params)
   - Where is it read in the handler?
   - Is it actually passed to the data function/API call?
   - Does the result reflect the setting?

2. **Check for these anti-patterns:**

| Anti-Pattern | Example | Detection |
|--------------|---------|-----------|
| **Hardcoded override** | `items.map(i => ({...i, chapter: 1}))` | Search for hardcoded values replacing user input |
| **Missing parameter** | `api.get({type: 'verb'})` missing `chapter` | Compare function signature to call site |
| **Wrong variable** | Using `defaultChapters` instead of `selectedChapters` | Check variable names match user input source |
| **Silent fallback** | `if (items.length > 0) { navigate() }` no else | Look for missing error feedback |
| **API ignoring params** | Backend receives but doesn't use filter | Trace through backend handler |

3. **Functional verification question:**
   > "If the user selects [specific setting], does the result actually reflect [that setting]?"

### Code Review Checklist

Before approving any code that:
- Reads user preferences/settings
- Filters data based on user selection
- Calls APIs with user-provided parameters

Ask these questions:

- [ ] Is the user's selection actually being used? (not ignored, not overwritten)
- [ ] Is it passed to all relevant function calls? (API, data selectors, filters)
- [ ] If the filter finds no results, does the user get feedback?
- [ ] Have I mentally traced the data flow from selection → result?

### Example: The Bug This Protocol Would Have Caught

```typescript
// BAD - This bug survived code review:
const handleStartCases = async () => {
  // selectedChapters is from user settings - but look what happens:
  const casesWithChapter = CASE_EXERCISES.map((c) => ({ ...c, chapter: 1 }));  // ← OVERWRITES!
  const cards = selectCardsForSession(casesWithChapter, caseScores, [1], 12);   // ← HARDCODED [1]!
  // User's selectedChapters is completely ignored
};

// GOOD - User selection is actually used:
const handleStartCases = async () => {
  const cards = selectCardsForSession(CASE_EXERCISES, caseScores, selectedChapters, 12);
  if (cards.length === 0) {
    alert('No exercises found for selected chapters.');  // ← User gets feedback
  }
};
```

## Verification Steps

### Step 1: Identify User Input Dependencies

List all user inputs/settings the code depends on:
- Selected chapters
- Filter options
- Sort preferences
- Search queries
- etc.

### Step 2: Trace Each Input

For each input, trace through the code:
```
User selects → stored in → read by handler → passed to → affects result
```

### Step 3: Verify End-to-End

Either:
- Write a test that selects a specific value and verifies the result reflects it
- Manually verify in the running application
- Add logging and check the logs

### Step 4: Check Error Paths

What happens when:
- User selection produces empty results?
- API call fails?
- Invalid combinations are selected?

## Integration with Existing Protocols

This protocol complements:

- **quality-check.md**: Adds functional verification to "verify before declaring done"
- **shadow-code-reviewer.md**: Adds "user input flow" to the review checklist
- **security-audit**: Input validation covers some of this, but this focuses on "is the input USED correctly?"

## Red Flags in Code Reviews

Flag these patterns immediately:

1. **Hardcoded values replacing user input:**
   ```typescript
   // RED FLAG: Why is 1 hardcoded when we have selectedChapters?
   items.map(i => ({ ...i, chapter: 1 }))
   ```

2. **API calls missing parameters from user settings:**
   ```typescript
   // RED FLAG: Where is the chapter/filter parameter?
   getTrainingSession({ itemTypes: ['verb'], count: 12 })
   ```

3. **Silent failures on empty results:**
   ```typescript
   // RED FLAG: No else - user gets no feedback!
   if (cards.length > 0) { navigate('/page'); }
   ```

4. **Different handling for similar features:**
   ```typescript
   // RED FLAG: Why does vocab use selectedChapters but cases uses [1]?
   handleVocab: selectCards(VOCAB, scores, selectedChapters)
   handleCases: selectCards(CASES, scores, [1])  // Inconsistent!
   ```

## Stellaris Training Mode Verification

### Before declaring any Stellaris change complete:

When modifying Stellaris training modes or API integration:

1. **Test all training modes load:**
   - [ ] Vokabeln (vocabulary) - loads, shows question
   - [ ] Stammformen (verbs) - loads, shows verb form question
   - [ ] Kasusendungen (cases) - loads, shows case question

2. **Verify API data translation:**
   - [ ] Case names use German format (`Nominativ`, `Genitiv`, `Dativ`, `Akkusativ`, `Ablativ`)
   - [ ] NOT English format (`nominative`, `genitive`, `dative`, `accusative`, `ablative`)
   - [ ] `apiItemToCard()` produces cards matching expected TypeScript types

3. **Test with API enabled (not just static fallback):**
   - Check browser Network tab - is API being called?
   - Verify API response format matches expected structure
   - Confirm frontend correctly parses API response

4. **Edge cases:**
   - [ ] Chapter with no verbs (e.g., Chapter 1) - shows proper error message
   - [ ] Empty API response - falls back to static data gracefully
   - [ ] JavaScript error - ErrorBoundary catches it (no blank screen)

### The Bug This Section Would Have Caught

```typescript
// API returns English case names:
{ "question": "servus (nominative plural)", "answer": "serv-ī" }

// BAD - Frontend expected German but got English:
const caseDisplay = match[2].trim();  // "nominative plural" - WRONG!

// GOOD - Translate API response to expected format:
const caseDisplay = translateCaseName(match[2].trim());  // "Nominativ Plural" - CORRECT!
```

### Stellaris E2E Tests

Run these tests before shipping Stellaris changes:
```bash
cd stellaris/frontend && npx playwright test training-modes.spec.ts
```

## Remember

The goal isn't just "code that compiles" or "tests that pass" - it's **features that work as users expect**.
