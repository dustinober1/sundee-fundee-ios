# Phase 6: Subscriptions and Monetization - Research

**Researched:** 2026-03-15
**Domain:** RevenueCat SDK (react-native-purchases v9), Stripe Checkout, Firebase Cloud Functions v2, cross-platform entitlement management
**Confidence:** HIGH (standard stack well-documented; architecture locked in CONTEXT.md matches verified patterns)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Free vs Premium feature split:**
- Free: Custom workout logging, exercise library (200+), workout history, 1RM tracking, maxes tab, benchmark catalog browsing, benchmark recording
- Premium: AI workout generation, cycle adaptation (auto-adjusting load/sets/reps), program catalog access, injury adaptation (auto-substitution of contraindicated exercises)
- Cycle tracking data logging (period dates, phase viewing) stays free — only smart adaptation is premium
- Injury profile creation and pain logging stays free — only automatic exercise substitution is premium
- Guests get free tier only — must create account before subscribing

**Paywall presentation:**
- Full-screen modal triggered on first tap of any premium feature
- No proactive upsell — user discovers paywall naturally
- Premium features visible in UI with lock icon or "Premium" badge — not hidden
- Art Deco styled paywall: clean feature list (4 premium features), pricing cards, annual pre-selected with "Best Value" badge
- Platform-only pricing shown (App Store guideline compliance)

**Pricing:**
- Mobile (iOS/Android via RevenueCat): $9.99/month, $59.99/year
- Web (Stripe Checkout): $7.99/month, $47.99/year
- 7-day free trial on all platforms

**Trial-to-paid conversion:**
- No countdown during first 5 days of trial
- Days 6-7: subtle dismissable banner on dashboard
- Mid-session graceful handling (never interrupt active workout)
- One-time "Your trial ended" modal after expiry

**RevenueCat identity:**
- Purchases.logIn(firebaseUID) immediately after Firebase auth
- Guests skip RC login until account creation
- Guest→auth upgrade triggers Purchases.logIn(newFirebaseUID)
- Firebase UID only in subscriber attributes

**Subscription management:**
- Settings subscription section: plan name, renewal date, "Manage Subscription" link
- Mobile: deep-links to App Store/Play Store subscription management
- Web: Stripe Customer Portal link
- "Restore Purchases" button calls RevenueCat restorePurchases()

**Stripe web checkout flow:**
- Firebase Cloud Function (createCheckoutSession) creates Stripe Checkout session with Firebase UID in metadata
- Stripe Checkout redirect (not embedded)
- Post-payment: sundeefundee.com/subscription/success?session_id=xxx
- Cancel redirect back to paywall page

**Stripe → RevenueCat entitlement sync:**
- Firebase Cloud Function handles Stripe webhook events (subscription.created, subscription.updated, subscription.deleted)
- Webhook handler calls RevenueCat REST API to grant/revoke "premium" entitlement by Firebase UID
- Mobile reads entitlements from RevenueCat as single source of truth
- Target: entitlements sync within 60 seconds of payment

### Claude's Discretion
- Exact paywall modal layout, animations, and Art Deco styling details
- Lock icon/badge design for premium features in free tier
- Trial banner positioning and styling
- "Your trial ended" modal design and feature usage summary format
- Stripe success page design
- RevenueCat SDK configuration details (API key management, configure() call placement)
- Webhook retry and error handling strategy
- Entitlement caching and refresh interval in useEntitlements hook

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SUBS-01 | User can subscribe via in-app purchase (RevenueCat) on iOS and Android | RevenueCat SDK v9 configure/logIn/purchasePackage pattern; Offerings API |
| SUBS-02 | User can subscribe via Stripe web checkout at lower price point | Firebase Cloud Function createCheckoutSession; Stripe Checkout with subscription_data.trial_period_days |
| SUBS-03 | Subscription entitlements sync between mobile and web | RC REST API POST /v1/subscribers/{uid}/entitlements/{id}/promotional; 60s target via webhook |
| SUBS-04 | Premium features gated behind subscription (paywall) | useEntitlements hook upgrade; PaywallModal component; feature-level entitlement checks |
| SUBS-05 | User can manage subscription from settings | iOS: itms-apps://apps.apple.com/account/subscriptions; Android: RC managementURL; Stripe Customer Portal link |
</phase_requirements>

---

## Summary

