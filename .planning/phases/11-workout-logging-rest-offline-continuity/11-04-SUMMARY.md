---
phase: 11
plan: "04"
name: "Parity Gate Tests for Workout Logging, Rest Timer, Offline Continuity"
subsystem: integration-tests
one-liner: "Parity gate tests for WORK-01/02/03 via Key selectors, Drift DB queries, and FakeConnectivity"
tags: [integration-test, parity-gate, drift, offline, rest-timer, workout-logging]

dependency-graph:
  requires:
    - "11-01"  # WorkoutScreen + ExerciseAccordion + set logging
    - "11-02"  # CompletedWorkouts/CompletedSets Drift tables + persistence
    - "11-03"  # RestTimerProvider + RestTimerSheet integration
  provides:
    - "WORK-01 integration test coverage (set logging + Drift persistence)"
    - "WORK-02 integration test coverage (rest timer appears, pause/resume/skip)"
    - "WORK-03 integration test coverage (offline workout completion + local persistence)"
    - "Start Workout navigation button in DashboardScreen active cycle card"
    - "Shared workout test helpers in app_helper.dart"
  affects:
    - "12+"  # All future parity gates can reuse workout helpers

tech-stack:
  added: []
  patterns:
    - "pumpApp + completeOnboarding + startCycleFromPrograms + navigateToWorkoutFromDashboard helper chain"
    - "ProviderScope.containerOf + container.read(databaseProvider) for Drift assertion in integration tests"
    - "FakeConnectivityPlatform.goOffline before pumpApp for deterministic offline gate"

file-tracking:
  key-files:
    created: []
    modified:
      - flutter_app/lib/features/dashboard/dashboard_screen.dart
      - flutter_app/integration_test/helpers/app_helper.dart
      - flutter_app/integration_test/parity_gates/workout_parity_test.dart
      - flutter_app/integration_test/parity_gates/offline_parity_test.dart

decisions:
  - id: "D-11-04-1"
    decision: "Add Start Workout button to DashboardScreen (not ProgramsScreen or WorkoutScreen)"
    rationale: "Dashboard is the natural post-cycle-start landing point; button is only visible with active cycle"
    impact: "Closes navigation gap between cycle-start and workout entry for all integration tests"
  - id: "D-11-04-2"
    decision: "startCycleFromPrograms uses runtime guard (if startButton.evaluate().isNotEmpty) before tapping"
    rationale: "Handles case where a cycle was already started (e.g. test re-run without DB teardown)"
    impact: "Tests are idempotent across re-runs"

metrics:
  duration: "1 minute"
  completed: "2026-02-21"
  tasks-completed: 4
  tasks-total: 4
---

# Phase 11 Plan 04: Parity Gate Tests for Workout Logging, Rest Timer, Offline Continuity Summary

## What Was Built

Parity gate integration tests covering all three Phase 11 requirements (WORK-01, WORK-02, WORK-03), plus a "Start Workout" button added to `DashboardScreen` to close the navigation gap that previously prevented tests from reaching the workout screen.

## Tasks Completed

| # | Name | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Add Start Workout button to DashboardScreen | 9e85c31 | `dashboard_screen.dart` |
| 2 | Add workout helpers to app_helper.dart | 58c0f54 | `integration_test/helpers/app_helper.dart` |
| 3 | Update workout_parity_test.dart (WORK-01, WORK-02) | 897dcbf | `integration_test/parity_gates/workout_parity_test.dart` |
| 4 | Add WORK-03 offline workout test | c9a4536 | `integration_test/parity_gates/offline_parity_test.dart` |

## Decisions Made

1. **Start Workout button on Dashboard** — The only place that makes sense as a "start workout from active cycle" entry point. Keyed `start-workout-button`, only rendered inside the `activeCycle != null` branch of `activeCycleAsync.when`. Navigates via `context.go('/workout/${activeCycle.programId}')`.

2. **Helper guard on startCycleButton** — `startCycleFromPrograms` uses `if (startButton.evaluate().isNotEmpty)` to tolerate test re-runs where a cycle may already be active. Prevents duplicate-start error from leaking into test assertions.

## Test Coverage Summary

### workout_parity_test.dart — 5 tests

| Test | Requirement |
|------|-------------|
| navigates to workout screen via programs and dashboard | Navigation smoke test |
| logs sets and completes workout with Drift persistence | **WORK-01** |
| rest timer appears after logging a set | **WORK-02** |
| shows discard confirmation when leaving workout with logged sets | WORK-01 guard |
| completes workout and returns to dashboard | Navigation smoke test |

### offline_parity_test.dart — 4 tests (3 pre-existing + 1 new)

| Test | Requirement |
|------|-------------|
| shows offline banner when connectivity is lost | QUAL-02 (pre-existing) |
| hides offline banner when connectivity returns | QUAL-02 (pre-existing) |
| app functions offline — Drift persists locally | QUAL-02 (pre-existing) |
| **completes workout offline — persists to local Drift** | **WORK-03** |

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- All Phase 11 requirements (WORK-01, WORK-02, WORK-03) have parity gate test coverage
- Phase 12 can proceed
- No blockers or concerns
