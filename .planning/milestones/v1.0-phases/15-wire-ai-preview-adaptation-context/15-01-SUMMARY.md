---
phase: 15-wire-ai-preview-adaptation-context
plan: 01
subsystem: ai-workout
tags: [adaptation-context, shared-state, AdaptationChip, preview-screen, tdd]
dependency_graph:
  requires: []
  provides: [adaptation-context-in-preview]
  affects: [ai-workout-preview, ai-workout-config]
tech_stack:
  added: []
  patterns: [module-level-shared-state, adaptation-context-pass-through]
key_files:
  created:
    - SundeeFundeeRN/app/(app)/ai-workout/__tests__/preview.test.tsx
  modified:
    - SundeeFundeeRN/app/(app)/ai-workout/config.tsx
    - SundeeFundeeRN/app/(app)/ai-workout/preview.tsx
decisions:
  - "SharedWorkoutState extended with three adaptation fields rather than re-fetching in preview — anti-pattern per plan research"
  - "injuries filtered to active-only (recoveryPhase !== resolved) at setSharedWorkout call site in config — preview receives pre-filtered list"
metrics:
  duration: 12
  completed_date: "2026-03-16"
  tasks_completed: 2
  files_changed: 3
---

# Phase 15 Plan 01: Wire AI Preview Adaptation Context Summary

**One-liner:** Wired cycle phase, active injuries, and readiness score from config through SharedWorkoutState into preview screen so AdaptationChip renders with real adaptation data.

## What Was Built

The AI workout preview screen was showing an empty AdaptationChip because the shared state passed from config to preview never carried the adaptation records — only the generated workout and context. This plan closes that gap by:

1. Extending `SharedWorkoutState` in `config.tsx` with three new fields: `adaptationCyclePhase`, `adaptationInjuries`, `adaptationReadiness`
2. Updating `setSharedWorkout` to accept and store those three fields
3. Updating the call site in `handleGenerateWorkout` to pass the config screen's React state values (with injuries pre-filtered to active-only)
4. Unpacking the three adaptation fields in `preview.tsx`'s `useEffect` into local state consumed by `AdaptationChip`
5. Adding `preview.test.tsx` with 4 tests covering all adaptation display combinations

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Extend SharedWorkoutState and wire adaptation context | bb1bf03 | config.tsx, preview.tsx |
| 2 | Add preview.test.tsx | 9c16bcf | preview.test.tsx (new) |

## Verification

```
Test Suites: 2 passed, 2 total
Tests:       16 passed, 16 total
```

All 12 existing config tests pass. All 4 new preview tests pass.

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

- **SharedWorkoutState adaptation fields added (not re-fetched in preview):** The plan explicitly called out re-fetching as an anti-pattern. The config screen's React state is the authoritative source since it already loaded the data during `loadAdaptationContext`.
- **Active injury filtering at call site:** `injuries.filter((i) => i.recoveryPhase !== 'resolved')` applied in `handleGenerateWorkout` before calling `setSharedWorkout` — consistent with the `activeInjuries` variable already computed for `WorkoutGenerationContext`.

## Self-Check: PASSED

- FOUND: SundeeFundeeRN/app/(app)/ai-workout/__tests__/preview.test.tsx
- FOUND: SundeeFundeeRN/app/(app)/ai-workout/config.tsx
- FOUND: SundeeFundeeRN/app/(app)/ai-workout/preview.tsx
- FOUND commit: bb1bf03 (feat: SharedWorkoutState + wiring)
- FOUND commit: 9c16bcf (test: preview.test.tsx)
