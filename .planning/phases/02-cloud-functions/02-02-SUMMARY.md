---
phase: 02-cloud-functions
plan: 02
subsystem: backend/cloud-functions
tags: [stripe, cloud-functions, checkout, billing-portal, webhook, firebase-functions, tdd]
dependency_graph:
  requires: [02-01]
  provides: [createStripeCheckoutSession, createStripePortalSession, stripeWebhook, functions-deploy-pipeline]
  affects: [functions/src/index.ts, .github/workflows/deploy.yml, pwa/src/entitlements/stripe-checkout.ts]
tech_stack:
  added: [stripe@^17]
  patterns: [Firebase-Functions-v2-onCall, Firebase-Functions-v2-onRequest, Stripe-Checkout-redirect, Stripe-Billing-Portal, Stripe-Webhook-signature-verification, TDD-module-mapper-pattern]
key_files:
  created:
    - functions/src/createCheckoutSession.ts
    - functions/src/stripeWebhook.ts
    - functions/__mocks__/firebase-admin-firestore.ts
  modified:
    - functions/src/index.ts
    - functions/src/__tests__/createCheckoutSession.test.ts
    - functions/src/__tests__/stripeWebhook.test.ts
    - functions/__mocks__/firebase-functions.ts
    - functions/package.json
    - .github/workflows/deploy.yml
decisions:
  - "Require firebase-admin/firestore via mapped name (not relative path) in tests so Jest shares the same module cache instance as the implementation"
  - "Firestore mock uses module-level mutable delegation pattern — stable doc ref delegates to swappable handler functions, giving tests control without fighting clearAllMocks"
  - "Service account key written via env var in deploy step (not inline echo) to avoid security hook violation"
metrics:
  duration_minutes: 9
  completed_date: "2026-03-21"
  tasks_completed: 2
  files_changed: 8
---

# Phase 02 Plan 02: Stripe Checkout, Portal, and Webhook Cloud Functions Summary

**One-liner:** Stripe Checkout and Billing Portal onCall functions plus signature-verified webhook that writes premiumEntitlement to Firestore, with deploy pipeline updated to build and ship Cloud Functions alongside hosting.

## What Was Built

### Task 1: createStripeCheckoutSession, createStripePortalSession, stripeWebhook (TDD)

**RED phase:** Replaced Wave 0 stubs with real behavioral tests covering all 8 behaviors (auth gates, URL returns, customer metadata, signature verification, Firestore writes).

**GREEN phase:** Implemented three functions:

**`functions/src/createCheckoutSession.ts`:**
- `createStripeCheckoutSession` (onCall, auth-gated): checks Firestore for existing `stripeCustomerId`; creates new Stripe customer with `metadata.firebaseUID = uid` if none; creates Checkout session with `mode: 'subscription'`; returns `{ url: session.url }`
- `createStripePortalSession` (onCall, auth-gated): looks up `stripeCustomerId` from Firestore `premiumEntitlement`; throws `failed-precondition` if not found; creates Billing Portal session; returns `{ url: portalSession.url }`

**`functions/src/stripeWebhook.ts`:**
- `stripeWebhook` (onRequest): returns 400 if `stripe-signature` header missing; verifies signature via `stripe.webhooks.constructEvent(request.rawBody, sig, webhookSecret)` (critical: uses rawBody not body); handles `checkout.session.completed` → retrieves customer metadata.firebaseUID → writes `premiumEntitlement: { active: true, stripeCustomerId, subscriptionId, activatedAt }`; handles `customer.subscription.deleted` → writes `premiumEntitlement: { active: false, cancelledAt }`; always returns `{ received: true }` on success

**`functions/src/index.ts`:** Updated to export all 4 Cloud Functions: `generateAIWorkout`, `createStripeCheckoutSession`, `createStripePortalSession`, `stripeWebhook`.

**Test infrastructure additions:**
- `functions/__mocks__/firebase-admin-firestore.ts`: new mock using mutable delegation pattern (stable doc ref delegates to swappable `_handleGet`/`_handleSet`/`_handleUpdate` functions, giving tests control via `setMockGetResult()`, `getHandlers()`, `resetFirestoreMocks()`)
- `functions/__mocks__/firebase-functions.ts`: added `onRequest` mock
- `functions/package.json`: added `firebase-admin/firestore` → mock mapping to moduleNameMapper

**Results:** 14/14 tests pass, `npx tsc --noEmit` clean.

### Task 2: Update deploy workflow

Updated `.github/workflows/deploy.yml`:
- Added `functions/package-lock.json` to `cache-dependency-path` for npm cache efficiency
- Added `Install functions dependencies` step (`npm ci` in `functions/`)
- Added `Build functions` step (`npm run build` in `functions/`)
- Added `Deploy Cloud Functions` step: writes SA key via `env:` block (not inline echo), sets `GOOGLE_APPLICATION_CREDENTIALS`, runs `firebase-tools deploy --only functions --project sundee-fundee --force`
- Deployment remains `workflow_dispatch` only (no auto-deploy on push)

## Test Results

- `functions npx tsc --noEmit`: PASS
- `functions npx jest`: 14/14 PASS (3 suites)
- `pwa npx tsc -b --noEmit`: PASS
- `pwa npx vitest run`: 773/773 PASS (no regressions)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Jest module cache isolation between test and implementation**
- **Found during:** Task 1 TDD GREEN phase
- **Issue:** `require('../../__mocks__/firebase-admin-firestore')` from `src/__tests__/` resolves via the real file path, creating a different Jest module cache entry than `import { getFirestore } from 'firebase-admin/firestore'` (which goes through moduleNameMapper). The test and implementation had separate module instances, so test mutations to the mock had no effect on what the implementation called.
- **Fix:** Changed test requires to use `require('firebase-admin/firestore')` (the mapped name) so both test and implementation share the exact same Jest module cache entry. Also redesigned the mock to use a mutable delegation pattern (stable doc ref that delegates to swappable handler functions) instead of trying to control jest.fn() instances across `clearAllMocks()`.
- **Files modified:** `functions/__mocks__/firebase-admin-firestore.ts`, `functions/src/__tests__/createCheckoutSession.test.ts`, `functions/src/__tests__/stripeWebhook.test.ts`
- **Commit:** c5f9f35

**2. [Rule 2 - Security] Service account JSON in deploy step**
- **Found during:** Task 2 implementation
- **Issue:** Security hook flagged `echo '${{ secrets.FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE }}' > /tmp/sa-key.json` as potential injection risk (even though it's a GitHub Secret, not user input).
- **Fix:** Wrote the secret via `env: SA_KEY:` block and used `echo "$SA_KEY"` in the run step, which is the recommended secure pattern.
- **Files modified:** `.github/workflows/deploy.yml`
- **Commit:** fceb3ea

## Commits

| Hash | Type | Description |
|------|------|-------------|
| c5f9f35 | feat | Implement Stripe checkout, portal, and webhook Cloud Functions |
| fceb3ea | feat | Update deploy workflow to build and deploy Cloud Functions |

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| functions/src/createCheckoutSession.ts | FOUND |
| functions/src/stripeWebhook.ts | FOUND |
| functions/src/index.ts exports all 4 | FOUND |
| functions/__mocks__/firebase-admin-firestore.ts | FOUND |
| .github/workflows/deploy.yml has Deploy Cloud Functions | FOUND |
| Commit c5f9f35 | FOUND |
| Commit fceb3ea | FOUND |
| Functions tests 14/14 | PASS |
| PWA tests 773/773 | PASS |
