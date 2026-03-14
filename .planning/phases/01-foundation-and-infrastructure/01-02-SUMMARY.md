---
phase: 01-foundation-and-infrastructure
plan: 02
subsystem: auth
tags: [auth, firebase, context, hooks, repository, firestore, asyncstorage, tdd, typescript]

# Dependency graph
requires:
  - 01-01 (Firebase init, platform-aware auth module, jest mocks)
provides:
  - SessionProvider with onAuthStateChanged listener and useSession hook
  - Four auth hooks: useAppleSignIn, useGoogleSignIn, useEmailAuth, useGuestSignIn
  - authErrors.ts: Firebase error code -> user-friendly message mapping
  - UserRepository interface and UserProfile type
  - FirestoreUserRepo: writes /users/{uid} with merge semantics (satisfies AUTH-07)
  - LocalUserRepo: persists guest profile to AsyncStorage
  - Root layout wired with SessionProvider and repository routing on sign-in
affects:
  - 01-03 (auth hooks available for paywall gating, useSession provides auth state)
  - 02 (domain layer tests run against same jest infrastructure)
  - all subsequent phases (every screen can call useSession for auth state)

# Tech tracking
tech-stack:
  added:
    - expo-apple-authentication signInAsync (individual function, not object method)
    - expo-secure-store (SecureStore.setItemAsync for Apple display name persistence)
    - "@react-native-async-storage/async-storage (LocalUserRepo + SessionProvider signOut)"
  patterns:
    - SessionProvider pattern: React context with onAuthStateChanged listener, useCallback signOut
    - Repository factory pattern: FirestoreUserRepo for auth users, LocalUserRepo for guests
    - TDD: RED (write failing tests) -> GREEN (implement) for both tasks with tdd=true
    - Auth error mapping: centralized getAuthErrorMessage() from Firebase codes to user strings
    - Verification gate: signIn signs out unverified users before resolving (per locked decision)
    - Guest upgrade: linkWithCredential preserves UID on account promotion (per locked decision)
    - Apple fullName to SecureStore: stored on sign-in since Apple provides it only once

key-files:
  created:
    - SundeeFundeeRN/src/auth/AuthContext.tsx
    - SundeeFundeeRN/src/auth/useAppleSignIn.ts
    - SundeeFundeeRN/src/auth/useGoogleSignIn.ts
    - SundeeFundeeRN/src/auth/useEmailAuth.ts
    - SundeeFundeeRN/src/auth/useGuestSignIn.ts
    - SundeeFundeeRN/src/auth/authErrors.ts
    - SundeeFundeeRN/src/auth/__tests__/AuthContext.test.tsx
    - SundeeFundeeRN/src/auth/__tests__/useAppleSignIn.test.ts
    - SundeeFundeeRN/src/auth/__tests__/useEmailAuth.test.ts
    - SundeeFundeeRN/src/auth/__tests__/useGoogleSignIn.test.ts
    - SundeeFundeeRN/src/auth/__tests__/useGuestSignIn.test.ts
    - SundeeFundeeRN/src/repositories/UserRepository.ts
    - SundeeFundeeRN/src/repositories/FirestoreUserRepo.ts
    - SundeeFundeeRN/src/repositories/LocalUserRepo.ts
    - SundeeFundeeRN/src/repositories/__tests__/FirestoreUserRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/LocalUserRepo.test.ts
    - SundeeFundeeRN/__mocks__/@react-native-async-storage/async-storage.ts
    - SundeeFundeeRN/__mocks__/expo-secure-store.ts
  modified:
    - SundeeFundeeRN/app/_layout.tsx (replaced stub SessionProvider with real AuthContext + UserRepository wiring)
    - SundeeFundeeRN/__mocks__/expo-apple-authentication.ts (fixed to export standalone functions not object)

key-decisions:
  - "expo-apple-authentication exports individual functions (signInAsync, isAvailableAsync) not an AppleAuthentication object — import must use named function imports"
  - "Apple nonce not available from expo-apple-authentication credential type — pass undefined as second arg to AppleAuthProvider.credential"
  - "useEmailAuth signIn marks verification error with _verificationError flag to avoid double-setting error in catch block"
  - "SessionProvider accepts optional onUserSignIn callback rather than inlining repository logic — keeps AuthContext pure and RootLayout responsible for data concerns"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-07]

# Metrics
duration: 7min
completed: 2026-03-14
---

# Phase 1 Plan 02: Foundation and Infrastructure Summary

**Complete auth layer: SessionProvider with onAuthStateChanged, four auth hooks (Apple/Google/Email/Guest), error message mapping, UserRepository interface with Firestore and AsyncStorage implementations — 30 unit tests, TypeScript clean**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-14T14:40:15Z
- **Completed:** 2026-03-14T14:47:15Z
- **Tasks:** 3 of 3
- **Files modified:** 19

## Accomplishments

- Built complete auth layer: SessionProvider with onAuthStateChanged session persistence, signOut clearing Firebase + AsyncStorage, and useSession hook that throws outside provider
- Implemented four auth hooks with consistent `{ isLoading, error }` shape: useAppleSignIn (expo-apple-authentication + SecureStore), useGoogleSignIn (Play Services check + idToken), useEmailAuth (verification gate on signIn), useGuestSignIn (anonymous + linkWithCredential upgrade)
- Created UserRepository interface with two implementations: FirestoreUserRepo (merge-writes /users/{uid}, satisfies AUTH-07) and LocalUserRepo (AsyncStorage for guest mode)
- Wired SessionProvider and repository routing into root layout — authenticated users sync to Firestore, guests persist locally

## Task Commits

