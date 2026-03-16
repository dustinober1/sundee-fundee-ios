---
phase: 16-thread-weight-unit-into-program-session
plan: "01"
subsystem: programs-session
tags: [weight-unit, formatting, tdd, programs, benchmarks]
dependency_graph:
  requires:
    - src/utils/formatWeight.ts
    - src/repositories/SettingsRepo.ts
    - src/domain/types/index.ts
  provides:
    - Unit-aware formatTargetWeight with optional WeightUnit param
    - Unit-aware formatScore for weight type with optional WeightUnit param
    - ProgramSessionScreen loads and threads weightUnit into ExerciseRow
  affects:
    - app/(app)/programs/session.tsx
    - src/components/programs/target-weight.ts
    - src/components/benchmarks/scoring-input.ts
tech_stack:
  added: []
  patterns:
    - TDD red-green cycle across 3 tasks
    - jest.MockedFunction refs after jest.mock() to avoid Babel hoisting TDZ
    - Optional WeightUnit param with 'lb' default for backward compatibility
key_files:
  created:
    - SundeeFundeeRN/app/(app)/programs/__tests__/session.test.tsx
  modified:
    - SundeeFundeeRN/src/components/programs/target-weight.ts
    - SundeeFundeeRN/src/components/programs/__tests__/targetWeight.test.ts
    - SundeeFundeeRN/src/components/benchmarks/scoring-input.ts
    - SundeeFundeeRN/src/components/benchmarks/__tests__/scoringInput.test.ts
    - SundeeFundeeRN/app/(app)/programs/session.tsx
decisions:
  - "[16-01]: jest.MockedFunction typed refs retrieved after import, not as const variables before jest.mock() — avoids Babel hoisting TDZ failure when factory references non-mock-prefixed variables"
  - "[16-01]: formatTargetWeight and formatScore accept optional unit: WeightUnit = 'lb' — backward compatible with all existing callers that omit the unit"
  - "[16-01]: session.tsx uses Promise.all to load settings alongside program/maxes — single await, no extra round trip"
metrics:
  duration: 4 min
  completed: "2026-03-16"
  tasks_completed: 3
  files_modified: 6
---

# Phase 16 Plan 01: Thread Weight Unit Into Program Session Summary

Thread weight unit preference into program session screen and utility functions that previously hardcoded 'lbs'. Closes the final PLAT-05 gap so ALL weight displays throughout the app respect the user's lb/kg preference.

## What Was Built

### Task 1 — Add WeightUnit param to formatTargetWeight and formatScore (TDD)

`formatTargetWeight` in `target-weight.ts` now accepts an optional `unit: WeightUnit = 'lb'` third parameter and delegates weight display to `formatWeight(weight, unit)` instead of the hardcoded template literal `` `${weight} lbs` ``.

`formatScore` in `scoring-input.ts` now accepts an optional `unit: WeightUnit = 'lb'` third parameter. The `'weight'` case now delegates to `formatWeight(score, unit)` instead of `` `${score} lbs` ``.

Both changes preserve backward compatibility — all existing callers that omit the unit param continue to receive `'lb'` formatted output with `.toFixed(1)` precision (e.g., `'225.0 lbs'` instead of `'225 lbs'`). Existing tests were updated to match the new precision.

### Task 2 — Create session.test.tsx (TDD RED)

Created `app/(app)/programs/__tests__/session.test.tsx` with 4 `ExerciseRow` weight unit rendering tests. `ExerciseRow` was exported from `session.tsx` as a minimal pre-step. Tests failed RED because `ExerciseRow` did not yet accept a `weightUnit` prop.

### Task 3 — Thread weightUnit into session.tsx (TDD GREEN)

`session.tsx` updates:
- Added `weightUnit: WeightUnit` to `ExerciseRowProps`
- Added `useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit)` in `ProgramSessionScreen`
- Extended `Promise.all` in `useFocusEffect loadData` to also call `getSettingsRepo(isGuest).getSettings(uid)` and apply `settings.weightUnit` after load
- `formatTargetWeight` call now passes `weightUnit` as the third argument
- Weight range display replaced `` `${lo}–${hi} lbs` `` with `` `${formatWeight(lo, weightUnit)}–${formatWeight(hi, weightUnit)}` ``
- `ExerciseRow` usage in render now passes `weightUnit={weightUnit}`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Jest Babel hoisting TDZ in session.test.tsx mock pattern**
- **Found during:** Task 3 (when running GREEN verification)
- **Issue:** Test file defined `const mockFormatTargetWeight = jest.fn(...)` before `jest.mock()` calls. Babel hoists `jest.mock()` to the top of the file, so the `const` variables are in TDZ when the factory runs — resulting in `(0, _targetWeight.formatTargetWeight) is not a function` at render time.
- **Fix:** Replaced with inline `jest.fn()` factories inside `jest.mock()` calls, then retrieved typed references via `const mockFormatTargetWeight = formatTargetWeight as jest.MockedFunction<typeof formatTargetWeight>` after the imports. `beforeEach` re-applies mock implementations after `clearAllMocks()`.
- **Files modified:** `app/(app)/programs/__tests__/session.test.tsx`
- **Commit:** 68ba369

## Test Results

```
Test Suites: 4 passed, 4 total
Tests:       71 passed, 71 total
```

Target test files: `targetWeight.test.ts`, `scoringInput.test.ts`, `session.test.tsx`

## Self-Check: PASSED

| Item | Status |
|------|--------|
| target-weight.ts | FOUND |
| scoring-input.ts | FOUND |
| session.tsx | FOUND |
| session.test.tsx | FOUND |
| 16-01-SUMMARY.md | FOUND |
| commit 0c6c31f (Task 1) | FOUND |
| commit ab9066b (Task 2) | FOUND |
| commit 68ba369 (Task 3) | FOUND |
