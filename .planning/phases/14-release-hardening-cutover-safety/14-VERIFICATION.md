---
phase: 14-release-hardening-cutover-safety
verified: 2026-02-21T00:00:00Z
status: human_needed
score: 4.5/5 must-haves verified
re_verification: false
human_verification:
  - test: "Run GitHub Actions flutter-release.yml on a branch push to verify all three build jobs complete without error"
    expected: "build-web, build-android, and build-ios jobs all succeed; artifacts uploaded (web-release/, app-release.aab, ios IPA)"
    why_human: "Workflow has never been triggered against real CI environment; cannot verify flutter pub get / pod install / build commands succeed end-to-end from grep alone"
  - test: "Run `flutterfire configure` inside flutter_app/, commit the generated lib/firebase_options.dart, then do a local `flutter run` and confirm Crashlytics initialises without exception"
    expected: "Firebase.initializeApp() succeeds, FlutterError.onError is wired to recordFlutterFatalError, a test crash event appears in Firebase Console"
    why_human: "firebase_options.dart does not exist in the repo yet. The try/catch in main.dart silently skips Crashlytics in its absence (by design), meaning telemetry is NOT active in production builds until this step is completed"
  - test: "Download the ios-release IPA artifact from a CI run, open it in Xcode Organizer or Transporter and attempt an App Store Connect upload"
    expected: "Xcode can sign the unsigned archive and upload to App Store Connect successfully"
    why_human: "Pipeline deliberately produces --no-codesign IPA; a human with an Apple Developer account must perform the manual code-signing step before App Store submission is possible"
  - test: "Deploy flutter build web output to Firebase Hosting and navigate to /workout (or any deep route), then hit browser Refresh"
    expected: "Page loads correctly — no 404. Firebase serves /index.html and Flutter's path URL strategy resolves the route"
    why_human: "SPA rewrite + usePathUrlStrategy are code-verified but actual Firebase deploy has not been run; CDN routing requires live test"
---

# Phase 14: Release Hardening & Cutover Safety — Verification Report

**Phase Goal:** Users can safely transition to the Flutter app in production without silent data loss or deployment breakage.
**Verified:** 2026-02-21
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User gets equivalent behavior outcomes across web, Android, and iOS for the same workout inputs | ✓ VERIFIED | 29/29 parity tests pass live (`flutter test`); calculations.dart is line-for-line equivalent to v1.1 calculations.ts |
| 2 | Existing user data has a defined migration/continuity path with no silent data loss during cutover | ✓ VERIFIED | `docs/DATA_MIGRATION_GUIDE.md` (80 lines) documents both Supabase sync and local-only paths explicitly; no silent discard |
| 3 | User can open and refresh deep links on Firebase-hosted web routes without 404 errors | ✓ VERIFIED | `firebase.json` has `** → /index.html` rewrite; `usePathUrlStrategy()` in `main.dart` after `ensureInitialized()`; WASM MIME header present |
| 4 | Team can produce reproducible signed Android and iOS release builds from pipeline | ⚠️ PARTIAL | Android AAB signing wired via GitHub Secrets ✓; iOS CI builds are `--no-codesign` (unsigned) by documented design — manual App Store signing required |
| 5 | Production rollout uses defined telemetry thresholds and a tested rollback path | ⚠️ PARTIAL | `ROLLOUT_SAFETY.md` is comprehensive (staged %, go/no-go, rollback for all 3 platforms) ✓; Crashlytics error handlers wired in `main.dart` ✓; **but `firebase_options.dart` not yet generated** — Crashlytics silently skipped at runtime until `flutterfire configure` is run |

