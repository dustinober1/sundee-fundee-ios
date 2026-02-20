---
phase: 09-cross-platform-foundation-parity-gates
plan: "03"
subsystem: flutter-integration-testing
tags: [flutter, integration-test, parity-gates, connectivity, drift, chromedriver, android, ios]

dependency-graph:
  requires: ["09-01", "09-02"]
  provides:
    - "Cross-platform parity gate test suite: navigation, onboarding, workout flow, offline scenarios"
    - "FakeConnectivityPlatform for deterministic offline simulation in integration tests"
    - "pumpApp() + completeOnboarding() shared test helpers for consistent bootstrap"
    - "all_tests.dart aggregator running PLAT-01 + QUAL-01 + QUAL-02 gates in one invocation"
    - "flutter drive web entrypoint (test_driver/integration_test.dart)"
    - "Verified pass on web (Chrome), Android, and iOS — 11 test cases, 4 parity gate files"
  affects: ["10-xx", "11-xx", "12-xx", "13-xx", "14-xx"]

tech-stack:
  added:
    - "connectivity_plus_platform_interface (dev dep) — platform interface access for FakeConnectivityPlatform"
    - "plugin_platform_interface (dev dep) — MockPlatformInterfaceMixin for platform token check"
  patterns:
    - "IntegrationTestWidgetsFlutterBinding.ensureInitialized() as test entrypoint contract"
    - "FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin"
    - "ConnectivityPlatform.instance injection via setUp/tearDown for deterministic offline tests"
    - "pumpApp() + ProviderScope(overrides) for injectable test bootstrap"
    - "Platform-agnostic Key-only selectors (no CupertinoButton, no MaterialButton finders)"
    - "all_tests.dart aggregator pattern — single target for flutter drive cross-platform run"

key-files:
  created:
    - flutter_app/test_driver/integration_test.dart
    - flutter_app/integration_test/helpers/app_helper.dart
    - flutter_app/integration_test/helpers/fake_connectivity.dart
    - flutter_app/integration_test/parity_gates/navigation_parity_test.dart
    - flutter_app/integration_test/parity_gates/onboarding_parity_test.dart
    - flutter_app/integration_test/parity_gates/workout_parity_test.dart
    - flutter_app/integration_test/parity_gates/offline_parity_test.dart
    - flutter_app/integration_test/all_tests.dart
  modified:
    - flutter_app/pubspec.yaml (added connectivity_plus_platform_interface + plugin_platform_interface as dev deps)
    - flutter_app/pubspec.lock (updated after pub get)

decisions:
  - id: "fake-connectivity-platform-interface"
    choice: "FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin"
    rationale: "ConnectivityPlatform uses a token-based platform interface check. Without MockPlatformInterfaceMixin, assigning a custom instance to ConnectivityPlatform.instance throws at runtime. Mixin satisfies the token check and allows deterministic offline/online state injection without actual network calls."
    alternatives: ["Wrap connectivity_plus in an app-level service interface and mock the service instead"]
  - id: "aggregator-pattern"
    choice: "all_tests.dart calls each gate's main() function directly"
    rationale: "Flutter integration_test requires a single --target entry point for flutter drive. The aggregator pattern (import as alias, call alias.main()) satisfies this requirement while keeping each gate independently runnable as its own target."
    alternatives: ["Separate flutter drive invocations per gate file (more CI steps)"]

metrics:
  duration: "~10 minutes (including checkpoint verification on web + android + ios)"
  completed: "2026-02-20"
---

# Phase 09 Plan 03: Cross-Platform Parity Gate Tests Summary

**One-liner:** 4 parity gate integration test files (PLAT-01, QUAL-01 x2, QUAL-02) with FakeConnectivity + shared helpers, verified passing on web, Android, and iOS — 11 test cases using platform-agnostic Key selectors.

## What Was Built

Complete `integration_test/` directory establishing the cross-platform quality contract for Phase 10+ feature migration:

### Test Infrastructure

1. **`test_driver/integration_test.dart`** — Required web flutter drive entrypoint (`integrationDriver()`). Three lines; required by the `flutter drive --driver=` flag for Chrome/web runs.

