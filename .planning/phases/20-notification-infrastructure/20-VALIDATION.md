---
phase: 20
slug: notification-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 29.x (existing, 71 suites / 1327+ tests) |
| **Config file** | `jest.config.js` at repo root |
| **Quick run command** | `npx jest --passWithNoTests src/domain/__tests__/ src/repositories/__tests__/ -x` |
| **Full suite command** | `npx jest --passWithNoTests` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npx jest --passWithNoTests src/domain/__tests__/ src/repositories/__tests__/ src/hooks/__tests__/ src/services/__tests__/ -x`
- **After every plan wave:** Run `npx jest --passWithNoTests`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | NOTIF-06 | unit | `npx jest --passWithNoTests src/repositories/__tests__/SettingsRepo.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-01-02 | 01 | 1 | NOTIF-02 | unit | `npx jest --passWithNoTests src/domain/__tests__/notifications.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-02-01 | 02 | 1 | NOTIF-01 | unit | `npx jest --passWithNoTests src/hooks/__tests__/useRestTimer.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-02-02 | 02 | 2 | NOTIF-02 | unit | `npx jest --passWithNoTests src/domain/__tests__/notifications.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-03-01 | 03 | 2 | NOTIF-03 | unit (mocked) | `npx jest --passWithNoTests src/services/__tests__/notificationService.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-03-02 | 03 | 2 | NOTIF-08 | unit (mocked) | `npx jest --passWithNoTests src/services/__tests__/notificationService.test.ts -x` | ❌ W0 | ⬜ pending |
| 20-03-03 | 03 | 2 | NOTIF-07 | unit | `npx jest --passWithNoTests src/domain/__tests__/notifications.test.ts -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `src/hooks/__tests__/useRestTimer.test.ts` — stubs for NOTIF-01 (toggle guard, no eager permission call)
- [ ] `src/domain/__tests__/notifications.test.ts` — stubs for NOTIF-02 (first-workout detection), NOTIF-07 (cycle copy map)
- [ ] `src/services/__tests__/notificationService.test.ts` — stubs for NOTIF-03 (FCM registration), NOTIF-08 (schedule/cancel/reschedule)
- [ ] `src/repositories/__tests__/SettingsRepo.test.ts` — stubs for NOTIF-06 (AppSettings schema + defaults)
- Note: `__mocks__/expo-notifications.ts` already exists with all required stubs. No mock gaps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rest timer notification appears when app is backgrounded | NOTIF-01 | Requires real device background state | Start rest timer, background app, wait for timer to expire, verify notification appears |
| OS permission dialog shows after first workout | NOTIF-02 | Requires real OS dialog interaction | Complete workout as new user, verify Art Deco modal then OS dialog appears |
| FCM token visible in Firebase console | NOTIF-03 | Requires Firebase console access | Grant permission, check Firestore /users/{uid} for fcmToken field |
| Notification deep-link opens workout session | NOTIF-01 | Requires real notification tap | Background app, receive rest timer notification, tap it, verify navigation to workout-session |
| Settings toggles disabled when OS permission denied | NOTIF-06 | Requires real OS permission state | Deny notifications in device settings, open Settings screen, verify toggles are grayed out |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
