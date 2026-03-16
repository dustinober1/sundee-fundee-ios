---
phase: 11-wire-guest-upgrade-entry-point
plan: 01
subsystem: auth
tags: [firebase, react-native, anonymous-auth, credential-linking, jest, tdd]

# Dependency graph
requires:
  - phase: 09-fix-guest-migration-ai-profile
    provides: useGuestSignIn.upgrade() — linkWithCredential + Firestore migration pipeline

provides:
  - isAnonymous guard in sign-in.tsx for Apple, Google, and email sign-up handlers
  - getCredential() on useAppleSignIn — pure credential factory without signing in
  - getCredential() on useGoogleSignIn — pure credential factory without signing in
  - EmailAuthProvider exported from auth.ts (native), auth.web.ts (web), and mock
  - 8 tests covering all guest upgrade and regression branches

affects:
  - phase 12 (if any further auth flow work)
  - any caller of useAppleSignIn or useGoogleSignIn (new getCredential method available)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - getCredential() split from signIn() — credential factory pattern allows callers to route the credential (upgrade vs. sign-in) without duplicating provider logic
    - isAnonymous guard before credential consumption — read getCurrentUser() after getCredential() to catch race-free anonymous state
    - jest.mock() factories use inline jest.fn() with module imported after — avoids TDZ failure from Babel hoisting when factory references const variables

key-files:
  created:
    - SundeeFundeeRN/app/(app)/__tests__/sign-in.test.tsx
  modified:
    - SundeeFundeeRN/app/sign-in.tsx
    - SundeeFundeeRN/src/auth/useAppleSignIn.ts
    - SundeeFundeeRN/src/auth/useGoogleSignIn.ts
    - SundeeFundeeRN/src/firebase/auth.ts
    - SundeeFundeeRN/src/firebase/auth.web.ts
    - SundeeFundeeRN/__mocks__/@react-native-firebase/auth.ts

key-decisions:
  - "getCredential() is a pure credential factory on Apple/Google hooks — no loading/error state; signIn() delegates to it internally, existing callers unchanged"
  - "sign-in.tsx uses firebaseSignIn(credential) directly in the non-guest branch instead of calling hook.signIn() — avoids double Apple/Google prompt risk"
  - "Email sign-in mode always uses normal emailAuth.signIn path — a guest signing in with an existing account has no upgrade path"
  - "jest.mock() factories use inline jest.fn(); module imported after mock, then hook return values reconfigured per-test in beforeEach via (useHook as jest.Mock).mockReturnValue()"

patterns-established:
  - "Credential routing pattern: getCredential() → isAnonymous check → guest.upgrade(credential) OR firebaseSignIn(credential)"
  - "Platform.OS test override: Object.defineProperty(Platform, 'OS', { value: 'android', configurable: true }) in beforeEach to test Google button branch"

requirements-completed: [AUTH-07]

# Metrics
duration: 6min
completed: 2026-03-15
---

# Phase 11 Plan 01: Wire Guest Upgrade Entry Point Summary

**Guest-to-permanent account upgrade wired into all three sign-in.tsx auth handlers via isAnonymous check + guest.upgrade(credential), closing AUTH-07 gap — anonymous users now retain all workout history and data on sign-up**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-15T23:00:42Z
- **Completed:** 2026-03-15T23:06:22Z
- **Tasks:** 2 (+ 1 TDD RED commit)
- **Files modified:** 7

## Accomplishments

- EmailAuthProvider exported from native auth.ts, web auth.web.ts, and the Jest mock — enabling email credential creation for guest upgrades
- useAppleSignIn and useGoogleSignIn refactored to expose getCredential() as pure credential factories; signIn() delegates to getCredential() internally so all existing callers are unaffected
- sign-in.tsx now checks getCurrentUser().isAnonymous before routing credential — guest users hit guest.upgrade(credential), non-guest users hit firebaseSignIn(credential) directly
- Email sign-up mode creates EmailAuthProvider.credential and routes through guest.upgrade(); email sign-in mode always uses normal path
- 8 TDD tests cover all upgrade and regression branches; full 1283-test suite remains green

## Task Commits

Each task was committed atomically:

1. **Task 1: Export EmailAuthProvider and refactor Apple/Google hooks to expose getCredential** - `f9c3caa` (feat)
2. **TDD RED: Failing tests for isAnonymous guard** - `0572f8c` (test)
3. **Task 2: Wire isAnonymous guard into sign-in.tsx handlers** - `977cc32` (feat)

## Files Created/Modified

- `SundeeFundeeRN/app/sign-in.tsx` - Added isAnonymous guards in handleAppleSignIn, handleGoogleSignIn, handleEmailAuth
- `SundeeFundeeRN/src/auth/useAppleSignIn.ts` - Extracted getCredential() from signIn(); added to AppleSignInState interface
- `SundeeFundeeRN/src/auth/useGoogleSignIn.ts` - Extracted getCredential() from signIn(); added to GoogleSignInState interface
- `SundeeFundeeRN/src/firebase/auth.ts` - Added EmailAuthProvider export (native)
- `SundeeFundeeRN/src/firebase/auth.web.ts` - Added EmailAuthProvider export (web)
- `SundeeFundeeRN/__mocks__/@react-native-firebase/auth.ts` - Added EmailAuthProvider mock; added to Object.assign and named exports
- `SundeeFundeeRN/app/(app)/__tests__/sign-in.test.tsx` - Created: 8 tests covering guest upgrade and regression branches

## Decisions Made

- getCredential() is a pure credential factory — no loading/error state management; sign-in.tsx manages state flow by calling the hooks
- Non-guest Apple/Google sign-in calls firebaseSignIn(credential) directly rather than hook.signIn() — avoids the Apple dialog being shown twice (getCredential already dismissed it)
- Email sign-in mode (returning users) always uses normal emailAuth.signIn — no upgrade attempt, correct because a returning user with an existing account cannot link
- jest.mock() factories used inline jest.fn() with module imported after — STATE.md Babel hoisting safety pattern applied

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Test file initially used const variables in jest.mock() factories which triggered Babel TDZ failures — corrected by using inline jest.fn() in factories and reconfiguring via (useHook as jest.Mock).mockReturnValue() in beforeEach (following the established pattern from STATE.md Phase 06 and Phase 09 decisions)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AUTH-07 gap closed: guest upgrade now wired end-to-end (useGuestSignIn.upgrade was already implemented in Phase 09, sign-in.tsx now calls it)
- All auth flows tested and green
- Ready for Phase 11 Plan 02 (if additional gap closure work) or Phase 12

---
*Phase: 11-wire-guest-upgrade-entry-point*
*Completed: 2026-03-15*
