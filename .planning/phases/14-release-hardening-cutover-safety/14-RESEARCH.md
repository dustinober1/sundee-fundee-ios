# Phase 14: Release Hardening + Cutover Safety — Research

**Researched:** 2026-02-21
**Domain:** Flutter release pipeline, data migration, Firebase Hosting, CI/CD signing, rollout safety
**Confidence:** HIGH (DPLY-01, DATA-01 analysis), MEDIUM (DPLY-02, DPLY-03), LOW (Crashlytics integration detail without Firebase project)

---

## Summary

Phase 14 closes the gap between a working Flutter app (Phases 9–13) and a safely deployable, user-trustworthy production release. Five distinct requirements span three problem domains: **behavioral equivalence** across platforms (PLAT-02), **data continuity** during cutover (DATA-01), and **deployment infrastructure** (DPLY-01/02/03).

The codebase is in excellent shape for most of this phase. Calculations are already a verified port (calculations.dart = calculations.ts), parity gate tests cover Phases 9–13 behaviors, and the Supabase sync layer (Phase 13) is the natural bridge for data migration. The main gaps are: (1) firebase.json doesn't exist yet, (2) no signed Android/iOS release configs exist, (3) no Flutter CI workflow exists, and (4) no telemetry/rollback plan is defined.

**Primary recommendation:** Address the five requirements as three parallel workstreams — parity gate (PLAT-02), migration path documentation + test (DATA-01), and deployment infrastructure (DPLY-01/02/03 together since they share CI).

---

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---|---|---|
| `flutter_riverpod` | 3.2.1 | State management | Already in app |
| `go_router` | 17.1.0 | Path-based URL routing | Already in app |
| `drift` / `drift_flutter` | 2.31.0 / 0.2.8 | SQLite persistence | Already in app |
| `supabase_flutter` | 2.12.0 | Cloud sync + auth | Already in app |
| `subosito/flutter-action@v2` | v2 | Flutter in GitHub Actions | Community standard |
| `firebase_crashlytics` | ~4.x | Crash telemetry | Firebase-official, pairs with flutterfire |
| `flutterfire_cli` | latest | Firebase project wiring | Official Flutter Firebase setup tool |

### Supporting

| Tool | Purpose | When to Use |
|---|---|---|
| `dexie-export-import` npm package | Export Dexie IndexedDB to JSON blob | Web→Flutter manual migration |
| `usePathUrlStrategy()` (Flutter web) | Clean path-based URLs (no `/#/`) | Required for Firebase Hosting rewrites to work |
| `key.properties` + signingConfig | Android release keystore config | Required for Play Store upload |
| App Store Connect API key (JSON) | iOS signing in CI (no interactive login) | Required for `flutter build ipa --release` in CI |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Firebase Crashlytics | Sentry | Sentry has better filtering; Crashlytics is simpler when already in Firebase ecosystem |
| Google Play staged rollout | Firebase App Distribution | App Distribution is for beta/internal; Play Console staged rollout is for production |
| Manual signing in CI | Fastlane | Fastlane adds Ruby dependency; direct `flutter build` with secrets is simpler for small teams |

---

## Architecture Patterns

### PLAT-02: Cross-Platform Behavior Parity

**What exists:** All parity gate tests in `integration_test/parity_gates/` cover user flows (navigation, onboarding, workout, offline, recommendations, sync). `calculations.dart` is already a verified exact port of `calculations.ts` (same Epley formula with `reps.clamp(1,10)`, same `getNextRecommendedWeight`, same success logic).

**What's missing:** A dedicated **calculations parity gate** that proves Flutter produces numerically identical outputs to v1.1 for the same inputs. This is the PLAT-02 evidence artifact.

