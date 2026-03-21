---
phase: 02-cloud-functions
plan: 01
subsystem: backend/cloud-functions
tags: [firebase-functions, gemini, ai-workout, cloud-functions]
dependency_graph:
  requires: [02-00]
  provides: [generateAIWorkout-cloud-function, functions-scaffold]
  affects: [pwa/src/routes/AIWorkoutConfig.tsx, firebase.json]
tech_stack:
  added: [firebase-functions@^6, firebase-admin@^12, "@google/genai@^1", "@modelcontextprotocol/sdk@^1"]
  patterns: [Firebase-Functions-v2-onCall, Gemini-generateContent, TDD-handler-capture]
key_files:
  created:
    - functions/src/generateAIWorkout.ts
    - functions/src/index.ts
    - functions/.secret.local.example
    - functions/__mocks__/firebase-functions.ts
    - functions/__mocks__/firebase-functions-params.ts
    - functions/__mocks__/firebase-admin.ts
    - functions/__mocks__/generative-ai.ts
    - functions/__mocks__/stripe.ts
    - functions/__mocks__/firebase-functions-logger.ts
  modified:
    - functions/package.json
    - functions/tsconfig.json
    - functions/src/__tests__/generateAIWorkout.test.ts
    - firebase.json
    - .gitignore
    - pwa/src/routes/AIWorkoutConfig.tsx
decisions:
  - "Extract handler capture pattern via getLastHandler() mock to enable direct unit testing of onCall handlers without TypeScript type conflicts"
  - "Add @modelcontextprotocol/sdk as production dependency because @google/genai SDK types require it"
  - "Offline fallback retained in AIWorkoutConfig.tsx after Cloud Function failure — Cloud Function is additive, not replacing"
metrics:
  duration_minutes: 45
  completed_date: "2026-03-21"
  tasks_completed: 2
  files_changed: 14
---

# Phase 02 Plan 01: Cloud Functions Scaffold and generateAIWorkout Summary

**One-liner:** Firebase Functions v2 scaffold with generateAIWorkout onCall implementing Gemini-backed AI workout generation with auth gating, input validation, and offline fallback wiring in the PWA client.

## What Was Built

### Task 1: Functions scaffold and firebase.json update

Set up the complete functions/ directory infrastructure needed for all three Cloud Functions:

- Updated `functions/package.json` with serve/deploy scripts and jest moduleNameMapper for all 6 mock files
- Created `functions/src/index.ts` with Firebase Admin init guard and generateAIWorkout export
- Created `functions/.secret.local.example` documenting 3 required secrets (GEMINI_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET)
- Added `"functions"` block to `firebase.json` with predeploy build hook
- Updated `.gitignore` to exclude `functions/lib/` and `functions/.secret.local`
- Created 6 `__mocks__/` files for jest module resolution (firebase-functions, firebase-functions-params, firebase-admin, generative-ai, stripe, firebase-functions-logger)

### Task 2: generateAIWorkout implementation and client wiring

Implemented the complete `generateAIWorkout` Cloud Function following TDD:

**RED:** Updated `generateAIWorkout.test.ts` with 5 real behavioral assertions:
- Unauthenticated calls throw `HttpsError('unauthenticated')`
- Valid call returns `{ exercises: [...], coachingSummary: string }`
- Missing timeMinutes/focus/equipment throws `HttpsError('invalid-argument')`

**GREEN:** Implemented `generateAIWorkout.ts`:
- Auth gate: `if (!request.auth)` throws `HttpsError('unauthenticated')`
- Input validation for timeMinutes, focus, equipment
- Gemini prompt built from full WorkoutGenerationContext fields
- Calls `ai.models.generateContent()` with `responseMimeType: 'application/json'`
- Parses JSON response; strips markdown code fences if present
- Logs via `firebase-functions/logger` (uid, context summary, errors)
- Returns `{ coachingSummary, exercises }` to client

**Client wiring:** Updated `AIWorkoutConfig.tsx` to try Cloud Function via `httpsCallable(functions, 'generateAIWorkout')` first, constructing a full `GeneratedWorkout` object from the response, then falling back to `generateOfflineWorkout(context)` on any failure.

## Test Results

- `functions/src/__tests__/generateAIWorkout.test.ts`: 5/5 tests PASS
- `pwa vitest run`: 773/773 tests PASS (no regressions)
- `functions npx tsc --noEmit`: PASS
- `pwa npx tsc -b --noEmit`: PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Mock circular require issue in test setup**
- **Found during:** Task 2 TDD RED phase
- **Issue:** Tests using `jest.mock('firebase-functions/v2/https', () => require('../../__mocks__/firebase-functions'))` caused infinite recursion — Jest's module resolution mapped `firebase-functions/v2/https` to the mock file, and then `require` inside the factory also resolved to the mock, creating a call stack overflow
- **Fix:** Used the `moduleNameMapper` in `package.json` as the sole resolution mechanism; tests import directly from mapped paths and use `require('../../__mocks__/firebase-functions')` with explicit path to bypass Jest's module mapping
- **Files modified:** `functions/src/__tests__/generateAIWorkout.test.ts`, `functions/__mocks__/firebase-functions.ts` (added `getLastHandler()` export)
- **Commit:** 7312214

**2. [Rule 3 - Blocking] TypeScript type conflict calling onCall result**
- **Found during:** Task 2 TDD RED phase
- **Issue:** TypeScript typed `generateAIWorkout` as the Firebase Functions callable type (`(req, res) => void`), not the handler return type; direct invocation failed TS type checking
- **Fix:** Used handler capture pattern — `__mocks__/firebase-functions.ts` stores the last registered handler via `getLastHandler()`, tests call the captured handler directly rather than the exported callable
- **Files modified:** `functions/__mocks__/firebase-functions.ts`, `functions/src/__tests__/generateAIWorkout.test.ts`

**3. [Rule 3 - Blocking] @google/genai requires @modelcontextprotocol/sdk**
- **Found during:** Task 1 TS compilation verification
- **Issue:** `@google/genai` v1 types reference `@modelcontextprotocol/sdk/client/index.js` which wasn't installed
- **Fix:** `npm install @modelcontextprotocol/sdk` inside `functions/`; added to `functions/package.json` dependencies
- **Files modified:** `functions/package.json`, `functions/package-lock.json`
- **Commit:** 7312214

## Commits

| Hash | Type | Description |
|------|------|-------------|
| c4b24da | feat | Scaffold functions/ directory and update firebase.json |
| 7312214 | feat | Implement generateAIWorkout Cloud Function with offline fallback |

## Self-Check: PASSED

All key files exist on disk and both commits are present in git history.

| Check | Result |
|-------|--------|
| functions/src/generateAIWorkout.ts | FOUND |
| functions/src/index.ts | FOUND |
| functions/.secret.local.example | FOUND |
| 02-01-SUMMARY.md | FOUND |
| Commit c4b24da | FOUND |
| Commit 7312214 | FOUND |
