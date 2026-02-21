---
phase: 11
plan: "01"
subsystem: data-layer
tags: [drift, sqlite, workout-logging, repository-pattern, riverpod]

dependency-graph:
  requires:
    - "10-03: Drift schema v2 with Users and ActiveCycles tables"
    - "10-02: CycleRepository constructor injection pattern"
    - "10-01: Riverpod databaseProvider"
  provides:
    - "Drift schema v3 with CompletedWorkouts, CompletedSets, OneRepMaxes, PersonalRecords tables"
    - "SetData ephemeral model for in-session set collection"
    - "WorkoutRepository with transactional saveWorkout()"
    - "workoutRepositoryProvider Riverpod provider"
  affects:
    - "11-02: WorkoutSessionProvider consumes workoutRepositoryProvider to persist sessions"
    - "11-03: Rest timer provider integrates with vibration package added here"
    - "12+: History and analytics queries build on CompletedWorkouts/CompletedSets"

tech-stack:
  added:
    - "vibration: ^2.0.0 — rest timer haptic feedback (consumed in Plan 03)"
  patterns:
    - "Constructor injection: WorkoutRepository(AppDatabase) mirrors CycleRepository"
    - "Drift transaction: _db.transaction(() async {...}) for atomic workout+sets insert"
    - "Value() wrapper: nullable Companion fields follow existing convention"
    - "PRAGMA foreign_keys = ON: required in NativeDatabase.memory() for cascade test coverage"

file-tracking:
  created:
    - flutter_app/lib/data/models/set_data.dart
    - flutter_app/lib/data/repositories/workout_repository.dart
    - flutter_app/lib/shared/providers/workout_repository_provider.dart
    - flutter_app/test/unit/repositories/workout_repository_test.dart
  modified:
    - flutter_app/lib/data/database/app_database.dart
    - flutter_app/lib/data/database/app_database.g.dart
    - flutter_app/pubspec.yaml
    - flutter_app/pubspec.lock

decisions:
  - id: D1
    decision: "cascade delete on CompletedSets.workoutId FK (KeyAction.cascade)"
    rationale: "Sets are meaningless without their parent workout; cascade prevents orphaned rows"
  - id: D2
    decision: "vibration package added in Plan 01 even though it's consumed in Plan 03"
    rationale: "pubspec.yaml changes trigger pub get and lockfile updates; consolidate dependency additions early"
  - id: D3
    decision: "SetData is a plain Dart class (not Drift DataClass)"
    rationale: "Ephemeral — lives in WorkoutSessionProvider state, never stored directly; avoids build_runner conflicts"

metrics:
  duration: "~2m 31s"
  completed: "2026-02-21"
  tasks-completed: 3
  tests-added: 3
  deviations: 1
---

# Phase 11 Plan 01: Drift Schema v3 + WorkoutRepository Summary

**One-liner:** Drift schema extended to v3 with 4 workout tables; transactional WorkoutRepository with cascade-delete sets and in-memory FK pragma fix.

## What Was Built

Extended the Drift database from v2 (Users, ActiveCycles) to v3 by adding four workout-data tables, created the ephemeral SetData model for in-session use, and implemented WorkoutRepository with fully transactional save and rich query methods. Added the vibration dependency for Plan 03's rest timer.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Extend Drift schema to v3 with workout tables | `7221c1b` | app_database.dart, app_database.g.dart, pubspec.yaml |
| 2 | Create SetData model and WorkoutRepository | `f8c1fd2` | set_data.dart, workout_repository.dart, workout_repository_provider.dart |
| 3 | Verify schema migration and transactional save | `56cde1f` | workout_repository_test.dart |

## Schema Changes (v2 → v3)

| Table | Purpose | Key Constraints |
|-------|---------|-----------------|
| `CompletedWorkouts` | Workout session header (userId, activeCycleId, programId, week, completedAt) | FK → Users, FK → ActiveCycles |
| `CompletedSets` | Individual sets logged per workout | FK → CompletedWorkouts **CASCADE DELETE** |
| `OneRepMaxes` | Calculated 1RM snapshots per exercise per user | FK → Users |
| `PersonalRecords` | Weight and volume PRs with workout linkage | FK → Users, FK → CompletedWorkouts |

Migration strategy:
- `from < 2`: creates `activeCycles` (existing path, unchanged)
- `from < 3`: creates all 4 new tables (new path)

## Repository API

```dart
// Atomic: inserts CompletedWorkout + all CompletedSets in a single transaction
Future<int> saveWorkout({userId, activeCycleId, programId, week, sets, completedAt, ...})

// Queries
Future<List<CompletedWorkout>> getWorkoutHistory(int userId)          // DESC by completedAt
Future<List<CompletedSet>>     getSetsForWorkout(int workoutId)       // ASC by setNumber
Future<List<CompletedWorkout>> getWorkoutsForCycle(int activeCycleId) // ASC by completedAt
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SQLite foreign key cascade not enforced in in-memory test database**

- **Found during:** Task 3 — cascade delete test failed (sets persisted after workout deletion)
- **Issue:** SQLite disables foreign key enforcement by default; `NativeDatabase.memory()` does not set `PRAGMA foreign_keys = ON` automatically
- **Fix:** Added `setup: (rawDb) { rawDb.execute('PRAGMA foreign_keys = ON'); }` to `NativeDatabase.memory()` in test `setUp()`
- **Files modified:** `flutter_app/test/unit/repositories/workout_repository_test.dart`
- **Commit:** `56cde1f`
- **Note:** Production `AppDatabase.defaults()` uses `driftDatabase()` which does enable FKs via drift_flutter; this is test-only

## Decisions Made

1. **Cascade delete on CompletedSets** — Sets are meaningless without their parent workout; cascade prevents orphaned rows and simplifies delete logic in future workout management UI.

2. **vibration added in Plan 01** — pubspec.yaml changes require `flutter pub get` + lockfile updates; consolidating dependency additions into the first plan of the phase avoids repeated lockfile churn.

3. **SetData is plain Dart** — Ephemeral model living in WorkoutSessionProvider state only; no Drift codegen needed; avoids build_runner conflicts with freezed per project conventions.

## Next Phase Readiness

- **11-02** can immediately import `workoutRepositoryProvider` and `SetData` — all exports are available
- **11-03** can use `vibration` package — dependency is resolved in pubspec.lock
- No blockers identified
