---
phase: 02-cloud-functions
plan: "00"
subsystem: testing
tags: [firebase-functions, jest, ts-jest, typescript, stripe, gemini, cloud-functions]

requires: []
provides:
  - Test stubs for generateAIWorkout Cloud Function (BACK-01): auth gate, response shape, validation
  - Test stubs for createStripeCheckoutSession + createStripePortalSession (BACK-02): auth gate, URL, metadata
  - Test stubs for stripeWebhook (BACK-03): signature verification, entitlement write, subscription deleted
  - functions/ directory scaffold with package.json and tsconfig.json
affects:
  - 02-01-generate-ai-workout
  - 02-02-stripe-checkout

tech-stack:
  added:
    - jest@^29 (test runner in functions/)
    - ts-jest@^29 (TypeScript Jest transform)
    - "@types/jest@^29"
    - firebase-functions@^6 (will be used by implementation plans)
    - firebase-admin@^12 (will be used by implementation plans)
    - "@google/genai@^1 (will be used by BACK-01)"
    - stripe@^17 (will be used by BACK-02 and BACK-03)
  patterns:
    - Jest with ts-jest preset for Cloud Functions TypeScript testing
    - Intentionally-failing RED stubs as behavioral specification before implementation

key-files:
  created:
    - functions/package.json
    - functions/tsconfig.json
    - functions/src/__tests__/generateAIWorkout.test.ts
    - functions/src/__tests__/createCheckoutSession.test.ts
    - functions/src/__tests__/stripeWebhook.test.ts
  modified: []

key-decisions:
  - "Jest with ts-jest used for Cloud Functions tests (separate from PWA's vitest) — functions/ has its own test runner in its own package.json"
  - "All dependencies pre-installed in Wave 0 so Plans 02-01 and 02-02 can start implementing immediately"

patterns-established:
  - "Pattern 1: Wave 0 RED stubs — all test stubs fail intentionally with expect(true).toBe(false) and a comment indicating which plan implements them"
  - "Pattern 2: functions/ is an independent Node.js package with its own tsconfig.json targeting commonjs/es2017 — separate from PWA's ESM build"

requirements-completed: [BACK-01, BACK-02, BACK-03]

duration: 2min
completed: 2026-03-21
---

# Phase 02 Plan 00: Cloud Functions Test Stubs (Wave 0) Summary

**12 intentionally-failing test stubs across three Cloud Functions (auth gate, response shape, entitlement write) establishing behavioral contracts before implementation**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-21T17:15:15Z
- **Completed:** 2026-03-21T17:16:49Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Created `functions/` directory scaffold (package.json, tsconfig.json) with jest + ts-jest configured for TypeScript
- Installed all Cloud Functions dependencies: firebase-functions, firebase-admin, @google/genai, stripe
- Wrote 3 behavioral test stubs for `generateAIWorkout` (BACK-01: auth gate, response shape, input validation)
- Wrote 5 behavioral test stubs for `createStripeCheckoutSession` + `createStripePortalSession` (BACK-02: auth gate, URL return, customer metadata)
- Wrote 4 behavioral test stubs for `stripeWebhook` (BACK-03: missing signature, entitlement activated, entitlement deactivated, received response)
- Confirmed all 12 tests fail as expected RED; TypeScript compiles cleanly

## Task Commits

1. **Task 1: Set up test infrastructure and create test stubs** - `4a6d104` (test)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `functions/package.json` - Node 20 package with jest/ts-jest config and all runtime/dev dependencies
- `functions/tsconfig.json` - CommonJS compilation targeting es2017 with strict mode
- `functions/src/__tests__/generateAIWorkout.test.ts` - 3 RED stubs: unauthenticated, response shape, validation
- `functions/src/__tests__/createCheckoutSession.test.ts` - 5 RED stubs: checkout auth, URL, metadata; portal auth, URL
- `functions/src/__tests__/stripeWebhook.test.ts` - 4 RED stubs: signature missing, entitlement true, entitlement false, received

## Decisions Made

- Jest with ts-jest used for Cloud Functions tests rather than vitest — functions/ is a separate Node.js package with its own test runner, keeping it independent from the PWA's vitest setup
- All production dependencies pre-installed in Wave 0 so implementing plans (02-01, 02-02) can start coding without an install step

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required for this Wave 0 stub plan.

## Next Phase Readiness

- `functions/src/__tests__/` contains behavioral contracts for all three Cloud Functions
- Plan 02-01 can implement `generateAIWorkout` against the RED stubs in `generateAIWorkout.test.ts`
- Plan 02-02 can implement `createCheckoutSession` and `stripeWebhook` against their respective RED stubs
- No blockers

## Self-Check

- [x] `functions/package.json` — created
- [x] `functions/tsconfig.json` — created
- [x] `functions/src/__tests__/generateAIWorkout.test.ts` — created
- [x] `functions/src/__tests__/createCheckoutSession.test.ts` — created
- [x] `functions/src/__tests__/stripeWebhook.test.ts` — created
- [x] Commit `4a6d104` — confirmed

## Self-Check: PASSED

---
*Phase: 02-cloud-functions*
*Completed: 2026-03-21*
