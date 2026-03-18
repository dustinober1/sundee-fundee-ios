---
phase: 19
slug: analytics-crash-reporting
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30.3.0 + jest-expo 55.0.9 |
| **Config file** | jest.config.js |
| **Quick run command** | `npx jest --passWithNoTests` |
| **Full suite command** | `npx jest --passWithNoTests` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npx jest --passWithNoTests`
- **After every plan wave:** Run `npx jest --passWithNoTests`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 0 | ANLYT-01, ANLYT-04, ANLYT-05 | mock setup | `npx jest --passWithNoTests` | ❌ W0 | ⬜ pending |
| 19-01-02 | 01 | 0 | ANLYT-01 | unit | `npx jest --testPathPattern=useScreenTracking` | ❌ W0 | ⬜ pending |
| 19-01-03 | 01 | 0 | ANLYT-02, ANLYT-03 | unit | `npx jest --testPathPattern=analytics.test` | ❌ W0 | ⬜ pending |
| 19-01-04 | 01 | 0 | ANLYT-04, ANLYT-05 | unit | `npx jest --testPathPattern=crashlytics.test` | ❌ W0 | ⬜ pending |
| 19-02-01 | 02 | 1 | ANLYT-01 | unit | `npx jest --testPathPattern=useScreenTracking` | ❌ W0 | ⬜ pending |
| 19-02-02 | 02 | 1 | ANLYT-02 | unit | `npx jest --testPathPattern=analytics.test` | ❌ W0 | ⬜ pending |
| 19-02-03 | 02 | 1 | ANLYT-03 | unit | `npx jest --testPathPattern=analytics.test` | ❌ W0 | ⬜ pending |
| 19-03-01 | 03 | 1 | ANLYT-04 | unit | `npx jest --testPathPattern=crashlytics.test` | ❌ W0 | ⬜ pending |
| 19-03-02 | 03 | 1 | ANLYT-05 | unit | `npx jest --testPathPattern=crashlytics.test` | ❌ W0 | ⬜ pending |
| 19-04-01 | 04 | 2 | ANLYT-06 | manual | N/A — requires EAS account + preview build | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `__mocks__/@react-native-firebase/analytics.js` — mocks logEvent, logScreenView, setUserProperties
- [ ] `__mocks__/@react-native-firebase/crashlytics.js` — mocks recordError, setAttributes, setAttribute, log
- [ ] `src/hooks/__tests__/useScreenTracking.test.ts` — unit tests for ANLYT-01 screen tracking hook
- [ ] `src/firebase/__tests__/analytics.test.ts` — unit tests for logEvent, setUserProperties helpers (ANLYT-02, ANLYT-03)
- [ ] `src/firebase/__tests__/crashlytics.test.ts` — unit tests for recordError, setCrashlyticsKeys (ANLYT-04, ANLYT-05)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DebugView shows screen_view events | ANLYT-01 | Requires physical device + Firebase Console | Enable DebugView (-FIRDebugEnabled on iOS), navigate tabs, check Firebase Console DebugView |
| DebugView shows all 5 key events | ANLYT-02 | Requires physical device + Firebase Console | Trigger each action (start workout, finish workout, subscribe, generate AI workout, update cycle phase), check DebugView |
| Crashlytics dashboard shows non-fatal | ANLYT-04 | Requires preview build + Firebase Console | Build preview, trigger recordError, check Crashlytics dashboard Non-fatals tab |
| EAS Update installs on device | ANLYT-06 | Requires EAS account + preview build + device | Run `eas update --channel preview`, verify device downloads and applies update |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
