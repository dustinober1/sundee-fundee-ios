---
phase: 13-complete-weight-unit-threading
plan: 01
subsystem: weight-unit-display
tags: [weight-unit, history, exercise-detail, charts, settings]
dependency_graph:
  requires: [formatWeight utility (Phase 07), SettingsRepo (Phase 03)]
  provides: [PLAT-05 closed — all weight displays settings-aware]
  affects: [HistoryCard, RepRangePRTable, exercise-detail screen]
tech_stack:
  added: []
  patterns: [WeightUnit prop threading, settings useEffect pattern]
key_files:
  created:
    - SundeeFundeeRN/src/components/history/__tests__/HistoryCard.test.ts
    - SundeeFundeeRN/src/components/charts/__tests__/RepRangePRTable.test.tsx
    - SundeeFundeeRN/app/(app)/__tests__/exercise-detail.test.tsx
  modified:
    - SundeeFundeeRN/src/components/history/HistoryCard.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/history.tsx
    - SundeeFundeeRN/src/components/charts/RepRangePRTable.tsx
    - SundeeFundeeRN/app/(app)/exercise-detail.tsx
decisions:
  - formatVolume delegates to formatWeight with WeightUnit param — drops k lbs abbreviation, all weight display is now consistent
  - weightUnit defaults to lb everywhere via optional prop — backward compatible with existing callers
  - settings useEffect pattern reused from maxes.tsx — consistent approach across all screens that display weights
metrics:
  duration: 15
  completed_date: "2026-03-15"
  tasks: 2
  files_changed: 7
requirements_closed: [PLAT-05]
---

# Phase 13 Plan 01: Weight Unit Threading Summary

**One-liner:** WeightUnit setting threaded into HistoryCard, history.tsx, RepRangePRTable, and exercise-detail so all weight displays respect the user's lbs/kg preference.

## Completed Tasks

| # | Name | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Thread weightUnit into HistoryCard and history.tsx | f720026 | HistoryCard.tsx, history.tsx, HistoryCard.test.ts |
| 2 | Thread weightUnit into exercise-detail and RepRangePRTable | 705d359 | RepRangePRTable.tsx, exercise-detail.tsx, RepRangePRTable.test.tsx, exercise-detail.test.tsx |

## What Was Built

### HistoryCard.tsx
- `formatVolume` signature changed to `formatVolume(volume: number | undefined, unit: WeightUnit = 'lb'): string | null`
- Body replaced with single `formatWeight(volume, unit)` call — drops the old `k lbs` abbreviation
- `weightUnit?: WeightUnit` prop added to `HistoryCardProps` (defaults to `'lb'`)
- Component destructures and passes `weightUnit` to `formatVolume`

### history.tsx
- Added `weightUnit` state (default `DEFAULT_SETTINGS.weightUnit`)
- Added `useEffect` to load settings via `getSettingsRepo(isGuest).getSettings(user.uid)` on mount
- Passes `weightUnit={weightUnit}` to every `<HistoryCard>` in `renderItem`

### RepRangePRTable.tsx
- `weightUnit?: WeightUnit` prop added to `RepRangePRTableProps`
- Component destructures `weightUnit = 'lb'`
- Weight cell changed from `` `${pr.weight} lbs` `` to `formatWeight(pr.weight, weightUnit)`

### exercise-detail.tsx
- Added `weightUnit` state (default `DEFAULT_SETTINGS.weightUnit`)
- Added `useEffect` to load settings on mount (same pattern as other screens)
- PR badge: `{Math.round(best1RM.weight)} lbs` → `{formatWeight(best1RM.weight, weightUnit)}`
- 1RM chart yLabel: `"lbs (estimated)"` → `weightUnit === 'kg' ? 'kg (estimated)' : 'lbs (estimated)'`
- Volume chart yLabel: `"total volume (lbs)"` → `weightUnit === 'kg' ? 'total volume (kg)' : 'total volume (lbs)'`
- RepRangePRTable: `<RepRangePRTable prs={repRangePRs} />` → `<RepRangePRTable prs={repRangePRs} weightUnit={weightUnit} />`

## Tests Added

| File | Tests | Coverage |
|------|-------|----------|
| HistoryCard.test.ts | 11 (formatDuration × 4, formatVolume × 7) | New file |
| RepRangePRTable.test.tsx | 5 (lb, kg, null, default, multiple-kg) | New file |
| exercise-detail.test.tsx | 4 (PR badge lb, PR badge kg, yLabel kg, yLabel lb) | New file |

**Full suite:** 1303 tests pass, 0 failures, no regressions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test used getByText for elements that appear multiple times**
- **Found during:** Task 2 — RepRangePRTable test (null weight + null date both render `—`) and exercise-detail test (PR badge + RepRangePRTable both show same weight value)
- **Issue:** `screen.getByText('—')` and `screen.getByText('225.0 lbs')` threw "Found multiple elements" error
- **Fix:** Changed to `getAllByText(...).length >= 1` assertions where multiple matches are valid
- **Files modified:** RepRangePRTable.test.tsx, exercise-detail.test.tsx
- **Commit:** 705d359

## Self-Check: PASSED

All 7 modified/created files confirmed present on disk.
Both task commits confirmed in git log: f720026, 705d359.
Full test suite: 1303 passed, 0 failed.
