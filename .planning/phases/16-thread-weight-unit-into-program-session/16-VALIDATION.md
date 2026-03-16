---
phase: 16
slug: thread-weight-unit-into-program-session
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-16
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest (jest-expo preset) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern="targetWeight\|scoringInput\|session" --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern="targetWeight|scoringInput|session" --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="targetWeight" --no-coverage` | ✅ (needs update) | ⬜ pending |
| 16-01-02 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="scoringInput" --no-coverage` | ✅ (needs update) | ⬜ pending |
| 16-01-03 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="session" --no-coverage` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Update `SundeeFundeeRN/src/components/programs/__tests__/targetWeight.test.ts` — fix "225 lbs" → "225.0 lbs" assertion; add kg test cases
- [ ] Update `SundeeFundeeRN/src/components/benchmarks/__tests__/scoringInput.test.ts` — fix "315 lbs" → "315.0 lbs" assertion; add kg test case
- [ ] Create `SundeeFundeeRN/app/(app)/programs/__tests__/session.test.tsx` — covers ExerciseRow rendering with weightUnit prop

*Existing test infrastructure covers framework and config needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Program session screen shows kg when user preference is kg | PLAT-05 | Full screen render with navigation + settings requires device/simulator | 1. Set weight unit to kg in Settings 2. Navigate to Programs → active session 3. Verify target weights show kg suffix 4. Verify weight ranges show kg |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
