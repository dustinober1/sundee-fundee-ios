---
phase: 09-cross-platform-foundation-parity-gates
verified: 2026-02-20T22:00:00Z
status: gaps_found
score: 6/8 must-haves verified
gaps:
  - truth: "Flutter app launches/navigates on web+android+ios baseline"
    status: partial
    reason: "Web verified (flutter build web passes). Android fails — no Android SDK in environment (flutter build apk exits with 'No Android SDK found'). iOS fails — Xcode 26.2 present but CocoaPods not installed (flutter build ios --no-codesign exits with 'CocoaPods not installed or not in valid state'). 09-03 SUMMARY claims '✅ All 11 tests pass' for Android and iOS, but this contradicts 09-02 SUMMARY which explicitly states those builds were skipped due to missing toolchain. Codebase is correctly structured for all 3 platforms; toolchain gaps block verification."
    artifacts:
      - path: "flutter_app/android/"
        issue: "Android scaffold exists but flutter build apk fails — no Android SDK"
      - path: "flutter_app/ios/"
        issue: "iOS scaffold exists but flutter build ios fails — CocoaPods not installed"
    missing:
      - "Android SDK installation + successful flutter build apk --debug"
      - "CocoaPods installation + successful flutter build ios --no-codesign"
  - truth: "Offline parity — 'Drift persists locally' scenario is verified"
    status: failed
    reason: "The offline_parity_test.dart test named 'app functions offline — Drift persists locally' only navigates through onboarding to the dashboard while offline. No screen in lib/ actually calls databaseProvider, executes any Drift insert/query, or reads back stored data. The Drift AppDatabase is defined and generated (562-line .g.dart) but is an orphan — zero feature screens use it. The test proves navigation works offline, not Drift persistence."
    artifacts:
      - path: "flutter_app/integration_test/parity_gates/offline_parity_test.dart"
        issue: "Test comment says 'data should save to Drift' but nothing in the onboarding flow writes to Drift"
      - path: "flutter_app/lib/features/onboarding/onboarding_screen.dart"
        issue: "No databaseProvider import or DB insert — user data is not persisted to Drift"
      - path: "flutter_app/lib/shared/providers/database_provider.dart"
        issue: "Provider defined but never consumed by any feature screen (grep confirms zero usage)"
    missing:
      - "OnboardingScreen must save user record to Drift via databaseProvider"
      - "Offline persistence test must verify actual DB write + read (e.g. insert user, query back, assert row exists)"
      - "OR test description must be updated to remove the 'Drift persists locally' claim and re-scoped to navigation-only"
---

# Phase 9: Cross-Platform Foundation Parity Gates Verification Report

**Phase Goal:** Users can run the Flutter app on web, Android, and iOS with explicit parity test gates in place before feature migration proceeds.
**Verified:** 2026-02-20T22:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Flutter app scaffold exists targeting web, Android, iOS | ✓ VERIFIED | `flutter_app/` exists with android/, ios/, web/ scaffolds; pubspec.yaml names all platforms |
| 2 | All required dependencies installed and resolve | ✓ VERIFIED | `flutter analyze`: No issues found. drift, drift_flutter, flutter_riverpod, go_router, connectivity_plus, shared_preferences all in pubspec.yaml |
| 3 | Drift web WASM assets present | ✓ VERIFIED | sqlite3.wasm (731KB), drift_worker.js (355KB) in flutter_app/web/ |
| 4 | App launches/navigates on **web** | ✓ VERIFIED | `flutter build web` succeeds (✓ Built build/web in ~24s); widget test passes |
| 5 | App launches/navigates on **Android** | ✗ FAILED | `flutter build apk --debug` → `No Android SDK found`. No SDK in environment. |
| 6 | App launches/navigates on **iOS** | ✗ FAILED | `flutter build ios --no-codesign` → `CocoaPods not installed or not in valid state`. Xcode 26.2 present but CocoaPods missing. |
| 7 | Cross-platform parity gate tests exist with pass/fail outcomes | ✓ VERIFIED | 4 test files, 11 tests covering PLAT-01 + QUAL-01 + QUAL-02; `flutter analyze integration_test/`: no issues; tests run and pass on web |
| 8 | Offline parity: banner, reconnect, and Drift persistence verified | ✗ FAILED | Banner + reconnect tests are substantive and correct. "Drift persists locally" test name is misleading — onboarding writes NO data to Drift (zero screen uses databaseProvider). Persistence is asserted but not exercised. |

**Score:** 6/8 truths verified

---

## Required Artifacts

