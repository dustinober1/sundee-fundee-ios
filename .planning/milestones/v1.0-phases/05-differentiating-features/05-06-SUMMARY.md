---
phase: 05-differentiating-features
plan: "06"
subsystem: ui
tags: [react-native, expo-router, programs, target-weight, enrollment, 1RM, tdd]

# Dependency graph
requires:
  - phase: 05-01
    provides: ProgramRepo (getProgramRepo factory), LocalProgramRepo, FirestoreProgramRepo, programs.json bundled resource
  - phase: 04-core-workout-loop
    provides: ExerciseMaxRepo (getAllMaxes), WorkoutRepo (saveWorkout), Art Deco component patterns

provides:
  - Program catalog screen with filter chips (All/Strength/Hypertrophy/Power)
  - Program detail screen with collapsible session breakdown and enrollment CTA
  - Active program session screen with target weight calculation from 1RM
  - target-weight.ts helpers: calculateTargetWeight, getMissing1RMs, formatTargetWeight

affects:
  - 05-09 (tab wiring — programs tab navigation)
  - 05-07 (any features depending on program enrollment state)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TDD for pure calculation helpers: test file written before implementation, RED confirmed, GREEN achieved"
    - "getMissing1RMs: fixed ExerciseValue with value <= 1.0 treated as 1RM percentage (not absolute weight)"
    - "useFocusEffect for data loading in program screens — refreshes on navigation return"
    - "getAllMaxes used (not getMaxes) to retrieve all exercise maxes across all rep ranges for 1RM lookup"

key-files:
  created:
    - SundeeFundeeRN/src/components/programs/target-weight.ts
    - SundeeFundeeRN/src/components/programs/__tests__/targetWeight.test.ts
    - SundeeFundeeRN/app/(app)/programs/index.tsx
    - SundeeFundeeRN/app/(app)/programs/[id].tsx
    - SundeeFundeeRN/app/(app)/programs/session.tsx
  modified: []

key-decisions:
  - "fixed ExerciseValue with value <= 1.0 is treated as a 1RM percentage — programs.json uses text weights but future programs can use percentage fractions"
  - "calculateTargetWeight finds the best estimated1RM across all rep ranges (not just repRange=1) — maximises accuracy for users who log across rep ranges"
  - "getMissing1RMs excludes text and amrap weights — only fixed percentage values require a 1RM for calculation"
  - "Missing 1RM prompt accepts weights but does not save them to ExerciseMaxRepo (repRange metadata is required for saveMax) — skip is first-class action"
  - "Session completion saves a WorkoutRecord with source=program and empty exercises array — durationSeconds=0 for program-initiated sessions without tracking"

patterns-established:
  - "Percentage weight encoding: ExerciseValue kind=fixed, value in [0.0, 1.0] represents a fraction of 1RM"
  - "Target weight display: absolute lbs when 1RM available, '75%' percentage fallback otherwise"
  - "Enrollment state machine: none / enrolled-here / enrolled-elsewhere drives CTA rendering"

requirements-completed: [PROG-01, PROG-02, PROG-03, PROG-04]

# Metrics
duration: 6min
completed: 2026-03-15
---

# Phase 5 Plan 06: Programs Summary

**Program catalog, enrollment flow, and session screen with auto-calculated target weights from user's logged 1RM using TDD-verified percentage helpers**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-15T13:00:28Z
- **Completed:** 2026-03-15T13:06:15Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Built `calculateTargetWeight` / `getMissing1RMs` / `formatTargetWeight` helpers with TDD (10 tests passing)
- Program catalog with horizontal filter chips (All/Strength/Hypertrophy/Power), card list with Art Deco styling
- Program detail with collapsible session accordion, three-state enrollment CTA, skippable missing-1RM prompt
- Active session screen showing target weights per exercise ("225 lbs" or "75% 1RM" fallback) and session completion flow

## Task Commits

1. **Task 1: Build target weight helper and program catalog screen** - `7b712b5` (feat)
2. **Task 2: Build program detail, enrollment, and active session screens** - `dd69bde` (feat)

## Files Created/Modified

- `SundeeFundeeRN/src/components/programs/target-weight.ts` — calculateTargetWeight, getMissing1RMs, formatTargetWeight helpers
- `SundeeFundeeRN/src/components/programs/__tests__/targetWeight.test.ts` — 10 TDD tests covering all helper functions
- `SundeeFundeeRN/app/(app)/programs/index.tsx` — Program catalog with filter chips and card list
- `SundeeFundeeRN/app/(app)/programs/[id].tsx` — Program detail with enrollment CTA and session breakdown
- `SundeeFundeeRN/app/(app)/programs/session.tsx` — Active session with target weights and completion flow

## Decisions Made

- Fixed ExerciseValue with value <= 1.0 is treated as 1RM percentage (not absolute weight) — programs.json uses text weights today but future programs can encode percentages as fractions
- `calculateTargetWeight` finds best `estimated1RM` across all rep ranges, maximising accuracy for users who log multiple rep ranges
- Missing 1RM prompt accepts weight inputs but does not save to `ExerciseMaxRepo` — `saveMax` requires `repRange` metadata not available at enrollment time; Skip is first-class action
- Session completion saves a minimal `WorkoutRecord` with `source='program'` and empty exercises array — full exercise tracking can be layered in later via the "Start Workout" flow

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Programs tab screens are complete and ready for tab bar wiring in Plan 09
- Session screen navigates to `/(app)/(tabs)` on completion — dashboard will show the last program workout in the recent workout card
- "Start Workout" button (navigates to workout-session with program exercises preloaded) is noted for Plan 09 wiring

---
*Phase: 05-differentiating-features*
*Completed: 2026-03-15*