**Pattern: Parameterized parity test in `tests/unit/`**
```dart
// flutter_app/test/parity_gates/calculations_parity_test.dart
// Source: verified against src/lib/calculations.ts + src/lib/cycle-calculations.ts

import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee/core/recommendations/calculations.dart';

void main() {
  group('PLAT-02: Calculation parity (Dart == TypeScript v1.1)', () {
    // Epley 1RM
    test('epley: 225 lbs × 5 reps = 262.5', () {
      expect(epley(225, 5), closeTo(262.5, 0.01));
    });
    test('epley: clamps at 10 reps (225 × 12 == 225 × 10)', () {
      expect(epley(225, 12), equals(epley(225, 10)));
    });
    test('epley: 1 rep returns weight unchanged', () {
      expect(epley(225, 1), equals(225));
    });

    // roundToNearestFive
    test('roundToNearestFive: 137 -> 135', () {
      expect(roundToNearestFive(137), equals(135));
    });

    // getNextRecommendedWeight
    test('first: 70% of 1RM rounded to 5', () {
      expect(getNextRecommendedWeight(0, SessionResult.first, 200),
          equals(140)); // 200 * 0.7 = 140
    });
    test('success: +5 from current', () {
      expect(getNextRecommendedWeight(135, SessionResult.success, 300),
          equals(140));
    });
    test('failure: -5 from current, floor at 50% 1RM', () {
      expect(getNextRecommendedWeight(50, SessionResult.failure, 200),
          equals(100)); // floor = 200*0.5=100; 50-5=45 < floor
    });
  });
}
```

**Pattern: Integration parity test for Drift outcomes**
The existing `workout_parity_test.dart` already verifies Drift persistence after workout completion. For PLAT-02, add assertions that the computed recommendation weight stored in Drift matches expected values for given inputs — same test can run on Android emulator, iOS simulator, and web (Chrome with `flutter test -d chrome`).

---

### DATA-01: Dexie → Drift Migration Path

**Key insight:** There is no automatic migration from Dexie (IndexedDB, browser-native) to Drift (SQLite WASM for web, SQLite native for mobile). These are fundamentally different storage engines.

**The three cutover scenarios:**

| User Scenario | Migration Path | Effort |
|---|---|---|
| Had Supabase sync enabled (Phase 13) | Log in on Flutter → `syncPull` downloads all data to Drift automatically | Zero user effort |
| Web-only, no Supabase, switches to Flutter **mobile** | Must trigger export-then-import OR accept "fresh start" with clear messaging | Medium UX work |
| Web-only, no Supabase, opens Flutter **web** | Same browser, different storage engine — data is NOT automatically available | Must document |

**Primary path — Supabase-bridged migration (recommended, zero-code):**
Since Phase 13 already syncs all tables (ActiveCycles, CompletedWorkouts, CompletedSets, OneRepMaxes, PersonalRecords), users who sign in on Flutter web/mobile will have their data pulled from Supabase via `SyncService.syncPull()`. No additional code needed — just documentation.

**Secondary path — Manual export/import (for users without Supabase):**

Step 1: Web app exports via `dexie-export-import`:
```typescript
// src/lib/db/export.ts — new helper
import 'dexie-export-import';
export async function exportWorkoutData(): Promise<Blob> {
  return db.export({ prettyJson: true });
}
```

Step 2: User downloads JSON file.

Step 3: Flutter app reads file and imports via batch insert:
```dart
// Minimal import: only the 6 tables that have Drift equivalents
// Dexie tables NOT in Drift: setMetrics, periodLogs, symptomLogs,
//   bbtLogs, symptomDefinitions, cycleSettings, programs, userProgramPreferences
Future<void> importFromDexieJson(String jsonString, AppDatabase db) async {
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  await db.transaction(() async {
    for (final row in (data['data']['data'] as List)) {
      final table = row['tableName'] as String;
      final rows = row['rows'] as List<dynamic>;
      // map each table name → Drift companion inserts
      // handle FK ordering: users → activeCycles → completedWorkouts → completedSets/1RMs/PRs
    }
  });
}
```

**Data shape delta (Dexie v4 → Drift v4):**

| Dexie field | Drift field | Delta |
|---|---|---|
| `id` (string UUID) | `id` (int autoIncrement) | Cannot map directly — all local IDs differ; use `syncId` as the stable identity key |
| `userId` (string UUID) | `userId` (int FK to Users) | Needs Users row inserted first; local int ID differs |
| `completedAt` (string/number) | `completedAt` (DateTime) | Parse ISO string |
| `setMetrics` table | No Drift equivalent | Drop silently (derived data; can be recomputed) |
| `period*`, `symptom*`, `bbt*`, `cycleSettings` | No Drift equivalent | Out of scope for Flutter v2.0 |

