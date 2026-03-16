---
phase: 6
slug: subscriptions-and-monetization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest-expo (jest ^29.7.0) for RN; jest for Cloud Functions |
| **Config file** | `SundeeFundeeRN/jest.config.js` (RN), `functions/jest.config.js` (functions) |
| **Quick run command** | `cd SundeeFundeeRN && npx jest src/entitlements/ --no-coverage` + `cd functions && npm test` |
| **Full suite command** | `cd SundeeFundeeRN && npx jest --coverage` + `cd functions && npm test` |
| **Estimated runtime** | ~30 seconds (RN) + ~10 seconds (functions) |

---

## Sampling Rate

- **After every task commit:** Run `cd SundeeFundeeRN && npx jest src/entitlements/ --no-coverage` + `cd functions && npm test`
- **After every plan wave:** Run `cd SundeeFundeeRN && npx jest --coverage` + `cd functions && npm test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 40 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | SUBS-01 | unit | `cd SundeeFundeeRN && npx jest src/entitlements/ -t "configure"` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | SUBS-01 | unit | `cd SundeeFundeeRN && npx jest src/entitlements/ -t "logIn"` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | SUBS-01, SUBS-04 | unit | `cd SundeeFundeeRN && npx jest src/entitlements/ -t "useEntitlements"` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 1 | SUBS-02 | unit | `cd functions && npm test -- --testNamePattern="createCheckoutSession"` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | SUBS-03 | unit | `cd functions && npm test -- --testNamePattern="stripeWebhook"` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 2 | SUBS-04 | unit | `cd SundeeFundeeRN && npx jest src/components/paywall/ -t "PaywallModal"` | ❌ W0 | ⬜ pending |
| 06-03-02 | 03 | 2 | SUBS-04 | unit | `cd SundeeFundeeRN && npx jest src/ -t "premium feature gate"` | ❌ W0 | ⬜ pending |
| 06-04-01 | 04 | 2 | SUBS-05 | unit | `cd SundeeFundeeRN && npx jest app/ -t "subscription settings"` | ❌ W0 | ⬜ pending |
| 06-04-02 | 04 | 2 | SUBS-05 | unit | `cd SundeeFundeeRN && npx jest app/ -t "restore purchases"` | ❌ W0 | ⬜ pending |
| 06-05-01 | 05 | 3 | SUBS-04 | unit | `cd SundeeFundeeRN && npx jest src/ -t "trial banner"` | ❌ W0 | ⬜ pending |
| 06-05-02 | 05 | 3 | SUBS-04 | unit | `cd SundeeFundeeRN && npx jest src/ -t "trial ended modal"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `SundeeFundeeRN/src/entitlements/__tests__/useEntitlements.test.ts` — stubs for SUBS-01, SUBS-03, SUBS-04
- [ ] `SundeeFundeeRN/src/components/paywall/__tests__/PaywallModal.test.tsx` — stubs for SUBS-01, SUBS-04
- [ ] `functions/src/__tests__/createCheckoutSession.test.ts` — stubs for SUBS-02
- [ ] `functions/src/__tests__/stripeWebhook.test.ts` — stubs for SUBS-03
- [ ] `functions/__mocks__/stripe.ts` — Stripe SDK mock
- [ ] Install stripe in functions: `cd functions && npm install stripe`
- [ ] Add env vars: `EXPO_PUBLIC_RC_APPLE_API_KEY`, `EXPO_PUBLIC_RC_GOOGLE_API_KEY`
- [ ] Add Firebase Secrets: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `RC_SECRET_API_KEY`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App Store/Play Store purchase flow completes | SUBS-01 | Requires real store sandbox | Use TestFlight + sandbox Apple ID; verify entitlement activates |
| Stripe Checkout redirect renders and completes | SUBS-02 | Requires Stripe test mode + browser | Use Stripe test card 4242...; verify success redirect |
| Cross-platform entitlement sync < 60s | SUBS-03 | End-to-end timing | Subscribe on web, check mobile within 60s |
| App Store subscription management deep link opens | SUBS-05 | Requires real device | Tap "Manage Subscription" on iOS device |
| Trial countdown banner appears on days 6-7 only | SUBS-04 | Time-dependent UI | Adjust device date or use short trial for testing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 40s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
