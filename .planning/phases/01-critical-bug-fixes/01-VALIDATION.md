---
phase: 1
slug: critical-bug-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`) — Xcode 16 native |
| **Config file** | Xcode scheme / xctest target `SundeeFundeTests` |
| **Quick run command** | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SundeeFundeTests/{TestClass}` |
| **Full suite command** | `xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `-only-testing:SundeeFundeTests/{relevant test class}`
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | FIX-01 | unit | `-only-testing:SundeeFundeTests/GeminiPromptBuilderTests` | Partial — kg tests needed | ⬜ pending |
| 01-02-01 | 02 | 1 | FIX-02 | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | Partial — V12 tests needed | ⬜ pending |
| 01-03-01 | 03 | 1 | FIX-03 | unit | `-only-testing:SundeeFundeTests/AppAuthCoverageTests` | ❌ W0 — new tests needed | ⬜ pending |
| 01-04-01 | 04 | 1 | FIX-04 | unit | `-only-testing:SundeeFundeTests/SubscriptionServiceTests` | Partial — remove conflicting test | ⬜ pending |
| 01-05-01 | 05 | 1 | FIX-05 | smoke | Manual device test | N/A (manual) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New test cases in `GeminiPromptBuilderTests.swift` — kg system prompt, kg maxes conversion, kg body weight (FIX-01)
- [ ] New test cases in `AppAuthCoverageTests.swift` — sign-out V12 scope, delete-account V12 completeness (FIX-02)
- [ ] New test cases in `AppAuthCoverageTests.swift` — guest UUID Keychain persistence, batch migration (FIX-03)
- [ ] Delete `restoresTierFromUserDefaults` test in `SubscriptionServiceTests.swift` — behavior intentionally removed by FIX-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Local persistent container opens without crash after migration | FIX-05 | SwiftData migration cannot be unit tested — requires actual persistent store | 1. Install previous build. 2. Create data. 3. Install new build. 4. Verify app boots without crash. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
