---
phase: 12
slug: fix-firestore-pain-log-rules
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 30 via `jest-expo` preset |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `npm test` |
| **Full suite command** | `npm run test:rules` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npm test`
- **After every plan wave:** Run `npm run test:rules`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | INJR-03 | rules integration | `npm run test:rules` | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | INJR-03 | rules integration | `npm run test:rules` | ✅ | ⬜ pending |
| 12-01-03 | 01 | 1 | INJR-03 | rules integration | `npm run test:rules` | ✅ | ⬜ pending |
| 12-01-04 | 01 | 1 | INJR-04 | rules integration | `npm run test:rules` | ✅ | ⬜ pending |
| 12-01-05 | 01 | 1 | INJR-04 | rules integration | `npm run test:rules` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pain log persists after app restart | INJR-03 | Requires live Firestore + real device | 1. Log pain level, 2. Force-quit app, 3. Reopen, verify log persists |
| Pain trend chart renders with real data | INJR-04 | Visual verification | 1. Log 3+ pain entries, 2. Navigate to injury detail, 3. Verify chart displays trend |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
