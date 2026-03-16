---
phase: 7
slug: polish-and-pre-launch
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 29 + jest-expo preset |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern="formatWeight\|exportData\|deleteAccount\|settings" --passWithNoTests` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage && cd ../functions && npx jest` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern="formatWeight\|exportData\|deleteAccount\|settings" --passWithNoTests`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage && cd ../functions && npx jest`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | PLAT-05 | unit | `npx jest src/utils/__tests__/formatWeight.test.ts` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | PLAT-05 | unit | `npx jest --testPathPattern="settings"` | ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | PLAT-06 | unit | `npx jest src/export/__tests__/exportData.test.ts` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 1 | PLAT-06 | unit | `npx jest src/export/__tests__/csvFormatters.test.ts` | ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 2 | PLAT-07 | unit | `cd functions && npx jest __tests__/deleteAccount.test.ts` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 2 | PLAT-07 | unit | `npx jest --testPathPattern="settings"` | ❌ W0 | ⬜ pending |
| 07-04-01 | 04 | 2 | PLAT-04 | manual | Manual visual review | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/utils/__tests__/formatWeight.test.ts` — stubs for PLAT-05: formatWeight, parseWeightInput, 0.5 kg rounding
- [ ] `SundeeFundeeRN/src/export/__tests__/exportData.test.ts` — stubs for PLAT-06: data collection, file generation
- [ ] `SundeeFundeeRN/src/export/__tests__/csvFormatters.test.ts` — stubs for PLAT-06: CSV column headers, unit-aware formatting
- [ ] `functions/__tests__/deleteAccount.test.ts` — stubs for PLAT-07: full delete orchestration

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Art Deco visual consistency (spacing, typography, colors) | PLAT-04 | No automated visual regression in project | Review all screens for consistent spacing, font sizes, card styles, and color usage against theme tokens |
| Share sheet opens with correct file | PLAT-06 | Native share sheet interaction | Tap Export in Settings, choose CSV, verify zip file opens in share sheet |
| Account deletion goodbye screen | PLAT-07 | Navigation flow | Delete account, verify goodbye screen shows, tap Done, verify return to sign-in |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