**Score:** 4.5/5 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `flutter_app/test/parity_gates/calculations_parity_test.dart` | PLAT-02 parity gate | ✓ VERIFIED | 222 lines, 29 assertions, all pass |
| `flutter_app/lib/core/recommendations/calculations.dart` | Flutter port of v1.1 calculations.ts | ✓ VERIFIED | 91 lines, all 8 exported functions, no stubs |
| `docs/DATA_MIGRATION_GUIDE.md` | DATA-01 migration doc | ✓ VERIFIED | 80 lines, 2 migration paths, FAQ section |
| `firebase.json` | SPA hosting config | ✓ VERIFIED | Valid JSON, SPA rewrite, WASM MIME, cache-control |
| `flutter_app/lib/main.dart` | URL strategy + Crashlytics | ✓ VERIFIED | `usePathUrlStrategy()` + Firebase try/catch + dual error handlers |
| `flutter_app/android/app/build.gradle.kts` | App ID + release signing | ✓ VERIFIED | `applicationId = "com.sundeefundee.app"`, keystore decode block, `isMinifyEnabled = false` |
| `flutter_app/android/app/src/main/AndroidManifest.xml` | Android display name | ✓ VERIFIED | `android:label="Sundee Fundee"` |
| `flutter_app/ios/Runner/Info.plist` | iOS display name | ✓ VERIFIED | `CFBundleDisplayName = Sundee Fundee`, `CFBundleName = Sundee Fundee` |
| `flutter_app/ios/Runner.xcodeproj/project.pbxproj` | iOS bundle ID | ✓ VERIFIED | 3× `com.sundeefundee.app`, 3× `com.sundeefundee.app.RunnerTests`; no `flutterApp` or `flutter_app` variants remaining |
| `.github/workflows/flutter-release.yml` | CI release workflow | ✓ VERIFIED | 90 lines, 3 jobs (web/android/ios), Flutter 3.29.3, secrets injection |
| `flutter_app/pubspec.yaml` | Firebase dependencies | ✓ VERIFIED | `firebase_core: ^3.14.0`, `firebase_crashlytics: ^4.3.0` present |
| `docs/ROLLOUT_SAFETY.md` | Rollout safety plan | ✓ VERIFIED | 170 lines, staged 1%→10%→50%→100%, go/no-go table, rollback procedures for Android/iOS/web |
| `flutter_app/lib/firebase_options.dart` | Crashlytics config (generated) | ✗ MISSING | Expected — requires `flutterfire configure` run; absence is handled by try/catch but Crashlytics is INACTIVE until generated |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `calculations_parity_test.dart` | `calculations.dart` | `import 'package:sundee_fundee/core/recommendations/calculations.dart'` | ✓ WIRED | Import present; 29 live assertions verified |
| `calculations.dart` | v1.1 `calculations.ts` | logic match | ✓ VERIFIED | All 8 function implementations match TS source; parity confirmed by test run |
| `firebase.json` | `flutter_app/build/web` | `hosting.public` | ✓ WIRED | Correct Flutter web build output directory |
| `flutter_app/build/web/**` | `/index.html` | `rewrites[0].source = "**"` | ✓ WIRED | Catch-all rewrite prevents 404 on deep link refresh |
| `main.dart` | `usePathUrlStrategy()` | import + call | ✓ WIRED | Called immediately after `ensureInitialized()`, before routing |
| `main.dart` | `FirebaseCrashlytics` | `FlutterError.onError + PlatformDispatcher.onError` | ✓ WIRED (conditional) | Wired inside try/catch; inactive without `firebase_options.dart` |
| `build.gradle.kts` | keystore (CI secret) | `ANDROID_KEYSTORE_BASE64` env decode | ✓ WIRED | Reads env var, decodes base64, writes to `${buildDir}/keystore.jks`, fallback to debug |
| `flutter-release.yml` | `build.gradle.kts` | `ANDROID_KEYSTORE_*` env injection | ✓ WIRED | 4 secrets mapped to env vars in `build-android` job |
| `flutter-release.yml` | `flutter_app/**` changes | `on.push.paths` trigger | ✓ WIRED | Workflow triggers on any `flutter_app/**` change or workflow file edit |
| iOS pipeline | App Store Connect | `--no-codesign` + manual | ⚠️ PARTIAL | Pipeline produces unsigned IPA; human must sign via Xcode/Transporter |

---

## Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| PLAT-02: Calculations parity | ✓ SATISFIED | 29/29 tests pass |
| DATA-01: No silent data loss | ✓ SATISFIED | Both migration paths documented |
| DPLY-01: SPA deep links | ✓ SATISFIED | firebase.json rewrite + path URL strategy |
| DPLY-02: Reproducible release builds | ⚠️ PARTIAL | Android: fully signed by CI. iOS: unsigned from CI, manual signing needed |
| DPLY-03: Rollout safety + telemetry | ⚠️ PARTIAL | Documentation and code complete; Crashlytics inert until `flutterfire configure` |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `flutter_app/android/app/build.gradle.kts` | 26 | `// TODO: Specify your own unique Application ID` | ℹ️ Info | Flutter-generated template comment; `applicationId` is already correctly set to `com.sundeefundee.app`. Dead comment, not a blocker. |

---

## Human Verification Required

