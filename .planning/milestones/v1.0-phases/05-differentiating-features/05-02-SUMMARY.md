---
phase: 05-differentiating-features
plan: "02"
subsystem: api
tags: [gemini, google-ai, firebase-functions, cloud-functions, ai-workout, jest, ts-jest]

# Dependency graph
requires:
  - phase: 04-core-workout-loop
    provides: WorkoutContext type with cyclePhase, activeInjuries, readinessTier fields

provides:
  - Gemini-powered generateWorkout Cloud Function with minInstances: 1 and JSON response mode
  - Unit test suite verifying all WorkoutGenerationContext fields appear in Gemini prompt
  - Jest + ts-jest testing infrastructure for Cloud Functions

affects: [05-differentiating-features, ai-workout-generation]

# Tech tracking
tech-stack:
  added:
    - "@google/generative-ai ^0.21.0 — Gemini SDK replacing Anthropic"
    - "jest ^29.7.0 + ts-jest ^29.2.5 — Cloud Function unit testing"
  patterns:
    - "Gemini systemInstruction + contents format for chat prompts"
    - "responseMimeType: application/json eliminates JSON parsing brittleness"
    - "Pure function prompt builders (buildUserPrompt/buildSystemPrompt) enable unit tests without SDK calls"

key-files:
  created:
    - functions/__tests__/generateWorkout.test.ts
    - functions/__mocks__/firebase-functions.ts
    - functions/__mocks__/firebase-functions-params.ts
    - functions/__mocks__/firebase-admin.ts
    - functions/__mocks__/generative-ai.ts
  modified:
    - functions/src/generateWorkout.ts
    - functions/package.json

key-decisions:
  - "gemini-2.0-flash used (not gemini-pro) — fast, cost-effective for structured JSON generation"
  - "responseMimeType: application/json used — eliminates regex stripping and parse-retry overhead vs Anthropic text format"
  - "minInstances: 1 set — eliminates cold start for latency-sensitive workout generation path"
  - "GEMINI_API_KEY secret defined via defineSecret — must be set via firebase functions:secrets:set GEMINI_API_KEY before deploy"
  - "Functions directory is at /functions/ not SundeeFundeeRN/functions/ — plan path was off but implementation target was correct"

patterns-established:
  - "Cloud Function mock pattern: moduleNameMapper in jest config maps firebase-functions/v2/https and firebase-admin to __mocks__/ stubs"
  - "Prompt builder test pattern: test pure buildUserPrompt() function directly — no Gemini API calls needed in tests"

requirements-completed: [AIWK-01, AIWK-02]

# Metrics
duration: 15min
completed: 2026-03-15
---

# Phase 5 Plan 02: Gemini Migration Summary

**Cloud Function migrated from Anthropic claude-haiku to Gemini 2.0 Flash with JSON response mode, minInstances: 1, and 13 unit tests verifying cyclePhase/activeInjuries/readinessTier appear in the generated prompt**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-15T04:30:00Z
- **Completed:** 2026-03-15T04:45:00Z
- **Tasks:** 1 of 1
- **Files modified:** 7

## Accomplishments

- Replaced `@anthropic-ai/sdk` with `@google/generative-ai ^0.21.0` in Cloud Function
- Switched to `gemini-2.0-flash` with `responseMimeType: "application/json"` for native JSON output
- Added `minInstances: 1` and `concurrency: 80` to reduce cold start latency
- Defined `GEMINI_API_KEY` secret (removed `ANTHROPIC_API_KEY`)
- Verified all three WorkoutGenerationContext personalization fields (cyclePhase, activeInjuries, readinessTier) are already present in `buildUserPrompt` — preserved exactly
- Created 13-test Jest suite covering all context field presence/absence scenarios in generated prompt
- Built complete ts-jest + module mock infrastructure for Cloud Function unit testing

## Task Commits

1. **Task 1: Migrate generateWorkout Cloud Function from Anthropic to Gemini** - `37709d6` (feat)

## Files Created/Modified

- `functions/src/generateWorkout.ts` — Anthropic SDK replaced with GoogleGenerativeAI; Gemini format (systemInstruction + contents); JSON response mode; minInstances: 1
- `functions/package.json` — Added @google/generative-ai, jest, ts-jest; removed @anthropic-ai/sdk; added test script and jest config
- `functions/__tests__/generateWorkout.test.ts` — 13 unit tests for prompt builder with context fields
- `functions/__mocks__/firebase-functions.ts` — onCall + HttpsError stubs for Jest
- `functions/__mocks__/firebase-functions-params.ts` — defineSecret stub returning test values
- `functions/__mocks__/firebase-admin.ts` — Firestore collection/doc stubs
- `functions/__mocks__/generative-ai.ts` — GoogleGenerativeAI mock class

## Decisions Made

- `gemini-2.0-flash` chosen over `gemini-pro`: faster, cheaper, adequate for structured JSON workout generation
- `responseMimeType: "application/json"` enabled: Gemini natively returns parsed JSON, eliminating brittle text-block extraction + retry cycle that Anthropic format required
- `minInstances: 1` added per locked decision from Phase 5 planning (cold start mitigation for AI workout path)
- Prompt builder functions tested directly as pure functions — no need to invoke Gemini SDK in unit tests, making tests fast and deterministic

## Deviations from Plan

### Path Correction

**[Rule 3 - Blocking] Functions directory path mismatch between plan and repo**
- **Found during:** Task 1 (initial file read)
- **Issue:** Plan specified `SundeeFundeeRN/functions/` but actual path is `functions/` at repo root
- **Fix:** Used correct path `/Users/dustinober/Projects/Sundee-Fundee/functions/` throughout implementation
- **Files modified:** No extra files — just resolved discovery path
- **Verification:** Files compile and tests pass from correct path

---

**Total deviations:** 1 path correction (not a code issue, just plan path inaccuracy)
**Impact on plan:** None — implementation targets are correct, plan path was a documentation inconsistency only.

## User Setup Required

Before deploying the Cloud Function, the GEMINI_API_KEY secret must be set:

```bash
firebase functions:secrets:set GEMINI_API_KEY
# When prompted, paste your Gemini API key from Google AI Studio
firebase deploy --only functions
```

## Next Phase Readiness

- Cloud Function ready for testing with live Gemini API once GEMINI_API_KEY secret is set
- Test suite provides regression coverage for all AIWK-02 context field personalization requirements
- The existing `workoutPrompt.ts` prompt builders are not modified — context fields were already present from prior Anthropic implementation

---
*Phase: 05-differentiating-features*
*Completed: 2026-03-15*