Phase 6 implements a dual-platform monetization system: RevenueCat handles iOS/Android in-app purchases, while a custom Firebase Cloud Function + Stripe Checkout path handles web purchases at a lower price point. The two systems are unified via RevenueCat's promotional entitlement REST API — the Stripe webhook Cloud Function grants/revokes the "premium" entitlement on the RevenueCat subscriber record keyed by Firebase UID, so all platforms read entitlement status from RevenueCat as a single source of truth.

The existing `useEntitlements` hook in `src/entitlements/useEntitlements.ts` is the primary integration point for all feature gating. It currently returns `isPremium: false` on web (infrastructure stub from Phase 1). Phase 6 upgrades this hook to also check Firebase for web users' entitlement state (written by the webhook handler) and adds `addCustomerInfoUpdateListener` for real-time updates on mobile.

**Note on RevenueCat Web Billing alternative:** RevenueCat released native Web Billing (via `@revenuecat/purchases-js`, v9.7.6+) that abstracts away custom Stripe webhooks. The CONTEXT.md has locked the custom Stripe Cloud Function approach for this project. That approach is correct — it gives direct control over the checkout flow, lower-priced web tiers, and Firebase UID-based entitlement mapping without RevenueCat managing the payment relationship.

**Primary recommendation:** Wire Purchases.logIn(firebaseUID) in the existing `onUserSignIn` callback in SessionProvider. Upgrade `useEntitlements` to add a `Purchases.addCustomerInfoUpdateListener` for real-time mobile updates and a Firestore read for web entitlement state. Build two new Firebase Cloud Functions: `createCheckoutSession` (onCall) and `stripeWebhook` (onRequest).

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| react-native-purchases | ^9.12.0 (installed) | RevenueCat SDK for iOS/Android IAP | Single SDK for both stores, entitlement management, restore purchases |
| stripe (npm) | ^17.x (to install) | Stripe SDK for Cloud Functions backend | Official Node.js library, TypeScript types, webhook signature verification |
| firebase-functions/v2 | ^6.0.0 (installed) | Cloud Functions for checkout + webhook | Already in project; v2 provides rawBody on onRequest |
| firebase-admin | ^12.0.0 (installed) | Firebase Admin for auth verification in Cloud Functions | Already in project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @stripe/stripe-js | ^4.x (web, optional) | Stripe.js for web redirects | Only if embedding Stripe Elements — not needed for Checkout redirect flow |
| expo-linking | (expo built-in) | Opening App Store subscription management URL | Deep-link to `itms-apps://apps.apple.com/account/subscriptions` on iOS |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Stripe + RC REST API (locked) | RevenueCat Web Billing (@revenuecat/purchases-js) | RC Web Billing abstracts webhooks but requires separate `@revenuecat/purchases-js` package, different checkout API, and no lower web pricing tier control |
| Stripe Checkout redirect | Stripe Elements embedded | Redirect is PCI-compliant by default; no custom card UI needed |
| RevenueCat REST API grant entitlement | RC Stripe Server Notifications (direct webhook) | RC Stripe Server Notifications require purchase to already exist in RC system; custom Cloud Function grants entitlement independently, required for external Stripe checkout |

**Installation (functions):**
```bash
cd functions && npm install stripe
```

---

## Architecture Patterns

### Recommended Project Structure
```
SundeeFundeeRN/src/
├── entitlements/
│   ├── useEntitlements.ts         # UPGRADE: add listener + web Firestore check
│   └── EntitlementContext.tsx     # NEW: context provider wrapping useEntitlements
├── components/paywall/
│   ├── PaywallModal.tsx            # NEW: full-screen modal with offerings
│   ├── PremiumBadge.tsx            # NEW: lock icon / "Premium" badge component
│   └── TrialBanner.tsx             # NEW: days 6-7 trial countdown banner
functions/src/
├── createCheckoutSession.ts        # NEW: onCall — creates Stripe Checkout session
├── stripeWebhook.ts                # NEW: onRequest — handles Stripe webhook events
├── index.ts                        # UPDATE: export new functions
```

### Pattern 1: RevenueCat SDK Configure + logIn

**What:** Call `Purchases.configure()` at app startup (platform-specific API keys), then `Purchases.logIn(firebaseUID)` when a Firebase user authenticates.

**When to use:** Configure once on app mount (before any UI renders). logIn on every auth state change where `user` is non-null.

