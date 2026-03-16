---
phase: 4
slug: core-workout-loop
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30 + jest-expo 55 + @testing-library/react-native 13 |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern=src/ --passWithNoTests` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern=src/ --passWithNoTests`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | WORK-01 | unit | `npx jest src/domain/__tests__/workout-session.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-02 | 01 | 0 | WORK-02 | unit | `npx jest src/hooks/__tests__/useRestTimer.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-03 | 01 | 0 | WORK-03 | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-04 | 01 | 0 | WORK-04 | unit | `npx jest src/domain/__tests__/exercises.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-05 | 01 | 0 | WORK-05 | unit | `npx jest src/repositories/__tests__/ExerciseRepo.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-06 | 01 | 0 | WORK-08 | unit | `npx jest src/domain/__tests__/history-filter.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-07 | 01 | 0 | WORK-10 | unit | `npx jest src/domain/__tests__/progress-data.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-08 | 01 | 0 | MAX-01 | unit | `npx jest src/repositories/__tests__/ExerciseMaxRepo.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-09 | 01 | 0 | EXEC-01..04 | unit | `npx jest src/domain/__tests__/timers.test.ts` | No — Wave 0 | ⬜ pending |
| 04-01-10 | 01 | 0 | WORK-12 | unit | `npx jest src/domain/__tests__/workout-session.test.ts` | No — Wave 0 | ⬜ pending |
| 04-xx-xx | TBD | TBD | WORK-07 | unit | `npx jest src/repositories/__tests__/LocalWorkoutRepo.test.ts` | Yes | ⬜ pending |
| 04-xx-xx | TBD | TBD | WORK-09 | unit | `npx jest src/repositories/__tests__/LocalWorkoutRepo.test.ts` | Yes | ⬜ pending |
| 04-xx-xx | TBD | TBD | MAX-03 | unit | `npx jest src/domain/__tests__/calculations.test.ts` | Yes | ⬜ pending |
| 04-xx-xx | TBD | TBD | MAX-02 | unit | `npx jest src/domain/__tests__/progress-data.test.ts` | No — Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `src/domain/__tests__/timers.test.ts` — stubs for WORK-02, WORK-03, EXEC-01, EXEC-02, EXEC-03, EXEC-04
- [ ] `src/domain/__tests__/exercises.test.ts` — stubs for WORK-04
- [ ] `src/domain/__tests__/workout-session.test.ts` — stubs for WORK-01, WORK-12
- [ ] `src/domain/__tests__/pr-detection.test.ts` — stubs for MAX-01
- [ ] `src/domain/__tests__/history-filter.test.ts` — stubs for WORK-08
- [ ] `src/domain/__tests__/progress-data.test.ts` — stubs for WORK-10, MAX-02
- [ ] `src/repositories/__tests__/ExerciseRepo.test.ts` — stubs for WORK-05
- [ ] `src/repositories/__tests__/ExerciseMaxRepo.test.ts` — stubs for MAX-01
- [ ] `src/hooks/__tests__/useRestTimer.test.ts` — stubs for WORK-02
- [ ] Install: `expo-notifications`, `expo-haptics`, `expo-av`
- [ ] Install: `react-native-gifted-charts`, `react-native-draggable-flatlist`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rest timer survives screen lock | WORK-03 | Requires real device background state | Lock screen during rest timer, verify notification fires and timer shows correct elapsed time on return |
| EMOM notifications while backgrounded | EXEC-03 | Requires real device notification delivery | Start 5-min EMOM, background app, verify per-minute notifications arrive |
| Timer persists through app background | EXEC-04 | Requires real device AppState transitions | Start ForTime timer, switch to another app for 30s, return and verify timer shows correct elapsed time |
| Drag-to-reorder exercises | WORK-12 | Gesture interaction | Long-press exercise row, drag to new position, verify order persists |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
