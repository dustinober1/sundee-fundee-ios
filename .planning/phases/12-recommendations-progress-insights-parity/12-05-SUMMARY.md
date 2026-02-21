---
phase: 12
plan: 05
subsystem: integration-testing
tags: [flutter, integration-test, parity-gate, drift, riverpod, connectivity]

dependency-graph:
  requires:
    - "12-01: progress screen UI (progress-screen, one-rm-chart, weekly-volume-chart, workout-heatmap keys)"
    - "12-02: calculations.dart and plateau_detection.dart (RECO-01, RECO-02 logic)"
    - "12-03: chart widget Keys on outer always-rendered containers"
    - "12-04: WorkoutRepository PR methods (checkAndSaveWeightPR, saveOneRepMax, historicalMax guard)"
  provides:
    - "recommendations_parity_test.dart: CHRT-01, CHRT-02, RECO-01, RECO-02 parity gate tests"
    - "test_database.dart: reusable in-memory Drift DB helper for integration tests"
    - "all_tests.dart: updated aggregator including recommendations tests"
  affects:
    - "Phase 13+: all future integration test phases can reuse test_database.dart helper"

tech-stack:
  added: []
  patterns:
    - "test_database.dart helper: createTestDatabase() returns NativeDatabase.memory() with FK enabled"
    - "Integration tests use setUp/tearDown for FakeConnectivityPlatform lifecycle"
    - "CHRT-01 uses pumpApp + completeOnboarding helpers (no DB injection needed)"
    - "CHRT-02 uses ProviderScope overrides (databaseProvider + onboardingCompleteProvider)"
    - "RECO-01: pure unit tests (no widget/DB needed) inline in integration_test runner"
    - "RECO-02: Drift integration tests via createTestDatabase() with seeded data"

key-files:
  created:
    - flutter_app/integration_test/helpers/test_database.dart
    - flutter_app/integration_test/parity_gates/recommendations_parity_test.dart
  modified:
    - flutter_app/integration_test/all_tests.dart

decisions:
  - id: D1
    choice: "test_database.dart lives in helpers/ (not parity_gates/)"
    rationale: "Reusable across all parity gate test files; follows existing helpers/ pattern"
  - id: D2
    choice: "CHRT-01 uses pumpApp helper without DB injection"
    rationale: "Progress screen renders chart containers even with no data (Keys on outer always-rendered widgets per 12-03); no seeding required"
  - id: D3
    choice: "CHRT-02 uses ProviderScope.overrideWithValue(db) pattern"
    rationale: "Needs pre-seeded offline data; consistent with STATE.md Riverpod 3.x override pattern"
  - id: D4
    choice: "RECO-01 pure unit tests run inside integration_test runner (no tester arg)"
    rationale: "Calculations are pure Dart; no widget pump needed; integration_test runner supports plain test() alongside testWidgets()"

metrics:
  duration: "~2 minutes"
  completed: "2026-02-21"

commits:
  - hash: 3564d17
    message: "chore(12-05): add test_database.dart helper for integration tests"
  - hash: 415e654
    message: "test(12-05): add recommendations_parity_test.dart covering CHRT-01, CHRT-02, RECO-01, RECO-02"
  - hash: d2ff930
    message: "chore(12-05): add recommendations tests to all_tests.dart aggregator"
---

# Phase 12 Plan 05: Recommendations + Progress Parity Gate Tests Summary

**One-liner:** Parity gate integration tests for RECO-01, RECO-02, CHRT-01, CHRT-02 using Drift in-memory DB, FakeConnectivityPlatform, and WorkoutRepository PR methods.

## What Was Built

Three files created/updated to complete the Phase 12 parity gate test suite:

1. **`flutter_app/integration_test/helpers/test_database.dart`** — `createTestDatabase()` helper that returns an in-memory `AppDatabase` with `PRAGMA foreign_keys = ON` enabled. Reusable across all integration test files.