**Integration point:** The existing `onUserSignIn` callback in `SessionProvider` is the right place for `Purchases.logIn`. This callback already fires on every auth state change.

```typescript
// Source: https://www.revenuecat.com/docs/getting-started/configuring-sdk
// In app/_layout.tsx or root App component — runs once
import { Platform } from 'react-native';
import Purchases from 'react-native-purchases';

useEffect(() => {
  if (Platform.OS === 'web') return; // Web uses Firestore entitlement state
  if (Platform.OS === 'ios') {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_APPLE_API_KEY! });
  } else if (Platform.OS === 'android') {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_GOOGLE_API_KEY! });
  }
}, []);

// In onUserSignIn callback (already exists in app/(app)/_layout.tsx)
async function onUserSignIn(user: AuthUser): Promise<void> {
  if (Platform.OS !== 'web') {
    try {
      await Purchases.logIn(user.uid);
    } catch {
      // RC login failure is non-fatal — entitlement check will use cached state
    }
  }
  // ... existing Firestore profile write ...
}
```

### Pattern 2: useEntitlements Hook Upgrade

**What:** Add `Purchases.addCustomerInfoUpdateListener` for real-time mobile updates. Add Firestore read for web users (entitlement written by stripeWebhook function).

**When to use:** Called in every screen that gates premium features. Returns `{ isPremium, isLoading }`.

```typescript
// Source: https://www.revenuecat.com/docs/customers/customer-info
// src/entitlements/useEntitlements.ts (upgrade)

useEffect(() => {
  if (Platform.OS === 'web') {
    // Read Firestore entitlement doc for web users
    // Path: /users/{uid}/private/entitlements  (written by stripeWebhook Cloud Function)
    // Return isPremium based on active field
    return;
  }

  // Mobile: initial fetch + listener for real-time updates
  const Purchases = require('react-native-purchases').default;

  void checkEntitlements(); // initial check (existing pattern)

  const subscription = Purchases.addCustomerInfoUpdateListener((customerInfo) => {
    const active = customerInfo?.entitlements?.active ?? {};
    setIsPremium(PREMIUM_ENTITLEMENT_ID in active);
  });

  return () => {
    subscription.remove();
  };
}, [user?.uid]);
```

### Pattern 3: PaywallModal — Offerings Fetch + Purchase

**What:** Fetch RevenueCat offerings on mount, render annual/monthly packages, call `Purchases.purchasePackage()` on user confirm.

```typescript
// Source: https://www.revenuecat.com/docs/getting-started/making-purchases
const Purchases = require('react-native-purchases').default;

// Fetch offerings
const { offerings } = await Purchases.getOfferings();
const monthlyPkg = offerings.current?.monthly;
const annualPkg = offerings.current?.annual;

// Purchase (iOS/Android only)
try {
  const { customerInfo } = await Purchases.purchasePackage(selectedPackage);
  const isNowPremium = PREMIUM_ENTITLEMENT_ID in (customerInfo.entitlements.active ?? {});
  if (isNowPremium) {
    onSuccess(); // dismiss paywall, unlock feature
  }
} catch (e: any) {
  if (!e.userCancelled) {
    // Show error — RevenueCat surfaces store-specific error messages
  }
}
```

### Pattern 4: Firebase Cloud Function — createCheckoutSession

**What:** `onCall` function (requires Firebase auth) that creates a Stripe Checkout session with Firebase UID in metadata for entitlement mapping.

```typescript
// Source: https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/
// functions/src/createCheckoutSession.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import Stripe from 'stripe';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');

export const createCheckoutSession = onCall(
  { secrets: [STRIPE_SECRET_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }
    const firebaseUID = request.auth.uid;
    const { priceId, successUrl, cancelUrl } = request.data;

    const stripe = new Stripe(STRIPE_SECRET_KEY.value(), {
      apiVersion: '2025-01-27.acacia',
    });

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      subscription_data: {
        trial_period_days: 7,
        trial_settings: {
          end_behavior: { missing_payment_method: 'cancel' },
        },
        metadata: { firebaseUID }, // Used by webhook to identify user
      },
      payment_method_collection: 'if_required', // Optional during trial
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { firebaseUID }, // Also on session for redundancy
    });

    return { url: session.url };
  }
);
```

### Pattern 5: Firebase Cloud Function — stripeWebhook + RC Entitlement Grant

**What:** `onRequest` function that receives Stripe events, verifies signature with `request.rawBody`, and calls RevenueCat REST API to grant/revoke the "premium" entitlement.

