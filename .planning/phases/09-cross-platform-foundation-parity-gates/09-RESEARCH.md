# Phase 9: Cross-Platform Foundation + Parity Gates - Research

**Researched:** 2026-02-20
**Domain:** Flutter cross-platform app foundation, integration testing, offline parity
**Confidence:** HIGH (primary findings from pub.dev API, Flutter official docs, and verified package metadata)

---

## Summary

Phase 9 is the first phase of the v2.0 Flutter Full Rewrite. The existing product is a Next.js/React app (~11,947 LOC) with 11 passing Playwright E2E tests covering onboarding, workout flow, recommendations, sync, and cycle logging. Phase 9 creates a **new Flutter app** — a separate project directory within the monorepo — and establishes cross-platform parity test gates before feature migration proceeds.

The standard approach is: (1) `flutter create` a new project targeting web + Android + iOS, (2) wire up the foundational stack (Drift for local storage, Riverpod for state, go_router for navigation, supabase_flutter for optional sync, connectivity_plus for offline detection), (3) write integration tests using Flutter's built-in `integration_test` SDK package that can be run on all three platforms with identical assertions, and (4) define explicit parity gates as named test groups that must all pass on all three platforms before Phase 10 (feature migration) begins.

The key architectural decision is that **Drift 2.31.0 + drift_flutter 0.2.8** is the correct local-first SQLite replacement for the Next.js app's Dexie.js. Drift works on Android, iOS, macOS, Windows, Linux, and web — but web requires sqlite3.wasm and drift_worker.js to be manually placed in `web/`. Offline parity tests use `connectivity_plus` with mock injection in widget/unit tests, or `patrol` 4.1.1 for full native airplane-mode simulation in integration tests.

**Primary recommendation:** Create `flutter_app/` as the Flutter project root co-located with the Next.js app, not replacing it. Use Flutter's built-in `integration_test` (SDK package) for all cross-platform tests. Run the same test file on web, Android, and iOS as the parity gate mechanism.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.41.2 (stable) | Cross-platform UI framework | Latest stable as of 2026-02-20 |
| Dart SDK | 3.7.0 (bundled) | Language | Bundled with Flutter 3.41.2 |
| drift | ^2.31.0 | Reactive SQLite ORM (local-first DB) | Works on all 6 platforms including web; type-safe; reactive streams; replaces Dexie.js |
| drift_flutter | ^0.2.8 | Flutter DB setup helper | Single `driftDatabase(name:)` call handles all platforms |
| flutter_riverpod | ^3.2.1 | State management | Official Flutter team endorsed; DI via ProviderScope; best for offline-first |
| go_router | ^17.1.0 | Declarative navigation with deep links | Flutter team maintained; works on all platforms |
| connectivity_plus | ^7.0.0 | Network connectivity detection | Flutter Favorites; supports Android/iOS/web/desktop |
| supabase_flutter | ^2.12.0 | Optional cloud sync (matches Next.js version) | Official Supabase Flutter client |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| integration_test | sdk: flutter | Cross-platform integration tests | All integration/E2E tests; use SDK version, NOT pub.dev package |
| flutter_test | sdk: flutter | Unit/widget test framework | All unit and widget tests |
| mocktail | ^1.0.4 | Mocking for unit tests | Repository and service mocks |
| patrol | ^4.1.1 | Advanced cross-platform E2E (native automation) | When you need native airplane mode, notifications, etc. in tests |
| flutter_lints | ^6.0.0 | Lint rules | Standard project linting |
| path_provider | ^2.1.5 | App document directory (needed by drift on native) | Already handled by drift_flutter |
| shared_preferences | ^2.5.4 | Simple key-value (app settings, onboarding done flag) | For simple non-relational persisted values |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| drift | sqflite 2.4.2 | sqflite doesn't work on web without sqflite_common_ffi_web workaround; drift handles all platforms natively |
| drift | isar 3.1.0+1 | Isar is fast but web support is immature; not recommended for web targets |
| drift | hive 2.2.3 | Hive lacks SQL query power; poor for relational workout data |
| flutter_riverpod | flutter_bloc 9.1.1 | Bloc is more verbose for this scale; Riverpod preferred for offline-first reactive data |
| integration_test SDK | patrol | Patrol adds value for native automation; use patrol on top of integration_test, not instead |
| go_router | Navigator 2.0 | go_router is the official high-level abstraction over Navigator 2.0 |

