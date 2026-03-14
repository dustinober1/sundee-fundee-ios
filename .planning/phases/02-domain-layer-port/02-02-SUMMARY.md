---
phase: 02-domain-layer-port
plan: 02
subsystem: domain/cycle
tags: [domain, cycle, calculations, adaptation, typescript, tdd, parity, date-fns]
dependency_graph:
  requires:
    - src/domain/types/index.ts (shared domain interfaces — from Plan 02-01)
    - date-fns (installed in Plan 02-01)
  provides:
    - src/domain/cycle/ (fully ported cycle subdomain)
    - src/domain/cycle/index.ts (barrel re-export)
  affects:
    - All UI and repository layers that consume cycle phase data
    - Plan 02-03 (injury domain) can now import ReadinessTier from types
tech_stack:
  added: []
  patterns:
    - TDD (RED → GREEN) for all cycle implementations
    - date-fns for all calendar arithmetic (startOfDay/differenceInCalendarDays/addDays)
    - Pure functions — no input mutation throughout
    - Barrel re-export pattern for cycle subdomain
    - Discriminated union ExerciseValue scaling with Math.max(1,...) floor
key_files:
  created:
    - SundeeFundeeRN/src/domain/cycle/cycle-calculations.ts
    - SundeeFundeeRN/src/domain/cycle/cycle-adaptation-policy.ts
    - SundeeFundeeRN/src/domain/cycle/cycle-program-generator.ts
    - SundeeFundeeRN/src/domain/cycle/index.ts
    - SundeeFundeeRN/src/domain/__fixtures__/cycle-calculations.json
    - SundeeFundeeRN/src/domain/__fixtures__/cycle-adaptation.json
    - SundeeFundeeRN/src/domain/__tests__/cycle.test.ts
  modified:
    - SundeeFundeeRN/src/domain/types/index.ts (added bodyweightOnly to ProgramExercise)
decisions:
  - blendMultiplier formula matches Swift exactly: clamp(1.0 + (target - 1.0) * rs * cs, 0.75, 1.25)
  - ProgramExercise.sets is number (not ExerciseValue) — scaleSets wraps swiftRound with Math.max(1,...) floor
  - ProgramExercise.weight (ExerciseValue) replaces Swift percent1RM (Double) — RN model uses absolute weights
  - adaptProgram always adapts (no adaptationEnabled guard) — caller controls whether to invoke
  - resolveConfidence exported from cycle-program-generator for direct testability
  - bodyweightOnly optional field added to ProgramExercise to unblock pre-existing tsc error from Plan 02-03 RED tests
metrics:
  duration: 9 min
  completed_date: "2026-03-14"
  tasks_completed: 2
  files_created: 7
  files_modified: 1
  tests_added: 71
---

# Phase 02 Plan 02: Cycle Domain Port Summary

**One-liner:** 3 cycle domain files ported from Swift — phase inference via date-fns, load/rep blending with readiness tiers, full program adaptation pipeline — 71 tests, 100% line/branch/function coverage on all implementation files.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Port CycleCalculations with date-fns parity | 3ecbfb2 | cycle-calculations.ts, cycle-calculations.json, cycle.test.ts |
| 2 | Port CycleAdaptationPolicy and CycleProgramGenerator with readiness integration | 86a310c | cycle-adaptation-policy.ts, cycle-program-generator.ts, index.ts, cycle-adaptation.json, types/index.ts |

## Artifacts Produced

### src/domain/cycle/cycle-calculations.ts
Phase inference and cycle status calculation:
- `getPhaseBoundaries(settings)` — computes start/end cycle-day for each of 4 phases
- `inferCurrentPhase(cycleDay, settings)` — maps cycle-day number to CyclePhase
- `calculateCycleStatus(periodLogs, settings, referenceDate?)` — full status result with cycleDay, daysUntilNextPhase, predictedNextPeriod, phase date bounds
- `getPhaseRecommendation(phase)` — informational training guidance per phase
- Exact parity with Swift Calendar.current via date-fns startOfDay/differenceInCalendarDays/addDays