```typescript
// Source: verified from multiple sources
// functions/src/stripeWebhook.ts
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import Stripe from 'stripe';
import * as logger from 'firebase-functions/logger';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');
const RC_SECRET_API_KEY = defineSecret('RC_SECRET_API_KEY');

export const stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, RC_SECRET_API_KEY] },
  async (request, response) => {
    const sig = request.headers['stripe-signature'];
    if (!sig) { response.status(400).send('Missing stripe-signature'); return; }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value(), { apiVersion: '2025-01-27.acacia' });
    let event: Stripe.Event;
    try {
      // CRITICAL: must use request.rawBody — parsed body breaks signature
      event = stripe.webhooks.constructEvent(request.rawBody, sig, STRIPE_WEBHOOK_SECRET.value());
    } catch (err) {
      response.status(400).send(`Webhook Error: ${err}`);
      return;
    }

    const subscription = event.data.object as Stripe.Subscription;
    const firebaseUID = subscription.metadata?.firebaseUID;
    if (!firebaseUID) { response.json({ received: true }); return; }

    if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated') {
      const isActive = subscription.status === 'active' || subscription.status === 'trialing';
      if (isActive) {
        await grantRCEntitlement(firebaseUID, RC_SECRET_API_KEY.value());
      } else {
        await revokeRCEntitlement(firebaseUID, RC_SECRET_API_KEY.value());
      }
    } else if (event.type === 'customer.subscription.deleted') {
      await revokeRCEntitlement(firebaseUID, RC_SECRET_API_KEY.value());
    }

    response.json({ received: true });
  }
);
```

### Pattern 6: RevenueCat REST API — Grant/Revoke Entitlement

**What:** Server-side calls using RevenueCat's Secret API key to manage entitlements for web-subscribed users.

```typescript
// Source: https://www.revenuecat.com/docs/api-v1 (promotional entitlement endpoint)
// RevenueCat v1 API — requires Secret API key (not public key)

async function grantRCEntitlement(appUserId: string, rcSecretKey: string): Promise<void> {
  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
  await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${rcSecretKey}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify({ duration: 'monthly' }),
    // Note: duration is the grant period; recurring subscription events re-grant on renewal
  });
}

// Revocation: RevenueCat v1 API — DELETE endpoint
async function revokeRCEntitlement(appUserId: string, rcSecretKey: string): Promise<void> {
  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
  await fetch(url, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${rcSecretKey}`,
      'Accept': 'application/json',
    },
  });
}
```

### Pattern 7: Feature Gating — Hook + Paywall Trigger

**What:** Each premium feature screen calls `useEntitlements()` and renders a lock state or triggers `PaywallModal` on interaction.

```typescript
// Pattern used at: ai-workout/config.tsx, programs/index.tsx,
//                 cycle.tsx (adaptation toggle), injuries/[id].tsx (substitution toggle)

function PremiumFeatureScreen(): React.JSX.Element {
  const { isPremium, isLoading } = useEntitlements();
  const [showPaywall, setShowPaywall] = useState(false);

  if (isLoading) return <LoadingSpinner />;

  function handlePremiumAction(): void {
    if (!isPremium) {
      setShowPaywall(true);
      return;
    }
    // proceed with premium action
  }

  return (
    <>
      <TouchableOpacity onPress={handlePremiumAction}>
        {!isPremium && <PremiumBadge />}
        <FeatureContent />
      </TouchableOpacity>
      {showPaywall && (
        <PaywallModal
          onDismiss={() => setShowPaywall(false)}
          onSubscribed={() => setShowPaywall(false)}
        />
      )}
    </>
  );
}
```

### Pattern 8: Restore Purchases

```typescript
// Source: https://www.revenuecat.com/docs/getting-started/making-purchases
const Purchases = require('react-native-purchases').default;

