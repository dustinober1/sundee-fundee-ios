---
phase: 02-domain-layer-port
plan: 04
subsystem: domain/ai-workout,domain/history,domain/readiness,domain/benchmarks,domain/shared
tags: [domain, ai-workout, offline-generator, benchmarks, readiness, history, shared, tdd, parity]
dependency_graph:
  requires:
    - src/domain/types/index.ts (updated WorkoutFocus, EnergyLevel, EquipmentAccess, BenchmarkScoringType)
    - src/domain/calculations/ (snapBarbellWeightLb, snapDumbbellWeightLb, roundToNearestFive)
    - date-fns (ProgramAvailability date arithmetic)
  provides:
    - src/domain/ai-workout/ (GeneratedWorkout, GeneratedExercise, WorkoutGenerationContext, OfflineWorkoutGenerator)
    - src/domain/history/ (HistoryItem discriminated union)
    - src/domain/readiness/ (calculateReadinessScore, tierFromScore, pure scoring functions)
    - src/domain/benchmarks/ (BENCHMARK_CATALOG 26 entries, encodeRoundsAndReps, decodeRoundsAndReps)
    - src/domain/shared/ (CelebrationEvent, ProgramAvailability, WODTemplateType)
    - src/domain/index.ts (top-level barrel for all 7 subdomains)
  affects:
    - Phase 3 repository layer imports from src/domain barrel
    - Phase 4+ features import domain types and functions via top-level barrel
tech_stack:
  added: []
  patterns:
    - Discriminated union for CelebrationEvent and HistoryItemSource (kind discriminant)
    - Pure functions replacing Swift computed properties and static methods
    - TDD (RED → GREEN) for all implementations
    - date-fns for ProgramAvailability date arithmetic (already installed from 02-01)
    - roundsAndReps encoding: rounds * 10000 + reps (per CLAUDE.md and locked decision)
key_files:
  created:
    - SundeeFundeeRN/src/domain/ai-workout/generated-workout.ts
    - SundeeFundeeRN/src/domain/ai-workout/offline-workout-generator.ts
    - SundeeFundeeRN/src/domain/ai-workout/workout-generation-context.ts
    - SundeeFundeeRN/src/domain/ai-workout/index.ts
    - SundeeFundeeRN/src/domain/history/history-item.ts
    - SundeeFundeeRN/src/domain/history/index.ts
    - SundeeFundeeRN/src/domain/readiness/readiness-survey.ts
    - SundeeFundeeRN/src/domain/readiness/index.ts
    - SundeeFundeeRN/src/domain/benchmarks/benchmark-catalog.ts
    - SundeeFundeeRN/src/domain/benchmarks/index.ts
    - SundeeFundeeRN/src/domain/shared/celebration-event.ts
    - SundeeFundeeRN/src/domain/shared/program-availability.ts
    - SundeeFundeeRN/src/domain/shared/wod-template-type.ts
    - SundeeFundeeRN/src/domain/shared/index.ts
    - SundeeFundeeRN/src/domain/index.ts
    - SundeeFundeeRN/src/domain/__fixtures__/benchmark-scoring.json
    - SundeeFundeeRN/src/domain/__tests__/ai-workout.test.ts
    - SundeeFundeeRN/src/domain/__tests__/shared.test.ts
  modified:
    - SundeeFundeeRN/src/domain/types/index.ts (WorkoutFocus, EnergyLevel, EquipmentAccess, BenchmarkScoringType updated to match Swift raw values)
decisions:
  - WorkoutFocus updated to match Swift raw values (upper_body, lower_body, full_body, push, pull, core, conditioning, strength, olympic_lifts, gymnastics, mobility, stretching)
  - EnergyLevel updated to match Swift (low/medium/high — medium not moderate)
  - EquipmentAccess updated to match Swift raw values (full_gym, home_dumbbells, hotel_gym, bodyweight_only, outdoor)
  - BenchmarkScoringType updated to match Swift (time/reps/weight/distance/roundsAndReps)
  - ReadinessSurvey saveTodayResult/loadTodayResult intentionally omitted — storage belongs in Phase 3 repository layer (research pitfall 6)
  - ProgramAvailability uses date-fns parseISO + startOfDay for timezone-safe comparison
  - Tests use new Date(year, monthIndex, day) constructors (not ISO strings) to avoid UTC-vs-local timezone issues
