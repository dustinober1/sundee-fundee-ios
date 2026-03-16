---
phase: 01-foundation-and-infrastructure
plan: 01
subsystem: infra
tags: [expo, react-native, firebase, firestore, revenuecat, eas, jest, typescript, auth]

# Dependency graph
requires: []
provides:
  - Expo TypeScript project scaffolded at SundeeFundeeRN/ with all native dependencies
  - Platform-aware Firebase init (RNFirebase native on iOS/Android, JS SDK on web)
  - Firestore security rules with user-owned data pattern (default deny, /users/{uid} owner-only)
  - Firestore rules test suite covering all access patterns (requires Firebase Emulator)
  - RevenueCat SDK initialization in root layout (iOS/Android only, web deferred to Phase 6)
  - Art Deco design tokens: CREAM #F4F0DF, NAVY #0D1A40, ORANGE #F2731A
  - EAS build profiles: development (developmentClient), preview, production
  - Jest test infrastructure with jest-expo preset and all required native module mocks
affects:
  - 01-02 (auth layer builds on this Firebase init + security rules foundation)
  - 01-03 (entitlements hook and RevenueCat config used in paywall gating)
  - 02 (domain layer tests use same jest.config.js and mock infrastructure)
  - all subsequent phases (all TypeScript compiled without errors as baseline)

# Tech tracking
tech-stack:
  added:
    - expo ~55.0.6 (managed workflow, EAS orchestration)
    - expo-router ~55.0.5 (file-based routing, Stack.Protected auth gating)
    - "@react-native-firebase/app ^23.8.8 (core native Firebase SDK)"
    - "@react-native-firebase/auth ^23.8.8 (native auth, mobile only)"
    - "@react-native-firebase/firestore ^23.8.8 (native Firestore with offline persistence)"
    - expo-build-properties ~55.0.9 (useFrameworks static + forceStaticLinking for RNFirebase)
    - expo-apple-authentication ~55.0.8 (iOS Sign in with Apple)
    - "@react-native-google-signin/google-signin ^16.1.2 (Android/Web Google auth)"
    - react-native-purchases ^9.12.0 (RevenueCat SDK)
    - firebase ^12.10.0 (JS SDK for web platform auth)
    - jest-expo 55.0.9 + @testing-library/react-native (test framework)
    - "@firebase/rules-unit-testing ^5.0.0 (Firestore rules tests, requires emulator)"
    - babel-preset-expo (required by jest-expo runner)
  patterns:
    - Platform-aware Firebase: auth.native.ts (RNFirebase) vs auth.web.ts (JS SDK) — Metro resolves by extension
    - Dynamic require for platform-branching in firestore.ts to prevent cross-platform bundle issues
    - RevenueCat configured in root _layout.tsx useEffect, skipped on web
    - Firestore security rules: default deny all, /users/{uid} owner-only, read-only collections
    - Jest WinterCG stub: __mocks__/setup.js pre-stubs Expo SDK 55 globals to prevent setup-phase import errors

key-files:
  created:
    - SundeeFundeeRN/app.json
    - SundeeFundeeRN/eas.json
    - SundeeFundeeRN/tsconfig.json
    - SundeeFundeeRN/babel.config.js
    - SundeeFundeeRN/jest.config.js
    - SundeeFundeeRN/firestore.rules
    - SundeeFundeeRN/firestore.rules.test.ts
    - SundeeFundeeRN/app/_layout.tsx
    - SundeeFundeeRN/src/firebase/app.ts
    - SundeeFundeeRN/src/firebase/auth.native.ts
    - SundeeFundeeRN/src/firebase/auth.web.ts
    - SundeeFundeeRN/src/firebase/firestore.ts
    - SundeeFundeeRN/src/entitlements/useEntitlements.ts
    - SundeeFundeeRN/src/theme/colors.ts
    - SundeeFundeeRN/src/theme/typography.ts
    - SundeeFundeeRN/__mocks__/@react-native-firebase/app.ts
    - SundeeFundeeRN/__mocks__/@react-native-firebase/auth.ts
    - SundeeFundeeRN/__mocks__/@react-native-firebase/firestore.ts
    - SundeeFundeeRN/__mocks__/expo-apple-authentication.ts
    - SundeeFundeeRN/__mocks__/@react-native-google-signin/google-signin.ts
    - SundeeFundeeRN/__mocks__/react-native-purchases.ts
    - SundeeFundeeRN/__mocks__/setup.js
    - SundeeFundeeRN/src/__tests__/setup.test.ts
  modified:
    - SundeeFundeeRN/package.json (scripts, all dependencies added)
    - SundeeFundeeRN/index.ts (changed to expo-router/entry)

