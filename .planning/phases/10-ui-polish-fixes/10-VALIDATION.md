---
phase: 10
slug: ui-polish-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest-expo (Jest 29) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern="workout-detail\|goodbye\|exportData" --passWithNoTests` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern="workout-detail|goodbye|exportData" --passWithNoTests`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="workout-detail"` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="goodbye"` | ❌ W0 | ⬜ pending |
| 10-01-03 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="exportData"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/app/(app)/__tests__/workout-detail.test.tsx` — stubs for PLAT-05 unit conversion in CompletedExerciseSection and AIExerciseSection
- [ ] `SundeeFundeeRN/app/(app)/__tests__/goodbye.test.tsx` — verifies screen renders and Done button navigates to /sign-in
- [ ] `exportData.test.ts` web section — add test case verifying single zip download call when `Platform.OS === 'web'` and format is `'csv'`

*Existing infrastructure covers framework setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual weight label alignment | PLAT-05 | Layout varies by device | Check workout-detail on simulator with lbs and kg |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
