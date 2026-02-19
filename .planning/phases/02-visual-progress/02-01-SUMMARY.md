---
phase: "02-visual-progress"
plan: "01"
subsystem: "progress-charts"
status: "complete"
tags: ["recharts", "dexie", "1rm", "epley", "hooks", "line-chart"]

dependency-graph:
  requires:
    - "01-03: workout data persistence (completedSets + completedWorkouts in Dexie)"
  provides:
    - "use1RMProgress hook: Dexie query + Epley 1RM calculation per workout"
    - "useTrackedExercises hook: unique exerciseId lookup with name resolution"
    - "WeightProgressChart component: 1RM line chart with exercise selector"
  affects:
    - "02-02: volume/heatmap charts (same Dexie pattern)"
    - "02-03: any further progress charts that consume similar hooks"

tech-stack:
  added: []
  patterns:
    - "isActive cleanup flag for async useEffect"
    - "Derived state instead of setState-in-effect (effectiveExerciseId)"
    - "Epley 1RM formula with reps clamped at 10"

file-tracking:
  created:
    - "src/hooks/use-1rm-progress.ts"
  modified:
    - "src/components/progress/weight-progress-chart.tsx"

decisions:
  - id: "derived-exercise-id"
    choice: "Derive effectiveExerciseId = selectedId || exercises[0]?.id"
    rationale: "Avoids synchronous setState in useEffect (react-hooks/set-state-in-effect lint rule)"
  - id: "no-async-setloading"
    choice: "setLoading(true) moved inside async IIFE, not in effect body"
    rationale: "Same lint rule — synchronous setState in effect body triggers cascading render warning"

metrics:
  duration: "4 minutes"
  completed: "2026-02-19"
  tasks-completed: 2
  tasks-total: 2
---

# Phase 02 Plan 01: 1RM Progress Chart Summary

**One-liner:** Epley 1RM line chart with Dexie-backed exercise selector using `weight * (1 + min(reps,10)/30)` formula.

## What Was Built

### Task 1: `use-1rm-progress.ts` hook
- **`use1RMProgress(exerciseId)`** — queries `db.completedSets` by exerciseId, joins to `db.completedWorkouts` for dates, groups sets by workout, calculates Epley 1RM per workout, returns sorted `OneRMPoint[]`
- **`useTrackedExercises()`** — scans all `completedSets`, extracts unique exerciseIds, maps to display names via `EXERCISES` array with raw id fallback
- **`epley(weight, reps)`** — internal helper: `weight * (1 + Math.min(reps, 10) / 30)`, returns weight as-is for single-rep sets
- Both hooks use `isActive` cleanup flag pattern

### Task 2: `weight-progress-chart.tsx` rewrite
- Replaced raw set-weight chart with Epley estimated 1RM line chart
- `Select` dropdown shows only exercises the user has actually trained (from `useTrackedExercises`)
- Auto-selects first exercise via derived state: `effectiveExerciseId = selectedId || exercises[0]?.id`
- Recharts `LineChart` with `chart-1` CSS variable for colors, YAxis lbs suffix, Tooltip showing `Est. 1RM`
- `Skeleton` loading states for both the exercise list and chart
- Two empty states: "No workout data yet" (no exercises) and "No data for this exercise yet" (exercise with no sets)
- Export name `WeightProgressChart` preserved for backward compatibility with `progress/page.tsx`

## Files Modified

| File | Action | Notes |
|------|--------|-------|
| `src/hooks/use-1rm-progress.ts` | Created | New hook file |
| `src/components/progress/weight-progress-chart.tsx` | Rewritten | Same export name, new implementation |

## Commits

| Hash | Description |
|------|-------------|
| `9713f9c` | feat(02-01): create use-1rm-progress hook |
| `b35ef23` | feat(02-01): rewrite weight-progress-chart as 1RM chart with exercise selector |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Synchronous setState in useEffect**

- **Found during:** Task 2 (lint check)
- **Issue:** `setData([])` and `setLoading(false)` called synchronously in `useEffect` early return; `setLoading(true)` also called synchronously. ESLint `react-hooks/set-state-in-effect` flagged these as causing cascading renders.
- **Fix:**
  - Removed `setData([])` from early return (data defaults to `[]`, no-op)
  - Removed `setLoading(false)` from early return (loading defaults to `false`)
  - Moved `setLoading(true)` inside async IIFE (first line, before any await)
  - In `WeightProgressChart`: replaced `useEffect` auto-select pattern with derived state: `effectiveExerciseId = selectedId || exercises[0]?.id`
- **Files modified:** `src/hooks/use-1rm-progress.ts`, `src/components/progress/weight-progress-chart.tsx`
- **Commit:** `b35ef23`

## Next Phase Readiness

- ✅ `WeightProgressChart` is a drop-in replacement — `progress/page.tsx` needs no changes
- ✅ Dexie query pattern (`where/equals` + `where/anyOf`) established for other charts to follow
- ✅ Build, lint, TypeScript all clean
