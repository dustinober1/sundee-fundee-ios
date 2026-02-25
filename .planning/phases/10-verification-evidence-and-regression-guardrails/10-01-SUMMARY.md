# 10-01 Summary - Emulator-backed critical-flow regression guardrails

## Outcome
Implemented the Phase 10 wave-1 test foundation for QA-01:
- Added deterministic Firebase emulator harness utilities for integration verification account setup.
- Added `critical_access_flow_test.dart` checkpoints covering unauth guard behavior and `login -> dashboard -> programs -> workout start` navigation flow assertions.
- Extended onboarding and workout resilience regression tests to lock no-false-prompt and `permission-denied` sync queue behavior.
- Added a dedicated CI `quality-integration` lane in `.github/workflows/flutter-release.yml` and made release builds depend on it.

## Task Commits
- Task 1 (harness + deps): `0e2b198`
- Task 2 (integration + regressions): `cfa6bec`
- Task 3 (CI lane): `71e72d1`

## Verification
Commands executed:

1. `cd flutter_app && flutter pub get`
- Result: passed

2. `cd flutter_app && flutter test test/features/auth/data/auth_repository_onboarding_bootstrap_test.dart test/features/workouts/presentation/workout_write_resilience_test.dart -r compact`
- Result: passed (11 tests)

3. `cd flutter_app && flutter analyze integration_test/critical_access_flow_test.dart integration_test/support/firebase_emulator_test_harness.dart`
- Result: passed

4. `cd flutter_app && flutter test integration_test/critical_access_flow_test.dart --dart-define=ENABLE_FIREBASE=true --dart-define=USE_FIREBASE_EMULATORS=true -r compact`
- Result: blocked in this local workspace (`Web devices are not supported for integration tests yet.` and no desktop platform project configured). CI lane is configured to run this via Firebase emulators in GitHub Actions.

5. `rg -n "emulators:exec|integration_test/critical_access_flow_test.dart|quality-integration|upload-artifact" .github/workflows/flutter-release.yml`
- Result: passed

## Notes
- `quality-integration` job now runs:
  - `firebase emulators:exec --only auth,firestore`
  - `flutter test integration_test/critical_access_flow_test.dart --dart-define=ENABLE_FIREBASE=true --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=SEED_VERIFICATION_ACCOUNT=true`
- Build jobs (`build-web`, `build-android`, `build-ios`) now require both `quality` and `quality-integration`.
