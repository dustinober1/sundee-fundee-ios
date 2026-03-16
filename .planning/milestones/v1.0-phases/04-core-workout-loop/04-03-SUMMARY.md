---
phase: 04-core-workout-loop
plan: "03"
subsystem: repositories
tags: [exercise-repo, exercise-max-repo, workout-record, async-storage, firestore, tdd]
dependency_graph:
  requires:
    - 04-01  # domain types: Exercise, ExerciseMax, TrackedRepRange
    - 04-02  # existing repository factory pattern
  provides:
    - ExerciseRepository interface + Local/Firestore implementations
    - ExerciseMaxRepository interface + Local/Firestore implementations
    - Expanded WorkoutRecord with CompletedExercise/CompletedSet
  affects:
    - 04-04  # Workout UI will use ExerciseRepo and ExerciseMaxRepo
    - 04-05  # PR detection will write maxes via ExerciseMaxRepo
tech_stack:
  added: []
  patterns:
    - Repository factory pattern (isGuest flag → Local vs Firestore)
    - TDD Red/Green with AsyncStorage mock
    - Upsert-only-if-better pattern (ExerciseMaxRepo.saveMax)
key_files:
  created:
    - SundeeFundeeRN/src/repositories/ExerciseRepo.ts
    - SundeeFundeeRN/src/repositories/LocalExerciseRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreExerciseRepo.ts
    - SundeeFundeeRN/src/repositories/ExerciseMaxRepo.ts
    - SundeeFundeeRN/src/repositories/LocalExerciseMaxRepo.ts
    - SundeeFundeeRN/src/repositories/FirestoreExerciseMaxRepo.ts
    - SundeeFundeeRN/src/repositories/__tests__/ExerciseRepo.test.ts
    - SundeeFundeeRN/src/repositories/__tests__/ExerciseMaxRepo.test.ts
  modified:
    - SundeeFundeeRN/src/repositories/WorkoutRepo.ts
    - SundeeFundeeRN/src/repositories/index.ts
decisions:
  - "ExerciseMaxRepo.saveMax skips write when new weight is not strictly higher — avoids regressing PR records on bad data entry"
  - "FirestoreExerciseMaxRepo uses compositeId (exerciseId_repRange) as doc ID — ensures one document per max slot, efficient upserts"
  - "WorkoutRecord.workout made optional for backward compatibility — existing AI records unchanged, custom records use exercises field"
metrics:
  duration: 3 min
  completed_date: "2026-03-14"
  tasks_completed: 2
  files_created: 8
  files_modified: 2
---

# Phase 04 Plan 03: Exercise and ExerciseMax Repositories Summary

**One-liner:** ExerciseRepository (CRUD) and ExerciseMaxRepository (PR tracking with upsert-only-if-better) with Local/Firestore dual implementations, plus backward-compatible WorkoutRecord expansion for custom workout data.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create ExerciseRepo and ExerciseMaxRepo with dual implementations | f92a82a | 9 files |
| 2 | Expand WorkoutRecord to support custom workout data | a6dd1f3 | 2 files |

## What Was Built

**ExerciseRepository** (`ExerciseRepo.ts`): Interface for custom exercise CRUD with three methods — `getCustomExercises`, `saveCustomExercise`, `deleteCustomExercise`. LocalExerciseRepo uses `@sundee/custom-exercises` AsyncStorage key. FirestoreExerciseRepo writes to `/users/{uid}/customExercises/{exerciseId}`.

**ExerciseMaxRepository** (`ExerciseMaxRepo.ts`): Interface for PR max tracking with five methods. Key behavior: `saveMax` upserts — only replaces when new weight is strictly higher, otherwise skips the write. `getMax1RMHistory` returns time-ordered `{ date, estimated1RM }` pairs suitable for chart data. LocalExerciseMaxRepo uses `@sundee/exercise-maxes` key. FirestoreExerciseMaxRepo uses composite doc ID `{exerciseId}_{repRange}` for O(1) upserts.

**WorkoutRecord expansion**: `workout` field made optional (AI records keep it; custom/program records use `exercises` instead). Added `CompletedExercise` and `CompletedSet` types plus `workoutName`, `timerMode`, `totalVolume`, `exerciseCount` optional fields. All 85 existing WorkoutRepo tests continue to pass.

## Test Results

- 26 new tests (ExerciseRepo.test.ts + ExerciseMaxRepo.test.ts) — all pass
- 85 existing repository tests — all pass
- Full suite: 889 tests pass across 35 test suites

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

Files exist:
- SundeeFundeeRN/src/repositories/ExerciseRepo.ts ✓
- SundeeFundeeRN/src/repositories/LocalExerciseRepo.ts ✓
- SundeeFundeeRN/src/repositories/FirestoreExerciseRepo.ts ✓
- SundeeFundeeRN/src/repositories/ExerciseMaxRepo.ts ✓
- SundeeFundeeRN/src/repositories/LocalExerciseMaxRepo.ts ✓
- SundeeFundeeRN/src/repositories/FirestoreExerciseMaxRepo.ts ✓

Commits exist:
- f92a82a ✓
- a6dd1f3 ✓