key-decisions:
  - "Used platform-specific file extensions (auth.native.ts / auth.web.ts) not Platform.OS branching for Firebase auth — Metro resolver handles it automatically, prevents cross-platform bundle errors"
  - "Installed react-native-purchases with --legacy-peer-deps due to peer dependency conflict with React 19 (Expo SDK 55 uses RN 0.83, RC has not yet declared React 19 peer support)"
  - "Added __mocks__/setup.js to pre-stub Expo SDK 55 WinterCG globals — SDK 55 lazy-installs structuredClone and __ExpoImportMetaRegistry via property getters that fire during Jest setupFiles phase, causing import-outside-scope errors; stubbing them upfront prevents this"
  - "Used dynamic require() in firestore.ts for platform branching instead of static imports — prevents @react-native-firebase/firestore from being bundled on web where it causes build failure"
  - "EAS development profile includes FIREBASE_APP_CHECK_DEBUG_TOKEN placeholder — App Check enforcement can be enabled at production deploy without code changes (project-level gate from STATE.md)"

patterns-established:
  - "Platform-aware modules: use .native.ts / .web.ts file extensions. Never use Platform.OS branching for module-level imports."
  - "Jest setup: __mocks__/setup.js runs before jest-expo setup to stub globals that cause Expo SDK 55 WinterCG init errors"
  - "Native module mocks: all native SDKs have full jest.fn() mock files in __mocks__/ directory at the root"
  - "RevenueCat: initialize in root layout useEffect, skip on web (Platform.OS check), gracefully degrade when API key not set"
  - "Firebase security rules: default deny, then explicit allow — never default allow"

requirements-completed: [PLAT-01, PLAT-02, PLAT-03]

# Metrics
duration: 10min
completed: 2026-03-14
---

# Phase 1 Plan 01: Foundation and Infrastructure Summary

**Expo SDK 55 + React Native Firebase project scaffolded with platform-aware auth, Firestore security rules with test suite, RevenueCat init, EAS profiles, Art Deco design tokens, and Jest infrastructure including Expo SDK 55 WinterCG compatibility fix**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-14T14:25:18Z
- **Completed:** 2026-03-14T14:35:22Z
- **Tasks:** 3 of 3
- **Files modified:** 25

## Accomplishments

- Scaffolded greenfield Expo TypeScript project at `SundeeFundeeRN/` with all dependencies for Firebase, auth providers, RevenueCat, and EAS builds
- Configured Firestore security rules with default-deny pattern and user-owned data enforcement, backed by 18-assertion test suite covering all access patterns
- Established Jest test infrastructure with jest-expo preset, all required native module mocks, and a workaround for Expo SDK 55's WinterCG runtime breaking Jest setup

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Expo project with Firebase, auth providers, RevenueCat, EAS config** - `68e4557` (feat)
2. **Task 2: Write Firestore security rules and rule tests** - `b8c7d60` (feat)
3. **Task 3: Set up Jest test infrastructure with module mocks** - `c9a8891` (feat)

**Plan metadata:** *(see final commit below)*

## Files Created/Modified

