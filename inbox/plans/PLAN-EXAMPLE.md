# Plan: Audio Pronunciation Training for Stellaris
**ID:** PLAN-2025-001
**Priority:** high
**Branch:** feature/audio-pronunciation
**Status:** queued
**Created:** 2025-12-28

---

## Dependencies

**Blocks:** PLAN-2025-003 (Advanced Speech Recognition)
**Blocked by:** None
**Conflicts with:** None

---

## File Touchpoints

- `stellaris/routes/exercises.py` (modify - add audio exercise endpoints)
- `stellaris/models/exercise.py` (modify - add audio_url field)
- `stellaris/frontend/components/AudioPlayer.tsx` (new)
- `stellaris/frontend/components/PronunciationExercise.tsx` (new)
- `stellaris/frontend/stores/exerciseStore.ts` (modify)
- `stellaris/tests/test_audio_exercises.py` (new)
- `stellaris/tests/frontend/AudioPlayer.test.tsx` (new)

---

## Objectives

- [ ] Add audio playback capability to vocabulary exercises
- [ ] Implement pronunciation practice interface
- [ ] Store audio files in CDN and reference in database
- [ ] Add audio upload endpoint for admin
- [ ] Create tests for audio functionality

---

## Workstreams

### Workstream 1: Backend Audio API
**Agent:** artificial-shadow-dev
**Files:** stellaris/routes/exercises.py, stellaris/models/exercise.py
**Complexity:** medium
**Estimated time:** 3h

**Description:**
Add audio support to the Stellaris exercise API.

Requirements:
- Add `audio_url` field to Exercise model (nullable, stores CDN URL)
- Add POST /api/admin/exercises/{id}/audio endpoint (upload audio file)
  - Accept multipart/form-data with audio file
  - Validate file type (mp3, wav, ogg)
  - Upload to CDN (or local storage for now)
  - Store URL in database
- Modify GET /api/exercises/{id} to include audio_url in response
- Add audio file size limit (max 5MB)

Acceptance criteria:
- Exercise model includes audio_url field
- Audio upload endpoint works with valid files
- Audio URL returned in exercise GET response
- Invalid file types rejected with clear error message

### Workstream 2: Frontend Audio Player
**Agent:** artificial-shadow-dev
**Files:** stellaris/frontend/components/AudioPlayer.tsx, stellaris/frontend/components/PronunciationExercise.tsx
**Complexity:** medium
**Estimated time:** 3h

**Description:**
Create React components for audio playback and pronunciation practice.

Requirements:
- AudioPlayer component:
  - Props: audioUrl, autoPlay (optional)
  - Play/pause button with visual feedback
  - Loading state while audio loads
  - Error state if audio fails to load
  - Use HTML5 <audio> element
  - Accessible (ARIA labels, keyboard controls)

- PronunciationExercise component:
  - Extends existing exercise interface
  - Shows word/phrase to pronounce
  - AudioPlayer with native speaker pronunciation
  - "Listen again" button
  - Child-friendly UI (large buttons, clear labels)

Acceptance criteria:
- AudioPlayer renders and plays audio correctly
- PronunciationExercise integrates AudioPlayer
- Components are accessible (keyboard navigation)
- Error handling for missing/broken audio files

### Workstream 3: State Management Integration
**Agent:** artificial-shadow-dev
**Files:** stellaris/frontend/stores/exerciseStore.ts
**Complexity:** low
**Estimated time:** 1h

**Description:**
Update the exercise store to handle audio URLs.

Requirements:
- Add audio_url to Exercise type definition
- Fetch audio_url from API when loading exercises
- Preload audio files for better UX (optional, nice-to-have)

Acceptance criteria:
- Exercise type includes audio_url field
- Audio URL fetched and stored correctly

### Workstream 4: Testing
**Agent:** qa-engineer
**Files:** stellaris/tests/test_audio_exercises.py, stellaris/tests/frontend/AudioPlayer.test.tsx
**Complexity:** medium
**Estimated time:** 2h

**Description:**
Write comprehensive tests for audio functionality.

Backend tests (pytest):
- Test audio upload endpoint with valid file
- Test audio upload with invalid file type
- Test audio upload with oversized file
- Test exercise GET includes audio_url

Frontend tests (React Testing Library):
- Test AudioPlayer renders correctly
- Test play/pause functionality
- Test error handling for broken audio URLs
- Test PronunciationExercise integration

Acceptance criteria:
- All backend tests pass
- All frontend tests pass
- Code coverage > 80% for new code

---

## Success Criteria

- [ ] All workstreams executed successfully
- [ ] All tests pass (pytest + React Testing Library)
- [ ] Code review approved (shadow-code-reviewer)
- [ ] No security issues (security-audit)
- [ ] PR created and ready for merge
- [ ] Audio playback works in manual testing (user verification)

---

## Cost Estimation

**Estimated API cost:** $3.50
- Claude Sonnet: 25 requests × $0.10 = $2.50
- OpenAI embeddings: 40 chunks × $0.0001 = $0.004
- Code review: ~$1.00

**Estimated build time:** 9 hours (3 + 3 + 1 + 2)
**User benefit:** High - Critical feature for language learning app
**ROI:** ★★★★★ (5 stars)

**Justification:**
Audio pronunciation is essential for language learning. This feature:
- Significantly improves learning outcomes (hearing native pronunciation)
- Unblocks PLAN-2025-003 (Advanced Speech Recognition)
- Highly requested by beta testers
- Differentiates Stellaris from text-only apps

Cost-to-benefit ratio is excellent ($3.50 for critical feature).

---

## Notes