### src/domain/cycle/cycle-adaptation-policy.ts
Phase-aware load/set/rep multiplier engine:
- `blendMultiplier(target, readinessScale, confidenceScale)` — `clamp(1 + (target-1)*rs*cs, 0.75, 1.25)`
- `resolveReadinessTier(readinessScore?)` — maps 1-10 score to low/neutral/high tier
- `resolveConfidenceScale(confidence, lowConfidenceScale?)` — maps confidence tier to scale factor
- `applyPhaseAdjustment(exercise, phase, readinessTier, confidence)` — adapts sets/reps/weight
- Phase multiplier tables: menstrual (0.90/0.90/0.90), follicular (1.00/1.00/1.00), ovulation (1.12/1.05/0.95), luteal (0.97/0.95/0.92)

### src/domain/cycle/cycle-program-generator.ts
Full program adaptation pipeline:
- `adaptProgram(program, periodLogs, settings, referenceDate?, readinessScore?)` — adapts all sessions
- Derives confidence from period log count and recency (mirrors Swift resolveConfidence)
- Falls back to 'follicular' with low confidence when no cycle data available

### src/domain/cycle/index.ts
Barrel re-export of all public cycle API.

### Parity Fixtures
- `cycle-calculations.json`: 3 boundary fixtures (28/21/35-day cycles) + 7 phase-inference fixtures
- `cycle-adaptation.json`: 8 blendMultiplier cases (including clamping edges) + 9 readinessTier cases

## Verification Results

```
TypeScript: PASS (npx tsc --noEmit — zero errors)
Tests: 71 passed, 0 failed
Coverage (cycle/ line):     100% on all implementation files
Coverage (cycle/ branch):   100% on all implementation files
Coverage (cycle/ function): 100% on all implementation files
Phase boundary fixture cases: 3/3 pass
Phase inference fixture cases: 7/7 pass
blendMultiplier clamping: [0.75, 1.25] verified for both extremes
Barrel import: import { calculateCycleStatus, applyPhaseAdjustment, adaptProgram } from 'src/domain/cycle' resolves
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing TS2339 type error in injury.test.ts**
- **Found during:** Task 2 — overall verification `npx tsc --noEmit`
- **Issue:** Plan 02-03 RED-phase tests (committed in f8fe3eb) reference `exercise.bodyweightOnly` which did not exist on ProgramExercise interface
- **Fix:** Added `bodyweightOnly?: boolean` optional field to `ProgramExercise` in `types/index.ts`
- **Files modified:** `src/domain/types/index.ts`
- **Commit:** 86a310c

**2. [Architectural Note] RN ProgramExercise differs from Swift ProgramExercise**
- **Found during:** Task 2 — porting applyPhaseAdjustment
- **Issue:** Swift uses `percent1RM: Double?` for load; RN uses `weight?: ExerciseValue` (absolute weight values)
- **Fix:** Port adapted to use `weight` field scaling (ExerciseValue) instead of percent1RM multiplication — matches RN data model correctly
- **Files modified:** `cycle-adaptation-policy.ts` (uses weight instead of percent1RM)

## Self-Check: PASSED

Files verified present:
- FOUND: SundeeFundeeRN/src/domain/cycle/cycle-calculations.ts
- FOUND: SundeeFundeeRN/src/domain/cycle/cycle-adaptation-policy.ts
- FOUND: SundeeFundeeRN/src/domain/cycle/cycle-program-generator.ts
- FOUND: SundeeFundeeRN/src/domain/cycle/index.ts
- FOUND: SundeeFundeeRN/src/domain/__fixtures__/cycle-calculations.json
- FOUND: SundeeFundeeRN/src/domain/__fixtures__/cycle-adaptation.json
- FOUND: SundeeFundeeRN/src/domain/__tests__/cycle.test.ts

Commits verified:
- 3ecbfb2: feat(02-02): port CycleCalculations with date-fns parity and 100% coverage
- 86a310c: feat(02-02): port CycleAdaptationPolicy, CycleProgramGenerator, barrel exports — 100% coverage
