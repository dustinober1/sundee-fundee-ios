---
phase: 01-smart-guidance
plan: 01
subsystem: data-persistence
tags: [dexie, indexeddb, workout-tracking, radix-ui, tooltip, typescript]

dependency-graph:
  requires: []
  provides:
    - CompletedWorkout and CompletedSets persisted to IndexedDB on workout completion
    - PersonalRecord type and DB table ready for PR tracking
    - WeightOverrideReason type for future override-reason UX
    - Four new DB query functions for Phase 1 features
    - Radix UI Tooltip component wrapper
    - TooltipProvider in app tree
  affects:
    - "01-02: Recommendations engine (needs getLastCompletedSetsForExercise)"
    - "01-03: Plateau detection (needs getCompletedWorkoutsForCycle)"
    - "01-04: PR tracking (needs savePersonalRecord, getPersonalRecordsForExercise)"
    - "Any component using Tooltip (TooltipProvider now in tree)"

tech-stack:
  added: []
  patterns:
    - "Dexie versioned schema migration (version 4)"
    - "CollectedSetData interface for per-set workout data collection"
    - "async onComplete handler pattern in Next.js page component"
    - "Radix UI component re-export pattern (shadcn-style)"

key-files:
  created:
    - src/components/ui/tooltip.tsx
  modified:
    - src/types/workout.ts
    - src/lib/db/dexie.ts
    - src/lib/db/index.ts
    - src/app/workout/[id]/page.tsx
    - src/components/program/workout-session-view.tsx
    - src/components/program/exercise-card-v2.tsx
    - src/contexts/providers.tsx
    - tests/unit/program/exercise-card-v2.test.tsx

decisions:
  - "Used getActiveCycles() inside onComplete handler to resolve activeCycleId at completion time; falls back to generateId() if no active cycle exists yet — keeps the persistence wiring functional without blocking on cycle setup"
  - "CollectedSetData exported from workout-session-view.tsx as named type for use in page.tsx"
  - "exerciseId prop added to ExerciseCardV2 as required (not optional) — makes the data contract explicit and type-safe"
  - "TooltipContent wrapped in Portal for correct z-index and overlay behaviour"

metrics:
  duration: "3m 52s"
  completed: "2026-02-18"
---

# Phase 01 Plan 01: Data Foundation & Workout Persistence Summary

**One-liner:** Wired IndexedDB persistence for workout completions (CompletedWorkout + CompletedSets with full set data) and added Dexie v4 schema with personalRecords table plus Radix UI Tooltip wrapper.

## What Was Built

### Task 1: Extend types, DB schema, and DB functions
- **`src/types/workout.ts`** — Added `WeightOverrideReason` union type, `overrideReason?` field to `CompletedSet`, `PRType` type, and `PersonalRecord` interface
- **`src/lib/db/dexie.ts`** — Added `PersonalRecord` import, `personalRecords!: Table<PersonalRecord, string>` class property, and `version(4).stores()` with all v3 tables plus `personalRecords: 'id, userId, exerciseId, type, date'`
- **`src/lib/db/index.ts`** — Added four new exported async functions: `savePersonalRecord`, `getPersonalRecordsForExercise`, `getLastCompletedSetsForExercise`, `getCompletedWorkoutsForCycle`

### Task 2: Wire workout data persistence and create Tooltip component
- **`src/components/ui/tooltip.tsx`** — Shadcn-style Radix UI Tooltip wrapper exporting `Tooltip`, `TooltipTrigger`, `TooltipContent` (with Portal + styling), `TooltipProvider`
- **`src/contexts/providers.tsx`** — Added `TooltipProvider delayDuration={300}` wrapping the app within `CycleProvider`
- **`src/components/program/workout-session-view.tsx`** — Added `setDataMap` state to collect per-set data (exerciseId, setNumber, actualWeight, actualReps, prescribedWeight, prescribedReps); updated `handleSetChange` to populate map; updated `onComplete` callback type to pass `CollectedSetData[]`; exported `CollectedSetData` interface
- **`src/components/program/exercise-card-v2.tsx`** — Added required `exerciseId` prop; extended `onSetChange` signature to include `prescribedWeight` and `prescribedReps` in data payload
- **`src/app/workout/[id]/page.tsx`** — Replaced no-op `onComplete={() => {}}` with async `handleWorkoutComplete` that resolves `activeCycleId`, calls `saveCompletedWorkout`, loops through sets calling `saveCompletedSet`, then navigates back

## Verification Results

| Check | Status |
|-------|--------|
| `npx tsc --noEmit` (source files) | ✅ Pass |
| `npm run build` | ✅ Pass |
| `PersonalRecord` in `src/types/workout.ts` | ✅ |
| `version(4)` with `personalRecords` in dexie.ts | ✅ |
| 4 new DB functions exported from `src/lib/db/index.ts` | ✅ |
| `onComplete` calls `saveCompletedWorkout` + `saveCompletedSet` | ✅ |
| `src/components/ui/tooltip.tsx` with Radix exports | ✅ |
| `TooltipProvider` wrapping app in providers.tsx | ✅ |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed breaking TypeScript errors in exercise-card-v2 tests**

- **Found during:** Task 2 TypeScript verification
- **Issue:** Adding the required `exerciseId` prop to `ExerciseCardV2Props` caused 4 type errors in `tests/unit/program/exercise-card-v2.test.tsx` — all test renders were missing the new required prop
- **Fix:** Added `exerciseId="pause-squat"` to all 4 `ExerciseCardV2` renders in the test file
- **Files modified:** `tests/unit/program/exercise-card-v2.test.tsx`
- **Commit:** `4da9156`

**Note:** Two pre-existing TypeScript errors in `RestTimerExpanded.test.tsx` and `RestTimerPill.test.tsx` (status type mismatches introduced in earlier commits `8f70539`, `833af9f`) remain unfixed — these are out of scope for this plan.

## Next Phase Readiness

Phase 1 Plan 02 (Recommendations engine) can proceed immediately:
- `getLastCompletedSetsForExercise(exerciseId, activeCycleId, limit)` is ready
- `getCompletedWorkoutsForCycle(activeCycleId)` is ready
- `CollectedSetData` type is exported and usable
- Workout data is now being persisted on every completion
