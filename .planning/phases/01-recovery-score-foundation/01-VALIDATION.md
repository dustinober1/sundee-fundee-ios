---
phase: 1
slug: recovery-score-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing + XCTest |
| **Config file** | `SundeeFundee/Package.swift` |
| **Quick run command** | `cd SundeeFundee && swift test` |
| **Full suite command** | `cd SundeeFundee && swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundee && swift test`
- **After every plan wave:** Run `cd SundeeFundee && swift test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | HK-01 | — | N/A | unit | `swift test --filter RecoveryScoreTests` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 1 | HK-02 | — | N/A | unit | `swift test --filter SleepScorerTests` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | HK-03 | — | N/A | unit | `swift test --filter HRVScorerTests` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 1 | REC-01 | — | N/A | unit | `swift test --filter RecoveryScoreCalculatorTests` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 1 | REC-02 | — | N/A | unit | `swift test --filter WeightRedistributionTests` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 2 | REC-03 | — | N/A | unit | `swift test --filter RecoveryBreakdownTests` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 2 | REC-04 | — | N/A | unit | `swift test --filter HRVBaselineTests` | ❌ W0 | ⬜ pending |
| 1-04-01 | 04 | 2 | REC-05 | — | N/A | unit | `swift test --filter RecoveryTrendTests` | ❌ W0 | ⬜ pending |
| 1-04-02 | 04 | 2 | REC-06 | — | N/A | unit | `swift test --filter RecoveryScoreIntegrationTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/SundeeFundeeKitTests/DomainTests/RecoveryScoreCalculatorTests.swift` — stubs for REC-01, REC-02
- [ ] `Tests/SundeeFundeeKitTests/DomainTests/HRVScorerTests.swift` — stubs for HK-03, REC-04
- [ ] `Tests/SundeeFundeeKitTests/DomainTests/SleepScorerTests.swift` — stubs for HK-02
- [ ] `Tests/SundeeFundeeKitTests/DomainTests/TrainingLoadScorerTests.swift` — stubs for REC-01
- [ ] `Tests/SundeeFundeeKitTests/DomainTests/SleepDeduplicatorTests.swift` — stubs for sleep dedup logic

*Existing test infrastructure covers framework setup. Only test files for new domain types needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recovery score card visible on dashboard | REC-05 | UI visual check | Open app → Dashboard → verify score card renders with color |
| Tap score card navigates to breakdown | REC-03 | Navigation + UI | Tap score card → verify breakdown screen appears |
| 30-day trend chart with cycle bands | REC-06 | Chart visual rendering | Navigate to trend → verify chart with phase bands |
| CloudKit record type creation | HK-01 | Dashboard manual step | CloudKit Dashboard → verify RecoveryScore record type exists |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
