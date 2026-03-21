---
phase: 7
slug: gap-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (pwa/) + Jest (repo root, rules) |
| **Config file** | `pwa/vitest.config.ts` (component tests); `jest.rules.config.js` (Firestore rules) |
| **Quick run command** | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` |
| **Full suite command** | `cd pwa && npx vitest run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd pwa && npx vitest run src/routes/Dashboard.test.tsx`
- **After every plan wave:** Run `cd pwa && npx vitest run`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 0 | (nyquist) | unit | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | SEC-01, SEC-02 | smoke | `grep -q "firestore" .github/workflows/deploy.yml && echo PASS` | ✅ | ⬜ pending |
| 07-01-03 | 01 | 1 | (route) | unit | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pwa/src/routes/Dashboard.test.tsx` — stubs for route link correctness (Start Workout → /workout-session, AI Workout → /ai-workout/config)

*Existing Firestore rules test infrastructure (`firestore.rules.test.ts`) already covers SEC-01/SEC-02 logic.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Firestore rules actually deployed to production | SEC-01, SEC-02 | Requires actual CI pipeline execution | Trigger deploy.yml on main, verify in Firebase Console > Firestore > Rules |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
