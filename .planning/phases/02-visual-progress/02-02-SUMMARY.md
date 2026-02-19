---
phase: "02-visual-progress"
plan: "02"
status: complete
subsystem: "progress-charts"
tags: ["recharts", "react-activity-calendar", "dexie", "date-fns", "hooks", "charts"]

dependency-graph:
  requires: ["01-01"]
  provides: ["CHART-02 weekly-volume-bar-chart", "CHART-03 workout-frequency-heatmap"]
  affects: ["02-03", "02-04"]

tech-stack:
  added: ["react-activity-calendar@3.1.1"]
  patterns: ["data hook pattern with isActive cleanup flag", "recharts ResponsiveContainer", "activity calendar heatmap"]

key-files:
  created:
    - src/hooks/use-weekly-volume.ts
    - src/hooks/use-workout-frequency.ts
    - src/components/progress/weekly-volume-chart.tsx
    - src/components/progress/workout-heatmap.tsx
  modified:
    - package.json
    - package-lock.json

decisions:
  - id: "named-export-activity-calendar"
    choice: "Use named export { ActivityCalendar } from react-activity-calendar"
    reason: "Library v3 does not expose a default export; plan specified default import which caused TS2613 error"
    alternatives: ["default import (broken in v3)"]

metrics:
  duration: "~2 minutes"
  completed: "2026-02-19"
---

# Phase 02 Plan 02: Weekly Volume Chart + Workout Heatmap Summary

**One-liner:** Weekly volume bar chart (last 12 weeks, recharts) and 365-day workout frequency heatmap (react-activity-calendar) with Dexie data hooks.

## What Was Built

### CHART-02: Weekly Volume Bar Chart
- **Hook** `use-weekly-volume.ts` — queries `completedWorkouts` + `completedSets` from Dexie, groups volume (`actualWeight × actualReps`) by `startOfWeek(..., { weekStartsOn: 1 })`, returns last 12 weeks sorted ascending. Uses `isActive` cleanup flag.
- **Component** `weekly-volume-chart.tsx` — recharts `BarChart` in `ResponsiveContainer` (100% × 250px). Skeleton loading state, empty state with copy, k-suffix Y-axis formatter, `hsl(var(--chart-2))` bar color.

### CHART-03: Workout Frequency Heatmap
- **Hook** `use-workout-frequency.ts` — queries `completedWorkouts`, counts per date, generates full 365-day `Activity[]` using `eachDayOfInterval`, maps counts to level 0–4 (0→0, 1→1, 2→2, 3-4→3, 5+→4). Returns `data`, `loading`, `totalWorkouts`.
- **Component** `workout-heatmap.tsx` — `ActivityCalendar` from `react-activity-calendar` with GitHub-style green theme, weekday labels, 12px blocks, summary paragraph below.

## Commits

| Hash    | Message                                                             |
| ------- | ------------------------------------------------------------------- |
| 80d14a2 | feat(02-02): install react-activity-calendar + CHART-02 volume hook + bar chart |
| aaf0cbb | feat(02-02): CHART-03 workout frequency hook + activity heatmap     |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed react-activity-calendar import (default → named export)**

- **Found during:** Task 2 TypeScript check
- **Issue:** Plan specified `import ActivityCalendar from 'react-activity-calendar'` but library v3.1.1 does not have a default export (TS2613)
- **Fix:** Changed to named import `import { ActivityCalendar } from 'react-activity-calendar'`
- **Files modified:** `src/components/progress/workout-heatmap.tsx`
- **Commit:** aaf0cbb

## Verification Results

| Check | Result |
|-------|--------|
| `npx tsc --noEmit` (src/ only) | ✅ Zero errors in src/ |
| `npm run build` | ✅ Build succeeds |
| `npm ls react-activity-calendar` | ✅ 3.1.1 installed |
| All 4 files exist | ✅ |
| `grep "eachDayOfInterval"` in frequency hook | ✅ |
| `grep "startOfWeek"` in volume hook | ✅ |

> Note: 2 pre-existing TypeScript errors in `tests/unit/components/` (RestTimer test files) were present before this plan and are unrelated to changes made here.

## Next Phase Readiness

- CHART-02 and CHART-03 are ready to be imported into the `/progress` page (02-03)
- Both components self-contain their data fetching — no props required for basic usage
- Empty states handle new users gracefully
