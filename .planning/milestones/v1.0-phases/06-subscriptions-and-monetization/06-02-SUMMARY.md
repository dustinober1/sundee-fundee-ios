---
phase: 06-subscriptions-and-monetization
plan: 02
subsystem: payments
tags: [revenuecat, stripe, entitlements, paywall, react-native-purchases, firestore, firebase-functions]

# Dependency graph
requires:
  - phase: 06-subscriptions-and-monetization
    provides: "RevenueCat SDK configured in Phase 1, RC mock with basic methods"
  - phase: 03-data-layer-and-offline-architecture
    provides: "Firestore instance (getFirestoreInstance), onSnapshot patterns"
  - phase: 01-foundation-and-infrastructure
    provides: "SessionProvider, useSession, AuthContext with user UID"
provides:
  - "useEntitlements: real-time entitlement hook — mobile listener + web Firestore"
  - "EntitlementContext: app-wide EntitlementProvider + useEntitlementContext"
  - "PaywallModal: full-screen paywall with RevenueCat (mobile) and Stripe (web) purchase flows"
  - "PremiumBadge: inline lock icon badge component for premium feature gating"
  - "_layout.tsx: Purchases.logIn(uid) wired to auth sign-in for RC identity binding"
affects: [06-subscriptions-and-monetization, feature-gating, premium-features]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-time entitlement tracking via addCustomerInfoUpdateListener (mobile) and onSnapshot (web)"
    - "EntitlementProvider wraps app-wide to avoid duplicate listener spawning per screen"
    - "PaywallModal handles both platforms (RC packages on mobile, Stripe checkout on web) in one component"
    - "Purchases.logIn() called in handleUserSignIn callback in RootLayout for RC identity binding"

key-files:
  created:
    - SundeeFundeeRN/src/entitlements/EntitlementContext.tsx
    - SundeeFundeeRN/src/entitlements/__tests__/useEntitlements.test.ts
    - SundeeFundeeRN/src/components/paywall/PaywallModal.tsx
    - SundeeFundeeRN/src/components/paywall/PremiumBadge.tsx
    - SundeeFundeeRN/src/components/paywall/__tests__/PaywallModal.test.tsx
    - SundeeFundeeRN/src/components/paywall/__tests__/PremiumBadge.test.tsx
  modified:
    - SundeeFundeeRN/src/entitlements/useEntitlements.ts
    - SundeeFundeeRN/app/_layout.tsx
    - SundeeFundeeRN/__mocks__/react-native-purchases.ts

key-decisions:
  - "useEntitlements accepts optional uid param — re-runs effect when uid changes (login/logout cycles)"
  - "EntitlementProvider must be inside SessionProvider so it can call useSession() for uid"
  - "PaywallModal's createCheckoutSession uses firebase/functions (web SDK) via dynamic require — avoids native module bundling on web"
  - "RC mock variables in jest.mock factory must be named with 'mock' prefix for babel hoisting compatibility"
  - "Platform.OS mocking in tests uses Object.defineProperty(Platform, 'OS', ...) — jest.mock of Platform module path does not intercept react-native's Platform.OS at runtime"
  - "Purchases.logIn placed after profile persistence in handleUserSignIn — non-fatal, wrapped in try/catch"

patterns-established:
  - "Platform.OS test mocking: Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true }) in beforeEach"
  - "jest.mock factory variables must be named starting with 'mock' or babel hoisting blocks access"

requirements-completed: [SUBS-01, SUBS-04]

# Metrics
duration: 8min
completed: 2026-03-15
---

# Phase 6 Plan 02: Entitlement Infrastructure Upgrade and Paywall Components Summary

**Real-time RevenueCat entitlement hook with Firestore web fallback, EntitlementContext provider, PaywallModal with Art Deco styling and dual-platform purchase flows (RC packages mobile / Stripe checkout web), and PremiumBadge inline indicator**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-15T17:58:28Z
- **Completed:** 2026-03-15T18:06:40Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Upgraded useEntitlements from one-shot check to real-time listener (addCustomerInfoUpdateListener on mobile, Firestore onSnapshot on web)
- Created EntitlementProvider/useEntitlementContext for app-wide entitlement access without duplicate listeners
- Wired Purchases.logIn(user.uid) to auth sign-in in RootLayout for correct RevenueCat identity binding
- Built PaywallModal with 4 premium feature cards, annual pre-selected with "Best Value" badge, guest CTA, and both mobile/web purchase paths
- Built PremiumBadge inline component for gating indicators

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade useEntitlements hook and wire RC logIn to auth** - `6b9ae9a` (feat)
2. **Task 2: Build PaywallModal and PremiumBadge components** - `4aff4ce` (feat)