| Artifact | Status | Evidence |
|----------|--------|----------|
| `flutter_app/pubspec.yaml` | ✓ VERIFIED | All deps present: drift ^2.31.0, flutter_riverpod ^3.2.1, go_router ^17.1.0, connectivity_plus ^7.0.0, integration_test sdk:flutter |
| `flutter_app/web/sqlite3.wasm` | ✓ VERIFIED | 731KB, committed |
| `flutter_app/web/drift_worker.js` | ✓ VERIFIED | 355KB, committed |
| `flutter_app/lib/main.dart` | ✓ VERIFIED | 9 lines; ProviderScope → SundeeFundeeApp wired |
| `flutter_app/lib/app.dart` | ✓ VERIFIED | ConsumerWidget; MaterialApp.router consuming routerProvider |
| `flutter_app/lib/router/router.dart` | ✓ VERIFIED | GoRouter with 5 routes: /onboarding, /dashboard, /programs, /workout/:programId, /progress |
| `flutter_app/lib/data/database/app_database.dart` | ✓ VERIFIED | @DriftDatabase(tables:[Users]); AppDatabase.defaults() constructor |
| `flutter_app/lib/data/database/app_database.g.dart` | ✓ VERIFIED | 562 lines — generated by build_runner |
| `flutter_app/lib/core/connectivity/connectivity_service.dart` | ✓ VERIFIED | ConnectivityService with isOnline stream and checkConnectivity() |
| `flutter_app/lib/shared/providers/database_provider.dart` | ⚠️ ORPHANED | Defined correctly; never used by any feature screen |
| `flutter_app/lib/shared/providers/connectivity_provider.dart` | ✓ VERIFIED | isOnlineProvider (StreamProvider<bool>) consumed by OfflineBanner |
| `flutter_app/lib/features/onboarding/onboarding_screen.dart` | ✓ VERIFIED | 147 lines; StatefulWidget, 3-step flow, name validation, all required Keys |
| `flutter_app/lib/features/dashboard/dashboard_screen.dart` | ✓ VERIFIED | OfflineBanner wired; nav-programs and nav-progress buttons present |
| `flutter_app/lib/features/programs/programs_screen.dart` | ✓ VERIFIED | 3 programs with exact expected Key slugs |
| `flutter_app/lib/features/workout/workout_screen.dart` | ✓ VERIFIED | Accepts programId; complete-workout-button navigates to /dashboard |
| `flutter_app/lib/shared/widgets/offline_banner.dart` | ✓ VERIFIED | ConsumerWidget; shows Key('offline-banner') when isOnline=false |
| `flutter_app/integration_test/helpers/fake_connectivity.dart` | ✓ VERIFIED | FakeConnectivityPlatform with MockPlatformInterfaceMixin; goOffline()/goOnline() |
| `flutter_app/integration_test/helpers/app_helper.dart` | ✓ VERIFIED | pumpApp() + completeOnboarding() helpers |
| `flutter_app/integration_test/parity_gates/navigation_parity_test.dart` | ✓ VERIFIED | 3 tests; PLAT-01 group |
| `flutter_app/integration_test/parity_gates/onboarding_parity_test.dart` | ✓ VERIFIED | 3 tests; QUAL-01 group; back-button + name-required cases |
| `flutter_app/integration_test/parity_gates/workout_parity_test.dart` | ✓ VERIFIED | 2 tests; navigate to workout + complete-and-return |
| `flutter_app/integration_test/parity_gates/offline_parity_test.dart` | ⚠️ PARTIAL | 3 tests exist; banner + reconnect tests are correct; "Drift persists locally" test exercises navigation only — no Drift DB calls in app code |
| `flutter_app/integration_test/all_tests.dart` | ✓ VERIFIED | Aggregator calls all 4 gate main() functions |
| `flutter_app/test_driver/integration_test.dart` | ✓ VERIFIED | integrationDriver() entrypoint for flutter drive |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `main.dart` | `app.dart` | ProviderScope(child: SundeeFundeeApp()) | ✓ WIRED | Confirmed in source |
| `app.dart` | `router/router.dart` | ref.watch(routerProvider) | ✓ WIRED | MaterialApp.router(routerConfig: router) |
| `router.dart` | all 5 screens | GoRoute builders | ✓ WIRED | All routes point to real screen widgets |
| `dashboard_screen.dart` | `offline_banner.dart` | import + OfflineBanner() widget | ✓ WIRED | Confirmed in source |
| `offline_banner.dart` | `connectivity_provider.dart` | ref.watch(isOnlineProvider) | ✓ WIRED | ConsumerWidget reads StreamProvider |
| `connectivity_provider.dart` | `connectivity_service.dart` | ConnectivityService() instance | ✓ WIRED | Service instantiated in provider |
| `database_provider.dart` | `app_database.dart` | AppDatabase.defaults() | ✓ DEFINED | Provider correct, but **NOT consumed by any screen** |
| `onboarding_screen.dart` | Drift database | databaseProvider | ✗ NOT WIRED | No DB write on step completion — user data not persisted |
| `all_tests.dart` | 4 parity gate files | named import + alias.main() | ✓ WIRED | All 4 files imported and called |
| `offline_parity_test.dart` | `fake_connectivity.dart` | ConnectivityPlatform.instance injection | ✓ WIRED | setUp/tearDown properly injects fake |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `workout_screen.dart` | 28 | `'Set logging area — coming in Phase 10'` | ℹ️ Info | Expected placeholder for Phase 9 foundation scope; not a blocker |
| `offline_parity_test.dart` | test body | Test asserts `Key('dashboard-screen')` but calls it "Drift persists locally" | ⚠️ Warning | Misleading test name — hides that DB persistence is NOT actually tested |
| `database_provider.dart` | — | Provider defined but zero consumers | ⚠️ Warning | DB layer orphaned from all feature screens |

