---
phase: 06-subscriptions-and-monetization
plan: 03
subsystem: paywall-ux
tags: [paywall, entitlements, trial, settings, subscription-management]
dependency_graph:
  requires: [06-01, 06-02]
  provides: [premium-feature-gating, trial-ux, subscription-settings]
  affects: [dashboard, ai-workout, programs, cycle, injuries, settings]
tech_stack:
  added: []
  patterns:
    - useEntitlementContext for isPremium gating in screens
    - PaywallModal overlay pattern (conditional on showPaywall state)
    - TrialBanner null-return pattern (renders null when not applicable)
    - jest.spyOn(Linking, 'openURL') for Linking deep-link testing
key_files:
  created:
    - SundeeFundeeRN/src/components/paywall/TrialBanner.tsx
    - SundeeFundeeRN/src/components/paywall/TrialEndedModal.tsx
    - SundeeFundeeRN/src/components/paywall/__tests__/TrialBanner.test.tsx
    - SundeeFundeeRN/src/components/paywall/__tests__/TrialEndedModal.test.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/__tests__/settings.test.tsx
  modified:
    - SundeeFundeeRN/app/(app)/ai-workout/config.tsx
    - SundeeFundeeRN/app/(app)/programs/index.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/cycle.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/index.tsx
    - SundeeFundeeRN/app/(app)/injuries/[id].tsx
    - SundeeFundeeRN/app/(app)/(tabs)/settings.tsx
decisions:
  - "jest.spyOn(Linking, 'openURL') used for Linking deep-link testing — mocking full react-native module breaks @testing-library/react-native FlatList"
  - "TrialBanner uses null-return pattern — safe to render unconditionally in dashboard, handles its own visibility logic"
  - "Programs catalog gates on card tap (not browse) — catalog browsing stays free per user decision"
  - "Cycle adaptation section added as Pressable — tapping shows paywall for non-premium, informational text for premium"
  - "Injury [id] adaptation gate wraps InjurySubstitutionCard — premium users see full card, non-premium see PremiumBadge gate"
metrics:
  duration: 35 min
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_modified: 11
---

# Phase 06 Plan 03: Premium Feature Gating and Trial UX Summary

User-facing monetization completion: all 4 premium features gated with PaywallModal, trial countdown banner (days 6-7), one-time trial-ended modal, and subscription management section in Settings with platform-specific deep-links and Restore Purchases.

## Tasks Completed

### Task 1: Gate premium features and build trial UX components

**All 4 premium features gated with paywall:**

- **AI Workout Config** (`ai-workout/config.tsx`): `handleGenerateWorkout` checks `isPremium` from `useEntitlementContext()` first — if false, calls `setShowPaywall(true)` and returns immediately
- **Programs Catalog** (`programs/index.tsx`): Each `ProgramCard` shows `<PremiumBadge compact />` when `!isPremium`; tapping a card shows `PaywallModal` instead of navigating
- **Cycle Tab** (`cycle.tsx`): New "Cycle Adaptation" section with `<PremiumBadge />` for non-premium; tapping the section opens `PaywallModal`
- **Injury Profile** (`injuries/[id].tsx`): `InjurySubstitutionCard` replaced by a premium gate card with `<PremiumBadge />` for non-premium; tapping opens `PaywallModal`

**Trial UX components:**

- **`TrialBanner`**: Mobile-only; checks RevenueCat `getCustomerInfo()` on mount; renders only when `periodType === 'TRIAL'` and `daysRemaining <= 2`; dismissable via X button (stored to AsyncStorage key `trialBannerDismissed`); "Subscribe" CTA opens PaywallModal
- **`TrialEndedModal`**: One-time modal with "Your Trial Has Ended" header, feature list, "Subscribe Now" (orange), and "Continue with Free" (text) buttons; dismissal persisted via `trialEndedModalShown` key

**Dashboard wiring**: `TrialBanner` rendered unconditionally near top of content — returns `null` when not applicable; `PaywallModal` added with `showPaywall` state

### Task 2: Add subscription management to Settings

**Subscription section** added between Rest Timer and About sections:

- **Subscribed users**: Plan name (parsed from RevenueCat `productIdentifier`), renewal/expiry date, "Manage Subscription" row
  - iOS: `Linking.openURL('itms-apps://apps.apple.com/account/subscriptions')`
  - Android: `Linking.openURL(managementURL)` from `customerInfo.managementURL`
  - Web: Static text "Manage on sundeefundee.com"
- **Non-subscribed users**: "Unlock Premium" card (orange-tinted) with feature list snippet and "View Plans" button opening `PaywallModal`
- **Restore Purchases**: Mobile-only button (Apple/Google App Review requirement); calls `Purchases.restorePurchases()`; shows `Alert` with success/failure feedback; disabled during restore
- **`TrialEndedModal` integration**: Settings checks `trialEndedModalShown` AsyncStorage key on mount; shows modal if trial expired and not yet shown

## Test Coverage

- `TrialBanner.test.tsx`: 7 tests — renders with <= 2 days, hidden with > 2 days, hidden on non-trial, dismissal stored to AsyncStorage, onSubscribe called, not rendered when dismissed, not rendered on web
- `TrialEndedModal.test.tsx`: 5 tests — renders heading, feature list, onSubscribe, onDismiss, hidden when not visible
- `settings.test.tsx`: 9 tests — Subscription heading, Unlock Premium card, View Plans button, PaywallModal opens, plan info for subscribed, Manage Subscription deep-link iOS, Restore Purchases mobile, Restore Purchases hidden on web, restorePurchases called

**Total: 1155 tests pass across 56 test suites (full suite)**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] jest.mock('react-native') breaks @testing-library/react-native**
- **Found during:** Task 2 settings test writing
- **Issue:** Mocking the full `react-native` module in settings tests caused `@testing-library/react-native` to fail loading (FlatList circular dependency)
- **Fix:** Used `jest.spyOn(Linking, 'openURL').mockResolvedValue(undefined)` in `beforeEach` instead
- **Files modified:** `app/(app)/(tabs)/__tests__/settings.test.tsx`
- **Commit:** 2829f76

## Self-Check: PASSED

All key files verified to exist. Both commits verified in git log.

| Item | Status |
|------|--------|
| TrialBanner.tsx | FOUND |
| TrialEndedModal.tsx | FOUND |
| TrialBanner.test.tsx | FOUND |
| TrialEndedModal.test.tsx | FOUND |
| settings.test.tsx | FOUND |
| Commit 8f5154f (Task 1) | FOUND |
| Commit 2829f76 (Task 2) | FOUND |
| Full test suite: 1155 tests | PASSED |
