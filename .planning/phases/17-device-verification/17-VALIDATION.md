---
phase: 17
slug: device-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-16
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest 29.x (existing) + iOS Simulator MCP tools |
| **Config file** | `jest.config.js` (existing) |
| **Quick run command** | `npx jest --passWithNoTests` |
| **Full suite command** | `npx jest` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npx jest --passWithNoTests`
- **After every plan wave:** Run `npx jest` + manual simulator verification
- **Before `/gsd:verify-work`:** Full suite must be green + all triage items resolved
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | VERIFY-01 | manual+auto | iOS Simulator MCP screenshot/tap | N/A | ⬜ pending |
| 17-02-01 | 02 | 2 | VERIFY-02 | manual | Simulator MCP workflow | N/A | ⬜ pending |
| 17-03-01 | 03 | 2 | VERIFY-03 | manual | Simulator offline test | N/A | ⬜ pending |
| 17-04-01 | 04 | 3 | VERIFY-04 | manual | Firebase Emulator + Simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Confirm dev build (`.app` bundle) is installed on iPhone 16 Pro simulator
- [ ] Confirm Firebase Emulator can start (`firebase emulators:start`)
- [ ] Confirm Android emulator (Pixel 9) is available and boots
- [ ] Build app for simulator if needed: `npx expo run:ios`

*If dev build not available, Wave 0 must produce one before any verification begins.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual polish (charts, toasts, animations) | VERIFY-01 | Visual correctness needs human eyes via simulator screenshots | Take screenshots at each verification point, compare to expected |
| Full workout flow | VERIFY-02 | End-to-end user flow with real UI interactions | Use Simulator MCP to tap through workout start → sets → finish |
| Offline sync | VERIFY-03 | Requires network state changes + app kill | Script: disable network → workout → kill → relaunch → enable network → verify |
| Auth flows | VERIFY-04 | Platform-specific auth UIs (Apple/Google sign-in) | Test each provider on simulator + Firebase Emulator |
| Physical device haptics | Deferred | Requires physical device | Deferred to Phase 18 |
| Real push notifications | Deferred | Requires APNs/FCM on device | Deferred to Phase 18 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
