---
phase: 07-polish-and-pre-launch
plan: "03"
subsystem: payments
tags: [stripe, firebase-functions, cloud-functions, account-deletion, data-export, react-native, art-deco]

# Dependency graph
requires:
  - phase: 07-02
    provides: exportUserData function, RepoBundle type, CSV formatters
  - phase: 06-subscriptions-and-monetization
    provides: stripeWebhook, RevenueCat entitlement pipeline
provides:
  - deleteAccount Cloud Function (RC revoke + Stripe cancel + Firestore recursiveDelete + Auth deleteUser)
  - stripeSubscriptionId persisted to /users/{uid} on subscription.created
  - Settings Export Data section (CSV zip / JSON)
  - Settings Danger Zone (Delete Account for auth, Clear Local Data for guest)
  - Two-step Delete Account confirmation with "DELETE" text input and export data link
  - Goodbye screen (post-deletion farewell with Done -> sign-in)
affects: [app-store-review, play-store-review, 07-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - deleteAccount follows best-effort pattern: RC and Stripe errors logged but never block Firestore/Auth cleanup
    - jest.mock() used in place of direct __mocks__ imports — ensures test and production code share the same mock reference
    - testPathIgnorePatterns excludes lib/ from Jest to prevent compiled JS test artifacts from running alongside TypeScript source tests

key-files:
  created:
    - functions/src/deleteAccount.ts
    - functions/__tests__/deleteAccount.test.ts
    - SundeeFundeeRN/app/(app)/goodbye.tsx
  modified:
    - functions/src/stripeWebhook.ts
    - functions/src/index.ts
    - functions/__mocks__/stripe.ts
    - functions/__mocks__/firebase-admin.ts
    - functions/src/__tests__/stripeWebhook.test.ts
    - functions/src/__tests__/createCheckoutSession.test.ts
    - functions/package.json
    - SundeeFundeeRN/app/(app)/(tabs)/settings.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/__tests__/settings.test.tsx

key-decisions:
  - "deleteAccount execution order: RC revoke (best-effort) -> Stripe cancel (best-effort) -> db.recursiveDelete -> admin.auth().deleteUser"
  - "Stripe cancel skipped if stripeSubscriptionId missing from /users/{uid} — no error thrown"
  - "jest.mock() in test files rather than direct __mocks__ imports — ensures same mock reference in test and module under test"
  - "testPathIgnorePatterns: /lib/ added to Jest config to exclude compiled artifacts from test runs"
  - "settings.tsx imports callCloudFunction platform wrapper — not httpsCallable directly — for cross-platform compatibility"

patterns-established:
  - "Best-effort external API wrapper: try/catch around RC and Stripe calls, log error, continue deletion"
  - "Two-step destructive action pattern: tap -> modal with consequences list + export link + type DELETE -> confirm"
  - "Danger Zone section: red-tinted border/background to visually distinguish from normal settings"

requirements-completed:
  - PLAT-04
  - PLAT-07

# Metrics
duration: 14min
completed: 2026-03-15
---

# Phase 7 Plan 03: Account Deletion and Data Export Summary

**deleteAccount Cloud Function with RC+Stripe+Firestore+Auth cleanup, stripeSubscriptionId gap fixed, Settings Export Data and Danger Zone with two-step delete confirmation, and Art Deco goodbye screen**

## Performance

- **Duration:** 14 min
- **Started:** 2026-03-15T19:54:07Z
- **Completed:** 2026-03-15T20:08:07Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- deleteAccount callable Cloud Function: RC revoke -> Stripe cancel -> db.recursiveDelete -> admin.auth().deleteUser, with best-effort wrapping for external API calls
- Fixed stripeWebhook gap: stripeSubscriptionId now persisted to /users/{uid} on subscription.created/updated so deleteAccount can find and cancel it
- Settings screen Danger Zone: authenticated users see "Delete Account" (two-step confirmation with "DELETE" text input and export data suggestion link), guest users see "Clear Local Data"
- Settings screen Data section: Export Data button opens CSV zip / JSON format picker, calls exportUserData from Plan 02
- Goodbye screen: Art Deco farewell page (cream/navy/orange) with Done -> /sign-in navigation
- Fixed pre-existing test failures: stripeWebhook and createCheckoutSession tests used direct __mocks__ imports instead of jest.mock(), causing mock reference mismatch

## Task Commits

Each task was committed atomically:

1. **TDD RED: deleteAccount tests** - `671af0e` (test)
2. **Task 1: deleteAccount Cloud Function + stripeWebhook fix** - `0b96164` (feat)
3. **Task 2: Settings Export Data + Danger Zone + goodbye screen** - `8cf8a21` (feat)

**Plan metadata:** (docs commit — see below)

_Note: Task 1 used TDD: RED commit first, then GREEN (combined with implementation)_

## Files Created/Modified
- `functions/src/deleteAccount.ts` - Callable Cloud Function: RC revoke + Stripe cancel + Firestore recursiveDelete + Auth deleteUser
- `functions/__tests__/deleteAccount.test.ts` - 7 tests: auth guard, full flow, missing subscription ID, best-effort errors
- `functions/src/stripeWebhook.ts` - Added stripeSubscriptionId to set() call on subscription.created/updated
- `functions/src/index.ts` - Export deleteAccount
- `functions/__mocks__/stripe.ts` - Added subscriptions.cancel mock
- `functions/__mocks__/firebase-admin.ts` - Added auth mock with deleteUser, recursiveDelete on firestoreInstance
- `functions/src/__tests__/stripeWebhook.test.ts` - Fixed mock reference bug: converted to jest.mock() pattern
- `functions/src/__tests__/createCheckoutSession.test.ts` - Fixed mock reference bug: converted to jest.mock() pattern
- `functions/package.json` - Added testPathIgnorePatterns: /lib/ to exclude compiled JS test artifacts
- `SundeeFundeeRN/app/(app)/(tabs)/settings.tsx` - Added Data section (Export Data), Danger Zone (Delete Account / Clear Local Data), delete confirmation modal, export format picker
- `SundeeFundeeRN/app/(app)/goodbye.tsx` - Post-deletion farewell screen
- `SundeeFundeeRN/app/(app)/(tabs)/__tests__/settings.test.tsx` - Added tests for export, delete flow, danger zone

## Decisions Made
- deleteAccount uses `db.recursiveDelete` from firebase-admin — handles all subcollections (workouts, maxes, injuries, painLogs, cycleData, benchmarks, enrollments, readiness) in one call
- RC and Stripe steps wrapped in try/catch with logging — Firestore + Auth deletion always happens even if external APIs fail
- `jest.mock()` factory pattern used in tests instead of direct `../../__mocks__/stripe` imports — ensures the mock instance inside the module under test matches the one in the test assertions
- `testPathIgnorePatterns: ['/lib/']` added to functions Jest config — compiled `.js` test artifacts in `lib/` were being discovered and run alongside TypeScript source tests, causing stale test failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing stripeWebhook test mock reference mismatch**
- **Found during:** Task 1 (verifying all tests pass after changes)
- **Issue:** `src/__tests__/stripeWebhook.test.ts` imported `mockConstructEvent` directly from `../../__mocks__/stripe` — a different module instance than what `moduleNameMapper` resolves inside `stripeWebhook.ts`. All tests using `mockReturnValueOnce` silently failed.
- **Fix:** Converted test to use `jest.mock("stripe")` factory to ensure shared mock reference
- **Files modified:** `functions/src/__tests__/stripeWebhook.test.ts`
- **Verification:** All 9 stripeWebhook tests pass
- **Committed in:** 0b96164 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed pre-existing createCheckoutSession test mock reference mismatch**
- **Found during:** Task 1 (running full test suite)
- **Issue:** Same pattern — `mockSessionCreate` imported directly from mock file, different instance than module under test
- **Fix:** Converted to `jest.mock("stripe")` factory pattern
- **Files modified:** `functions/src/__tests__/createCheckoutSession.test.ts`
- **Verification:** All 4 createCheckoutSession tests pass
- **Committed in:** 0b96164 (Task 1 commit)

**3. [Rule 1 - Bug] Fixed compiled lib/ test artifacts running alongside TypeScript tests**
- **Found during:** Task 1 (after tsc rebuild, lib/ tests appeared in Jest results)
- **Issue:** `lib/src/__tests__/stripeWebhook.test.js` compiled from old test source, expected old `set()` format without `stripeSubscriptionId`
- **Fix:** Added `testPathIgnorePatterns: ["/lib/"]` to Jest config in functions/package.json
- **Files modified:** `functions/package.json`
- **Verification:** Only 4 test suites run (no lib/ tests), all pass
- **Committed in:** 0b96164 (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 - pre-existing bugs)
**Impact on plan:** Pre-existing test failures resolved. No scope creep.

## Issues Encountered
- Mock module isolation in Jest: direct `__mocks__/` imports and `moduleNameMapper` imports are different module instances — `jest.mock()` factory is required to share the same mock reference between test file and production code. This affected stripeWebhook and createCheckoutSession tests.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Account deletion flow is end-to-end: Settings -> Cloud Function -> Firestore wipe -> Auth delete -> Goodbye screen
- stripeSubscriptionId now persisted for all new subscriptions; existing subscriptions without it will gracefully skip Stripe cancel
- All Cloud Functions exported and ready for Firebase deploy
- App Store and Play Store account deletion requirement (PLAT-07) satisfied

---
*Phase: 07-polish-and-pre-launch*
*Completed: 2026-03-15*