### Installation

```bash
# New Flutter project (run from repo root)
flutter create flutter_app --platforms=web,android,ios

cd flutter_app

# Add to pubspec.yaml dependencies:
flutter pub add drift drift_flutter flutter_riverpod go_router connectivity_plus supabase_flutter shared_preferences

# Add to pubspec.yaml dev_dependencies:
flutter pub add --dev flutter_lints mocktail patrol

# integration_test and flutter_test are added as SDK deps (not via pub add):
# dev_dependencies:
#   integration_test:
#     sdk: flutter
#   flutter_test:
#     sdk: flutter
```

---

## Architecture Patterns

### Recommended Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                    # Entry point, ProviderScope, Supabase.initialize()
│   ├── app.dart                     # MaterialApp.router with go_router config
│   ├── router/
│   │   └── router.dart              # GoRouter definition — all routes
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart    # @DriftDatabase class
│   │   │   ├── tables/              # Drift table definitions (UserTable, WorkoutTable, etc.)
│   │   │   └── daos/                # Data access objects per domain
│   │   ├── repositories/
│   │   │   ├── user_repository.dart
│   │   │   ├── workout_repository.dart
│   │   │   └── sync_repository.dart # Supabase sync (optional)
│   │   └── models/                  # Immutable domain models (freezed or manual)
│   ├── features/
│   │   ├── onboarding/
│   │   ├── dashboard/
│   │   ├── programs/
│   │   ├── workout/
│   │   ├── progress/
│   │   └── cycle/
│   ├── shared/
│   │   ├── widgets/                 # Shared UI components
│   │   ├── providers/               # Cross-feature Riverpod providers
│   │   └── theme/                   # MaterialTheme, colors, typography
│   └── core/
│       ├── connectivity/            # Connectivity service wrapping connectivity_plus
│       └── constants.dart
├── test/                            # Unit + widget tests (flutter test)
│   ├── data/
│   │   └── repositories/
│   └── features/
├── integration_test/                # Cross-platform parity tests (flutter test integration_test/)
│   ├── helpers/
│   │   └── app_helper.dart          # Shared test setup utilities
│   ├── parity_gates/
│   │   ├── navigation_parity_test.dart    # Launch and navigate on all platforms
│   │   ├── onboarding_parity_test.dart    # Onboarding flow parity
│   │   ├── workout_parity_test.dart       # Critical workout flow parity
│   │   └── offline_parity_test.dart       # Offline scenarios parity (QUAL-02)
│   └── all_tests.dart               # Aggregates all parity tests
├── web/
│   ├── index.html
│   ├── sqlite3.wasm                 # REQUIRED for drift web support
│   └── drift_worker.js              # REQUIRED for drift web support
├── android/
├── ios/
└── pubspec.yaml
```

### Pattern 1: Integration Test as Parity Gate

**What:** Every critical flow is a named `testWidgets` group in `integration_test/`. The same file runs on web, Android, and iOS. "Parity gate" = all tests in the gate group must report PASS on all 3 platforms.

**When to use:** All acceptance tests for QUAL-01 and QUAL-02.

```dart
// integration_test/parity_gates/navigation_parity_test.dart
// Source: https://docs.flutter.dev/testing/integration-tests

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sundee_fundee/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Navigation (PLAT-01)', () {
    testWidgets('app launches on platform', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app starts — onboarding if no user, dashboard if user exists
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    });

    testWidgets('can navigate to programs screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      // ... navigation assertions
    });
  });
}
```

**Running on each platform:**
```bash
# Web (requires ChromeDriver)
npx @puppeteer/browsers install chromedriver@stable
chromedriver --port=4444 &
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/parity_gates/navigation_parity_test.dart \
  -d chrome

# Android (device/emulator must be connected)
flutter test integration_test/parity_gates/navigation_parity_test.dart \
  -d <android_device_id>