metrics:
  duration: 13 min
  completed_date: "2026-03-14"
  tasks_completed: 2
  files_created: 18
  files_modified: 1
  tests_added: 197
---

# Phase 02 Plan 04: Remaining Domain Modules Port Summary

**One-liner:** 9 Swift domain files ported to TypeScript (AI workout pipeline, HistoryItem, ReadinessSurvey scoring, 26-entry BenchmarkCatalog, CelebrationEvent, ProgramAvailability, WODTemplateType) with top-level barrel completing the full domain layer.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Port AI workout, history, readiness, and benchmarks | c595217 | 12 files — generated-workout.ts, offline-workout-generator.ts, workout-generation-context.ts, history-item.ts, readiness-survey.ts, benchmark-catalog.ts, 4 index barrels, benchmark-scoring.json, ai-workout.test.ts |
| 2 | Port shared modules and create top-level domain barrel | c4e2615 | 6 files — celebration-event.ts, program-availability.ts, wod-template-type.ts, shared/index.ts, domain/index.ts, shared.test.ts |

## Artifacts Produced

### src/domain/ai-workout/

**offline-workout-generator.ts** (~200 lines): Template selection pipeline with 6 focus pools (upper/lower/push/pull/core/conditioning), equipment filtering (fullGym/homeDumbbells/hotelGym/bodyweight/outdoor), time scaling (minimum 3 exercises), weight application from 1RM percentages, energy level adjustment, injury substitution table, cycle phase adjustment, coaching summary builder. Exports `generateOfflineWorkout`, `selectTemplates`, `filterForEquipment`, `scaleForTime`, `applyWeights`, `applyEnergyLevel`, `buildCoachingSummary`, `defaultPercentage`.

**generated-workout.ts**: `GeneratedWorkout` and `GeneratedExercise` interfaces + pure functions: `getEquipmentType`, `totalEstimatedMinutes`, `extractMuscleGroups`, `stripHealthReferences`, `strippedForSharing`.

**workout-generation-context.ts**: `WorkoutGenerationContext`, `ExerciseMax`, `InjurySummary`, `QuestionnaireAnswers` interfaces.

### src/domain/benchmarks/benchmark-catalog.ts

26-entry predefined catalog matching Swift sort order exactly. Categories: Classic WODs (9), Strength (6), Endurance (4), Gymnastics (4), General Fitness (3). Exports `BENCHMARK_CATALOG`, `encodeRoundsAndReps`, `decodeRoundsAndReps`, `getBenchmarkCategoryGroups`.

**roundsAndReps encoding:** `rounds * 10000 + reps` per CLAUDE.md spec. `encodeRoundsAndReps(3, 15) === 30015`, `decodeRoundsAndReps(30015) === { rounds: 3, reps: 15 }`.

### src/domain/readiness/readiness-survey.ts

Pure scoring functions only (storage intentionally omitted):
- `calculateReadinessScore(sleep, stress, soreness)`: weights 0.4/0.3/0.3, inverts stress and soreness, clamps to [0,10]
- `tierFromScore(score)`: score ≤3 → low, score ≥8 → high, else neutral
- `blendWithHealthKit(survey, hk)`: 70/30 blend
- `tierDisplayName`, `tierStringForAI`, `adjustmentBannerText`

### src/domain/history/history-item.ts

`HistoryItem` interface with `HistoryItemSource` discriminated union (`{ kind: 'aiWorkout' }` | `{ kind: 'program'; name: string }`). `getSourceLabel` pure function.

### src/domain/shared/