- `SundeeFundeeRN/app.json` - Expo config with Firebase plugins, Apple Sign-In, build properties, Google Sign-In, EAS scheme
- `SundeeFundeeRN/eas.json` - EAS build profiles: development (developmentClient), preview, production
- `SundeeFundeeRN/tsconfig.json` - TypeScript with @/* path alias
- `SundeeFundeeRN/babel.config.js` - babel-preset-expo (required by jest-expo runner)
- `SundeeFundeeRN/jest.config.js` - jest-expo preset, transformIgnorePatterns, @/* mapper, rules test exclusion
- `SundeeFundeeRN/firestore.rules` - Firestore security rules with default-deny and user-owned data pattern
- `SundeeFundeeRN/firestore.rules.test.ts` - 18 test assertions for all access patterns (requires Firebase Emulator)
- `SundeeFundeeRN/app/_layout.tsx` - Root layout with RevenueCat init and SessionProvider stub
- `SundeeFundeeRN/src/firebase/app.ts` - Platform detection and Firebase web init utility
- `SundeeFundeeRN/src/firebase/auth.native.ts` - Native Firebase auth (iOS/Android) via RNFirebase
- `SundeeFundeeRN/src/firebase/auth.web.ts` - Web Firebase auth via JS SDK
- `SundeeFundeeRN/src/firebase/firestore.ts` - Platform-aware Firestore instance via dynamic require
- `SundeeFundeeRN/src/entitlements/useEntitlements.ts` - RevenueCat entitlement hook, graceful web no-op
- `SundeeFundeeRN/src/theme/colors.ts` - Art Deco palette (CREAM, NAVY, ORANGE) + semantic aliases
- `SundeeFundeeRN/src/theme/typography.ts` - Font sizes, weights, line heights, preset text styles
- `SundeeFundeeRN/__mocks__/setup.js` - Pre-stubs Expo SDK 55 WinterCG globals for Jest compatibility
- `SundeeFundeeRN/__mocks__/@react-native-firebase/{app,auth,firestore}.ts` - Native Firebase mocks
- `SundeeFundeeRN/__mocks__/expo-apple-authentication.ts` - Apple auth mock
- `SundeeFundeeRN/__mocks__/@react-native-google-signin/google-signin.ts` - Google sign-in mock
- `SundeeFundeeRN/__mocks__/react-native-purchases.ts` - RevenueCat mock
- `SundeeFundeeRN/src/__tests__/setup.test.ts` - 10-assertion smoke test verifying Jest + theme tokens

## Decisions Made

- **Platform-specific file extensions over Platform.OS branching:** Used `.native.ts` / `.web.ts` extensions for Firebase auth module so Metro's resolver handles platform selection automatically. This prevents `@react-native-firebase/auth` from being bundled on web where it causes build failures.

- **react-native-purchases installed with --legacy-peer-deps:** The package has not yet declared React 19 as a supported peer. Expo SDK 55 ships with React 19.2.0. The `--legacy-peer-deps` flag allows installation without breaking the dependency tree.

- **Expo SDK 55 WinterCG Jest fix:** Expo SDK 55 installs globals (structuredClone, __ExpoImportMetaRegistry) via lazy property getters. These getters fire during Jest's `setupFiles` phase when `react-native/Libraries/BatchedBridge/NativeModules` is required by jest-expo. The getters try to `require()` modules with ES module `import` syntax, which fails with "import outside test scope." Solution: `__mocks__/setup.js` pre-defines these globals before jest-expo's setup runs, preventing the lazy getters from ever firing.

- **Dynamic require in firestore.ts:** Static imports of `@react-native-firebase/firestore` cause web bundle failures. Using `require()` inside the platform branch prevents the native module from being bundled on web.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed incorrect firebase/auth import in auth.web.ts**
- **Found during:** Task 1 (TypeScript verification)
- **Issue:** `initializeApp` and `getApps` were imported from `firebase/auth` instead of `firebase/app`
- **Fix:** Moved `initializeApp` and `getApps` imports to `firebase/app`; renamed local `initApp` alias back to `initializeApp`
- **Files modified:** `SundeeFundeeRN/src/firebase/auth.web.ts`
- **Verification:** `npx tsc --noEmit` — zero errors
- **Committed in:** `68e4557` (Task 1 commit)

**2. [Rule 3 - Blocking] react-native-purchases install required --legacy-peer-deps flag**
- **Found during:** Task 1 (dependency installation)
- **Issue:** `npx expo install react-native-purchases` failed with peer dependency conflict
- **Fix:** Used `npm install react-native-purchases --legacy-peer-deps`
- **Files modified:** `SundeeFundeeRN/package.json`
- **Verification:** Package installed; TypeScript and Jest run cleanly
- **Committed in:** `68e4557` (Task 1 commit)

**3. [Rule 3 - Blocking] Jest required babel-preset-expo and jest package**
- **Found during:** Task 3 (Jest verification)
- **Issue:** jest-expo was installed but neither `jest` nor `babel-preset-expo` were present, causing "Cannot find module 'jest/package.json'" and "Cannot find module 'babel-preset-expo'" errors
- **Fix:** `npm install --save-dev jest babel-preset-expo --legacy-peer-deps`; added `babel.config.js`
- **Files modified:** `SundeeFundeeRN/package.json`, `SundeeFundeeRN/babel.config.js`
- **Verification:** `npx jest --passWithNoTests` — 10 tests pass
- **Committed in:** `c9a8891` (Task 3 commit)

**4. [Rule 1 - Bug] Expo SDK 55 WinterCG runtime breaks Jest setupFiles phase**
- **Found during:** Task 3 (Jest verification)
- **Issue:** Jest setup failed with "You are trying to import a file outside of the scope of the test code" — Expo SDK 55's lazy global installation (structuredClone, __ExpoImportMetaRegistry) fires during `setupFiles` and tries to require ES-module-only packages
- **Fix:** Added `__mocks__/setup.js` that runs as a `setupFiles` entry to pre-stub the affected globals before jest-expo's setup.js fires
- **Files modified:** `SundeeFundeeRN/__mocks__/setup.js`, `SundeeFundeeRN/jest.config.js`
- **Verification:** `npx jest --passWithNoTests` — 10 tests pass, no setup errors
- **Committed in:** `c9a8891` (Task 3 commit)

---

**Total deviations:** 4 auto-fixed (1 bug, 3 blocking)
**Impact on plan:** All auto-fixes were required for correct dependency installation and test runner operation. No scope creep.

## Issues Encountered

The Expo SDK 55 WinterCG Jest incompatibility (Deviation 4) is a known-but-undocumented issue at the time of research (2026-03-14). The fix — pre-stubbing globals before jest-expo setup — is specific to SDK 55 and should be removed if SDK 56+ resolves the issue natively.

## User Setup Required

External services require manual configuration before EAS builds can succeed. The following must be completed before Plan 02 (auth layer) can be tested on device:

**Firebase:**
- Create Firebase project at console.firebase.google.com
- Enable Email/Password, Apple (iOS), and Google (Android/Web) sign-in providers
- Download `GoogleService-Info.plist` → place at `SundeeFundeeRN/GoogleService-Info.plist`
- Download `google-services.json` → place at `SundeeFundeeRN/google-services.json`
- Set environment variables: `EXPO_PUBLIC_FIREBASE_WEB_API_KEY`, `EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN`, `EXPO_PUBLIC_FIREBASE_PROJECT_ID`
- Deploy Firestore security rules: `cd SundeeFundeeRN && firebase deploy --only firestore:rules`

**RevenueCat:**
- Create RevenueCat project and link Firebase app user IDs
- Set `EXPO_PUBLIC_RC_APPLE_KEY` and `EXPO_PUBLIC_RC_GOOGLE_KEY`

**Google Sign-In:**
- Set `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` (auto-created by Firebase when enabling Google sign-in)

**EAS:**
- Run `npx eas init` to register the project
- `npx eas build --profile development` for first native build

## Next Phase Readiness

- Project structure, Firebase configuration, security rules, and test infrastructure are complete
- Plan 02 can now implement the full auth layer (AuthContext, sign-in hooks, SessionProvider) using the Firebase init files and module mocks created here
- Firestore security rules must be deployed to Firebase before any Firestore write code executes (project-level gate)
- The `react-native-purchases --legacy-peer-deps` install should be monitored — RC may release React 19 peer support in an upcoming minor version

---
*Phase: 01-foundation-and-infrastructure*
*Completed: 2026-03-14*