# iOS (simulator must be running)
flutter test integration_test/parity_gates/navigation_parity_test.dart \
  -d <ios_simulator_id>
```

### Pattern 2: Offline Parity Test via Connectivity Mock

**What:** Inject a fake connectivity stream that reports `ConnectivityResult.none`, verify critical flows still work from Drift local data.

**When to use:** QUAL-02 offline parity scenarios.

```dart
// integration_test/parity_gates/offline_parity_test.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Fake connectivity for deterministic offline tests
class FakeConnectivity extends ConnectivityPlatform {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.none];
  }

  void goOffline() => _controller.add([ConnectivityResult.none]);
  void goOnline() => _controller.add([ConnectivityResult.wifi]);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Offline Scenarios (QUAL-02)', () {
    late FakeConnectivity fakeConnectivity;

    setUp(() {
      fakeConnectivity = FakeConnectivity();
      ConnectivityPlatform.instance = fakeConnectivity;
    });

    testWidgets('shows offline indicator when disconnected', (tester) async {
      fakeConnectivity.goOffline();
      // ... pump app, verify offline indicator
    });

    testWidgets('workout data persists to Drift offline', (tester) async {
      fakeConnectivity.goOffline();
      // ... complete workout flow, verify saved to local DB
    });
  });
}
```

### Pattern 3: Drift Database Setup (Cross-Platform)

**What:** Single `driftDatabase(name:)` call works on all platforms. Web requires wasm files.

```dart
// lib/data/database/app_database.dart
// Source: https://pub.dev/packages/drift_flutter

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Programs, WorkoutSessions, CompletedSets])
final class AppDatabase extends _$AppDatabase {
  // Constructor for tests (in-memory)
  AppDatabase(super.e);

  // Default constructor for production
  AppDatabase.defaults() : super(driftDatabase(name: 'sundee_fundee'));

  @override
  int get schemaVersion => 1;
}

// In ProviderScope override for tests:
// final db = AppDatabase(NativeDatabase.memory());
```

**Web wasm setup** (required; do NOT hand-roll):
```bash
# From flutter_app/ directory — download drift web assets
dart run drift_dev:make-migrations   # if using migrations
# Download sqlite3.wasm and drift_worker.js per drift docs:
# https://drift.simonbinder.eu/platforms/web/
```

### Pattern 4: Riverpod Provider Structure

```dart
// lib/data/repositories/workout_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});
```

### Anti-Patterns to Avoid

- **Using `flutter_driver` (legacy):** flutter_driver is effectively deprecated. Use `integration_test` (SDK package). The pub.dev `flutter_driver` package (0.0.1) is a stub.
- **Using pub.dev `integration_test` 1.0.2+3:** This is discontinued and marked as "Dart 3 incompatible". Always use `integration_test: sdk: flutter`.
- **sqflite for web targets:** sqflite doesn't work natively on web. If web is in scope, use drift.
- **Different test files per platform:** One test file runs on all platforms. That's the parity guarantee. Never write `web_test.dart` and `android_test.dart` separately.
- **Running integration_test directly:** `flutter test integration_test/` works on native; for web you must use `flutter drive` with ChromeDriver running. Plan for this setup in CI.
- **Skipping wasm file setup for drift on web:** The app will crash at DB init on web without `sqlite3.wasm` in `web/`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-platform local DB | Custom SQLite adapter per platform | `drift` + `drift_flutter` | Drift handles web (wasm), Android, iOS with one API |
| Connectivity detection | Platform channels to check network | `connectivity_plus` | Handles all platform edge cases, provides stream |
| Navigation with deep links | Custom Navigator 2.0 implementation | `go_router` | Deep links, web URL sync, redirects, nested navigation |
| State management | InheritedWidget boilerplate | `flutter_riverpod` | DI, testability, reactive DB streams |
| Test double for Connectivity | Fake platform channels | `ConnectivityPlatform.instance =` swap | `connectivity_plus_platform_interface` supports DI |
| Integration test runner | Custom driver scripts | `flutter test integration_test/` + `flutter drive` | Built into SDK; handles Android, iOS, web |
| Offline queue | Custom HTTP retry logic | Supabase client offline detection + local queue in Drift | Supabase handles auth token refresh; local Drift stores unsynced rows |

**Key insight:** The temptation is to write platform-specific DB adapters or custom connectivity services. Both problems are solved by mature packages that handle the edge cases (web wasm threading, iOS network permission dialogs, Android connectivity API changes in SDK 30+).

---

## Common Pitfalls

### Pitfall 1: Using Deprecated integration_test from pub.dev

**What goes wrong:** Developer adds `integration_test: ^1.0.2+3` from pub.dev. Package is "Dart 3 incompatible" and discontinued. Tests fail to compile.

**Why it happens:** pub.dev search returns the deprecated package first by name.

**How to avoid:** Always use:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```
**Warning signs:** `Dart 3 incompatible` badge on the package page; compiler errors about `WidgetsBinding`.

