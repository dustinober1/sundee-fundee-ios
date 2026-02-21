---
phase: 12
plan: 04
subsystem: flutter-workout-pr-detection
tags: [flutter, drift, riverpod, pr-detection, 1rm, workout-completion]

dependency-graph:
  requires: ["12-01", "12-02"]
  provides: ["PR detection on workout completion", "1RM recording per exercise"]
  affects: ["12-05"]

tech-stack:
  added: []
  patterns:
    - "PR-before-1RM ordering: check PRs against pre-session baseline before saving new 1RM"
    - "Record type returns from async Notifier methods (workoutId + weightPRs + volumePRs)"

key-files:
  created: []
  modified:
    - flutter_app/lib/data/repositories/workout_repository.dart
    - flutter_app/lib/shared/providers/workout_session_provider.dart
    - flutter_app/lib/features/workout/workout_screen.dart

decisions:
  - id: pr-ordering
    choice: "Check PRs before saving 1RM"
    rationale: "Preserves pre-session baseline so new weight/volume is compared against prior history, not current session"
  - id: no-first-lift-pr
    choice: "historicalMax <= 0 guard blocks weight PR on first-ever lift"
    rationale: "Matches v1.1 behavior — a first lift can't be a PR"
  - id: no-first-session-volume-pr
    choice: "bestHistorical <= 0 guard blocks volume PR on first session"
    rationale: "Matches v1.1 behavior — first session has no prior baseline to beat"
  - id: record-return-type
    choice: "completeWorkout returns ({int? workoutId, List<String> weightPRs, List<String> volumePRs})?  "
    rationale: "Backward-compatible record type; callers can ignore PR fields if unused"

metrics:
  duration: "~2 minutes"
  completed: "2026-02-21"
  tasks-completed: 2
  tasks-total: 2
---

# Phase 12 Plan 04: PR Detection and 1RM Recording Summary

**One-liner:** Post-workout PR detection (weight + volume) and Epley 1RM recording wired into WorkoutSessionNotifier with RECO-02-compliant ordering (check PRs before saving 1RM).

## What Was Built

### Task 1 — PR detection and 1RM save methods in WorkoutRepository
**Commit:** `e737948`

Added five methods to `WorkoutRepository`:

| Method | Purpose |
|--------|---------|
| `saveOneRepMax()` | Inserts estimated 1RM into `OneRepMaxes` table |
| `getHistoricalMax()` | Queries max weight from `OneRepMaxes` for exercise/user |
| `checkAndSaveWeightPR()` | Compares max session weight vs historical max; saves to `PersonalRecords` if PR |
| `getBestSessionVolume()` | Gets best prior session volume for an exercise (excludes current workout) |
| `checkAndSaveVolumePR()` | Compares session volume vs best historical; saves to `PersonalRecords` if PR |

**Critical guards:**
- `checkAndSaveWeightPR`: `historicalMax <= 0` → no PR (first-ever lift)
- `checkAndSaveVolumePR`: `bestHistorical <= 0` → no PR (first session)

### Task 2 — Wire PR detection into workout completion
**Commit:** `65c48d3`

Updated `WorkoutSessionNotifier.completeWorkout()` in `workout_session_provider.dart`:

1. **Return type changed** from `Future<int?>` to `Future<({int? workoutId, List<String> weightPRs, List<String> volumePRs})?>` — carries detected PR exercise IDs
2. **CRITICAL ORDERING enforced:**
   - Step A: `checkAndSaveWeightPR` + `checkAndSaveVolumePR` query `OneRepMaxes` BEFORE current 1RM is saved
   - Step B: `saveOneRepMax` (Epley formula) runs AFTER PR checks
3. **Weight PR** uses `maxWeight` (max actual weight from session sets)
4. **Volume PR** uses `sessionVolume` (Σ weight × reps across all sets)

Updated `workout_screen.dart`:
- `workoutId` → `result` variable name
- Null check updated: `if (result != null && mounted)`

