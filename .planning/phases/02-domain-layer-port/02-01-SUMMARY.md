---
phase: 02-domain-layer-port
plan: 01
subsystem: domain/calculations
tags: [domain, calculations, epley, weight, typescript, tdd, parity]
dependency_graph:
  requires: []
  provides:
    - src/domain/types/index.ts (shared domain interfaces for all downstream plans)
    - src/domain/calculations/ (fully ported calculations subdomain)
  affects:
    - All future domain plans depend on types/index.ts
    - Future repository and feature layers consume calculations exports
tech_stack:
  added:
    - date-fns (installed, available for future domain plans)
  patterns:
    - TDD (RED → GREEN) for all calculation implementations
    - Barrel re-export pattern for calculations subdomain
    - Discriminated union for ExerciseValue (kind discriminant)
    - String unions instead of TypeScript enums (per architecture research)
    - Pure functions (no input mutation) throughout
key_files:
  created:
    - SundeeFundeeRN/src/domain/types/index.ts
    - SundeeFundeeRN/src/domain/calculations/epley-formula.ts
    - SundeeFundeeRN/src/domain/calculations/weight-calculations.ts
    - SundeeFundeeRN/src/domain/calculations/plate-calculation.ts
    - SundeeFundeeRN/src/domain/calculations/weight-unit-conversion.ts
    - SundeeFundeeRN/src/domain/calculations/barbell-defaults.ts
    - SundeeFundeeRN/src/domain/calculations/index.ts
    - SundeeFundeeRN/src/domain/__fixtures__/epley-formula.json
    - SundeeFundeeRN/src/domain/__fixtures__/weight-calculations.json
    - SundeeFundeeRN/src/domain/__tests__/calculations.test.ts
  modified:
    - SundeeFundeeRN/package.json (date-fns added)
    - SundeeFundeeRN/package-lock.json
decisions:
  - Equidistant snap ties break toward first match (matching Swift min(by:) strict-less-than semantics)
  - index.ts barrel file shows 0% jest coverage — pure re-exports have no executable statements, this is expected
  - swiftRound uses Math.sign * Math.round(Math.abs) for half-away-from-zero parity with Swift's .rounded()
  - Locale-dependent formatting intentionally omitted from weight-unit-conversion.ts (belongs in UI layer)
  - snapBarbellWeightKg uses 5 kg total steps (2.5 kg per side) matching Swift pattern
metrics:
  duration: 6 min
  completed_date: "2026-03-14"
  tasks_completed: 2
  files_created: 10
  files_modified: 2
  tests_added: 169
---

# Phase 02 Plan 01: Calculations Subdomain Port Summary

**One-liner:** 5 calculation files ported from Swift with exact numeric parity (Epley formula, barbell snapping, plate math, unit conversion, barbell defaults) — 79 fixture-driven tests pass to 4 decimal places, 100% line coverage.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Install date-fns, shared domain types, fixtures | e65a5f1 | types/index.ts, 2 fixture JSONs, package.json |
| 2 | Port calculations subdomain with 100% test coverage | 318439c | 5 calculation files, index.ts barrel, calculations.test.ts |

## Artifacts Produced

### src/domain/types/index.ts
All shared domain interfaces and union types:
- `WeightUnit`, `CyclePhase`, `RecoveryPhase`, `BodyLocation` string unions
- `ExerciseValue` discriminated union (`kind: 'fixed' | 'range' | 'amrap' | 'text'`)
- `RECOVERY_PHASE_ORDER` ordered array
- `Gender`, `WorkoutFocus`, `EnergyLevel`, `EquipmentAccess`, `ReadinessTier`
- `InjuryProfile`, `PainLog`, `PeriodLog`, `CycleSettings` interfaces
- `ProgramExercise`, `ProgramSession`, `Program`, `WorkoutTemplate` interfaces
- `BenchmarkDefinition`, `BenchmarkScoringType`
- `scaleExerciseValue`, `clamp`, `swiftRound` utility functions

### src/domain/calculations/
- `epley-formula.ts` — `estimated1RM(weight, reps)`, `isPR(newEstimate, currentMax?)`
- `weight-calculations.ts` — `roundToNearestFive`, `snapBarbellWeightLb/Kg`, `snapDumbbell/KettlebellWeightLb`, `calculateTargetWeight`, `isPersonalRecord`, `calculateVolumeLoad`, `detectPlateau`
- `weight-unit-conversion.ts` — `lbToKg`, `kgToLb`, `valueFromKilograms`, `kilogramsFrom` (POUNDS_PER_KG = 2.2046226218)
- `plate-calculation.ts` — `platesPerSideLb`, `platesPerSideKg` with lb-equivalent plate denominations
- `barbell-defaults.ts` — `barbellPresets` (Standard/Women's/Training/EZ Curl), `suggestedPresetName`
- `index.ts` — barrel re-export of all public API

### Parity Fixtures
- 79-case Epley formula fixture covering weights [45–405] × reps [1–20]
- Weight-calculations fixture for roundToNearestFive, snapBarbellWeightLb, isPersonalRecord, plateCalculation225lb

## Verification Results

```
TypeScript: PASS (npx tsc --noEmit — zero errors)
Tests: 169 passed, 0 failed
Coverage (calculations/ line): 100% on all implementation files
Epley parity: 79 fixture cases pass to 4 decimal places (toBeCloseTo(expected, 4))
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test expectations for tie-breaking in snap functions**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** Three test cases assumed wrong tie-breaking direction for `snapDumbbellWeightLb(60)`, `snapKettlebellWeightLb(20)`, and `suggestedPresetName` for non-compound exercises
- **Fix:** Corrected test expectations to match Swift `min(by:)` strict-less-than tie-breaking (first match wins when distances are equal)
- **Files modified:** `src/domain/__tests__/calculations.test.ts`

**2. [Rule 1 - Bug] Contradictory test for suggestedPresetName**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** One test asserted `Calf Raises + female → Women's` while the immediately following test correctly asserted `Standard`. The correct behavior is Standard (no compound keyword match).
- **Fix:** Merged into single consistent test, removed contradictory assertion
- **Files modified:** `src/domain/__tests__/calculations.test.ts`

None — plan executed with only minor test expectation corrections during TDD GREEN phase. All implementation files match Swift source exactly.

## Self-Check: PASSED

Files verified present:
- FOUND: SundeeFundeeRN/src/domain/types/index.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/epley-formula.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/weight-calculations.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/plate-calculation.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/weight-unit-conversion.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/barbell-defaults.ts
- FOUND: SundeeFundeeRN/src/domain/calculations/index.ts
- FOUND: SundeeFundeeRN/src/domain/__fixtures__/epley-formula.json
- FOUND: SundeeFundeeRN/src/domain/__tests__/calculations.test.ts

Commits verified:
- e65a5f1: feat(02-01): install date-fns, shared domain types, parity fixtures
- 318439c: feat(02-01): port calculations subdomain with 100% line coverage