### Pitfall 2: Drift Web Missing wasm Files

**What goes wrong:** Flutter web app crashes with `Could not initialize database` or `TypeError: Cannot read properties of null (reading 'open')` at runtime.

**Why it happens:** Drift web requires `sqlite3.wasm` and `drift_worker.js` in the `web/` directory. `flutter create` does not add these. They must be manually downloaded and placed there.

**How to avoid:** Add as a build step — download the wasm files from drift's GitHub releases during `flutter create` setup. Check drift docs at `https://drift.simonbinder.eu/platforms/web/` for exact file URLs per drift version.

**Warning signs:** App runs fine on Android/iOS, crashes on web at startup.

### Pitfall 3: Chrome/ChromeDriver Version Mismatch for Web Tests

**What goes wrong:** `flutter drive` for web fails with ChromeDriver version mismatch error.

**Why it happens:** ChromeDriver version must match the installed Chrome version exactly.

**How to avoid:** Use `npx @puppeteer/browsers install chromedriver@stable` which matches stable Chrome. Pin this in CI.

**Warning signs:** `ChromeDriver only supports Chrome version X` error.

### Pitfall 4: Parity Tests Coupled to Platform-Specific UI

**What goes wrong:** Integration tests that pass on iOS but fail on web/Android because they assert platform-specific widgets (e.g., `CupertinoButton`, `Material` splash effects).

**Why it happens:** Tests written on iOS first using iOS-specific widget finders.

**How to avoid:** Use semantic finders (`find.bySemanticsLabel`, `find.text`, `find.byKey`) not renderer-specific ones. All parity gate tests must use platform-agnostic selectors.

**Warning signs:** Test passes on one platform but finds 0 widgets on another.

### Pitfall 5: Offline Tests Not Deterministic

**What goes wrong:** Offline parity tests are flaky because they depend on actual network state or timing of connectivity_plus stream emissions.

**Why it happens:** Connectivity stream is async; tests proceed before offline state is registered by the app.

**How to avoid:** Inject `FakeConnectivity` via `ConnectivityPlatform.instance` in `setUp`. Call `fakeConnectivity.goOffline()` before `pumpWidget`. Use `pumpAndSettle()` to drain async updates.

**Warning signs:** Tests pass in isolation but fail in CI; different results on different network environments.

### Pitfall 6: flutter_app Inside Next.js Project Causes Build Conflicts

**What goes wrong:** Placing Flutter project at root or inside `src/` causes Next.js or Flutter build tools to pick up each other's files.

**Why it happens:** Both frameworks have strong conventions about directory ownership.

**How to avoid:** Create Flutter project as `flutter_app/` at the monorepo root, completely separate from Next.js files. Add `flutter_app/` paths to `.gitignore` exclusions carefully — both `flutter_app/.dart_tool/` and `flutter_app/build/` should be gitignored.

---

## Code Examples

### Minimal App Setup with All Stack Components

```dart
// flutter_app/lib/main.dart
// Source: supabase_flutter docs + flutter_riverpod docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(
    const ProviderScope(
      child: SundeeFundeeApp(),
    ),
  );
}
```

### GoRouter Configuration