async function handleRestorePurchases(): Promise<void> {
  try {
    const customerInfo = await Purchases.restorePurchases();
    const isNowPremium = PREMIUM_ENTITLEMENT_ID in (customerInfo.entitlements.active ?? {});
    // Show success/failure feedback to user
  } catch (e) {
    // Show error feedback
  }
}
```

### Anti-Patterns to Avoid

- **Using `request.body` instead of `request.rawBody` in stripeWebhook:** Breaks Stripe signature verification. Firebase Cloud Functions v2 `onRequest` provides `rawBody` — always use it for Stripe.
- **Storing RC public API key in functions (server-side):** Use only the RC Secret API key server-side. The public key goes in the React Native app via `EXPO_PUBLIC_*` env vars.
- **Calling RevenueCat configure() on web platform:** `react-native-purchases` Web Billing requires a separate `@revenuecat/purchases-js` package. Since this project uses custom Stripe checkout, skip `Purchases.configure()` on web entirely (`if (Platform.OS === 'web') return`).
- **Reading entitlement state from Firestore directly on mobile:** RevenueCat is the single source of truth on mobile. Firestore entitlement field is web-only.
- **Gating the paywall on guest users at display time:** The paywall should be shown to guests too — but the purchase flow must gate account creation first. Show paywall, then if guest, redirect to sign-in with a return callback.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| iOS/Android purchase flow | Custom StoreKit/Play Billing wrapper | RevenueCat purchasePackage() | App Review compliance, receipt validation, retry logic, error codes per store |
| Subscription status across sessions | Manual Firestore subscription field for mobile | RevenueCat getCustomerInfo() + listener | RC handles token refresh, expiration, grace period |
| Stripe webhook signature verification | Custom HMAC check | stripe.webhooks.constructEvent(rawBody, sig, secret) | Timing-safe comparison, handles tolerance window, event type coercion |
| Trial tracking | Custom date-based trial state | RevenueCat trial_period_days on mobile; Stripe trial_period_days on web | Store-enforced, one trial per device (RC), no server-side enforcement code needed |
| Restore purchases | Custom re-validation loop | Purchases.restorePurchases() | Required by Apple; RC handles cross-device restore |

**Key insight:** RevenueCat abstracts all store-specific receipt validation complexity. The only custom server code needed is the Stripe checkout creation and webhook-to-RC entitlement bridge.

---

## Common Pitfalls

### Pitfall 1: rawBody Missing on Stripe Webhook
**What goes wrong:** Stripe signature verification fails with "No signatures found matching the expected signature for payload."
**Why it happens:** Firebase Cloud Functions v2 `onRequest` parses the body as JSON by default. Stripe signs the raw bytes, not the parsed object. Using `request.body` instead of `request.rawBody` produces a different hash.
**How to avoid:** Always use `request.rawBody` in `stripe.webhooks.constructEvent()`. Firebase Functions v2 `onRequest` provides `rawBody` automatically — no middleware configuration needed.
**Warning signs:** "Webhook Error" response in Stripe dashboard after a valid event.

### Pitfall 2: firebaseUID Not in Stripe Metadata
**What goes wrong:** Webhook receives subscription event but `subscription.metadata.firebaseUID` is undefined, so RC entitlement grant is skipped.
**Why it happens:** The `metadata` must be set on `subscription_data`, not just on the `checkout.sessions.create` call. Session metadata and subscription metadata are separate.
**How to avoid:** Set `subscription_data.metadata.firebaseUID` AND `metadata.firebaseUID` (on session) when creating the checkout session. Handle both paths in webhook handler.
**Warning signs:** Stripe dashboard shows successful events but user never gets premium access.

### Pitfall 3: RevenueCat logIn Before Configure
**What goes wrong:** `Purchases.logIn()` throws "RevenueCat has not been configured."
**Why it happens:** `configure()` must be called before any other RC API. If `onUserSignIn` fires before the configure `useEffect` runs, logIn will fail.
**How to avoid:** Call `Purchases.configure()` synchronously (not in a Promise/async call) at app startup, before `SessionProvider` mounts. The `useEffect` in the root layout runs after mount, which may be too late if auth state restores from cache. Alternatively, call configure before rendering the root layout.
**Warning signs:** "RevenueCat has not been configured" error in console during development.

### Pitfall 4: Paywall Shown to Guest Users Without Account Prompt
**What goes wrong:** Guest taps premium feature, sees paywall, taps "Subscribe" — but RevenueCat requires a non-anonymous user ID. Guest subscribes, gets charged, app crashes or subscription is lost.
**Why it happens:** CONTEXT.md requires account creation before subscription, but the paywall modal might have a generic "Subscribe" CTA.
**How to avoid:** In PaywallModal, check `isGuest` from `useSession()`. If guest, show "Create Account to Subscribe" CTA that routes to sign-in flow, not directly to the purchase flow.
**Warning signs:** Purchase flow called with an anonymous user ID.

### Pitfall 5: React Native Purchases on Web Crashes
**What goes wrong:** App crashes on web with "Cannot find native module: RNPurchases."
**Why it happens:** `react-native-purchases` requires native modules (StoreKit/Play Billing). Even with dynamic `require()`, some environments eagerly evaluate the import.
**How to avoid:** The existing `Platform.OS === 'web'` guard in `useEntitlements.ts` is correct — extend this pattern to every call site. Never call `Purchases.*` without the platform guard.
**Warning signs:** "Cannot find native module" errors in web console.

### Pitfall 6: Trial Banner Shown to Non-Trial Users
**What goes wrong:** Banner appears for users who are subscribed (not on trial) or already expired.
**Why it happens:** The trial end date must come from `customerInfo.subscriptions[productId].expiresDate` or `customerInfo.entitlements.active['premium'].expirationDate`, not from a locally-computed start+7 days.
**How to avoid:** Use `customerInfo.entitlements.active['premium'].expirationDate` to determine if in trial. RevenueCat provides a `periodType` field (`'TRIAL'` vs `'NORMAL'`) on the entitlement object to distinguish trial from paid.
**Warning signs:** Banner appears for paid users or after trial conversion.

### Pitfall 7: Stripe Secret in React Native Bundle
**What goes wrong:** Stripe secret key visible in reverse-engineered JS bundle.
**Why it happens:** Developer imports `stripe` directly in RN code, or accidentally includes it via an env var not prefixed `EXPO_PUBLIC_`.
**How to avoid:** Stripe secret key exists ONLY in Firebase Cloud Functions (as a Firebase Secret via `defineSecret`). The RN app never touches Stripe directly — it calls the `createCheckoutSession` Cloud Function and receives a URL. Only `EXPO_PUBLIC_*` env vars (safe for public) go in the RN app.
**Warning signs:** `STRIPE_SECRET_KEY` appearing in any RN source file or bundle.

---

## Code Examples

### RevenueCat SDK Setup (app root)
```typescript
// Source: https://www.revenuecat.com/docs/getting-started/configuring-sdk
// Platform-specific configure() — runs once at app startup

