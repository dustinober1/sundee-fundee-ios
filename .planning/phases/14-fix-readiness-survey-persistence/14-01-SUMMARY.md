---
phase: 14-fix-readiness-survey-persistence
plan: "01"
subsystem: readiness
tags: [testing, readiness, persistence, READ-01, READ-02]
dependency_graph:
  requires: []
  provides: [readiness-persistence-test-coverage]
  affects: [ReadinessSurveyModal, dashboard-index, workout-session]
tech_stack:
  added: []
  patterns: [source-grep-tests, component-integration-tests, fake-timers]
key_files:
  created:
    - SundeeFundeeRN/src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx
    - SundeeFundeeRN/src/__tests__/readiness-persistence.test.ts
  modified: []
decisions:
  - ReadinessResult has score+tier fields (no label field) — test assertion corrected to use tier
metrics:
  duration: "2 min"
  completed_date: "2026-03-16"
  tasks_completed: 2
  files_changed: 2
---

# Phase 14 Plan 01: Readiness Survey Persistence Tests Summary

**One-liner:** 8 tests prove readiness save-check-consume pipeline via modal saveSurvey, dashboard card suppression, workout-session score loading, and Firestore rules wildcard coverage.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add ReadinessSurveyModal persistence test | 50ef223 | `src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx` |
| 2 | Add readiness persistence pipeline tests | 5437c78 | `src/__tests__/readiness-persistence.test.ts` |

## What Was Built

**Task 1 — ReadinessSurveyModal.test.tsx (3 tests)**

Mocks `getReadinessRepo`, `useSession`, and `date-fns/format` following the Babel hoisting safety pattern. Tests:
- `saveSurvey` is called with `('test-user', { uid, date, id })` on submit
- `onComplete` is called with a `ReadinessResult` `{ score, tier }` after the 2-second auto-dismiss timer
- `onDismiss` is called when `saveSurvey` rejects (graceful degradation)

**Task 2 — readiness-persistence.test.ts (5 tests)**

Source-file verification following `cycle-adaptation-gate.test.ts` pattern. Tests:
- `ReadinessSurveyModal.tsx` contains `saveSurvey` call
- `app/(app)/(tabs)/index.tsx` contains `getSurveyForDate` call
- `app/(app)/(tabs)/index.tsx` hides card via `setShowReadinessCard(false)` when `existing != null`
- `app/(app)/workout-session.tsx` loads readiness score via `survey?.result.score`
- `firestore.rules` contains wildcard subcollection match covering readiness collection

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ReadinessResult has no `label` field — has `tier` instead**
- **Found during:** Task 1, second test assertion
- **Issue:** Plan specified `expect.objectContaining({ label: expect.any(String) })` but `ReadinessResult` interface has `tier: ReadinessTier` not `label`
- **Fix:** Changed assertion to `expect.objectContaining({ score: expect.any(Number), tier: expect.any(String) })`
- **Files modified:** `src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx`
- **Commit:** 50ef223

## Verification Results

- Task 1 verification: `npx jest ReadinessSurveyModal.test.tsx --no-coverage` — 3/3 pass
- Task 2 verification: `npx jest readiness-persistence.test.ts --no-coverage` — 5/5 pass
- Combined: 8/8 pass
- Full suite: 1311 tests across 69 suites — all passing, no regressions

## Requirements Closed

- **READ-01**: Modal calls `saveSurvey`, dashboard calls `getSurveyForDate` + hides card, Firestore rules permit subcollection writes — proven by tests 1, 2, 3, and 5
- **READ-02**: `workout-session.tsx` loads readiness score via `getSurveyForDate` + `result.score` — proven by test 4

## Self-Check: PASSED

- `src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx` — created and exists
- `src/__tests__/readiness-persistence.test.ts` — created and exists
- Commit 50ef223 — exists
- Commit 5437c78 — exists
