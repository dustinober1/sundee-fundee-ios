---
phase: 9
slug: fix-guest-migration-ai-profile
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest (jest-expo) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest src/repositories/__tests__/migration.test.ts --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest src/repositories/__tests__/migration.test.ts src/auth/__tests__/useGuestSignIn.test.ts --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 0 | AUTH-07 | unit | `npx jest migration.test.ts -t "batch"` | ❌ W0 | ⬜ pending |
| 09-01-02 | 01 | 0 | AUTH-07 | unit | `npx jest migration.test.ts -t "pending"` | ❌ W0 | ⬜ pending |
| 09-01-03 | 01 | 0 | AIWK-02 | unit | `npx jest config.test.tsx -t "profile"` | ❌ W0 | ⬜ pending |
| 09-01-04 | 01 | 1 | AUTH-07 | unit | `npx jest migration.test.ts -t "migrates"` | Partial ✅ | ⬜ pending |
| 09-01-05 | 01 | 1 | AUTH-07 | unit | `npx jest migration.test.ts -t "clears"` | ✅ | ⬜ pending |
| 09-01-06 | 01 | 1 | AUTH-07 | unit | `npx jest useGuestSignIn.test.ts -t "upgrade"` | Partial ✅ | ⬜ pending |
| 09-01-07 | 01 | 1 | AUTH-07 | unit | `npx jest -- -t "retryPendingMigration"` | ❌ W0 | ⬜ pending |
| 09-02-01 | 02 | 2 | AIWK-02 | unit | `npx jest config.test.tsx -t "profile"` | ❌ W0 | ⬜ pending |
| 09-02-02 | 02 | 2 | AIWK-02 | unit | `npx jest config.test.tsx -t "weightUnit"` | ❌ W0 | ⬜ pending |
| 09-02-03 | 02 | 2 | AIWK-02 | unit | `npx jest config.test.tsx -t "maxes"` | ❌ W0 | ⬜ pending |
| 09-02-04 | 02 | 2 | AIWK-02 | unit | `npx jest config.test.tsx -t "recentWorkouts"` | ❌ W0 | ⬜ pending |
| 09-02-05 | 02 | 2 | AIWK-02 | unit | `npx jest config.test.tsx -t "fallback"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/repositories/__tests__/migration.test.ts` — add cases for all 9 new key types, batch-split behavior, pending flag lifecycle
- [ ] `SundeeFundeeRN/src/auth/__tests__/useGuestSignIn.test.ts` — add assertion that migration is called after upgrade, pending flag is set before, upgrade succeeds even when migration throws
- [ ] `SundeeFundeeRN/app/(app)/ai-workout/__tests__/config.test.tsx` — new file covering profile/settings/maxes/recentWorkouts wiring and fallback behavior

*Existing infrastructure covers framework needs — no new installs required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guest upgrade preserves data end-to-end | AUTH-07 | Requires real Firebase Auth + Firestore | 1. Create guest, add data, upgrade to Apple ID, verify data in Firestore console |
| AI workout reflects real profile | AIWK-02 | Requires AI generation + visual inspection | 1. Set profile to male/advanced, generate workout, verify prompt uses correct values |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