import { Platform } from 'react-native';

function configurePurchases(): void {
  if (Platform.OS === 'web') return; // Web uses Stripe/Firestore path

  // Dynamic require prevents web bundle failure (established project pattern)
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const Purchases = require('react-native-purchases').default;

  if (__DEV__) {
    Purchases.setLogLevel(Purchases.LOG_LEVEL.DEBUG);
  }

  if (Platform.OS === 'ios') {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_APPLE_API_KEY! });
  } else {
    Purchases.configure({ apiKey: process.env.EXPO_PUBLIC_RC_GOOGLE_API_KEY! });
  }
}
```

### Stripe Webhook — Full Event Handling
```typescript
// Source: https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/
// functions/src/stripeWebhook.ts — condensed from pattern above

// Stripe subscription statuses that mean "has premium access":
const ACTIVE_STATUSES = new Set(['active', 'trialing', 'past_due']);
// 'past_due' included for grace period (subscription.updated fires when card fails)
// 'past_due' grace: typically 3-7 days before 'canceled' — allow graceful downgrade
```

### Entitlement State on Web (Firestore schema)
```typescript
// Written by stripeWebhook Cloud Function
// Path: /users/{firebaseUID}  (merges into existing user doc — no extra read)
// Field: premiumEntitlement: { active: boolean, expiresAt: Timestamp | null, source: 'stripe' }

// Read in useEntitlements.ts web branch
import { doc, onSnapshot } from 'firebase/firestore';

const unsubscribe = onSnapshot(doc(db, 'users', uid), (snap) => {
  const data = snap.data();
  const entitlement = data?.premiumEntitlement;
  const active = entitlement?.active === true &&
    (entitlement.expiresAt == null || entitlement.expiresAt.toDate() > new Date());
  setIsPremium(active);
  setIsLoading(false);
});
return unsubscribe;
```

### iOS Subscription Management Deep Link
```typescript
// Source: established iOS pattern for App Store subscription management
import { Linking } from 'react-native';

