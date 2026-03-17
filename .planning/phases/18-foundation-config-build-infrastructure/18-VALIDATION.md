---
phase: 18
slug: foundation-config-build-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 18-01-01 | 01 | 1 | SEC-04 | smoke | `npx jest __tests__/config/app-json.test.ts` | ❌ W0 | ⬜ pending |
| 18-01-02 | 01 | 1 | STORE-01 | smoke | `npx jest __tests__/config/eas-json.test.ts` | ❌ W0 | ⬜ pending |
| 18-02-01 | 02 | 1 | SEC-03 | manual | N/A — Firebase Console check | N/A | ⬜ pending |
| 18-03-01 | 03 | 2 | STORE-01 | manual | N/A — EAS build must succeed | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `__tests__/config/app-json.test.ts` — validates app.json plugins array includes all RNFB modules, privacyManifests structure matches legacy plist, iOS entitlements for messaging
- [ ] `__tests__/config/eas-json.test.ts` — validates eas.json has submit.production with ios.ascAppId and android.track

*Existing test infrastructure covers remaining phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App Check shows DeviceCheck (iOS) + Play Integrity (Android) in production mode | SEC-03 | Requires physical device + Firebase Console dashboard check | 1. Build EAS dev build 2. Install on physical device 3. Open Firebase Console > App Check 4. Verify production attestation active |
| EAS dev build installs and runs with no missing native module errors | STORE-01 | Requires actual EAS build and device install | 1. Run `eas build --platform all --profile development` 2. Install on iOS + Android 3. Verify messaging/crashlytics/analytics modules load without errors |
| PrivacyInfo.xcprivacy present in built IPA | SEC-04 | Requires inspecting actual build artifact | 1. Build production profile 2. Inspect IPA contents for PrivacyInfo.xcprivacy 3. Verify data types match legacy plist |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