### 1. CI Workflow End-to-End Build

**Test:** Push a change to `flutter_app/` on a branch and let the `flutter-release.yml` workflow run to completion.
**Expected:** All three jobs (`build-web`, `build-android`, `build-ios`) exit green; artifacts (`web-release/`, `app-release.aab`, iOS IPA dir) are present in GitHub Actions artifacts.
**Why human:** No CI run history can be verified from the codebase alone. `flutter pub get`, `pod install`, and the build commands must be executed against real runners to confirm they complete without error.

### 2. Firebase Crashlytics Activation

**Test:** Run `flutterfire configure` inside `flutter_app/`, confirm `lib/firebase_options.dart` is generated, rebuild the app, and verify a test crash event appears in Firebase Console Crashlytics.
**Expected:** `Firebase.initializeApp()` succeeds (no exception swallowed), Crashlytics dashboard shows the test event.
**Why human:** `firebase_options.dart` does not exist in the repo. The current try/catch silently suppresses Crashlytics in its absence. Telemetry is not operational in production until this step is done and `firebase_options.dart` is committed / injected via CI. This is a deployment prerequisite, but it blocks the "defined telemetry thresholds" truth from being fully operational.

### 3. iOS Signed Release Build

**Test:** Download the `ios-release` IPA artifact from a CI run; open in Xcode Organizer or Transporter with a valid Apple Developer account; sign and attempt upload to App Store Connect.
**Expected:** Signing succeeds, upload is accepted by App Store Connect.
**Why human:** The pipeline intentionally produces `--no-codesign` IPA. Apple Developer certificates are not available in open CI. A human with an enrolled Apple Developer account must complete the signing step.

### 4. Deep Link Refresh on Live Firebase Hosting

**Test:** Run `flutter build web --release`, then `firebase deploy --only hosting`. Navigate to `/workout` directly (typing in browser address bar) and hit Refresh.
**Expected:** Page loads the Flutter app on the correct route — no 404, no redirect loop, no `/#/` hash prefix in URL.
**Why human:** The SPA rewrite rule and `usePathUrlStrategy()` are code-verified but the full CDN+routing path requires a live Firebase Hosting deployment.

---

## Gaps Summary

All code artifacts exist, are substantive, and are correctly wired. There are **no missing files, stubs, or broken links** that would prevent the phase goal from being achieved. The two partial items (iOS signing, Crashlytics activation) are:

1. **By design / documented limitations:** iOS CI signing requires Apple Developer certs unavailable in open CI — this is captured in `ROLLOUT_SAFETY.md` prerequisites and the GitHub Actions decision log (D-14-05-3).
2. **Deployment prerequisites:** `firebase_options.dart` is a post-commit generation step (`flutterfire configure`) required before any production deployment — explicitly listed in `ROLLOUT_SAFETY.md` prerequisites checklist.

Neither constitutes a code gap requiring re-planning. The phase goal is architecturally complete; the remaining items are operational deployment steps that require human action.

---

## Evidence Summary

| Plan | Artifact | Lines | Live Test Result |
|------|----------|-------|-----------------|
| 14-01 | `calculations_parity_test.dart` | 222 | ✅ 29/29 passed (`flutter test`) |
| 14-02 | `docs/DATA_MIGRATION_GUIDE.md` | 80 | N/A (documentation) |
| 14-03 | `firebase.json` | 28 | N/A (config JSON, valid) |
| 14-03 | `main.dart` (URL strategy) | 47 | N/A (structural check) |
| 14-04 | `build.gradle.kts` | 65 | N/A (config) |
| 14-04 | `AndroidManifest.xml` | — | `Sundee Fundee` label ✓ |
| 14-04 | `Info.plist` | — | `Sundee Fundee` display name ✓ |
| 14-04 | `project.pbxproj` | — | 6× bundle IDs all `com.sundeefundee.app[.RunnerTests]` ✓ |
| 14-05 | `.github/workflows/flutter-release.yml` | 90 | N/A (never run) |
| 14-06 | `pubspec.yaml` Firebase deps | — | `firebase_crashlytics: ^4.3.0` ✓ |
| 14-06 | `main.dart` Crashlytics wiring | — | Dual error handlers wired ✓; firebase_options.dart missing |
| 14-06 | `docs/ROLLOUT_SAFETY.md` | 170 | N/A (documentation) |

---

_Verified: 2026-02-21_
_Verifier: Claude (gsd-verifier)_