**Verdict:** The DATA-01 requirement ("defined migration/continuity path with no silent data loss") is satisfied by:
1. In-app messaging: "Connect your account to preserve workout history across devices." 
2. For Supabase users: automatic on sign-in.
3. For non-Supabase users: opt-in manual export/import feature OR explicit "fresh start" acknowledgment.
4. A unit test proving the import logic handles all 6 table types without error.

---

### DPLY-01: Firebase Hosting + SPA Deep Link Fix

**Current state:** `firebase.json` does **not exist** in the repo root. The Flutter app uses GoRouter with path-based routing (no `/#/` hash strategy). Without a `firebase.json` rewrite, every page refresh or direct deep link returns a 404.

**Fix — create `firebase.json`:**
```json
{
  "hosting": {
    "public": "flutter_app/build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "**/*.wasm",
        "headers": [{ "key": "Content-Type", "value": "application/wasm" }]
      }
    ]
  }
}
```

**Why the WASM header:** `sqlite3.wasm` must be served with `application/wasm` MIME type or SharedArrayBuffer will refuse to load it. Firebase Hosting does not auto-set this header.

**Required Flutter web config — `usePathUrlStrategy()`:**
```dart
// flutter_app/lib/main.dart — add before runApp()
import 'package:flutter_web_plugins/url_strategy.dart';
// ...
void main() async {
  usePathUrlStrategy(); // removes # from URLs
  // ... rest of main
}
```

**Deployment command:**
```bash
flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
firebase deploy --only hosting
```

**Anti-pattern:** Do NOT use `HashUrlStrategy`. GoRouter already defaults to path-based; hash strategy would break deep links in a different way.

---

### DPLY-02: Signed Android + iOS Release Builds in CI

**Current state:**
- Android: `applicationId = "com.sundeefundee.flutter_app"`, signing uses debug keys only (`signingConfig = signingConfigs.getByName("debug")`)
- iOS: Bundle ID is `$(PRODUCT_BUNDLE_IDENTIFIER)` (undefined/template), display name "Flutter App"
- No Flutter GitHub Actions workflow exists (only `playwright.yml` for Next.js web)

**Android signing pattern:**

`android/app/build.gradle.kts` (add signingConfigs block):
```kotlin
android {
  signingConfigs {
    create("release") {
      storeFile = file(System.getenv("KEYSTORE_PATH") ?: "upload-keystore.jks")
      storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
      keyAlias = System.getenv("KEY_ALIAS") ?: ""
      keyPassword = System.getenv("KEY_PASSWORD") ?: ""
    }
  }
  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
      minifyEnabled = false // Drift codegen incompatible with R8 minification without rules
    }
  }
}
```

**Required GitHub secrets:**
- `KEYSTORE_BASE64` — base64-encoded JKS file
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`  
- `KEY_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_ID` — for iOS
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8` — base64-encoded .p8 file
- `APPLE_SIGNING_CERT_BASE64` — .p12 cert
- `APPLE_PROVISIONING_PROFILE_BASE64`
- `SUPABASE_URL` + `SUPABASE_ANON_KEY` — for build-time --dart-define

**GitHub Actions workflow pattern (`.github/workflows/flutter-release.yml`):**
```yaml
name: Flutter Release Build

on:
  push:
    tags: ['v*.*.*']

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
          channel: stable
          cache: true
      - run: flutter pub get
        working-directory: flutter_app
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > flutter_app/android/app/upload-keystore.jks
      - name: Build AAB
        working-directory: flutter_app
        env:
          KEYSTORE_PATH: upload-keystore.jks
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: flutter build appbundle --release
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }}
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      - uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: flutter_app/build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
          channel: stable
          cache: true
      - run: flutter pub get
        working-directory: flutter_app
      - name: Import signing cert
        run: |
          echo "${{ secrets.APPLE_SIGNING_CERT_BASE64 }}" | base64 --decode > cert.p12
          security create-keychain -p "" build.keychain
          security import cert.p12 -k build.keychain -P "" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain
      - name: Install provisioning profile
        run: |
          echo "${{ secrets.APPLE_PROVISIONING_PROFILE_BASE64 }}" | base64 --decode > profile.mobileprovision
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
      - name: Build IPA
        working-directory: flutter_app
        run: flutter build ipa --release --no-codesign
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }}
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      - uses: actions/upload-artifact@v4
        with:
          name: ios-release
          path: flutter_app/build/ios/ipa/*.ipa

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
          channel: stable
          cache: true
      - run: flutter pub get
        working-directory: flutter_app
      - name: Build web
        working-directory: flutter_app
        run: flutter build web --release
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }}
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          channelId: live
```

