---
phase: 3
slug: security-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (rules)** | `@firebase/rules-unit-testing` + Firebase Emulator |
| **Framework (functions)** | Jest 29.x + ts-jest |
| **Config file (rules)** | `jest.rules.config.js` at repo root (Wave 0 installs) |
| **Config file (functions)** | `functions/jest.config.js` (exists) |
| **Quick run command** | `cd functions && npx jest generateAIWorkout` |
| **Full suite command** | `cd functions && npm test` + `firebase emulators:exec --only firestore 'npx jest --config jest.rules.config.js'` |
| **Estimated runtime** | ~15 seconds (functions) + ~10 seconds (rules w/ emulator) |

---

## Sampling Rate

- **After every task commit:** Run `cd functions && npx jest generateAIWorkout`
- **After every plan wave:** Run full suite command (both functions + rules tests)
- **Before `/gsd:verify-work`:** Full suite must be green + manual CSP curl check
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 0 | SEC-01, SEC-02 | infra | `ls firestore.rules firestore.rules.test.ts` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | SEC-01 | unit (rules) | `firebase emulators:exec --only firestore 'npx jest --config jest.rules.config.js'` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | SEC-02 | unit (rules) | Same as above | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | SEC-04 | unit (functions) | `cd functions && npx jest generateAIWorkout` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | SEC-03 | manual smoke | `curl -I https://sundeefundee.web.app/` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `firestore.rules` — create at repo root (copy from worktree, add depth-2 wildcard + premiumEntitlement block)
- [ ] `firestore.rules.test.ts` — create at repo root (copy from worktree, add SEC-02 + depth-2 tests)
- [ ] `jest.rules.config.js` — Jest config at repo root for rules tests
- [ ] `@firebase/rules-unit-testing` — install at repo root
- [ ] `functions/__mocks__/firebase-admin-firestore.ts` — extend with `runTransaction` mock
- [ ] `functions/src/__tests__/generateAIWorkout.test.ts` — add rate limit test cases

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CSP header present and correct | SEC-03 | Firebase Hosting headers only served in deployed environment | 1. Deploy to Firebase Hosting 2. `curl -I https://sundeefundee.web.app/` 3. Verify `Content-Security-Policy` header present 4. Open app in browser, check DevTools console for CSP violations |
| CSP does not block app functionality | SEC-03 | Requires live browser with full Firebase/Stripe SDK loaded | 1. Open deployed app 2. Navigate all major features 3. Verify no CSP errors in DevTools console |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 25s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
