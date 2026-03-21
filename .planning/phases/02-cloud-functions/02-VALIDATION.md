---
phase: 2
slug: cloud-functions
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 4.x (PWA) + manual emulator smoke (Functions) |
| **Config file** | `pwa/vitest.config.ts` |
| **Quick run command** | `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts` |
| **Full suite command** | `cd pwa && npx vitest run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts`
- **After every plan wave:** Run `cd pwa && npx vitest run`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | BACK-01 | unit | `cd pwa && npx vitest run` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | BACK-01 | unit | `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 1 | BACK-02 | unit | `cd pwa && npx vitest run` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | BACK-03 | integration | `stripe trigger checkout.session.completed` | ❌ manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `functions/src/__tests__/generateAIWorkout.test.ts` — unit test stubs for BACK-01 function logic
- [ ] `functions/src/__tests__/createCheckoutSession.test.ts` — unit test stubs for BACK-02
- [ ] `functions/src/__tests__/stripeWebhook.test.ts` — unit test stubs for BACK-03

*Existing `pwa/src/domain/__tests__/ai-workout.test.ts` covers domain logic. Function-level tests are new.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stripe webhook writes entitlement to Firestore | BACK-03 | Requires Stripe CLI + Firebase emulator running together | 1. Start `firebase emulators:start --only functions,firestore` 2. Run `stripe listen --forward-to localhost:5001/sundee-fundee/us-central1/stripeWebhook` 3. Run `stripe trigger checkout.session.completed` 4. Check Firestore emulator for `premiumEntitlement.active = true` |
| Stripe Checkout redirects to hosted page | BACK-02 | Requires live Stripe test mode session | 1. Call `createStripeCheckoutSession` via emulator 2. Verify returned URL starts with `https://checkout.stripe.com` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
