---
phase: 14
slug: fix-readiness-survey-persistence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest + @testing-library/react-native |
| **Config file** | SundeeFundeeRN/jest.config.js |
| **Quick run command** | `cd SundeeFundeeRN && npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --no-coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest src/__tests__/readiness-persistence.test.ts --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --no-coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 0 | READ-01 | unit | `npx jest src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx --no-coverage` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 0 | READ-01 | unit | `npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` | ❌ W0 | ⬜ pending |
| 14-01-03 | 01 | 0 | READ-02 | unit (source-file grep) | `npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` | ❌ W0 | ⬜ pending |
| 14-01-04 | 01 | 1 | READ-01 | integration | `npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx` — stubs for READ-01 save call verification
- [ ] `SundeeFundeeRN/src/__tests__/readiness-persistence.test.ts` — stubs for READ-01 card suppression + READ-02 workout-session wiring

*Existing infrastructure covers test framework and mock patterns.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Firestore rules allow readiness subcollection writes | READ-01 | Rules file requires Firebase emulator or deployed check | Inspect `firestore.rules` for `/users/{uid}/readiness/{date}` match block |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
