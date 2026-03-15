---
phase: 04-core-workout-loop
plan: "01"
subsystem: domain
tags: [exercises, timers, workout-session, pr-detection, domain-types, tdd]
dependency_graph:
  requires: []
  provides:
    - Exercise, MuscleGroup, EquipmentType types
    - MUSCLE_GROUPS constant
    - filterExercises pure function
    - 202-exercise bundled catalog (exercises.json)
    - TimerState, TimerMode types
    - createTimerState, getElapsedMs, getRemainingMs, pauseTimer, resumeTimer, isTimerComplete, getEMOMCurrentMinute
    - WorkoutSession, ActiveExercise, LoggedSet types
    - ExerciseMax, PRCheckResult, TrackedRepRange, TRACKED_REP_RANGES
  affects:
    - All Phase 4 plans (04-02 through 04-08 depend on these types)
tech_stack:
  added:
    - expo-notifications (~55.x)
    - expo-haptics (~55.x)
    - expo-av (~55.x)
    - expo-linear-gradient (~55.x)
    - react-native-gifted-charts
    - react-native-draggable-flatlist
    - react-native-reanimated (~3.x via Expo SDK 55)
    - react-native-gesture-handler (~2.x via Expo SDK 55)
  patterns:
    - TDD red-green cycle for all domain functions
    - Pure functions with optional 'now' parameter for deterministic testing
    - Immutable state via object spread (no mutation)
    - Barrel index.ts re-exports per domain subdirectory
    - istanbul ignore file on barrel re-exports
key_files:
  created:
    - SundeeFundeeRN/src/domain/exercises/exercise-types.ts
    - SundeeFundeeRN/src/domain/exercises/exercise-filter.ts
    - SundeeFundeeRN/src/domain/exercises/index.ts
    - SundeeFundeeRN/src/resources/exercises.json
    - SundeeFundeeRN/src/domain/timers/timer-state.ts
    - SundeeFundeeRN/src/domain/timers/index.ts
    - SundeeFundeeRN/src/domain/__tests__/exercises.test.ts
    - SundeeFundeeRN/src/domain/__tests__/timers.test.ts
  modified:
    - SundeeFundeeRN/package.json (8 new dependencies)
    - SundeeFundeeRN/src/domain/workout-session/index.ts (fixed missing action exports)
decisions:
  - "exercises.json bundled as static JSON (202 entries) — no network dependency for exercise catalog"
  - "Timer functions accept optional 'now' parameter — enables deterministic unit tests without mocking Date.now"
  - "TimerState is immutable — all mutations return new objects via spread"
  - "forTime mode uses durationMs=0 sentinel — isTimerComplete always false for stopwatch mode"
  - "TRACKED_REP_RANGES = [1, 3, 5, 8, 10] as const — typed tuple for PRCheckResult.repRange narrowing"
metrics:
  duration_minutes: 5
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_created: 8
  files_modified: 2
---

# Phase 4 Plan 01: Domain Types, Exercise Catalog, and Timer Functions Summary

**One-liner:** Timestamp-based timer domain (pause/resume/EMOM math) + 202-exercise JSON catalog + pure filterExercises function + type contracts for WorkoutSession, ActiveExercise, and PR detection.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Install deps, exercise catalog and filterExercises | 2ffea8d | exercise-types.ts, exercise-filter.ts, exercises.json |
| 1 (TDD RED) | Failing tests for exercises | 24ec711 | exercises.test.ts |
| 2 | Timer state domain + session/PR types | 7de0318 | timer-state.ts, pr-types.ts, session-types.ts |
| 2 (TDD RED) | Failing tests for timers | deb0d57 | timers.test.ts |

## Verification Results

All new domain tests pass:
- exercises.test.ts: 16 tests passed
- timers.test.ts: 25 tests passed
- Full test suite: 830 tests passed across 31 suites (zero failures)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] workout-session/index.ts missing action function exports**

- **Found during:** Task 2 full suite verification
- **Issue:** Prior 04-02 plan committed session-actions.ts but index.ts had only type re-exports — workout-session tests importing createSession, addExercise, etc. from the barrel were failing with "is not a function"
- **Fix:** Updated workout-session/index.ts to re-export all action functions from session-actions.ts
- **Files modified:** SundeeFundeeRN/src/domain/workout-session/index.ts
- **Commit:** 7de0318 (included in Task 2 commit)

## Dependencies Installed

| Package | Version | Purpose |
|---------|---------|---------|
| expo-notifications | ~55.x | Rest timer and EMOM interval push notifications |
| expo-haptics | ~55.x | Haptic feedback on set completion and PR |
| expo-av | ~55.x | Timer beep sounds (3-2-1-Go countdown) |
| expo-linear-gradient | ~55.x | Art Deco gradient UI components |
| react-native-gifted-charts | latest | Progress and 1RM line charts |
| react-native-draggable-flatlist | latest | Exercise drag-and-drop reordering |
| react-native-reanimated | ~3.x | Animation base for Expo SDK 55 |
| react-native-gesture-handler | ~2.x | Gesture base for Expo SDK 55 |

## Type Contracts Exported

### Exercise Domain
- `MuscleGroup` — 'Chest' | 'Back' | 'Legs' | 'Shoulders' | 'Arms' | 'Core' | 'Full Body'
- `MUSCLE_GROUPS` — const array of all 7 values
- `EquipmentType` — 7 equipment categories
- `Exercise` — { id, name, muscleGroup, isCustom, equipmentType? }
- `filterExercises(exercises, query, muscleGroup?)` — pure search/filter function

### Timer Domain
- `TimerMode` — 'rest' | 'forTime' | 'amrap' | 'emom'
- `TimerState` — { startedAt, pausedAt, totalPausedMs, durationMs, mode, intervalMs? }
- All 7 timer functions exported with optional `now` param for deterministic testing

### Workout Session
- `LoggedSet`, `ActiveExercise`, `WorkoutSession` — active session type contracts
- Session action functions: createSession, addExercise, removeExercise, addSet, removeSet, completeSet, reorderExercises

### PR Detection
- `TRACKED_REP_RANGES` = [1, 3, 5, 8, 10] as const
- `TrackedRepRange`, `ExerciseMax`, `PRCheckResult`

## Self-Check: PASSED
