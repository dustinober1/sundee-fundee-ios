---
phase: 03-security-hardening
plan: "02"
subsystem: cloud-functions
tags: [rate-limiting, security, firestore, tdd]
dependency_graph:
  requires: [02-02]
  provides: [SEC-04]
  affects: [generateAIWorkout]
tech_stack:
  added: []
  patterns: [firestore-transaction-rate-limit, tdd-red-green]
key_files:
  created: []
  modified:
    - functions/src/generateAIWorkout.ts
    - functions/__mocks__/firebase-admin-firestore.ts
    - functions/src/__tests__/generateAIWorkout.test.ts
decisions:
  - Firestore transaction enforces atomic rate limit check — prevents race conditions on concurrent calls
  - Rate limit doc path users/{uid}/rateLimits/aiWorkout with {date, count} structure
  - DAILY_AI_LIMIT = 5 as named constant
  - require('firebase-admin/firestore') in tests (not relative path) so Jest moduleNameMapper shares same module instance as implementation
metrics:
  duration: "2min"
  completed: "2026-03-21"
  tasks_completed: 2
  files_modified: 3
---

# Phase 03 Plan 02: Rate Limiting for generateAIWorkout Summary

**One-liner:** Firestore transaction rate limiter capping AI workout generation at 5 calls per user per UTC day, with TDD-driven implementation.

## Objective

Add SEC-04 rate limiting to the generateAIWorkout Cloud Function to prevent abuse of the Gemini API endpoint (each call incurs cost). Enforced via a Firestore transaction counter at `users/{uid}/rateLimits/aiWorkout`.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Extend Firestore mock + add failing rate limit tests (RED) | 506e116 | Complete |
| 2 | Implement rate limiting in generateAIWorkout.ts (GREEN) | 707a147 | Complete |

## Key Changes

### functions/__mocks__/firebase-admin-firestore.ts
- Added `runTransaction` to `stableDb` — executes callback with a transaction mock that delegates `get/set/update` to the shared mutable handlers
- Added `collection()` method to `stableDocRef` for nested collection chaining — supports `collection('users').doc(uid).collection('rateLimits').doc('aiWorkout')` path
- Existing test control API (`setMockGetResult`, `resetFirestoreMocks`, `getHandlers`) unchanged

### functions/src/generateAIWorkout.ts
- Added `import { getFirestore } from 'firebase-admin/firestore'`
- Added `const DAILY_AI_LIMIT = 5`
- Inserted rate limit check between auth gate and input validation:
  - Computes `today = new Date().toISOString().slice(0, 10)` (UTC date string)
  - Runs `db.runTransaction()` to atomically read-then-write the rate limit counter
  - If `count >= 5` and same day: throws `HttpsError('resource-exhausted')`
  - If same day and under limit: increments `count`
  - If new day or no doc: sets `{ date: today, count: 1 }`

### functions/src/__tests__/generateAIWorkout.test.ts
- Added `require('firebase-admin/firestore')` import for test control API
- Added `describe('rate limiting (SEC-04)')` with 4 test cases:
  1. First call (no doc) — succeeds, creates counter at count=1
  2. Under-limit call (count=3) — succeeds, increments to count=4
  3. At-limit call (count=5) — rejects with `resource-exhausted`
  4. New day call (count=5 yesterday) — succeeds, resets counter to count=1

## Test Results

```
Test Suites: 3 passed, 3 total
Tests:       18 passed, 18 total
```

- 5 existing tests: all pass (no regressions)
- 4 new rate limit tests: all pass

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Require path for Firestore mock in test**
- **Found during:** Task 2 GREEN run
- **Issue:** Test required `'../../__mocks__/firebase-admin-firestore'` (relative path), which created a separate module instance from the one Jest injected via `moduleNameMapper`. Result: `mockFirestore.resetFirestoreMocks is not a function`.
- **Fix:** Changed require to `'firebase-admin/firestore'` (the mapped name), matching the same pattern used in `createCheckoutSession.test.ts`. This ensures Jest shares the same module instance.
- **Files modified:** `functions/src/__tests__/generateAIWorkout.test.ts`
- **Commit:** 707a147 (included in Task 2 commit)

## Self-Check: PASSED

- functions/src/generateAIWorkout.ts: FOUND
- functions/__mocks__/firebase-admin-firestore.ts: FOUND
- functions/src/__tests__/generateAIWorkout.test.ts: FOUND
- .planning/phases/03-security-hardening/03-02-SUMMARY.md: FOUND
- Commit 506e116 (RED): FOUND
- Commit 707a147 (GREEN): FOUND
- All 18 tests pass