**Deviation (Rule 1 - Bug):** Removed unused `calculations.dart` import from `workout_repository.dart` that was added speculatively (epley is used in the provider, not the repo). This cleared the `unused_import` analyzer warning.

## Verification Evidence

```
# Task 1 method presence
$ grep "saveOneRepMax\|checkAndSaveWeightPR\|checkAndSaveVolumePR" \
    flutter_app/lib/data/repositories/workout_repository.dart
Future<int> saveOneRepMax({
Future<bool> checkAndSaveWeightPR({
Future<bool> checkAndSaveVolumePR({

# First-lift guards
$ grep "historicalMax <= 0" flutter_app/lib/data/repositories/workout_repository.dart
    if (historicalMax <= 0) return false;

$ grep "bestHistorical <= 0" flutter_app/lib/data/repositories/workout_repository.dart
    if (bestHistorical <= 0) return false;

# Task 2 — provider wiring
$ grep "saveOneRepMax\|checkAndSaveWeightPR\|checkAndSaveVolumePR" \
    flutter_app/lib/shared/providers/workout_session_provider.dart
final isWeightPR = await repo.checkAndSaveWeightPR(
final isVolumePR = await repo.checkAndSaveVolumePR(
await repo.saveOneRepMax(

# Epley used in provider
$ grep "epley" flutter_app/lib/shared/providers/workout_session_provider.dart
          .map((s) => epley(s.actualWeight, s.actualReps))

# PR lists returned
$ grep "weightPRs\|volumePRs" flutter_app/lib/shared/providers/workout_session_provider.dart
  Future<({int? workoutId, List<String> weightPRs, List<String> volumePRs})?> ...
    final weightPRs = <String>[];
    final volumePRs = <String>[];
    if (isWeightPR) weightPRs.add(exerciseId);
    if (isVolumePR) volumePRs.add(exerciseId);
    return (workoutId: workoutId, weightPRs: weightPRs, volumePRs: volumePRs);

# Caller updated
$ grep "result" flutter_app/lib/features/workout/workout_screen.dart
    final result = await ref
    if (result != null && mounted) {

# Method count (3 definitions in repo)
$ grep -c "saveOneRepMax\|checkAndSaveWeightPR\|checkAndSaveVolumePR" \
    flutter_app/lib/data/repositories/workout_repository.dart
3

# Import verification
$ grep "import.*calculations" flutter_app/lib/shared/providers/workout_session_provider.dart
import '../../core/recommendations/calculations.dart';

# Flutter analyze
$ cd flutter_app && flutter analyze --no-fatal-infos
No issues found!
```

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| PR check ordering | PR checks before 1RM save | Pre-session baseline preserved for accurate detection; matches v1.1 |
| No-first-lift guard | `historicalMax <= 0` blocks weight PR | First lift has no prior history to beat |
| No-first-session guard | `bestHistorical <= 0` blocks volume PR | First session has no prior baseline |
| completeWorkout return type | Record with workoutId + PR lists | Backward-compatible; callers can ignore PR fields |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `calculations.dart` import from `workout_repository.dart`**

- **Found during:** flutter analyze after Task 1
- **Issue:** Plan instructed importing `calculations.dart` in `workout_repository.dart`, but `epley()` is only used in `workout_session_provider.dart`, not in the repo itself
- **Fix:** Removed the import from `workout_repository.dart` (it was already correctly imported in the provider)
- **Files modified:** `flutter_app/lib/data/repositories/workout_repository.dart`
- **Commit:** `65c48d3` (included in Task 2 commit)

## Next Phase Readiness

- **12-05** (InsightsScreen / recommendations display) can now read `PersonalRecords` table for PR history and `OneRepMaxes` table for 1RM trends
- PR data is workout-referenced (via `workoutId` FK) enabling per-workout PR display
- `completeWorkout()` return type carries detected PR exercise IDs for potential UI celebration
