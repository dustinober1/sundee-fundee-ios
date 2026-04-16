---
phase: 01-recovery-score-foundation
plan: 01
subsystem: domain
tags: [recovery-score, hrv, cycle-phase, training-load, pain, tdd, pure-domain]

# Dependency graph
requires:
  - phase: existing
    provides: CyclePhase enum, WeeklyLoadAnalyzer.WeeklySummary, CompletedWorkoutRecord
provides:
  - RecoveryScoreInputs struct (5 optional fields: HRV, sleep, load, cycle phase, pain)
  - RecoveryScore result struct with total, subScores, recommendation, explanations
  - RecoveryScoreCalculator.calculate(inputs:) -> RecoveryScore? entry point
  - HRVBaselineNormalizer with per-cycle-phase normalization
  - TrainingLoadScorer with ACWR-based scoring
  - CyclePhaseScorer with phase-specific energy context
  - PainScorer with linear intensity mapping
  - TrainingRecommendation enum (pushDay, moderate, restDay)
  - RecoveryInput enum (hrv, sleep, trainingLoad, cyclePhase, pain)
affects: [01-02, 01-03, 01-04, 01-05, dashboard, healthkit, sleep-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [caseless-enum-pure-domain, weight-redistribution, phase-relative-hrv-normalization, continuous-hrv-scoring]

key-files:
  created:
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreInputs.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScore.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/HRVBaselineNormalizer.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/CyclePhaseScorer.swift
    - SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/PainScorer.swift
    - SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/RecoveryScoreCalculatorTests.swift
  modified: []

key-decisions:
  - "Continuous linear interpolation for HRV scoring bands — ensures phase normalization produces different sub-scores even within the same band"
  - "ACWR computed from workoutCount (not volume/sets) — simpler and available from existing WeeklySummary"
  - "Weight redistribution: missing inputs redistribute proportionally among present inputs"

patterns-established:
  - "Sub-scorer pattern: caseless enum with static score() returning (score: Int, explanation: String) tuple"
  - "Calculator orchestration: weighted sum with totalWeight tracking for graceful degradation"

requirements-completed: [REC-02, REC-04, REC-06]

# Metrics
duration: 11min
completed: 2026-04-15
---

# Phase 1 Plan 01: Recovery Score Calculator Summary

**Pure domain recovery score calculator with 5 sub-scorers, per-cycle-phase HRV normalization, and weight redistribution for missing inputs**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-16T01:29:29Z
- **Completed:** 2026-04-16T01:40:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- TDD cycle completed: RED (11 failing tests) then GREEN (all 11 pass)
- Recovery score calculator with graceful degradation — nil when all inputs missing, valid partial scores with redistributed weights when some inputs present
- HRV baseline normalization with per-cycle-phase multipliers (luteal 0.85, menstrual 0.90, ovulation 1.05, follicular 1.0)
- All domain types conform to Sendable and Equatable with zero framework dependencies

## Task Commits

Each task was committed atomically:

1. **Task 1: Define recovery score domain types and write failing tests** - `f38e29e2` (test)
2. **Task 2: Implement all sub-scorers and calculator to make tests green** - `2f30ec79` (feat)

## TDD Gate Compliance

- RED gate: `test(01-01)` commit `f38e29e2` — 11 tests, 14 failures, project compiles
- GREEN gate: `feat(01-01)` commit `2f30ec79` — 11 tests, 0 failures
- No REFACTOR gate needed — implementation is clean

## Files Created/Modified
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreInputs.swift` - Input struct with 5 optional fields
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScore.swift` - Result struct, TrainingRecommendation enum, RecoveryInput enum
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/RecoveryScoreCalculator.swift` - Orchestrator with weight redistribution
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/HRVBaselineNormalizer.swift` - Per-phase HRV normalization with continuous scoring
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift` - ACWR-based training load scoring
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/CyclePhaseScorer.swift` - Phase-specific energy/recovery context
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/PainScorer.swift` - Linear pain intensity mapping
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/RecoveryScoreCalculatorTests.swift` - 11 test cases covering all scoring dimensions

## Decisions Made
- Used continuous linear interpolation within HRV scoring bands instead of flat thresholds — ensures phase normalization produces visible score differences within the same band (e.g., 42ms luteal scores higher than 42ms follicular)
- ACWR computed from workoutCount rather than volume/sets — simpler and uses existing WeeklySummary data without requiring additional fields
- Default training load score of 75 when insufficient data (< 2 weeks) — moderate default avoids penalizing new users

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Changed HRV scoring from flat bands to continuous linear interpolation**
- **Found during:** Task 2 (GREEN phase implementation)
- **Issue:** With flat scoring bands, 42ms luteal (normalized to 49.41) and 42ms follicular (42.0) both fell in the 40-60 band and scored 55, failing the HRV normalization test
- **Fix:** Replaced flat band thresholds with linear interpolation within each band (40-60ms maps to 30-60 score continuously), so normalization differences produce different scores
- **Files modified:** HRVBaselineNormalizer.swift
- **Verification:** All 11 tests pass including testCalculate_LutealHRV_NormalizesHigherThanFollicular
- **Committed in:** 2f30ec79 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Fix was necessary for test correctness — plan specified the test behavior, implementation needed adjustment to honor it. No scope creep.

## Issues Encountered
None beyond the HRV scoring deviation documented above.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All types and contracts are ready for downstream plans (01-02 through 01-05)
- RecoveryScore, RecoveryScoreInputs, and RecoveryScoreCalculator are the public API that UI and data layer plans will consume
- HRV normalization is phase-aware — plans integrating HealthKit sleep data should follow the same pattern of accepting optional inputs

## Self-Check: PASSED

- All 9 created files verified present
- Both commits verified in git log: f38e29e2 (RED), 2f30ec79 (GREEN)
- All 11 tests passing

---
*Phase: 01-recovery-score-foundation*
*Completed: 2026-04-15*
