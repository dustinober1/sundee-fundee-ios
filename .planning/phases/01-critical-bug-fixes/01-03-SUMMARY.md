---
phase: 01-critical-bug-fixes
plan: 03
subsystem: ai-workout-generation
tags: [weight-units, gemini, prompt-builder, bug-fix, kg-support]
dependency_graph:
  requires: []
  provides: [unit-aware-ai-workout-prompts, weight-unit-response-schema]
  affects: [GeminiWorkoutService, OfflineWorkoutGenerator, WorkoutExecutionViewModel, WorkoutPreviewViewModel]
tech_stack:
  added: []
  patterns: [backward-compatible-decoding, unit-conversion-at-boundary, separate-equipment-lists-per-unit]
key_files:
  created: []
  modified:
    - SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift
    - SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift
    - SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift
    - SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift
    - SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift
    - SundeeFundee/Features/AIWorkout/WorkoutPreviewViewModel.swift
    - SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift
    - SundeeFundeTests/GeminiPromptBuilderTests.swift
    - SundeeFundeTests/GeminiResponseParserTests.swift
    - SundeeFundeTests/AIWorkoutTests.swift
    - SundeeFundeTests/AIWorkoutViewModelTests.swift
    - SundeeFundeTests/GeminiWorkoutServiceTests.swift
decisions:
  - "Separate native equipment lists for kg and lbs (not mathematical conversion) — real gym values per unit"
  - "GeneratedExercise.weight stores value in exercise's own unit; weightInPounds computed for snapping logic"
  - "Backward-compat decoding: reads legacy weightLb JSON key and treats as unit lb"
  - "ExerciseMax.weightLb stays unchanged — it is input context data stored as lbs, converted at prompt boundary"
  - "withSnappedWeight() converts to lbs for snapping (which uses lbs tables), then converts back to stored unit"
metrics:
  duration_minutes: 11
  completed_date: "2026-03-19"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 12
requirements_completed: [FIX-01]
---

# Phase 1 Plan 3: AI Workout Weight Unit Parameterization Summary

Unit-parameterized Gemini prompt builder with separate native kg/lbs equipment lists, GeneratedExercise model renamed from `weightLb` to `weight` + `weightUnit`, and backward-compatible response parsing.

## Tasks Completed

### Task 1: Parameterize system prompt and user prompt by weight unit

- Replaced static `systemPrompt` property with `systemPrompt(weightUnit: String)` function
- Added separate native equipment lists for kg users: 20kg bar, metric plates (25/20/15/10/5/2.5/1.25 kg), metric dumbbells (4-32 kg), metric kettlebells (8-32 kg)
- Kept lbs list unchanged (45 lb bar, standard plates, lbs dumbbells/kettlebells)
- Updated `userPrompt(from:)` to convert maxes from stored lbs to kg when unit is kg
- Updated body weight display to use user's selected unit
- Renamed response schema field `weightLb` to `weight` + added `weightUnit` field
- Updated `GeminiWorkoutService.buildRequest(from:)` to pass `context.weightUnit` to `systemPrompt`

### Task 2: Update response parser, model, and tests for weight/weightUnit fields

- Renamed `GeneratedExercise.weightLb` to `weight` with accompanying `weightUnit: String` property (defaults to "lb")
- Added `weightInPounds` computed property for snapping logic that works in lbs
- Updated `withSnappedWeight()` to convert to lbs for snapping, then back to stored unit
- Added custom `init(from decoder:)` + `encode(to:)` with backward-compat decoding: falls back to `weightLb` JSON key with unit "lb"
- Updated `GeminiResponseParser` to parse `weight` + `weightUnit` fields; falls back to legacy `weightLb` key
- Updated `OfflineWorkoutGenerator` local variable usage (still produces lbs-unit exercises via offline path)
- Fixed `WorkoutExecutionViewModel.initializeAISets()`: now correctly converts exercise weight to kg for `SetExecutionState` (was previously passing lbs to kg parameter — pre-existing bug fixed)
- Updated `WorkoutPreviewViewModel.exerciseSummary()` to convert from exercise's stored unit to kg for display conversion
- Updated all test files to use `weight:` + `weightUnit:` in `GeneratedExercise` initializers
- Updated test assertions from `.weightLb` to `.weight`
- Added new kg-specific tests in `GeminiPromptBuilderTests`
- Added backward-compat tests in `GeminiResponseParserTests`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed WorkoutExecutionViewModel passing lbs to kg-typed parameter**

- **Found during:** Task 2 (updating `initializeAISets`)
- **Issue:** `initializeAISets` passed `exercise.weightLb` directly to `prescribedWeightKg` and `actualWeightKg` — lbs value in a kg field
- **Fix:** Added proper unit-aware conversion: if `exercise.weightUnit` is kg use directly, otherwise divide by `poundsPerKilogram`
- **Files modified:** `SundeeFundee/Features/Workouts/WorkoutExecutionViewModel.swift`
- **Commit:** c423b95

### Out-of-Scope Pre-existing Failures

Discovered pre-existing test compilation errors in unrelated files:
- `SundeeFundeTests/AuthOnboardingCoverageWave5Tests.swift` — missing args for `loadGuestUserID`, `deleteGuestUserID`
- `SundeeFundeTests/AppAuthCoverageTests.swift` — main actor isolation, missing Foundation imports

These are out of scope for this plan. Logged for deferred handling.

## Verification

- `grep -rn "\.weightLb\b" SundeeFundee/` — 0 results for `GeneratedExercise` property access (only `ExerciseMax.weightLb` accesses remain, which is the input context model)
- `grep -c "systemPrompt(weightUnit:" SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift` — returns 1
- `xcodebuild build -scheme SundeeFundee` — BUILD SUCCEEDED
- Response schema contains `weight` and `weightUnit` (not `weightLb`)

## Self-Check: PASSED

- SUMMARY.md exists: YES
- Commit 662f6d0 (Task 1): FOUND
- Commit c423b95 (Task 2): FOUND
- GeminiPromptBuilder.swift: FOUND
- GeneratedWorkout.swift: FOUND
- GeminiResponseParser.swift: FOUND
- BUILD SUCCEEDED (main target)
