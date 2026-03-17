---
phase: 18
slug: foundation-config-build-infrastructure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-17
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30.3.0 + jest-expo 55.0.9 |
| **Config file** | jest.config.js (root level) |
| **Quick run command** | `npx jest --passWithNoTests` |
| **Full suite command** | `npx jest --passWithNoTests` |
| **Estimated runtime** | ~60 seconds |

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
| 18-01-01 | 01 | 1 | SEC-04 | smoke | `npx jest __tests__/config/app-json.test.ts` | created by 18-01-02 | pending |
| 18-01-02 | 01 | 1 | STORE-01 | smoke | `npx jest __tests__/config/eas-json.test.ts` | created in this task | pending |
| 18-02-01 | 02 | 2 | SEC-03 | manual | N/A — EAS build status check + human checkpoint | N/A | pending |
| 18-02-02 | 02 | 2 | SEC-03 | manual | N/A — Firebase Console check (checkpoint:human-verify) | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Wave 0 test files (`__tests__/config/app-json.test.ts` and `__tests__/config/eas-json.test.ts`) are created by Task 2 of Plan 18-01, which is in the same Wave 1 plan as the config changes in Task 1. This satisfies the Nyquist requirement because the tests are written and run within the same plan execution before the plan is marked complete. No separate Wave 0 plan is needed.

- [x] `__tests__/config/app-json.test.ts` — validates app.json plugins array includes all RNFB modules, privacyManifests structure matches legacy plist, iOS entitlements for messaging
- [x] `__tests__/config/eas-json.test.ts` — validates eas.json has submit.production with ios.ascAppId and android.track

*Existing test infrastructure covers remaining phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Gate |
|----------|-------------|------------|------|
| App Check shows DeviceCheck (iOS) + Play Integrity (Android) in production mode | SEC-03 | Requires physical device + Firebase Console dashboard check | Plan 18-02 Task 2 (checkpoint:human-verify) |
| EAS dev build installs and runs with no missing native module errors | STORE-01 | Requires actual EAS build and device install | Plan 18-02 Task 2 (checkpoint:human-verify) |
| PrivacyInfo.xcprivacy present in built IPA | SEC-04 | Requires inspecting actual build artifact | Plan 18-02 Task 2 (checkpoint:human-verify) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (fulfilled within Plan 18-01 Task 2)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
