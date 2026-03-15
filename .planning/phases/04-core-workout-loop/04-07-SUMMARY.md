---
phase: 04-core-workout-loop
plan: "07"
subsystem: history-and-maxes-ui
tags: [history-tab, maxes-tab, workout-detail, exercise-detail, progress-chart, rep-range-prs, gifted-charts, swipeable]
dependency_graph:
  requires:
    - 04-03  # WorkoutRepository, ExerciseMaxRepository, WorkoutRecord types
    - 04-04  # history domain: filterHistoryBySource, groupHistoryByDate
    - 04-05  # workout session hooks and PRToast
  provides:
    - History tab with date-grouped workout cards, source filtering, swipe-to-delete, pull-to-refresh
    - Workout detail screen for custom/program (set table + PR badges) and AI (prescription view)
    - Maxes tab with best 1RM per exercise, search, alphabetical sort
    - Exercise detail screen with 1RM line chart, rep-range PR table, optional volume chart
    - SourceFilter component (filter chip row)
    - HistoryCard component (swipeable, source badge, meta stats)
    - ProgressChart component (gifted-charts LineChart wrapper, ORANGE/CREAM Art Deco theme)
    - RepRangePRTable component (5-row PR table with 1RM highlight)
  affects:
    - Phase 5 (AI workout generation will populate history)
    - Phase 6 (paywall gating on history/maxes features)
tech_stack:
  added: []
  patterns:
    - GestureHandlerRootView wraps swipeable list screens for react-native-gesture-handler
    - Swipeable from react-native-gesture-handler for swipe-left-to-delete pattern
    - Alert.alert on native + window.confirm on web for destructive confirmation dialogs
    - Optimistic delete (remove from state, then persist; reload on failure)
    - SectionList with date-grouped sections for chronological history display
    - react-native-gifted-charts LineChart with areaChart + focusEnabled for 1RM visualization
    - buildExerciseSummaries groups ExerciseMax records and computes best estimated1RM per exercise
    - workoutRecordToHistoryItem converts WorkoutRecord to HistoryItem at the UI boundary
    - CompletedWorkoutRecord built from WorkoutRecord.exercises for volume chart data
key_files:
  created:
    - SundeeFundeeRN/src/components/history/SourceFilter.tsx
    - SundeeFundeeRN/src/components/history/HistoryCard.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/history.tsx
    - SundeeFundeeRN/app/(app)/workout-detail.tsx
    - SundeeFundeeRN/src/components/charts/ProgressChart.tsx
    - SundeeFundeeRN/src/components/charts/RepRangePRTable.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx
    - SundeeFundeeRN/app/(app)/exercise-detail.tsx
  modified:
    - SundeeFundeeRN/app/(app)/_layout.tsx (added workout-detail and exercise-detail Stack.Screen entries)
    - SundeeFundeeRN/app/(app)/(tabs)/_layout.tsx (added History and Maxes tabs)
decisions:
  - "workoutRecordToHistoryItem maps WorkoutRecord.source to HistoryItemSource at UI layer — keeps repository types decoupled from domain types"
  - "AI workout detail uses separate AIExerciseSection component — GeneratedExercise.sets is a number, not array, different from CompletedExercise.sets"
  - "buildExerciseSummaries defined in maxes.tsx (not domain) — it's a view-model computation, not a pure domain function"
  - "Volume chart shown only when 2+ data points — single point provides no trend information"
  - "RepRangePRTable always renders all 5 rep ranges — prepareRepRangePRs guarantees exactly 5 entries"
metrics:
  duration: 6 min
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_created: 8
  files_modified: 2
---

# Phase 04 Plan 07: History Tab, Maxes Tab, and Progress Charts Summary

**One-liner:** History tab (date-grouped SectionList with SourceFilter chips, swipe-to-delete, pull-to-refresh), workout detail modal, Maxes tab (searchable exercise list with best 1RM), and exercise detail screen with react-native-gifted-charts 1RM line chart and rep-range PR table — all in Art Deco CREAM/NAVY/ORANGE theming.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | History tab, HistoryCard, SourceFilter, workout-detail screen | 8e53bd3 | 6 files |
| 2 | Maxes tab, exercise-detail, ProgressChart, RepRangePRTable | 37ce1b5 | 4 files |

## What Was Built

### Task 1: History UI

**SourceFilter** (`src/components/history/SourceFilter.tsx`): Horizontal scrollable chip row with four filter options (All/AI/Program/Custom). ORANGE background + CREAM text for active chip; CREAM_LIGHT + NAVY for inactive. Calls `onFilterChange` callback.

**HistoryCard** (`src/components/history/HistoryCard.tsx`): Swipeable card using `react-native-gesture-handler`. Shows workout title, source badge (AI=blue, Program=green, Custom=ORANGE), duration in MM:SS, exercise count, and total volume. Swipe left reveals red Delete button; confirmation uses `Alert.alert` on native and `window.confirm` on web. Exports `formatDuration` and `formatVolume` static helpers for reuse.

