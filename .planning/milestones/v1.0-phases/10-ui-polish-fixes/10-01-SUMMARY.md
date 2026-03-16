---
phase: 10-ui-polish-fixes
plan: "01"
subsystem: SundeeFundeeRN
tags: [ui-polish, weight-unit, export, navigation]
dependency_graph:
  requires: []
  provides: [weight-unit-display-fix, goodbye-route-declaration, web-csv-zip-export]
  affects: [workout-detail, _layout, exportData]
tech_stack:
  added: [jszip]
  patterns: [static-import-over-dynamic-for-jest, waitFor-async-render-pattern]
key_files:
  created:
    - SundeeFundeeRN/app/(app)/__tests__/workout-detail.test.tsx
    - SundeeFundeeRN/app/(app)/__tests__/goodbye.test.tsx
  modified:
    - SundeeFundeeRN/app/(app)/workout-detail.tsx
    - SundeeFundeeRN/app/(app)/_layout.tsx
    - SundeeFundeeRN/src/export/exportData.ts
    - SundeeFundeeRN/src/export/__tests__/exportData.test.ts
    - SundeeFundeeRN/package.json
decisions:
  - "[10-01]: Static import used for jszip instead of dynamic import — dynamic import() fails in Jest CommonJS mode without --experimental-vm-modules (consistent with 09-01 migration.ts decision)"
  - "[10-01]: waitFor used for async component rendering in workout-detail tests — render inside act() causes 'Can't access .root on unmounted test renderer' in jest-expo environment"
metrics:
  duration: 6 min
  completed: "2026-03-15"
  tasks_completed: 2
  files_modified: 7
---

# Phase 10 Plan 01: UI Polish Fixes Summary

Three post-launch UX bugs fixed with TDD coverage: weight unit rendering in workout detail, goodbye screen back button suppression, and web CSV export bundled as a single zip.

## Tasks Completed

### Task 1: Thread weightUnit into workout-detail.tsx via formatWeight

**Commit:** `68483b1`

Replaced all three hardcoded `" lbs"` instances in `workout-detail.tsx` with `formatWeight(value, weightUnit)`. Added a `weightUnit` state (defaults to `'lb'`) loaded from `getSettingsRepo` in a dedicated `useEffect`. Passed `weightUnit` as a prop to `CompletedExerciseSection` and `AIExerciseSection`.

**Files modified:**
- `SundeeFundeeRN/app/(app)/workout-detail.tsx` — imports, state, three formatWeight replacements, updated sub-component signatures
- `SundeeFundeeRN/app/(app)/__tests__/workout-detail.test.tsx` — 5 new tests

**Tests:** 5 tests pass (kg suffix, lbs suffix, AI exercise kg conversion, Volume MetaStat kg, zero-weight dash)

### Task 2: Add goodbye Stack.Screen and install JSZip for web zip export

**Commit:** `50f9fec`

Added `<Stack.Screen name="goodbye" options={{ headerShown: false }} />` to `app/(app)/_layout.tsx`, eliminating the system back button shown after account deletion.

Installed `jszip` (static import to avoid Jest CommonJS dynamic import failure). Updated `triggerWebDownload` to accept `Blob | string`. Replaced the web CSV 7-file loop with a single JSZip bundle, triggering one download instead of seven.

**Files modified:**
- `SundeeFundeeRN/app/(app)/_layout.tsx` — goodbye Stack.Screen entry
- `SundeeFundeeRN/src/export/exportData.ts` — jszip static import, triggerWebDownload signature, JSZip web CSV branch
- `SundeeFundeeRN/src/export/__tests__/exportData.test.ts` — 2 new web zip tests
- `SundeeFundeeRN/app/(app)/__tests__/goodbye.test.tsx` — 3 new tests
- `SundeeFundeeRN/package.json` — jszip dependency added

**Tests:** 19 exportData tests + 3 goodbye tests pass

## Verification

Full suite: **1275 tests, 0 failures, 63 test suites**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dynamic import for jszip replaced with static import**
- **Found during:** Task 2 GREEN phase
- **Issue:** `await import('jszip')` in `exportData.ts` throws "A dynamic import callback was invoked without --experimental-vm-modules" in Jest CommonJS mode — same root cause as the migration.ts fix in Phase 09
- **Fix:** Changed to static `import JSZip from 'jszip'` at file top, removed `.default` access from the call site
- **Files modified:** `SundeeFundeeRN/src/export/exportData.ts`
- **Commit:** `50f9fec`

**2. [Rule 1 - Bug] Test pattern updated from render-inside-act to render+waitFor**
- **Found during:** Task 1 GREEN phase
- **Issue:** `render(<WorkoutDetailScreen />)` inside `act(async () => {...})` caused "Can't access .root on unmounted test renderer" in jest-expo — the component unmounts when async effects complete before act finishes
- **Fix:** Moved `render()` outside `act()`, used `waitFor()` to await async state updates — consistent with the settings.test.tsx pattern already established in this codebase
- **Files modified:** `SundeeFundeeRN/app/(app)/__tests__/workout-detail.test.tsx`
- **Commit:** `68483b1`

## Self-Check: PASSED

All 7 key files verified on disk. Both task commits (68483b1, 50f9fec) confirmed in git log.
