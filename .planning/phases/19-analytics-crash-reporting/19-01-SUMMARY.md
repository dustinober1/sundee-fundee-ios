---
phase: 19-analytics-crash-reporting
plan: 01
subsystem: analytics
tags: [firebase, analytics, crashlytics, react-native-firebase, jest, mocks, hooks]

# Dependency graph
requires:
  - phase: 18-foundation-config-build-infrastructure
    provides: EAS dev build with @react-native-firebase/analytics and @react-native-firebase/crashlytics native modules installed and initialized

provides:
  - Jest mocks for @react-native-firebase/analytics and @react-native-firebase/crashlytics
  - logEvent() and setUserProperties() helpers in src/firebase/analytics.ts
  - recordError() and setCrashlyticsKeys() helpers in src/firebase/crashlytics.ts
  - useScreenTracking() hook for root layout screen tracking
  - Unit tests covering all 4 helpers and the hook (15 test cases)

affects:
  - 19-02 (plan 02 wires useScreenTracking into root layout and calls helpers from app screens)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Platform.OS === 'web' guard at function entry for all RNFB wrappers"
    - "require() inside try/catch for RNFB modules (non-fatal degradation)"
    - "eslint-disable @typescript-eslint/no-require-imports on RNFB require lines"
    - "Jest mocks via __mocks__/@react-native-firebase/*.js with module.exports + module.exports.default"
    - "useEffect keyed on [pathname] for route-change side effects in hooks"

key-files:
  created:
    - __mocks__/@react-native-firebase/analytics.js
    - __mocks__/@react-native-firebase/crashlytics.js
    - src/firebase/__tests__/analytics.test.ts
    - src/firebase/__tests__/crashlytics.test.ts
    - src/hooks/__tests__/useScreenTracking.test.ts
    - src/hooks/useScreenTracking.ts
  modified:
    - src/firebase/analytics.ts
    - src/firebase/crashlytics.ts

key-decisions:
  - "Use require() inside try/catch instead of top-level import for RNFB modules — same pattern as existing initAnalytics/initCrashlytics"
  - "Boolean cycleTrackingEnabled stringified with String() before sending to Firebase (Firebase user property values must be strings)"
  - "setCrashlyticsKeys skips setAttributes call entirely when no keys defined — avoids unnecessary native bridge call"
  - "recordError is synchronous (void, not Promise) matching crashlytics().recordError sync behavior; setCrashlyticsKeys is async"
  - "useScreenTracking uses void operator on async calls inside useEffect to satisfy no-floating-promises lint without blocking"

patterns-established:
  - "RNFB wrapper pattern: Platform.OS==='web' guard → require in try/catch → call → empty catch"
  - "Jest mock pattern: jest.fn() factory returning object of jest.fn() methods, exported as both module.exports and module.exports.default"

requirements-completed: [ANLYT-01, ANLYT-02, ANLYT-03, ANLYT-04, ANLYT-05]

# Metrics
duration: 19min
completed: 2026-03-18
---

# Phase 19 Plan 01: Analytics + Crashlytics Instrumentation Layer Summary

**Platform-safe Firebase Analytics and Crashlytics wrappers with Jest mocks and 15 unit tests — ready for Plan 02 wiring into app screens**

## Performance

- **Duration:** 19 min
- **Started:** 2026-03-18T04:40:57Z
- **Completed:** 2026-03-18T05:00:37Z
- **Tasks:** 2 (Task 1: helpers + mocks, Task 2: TDD unit tests)
- **Files modified:** 8 (2 mocks created, 2 source files extended, 1 hook created, 3 test files created)

## Accomplishments

- Created Jest mocks for both @react-native-firebase/analytics and @react-native-firebase/crashlytics, enabling unit testing without native build
- Extended analytics.ts with logEvent() and setUserProperties() — web-guarded, non-fatal, following existing initAnalytics() pattern
- Extended crashlytics.ts with recordError() and setCrashlyticsKeys() — web-guarded, non-fatal, context logging before error
- Created useScreenTracking hook that fires on pathname change via usePathname() from expo-router
- Wrote 15 unit tests across 3 test files; all pass with no regressions in the existing suite (pre-existing 2-suite failure confirmed as baseline)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Jest mocks and helper functions** - `f212734` (feat)
2. **Task 2: Write unit tests for all helpers and hook** - `8b67f65` (test)

## Files Created/Modified

- `__mocks__/@react-native-firebase/analytics.js` - Jest mock: factory returning logScreenView, logEvent, setUserProperties, setUserProperty, setAnalyticsCollectionEnabled
- `__mocks__/@react-native-firebase/crashlytics.js` - Jest mock: factory returning setCrashlyticsCollectionEnabled, recordError, setAttribute, setAttributes, log, setUserId, crash
- `src/firebase/analytics.ts` - Added logEvent() and setUserProperties() helpers below existing initAnalytics()
- `src/firebase/crashlytics.ts` - Added recordError() and setCrashlyticsKeys() helpers below existing initCrashlytics()
- `src/hooks/useScreenTracking.ts` - New hook; calls logScreenView + setAttribute on each pathname change
- `src/firebase/__tests__/analytics.test.ts` - 5 tests: logEvent(3), setUserProperties(2)
- `src/firebase/__tests__/crashlytics.test.ts` - 6 tests: recordError(3), setCrashlyticsKeys(3)
- `src/hooks/__tests__/useScreenTracking.test.ts` - 4 tests: initial render, setAttribute, pathname change, web no-op

## Decisions Made

- Used `require()` inside `try/catch` (not top-level import) for RNFB modules — consistent with existing initAnalytics/initCrashlytics pattern, non-fatal on missing native module
- Firebase user property values must be strings; `cycleTrackingEnabled` boolean is stringified via `String()` before being passed to `setUserProperties`
- `setCrashlyticsKeys` builds `attrs` object first and skips `setAttributes` entirely if empty — avoids unnecessary native bridge round-trip
- `recordError` is a synchronous void function (not async) to match the sync nature of `crashlytics().recordError`
- Dynamic `import()` in tests fails in Babel/Jest environment; all test helper imports use `require()` instead

## Deviations from Plan

None - plan executed exactly as written. The analytics.test.ts originally used dynamic `import()` which failed with "dynamic import callback invoked without --experimental-vm-modules" — switched to `require()` (same module resolution, test-environment-compatible pattern). This is an implementation detail within Task 2, not a deviation from plan intent.

## Issues Encountered

- Dynamic `import()` inside `it()` callbacks not supported in Jest/Babel setup (jest-expo). Fixed by using `require()` instead, which is already the established pattern for RNFB modules in this codebase.
- Pre-existing test failures (PaywallModal + useEntitlements suites, 8 tests) confirmed as baseline via `git stash` verification — not caused by this plan's changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All instrumentation helpers are tested and ready for Plan 02 to wire into the live app
- `useScreenTracking` hook can be dropped into root layout `_layout.tsx` with a single import + call
- `logEvent` and `recordError` can be imported anywhere in the app for event/error reporting
- Plan 02 should import from `src/firebase/analytics` and `src/firebase/crashlytics` — not directly from RNFB

---
*Phase: 19-analytics-crash-reporting*
*Completed: 2026-03-18*
