---
phase: 15
slug: wire-ai-preview-adaptation-context
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-16
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest (jest-expo preset) |
| **Config file** | `SundeeFundeeRN/jest.config.js` |
| **Quick run command** | `cd SundeeFundeeRN && npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx --no-coverage` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --no-coverage` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx --no-coverage`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --no-coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 0 | CYAD-03, AIWK-05 | unit | `npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx --no-coverage` | ❌ W0 | ⬜ pending |
| 15-01-02 | 01 | 1 | AIWK-05 | unit | `npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx -t "adaptation-chip" --no-coverage` | ❌ W0 | ⬜ pending |
| 15-01-03 | 01 | 1 | CYAD-03 | unit | `npx jest app/\(app\)/ai-workout/__tests__/preview.test.tsx -t "readiness" --no-coverage` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `app/(app)/ai-workout/__tests__/preview.test.tsx` — stubs for CYAD-03 and AIWK-05 display, tests shared state unpacking, chip visibility

*config.test.tsx exists and covers shared state write path; preview.test.tsx is the only missing file.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AdaptationChip visually renders correct icons/colors | AIWK-05 | Visual rendering not testable in Jest | 1. Open AI workout config 2. Generate workout 3. Verify preview shows adaptation chips with cycle/injury/readiness data |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
