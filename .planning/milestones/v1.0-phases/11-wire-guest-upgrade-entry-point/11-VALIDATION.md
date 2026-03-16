---
phase: 11
slug: wire-guest-upgrade-entry-point
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest-expo (Jest 29) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest app/\(app\)/__tests__/sign-in.test.tsx --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest app/\(app\)/__tests__/sign-in.test.tsx --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | AUTH-07 | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleAppleSignIn.*guest"` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | AUTH-07 | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleGoogleSignIn.*guest"` | ❌ W0 | ⬜ pending |
| 11-01-03 | 01 | 1 | AUTH-07 | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleEmailAuth.*guest.*signup"` | ❌ W0 | ⬜ pending |
| 11-01-04 | 01 | 1 | AUTH-07 | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "non-guest"` | ❌ W0 | ⬜ pending |
| 11-01-05 | 01 | 1 | AUTH-07 | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "credential-already-in-use"` | ❌ W0 | ⬜ pending |
| 11-01-06 | 01 | 1 | AUTH-07 | unit (import) | `npx jest src/firebase/__tests__/auth.test.ts` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `app/(app)/__tests__/sign-in.test.tsx` — stubs for AUTH-07 (all three upgrade branches + regression + error handling)
- [ ] `EmailAuthProvider` mock in `__mocks__/@react-native-firebase/auth.ts` — needed for email upgrade tests

*Existing test infrastructure (jest-expo, jest.config.js) covers framework needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guest taps Apple sign-in → data persists after upgrade | AUTH-07 | E2E with real Apple ID + device | 1. Launch as guest, log a workout 2. Tap Sign in with Apple 3. Verify workout appears in authenticated session |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
