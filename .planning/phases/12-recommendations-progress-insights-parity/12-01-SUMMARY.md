---
phase: 12-recommendations-progress-insights-parity
plan: "01"
subsystem: recommendations-engine
tags: [flutter, dart, recommendations, calculations, plateau-detection, exercises, fl-chart, intl]

dependency-graph:
  requires:
    - "11-04: Drift schema v3 (CompletedWorkouts, CompletedSets, OneRepMaxes, PersonalRecords)"
    - "11-04: WorkoutRepository transactional implementation"
  provides:
    - "Pure Dart recommendation calculations (calculations.dart)"
    - "Database-aware plateau detection (plateau_detection.dart)"
    - "Exercise metadata lookup (exercises.dart)"
    - "fl_chart + intl dependencies for progress charts"
  affects:
    - "12-02: Progress screen chart queries (uses exercises.dart + WorkoutRepository)"
    - "12-03: Recommendations provider (uses calculations.dart + plateau_detection.dart)"
    - "12-04: Insights feature (uses calculateVolumeLoad, wasSessionSuccessful)"
    - "12-05: Parity gate tests (validates truths from this plan)"

tech-stack:
  added:
    - "fl_chart: ^1.1.1 — chart rendering for progress screen"
    - "intl: ^0.20.2 — date formatting for progress charts"
  patterns:
    - "Pure function port pattern: v1.1 TypeScript → exact Dart equivalent"
    - "Repository pattern: plateau detection takes AppDatabase parameter (not raw Drift access)"
    - "v1.1 parity: constant_identifier_names suppression for EXERCISES (matches TS naming)"

key-files:
  created:
    - flutter_app/lib/core/recommendations/calculations.dart
    - flutter_app/lib/core/recommendations/plateau_detection.dart
    - flutter_app/lib/data/exercises.dart
  modified:
    - flutter_app/pubspec.yaml
    - flutter_app/pubspec.lock

decisions:
  - id: D1
    choice: "reps.clamp(1, 10) for Epley cap (not if-guard)"
    rationale: "Matches v1.1 Math.min(reps, 10) semantics; Dart clamp is idiomatic"
  - id: D2
    choice: "EXERCISES constant name kept uppercase despite lint warning"
    rationale: "Exact parity with v1.1 TypeScript; suppressed via ignore comment"
  - id: D3
    choice: "detectPlateauForExercise takes AppDatabase not WorkoutRepository"
    rationale: "Plateau detection needs compound queries; AppDatabase gives direct Drift builder access without coupling to repo method signatures that may evolve"
  - id: D4
    choice: "getDeloadWeight in plateau_detection.dart (not calculations.dart)"
    rationale: "Deload is only meaningful in context of plateau detection; keeps calculations.dart purely mathematical"

metrics:
  duration: "~3 minutes"
  tasks-completed: 3
  tasks-total: 3
  completed: "2026-02-21"
---

# Phase 12 Plan 01: Recommendation Engine Port Summary

**One-liner:** Pure Dart port of v1.1 recommendation calculations (Epley/plateau/session-result) with cycle-scoped rep-failure plateau detection and 7-exercise metadata.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Add dependencies and create exercises data | `24d1ea1` | pubspec.yaml, lib/data/exercises.dart |
| 2 | Create calculations.dart (pure Dart port) | `e025de9` | lib/core/recommendations/calculations.dart |
| 3 | Create plateau_detection.dart with repository integration | `93f792f` | lib/core/recommendations/plateau_detection.dart |

## Verification Evidence

### 1. `flutter pub get` — No errors
```
Resolving dependencies...
Got dependencies!
```

### 2. `flutter analyze --no-fatal-infos` — No issues
```
Analyzing flutter_app...
No issues found! (ran in 2.3s)
```
*(Initial run had 3 `info` items — dangling doc comments and constant naming — fixed before Task 3 commit.)*

### 3. All functions present in recommendations/
```
lib/core/recommendations/plateau_detection.dart: detectPlateauForExercise, roundToNearestFive
lib/core/recommendations/calculations.dart: roundToNearestFive, epley, detectPlateau
```

### 4. EXERCISES constant with 7 entries
```
const List<ExerciseMetadata> EXERCISES = [
    return EXERCISES.firstWhere((exercise) => exercise.id == id);
```

### 5. Critical truth verifications
- **Epley cap:** `grep "clamp(1, 10)"` → `return weight * (1 + reps.clamp(1, 10) / 30);` ✅
- **Cycle scoping:** `grep "activeCycleId.equals"` → `..where((t) => t.activeCycleId.equals(activeCycleId))` ✅
- **Rep failure logic:** `grep "actualReps < s.prescribedReps"` → `sets.any((s) => s.actualReps < s.prescribedReps)` ✅

## Success Criteria Checklist

- [x] fl_chart ^1.1.1 and intl ^0.20.2 added to pubspec.yaml
- [x] EXERCISES constant with 7 exercises matching v1.1
- [x] calculations.dart with all 8 functions ported from v1.1
- [x] plateau_detection.dart with cycle-scoped rep failure detection
- [x] No analysis errors in new files

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | `reps.clamp(1, 10)` for Epley cap | Idiomatic Dart equivalent of v1.1 `Math.min(reps, 10)` |
| D2 | Keep `EXERCISES` uppercase with lint suppression | Exact v1.1 parity; `// ignore: constant_identifier_names` documents intent |
| D3 | `detectPlateauForExercise` takes `AppDatabase` directly | Compound Drift queries need builder access; repo method signatures may evolve |
| D4 | `getDeloadWeight` lives in `plateau_detection.dart` | Only meaningful in plateau context; keeps `calculations.dart` purely mathematical |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dangling_library_doc_comments lint warnings**

- **Found during:** Task 3 verification (`flutter analyze --no-fatal-infos`)
- **Issue:** Triple-slash `///` file-level comments in `calculations.dart` and `exercises.dart` triggered `dangling_library_doc_comments` info warnings (no `library` directive attached)
- **Fix:** Converted to double-slash `//` regular comments
- **Files modified:** `calculations.dart`, `exercises.dart`
- **Commit:** `93f792f` (included in Task 3 commit)

**2. [Rule 2 - Missing Critical] Added `constant_identifier_names` lint suppression for EXERCISES**

- **Found during:** Task 3 verification (`flutter analyze --no-fatal-infos`)
- **Issue:** `EXERCISES` uppercase constant triggered lint warning
- **Fix:** Added `// ignore: constant_identifier_names — matches v1.1 TypeScript constant naming` to document intentional parity decision
- **Files modified:** `exercises.dart`
- **Commit:** `93f792f`

## Next Phase Readiness

**Plan 12-02** can proceed immediately — all prerequisites satisfied:
- `exercises.dart` EXERCISES constant available for exercise name lookups
- `calculations.dart` all 8 functions available
- `plateau_detection.dart` ready for provider wrapping
- `fl_chart` and `intl` packages resolved and available