```dart
// flutter_app/lib/router/router.dart
// Source: https://pub.dev/packages/go_router

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      // Check if onboarding complete, redirect to /dashboard
      // Driven by Riverpod provider watching Drift user table
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/programs', builder: (_, __) => const ProgramsScreen()),
      GoRoute(
        path: '/workout/:programId',
        builder: (_, state) => WorkoutScreen(
          programId: state.pathParameters['programId']!,
        ),
      ),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
    ],
  );
});
```

### Parity Gate Test Structure

```dart
// flutter_app/integration_test/all_tests.dart
// Aggregates all parity gates — run this file on each platform

import 'parity_gates/navigation_parity_test.dart' as navigation;
import 'parity_gates/onboarding_parity_test.dart' as onboarding;
import 'parity_gates/workout_parity_test.dart' as workout;
import 'parity_gates/offline_parity_test.dart' as offline;

void main() {
  navigation.main();    // PLAT-01: launch + navigate on web/Android/iOS
  onboarding.main();    // QUAL-01: onboarding flow parity
  workout.main();       // QUAL-01: workout flow parity
  offline.main();       // QUAL-02: offline scenarios parity
}
```

### Running All Parity Gates on Three Platforms

```bash
# All 3 platform parity gate runs — record pass/fail per platform

# Web
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/all_tests.dart \
  -d chrome \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>

# Android (use `flutter devices` to get device ID)
flutter test integration_test/all_tests.dart \
  -d <android_device_id> \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>

# iOS (use `flutter devices` to get simulator ID)
flutter test integration_test/all_tests.dart \
  -d <ios_simulator_id> \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```

### Drift Database (Cross-Platform)

```dart
// flutter_app/lib/data/database/app_database.dart
// Source: https://pub.dev/packages/drift_flutter

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get experienceLevel => text()();
  TextColumn get goal => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users])
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.defaults() : super(driftDatabase(name: 'sundee_fundee'));

  @override
  int get schemaVersion => 1;
}
```

---

## Critical Flows for Parity Gates

Based on the existing Playwright E2E tests, these are the flows that need cross-platform parity tests:

| Flow | Playwright Test File | Parity Gate Test |
|------|---------------------|-----------------|
| Onboarding (name → experience → goal → dashboard) | `onboarding.spec.ts` | `onboarding_parity_test.dart` |
| Full workout flow (program → session → log sets → complete) | `workout-flow.spec.ts` | `workout_parity_test.dart` |
| Navigation (launch → navigate programs, dashboard) | (multiple) | `navigation_parity_test.dart` |
| Offline: persist data without network | (no Playwright equivalent) | `offline_parity_test.dart` |
| Offline: reconnect and show sync indicator | (no Playwright equivalent) | `offline_parity_test.dart` |

The cycle logging and recommendation flows are present in the Next.js app but do NOT need parity gates in Phase 9 — those features aren't migrated yet. The offline parity gate covers the infrastructure-level guarantee (Drift works offline, connectivity detection works, UI shows offline status).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_driver` | `integration_test` (SDK) | Flutter 2.0 (2021) | flutter_driver is legacy; integration_test is the standard |
| `sqflite` for all platforms | `drift` for cross-platform | 2022+ for web targets | drift handles web natively; sqflite needs workarounds |
| HTML renderer (`--web-renderer html`) | CanvasKit (default) / skwasm (wasm mode) | Flutter 3.x removed HTML renderer | HTML renderer no longer available; CanvasKit is default |
| pub.dev `integration_test` package | `integration_test: sdk: flutter` | Flutter 2.0 | Package on pub.dev is discontinued and Dart 3 incompatible |
| `flutter_bloc` as default state mgmt | `flutter_riverpod` widely preferred | 2023+ | Riverpod's compile-time safety and DI ergonomics now preferred |

**Deprecated/outdated:**
- `flutter_driver`: Superseded by integration_test; don't use
- `integration_test` from pub.dev (1.0.2+3): Discontinued, Dart 3 incompatible
- HTML renderer for Flutter web: Removed in Flutter 3.x
- `hive` for complex relational data: Works but lacks SQL query power; drift preferred

---

## Flutter Web Important Notes

Flutter web is **production-ready for this use case** as of Flutter 3.x. Key facts:

1. **Default build mode** uses `canvaskit` renderer — compatible with all modern browsers
2. **WASM build mode** uses `skwasm` renderer — better performance, requires `--wasm` flag; needs SharedArrayBuffer security headers on the server
3. **For Phase 9**: Use default mode (canvaskit) for simplicity. WASM optimization is a later concern.
4. **drift on web** requires: `sqlite3.wasm` + `drift_worker.js` in `web/` directory — these must be downloaded manually
5. **Web integration tests** require ChromeDriver running separately on port 4444 and use `flutter drive`, not `flutter test`

---

## Open Questions

1. **Where does the Flutter app live in the repo?**
   - What we know: No Flutter project exists yet; Next.js app is at repo root
   - What's unclear: Convention preference — `flutter_app/` at root, or rename/restructure
   - Recommendation: Use `flutter_app/` as the Flutter project root, keeping Next.js at repo root until v2.0 is validated

2. **How to handle Supabase credentials in integration tests?**
   - What we know: `--dart-define` can pass env vars; integration tests should ideally not hit real Supabase
   - What's unclear: Whether Phase 9 tests need real Supabase or can stub it entirely
   - Recommendation: Phase 9 parity tests should use in-memory Drift only (no Supabase calls) — sync is tested in a later phase

3. **iOS physical device vs simulator for parity gates?**
   - What we know: iOS simulator works for `flutter test`; real device needs signing certs
   - What's unclear: Whether CI will use simulators or Firebase Test Lab
   - Recommendation: Use iOS simulator in Phase 9; defer Firebase Test Lab to CI pipeline setup phase

4. **patrol vs plain integration_test for offline parity?**
   - What we know: Patrol 4.1.1 supports native airplane mode; connectivity_plus mock is simpler
   - What's unclear: Whether native airplane mode simulation is required for QUAL-02
   - Recommendation: Use `ConnectivityPlatform.instance` mock injection for Phase 9. Patrol's native airplane mode is a future hardening step.

---

## Sources

### Primary (HIGH confidence)
- `https://docs.flutter.dev/testing/integration-tests` — Integration test setup, web browser, iOS, Android running instructions
- `https://docs.flutter.dev/platform-integration/web/renderers` — CanvasKit vs skwasm; build modes
- `https://pub.dev/packages/drift` (pub.dev API) — drift 2.31.0, platforms, features
- `https://pub.dev/packages/drift_flutter` (pub.dev API) — drift_flutter 0.2.8, web wasm requirements
- `https://pub.dev/packages/integration_test` (pub.dev API) — Confirmed deprecated; use SDK version
- `https://pub.dev/packages/patrol` (pub.dev API) — patrol 4.1.1, cross-platform features
- Flutter release metadata API — Flutter 3.41.2, Dart 3.7.0 confirmed as latest stable 2026-02-20

### Secondary (MEDIUM confidence)
- pub.dev API responses for all package versions (connectivity_plus 7.0.0, flutter_riverpod 3.2.1, go_router 17.1.0, supabase_flutter 2.12.0, mocktail 1.0.4) — versions verified via direct API calls
- Existing Playwright E2E tests in `tests/e2e/` — confirmed critical flows: onboarding, workout, recommendations, cycle logging

### Tertiary (LOW confidence)
- Architecture pattern for `flutter_app/` directory location — common community convention, not officially prescribed
- `ConnectivityPlatform.instance` swap for offline test injection — pattern based on connectivity_plus_platform_interface design; not explicitly documented in official Flutter testing docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All package versions verified via pub.dev API; Flutter version from official release metadata
- Architecture: HIGH — integration_test and drift patterns from official docs; project structure is conventional Flutter layout
- Pitfalls: HIGH — wasm requirement verified from drift_flutter README; ChromeDriver requirement from official Flutter integration test docs; deprecated packages confirmed
- Offline test pattern: MEDIUM — ConnectivityPlatform.instance injection is correct pattern but not explicitly in official docs

**Research date:** 2026-02-20
**Valid until:** 2026-03-20 (30 days — Flutter stable releases every ~3 months; packages update frequently but stack choices are stable)
