---
phase: 13
slug: complete-weight-unit-threading
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 29.x (jest-expo preset) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern="HistoryCard\|exercise-detail\|RepRangePR" --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~15 seconds (quick), ~60 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern="HistoryCard|exercise-detail|RepRangePR" --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 0 | PLAT-05 | unit | `npx jest --testPathPattern="HistoryCard" --no-coverage` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 0 | PLAT-05 | unit | `npx jest --testPathPattern="exercise-detail" --no-coverage` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 0 | PLAT-05 | unit | `npx jest --testPathPattern="RepRangePR" --no-coverage` | ❌ W0 | ⬜ pending |
| 13-01-04 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="HistoryCard" --no-coverage` | ✅ (W0) | ⬜ pending |
| 13-01-05 | 01 | 1 | PLAT-05 | component | `npx jest --testPathPattern="exercise-detail" --no-coverage` | ✅ (W0) | ⬜ pending |
| 13-01-06 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="RepRangePR" --no-coverage` | ✅ (W0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/components/history/__tests__/HistoryCard.test.ts` — stubs for formatVolume with weightUnit param (PLAT-05)
- [ ] `SundeeFundeeRN/app/(app)/__tests__/exercise-detail.test.tsx` — stubs for PR badge and chart label unit rendering (PLAT-05)
- [ ] `SundeeFundeeRN/src/components/charts/__tests__/RepRangePRTable.test.tsx` — stubs for weight cell rendering with unit param (PLAT-05)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual confirmation that history cards show kg after settings change | PLAT-05 | Requires real device/simulator visual check | 1. Open Settings, switch to kg. 2. Open History tab. 3. Verify volume stats show kg suffix. |
| Visual confirmation that exercise detail PR badge shows kg | PLAT-05 | Requires real device/simulator visual check | 1. Open Settings, switch to kg. 2. Tap any exercise in History. 3. Verify PR badge and chart labels show kg. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