**iOS gotcha:** `flutter build ipa --release` requires a real device connected OR `--no-codesign` for the artifact; actual codesign happens via `xcodebuild` or Fastlane if App Store upload is needed. For Phase 14 goal ("reproducible signed builds from pipeline"), producing a signed artifact that can be manually uploaded satisfies the requirement.

**App metadata fixes needed before signing:**
- Android: `android:label="flutter_app"` in `AndroidManifest.xml` → `"Sundee Fundee"`
- iOS: `CFBundleDisplayName` and `CFBundleName` in `Info.plist` → `"Sundee Fundee"`
- iOS: `PRODUCT_BUNDLE_IDENTIFIER` in Xcode project → `com.sundeefundee.app`
- Android: `applicationId` could stay as `com.sundeefundee.flutter_app` or change to `com.sundeefundee.app` (must decide before first Play Store submission — cannot change after)

---

### DPLY-03: Production Rollout Safety

**What "defined" means concretely:**

A *defined* rollout means three things are documented and tested **before** any user sees the new version:
1. **Telemetry threshold** — the numeric crash-free rate below which rollout pauses automatically
2. **Staged percentage plan** — the rollout schedule
3. **Rollback steps** — the specific actions taken if threshold is breached

**Standard pattern for Firebase + Google Play:**

**Telemetry tool:** `firebase_crashlytics` Flutter package
```yaml
# pubspec.yaml additions
dependencies:
  firebase_core: ^3.x
  firebase_crashlytics: ^4.x
```

**Initialization pattern:**
```dart
// main.dart additions
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart'; // generated by flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // ... rest of existing main()
}
```

**Staged rollout plan (Google Play):**
| Stage | Percentage | Hold Duration | Threshold to advance |
|---|---|---|---|
| Canary | 1% | 24 hours | Crash-free rate ≥ 99.5% |
| Early | 10% | 48 hours | Crash-free rate ≥ 99.5% |
| Broad | 50% | 48 hours | Crash-free rate ≥ 99% |
| Full | 100% | — | — |

**Rollback path:**
- **Google Play:** Play Console → Production → Manage release → Halt rollout. Users who already updated are not rolled back (Play Store limitation); issue a hotfix release.
- **App Store:** App Store Connect → phased release → Pause distribution. Same limitation — users who updated stay on new version.
- **Firebase Hosting (web):** `firebase hosting:rollback` — instantly reverts to previous deployment. No user limitation.

**Telemetry threshold = defined as 99% crash-free rate.** If Crashlytics Release Monitoring shows <99% for an expanding cohort, halt rollout and investigate before proceeding.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Flutter CI signing | Custom keytool scripts | `subosito/flutter-action@v2` + env secrets pattern | Proven, cached, handles Flutter version pinning |
| Cross-platform crash reporting | Custom error boundary | `firebase_crashlytics` | Handles both Flutter errors and platform-native crashes |
| Firebase Hosting SPA routing | Custom 404 handler | `firebase.json` rewrites | Server-side — no client code needed |
| Dexie→Drift migration | Custom sync engine | Supabase pull (Phase 13 already done) | The sync layer already exists; migration is free for Supabase users |
| iOS signing | Custom xcodebuild scripts | Fastlane or `flutter build ipa --no-codesign` + manual upload | Apple's signing is complex; use established tooling |

---

## Common Pitfalls

### Pitfall 1: sqlite3.wasm served without WASM MIME type on Firebase
**What goes wrong:** Firebase Hosting serves `.wasm` as `application/octet-stream` by default. Chrome refuses to instantiate WASM modules without `application/wasm` MIME type in strict contexts.
**How to avoid:** Add explicit `headers` block in `firebase.json` for `**/*.wasm`.
**Warning signs:** Flutter web app hangs on load with `TypeError: Failed to execute 'compile' on 'WebAssembly'` in browser console.