2. **`flutter_app/integration_test/parity_gates/recommendations_parity_test.dart`** — Full parity gate coverage for all 4 requirements:
   - **CHRT-01:** `testWidgets` pumps app via `pumpApp` + `completeOnboarding`, navigates to `nav-progress`, asserts `progress-screen`, `one-rm-chart`, `weekly-volume-chart`, `workout-heatmap` keys all render
   - **CHRT-02:** Seeds in-memory Drift DB, calls `goOffline()`, overrides `databaseProvider` + `onboardingCompleteProvider`, asserts progress screen and chart render offline
   - **RECO-01:** 6 pure unit tests for `getNextRecommendedWeight`, `epley` (cap at 10), `roundToNearestFive`, `wasSetSuccessful`
   - **RECO-02:** `detectPlateau` weight variance test; `detectPlateauForExercise` with 3-session rep failure seeding; `checkAndSaveWeightPR` false-on-first-lift guard; `checkAndSaveWeightPR` true-on-session-2 when 140 > 135

3. **`flutter_app/integration_test/all_tests.dart`** — Added `recommendations.main()` to aggregator with comment documenting RECO-01, RECO-02, CHRT-01, CHRT-02 coverage.

## Verification Evidence

```
flutter analyze --no-fatal-infos → "No issues found! (ran in 2.6s)"

ls flutter_app/integration_test/helpers/test_database.dart → EXISTS

grep -c "group\|testWidgets\|test(" recommendations_parity_test.dart → 17

grep "recommendations" all_tests.dart →
  import 'parity_gates/recommendations_parity_test.dart' as recommendations;
  recommendations.main(); // RECO-01, RECO-02, CHRT-01, CHRT-02
```

## Commits

| Hash | Type | Description |
|------|------|-------------|
| `3564d17` | `chore` | add test_database.dart helper for integration tests |
| `415e654` | `test` | add recommendations_parity_test.dart covering CHRT-01, CHRT-02, RECO-01, RECO-02 |
| `d2ff930` | `chore` | add recommendations tests to all_tests.dart aggregator |

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | `test_database.dart` in `helpers/` (not `parity_gates/`) | Reusable across all gate files; matches helpers/ pattern |
| D2 | CHRT-01 uses `pumpApp` without DB injection | Chart container keys render even with no data (12-03 outer-widget pattern) |
| D3 | CHRT-02 uses `ProviderScope.overrideWithValue(db)` | Needs seeded offline data; consistent with Riverpod 3.x STATE.md pattern |
| D4 | RECO-01 pure `test()` inside integration_test runner | Calculations are pure Dart; no widget pump needed |

## Deviations from Plan

None — plan executed exactly as written.

## Success Criteria Review

- [x] test_database.dart helper exists with `createTestDatabase()` function
- [x] recommendations_parity_test.dart covers CHRT-01, CHRT-02, RECO-01, RECO-02
- [x] CHRT-01: Uses `pumpApp` + `completeOnboarding` + `nav-progress` Key
- [x] CHRT-02: Uses `FakeConnectivityPlatform().goOffline()` pattern with `setUp`/`tearDown`
- [x] All navigation uses `find.byKey(const Key('nav-progress'))`
- [x] Import uses `'../helpers/fake_connectivity.dart'` (not fake_connectivity_platform.dart)
- [x] RECO-01: Unit tests for calculations.dart functions
- [x] RECO-02: Integration tests for plateau detection with Drift
- [x] RECO-02: Weight PR test verifies first-lift guard (returns false when historicalMax = 0)
- [x] RECO-02: Weight PR test verifies PR fires on session 2 when 140 > 135
- [x] all_tests.dart includes `recommendations.main()`
- [x] No analysis errors in test files

## Next Phase Readiness

Phase 12 is **complete**. All 5 plans delivered:

| Plan | What | Status |
|------|------|--------|
| 12-01 | Calculations + plateau detection (pure Dart) | ✅ |
| 12-02 | WorkoutSessionNotifier coaching hooks + coachingProvider | ✅ |
| 12-03 | Progress screen + 3 chart widgets (1RM, volume, heatmap) | ✅ |
| 12-04 | WorkoutRepository PR/1RM methods + completeWorkout() RECO-02 ordering | ✅ |
| 12-05 | Parity gate tests (CHRT-01, CHRT-02, RECO-01, RECO-02) | ✅ |

Ready to proceed to **Phase 13**.
