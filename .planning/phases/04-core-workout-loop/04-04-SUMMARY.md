---
phase: 04-core-workout-loop
plan: "04"
subsystem: domain
tags: [history, filtering, progress, charts, date-fns, typescript, tdd]

# Dependency graph
requires:
  - phase: 04-core-workout-loop (plan 01)
    provides: pr-detection subdomain with ExerciseMax and TrackedRepRange types
provides:
  - HistoryItemSource extended with 'custom' kind (backward compatible)
  - filterHistoryBySource: filters history items by all 4 source types (all/ai/program/custom)
  - groupHistoryByDate: groups history into Today/Yesterday/formatted date sections
  - prepare1RMChartData: converts ExerciseMax records to date-sorted 1RM time series
  - prepareVolumeChartData: aggregates workout volume per exercise per session
  - prepareRepRangePRs: returns best PR for each of 5 tracked rep ranges
affects:
  - History tab UI (filter chips, sectioned list)
  - Progress/Maxes tab UI (chart rendering)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Progress domain as pure data transformation layer — no storage access, fully tested"
    - "date-fns isToday/isYesterday/format used for human-readable date grouping"
    - "Chart data uses { date: string; value: number } as canonical point type"

key-files:
  created:
    - SundeeFundeeRN/src/domain/history/history-filter.ts
    - SundeeFundeeRN/src/domain/progress/progress-data.ts
    - SundeeFundeeRN/src/domain/progress/index.ts
    - SundeeFundeeRN/src/domain/__tests__/history-filter.test.ts
    - SundeeFundeeRN/src/domain/__tests__/progress-data.test.ts
  modified:
    - SundeeFundeeRN/src/domain/history/history-item.ts
    - SundeeFundeeRN/src/domain/history/index.ts

key-decisions:
  - "CompletedWorkoutRecord defined in progress domain (not WorkoutRepo) — keeps domain layer independent of repository types"
  - "Volume chart only counts completed sets (set.completed === true) — incomplete sets do not contribute to volume"
  - "Date grouping uses calendar date (local time) not UTC — prevents off-by-one on user's device timezone"

patterns-established:
  - "Pattern: Chart data points use string dates (YYYY-MM-DD) not Date objects — safer for sorting and serialization"
  - "Pattern: prepareRepRangePRs always returns exactly 5 entries — UI never needs to handle missing keys"

requirements-completed:
  - WORK-07
  - WORK-08
  - WORK-10
  - MAX-02

# Metrics
duration: 7min
completed: 2026-03-15
---

# Phase 4 Plan 04: History Filtering and Progress Chart Data Summary

**'custom' source type added to HistoryItem, with four-way source filtering and date grouping; three chart-data helpers (1RM/volume/rep-range PRs) convert raw ExerciseMax records into chart-ready arrays**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-15T00:27:00Z
- **Completed:** 2026-03-15T00:33:57Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended HistoryItemSource with `{ kind: 'custom' }` union member and added `totalVolume?` / `workoutName?` optional fields to HistoryItem
- Created `filterHistoryBySource` (4 source types) and `groupHistoryByDate` (Today/Yesterday/formatted sections) with TDD coverage
- Created `prepare1RMChartData` (best-per-day dedup, ascending sort), `prepareVolumeChartData` (per-session volume sum), and `prepareRepRangePRs` (all 5 rep ranges, null for missing) with full TDD coverage

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Failing tests for history filtering** - `1a6bb96` (test)
2. **Task 1 GREEN: Expand HistoryItemSource with 'custom', filterHistoryBySource, groupHistoryByDate** - `d5df367` (feat)
3. **Task 2 RED: Failing tests for progress chart data preparation** - `a11653f` (test)
4. **Task 2 GREEN: Create progress data preparation functions** - `caedee8` (feat)

**Plan metadata:** _(this commit)_ (docs: complete plan)

_Note: TDD tasks may have multiple commits (test -> feat -> refactor)_

## Files Created/Modified

- `SundeeFundeeRN/src/domain/history/history-item.ts` - Added `{ kind: 'custom' }` to HistoryItemSource, added `totalVolume?` and `workoutName?` to HistoryItem, updated getSourceLabel
- `SundeeFundeeRN/src/domain/history/history-filter.ts` - New: HistorySourceFilter type, filterHistoryBySource, groupHistoryByDate using date-fns
- `SundeeFundeeRN/src/domain/history/index.ts` - Updated barrel to export new filter functions
- `SundeeFundeeRN/src/domain/progress/progress-data.ts` - New: CompletedWorkoutRecord types, prepare1RMChartData, prepareVolumeChartData, prepareRepRangePRs
- `SundeeFundeeRN/src/domain/progress/index.ts` - New: barrel for progress subdomain
- `SundeeFundeeRN/src/domain/__tests__/history-filter.test.ts` - 16 tests covering all filter and grouping behavior
- `SundeeFundeeRN/src/domain/__tests__/progress-data.test.ts` - 17 tests covering all chart data preparation functions

## Decisions Made

- `CompletedWorkoutRecord` defined in progress domain rather than importing from WorkoutRepo — keeps domain layer free of repository dependencies (no circular imports, pure functions remain framework-free)
- Volume chart only counts sets where `completed === true` — prevents in-progress or skipped sets from inflating volume metrics
- Date grouping uses local calendar date via `toDateKey` (getFullYear/getMonth/getDate) not UTC — prevents off-by-one errors on user device timezones

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The existing `WorkoutRepo.WorkoutRecord` wraps `GeneratedWorkout` (which has `GeneratedExercise[]` with no logged sets), so a separate `CompletedWorkoutRecord` type was defined in the progress domain as planned — this was the correct approach per the plan's action section.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- History filtering domain is complete — History tab UI can use `filterHistoryBySource` and `groupHistoryByDate` directly
- Progress chart domain is complete — Maxes/Progress tab UI can use all three chart helpers
- No blockers for subsequent plans in Phase 4

## Self-Check: PASSED

All created files verified on disk. All task commits verified in git log.