### Pitfall 2: `usePathUrlStrategy()` must be called before `runApp()`
**What goes wrong:** If called after `runApp`, the URL strategy is ignored and `/#/` hash URLs are used, breaking Firebase rewrite rules.
**How to avoid:** Call `usePathUrlStrategy()` as the first statement in `main()` before any `await`.

### Pitfall 3: Android applicationId locked after first Play Store submission
**What goes wrong:** `com.sundeefundee.flutter_app` currently contains `flutter_app`, which looks wrong. But if any beta release is submitted with this ID, it cannot be changed.
**How to avoid:** Decide on the final application ID (`com.sundeefundee.app` recommended) before first upload.
**Warning signs:** Play Console shows app listed as "flutter_app" instead of "Sundee Fundee".

### Pitfall 4: Crashlytics requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
**What goes wrong:** `firebase_crashlytics` init crashes at runtime without these files. Neither file exists in the current repo.
**How to avoid:** Run `flutterfire configure` to generate `firebase_options.dart` and platform config files. These should NOT be committed if they contain sensitive project IDs — use `.gitignore` entries or environment injection.
**Warning signs:** `FirebaseException: [core/no-app] No Firebase App '[DEFAULT]' has been created` at app launch.

### Pitfall 5: iOS flutter build ipa requires Xcode 15+ and macOS 14+ runner
**What goes wrong:** Using `ubuntu-latest` for iOS builds fails immediately. iOS requires `macos-latest`.
**How to avoid:** Always use `runs-on: macos-latest` for iOS job.

### Pitfall 6: Drift + R8/ProGuard on Android release
**What goes wrong:** Drift's generated code uses reflection patterns that R8 minification strips by default, causing `MissingFieldException` on release builds.
**How to avoid:** Set `minifyEnabled = false` for release builds, OR add Drift-specific ProGuard rules (see Drift docs). For Phase 14, `minifyEnabled = false` is the safe default.

### Pitfall 7: Dexie data NOT automatically in Flutter (even same browser)
**What goes wrong:** A user who has been using the Next.js PWA and then opens the Flutter web build at the same origin will have empty data in Flutter, because Drift WASM SQLite uses a different IndexedDB key (`sundee_fundee` database) than Dexie (`StrengthApp`).
**How to avoid:** This is a known "same-origin, different storage" gap. Document it explicitly. The only automated bridge is Supabase sync. Add in-app copy: "Have your workout history? Sign in to restore your data."

---

## Code Examples

### Check `usePathUrlStrategy` placement
```dart
// Source: Flutter official docs — https://docs.flutter.dev/ui/navigation/url-strategies
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy(); // MUST be first — before WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();
  // ...
}
```

### Firebase Hosting rewrite (complete minimal firebase.json)
```json
{
  "hosting": {
    "public": "flutter_app/build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "**/*.wasm",
        "headers": [{ "key": "Content-Type", "value": "application/wasm" }]
      }
    ]
  }
}
```

### Android release signingConfig (build.gradle.kts)
```kotlin
// Source: Flutter deployment guide + Android signing docs
signingConfigs {
  create("release") {
    storeFile = file("upload-keystore.jks")
    storePassword = System.getenv("KEYSTORE_PASSWORD")!!
    keyAlias = System.getenv("KEY_ALIAS")!!
    keyPassword = System.getenv("KEY_PASSWORD")!!
  }
}
buildTypes {
  release {
    signingConfig = signingConfigs.getByName("release")
    minifyEnabled = false
  }
}
```

### Crashlytics minimal init
```dart
// Source: https://firebase.google.com/docs/crashlytics/flutter/get-started
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| `firebase_core` manual `GoogleService-Info.plist` copy | `flutterfire configure` CLI generates `firebase_options.dart` | Fewer manual steps, platform configs auto-generated |
| `--no-sound-null-safety` | Dart 3 null-safety is mandatory | All code already null-safe ✓ |
| `StateProvider` (Riverpod 1.x) | `NotifierProvider` (Riverpod 3.x) | Already using correct pattern ✓ |
| Hash URL strategy (`/#/routes`) | Path URL strategy + server rewrite | Required for Firebase Hosting; `usePathUrlStrategy()` needed |

