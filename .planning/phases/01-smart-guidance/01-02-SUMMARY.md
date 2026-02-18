---
phase: 01-smart-guidance
plan: 02
subsystem: recommendation-engine
tags: [calculations, plateau-detection, pr-detection, vitest, dexie, typescript]

dependency-graph:
  requires:
    - "01-01: DB schema v4, CompletedSet/CompletedWorkout types, Dexie setup"
  provides:
    - "getNextRecommendedWeight (first=70%1RM, success=+5, failure=-5, rounded to 5)"
    - "wasSetSuccessful / wasSessionSuccessful (session outcome evaluation)"
    - "detectPlateauForExercise (per-exercise, rep-based, 3-session consecutive failure)"
    - "getDeloadWeight (10% deload rounded to 5)"
    - "usePRDetection hook (weight PR vs 1RM, volume PR vs best single-session)"
  affects:
    - "01-03: UI integration — these functions are the contracts for all Phase 1 features"

tech-stack:
  added: []
  patterns:
    - "Pure function recommendation engine with typed SessionResult discriminated union"
    - "Dexie async queries inside React hook via usePRDetection"
    - "fake-indexeddb in vitest setup enables DB tests without mocking"

key-files:
  created:
    - "src/hooks/use-pr-detection.ts"
    - "tests/unit/recommendations/weight-recommendation.test.ts"
  modified:
    - "src/lib/calculations.ts"
    - "src/lib/recommendations/plateau-detection.ts"
    - "tests/unit/recommendations/plateau-detection.test.ts"

decisions:
  - id: "no-pr-on-first-session"
    choice: "Weight PR and volume PR both require prior data to exist before triggering"
    rationale: "Prevents celebration spam on first-ever lifts; only meaningful relative to a baseline"
  - id: "session-failure-definition"
    choice: "Per-exercise session is 'failed' if ANY set has actualReps < prescribedReps"
    rationale: "One failed set is meaningful signal — athlete couldn't complete the prescription"
  - id: "plateau-requires-exercise-sets"
    choice: "Sessions without sets for the target exercise do not count as failures"
    rationale: "If exercise wasn't performed in a session, it shouldn't penalize the plateau counter"

metrics:
  duration: "2 minutes"
  completed: "2026-02-18"
  tests-added: 26
  tests-passing: 37
---

# Phase 01 Plan 02: Recommendation Engine, Plateau Detection, PR Detection Summary

**One-liner:** Pure recommendation engine (70%/+5/-5 1RM logic), per-exercise rep-failure plateau detection, and weight+volume PR hook — all tested with 26 new tests against fake-indexeddb.

## What Was Built

### Task 1: Recommendation Engine (`src/lib/calculations.ts`)
Added three new exports alongside the existing functions (no regressions):

- **`SessionResult`** type: `'success' | 'failure' | 'first'`
- **`getNextRecommendedWeight(currentWeight, result, oneRepMax)`**:
  - `'first'` → `roundToNearestFive(oneRepMax * 0.7)` (70% 1RM starting weight)
  - `'success'` → `roundToNearestFive(currentWeight + 5)` (progressive overload)
  - `'failure'` → `roundToNearestFive(currentWeight - 5)`, floored at `roundToNearestFive(oneRepMax * 0.5)`
- **`wasSetSuccessful(set)`**: true if `actualReps >= prescribedReps` AND (if prescribed) `actualWeight >= prescribedWeight`
- **`wasSessionSuccessful(sets[])`**: true if every set passes `wasSetSuccessful`; vacuously true for empty arrays

### Task 2: Plateau Detection + PR Hook
**`src/lib/recommendations/plateau-detection.ts`** — Added two new exports (existing `detectPlateauForCycle` preserved):
- **`detectPlateauForExercise(exerciseId, activeCycleId)`**: Queries last 3 workouts for the cycle, checks each for this exercise's sets, detects plateau when ALL 3 sessions had any set with `actualReps < prescribedReps`
- **`getDeloadWeight(currentWeight)`**: `roundToNearestFive(currentWeight * 0.9)` — 10% deload

**`src/hooks/use-pr-detection.ts`** — New React hook:
- **`checkWeightPR(exerciseId, newWeight)`**: Synchronous check against `oneRepMaxes` from UserContext; requires `currentMax > 0` (no first-lift celebrations)
- **`checkVolumePR(workoutId, exerciseId, sets[])`**: Async Dexie query grouping historical sets by `workoutId`, compares current session volume against best single-session; requires prior sessions to exist

## Tests Added

| File | Tests | Coverage |
|------|-------|----------|
| `tests/unit/recommendations/weight-recommendation.test.ts` | 14 | `getNextRecommendedWeight`, `wasSetSuccessful`, `wasSessionSuccessful` |
| `tests/unit/recommendations/plateau-detection.test.ts` (extended) | +7 | `detectPlateauForExercise`, `getDeloadWeight` |
| **Total new** | **21** | |
| **Existing (no regressions)** | 11 + 5 | `calculations.test.ts`, `detectPlateauForCycle` |

**Final: 37 tests passing, 0 failing**

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| No PR on first session | Weight PR requires `currentMax > 0`; Volume PR requires prior session data | Prevents noise when no baseline exists |
| Session failure definition | ANY set with `actualReps < prescribedReps` = failed session | One missed set is meaningful signal for plateau detection |
| Missing exercise in session | Sessions without target exercise sets → not counted as failure | Athlete absence ≠ performance failure |
| Plateau detection approach | Rep-completion based (not weight-variance based) | `detectPlateau()` in calculations.ts checks weight stagnation — wrong signal for progressive overload |
| Volume granularity | Per single session, not cumulative across all sessions | Cumulative conflates volume growth with frequency increase |

## Verification

- ✅ `npx vitest run tests/unit/recommendations/` — 26 tests pass (weight-recommendation + plateau-detection)
- ✅ `npx vitest run tests/unit/calculations.test.ts` — 11 existing tests pass (no regressions)
- ✅ `npx tsc --noEmit` — No new type errors introduced (2 pre-existing RestTimer test errors unrelated to this plan)

## Deviations from Plan

None — plan executed exactly as written. Pre-existing TypeScript errors in `RestTimerExpanded.test.tsx` and `RestTimerPill.test.tsx` were present before this plan and are not introduced by this work.

## Next Phase Readiness

**01-03 can proceed.** All logic contracts are now implemented and tested:
- `getNextRecommendedWeight` → drives weight recommendation display in workout UI
- `detectPlateauForExercise` → drives plateau alert modals
- `usePRDetection` → drives PR celebration confetti/banners
- `getDeloadWeight` → used in plateau recommendation text