**history.tsx** (`app/(app)/(tabs)/history.tsx`): Loads via `getWorkoutRepo(isGuest).getHistory(uid)`. Converts `WorkoutRecord[]` to `HistoryItem[]` using `workoutRecordToHistoryItem`. Applies `filterHistoryBySource` + `groupHistoryByDate` to build SectionList data. Optimistic delete removes item from state immediately, then persists asynchronously (reloads on failure). Pull-to-refresh support. Empty state with Start Workout CTA.

**workout-detail.tsx** (`app/(app)/workout-detail.tsx`): Loads single record via `getWorkoutRepo(isGuest).getWorkout(uid, workoutId)`. Renders `CompletedExerciseSection` (custom/program workouts: set table with weight, reps, PR orange badge) and `AIExerciseSection` (AI workouts: prescribed set × rep scheme + notes). Handles missing exercises gracefully.

### Task 2: Maxes and Progress Charts

**ProgressChart** (`src/components/charts/ProgressChart.tsx`): Wraps `react-native-gifted-charts` `LineChart`. ORANGE line (thickness 2.5), CREAM_LIGHT area fill, NAVY axis labels, curved line, focus indicator on tap. Responsive width from `useWindowDimensions`. Shows "No data yet" empty state. Abbreviated date labels every N points for dense datasets.

**RepRangePRTable** (`src/components/charts/RepRangePRTable.tsx`): Renders 5-row table for TrackedRepRanges [1, 3, 5, 8, 10]. NAVY header row; alternating CREAM/CREAM_LIGHT data rows; 1RM row highlighted with ORANGE_LIGHT background and left-border accent when PR data exists. Null entries render "--".

**maxes.tsx** (`app/(app)/(tabs)/maxes.tsx`): Loads via `getExerciseMaxRepo(isGuest).getAllMaxes(uid)`. `buildExerciseSummaries` groups by exerciseId and finds best `estimated1RM` per exercise. Search filters by name (case-insensitive). FlatList sorted alphabetically. Orange 1RM value display. Pull-to-refresh. Taps navigate to exercise-detail with `exerciseId` + `exerciseName` params.

**exercise-detail.tsx** (`app/(app)/exercise-detail.tsx`): Parallel load of `getMaxes(exerciseId)` and `getHistory(uid)`. Builds `CompletedWorkoutRecord[]` from workout history for volume chart. Renders: current PR badge (if 1RM data exists), 1RM ProgressChart, RepRangePRTable, Volume ProgressChart (only when 2+ data points). Art Deco NAVY header with ORANGE accent.

## Verification Results

- `npx jest src/domain/__tests__/history-filter.test.ts`: 16/16 pass
- `npx jest src/domain/__tests__/progress-data.test.ts`: 17/17 pass
- Full suite: 921/921 tests pass across 37 suites
- `npx expo export --platform web`: clean bundle, no TypeScript errors

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed AI workout detail rendering**

- **Found during:** Task 1 — workout-detail AI exercise rendering
- **Issue:** `GeneratedExercise.sets` is a `number` (set count), not an array of set objects. Initial implementation tried to map over it as an array.
- **Fix:** Created separate `AIExerciseSection` component for AI workouts displaying prescribed `sets × reps` scheme text rather than a table of logged sets
- **Files modified:** `app/(app)/workout-detail.tsx`
- **Commit:** 8e53bd3

**2. [Rule 1 - Bug] Fixed TypeScript operator precedence error**

- **Found during:** Task 1 — expo export build
- **Issue:** `record.exerciseCount ?? customExercises.length || aiExercises.length` had precedence error — `??` has lower precedence than `||`, causing `(record.exerciseCount ?? customExercises.length) || aiExercises.length` behavior
- **Fix:** Rewrote as `record.exerciseCount ?? (customExercises.length > 0 ? customExercises.length : aiExercises.length)`
- **Files modified:** `app/(app)/workout-detail.tsx`
- **Commit:** 8e53bd3

**3. [Rule 1 - Bug] Removed duplicate `fontSize` property in StyleSheet**

- **Found during:** Task 2 — style definition in exercise-detail.tsx
- **Issue:** `sectionTitle` StyleSheet had `fontSize: 16` then `fontSize: 13` (duplicate key)
- **Fix:** Removed first `fontSize: 16`, kept `fontSize: 13`
- **Files modified:** `app/(app)/exercise-detail.tsx`
- **Commit:** 37ce1b5

## Self-Check: PASSED

Files verified on disk:
- SundeeFundeeRN/src/components/history/SourceFilter.tsx ✓
- SundeeFundeeRN/src/components/history/HistoryCard.tsx ✓
- SundeeFundeeRN/app/(app)/(tabs)/history.tsx ✓
- SundeeFundeeRN/app/(app)/workout-detail.tsx ✓
- SundeeFundeeRN/src/components/charts/ProgressChart.tsx ✓
- SundeeFundeeRN/src/components/charts/RepRangePRTable.tsx ✓
- SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx ✓
- SundeeFundeeRN/app/(app)/exercise-detail.tsx ✓

Commits verified:
- 8e53bd3 — Task 1 history UI ✓
- 37ce1b5 — Task 2 maxes + charts ✓