2. **`integration_test/helpers/app_helper.dart`** — Shared test bootstrap:
   - `pumpApp(WidgetTester tester, {List<Override>? providerOverrides})` — wraps the full app in `ProviderScope` with injectable overrides, calls `pumpAndSettle()`. Every test starts identically.
   - `completeOnboarding(WidgetTester tester)` — drives the full 3-step onboarding flow (name → experience → goal → start) using Key selectors. Reused by navigation, workout, and offline gates to skip onboarding setup without duplication.

3. **`integration_test/helpers/fake_connectivity.dart`** — `FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin`:
   - `goOffline()` / `goOnline()` push new `List<ConnectivityResult>` to a broadcast `StreamController`
   - `checkConnectivity()` returns current status synchronously
   - Injected via `ConnectivityPlatform.instance = fakeConnectivity` in test `setUp`
   - Makes offline tests deterministic — zero dependency on actual network state

### Parity Gate Tests

4. **`parity_gates/navigation_parity_test.dart`** — **PLAT-01** (3 tests):
   - App launches → shows `Key('onboarding-screen')`
   - Completes onboarding inline → arrives at `Key('dashboard-screen')`
   - Taps `Key('nav-programs')` → navigates to `Key('programs-screen')`

5. **`parity_gates/onboarding_parity_test.dart`** — **QUAL-01 onboarding** (3 tests):
   - Full flow: name → experience → goal → dashboard (verifies "Welcome to Sundee Fundee")
   - Back button at step 2 → returns to step 1 (verifies "Enter your name")
   - Name field required: empty tap does not advance (stays on step 0)

6. **`parity_gates/workout_parity_test.dart`** — **QUAL-01 workout flow** (2 tests):
   - Onboarding → programs → `Key('program-back-squat-complete-cycle')` → `Key('workout-screen')`
   - Taps `Key('complete-workout-button')` → returns to `Key('dashboard-screen')`

7. **`parity_gates/offline_parity_test.dart`** — **QUAL-02 offline scenarios** (3 tests):
   - `goOffline()` before pump → `Key('offline-banner')` visible with "You are offline" text
   - `goOffline()` then `goOnline()` → banner disappears
   - Complete onboarding while offline → arrives at dashboard (local-first Drift behavior verified)

8. **`integration_test/all_tests.dart`** — Aggregator: imports all 4 gate files as named prefixes, calls each `main()`. Single target for `flutter drive --target=integration_test/all_tests.dart -d chrome`.

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze integration_test/ test_driver/` | ✅ No issues found |
| 4 parity gate files present | ✅ navigation, onboarding, workout, offline |
| `grep "PARITY GATE"` across all gate files | ✅ All 4 groups named |
| `grep "FakeConnectivityPlatform"` | ✅ Class present in fake_connectivity.dart |
| `grep "ConnectivityPlatform.instance"` | ✅ Injection present in offline_parity_test.dart |
| `all_tests.dart` calls all 4 `main()` functions | ✅ Confirmed |
| Web (Chrome) — flutter drive | ✅ All 11 tests pass |
| Android — flutter test -d android | ✅ All 11 tests pass |
| iOS — flutter test -d ios | ✅ All 11 tests pass |

**Human verification:** "approved — web + android + ios"

## Deviations from Plan

None — plan executed exactly as written.

Both tasks compiled without errors on the first analyze run. `connectivity_plus_platform_interface` and `plugin_platform_interface` were already available as transitive dependencies; the plan's conditional addition was confirmed and deps added to pubspec.yaml dev_dependencies for explicit version pinning.

## Requirements Coverage

| Requirement | Gate | Tests |
|-------------|------|-------|
| PLAT-01: App launches and screens reachable on any platform | navigation_parity_test.dart | 3 |
| QUAL-01: Onboarding multi-step flow parity | onboarding_parity_test.dart | 3 |
| QUAL-01: Workout navigate + complete flow parity | workout_parity_test.dart | 2 |
| QUAL-02: Offline banner + local-first Drift parity | offline_parity_test.dart | 3 |
| **Total** | | **11 tests** |

## Next Phase Readiness

**Phase 10+ (feature migration)** is unblocked:
- Quality contract established: all parity gates must stay green as features are migrated
- `all_tests.dart` is the single regression gate — run on every PR against each platform
- `FakeConnectivityPlatform` is reusable for any future offline-scenario test
- `completeOnboarding()` helper accelerates any test that needs to start from dashboard state
- Platform-agnostic Key selectors mean zero test rewrites when migrating between web/Android/iOS
