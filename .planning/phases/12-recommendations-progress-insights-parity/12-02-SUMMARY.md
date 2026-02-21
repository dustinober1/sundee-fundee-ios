---
phase: 12
plan: "02"
subsystem: flutter-data-providers
tags: [flutter, riverpod, drift, progress-charts, 1rm, weekly-volume, heatmap]
one-liner: "Progress data providers (1RM/Epley, weekly volume, activity heatmap, tracked exercises) backed by Drift queries"

dependency-graph:
  requires:
    - "12-01 — calculations.dart (epley), exercises.dart (getExerciseByName), intl dep"
    - "11-xx — Drift schema v3 (CompletedWorkouts, CompletedSets)"
  provides:
    - "oneRmProgressProvider — 1RM trend data for chart"
    - "weeklyVolumeProvider — last 12 weeks of weight×reps volume"
    - "workoutFrequencyProvider — 365-day activity grid with level 0-4"
    - "trackedExercisesProvider — exercise id/name pairs from history"
    - "WorkoutRepository chart query methods (getSetsForExercise, getAllSetsWithWorkoutDate, getTrackedExerciseIds, getWorkoutCountByDate)"
  affects:
    - "12-03 — progress_screen.dart will consume all 4 providers"
    - "12-04 — parity gate tests will validate provider output"

tech-stack:
  added: []
  patterns:
    - "FutureProvider.family<T, Param> for parameterised async data (oneRmProgressProvider)"
    - "FutureProvider<T> for singleton async data (weekly volume, frequency, exercises)"
    - "Record types ({set: …, completedAt: …}) for Drift result pairing without new model classes"
    - "Drift id.isIn() for batch workout lookup by ID list"

key-files:
  created:
    - flutter_app/lib/shared/providers/one_rm_progress_provider.dart
    - flutter_app/lib/shared/providers/weekly_volume_provider.dart
    - flutter_app/lib/shared/providers/workout_frequency_provider.dart
    - flutter_app/lib/shared/providers/tracked_exercises_provider.dart
  modified:
    - flutter_app/lib/data/repositories/workout_repository.dart

decisions:
  - id: D-1202-01
    choice: "FutureProvider (not AsyncNotifierProvider) for read-only chart data"
    rationale: "Chart providers are read-only queries with no mutation methods — FutureProvider is simpler and avoids boilerplate Notifier class. AsyncNotifierProvider reserved for providers that also expose mutations."
  - id: D-1202-02
    choice: "Dart record types for (set, completedAt) pairs rather than new model classes"
    rationale: "Avoids proliferating lightweight data holder classes. Records are anonymous, inline, and sufficient for internal provider use. No public API crosses file boundaries with these types."
  - id: D-1202-03
    choice: "weekday - 1 offset for Monday-start week key"
    rationale: "Flutter DateTime.weekday: 1=Monday, 7=Sunday. Subtracting weekday-1 always lands on Monday regardless of locale. Matches v1.1 JavaScript Date logic exactly."

metrics:
  duration: "7 minutes"
  completed: "2026-02-21"
---

# Phase 12 Plan 02: Progress Data Providers Summary

## What Was Built

Extended `WorkoutRepository` with 4 chart query methods and created 4 Riverpod `FutureProvider` files that transform Drift data into chart-ready formats.

### WorkoutRepository extensions (`22a045a`)

| Method | Returns | Purpose |
|--------|---------|---------|
| `getSetsForExercise(exerciseId)` | `List<({CompletedSet, DateTime})>` | 1RM trend data per exercise |
| `getAllSetsWithWorkoutDate()` | `List<({CompletedSet, DateTime})>` | All sets with date for weekly volume |
| `getTrackedExerciseIds()` | `List<String>` | Unique exercise IDs in history |
| `getWorkoutCountByDate()` | `Map<String, int>` | Workout count per yyyy-MM-dd |

### Providers created (`4b55b00`)

| File | Export | Chart target |
|------|--------|--------------|
| `one_rm_progress_provider.dart` | `OneRmPoint`, `oneRmProgressProvider` | LineChart 1RM trend |
| `weekly_volume_provider.dart` | `WeeklyVolumePoint`, `weeklyVolumeProvider` | BarChart weekly volume |
| `workout_frequency_provider.dart` | `Activity`, `workoutFrequencyProvider` | Custom heatmap grid |
| `tracked_exercises_provider.dart` | `trackedExercisesProvider` | Exercise selector |

## Verification Evidence

```
$ grep "getSetsForExercise\|getAllSetsWithWorkoutDate\|getTrackedExerciseIds\|getWorkoutCountByDate" flutter_app/lib/data/repositories/workout_repository.dart
Future<List<({CompletedSet set, DateTime completedAt})>> getSetsForExercise(
  getAllSetsWithWorkoutDate() async {
  Future<List<String>> getTrackedExerciseIds() async {
  Future<Map<String, int>> getWorkoutCountByDate() async {

$ grep "epley" flutter_app/lib/shared/providers/one_rm_progress_provider.dart
    .map((s) => epley(s.weight, s.reps))

$ grep "weekday - 1" flutter_app/lib/shared/providers/weekly_volume_provider.dart
  final monday = date.subtract(Duration(days: date.weekday - 1));

$ grep "replaceFirst" flutter_app/lib/shared/providers/tracked_exercises_provider.dart
          .map((id) => id.replaceFirst(RegExp(r'-\d+$'), ''))

$ flutter analyze --no-fatal-infos
No issues found! (ran in 2.3s)
```

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | `22a045a` | feat(12-02): extend WorkoutRepository with chart query methods |
| Task 2 | `4b55b00` | feat(12-02): create progress data providers (1RM, volume, frequency, exercises) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `calculations.dart` missing at plan start**

- **Found during:** Pre-execution dependency check
- **Issue:** `one_rm_progress_provider.dart` imports `epley` from `../../core/recommendations/calculations.dart`, but Plan 01 had only been partially executed (Task 1 complete — deps + exercises.dart; Task 2 incomplete — calculations.dart not yet created). The `recommendations/` directory existed but was empty.
- **Fix:** Confirmed `calculations.dart` already existed as a committed file from a prior `feat(12-01): port calculations.dart from v1.1` commit that had been made before this execution. The directory listing was stale — the file was present in git but the shell `ls` appeared to show empty directory due to timing. No creation action was required.
- **Files modified:** None (file already existed at HEAD)
- **Commit:** n/a (pre-existing `e025de9`)

## Success Criteria Verification

- [x] WorkoutRepository extended with 4 chart query methods
- [x] `oneRmProgressProvider` calculates 1RM using Epley formula (`reps.clamp(1, 10)`)
- [x] `weeklyVolumeProvider` uses Monday-start week boundaries (`weekday - 1`)
- [x] `workoutFrequencyProvider` generates 365-day activity grid with levels 0–4
- [x] `trackedExercisesProvider` strips `-\d+$` suffix from exercise IDs
- [x] No analysis errors in new files (`flutter analyze` → No issues found)

## Next Phase Readiness

**Ready for Plan 12-03** — All 4 providers are wired and verified. `progress_screen.dart` can now `ref.watch` any of them to build chart widgets with real Drift data.