- **celebration-event.ts**: `CelebrationEvent` discriminated union (5 variants), `getCelebrationTitle`, `getCelebrationSubtitle` with all scoring type formatters
- **program-availability.ts**: `getProgramAvailability`, `sortedPrograms`, `nextUpcomingProgram`, `parseProgramDate`, `formatProgramStartDate` using date-fns
- **wod-template-type.ts**: `WODTemplateType` string union, `wodTemplateTypeFrom`, `wodTemplateTypeDisplayName`, `wodTemplateTypeRequiresTimer`

### src/domain/index.ts

Top-level barrel re-exporting all 7 subdomains. `import { estimated1RM, generateOfflineWorkout, BENCHMARK_CATALOG, calculateReadinessScore } from 'src/domain'` resolves.

## Verification Results

```
TypeScript: PASS (npx tsc --noEmit — zero errors)
Tests: 564 passed, 0 failed (across all 5 domain test suites)
  - calculations.test.ts: 169 tests (pre-existing, still pass)
  - cycle.test.ts: passes (pre-existing)
  - injury.test.ts: passes (pre-existing)
  - ai-workout.test.ts: 147 tests (new)
  - shared.test.ts: 50 tests (new)
Coverage (line): 100% on all implementation files (excluding barrel index.ts files)
roundsAndReps: encodeRoundsAndReps(3, 15) === 30015, decodeRoundsAndReps(30015) === { rounds: 3, reps: 15 }
Benchmark catalog: 26 entries, Fran first (sortOrder: 0), matches Swift order
Readiness: calculateReadinessScore pure (no storage), tierFromScore score≤3→low, score≥8→high
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated types/index.ts to match Swift raw enum values**
- **Found during:** Task 1 setup
- **Issue:** Existing `WorkoutFocus = 'strength' | 'hypertrophy' | 'endurance' | 'power' | 'mobility'` and `EnergyLevel = 'low' | 'moderate' | 'high'` and `EquipmentAccess = 'full' | 'limited' | 'home' | 'none'` didn't match the Swift enum raw values used in `WorkoutGenerationContext.swift` and `OfflineWorkoutGenerator.swift`. Also `BenchmarkScoringType` had wrong values.
- **Fix:** Updated all 4 types to match Swift raw values exactly. Added `workoutFocusDisplayName()` helper. Extended `Program` interface with optional `startDate`/`endDate` fields for `ProgramAvailability`.
- **Files modified:** `SundeeFundeeRN/src/domain/types/index.ts`
- **Impact:** Types now match wire format, no serialization issues

**2. [Rule 1 - Bug] Fixed date comparison timezone issue in tests**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** `new Date('2026-03-14')` creates UTC midnight, but `startOfDay` operates in local timezone, causing "start today" tests to return 'upcoming' in non-UTC timezones
- **Fix:** Changed test date constructors from ISO strings to `new Date(year, monthIndex, day)` for local-timezone date construction
- **Files modified:** `SundeeFundeeRN/src/domain/__tests__/shared.test.ts`

**3. [Rule 1 - Bug] Replaced dynamic imports in barrel tests with static imports**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** `await import('../index')` fails with "dynamic import callback was invoked without --experimental-vm-modules"
- **Fix:** Converted all dynamic imports in the top-level barrel test section to static imports
- **Files modified:** `SundeeFundeeRN/src/domain/__tests__/shared.test.ts`

## Self-Check: PASSED

Files verified present:
- FOUND: SundeeFundeeRN/src/domain/ai-workout/offline-workout-generator.ts
- FOUND: SundeeFundeeRN/src/domain/benchmarks/benchmark-catalog.ts
- FOUND: SundeeFundeeRN/src/domain/readiness/readiness-survey.ts
- FOUND: SundeeFundeeRN/src/domain/index.ts
- FOUND: SundeeFundeeRN/src/domain/history/history-item.ts
- FOUND: SundeeFundeeRN/src/domain/shared/celebration-event.ts
- FOUND: SundeeFundeeRN/src/domain/shared/program-availability.ts
- FOUND: SundeeFundeeRN/src/domain/shared/wod-template-type.ts

Commits verified:
- c595217: feat(02-04): port ai-workout, history, readiness, benchmarks subdomains
- c4e2615: feat(02-04): port shared modules and create top-level domain barrel
