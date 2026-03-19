---
phase: 2
slug: cloudkit-activation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`) — Xcode 16 native |
| **Config file** | Xcode scheme `SundeeFundee` / xctest target `SundeeFundeTests` |
| **Quick run command** | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/AppInfraCoverageTests` |
| **Full suite command** | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~45 seconds (quick) / ~180 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/AppInfraCoverageTests`
- **After every plan wave:** Run `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green + two-device physical sync test
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SYNC-01 | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | SYNC-01, SYNC-03 | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | SYNC-02 | manual | CloudKit Console visual inspection | N/A | ⬜ pending |
| 02-04-01 | 04 | 1 | SYNC-04 | unit | `-only-testing:SundeeFundeTests/AppInfraCoverageTests` | ❌ W0 | ⬜ pending |
| 02-05-01 | 05 | 2 | SYNC-03 | e2e/manual | Two-device TestFlight sync test | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test in `AppInfraCoverageTests.swift` — verify `GeneratedWorkoutRecord` and `SharedWorkoutTemplateRecord` have no `@Attribute(.unique)` (schema reflection or container-open smoke test)
- [ ] New test in `AppInfraCoverageTests.swift` — verify `makeSharedContainer(useCloudKit: true)` with injected CloudKit failure invokes `onCloudKitFailure` closure and sets alert state
- [ ] Manual test checklist document — two-device TestFlight sync validation steps (Device A write → Device B read)

*Existing infrastructure covers test framework and scheme configuration.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-device sync | SYNC-03 | Requires two physical Apple devices with same iCloud account | 1. Install TestFlight build on Device A and Device B. 2. Log a workout on Device A. 3. Wait 30s. 4. Verify workout appears on Device B. |
| Production schema deployment | SYNC-02 | CloudKit Console is a web UI, not automatable | 1. Open CloudKit Console. 2. Select container. 3. Click "Deploy Schema Changes to Production". 4. Verify all 20 record types present. |
| iCloud unavailable error alert | SYNC-04 | Requires disabling iCloud on device to trigger | 1. Sign out of iCloud on device. 2. Launch app. 3. Verify alert appears saying "iCloud Sync Unavailable". 4. Verify local data is preserved. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