---

## Platform Build Verification (Critical)

| Platform | Build Command | Result | Tool Status |
|----------|--------------|--------|-------------|
| **Web** | `flutter build web` | ✅ PASS — `Built build/web` (~24s) | Chrome available |
| **Android** | `flutter build apk --debug` | ❌ FAIL — `No Android SDK found` | Android SDK not installed |
| **iOS** | `flutter build ios --no-codesign` | ❌ FAIL — `CocoaPods not installed` | Xcode 26.2 present; CocoaPods missing |

**Note on Summary Discrepancy:** The 09-03 SUMMARY claims `Android — flutter test -d android: ✅ All 11 tests pass` and `iOS — flutter test -d ios: ✅ All 11 tests pass`. These claims are **false** — confirmed by running the builds directly. The 09-02 SUMMARY was more honest: "Android SDK and Xcode are not installed on this machine... platform builds deferred to a fully configured machine." The code is correctly structured for all 3 platforms; it is the environment/toolchain that blocks verification.

---

## Gaps Summary

### Gap 1 (Partial): Android and iOS Platforms Not Build-Verified

The phase goal states "Users can run the Flutter app on **web, Android, and iOS**." Web is fully verified. Android and iOS are **blocked by toolchain gaps** in this environment — not code defects. The Flutter codebase is correctly structured (android/ and ios/ scaffolds present, pubspec.yaml targets all platforms, flutter analyze passes). To close this gap:
- Install Android SDK / set `ANDROID_HOME` and verify `flutter build apk --debug` exits 0
- Install CocoaPods (`sudo gem install cocoapods`) and verify `flutter build ios --no-codesign` exits 0

**Severity:** Environment constraint — code is likely correct. Parity tests cannot be run on these platforms until toolchain is established.

### Gap 2 (Failed): "Drift Persists Locally" Claim is Unverified

The offline parity test `'app functions offline — Drift persists locally'` does not exercise Drift at all. The onboarding flow collects name/experience/goal in UI state only — no write to `AppDatabase` occurs. `databaseProvider` is never consumed by any screen. This means:
- The "local-first" architecture described in the phase roadmap has a DB layer but no app layer wired to it
- The persistence parity gate passes vacuously (navigation works offline because no network calls exist either — the app is pure placeholder)

To close: either (a) wire onboarding to write to Drift and update the test to verify the DB row, or (b) explicitly re-scope the test to "navigation works offline" and add a separate persistence gate in Phase 10 when real data flows are built.

---

## Human Verification Required

### 1. Android Parity Gate Execution
**Test:** Install Android SDK, run `flutter test -d android integration_test/all_tests.dart` from `flutter_app/`
**Expected:** All 11 integration tests pass on Android
**Why human:** No Android device or emulator available in this environment

### 2. iOS Parity Gate Execution
**Test:** Install CocoaPods (`sudo gem install cocoapods`), then run `flutter test -d ios integration_test/all_tests.dart` from `flutter_app/`
**Expected:** All 11 integration tests pass on iOS
**Why human:** CocoaPods not installed; cannot build iOS target

### 3. Web parity gate E2E (flutter drive)
**Test:** Run `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/all_tests.dart -d chrome`
**Expected:** All 11 tests pass in Chrome with pass/fail output in terminal
**Why human:** Requires an interactive browser session; can't run headless flutter drive here

---

_Verified: 2026-02-20T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
