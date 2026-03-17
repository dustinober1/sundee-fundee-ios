---
phase: 18-foundation-config-build-infrastructure
plan: 01
subsystem: infra
tags: [react-native-firebase, crashlytics, analytics, messaging, eas, app-check, privacy-manifest, ios-entitlements]

# Dependency graph
requires:
  - phase: 17.1-repo-restructure
    provides: Repo root restructured to RN app, configs at root, tests scoped

provides:
  - "@react-native-firebase/messaging, /crashlytics, /analytics installed at ^23.8.8"
  - "app.json with RNFB plugins, 7-entry forceStaticLinking, iOS privacyManifests (5 types), entitlements, background modes"
  - "eas.json with submit.production profile (iOS ascAppId, Android internal track) and corrected env var"
  - "firebase.json react-native section with crashlytics/analytics/messaging config"
  - "src/firebase/messaging.ts, crashlytics.ts, analytics.ts — init modules following appCheck.ts pattern"
  - "src/firebase/init.ts — centralized initFirebase() orchestrator calling all 4 Firebase modules in order"
  - "app/_layout.tsx wired to initFirebase() instead of initAppCheck() directly"
  - "__tests__/config/app-json.test.ts and eas-json.test.ts — 17 config validation tests"

affects:
  - 18-02-eas-dev-build
  - 19-firebase-crashlytics-analytics
  - 20-notifications
  - 22-firestore-security-rules
  - 23-app-store-submission

# Tech tracking
tech-stack:
  added:
    - "@react-native-firebase/messaging ^23.8.8"
    - "@react-native-firebase/crashlytics ^23.8.8"
    - "@react-native-firebase/analytics ^23.8.8"
  patterns:
    - "Firebase init module pattern: Platform.OS web guard, initialized flag, require() lazy import, try/catch non-fatal, console.log on success"
    - "Centralized initFirebase() orchestrator that sequences all Firebase modules — App Check first"
    - "Config validation tests reading JSON directly via require — lightweight, no mocking needed"

key-files:
  created:
    - src/firebase/messaging.ts
    - src/firebase/crashlytics.ts
    - src/firebase/analytics.ts
    - src/firebase/init.ts
    - __tests__/config/app-json.test.ts
    - __tests__/config/eas-json.test.ts
  modified:
    - app.json
    - eas.json
    - firebase.json
    - app/_layout.tsx
    - package.json
    - package-lock.json

key-decisions:
  - "analytics has no config plugin — only forceStaticLinking needed, not added to plugins array"
  - "initFirebase() order: AppCheck first (secures all calls), then Crashlytics, Analytics, Messaging"
  - "EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN replaces FIREBASE_APP_CHECK_DEBUG_TOKEN — only EXPO_PUBLIC_ vars accessible in JS runtime"
  - "No serviceAccountKeyPath in eas.json submit.production.android — first Play Store submission is manual AAB upload per user decision"
  - "Phase 20 owns push permission request — initMessaging() only initializes the module, no token/permission requests here"

patterns-established:
  - "Firebase init module pattern: web guard + initialized flag + lazy require + try/catch + console.log — see appCheck.ts, messaging.ts, crashlytics.ts, analytics.ts"
  - "Config validation tests via Jest + require(json) — validates app.json and eas.json shape without build step"

requirements-completed: [SEC-04, STORE-01]

# Metrics
duration: 4min
completed: 2026-03-17
---

# Phase 18 Plan 01: Foundation Config and Firebase Modules Summary

**RNFB messaging/crashlytics/analytics installed, app.json fully configured with privacy manifests and entitlements, centralized initFirebase() orchestrator wiring all four Firebase modules at app startup**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-17T13:02:34Z
- **Completed:** 2026-03-17T13:06:41Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Installed three new RNFB packages (messaging, crashlytics, analytics) matching existing ^23.8.8 versions
- Updated all config files: app.json with 5-type privacy manifest, aps-environment entitlement, 7-entry forceStaticLinking; eas.json with submit profiles and corrected env var name; firebase.json with react-native section
- Created four Firebase init modules (messaging.ts, crashlytics.ts, analytics.ts, init.ts) all following the established appCheck.ts pattern
- Wired app/_layout.tsx to call initFirebase() replacing direct initAppCheck() call, enabling all Firebase modules at startup
- Added 17 config validation tests across two new test files (app-json.test.ts, eas-json.test.ts)

## Task Commits

Each task was committed atomically:

1. **Task 1: Install RNFB modules and update all config files** - `f9f46cd` (feat)
2. **Task 2: Create Firebase init modules, wire entry point, add config tests** - `66292cb` (feat)

**Plan metadata:** (final docs commit below)

## Files Created/Modified
- `app.json` - Added RNFB plugins, 7-entry forceStaticLinking, privacyManifests (5 types), entitlements, background modes
- `eas.json` - Fixed env var name, added submit.production profile
- `firebase.json` - Added react-native config section
- `package.json` / `package-lock.json` - Added messaging, crashlytics, analytics at ^23.8.8
- `src/firebase/messaging.ts` - async initMessaging() — initializes FCM, skips permission/token (Phase 20 scope)
- `src/firebase/crashlytics.ts` - sync initCrashlytics() — enables crash collection
- `src/firebase/analytics.ts` - sync initAnalytics() — enables analytics collection
- `src/firebase/init.ts` - async initFirebase() — orchestrates AppCheck → Crashlytics → Analytics → Messaging
- `app/_layout.tsx` - Replaced initAppCheck() with initFirebase()
- `__tests__/config/app-json.test.ts` - 12 tests: plugins, static linking, privacy manifest, entitlements
- `__tests__/config/eas-json.test.ts` - 5 tests: submit profiles, env var name

## Decisions Made
- analytics has no config plugin — only forceStaticLinking entry added, NOT added to plugins array (per plan research/pitfall 4)
- EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN replaces old FIREBASE_APP_CHECK_DEBUG_TOKEN in eas.json — the code already read from EXPO_PUBLIC_ prefix but eas.json had wrong name
- No serviceAccountKeyPath for Android submit — first Play Store submission must be manual AAB upload
- initFirebase() order: App Check first (secures all Firebase calls), then Crashlytics (sync), Analytics (sync), Messaging (async)

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- 2 pre-existing test failures (PaywallModal.test.tsx and useEntitlements.test.ts) were present before execution. Verified via git stash before/after comparison. Not caused by this plan.

## User Setup Required
**Manual step required before eas.json submit section is usable:** Replace `REPLACE_WITH_APP_STORE_CONNECT_APP_ID` in `eas.json` with the real App Store Connect app ID when ready to submit.

## Next Phase Readiness
- Config is ready for an EAS development build (Phase 18-02)
- All native modules registered in app.json for inclusion in next native build
- initFirebase() will emit `[Crashlytics] Initialized`, `[Analytics] Initialized`, `[Messaging] Initialized` logs after build — these are the 18-02 checkpoint verification signals
- Pre-existing test failures in PaywallModal and useEntitlements are out of scope for this plan

---
*Phase: 18-foundation-config-build-infrastructure*
*Completed: 2026-03-17*
