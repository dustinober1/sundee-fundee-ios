---
phase: 1
slug: foundation-and-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest + @testing-library/react-native |
| **Config file** | jest.config.js (Wave 0 installs) |
| **Quick run command** | `npx jest --testPathPattern="auth" --passWithNoTests` |
| **Full suite command** | `npx jest --coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npx jest --testPathPattern="(auth|Auth)" --passWithNoTests`
- **After every plan wave:** Run `npx jest --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green + manual smoke tests on all 3 platforms
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 0 | PLAT-01 | smoke (manual) | manual — EAS build + xcrun simctl launch | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 0 | PLAT-02 | smoke (manual) | manual — EAS build + adb shell am start | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 0 | PLAT-03 | smoke (manual) | `npx expo start --web` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | AUTH-05 | unit | `npx jest --testPathPattern="AuthContext"` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | AUTH-01 | unit | `npx jest --testPathPattern="useEmailAuth"` | ❌ W0 | ⬜ pending |
| 01-02-03 | 02 | 1 | AUTH-02 | unit | `npx jest --testPathPattern="useAppleSignIn"` | ❌ W0 | ⬜ pending |
| 01-02-04 | 02 | 1 | AUTH-03 | unit | `npx jest --testPathPattern="useGoogleSignIn"` | ❌ W0 | ⬜ pending |
| 01-02-05 | 02 | 1 | AUTH-04 | unit | `npx jest --testPathPattern="useGuestSignIn"` | ❌ W0 | ⬜ pending |
| 01-02-06 | 02 | 1 | AUTH-06 | unit | `npx jest --testPathPattern="AuthContext"` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | AUTH-07 | rules test | `npx jest --testPathPattern="firestore.rules"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `jest.config.js` — Jest configuration with jest-expo preset
- [ ] `__mocks__/@react-native-firebase/auth.ts` — Mock firebase auth module
- [ ] `__mocks__/expo-apple-authentication.ts` — Mock Apple auth
- [ ] `__mocks__/@react-native-google-signin/google-signin.ts` — Mock Google sign-in
- [ ] `src/auth/__tests__/AuthContext.test.tsx` — Stubs for AUTH-05, AUTH-06
- [ ] `src/auth/__tests__/useEmailAuth.test.ts` — Stubs for AUTH-01
- [ ] `src/auth/__tests__/useAppleSignIn.test.ts` — Stubs for AUTH-02
- [ ] `src/auth/__tests__/useGoogleSignIn.test.ts` — Stubs for AUTH-03
- [ ] `src/auth/__tests__/useGuestSignIn.test.ts` — Stubs for AUTH-04
- [ ] `firestore.rules.test.ts` — Stubs for AUTH-07 (requires @firebase/rules-unit-testing)
- [ ] Framework install: `npx expo install jest-expo @testing-library/react-native`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| EAS dev build launches on iOS Simulator | PLAT-01 | Requires EAS cloud build + physical simulator | Run `eas build --profile development --platform ios`, install on simulator, verify app launches |
| EAS dev build launches on Android Emulator | PLAT-02 | Requires EAS cloud build + physical emulator | Run `eas build --profile development --platform android`, install on emulator, verify app launches |
| Web build serves auth screen | PLAT-03 | Requires browser verification | Run `npx expo start --web`, verify auth screen renders in browser |
| Apple Sign-In works on iOS device | AUTH-02 | Requires real Apple ID + iOS device | Sign in with Apple on device, verify Firebase user created |
| Google Sign-In works on Android | AUTH-03 | Requires Google Play Services on device | Sign in with Google on Android, verify Firebase user created |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