async function openSubscriptionManagement(): Promise<void> {
  if (Platform.OS === 'ios') {
    await Linking.openURL('itms-apps://apps.apple.com/account/subscriptions');
  } else if (Platform.OS === 'android') {
    // RevenueCat provides managementURL from customerInfo
    const Purchases = require('react-native-purchases').default;
    const info = await Purchases.getCustomerInfo();
    if (info.managementURL) {
      await Linking.openURL(info.managementURL);
    }
  }
  // Web: open Stripe Customer Portal URL (returned from createStripePortalSession Cloud Function)
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe `trial_from_plan` param | `subscription_data.trial_period_days` on session | 2023 (deprecated) | Must set trial on checkout session, not on price/plan |
| RevenueCat anonymous IDs, manual aliasing | `Purchases.logIn(appUserId)` for Firebase UID mapping | RC SDK v4+ | Simplified — logIn handles aliasing automatically |
| Stripe API version `"2023-10-16"` | `"2025-01-27.acacia"` (2025 current) | 2025 | Specify current version in Stripe constructor |
| firebase-functions v1 `functions.https.onRequest` | `onRequest` from `firebase-functions/v2/https` | Firebase v6 | v2 provides `request.rawBody` natively — required for Stripe |

---

## Open Questions

1. **RC entitlement grant duration for active subscriptions**
   - What we know: RC promotional entitlement endpoint accepts `"daily"`, `"weekly"`, `"monthly"`, `"two_month"`, `"three_month"`, `"six_month"`, `"yearly"`, `"lifetime"` as duration values
   - What's unclear: For an ongoing subscription, the best strategy is to grant `"monthly"` on `subscription.created` and re-grant `"monthly"` on each `invoice.payment_succeeded` event — or grant `"lifetime"` and revoke on `subscription.deleted`. The `"lifetime"` + explicit revoke approach is simpler but potentially risky if revoke fails.
   - Recommendation: Use `"lifetime"` grant + explicit DELETE revoke on cancellation. This avoids the need to handle renewal webhooks for the entitlement. Ensure the DELETE is retried on failure (idempotent).

2. **Firestore security rules for premiumEntitlement field**
   - What we know: The `stripeWebhook` Cloud Function writes `premiumEntitlement` to `/users/{uid}`. Firebase Admin SDK bypasses security rules, so writes are fine.
   - What's unclear: The existing security rules for `/users/{uid}` need to prevent client-side writes to `premiumEntitlement` while allowing reads by the same user. This must be verified against current rules.
   - Recommendation: Add a rule in Wave 0 that allows read of `premiumEntitlement` by the owning user but denies writes from client side.

3. **RevenueCat "Restore Purchases" on web**
   - What we know: `Purchases.restorePurchases()` is mobile-only (native purchases). Web subscriptions are Stripe-based.
   - What's unclear: How does a web user "restore" access on a new browser? The `useEntitlements` web branch reads from Firestore, which is keyed by Firebase UID — so re-authenticating automatically restores access. No explicit restore needed.
   - Recommendation: On web, the Settings "Restore Purchases" button can be hidden or replaced with "Re-sync Subscription" that triggers a Firestore read refresh.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | jest-expo (jest ^29.7.0) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest src/entitlements/ --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |
| Functions tests | `cd functions && npm test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUBS-01 | RevenueCat logIn called on auth; purchasePackage succeeds; entitlement active | unit | `cd SundeeFundeeRN && npx jest src/entitlements/ -t "mobile"` | ❌ Wave 0 |
| SUBS-01 | PaywallModal renders offerings, calls purchasePackage on confirm | unit | `cd SundeeFundeeRN && npx jest src/components/paywall/ -t "PaywallModal"` | ❌ Wave 0 |
| SUBS-02 | createCheckoutSession validates auth, returns Stripe URL | unit | `cd functions && npm test -- --testNamePattern="createCheckoutSession"` | ❌ Wave 0 |
| SUBS-03 | stripeWebhook grants RC entitlement on subscription.created | unit | `cd functions && npm test -- --testNamePattern="stripeWebhook"` | ❌ Wave 0 |
| SUBS-03 | stripeWebhook revokes RC entitlement on subscription.deleted | unit | `cd functions && npm test -- --testNamePattern="stripeWebhook"` | ❌ Wave 0 |
| SUBS-04 | Premium feature screen shows paywall when isPremium=false | unit | `cd SundeeFundeeRN && npx jest src/ -t "paywall"` | ❌ Wave 0 |
| SUBS-04 | useEntitlements returns isPremium=true after purchasePackage | unit | `cd SundeeFundeeRN && npx jest src/entitlements/` | ❌ Wave 0 |
| SUBS-05 | Settings shows subscription section for authenticated users | unit | `cd SundeeFundeeRN && npx jest app/ -t "settings subscription"` | ❌ Wave 0 |
| SUBS-05 | restorePurchases called from Settings restore button | unit | `cd SundeeFundeeRN && npx jest app/ -t "restore"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest src/entitlements/ --no-coverage` + `cd functions && npm test`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage` + `cd functions && npm test`
- **Phase gate:** Full suite green (with coverage) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/src/entitlements/__tests__/useEntitlements.test.ts` — covers SUBS-01, SUBS-03, SUBS-04
- [ ] `SundeeFundeeRN/src/components/paywall/__tests__/PaywallModal.test.tsx` — covers SUBS-01, SUBS-04
- [ ] `functions/src/__tests__/createCheckoutSession.test.ts` — covers SUBS-02
- [ ] `functions/src/__tests__/stripeWebhook.test.ts` — covers SUBS-03
- [ ] `functions/__mocks__/stripe.ts` — stripe mock for unit tests
- [ ] `functions/__mocks__/firebase-functions-onrequest.ts` — onRequest mock (separate from existing onCall mock)
- [ ] Install stripe npm package: `cd functions && npm install stripe`
- [ ] Add `EXPO_PUBLIC_RC_APPLE_API_KEY`, `EXPO_PUBLIC_RC_GOOGLE_API_KEY` to `.env` files
- [ ] Add Firebase Secrets: `firebase functions:secrets:set STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `RC_SECRET_API_KEY`

---

## Sources

### Primary (HIGH confidence)
- [RevenueCat Configuring SDK](https://www.revenuecat.com/docs/getting-started/configuring-sdk) — configure() placement, platform-specific keys, web platform handling
- [RevenueCat Making Purchases](https://www.revenuecat.com/docs/getting-started/making-purchases) — purchasePackage() flow, entitlement check pattern
- [RevenueCat Getting Subscription Status](https://www.revenuecat.com/docs/customers/customer-info) — addCustomerInfoUpdateListener(), entitlement active check
- [RevenueCat API v1 — Grant Promotional Entitlement](https://www.revenuecat.com/docs/api-v1) — POST endpoint, Secret key requirement, duration values
- [Stripe Trials Documentation](https://docs.stripe.com/billing/subscriptions/trials) — subscription_data.trial_period_days, payment_method_collection=if_required
- [Stripe Webhook Signature Verification](https://docs.stripe.com/webhooks/signature) — constructEvent, rawBody requirement

### Secondary (MEDIUM confidence)
- [Firebase Cloud Functions + Stripe Subscriptions (2025)](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — Full TypeScript implementation of createCheckoutSession + stripeWebhook, verified against Stripe docs
- [RevenueCat Stripe Server Notifications](https://www.revenuecat.com/docs/platform-resources/server-notifications/stripe-server-notifications) — Confirms RC supports direct Stripe webhook endpoint (alternative to REST API calls); explains why custom webhook + REST API is used here
- [RevenueCat Web Billing Overview](https://www.revenuecat.com/docs/web/web-billing/overview) — Confirmed RC Web Billing is a separate product; locked decision to use custom Stripe is architecturally sound
- [RevenueCat React Native Web Support](https://www.revenuecat.com/blog/engineering/revenuecat-react-native-sdk-adds-react-native-web-support/) — Confirmed `react-native-purchases` on web uses different @revenuecat/purchases-js SDK; project correctly avoids this

### Tertiary (LOW confidence)
- iOS subscription management URL `itms-apps://apps.apple.com/account/subscriptions` — not directly confirmed by Apple official docs; widely used in community; RevenueCat docs mention the URL format for subscription management deep links

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — react-native-purchases v9 installed, stripe pattern is well-documented from 2025 sources, Firebase Cloud Functions v2 already in project
- Architecture: HIGH — locked decisions align with verified patterns; rawBody behavior confirmed
- Pitfalls: HIGH — rawBody/metadata pitfalls confirmed by official Stripe docs and community reports; RC configure-before-logIn is documented SDK behavior
- Open questions: MEDIUM — RC entitlement duration strategy is project-level judgment call; Firestore rules need verification against actual rules file

**Research date:** 2026-03-15
**Valid until:** 2026-06-15 (90 days — Stripe API versions change slowly; RC SDK v9 is current)
