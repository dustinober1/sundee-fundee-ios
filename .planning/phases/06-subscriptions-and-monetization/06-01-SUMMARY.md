---
phase: 06-subscriptions-and-monetization
plan: 01
subsystem: payments
tags: [stripe, revenuecat, firebase-functions, cloud-functions, webhooks, firestore, subscriptions]

# Dependency graph
requires:
  - phase: 05-differentiating-features
    provides: generateWorkout Cloud Function and functions infrastructure (package.json, mocks, index.ts)
provides:
  - createCheckoutSession onCall Cloud Function for Stripe Checkout session creation with 7-day trial
  - stripeWebhook onRequest Cloud Function for Stripe event handling, RC entitlement grant/revoke, Firestore premiumEntitlement writes
  - stripe npm dependency in functions/package.json
affects: [06-subscriptions-and-monetization, paywall-ui, web-entitlement-reads]

# Tech tracking
tech-stack:
  added: [stripe@20.4.1]
  patterns:
    - onCall Cloud Function with defineSecret for Stripe API key injection
    - onRequest webhook handler using rawBody for Stripe signature verification
    - RevenueCat promotional entitlement grant/revoke via REST API (POST/DELETE)
    - Firestore premiumEntitlement merge-set pattern for web entitlement state sync

key-files:
  created:
    - functions/src/createCheckoutSession.ts
    - functions/src/stripeWebhook.ts
    - functions/__mocks__/stripe.ts
    - functions/__mocks__/firebase-functions-logger.ts
    - functions/src/__tests__/createCheckoutSession.test.ts
    - functions/src/__tests__/stripeWebhook.test.ts
  modified:
    - functions/src/index.ts
    - functions/package.json
    - functions/__mocks__/firebase-admin.ts
    - functions/__mocks__/firebase-functions.ts

key-decisions:
  - "stripeWebhook uses rawBody (not body) for Stripe signature verification — required by Stripe SDK constructEvent"
  - "past_due included in ACTIVE_STATUSES set — provides grace period so subscriptions are not immediately revoked on failed payment"
  - "Firestore premiumEntitlement write wrapped in try/catch and returns 200 to Stripe regardless — prevents Stripe retry storms from Firestore transient errors"
  - "RC entitlement uses 'lifetime' duration for promotional grant — entitlement is managed by webhook revoke, not by RC expiry"
  - "firebase-functions mock extended with onRequest export — required for stripeWebhook handler to be directly testable"
  - "firebase-admin mock extended with direct doc() method and Timestamp.now() — stripeWebhook uses firestore().doc() path not firestore().collection().doc()"
  - "jest.spyOn(global, 'fetch') at module level mocks RC API calls — avoids real network calls in tests"

patterns-established:
  - "Stripe webhook function: verify sig with rawBody -> extract firebaseUID from metadata -> grant/revoke RC -> write Firestore -> return 200"
  - "RC entitlement via REST: POST /v1/subscribers/{uid}/entitlements/premium/promotional with duration:lifetime to grant; DELETE same URL to revoke"

requirements-completed: [SUBS-02, SUBS-03]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 06 Plan 01: Stripe Checkout and Webhook Cloud Functions Summary

**Stripe Checkout onCall and webhook onRequest Cloud Functions bridging subscription events to RevenueCat entitlement grant/revoke and Firestore premiumEntitlement writes**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T17:18:08Z
- **Completed:** 2026-03-15T17:21:40Z
- **Tasks:** 1
- **Files modified:** 11

## Accomplishments

- createCheckoutSession onCall function creates Stripe Checkout sessions with 7-day trial, firebaseUID in subscription metadata, payment_method_collection: if_required, returns session URL
- stripeWebhook onRequest function verifies Stripe signature using rawBody, grants RevenueCat 'premium' entitlement on subscription.created/updated (active/trialing/past_due) and revokes on subscription.deleted or non-active status
- Firestore /users/{uid} premiumEntitlement field updated on every grant (active:true) and revoke (active:false, expiresAt:Timestamp.now()) for web onSnapshot reads
- All 26 tests pass (9 for stripeWebhook, 4 for createCheckoutSession, 13 pre-existing for generateWorkout)

## Task Commits

Each task was committed atomically:

1. **Task 1: Install Stripe, create Cloud Functions with tests** - `8aaab9a` (feat)

**Plan metadata:** (docs commit follows)

_Note: TDD task — tests written before implementation, both RED→GREEN confirmed_

## Files Created/Modified

