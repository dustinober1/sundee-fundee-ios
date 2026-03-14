---
phase: 3
slug: data-layer-and-offline-architecture
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30.3.0 + jest-expo 55.0.9 |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest --testPathPattern="repositories" --passWithNoTests` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest --testPathPattern="repositories" --passWithNoTests`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | ONBD-01 | unit | `npx jest --testPathPattern="FirestoreOnboardingProfileRepo"` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | ONBD-01 | unit | `npx jest --testPathPattern="LocalOnboardingProfileRepo"` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | ONBD-02 | unit | `npx jest --testPathPattern="OnboardingProfileRepo"` | ❌ W0 | ⬜ pending |
| 03-01-04 | 01 | 1 | WORK-11 | unit | `npx jest --testPathPattern="FirestoreWorkoutRepo"` | ❌ W0 | ⬜ pending |
| 03-01-05 | 01 | 1 | WORK-11 | unit | `npx jest --testPathPattern="LocalWorkoutRepo"` | ❌ W0 | ⬜ pending |
| 03-01-06 | 01 | 1 | AUTH-07 | unit | `npx jest --testPathPattern="repoFactory"` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | ONBD-03 | unit | `npx jest --testPathPattern="onboarding"` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | ONBD-01 | type | `npx tsc --noEmit` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | AUTH-07 | unit | `npx jest --testPathPattern="migration"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `src/repositories/__tests__/FirestoreOnboardingProfileRepo.test.ts` — stubs for ONBD-01, ONBD-02
- [ ] `src/repositories/__tests__/LocalOnboardingProfileRepo.test.ts` — stubs for ONBD-01, ONBD-02
- [ ] `src/repositories/__tests__/FirestoreWorkoutRepo.test.ts` — stubs for WORK-11
- [ ] `src/repositories/__tests__/LocalWorkoutRepo.test.ts` — stubs for WORK-11
- [ ] `src/repositories/__tests__/FirestoreSettingsRepo.test.ts` — stubs for settings persistence
- [ ] `src/repositories/__tests__/LocalSettingsRepo.test.ts` — stubs for settings persistence
- [ ] `src/repositories/__tests__/FirestoreReadinessRepo.test.ts` — stubs for readiness persistence
- [ ] `src/repositories/__tests__/LocalReadinessRepo.test.ts` — stubs for readiness persistence
- [ ] `src/repositories/__tests__/repoFactory.test.ts` — stubs for AUTH-07 factory routing
- [ ] `src/repositories/__tests__/migration.test.ts` — stubs for guest-to-auth migration

*Existing mocks in `__mocks__/@react-native-firebase/firestore.ts` and `__mocks__/@react-native-async-storage/async-storage.ts` cover all new repo tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Workout persists after airplane mode toggle | WORK-11 | Requires physical device offline simulation | 1. Enable airplane mode 2. Log workout 3. Disable airplane mode 4. Verify workout appears in history |
| Onboarding flow UX (back button, progress bar) | ONBD-01 | Visual/interaction quality | 1. Complete onboarding 2. Use back button at each step 3. Verify progress bar updates |
| Guest migration loading spinner | AUTH-07 | UX timing/visual | 1. Complete onboarding as guest 2. Sign up 3. Verify "Setting up your account..." spinner appears 4. Verify data appears after completion |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
