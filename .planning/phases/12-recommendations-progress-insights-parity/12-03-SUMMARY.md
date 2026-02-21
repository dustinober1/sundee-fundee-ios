---
phase: 12
plan: "03"
subsystem: progress-ui
tags: [flutter, fl_chart, heatmap, riverpod, progress-screen]

dependency-graph:
  requires: ["12-01", "12-02"]
  provides: ["progress_screen.dart", "one_rm_chart.dart", "weekly_volume_chart.dart", "workout_heatmap.dart"]
  affects: ["12-04", "12-05"]

tech-stack:
  added: []
  patterns:
    - ConsumerStatefulWidget for exercise dropdown state
    - ConsumerWidget for pure data-driven chart widgets
    - Key on outer widget pattern (always renders for test selectors)
    - Wrap(direction: Axis.vertical) for GitHub-style heatmap columns
    - interval = (length/5).ceil().clamp(1.0, ∞) for chart label density

key-files:
  created:
    - flutter_app/lib/features/progress/one_rm_chart.dart
    - flutter_app/lib/features/progress/weekly_volume_chart.dart
    - flutter_app/lib/features/progress/workout_heatmap.dart
  modified:
    - flutter_app/lib/features/progress/progress_screen.dart

decisions:
  - "Key selectors placed on outermost widget that always renders — not inside conditional data branches — ensuring integration tests find keys in empty-state"
  - "Heatmap uses Wrap(direction: Axis.vertical) with spacing/runSpacing=3 to create GitHub-style columns of 7 days"
  - "Chart label interval formula: (data.length / 5).ceil().clamp(1.0, ∞) to prevent overlap at any data volume"
  - "OneRmChart is ConsumerStatefulWidget (needs selectedExerciseId local state); volume/heatmap are stateless ConsumerWidgets"
  - "ProgressScreen upgraded from StatelessWidget to ConsumerWidget for Riverpod context"

metrics:
  duration: "~8 minutes"
  completed: "2026-02-21"
---

# Phase 12 Plan 03: Progress Screen Chart UI Summary

**One-liner:** Progress screen built with fl_chart LineChart/BarChart + custom GitHub-style heatmap wired to Riverpod providers from Plan 12-02.

## What Was Built

Three chart widget files and a fully-wired progress screen matching v1.1 layout:

| Widget | Type | Provider | Key |
|---|---|---|---|
| `OneRmChart` | `ConsumerStatefulWidget` | `oneRmProgressProvider(exerciseId)` + `trackedExercisesProvider` | `Key('one-rm-chart')` |
| `WeeklyVolumeChart` | `ConsumerWidget` | `weeklyVolumeProvider` | `Key('weekly-volume-chart')` |
| `WorkoutHeatmap` | `ConsumerWidget` | `workoutFrequencyProvider` | `Key('workout-heatmap')` |
| `ProgressScreen` | `ConsumerWidget` | — (composes widgets) | `Key('progress-screen')` |

## Tasks Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Create chart widgets (OneRM, WeeklyVolume, Heatmap) | `21e40e5` | one_rm_chart.dart, weekly_volume_chart.dart, workout_heatmap.dart |
| 2 | Update progress_screen.dart with chart layout | `ee5eb60` | progress_screen.dart |

## Verification Evidence

```
# flutter analyze --no-fatal-infos
Analyzing flutter_app...
1 issue found.  (pre-existing warning in workout_repository.dart — unused import, exit code 0)

# ls flutter_app/lib/features/progress/
one_rm_chart.dart    weekly_volume_chart.dart
progress_screen.dart  workout_heatmap.dart

# grep -r "Key(" flutter_app/lib/features/progress/
one_rm_chart.dart:      key: const Key('one-rm-chart'),
workout_heatmap.dart:      key: const Key('workout-heatmap'),
weekly_volume_chart.dart:      key: const Key('weekly-volume-chart'),
progress_screen.dart:      key: const Key('progress-screen'),
```

## Success Criteria

- [x] progress_screen.dart renders 3 chart Cards (1RM Progress, Weekly Volume, Training Frequency)
- [x] one_rm_chart.dart displays LineChart with exercise dropdown and lbs Y-axis
- [x] weekly_volume_chart.dart displays BarChart with k-formatted Y-axis
- [x] workout_heatmap.dart displays custom 365-day grid with GitHub-style colors
- [x] All widgets have Key selectors for testing (outer always-rendered widget)
- [x] No analysis errors in progress/ files (exit code 0)

## Decisions Made

1. **Key placement pattern:** Keys are always on the outermost widget returned by `build()`, not inside `.when(data: ...)` branches. This ensures parity gate tests find keys even in empty/loading states.
2. **Heatmap grid:** `Wrap(direction: Axis.vertical, spacing: 3, runSpacing: 3)` — 12×12px cells with 2px border-radius. Matches GitHub contribution graph layout.
3. **Chart label interval:** `(data.length / 5).ceil().clamp(1.0, double.infinity)` — scales to any data volume, always shows ≤5 labels.
4. **OneRmChart state:** Exercise selection stored in `selectedExerciseId` local state; falls back to `exercises.first.id` when null.
5. **Empty states:** Both charts and heatmap display friendly empty-state messages rather than blank/error UI.

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- **12-04** (parity gate tests): All 4 Key selectors present and on always-rendering widgets ✅
- **12-05** (recommendations screen): No dependencies on this plan's files