- `functions/src/createCheckoutSession.ts` - onCall function for Stripe Checkout session creation
- `functions/src/stripeWebhook.ts` - onRequest function for Stripe webhook handling, RC entitlement management, and Firestore writes
- `functions/src/__tests__/createCheckoutSession.test.ts` - Unit tests for checkout session creation (4 tests)
- `functions/src/__tests__/stripeWebhook.test.ts` - Unit tests for webhook handling including Firestore write assertions (9 tests)
- `functions/__mocks__/stripe.ts` - Mock Stripe constructor with checkout.sessions.create and webhooks.constructEvent mocks
- `functions/__mocks__/firebase-functions-logger.ts` - Mock for firebase-functions/logger
- `functions/__mocks__/firebase-admin.ts` - Updated to support firestore().doc() direct call and Timestamp.now()
- `functions/__mocks__/firebase-functions.ts` - Updated to add onRequest mock export
- `functions/src/index.ts` - Added exports for createCheckoutSession and stripeWebhook
- `functions/package.json` - Added stripe dependency and jest moduleNameMapper entries

## Decisions Made

- `rawBody` used (not `body`) for Stripe signature verification — required by Stripe SDK `constructEvent`
- `past_due` included in ACTIVE_STATUSES — grace period prevents immediate revocation on failed payment
- RC entitlement uses `'lifetime'` duration for promotional grant — expiry is managed via webhook revoke events, not RC's own TTL
- Firestore writes wrapped in try/catch and always return 200 to Stripe — prevents retry storms from transient Firestore errors
- `firebase-admin` mock extended with direct `firestore().doc()` path and `firestore.Timestamp.now()` to match stripeWebhook's usage pattern

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed test makeReq helper to correctly omit stripe-signature header**
- **Found during:** Task 1 (GREEN phase — test for missing signature was passing through)
- **Issue:** `makeReq({ headers: {} })` spread an empty object AFTER the default headers object, resulting in `{ "stripe-signature": "valid-sig" }` still being present — test was not actually testing the missing-signature path
- **Fix:** Changed `makeReq` to replace headers entirely when `overrides.headers` is provided, rather than spreading over defaults
- **Files modified:** functions/src/__tests__/stripeWebhook.test.ts
- **Verification:** Test correctly exercises the `if (!sig)` guard and returns 400
- **Committed in:** 8aaab9a (Task 1 commit)

**2. [Rule 3 - Blocking] Added onRequest export to firebase-functions mock**
- **Found during:** Task 1 (stripeWebhook imports onRequest from firebase-functions/v2/https)
- **Issue:** Existing mock only exported onCall and HttpsError; onRequest was undefined
- **Fix:** Added `export const onRequest = (_config, handler) => handler` to firebase-functions mock
- **Files modified:** functions/__mocks__/firebase-functions.ts
- **Committed in:** 8aaab9a (Task 1 commit)

**3. [Rule 3 - Blocking] Added firebase-functions/logger mock and moduleNameMapper entry**
- **Found during:** Task 1 (stripeWebhook imports logger from firebase-functions/logger)
- **Issue:** No mock existed for firebase-functions/logger; jest would fail to resolve the import
- **Fix:** Created __mocks__/firebase-functions-logger.ts and added moduleNameMapper entry in package.json
- **Files modified:** functions/__mocks__/firebase-functions-logger.ts, functions/package.json
- **Committed in:** 8aaab9a (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 3 - Blocking)
**Impact on plan:** All fixes necessary for test correctness and module resolution. No scope creep.

## Issues Encountered

None beyond the three auto-fixed deviations above.

## User Setup Required

**External services require manual configuration.** The following secrets must be configured before deploying these functions:

- `STRIPE_SECRET_KEY` — Stripe Dashboard -> Developers -> API keys -> Secret key
- `STRIPE_WEBHOOK_SECRET` — Stripe Dashboard -> Developers -> Webhooks -> Signing secret (after creating webhook endpoint pointing to the stripeWebhook Cloud Function URL)
- `RC_SECRET_API_KEY` — RevenueCat Dashboard -> Project -> API Keys -> Secret API key (v1)

Dashboard configuration needed:
1. Create Stripe products: monthly ($7.99) and annual ($47.99) subscription prices
2. Create RevenueCat 'premium' entitlement in your project
3. Create Stripe webhook endpoint pointing to your deployed stripeWebhook function URL for events: customer.subscription.created, customer.subscription.updated, customer.subscription.deleted

## Next Phase Readiness

- Cloud Functions are deployed-ready; secrets and Stripe/RC dashboard setup needed before live testing
- Plan 06-02 (paywall UI) can use `createCheckoutSession` onCall function via Firebase SDK
- Web clients can read `premiumEntitlement` from Firestore `/users/{uid}` via `onSnapshot` for real-time entitlement state

---
*Phase: 06-subscriptions-and-monetization*
*Completed: 2026-03-15*