---

## Open Questions

1. **Firebase project ID / google-services.json**
   - What we know: No Firebase project is configured yet (no `google-services.json`, `GoogleService-Info.plist`, or `firebase_options.dart`).
   - What's unclear: Does the team have an existing Firebase project, or does one need to be created?
   - Recommendation: Plan must include a `flutterfire configure` step as a prerequisite task. If no Firebase project exists, it must be created in Firebase Console first (outside CI).

2. **iOS bundle identifier**
   - What we know: Currently unset (`$(PRODUCT_BUNDLE_IDENTIFIER)` with no explicit value set in `project.pbxproj`).
   - What's unclear: Is `com.sundeefundee.app` the intended final ID?
   - Recommendation: Decide and hardcode before any TestFlight upload. Cannot change after first submission.

3. **Android applicationId rename risk**
   - What we know: Current ID is `com.sundeefundee.flutter_app` — looks like an oversight.
   - What's unclear: Has any release been submitted to Play Console under this ID?
   - Recommendation: If no prior submission, rename to `com.sundeefundee.app` in Phase 14. Document the change.

4. **Dexie export feature scope**
   - What we know: DATA-01 requires "no silent data loss" during cutover.
   - What's unclear: Is a full export/import UI required, or is in-app documentation + Supabase bridge sufficient?
   - Recommendation: Supabase bridge satisfies DATA-01 for syncing users. For non-sync users, a read-only "your data stays on this browser" notice + Supabase sign-up CTA satisfies "no silent loss" without requiring an import tool. A full import feature is out of scope for Phase 14.

5. **Next.js web app vs Flutter web app — same domain?**
   - What we know: `vercel.json` deploys Next.js; `firebase.json` will deploy Flutter web.
   - What's unclear: Will Flutter web replace the Next.js app at the same domain, or will they coexist?
   - Recommendation: Phase 14 should target Firebase Hosting for Flutter web at a staging URL. Production cutover (replacing Next.js at the primary domain) can be a separate deployment decision.

---

## Sources

### Primary (HIGH confidence)
- Firebase Hosting docs — https://firebase.google.com/docs/hosting/full-config — rewrites configuration
- Flutter URL strategy docs — https://docs.flutter.dev/ui/navigation/url-strategies — `usePathUrlStrategy()`
- Drift database schema in codebase — `flutter_app/lib/data/database/app_database.dart` — v4 schema
- Dexie schema in codebase — `src/lib/db/dexie.ts` — v4 schema
- Calculations parity — `flutter_app/lib/core/recommendations/calculations.dart` vs `src/lib/calculations.ts` — verified identical logic
- Existing CI — `.github/workflows/playwright.yml` — confirms no Flutter CI workflow exists
- `firebase.json` — confirmed NOT present in repo root

### Secondary (MEDIUM confidence)
- Firebase Crashlytics Flutter get-started — https://firebase.google.com/docs/crashlytics/flutter/get-started
- Flutter continuous delivery docs — https://docs.flutter.dev/deployment/cd
- `subosito/flutter-action` v2 — standard Flutter GitHub Actions setup
- Firebase Release Monitoring — https://firebase.google.com/docs/release/release-monitoring

### Tertiary (LOW confidence)
- Dexie → Drift migration pattern — WebSearch + official Dexie export-import docs (verified) + Drift import example — no single authoritative source for this specific cross-platform case

---

## Metadata

**Confidence breakdown:**
- PLAT-02 (calculations parity): HIGH — source code verified, logic is identical
- DATA-01 (migration path): HIGH — Supabase bridge path is zero-code (Phase 13); manual path is LOW confidence on import details
- DPLY-01 (Firebase rewrites): HIGH — standard pattern, official docs verified
- DPLY-02 (signed builds): MEDIUM — standard pattern exists, but no Firebase project or signing certs exist yet; CI workflow untested in this repo
- DPLY-03 (rollout safety): MEDIUM — standard pattern, but Firebase project must exist first for Crashlytics

**Research date:** 2026-02-21
**Valid until:** 2026-03-21 (stable tooling; Firebase + Flutter APIs rarely change)