**Plan metadata:** (upcoming docs commit)

_Note: Both tasks used TDD — RED (failing tests) → GREEN (implementation) → verified passing_

## Files Created/Modified
- `SundeeFundeeRN/src/entitlements/useEntitlements.ts` - Upgraded with real-time listener (mobile) and Firestore onSnapshot (web), accepts uid param
- `SundeeFundeeRN/src/entitlements/EntitlementContext.tsx` - New context provider wrapping useEntitlements for app-wide access
- `SundeeFundeeRN/src/entitlements/__tests__/useEntitlements.test.ts` - 13 tests covering mobile/web paths, listener lifecycle, context
- `SundeeFundeeRN/src/components/paywall/PaywallModal.tsx` - Full-screen paywall with offerings fetch, purchase handling, guest CTA
- `SundeeFundeeRN/src/components/paywall/PremiumBadge.tsx` - Inline lock badge, default and compact modes
- `SundeeFundeeRN/src/components/paywall/__tests__/PaywallModal.test.tsx` - 6 tests for paywall behavior
- `SundeeFundeeRN/src/components/paywall/__tests__/PremiumBadge.test.tsx` - 3 tests for badge rendering
- `SundeeFundeeRN/app/_layout.tsx` - Added Purchases.logIn in handleUserSignIn, wrapped Stack with EntitlementProvider
- `SundeeFundeeRN/__mocks__/react-native-purchases.ts` - Added addCustomerInfoUpdateListener, getOfferings, purchasePackage, LOG_LEVEL, setLogLevel

## Decisions Made
- useEntitlements accepts optional uid param and re-runs effect on uid change (handles login/logout cycles)
- EntitlementProvider sits inside SessionProvider in _layout.tsx so it can read uid from useSession()
- PaywallModal uses firebase/functions (web SDK) via dynamic require for createCheckoutSession — prevents native module from bundling on web
- Platform.OS test mocking requires `Object.defineProperty(Platform, 'OS', ...)` — mocking the module path doesn't intercept the already-imported Platform object
- jest.mock factory closures must reference variables named starting with "mock" prefix (babel hoisting rule)
- Purchases.logIn wrapped in try/catch after profile persistence — non-fatal, RC identity binding failure gracefully degrades

## Deviations from Plan

None — plan executed exactly as written. The Platform.OS mocking approach required iteration in tests (discovered correct pattern: Object.defineProperty) but this was test infrastructure, not a deviation from planned behavior.

## Issues Encountered
- Platform.OS test mocking: first attempts using `jest.mock('react-native/Libraries/Utilities/Platform')` and a mutable object did not intercept Platform.OS reads inside the hook. Resolved by using `Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true })` directly on the imported Platform object in beforeEach.
- jest.mock factory hoisting: `firestoreMocks` variable named without "mock" prefix triggered babel hoisting error. Renamed to `mockFirestoreFns` (mock prefix) to satisfy babel's hoisting safety rule.

## User Setup Required
**External services require manual configuration.** See plan frontmatter `user_setup` for:
- `EXPO_PUBLIC_RC_APPLE_KEY` — RevenueCat Dashboard -> Project -> API Keys -> Apple public API key
- `EXPO_PUBLIC_RC_GOOGLE_KEY` — RevenueCat Dashboard -> Project -> API Keys -> Google public API key
- Create 'premium' entitlement in RevenueCat Dashboard -> Project -> Entitlements
- Create Offering with monthly ($9.99) and annual ($59.99) packages in RevenueCat Dashboard

## Next Phase Readiness
- EntitlementProvider and useEntitlementContext ready for Plan 03 (premium feature gating)
- PaywallModal ready to be shown from gated feature screens
- PremiumBadge ready for use in any feature that needs a premium indicator
- No blockers — Purchases.logIn will fail gracefully until RC API keys are configured

---
*Phase: 06-subscriptions-and-monetization*
*Completed: 2026-03-15*

## Self-Check: PASSED

- FOUND: SundeeFundeeRN/src/entitlements/useEntitlements.ts
- FOUND: SundeeFundeeRN/src/entitlements/EntitlementContext.tsx
- FOUND: SundeeFundeeRN/src/components/paywall/PaywallModal.tsx
- FOUND: SundeeFundeeRN/src/components/paywall/PremiumBadge.tsx
- FOUND: .planning/phases/06-subscriptions-and-monetization/06-02-SUMMARY.md
- FOUND commit: 6b9ae9a (Task 1)
- FOUND commit: 4aff4ce (Task 2)
