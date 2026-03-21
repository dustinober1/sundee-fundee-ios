---
phase: 2
slug: cloud-functions
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-21
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 4.x (PWA) + Jest 29.x (Functions) |
| **Config file** | `pwa/vitest.config.ts`, `functions/jest.config.js` |
| **Quick run command** | `cd functions && npx jest --passWithNoTests` |
| **Full suite command** | `cd pwa && npx vitest run && cd ../functions && npx jest` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd functions && npx jest --passWithNoTests`
- **After every plan wave:** Run `cd pwa && npx vitest run && cd ../functions && npx jest`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-00-01 | 00 | 0 | BACK-01,02,03 | stub | `cd functions && npx jest --passWithNoTests` | Wave 0 creates | ⬜ pending |
| 02-01-01 | 01 | 1 | BACK-01 | unit | `cd functions && npx tsc --noEmit` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | BACK-01 | unit | `cd functions && npx jest -- src/__tests__/generateAIWorkout.test.ts` | ✅ (Wave 0) | ⬜ pending |
| 02-02-01 | 02 | 2 | BACK-02,03 | unit | `cd functions && npx jest` | ✅ (Wave 0) | ⬜ pending |
| 02-02-02 | 02 | 2 | BACK-02,03 | config | `grep -q 'Deploy Cloud Functions' .github/workflows/deploy.yml` | ✅ | ⬜ pending |
| 02-02-03 | 02 | 2 | BACK-02,03 | checkpoint | manual human verify | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `functions/src/__tests__/generateAIWorkout.test.ts` — unit test stubs for BACK-01 function logic (created by 02-00)
- [x] `functions/src/__tests__/createCheckoutSession.test.ts` — unit test stubs for BACK-02 checkout + portal (created by 02-00)
- [x] `functions/src/__tests__/stripeWebhook.test.ts` — unit test stubs for BACK-03 webhook (created by 02-00)

*Wave 0 plan (02-00) creates all test stubs before any implementation begins.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stripe webhook writes entitlement to Firestore | BACK-03 | Requires Stripe CLI + Firebase emulator running together | 1. Start `firebase emulators:start --only functions,firestore` 2. Run `stripe listen --forward-to localhost:5001/sundee-fundee/us-central1/stripeWebhook` 3. Run `stripe trigger checkout.session.completed` 4. Check Firestore emulator for `premiumEntitlement.active = true` |
| Stripe Checkout redirects to hosted page | BACK-02 | Requires live Stripe test mode session | 1. Call `createStripeCheckoutSession` via emulator 2. Verify returned URL starts with `https://checkout.stripe.com` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
