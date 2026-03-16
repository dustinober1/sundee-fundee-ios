---
phase: 05-differentiating-features
plan: 07
subsystem: ui
tags: [react-native, benchmarks, wod, scoring, firestore, gifted-charts, date-fns]

# Dependency graph
requires:
  - phase: 05-01
    provides: BenchmarkRepo (getBenchmarkRepo), WODRepo (getWODRepo), BenchmarkDefinition, BenchmarkResultRecord, WODRecord interfaces
  - phase: 02-domain-layer-port
    provides: BenchmarkScoringType, domain types, benchmark-catalog.ts with encodeRoundsAndReps/decodeRoundsAndReps
provides:
  - Benchmark catalog screen grouped by category with custom section
  - Scoring-aware benchmark result recording (ForTime/AMRAP/MaxLoad/Distance)
  - Benchmark result history with improvement chart and PR banner
  - Custom benchmark creation form
  - WOD dashboard card component (WODDashboardCard)
  - WOD archive browser screen
  - scoring-input.ts utility (formatScore, parseTimeInput, isScoreImproved)
  - Domain-level benchmark tests (benchmarks.test.ts)
affects: [dashboard-integration, phase-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scoring-aware input: switch on BenchmarkScoringType for time/reps/roundsAndReps/weight/distance"
    - "TDD: RED (failing tests) -> GREEN (implementation) -> commit each phase separately"
    - "Disable Save/Create button for invalid input (per CLAUDE.md convention)"
    - "useFocusEffect for refreshing data on screen focus"
    - "Static export functions (buildScore, isInputValid, findBestScore) for testability without hosting view"
    - "WODDashboardCard inline expand pattern: onStart expands exercise list in place (read-only)"

key-files:
  created:
    - SundeeFundeeRN/src/components/benchmarks/scoring-input.ts
    - SundeeFundeeRN/src/components/benchmarks/__tests__/scoringInput.test.ts
    - SundeeFundeeRN/src/domain/__tests__/benchmarks.test.ts
    - SundeeFundeeRN/app/(app)/benchmarks/index.tsx
    - SundeeFundeeRN/app/(app)/benchmarks/[id].tsx
    - SundeeFundeeRN/app/(app)/benchmarks/create.tsx
    - SundeeFundeeRN/src/components/wod/WODDashboardCard.tsx
    - SundeeFundeeRN/app/(app)/wods/index.tsx
  modified: []

key-decisions:
  - "formatScore('reps', N): if N >= 10000, decode as roundsAndReps; otherwise plain reps count — handles both AMRAP and pure-rep benchmarks with same scoring type"
  - "WOD Start button expands card inline (setExpanded(true)) — WOD exercises are string[] not structured data, no workout-session integration"
  - "Benchmark improvement chart uses inverted values for time/distance (so visual 'up' means better) in ChartDataPoint.value — display-only transform, raw score stored unmodified"
  - "buildScore, isInputValid, findBestScore exported as static functions from [id].tsx — testable without mounting the component"
  - "WOD archive Record Result navigates to benchmarks/[id] with wod-{id} synthetic benchmark id — reuses benchmark recording screen without new infrastructure"

patterns-established:
  - "Scoring-aware input: switch on BenchmarkScoringType in renderScoreInput() — one case per scoring type"
  - "PR detection: findBestScore over existing results, compare with isScoreImproved after save"
  - "useFocusEffect + useState loading pattern: setLoading(true) in async loadX(), catch -> fallback, finally setLoading(false)"

requirements-completed: [BNCH-01, BNCH-02, BNCH-03, BNCH-04, WODS-01, WODS-02]

# Metrics
duration: 5min
completed: 2026-03-15
---

# Phase 05 Plan 07: Benchmark Catalog and WOD Display Summary

**Benchmark catalog with scoring-aware recording (ForTime/AMRAP/MaxLoad), PR tracking, custom creation, and WOD dashboard card + archive browser backed by Firestore**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-15T13:59:46Z
- **Completed:** 2026-03-15T14:04:46Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Benchmark catalog SectionList grouped by category with custom benchmarks section and Create FAB
- Scoring-aware result recording: MM:SS for time/distance, rounds+reps for AMRAP, weight with lbs label, plain reps for rep-based
- PR detection banner + improvement chart (ProgressChart with 2+ result guard)
- Custom benchmark creation form with picker, multiline description, radio scoring type
- WODDashboardCard with inline expand to show exercise list (read-only, no workout-session)
- WOD archive browser with date-local sorting, expand/collapse cards, Record Result linking
- 39 tests covering scoring-input utilities and domain benchmark catalog functions

## Task Commits

Each task was committed atomically:

1. **TDD RED: Failing tests** - `caf9d56` (test)
2. **Task 1: Benchmark catalog, detail/recording, custom creation, scoring-input** - `8578df4` (feat)
3. **Task 2: WOD dashboard card and archive browser** - `af86657` (feat)

## Files Created/Modified
- `SundeeFundeeRN/src/components/benchmarks/scoring-input.ts` - formatScore, parseTimeInput, isScoreImproved utilities
- `SundeeFundeeRN/src/components/benchmarks/__tests__/scoringInput.test.ts` - 23 tests for scoring utilities
- `SundeeFundeeRN/src/domain/__tests__/benchmarks.test.ts` - 16 tests for benchmark catalog domain functions
- `SundeeFundeeRN/app/(app)/benchmarks/index.tsx` - Catalog SectionList with custom section and FAB
- `SundeeFundeeRN/app/(app)/benchmarks/[id].tsx` - Detail/recording/history/chart/PR screen
- `SundeeFundeeRN/app/(app)/benchmarks/create.tsx` - Custom benchmark creation form
- `SundeeFundeeRN/src/components/wod/WODDashboardCard.tsx` - Dashboard WOD card component
- `SundeeFundeeRN/app/(app)/wods/index.tsx` - WOD archive browser with expand-in-place

## Decisions Made
- `formatScore('reps', N)`: N >= 10000 treated as encoded rounds+reps, otherwise plain reps — one scorer handles both AMRAP and rep-only benchmarks
- WOD Start expands inline (not workout-session) — WOD exercises are `string[]` plain text, not structured exercise data
- Benchmark improvement chart inverts time/distance values so visual "up" = better performance
- `buildScore`, `isInputValid`, `findBestScore` exported as static functions for unit testability
- WOD Record Result reuses `benchmarks/[id]` screen with synthetic `wod-{id}` benchmark ID

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Benchmark and WOD screens are complete but need to be wired into the tab bar layout
- WODDashboardCard needs to be integrated into the dashboard (index.tsx) with getWODRepo().getWODForDate() call
- Phase 06 (paywall/premium) can reference benchmarks as a premium feature gate

## Self-Check: PASSED

All 7 created files found on disk. All 3 task commits verified in git log.

---
*Phase: 05-differentiating-features*
*Completed: 2026-03-15*