1. **Task 1: Build AuthContext with SessionProvider and all auth hooks** - `522e7a4` (feat)
2. **Task 2: Create UserRepository interface and Firestore/Local implementations** - `cfaa8b8` (feat)
3. **Task 3: Wire SessionProvider and UserRepository into root layout** - `02a537c` (feat)

**Plan metadata:** *(see final commit below)*

## Files Created/Modified

- `SundeeFundeeRN/src/auth/AuthContext.tsx` - SessionProvider with onAuthStateChanged + useSession hook
- `SundeeFundeeRN/src/auth/useAppleSignIn.ts` - Apple Sign-In via expo-apple-authentication + SecureStore display name
- `SundeeFundeeRN/src/auth/useGoogleSignIn.ts` - Google Sign-In via GoogleSignin + Firebase credential
- `SundeeFundeeRN/src/auth/useEmailAuth.ts` - Email auth with signUp + verification-gated signIn
- `SundeeFundeeRN/src/auth/useGuestSignIn.ts` - Anonymous sign-in + linkWithCredential upgrade
- `SundeeFundeeRN/src/auth/authErrors.ts` - Firebase error code -> user-friendly message mapping (7 codes + default)
- `SundeeFundeeRN/src/auth/__tests__/` - 22 unit tests covering all auth flows (TDD)
- `SundeeFundeeRN/src/repositories/UserRepository.ts` - Interface: UserProfile type + createOrUpdateUser/getUser/deleteUser
- `SundeeFundeeRN/src/repositories/FirestoreUserRepo.ts` - Firestore impl: .collection('users').doc(uid).set(profile, {merge:true})
- `SundeeFundeeRN/src/repositories/LocalUserRepo.ts` - AsyncStorage impl: stores as JSON at 'user_profile' key
- `SundeeFundeeRN/src/repositories/__tests__/` - 8 unit tests for both repo implementations (TDD)
- `SundeeFundeeRN/__mocks__/@react-native-async-storage/async-storage.ts` - AsyncStorage Jest mock
- `SundeeFundeeRN/__mocks__/expo-secure-store.ts` - SecureStore Jest mock
- `SundeeFundeeRN/__mocks__/expo-apple-authentication.ts` - Updated to export standalone functions
- `SundeeFundeeRN/app/_layout.tsx` - SessionProvider wraps app; handleUserSignIn routes to appropriate repo

## Decisions Made

- **SessionProvider accepts onUserSignIn callback:** Rather than importing repository logic into AuthContext (which would couple auth state to data concerns), the callback is passed from RootLayout. This keeps AuthContext responsible only for auth state and signOut.

- **expo-apple-authentication exports standalone functions:** The package exports `signInAsync`, `isAvailableAsync` etc. as individual named exports, not as methods on an `AppleAuthentication` object. This was caught during TypeScript verification and fixed via Rule 1 (bug auto-fix).

- **Apple nonce: pass undefined:** `AppleAuthenticationCredential` type does not include `nonce` (it is in the sign-in options). Pass `undefined` as the second argument to `AppleAuthProvider.credential` — Firebase ignores it safely.

- **useEmailAuth verification error flag:** Used a `_verificationError` flag on the thrown Error object to distinguish the "unverified email" path from other Firebase errors, preventing double-setting of the error state in the catch block.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed expo-apple-authentication import pattern**
- **Found during:** Task 3 (TypeScript verification)
- **Issue:** `useAppleSignIn.ts` imported `{ AppleAuthentication }` as an object from `expo-apple-authentication`, but the package exports standalone named functions (`signInAsync`, `isAvailableAsync`). TypeScript error: `TS2724: 'expo-apple-authentication' has no exported member named 'AppleAuthentication'`
- **Fix:** Changed import to `{ signInAsync as appleSignInAsync, AppleAuthenticationScope }`. Updated mock to export standalone functions. Updated test to import `signInAsync` directly.
- **Files modified:** `src/auth/useAppleSignIn.ts`, `__mocks__/expo-apple-authentication.ts`, `src/auth/__tests__/useAppleSignIn.test.ts`
- **Commit:** `02a537c` (included in Task 3 commit)

**2. [Rule 1 - Bug] Apple nonce not in credential type**
- **Found during:** Task 3 (TypeScript verification, same pass as deviation 1)
- **Issue:** Destructuring `nonce` from `AppleAuthenticationCredential` fails — the type only includes `identityToken`, `authorizationCode`, `user`, `email`, `fullName`, `state`, `realUserStatus`. Error: `TS2339: Property 'nonce' does not exist`
- **Fix:** Removed `nonce` from destructuring; pass `undefined` as second arg to `AppleAuthProvider.credential`. Firebase accepts this gracefully.
- **Files modified:** `src/auth/useAppleSignIn.ts`
- **Commit:** `02a537c`

---

**Total deviations:** 2 auto-fixed (both Rule 1 - bug, caught by TypeScript verification in Task 3)
**Impact on plan:** Caught during Task 3 TypeScript check. Fixed inline. All 30 tests pass, TypeScript compiles cleanly.

## Test Results

- **Auth tests:** 22 passing (AuthContext: 6, useEmailAuth: 5, useAppleSignIn: 4, useGoogleSignIn: 4, useGuestSignIn: 3)
- **Repository tests:** 8 passing (FirestoreUserRepo: 4, LocalUserRepo: 4)
- **Total:** 30 tests, 0 failures
- **TypeScript:** 0 errors

## Next Phase Readiness

- Plan 03 can now build sign-in screens using `useSession`, `useEmailAuth`, `useAppleSignIn`, `useGoogleSignIn`, and `useGuestSignIn`
- The `SessionProvider` is already wrapping the app in `_layout.tsx` — screens access auth state via `useSession()`
- User data persistence to Firestore (AUTH-07) is complete — sign-in automatically writes user document

---
*Phase: 01-foundation-and-infrastructure*
*Completed: 2026-03-14*
