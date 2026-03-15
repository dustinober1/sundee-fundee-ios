---
phase: 08-fix-cycle-adaptation-wiring
plan: "01"
subsystem: cycle-adaptation
tags: [bug-fix, cycle, onboarding, gate-fix]
dependency_graph:
  requires: []
  provides: [CYAD-01, CYAD-02, CYAD-03]
  affects: [workout-session, dashboard]
tech_stack:
  added: []
  patterns: [repository-factory, profile-gate]
key_files:
  created:
    - SundeeFundeeRN/src/__tests__/cycle-adaptation-gate.test.ts
  modified:
    - SundeeFundeeRN/app/(app)/workout-session.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/index.tsx
decisions:
  - "[08-01]: Cycle adaptation gate uses profile.cycleOptIn from OnboardingProfileRepo — not cycleSettings.cycleTrackingEnabled which does not exist on the CycleSettings type"
metrics:
  duration: "2 min"
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_modified: 3
---

# Phase 08 Plan 01: Fix Cycle Adaptation Gate Summary

**One-liner:** Fixed two broken gate conditions in workout-session and dashboard that referenced non-existent `cycleSettings.cycleTrackingEnabled` instead of `profile.cycleOptIn`, unblocking CYAD-01/02/03 in production.

## What Was Built

Both `workout-session.tsx` and `(tabs)/index.tsx` contained identical broken gate conditions that checked `cycleSettings?.cycleTrackingEnabled === true` — a property that does not exist on the `CycleSettings` type. This meant cycle adaptation logic (phase multiplier, readiness blend, CyclePhaseBanner) was permanently gated out in production for all users, regardless of their onboarding opt-in choice.

The fix follows the correct pattern already used in `ai-workout/config.tsx`:
1. Import `getOnboardingProfileRepo` from the repository layer
2. Load `OnboardingProfile` before the cycle phase block
3. Gate on `profile?.cycleOptIn === true`

`cycleSettings` is still fetched in both files — it is still needed as input to `calculateCycleStatus`.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Fix cycle adaptation gates in workout-session.tsx and dashboard index.tsx | 5a2d389 | workout-session.tsx, (tabs)/index.tsx |
| 2 | Unit test the cycle adaptation gate logic | 2b105e8 | src/__tests__/cycle-adaptation-gate.test.ts |

## Verification Results

- TypeScript compiles — errors in `programs/index.tsx` are pre-existing and unrelated
- All 7 gate tests pass: 5 logic tests + 2 source file verification tests
- `grep -r "cycleTrackingEnabled" app/` returns zero results (broken pattern eliminated)
- Both target files contain `profile?.cycleOptIn === true` at the correct gate point

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] `SundeeFundeeRN/app/(app)/workout-session.tsx` — contains `profile?.cycleOptIn === true`, no `cycleTrackingEnabled`
- [x] `SundeeFundeeRN/app/(app)/(tabs)/index.tsx` — contains `profile?.cycleOptIn === true`, no `cycleTrackingEnabled`
- [x] `SundeeFundeeRN/src/__tests__/cycle-adaptation-gate.test.ts` — 73 lines, 7 tests all passing
- [x] Commit 5a2d389 exists (Task 1 fix)
- [x] Commit 2b105e8 exists (Task 2 tests)