### Technical Constraints
- Audio files should be compressed (mp3 preferred)
- Need to decide on CDN (AWS S3, Cloudflare, or local storage for MVP)
- Consider adding audio waveform visualization in future iteration

### Design Decisions
- Using HTML5 <audio> for maximum browser compatibility
- No recording functionality in this plan (deferred to PLAN-2025-003)
- Child-friendly UI (large buttons, simple controls)

### Integration Points
- Integrates with existing exercise system
- Will be extended by speech recognition feature later

### Rollback Plan
If issues arise post-deployment:
- Feature flag to disable audio UI elements
- Database migration is additive (audio_url nullable), safe to rollback

---

## Risk Assessment

**Assessed by:** Risk Manager
**Date:** 2025-12-28 15:30 UTC
**Overall Risk Score:** 4/10 (Medium) 🟡

### Risk Breakdown

#### User Disruption Risk: 3/10 (Low)

**Risk factors identified:**
- ✅ Additive feature (no breaking changes) (-2 points)
- ✅ Audio is optional enhancement (-1 point)
- ✅ Feature flag available for rollback (-1 point)
- ⚠️ Could fail if CDN misconfigured (+2 points)

**Base score:** 6
**Adjusted score:** 3/10

**Explanation:** This is a purely additive feature. Existing functionality remains unchanged. Audio playback is an enhancement that doesn't affect users who don't use it. If audio files fail to load, the exercise still works without audio. Low user disruption risk.

#### Controllability Risk: 2/10 (Low)

**Risk factors identified:**
- ✅ Fully reversible via feature flag (-2 points)
- ✅ Changes isolated to audio functionality (-1 point)
- ✅ Database migration is additive (audio_url nullable) (-1 point)
- ✅ Well-defined workstreams with clear scope (-1 point)
- ⚠️ Requires CDN configuration (external dependency) (+2 points)

**Base score:** 5
**Adjusted score:** 2/10

**Explanation:** All changes are well-contained and reversible. The database migration adds a nullable field, so it can be rolled back safely. CDN dependency adds slight complexity but doesn't affect core controllability.

#### Liability & Compliance Risk: 5/10 (Medium)

**Risk factors identified:**
- ⚠️ Audio files may have copyright issues (+3 points)
- ⚠️ WCAG: Need captions/transcripts for deaf users (+3 points)
- ✅ No PII collection (-2 points)
- ✅ No new data processing (-1 point)

**Base score:** 6
**Adjusted score:** 5/10

**Explanation:**
- **Copyright:** Audio files with native speaker pronunciations must be properly licensed. Verify all audio is either original recordings or properly licensed.
- **Accessibility (WCAG):** Audio-only content creates accessibility barriers for deaf/hard-of-hearing users. Must provide text alternatives (e.g., phonetic transcriptions or visual pronunciation guides).
- **COPPA:** Since Stellaris is a children's app, ensure audio content is age-appropriate and doesn't inadvertently collect voice data.

**Mitigation required:** See recommendations below.

#### AI-Specific Risk: 1/10 (Low)

**Risk factors identified:**
- ✅ No AI/LLM usage (0 points)
- ✅ Static audio files only (+1 point for manual curation)

**Base score:** 1
**Adjusted score:** 1/10

**Explanation:** This plan doesn't involve AI or LLMs. Audio files are manually curated static files. Very low AI risk.

### Risk Mitigation Recommendations

1. **Copyright Compliance**
   - **Mitigation:** Verify all audio files are either:
     - Original recordings by St. Gallen Endowment staff
     - Licensed from audio libraries with appropriate usage rights
     - Public domain/Creative Commons licensed
   - **Owner:** Product team (before deployment)
   - **Validation:** Maintain audio source documentation

2. **WCAG Accessibility**
   - **Mitigation:** Add to success criteria:
     - Provide phonetic transcription alongside audio
     - Visual pronunciation guides (IPA notation or kid-friendly guides)
     - Ensure all UI controls are keyboard accessible
   - **Owner:** artificial-shadow-dev (frontend workstream)
   - **Validation:** Accessibility audit before deployment

3. **Age-Appropriate Content**
   - **Mitigation:** Review all audio content for age-appropriateness
   - **Owner:** Product team
   - **Validation:** Manual review of audio files

4. **Gradual Rollout**
   - **Mitigation:** Use feature flag for phased rollout (10% → 50% → 100%)
   - **Owner:** TPM Orchestrator (deployment)
   - **Validation:** Monitor error rates and user feedback

### Approval Decision

✅ **APPROVED for autonomous execution**

**Reasoning:**
- Overall risk score is 4/10 (Medium), below the 7/10 threshold
- No critical risks identified
- All medium risks have clear mitigations
- User disruption is minimal (additive feature)
- Controllability is high (reversible, feature-flagged)
- Compliance risks are manageable with recommended mitigations

**Conditions:**
- Must implement WCAG accessibility features (phonetic transcriptions)
- Must verify audio licensing before deployment
- Must use feature flag for gradual rollout

**Next steps:**
- Portfolio Manager may proceed with scheduling
- TPM Orchestrator should verify mitigations in success criteria
- Quality gates (tests, review, security) apply as usual

---

## Execution Metadata

*Auto-populated by Portfolio Manager and TPM Orchestrator:*

**Execution started:** [timestamp]
**Execution completed:** [timestamp]
**TPM Orchestrator ID:** [agent-id]
**PR URL:** [github-url]
**Final status:** [COMPLETED|FAILED]

---

## Conflict Resolution History

*Auto-populated by Portfolio Manager if conflicts detected:*

None yet.
