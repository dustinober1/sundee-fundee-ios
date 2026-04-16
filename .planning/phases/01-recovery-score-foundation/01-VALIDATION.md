---
phase: 1
slug: recovery-score-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-15
---

# Phase 1 -- Validation Strategy

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
| 1-01-01 | 01 | 1 | REC-02, REC-04, REC-06 | T-01-02 | nil-returns-nil | unit | `swift test --filter RecoveryScoreCalculatorTests` | Created by Plan 01 Task 1 | pending |
| 1-02-01 | 02 | 1 | HK-01, HK-02, HK-03 | T-01-05 | empty-returns-0 | unit | `swift test --filter SleepDeduplicatorTests` | Created by Plan 02 Task 1 | pending |
| 1-03-01 | 03 | 2 | REC-02, REC-05 | T-01-07, T-01-08 | guest-guard | integration | `swift test` | N/A (ViewModel, no dedicated test) | pending |
| 1-04-01 | 04 | 2 | REC-01, REC-03, REC-06 | T-01-10 | — | build | `swift test` | N/A (UI views) | pending |
| 1-05-01 | 05 | 3 | REC-01, REC-03, REC-05 | T-01-12 | guest-placeholder | manual + build | `swift test` | N/A (wiring) | pending |

*Status: pending -- ✅ green -- red -- flaky*

---

## Wave 0 Requirements

- [ ] `Tests/SundeeFundeeKitTests/DomainTests/RecoveryScoreCalculatorTests.swift` -- stubs for REC-02, REC-04, REC-06 (created by Plan 01 Task 1 as TDD RED phase)
- [ ] `Tests/SundeeFundeeKitTests/DataLayerTests/SleepDeduplicatorTests.swift` -- stubs for HK-03 (created by Plan 02 Task 1 as TDD RED phase)

*Both test files are created as part of the TDD plans (01-01 and 01-02) in Wave 1. No separate Wave 0 step is needed -- the TDD RED phase IS the test scaffold.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recovery score card visible on dashboard | REC-01 | UI visual check | Open app -> Dashboard -> verify score card renders with color |
| Tap score card navigates to breakdown | REC-03 | Navigation + UI | Tap score card -> verify breakdown screen appears |
| 30-day trend chart with cycle bands | REC-05 | Chart visual rendering | Navigate to trend -> verify chart with phase bands |
| CloudKit record type creation | -- | Dashboard manual step | CloudKit Dashboard -> verify RecoveryScore record type + recordName QUERYABLE index exists |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
