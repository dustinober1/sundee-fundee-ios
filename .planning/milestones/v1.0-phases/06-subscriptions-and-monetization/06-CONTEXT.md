# Phase 6: Subscriptions and Monetization - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can subscribe via in-app purchase (RevenueCat) on iOS/Android or Stripe web checkout at a lower price point. Premium features are gated behind subscription. Entitlements are unified across all platforms for the same Firebase UID. Subscription management is available from settings. A 7-day free trial is offered to new signups on all platforms.

</domain>

<decisions>
## Implementation Decisions

### Free vs Premium feature split
- **Free tier:** Custom workout logging, exercise library (200+), workout history, 1RM tracking, maxes tab, benchmark catalog browsing, benchmark recording
- **Premium tier:** AI workout generation, cycle adaptation (auto-adjusting load/sets/reps), program catalog access, injury adaptation (auto-substitution of contraindicated exercises)
- Cycle tracking data logging (period dates, phase viewing) stays free — only the smart adaptation is premium
- Injury profile creation and pain logging stay free — only the automatic exercise substitution is premium
- Guests get free tier only — must create account before subscribing (no subscription without Firebase auth)

### Paywall presentation
- Full-screen modal triggered on first tap of any premium feature (AI workout, program, cycle adaptation toggle, injury adaptation)
- No proactive upsell — user discovers paywall naturally when they try a premium feature
- Premium features visible in UI with lock icon or "Premium" badge — not hidden
- Paywall content: clean feature list with icons (4 premium features), brief one-liner per feature, pricing cards below, Art Deco styled
- Annual plan pre-selected with "Best Value" / "Save 50%" badge; monthly shown but visually de-emphasized
- Platform-only pricing shown — no cross-platform pricing or external purchase links (App Store guideline compliance)

### Pricing structure
- **Mobile (iOS/Android via RevenueCat):** $9.99/month, $59.99/year (save 50%)
- **Web (Stripe Checkout):** $7.99/month, $47.99/year (~20% cheaper than mobile)
- **Free trial:** 7 days on all platforms (RevenueCat trial on mobile, Stripe trial_period_days on web)
- One trial per device (RevenueCat device-based tracking prevents trial abuse across accounts)

### Trial-to-paid conversion
- No countdown during first 5 days of trial — let users enjoy premium
- Days 6-7: subtle dismissable banner on dashboard: "Your trial ends in X days. Subscribe to keep premium features."
- If user is mid-session (AI workout, program) when trial expires, let them finish that session — lock on next feature access
- One-time "Your trial ended" modal on first app launch after trial expiry: features they used, subscribe button, "Continue with free" dismiss. Shown once.

### RevenueCat ↔ Firebase UID mapping
- Call Purchases.logIn(firebaseUID) immediately after successful Firebase authentication
- Guest users skip RevenueCat identity — no RC login until account creation
- Guest→auth upgrade triggers Purchases.logIn(newFirebaseUID); trial eligibility determined by device-based check at that point
- Minimal subscriber attributes — Firebase UID only, no profile data synced to RevenueCat

### Subscription management
- Settings shows "Subscription" section with: plan name, renewal date, "Manage Subscription" link
- Mobile: "Manage Subscription" deep-links to App Store / Play Store subscription management
- Web: "Manage Subscription" links to Stripe Customer Portal (hosted by Stripe, customizable via dashboard)
- "Restore Purchases" button in Settings subscription section (required by Apple) — calls RevenueCat restorePurchases()
- Graceful downgrade on subscription lapse: premium features locked again with standard lock icon/paywall, all user data (periods, injuries, AI history) preserved

### Stripe web checkout flow
- Firebase Cloud Function (createCheckoutSession) creates Stripe Checkout session with Firebase UID in metadata — secure server-side UID verification
- Stripe Checkout redirect (not embedded) — PCI-compliant, handles 3D Secure
- Post-payment redirect to sundeefundee.com/subscription/success?session_id=xxx — Art Deco success page with "Continue to App" button
- Cancel redirect back to paywall page

### Stripe → RevenueCat entitlement sync
- Firebase Cloud Function listens for Stripe webhook events (subscription.created, subscription.updated, subscription.deleted)
- Webhook handler calls RevenueCat REST API to grant/revoke "premium" entitlement by Firebase UID
- Mobile reads entitlements from RevenueCat as normal — single source of truth for entitlement status across all platforms
- Target: entitlements sync within 60 seconds of successful payment (SUBS-03 criteria)

### Claude's Discretion
- Exact paywall modal layout, animations, and Art Deco styling details
- Lock icon/badge design for premium features in free tier
- Trial banner positioning and styling
- "Your trial ended" modal design and feature usage summary format
- Stripe success page design
- RevenueCat SDK configuration details (API key management, configure() call placement)
- Webhook retry and error handling strategy
- Entitlement caching and refresh interval in useEntitlements hook

</decisions>

<specifics>
## Specific Ideas

- Paywall should feel premium but not pushy — Art Deco styling with clean feature list, not a hard-sell modal
- Annual plan highlighted as "Best Value" to drive LTV
- Web pricing ~20% cheaper than mobile ($7.99 vs $9.99/mo) to incentivize direct purchase — better margin for both sides
- Trial experience should be friction-free: no countdown for 5 days, subtle reminder only at the end
- Mid-session graceful handling: never interrupt a workout for subscription status changes
- Guest-to-auth upgrade is a natural conversion funnel — trial starts on account creation, device-based abuse prevention

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/entitlements/useEntitlements.ts`: Hook already checks RevenueCat for "premium" entitlement, returns `{ isPremium, isLoading }`. Currently web returns false — needs Stripe/web support added
- `__mocks__/react-native-purchases.ts`: Full Jest mock for RevenueCat SDK with configure, getCustomerInfo, logIn, logOut, purchaseProduct, restorePurchases
- `react-native-purchases` already installed in package.json (installed with --legacy-peer-deps for React 19 compatibility)
- Theme tokens: cream (#F4F0DF), navy (#0D1A40), orange (#F2731A) — available for paywall styling
- Settings screen at `app/(app)/(tabs)/settings.tsx` — integration point for subscription management section

### Established Patterns
- Repository factory: `getXxxRepo(isGuest)` — subscription check can follow similar pattern
- Dynamic require() for platform-specific modules (used in firestore.ts, auth files) — applicable for RevenueCat web handling
- Platform-specific file extensions (.native.ts / .web.ts) — useful for checkout flow branching
- `SessionProvider` with `onUserSignIn` callback — natural place to add Purchases.logIn(firebaseUID)
- Firebase Cloud Functions exist at `functions/` directory (Gemini proxy already deployed) — Stripe webhook + checkout session functions go here

### Integration Points
- `useEntitlements` hook: needs upgrade from Phase 1 infrastructure-only to real entitlement gating with listener
- `SessionProvider` / auth flow: add Purchases.logIn on auth, Purchases.logOut on sign-out
- Settings tab: add Subscription section (status card, manage link, restore button)
- All premium feature screens: add entitlement check + paywall trigger (AI config, program catalog, cycle adaptation toggle, injury adaptation)
- Dashboard: trial countdown banner component (days 6-7)
- Firebase Cloud Functions: new createCheckoutSession + stripeWebhook functions
- Web app: subscription success/cancel redirect pages

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-subscriptions-and-monetization*
*Context gathered: 2026-03-15*
