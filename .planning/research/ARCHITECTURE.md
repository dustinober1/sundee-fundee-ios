# Architecture: Paywall Removal and App Store Preparation

**Domain:** iOS App -- removing StoreKit subscription gating and shipping free app
**Researched:** 2026-04-08
**Confidence:** HIGH (source code fully audited)

## Current Architecture Overview

```
SundeeFundeeApp/ (Xcode project)
    App.swift -- bootstraps StoreKitClient into SubscriptionClientFactory
        |
SundeeFundee/ (Swift Package -- SundeeFundeeKit)
    Subscription/       <-- Entire module to modify/remove
        SubscriptionTier.swift         -- .free/.plus/.premium with capability flags
        SubscriptionClientProtocol.swift -- async protocol for purchase/restore/check
        StoreKitClient.swift           -- Actor wrapping StoreKit 2
        SubscriptionClientFactory.swift -- Thread-safe singleton
        MockSubscriptionClient.swift   -- Test mock
        SubscriptionError.swift        -- Error types
    UI/
        Views/Dashboard/DashboardView.swift  -- upgradePrompts, subscriptionTier checks
        Views/Settings/SettingsView.swift    -- SubscriptionView, SubscriptionViewModel, TierBadge
        Views/Analytics/CycleCorrelationChart.swift -- upgradeCard, hasAccess gate
        Views/Analytics/AnalyticsView.swift  -- hasCycleAccess gate
        Views/Export/ExportView.swift        -- upgradeSection, canExport gate
        Views/Insights/InsightsView.swift    -- Pro-gated (comment only, no runtime gate)
        ViewModels/AnalyticsViewModel.swift  -- subscriptionTier, hasCycleAccess
        ViewModels/ExportViewModel.swift     -- currentTier, canExport, showingSubscription
        ViewModels/PainTrackingViewModel.swift -- tier.hasSmartSubstitutions gate
        ViewModels/AuthViewModel.swift       -- StoreKitClient.identify/logout calls
    DomainLayer/
        Coach/CoachContext.swift -- tier field + CoachContextBuilder.loadSubscription()
```

## Paywall Gate Inventory

Every location in the codebase that checks subscription status to gate features.

### Layer 1: SubscriptionTier Capability Flags (SubscriptionTier.swift)

These computed properties return `true`/`false` based on tier. They are the authoritative feature gates.

| Flag | Returns true for | Gated Feature |
|------|-----------------|---------------|
| `hasCustomBenchmarks` | .plus, .premium | Custom benchmark creation |
| `hasPainTrends` | .plus, .premium | Pain/effort trend analysis |
| `hasAdvancedInsights` | .plus, .premium | Cycle correlation chart, advanced analytics |
| `hasAIBuilder` | .plus, .premium | AI workout generation |
| `hasRecoveryAdjustments` | .plus, .premium | Pain-aware movement modifications |
| `hasAdaptivePlanner` | .premium only | Adaptive weekly programming |
| `hasCoachMemory` | .premium only | AI coach memory across sessions |
| `hasSmartSubstitutions` | .premium only | Smart exercise substitutions |
| `hasPlateauDetection` | .premium only | Plateau detection + recommendations |
| `hasPreferenceLearning` | .premium only | Preference learning from edits/swaps |
| `hasWeeklyRecap` | .premium only | Weekly recap + next-week recommendations |
| `hasExportShare` | .premium only | Data export/share |
| `maxLifts` | nil for .plus/.premium | Max lifts tracked (5 for free) |
| `maxInjuries` | nil for .plus/.premium | Max injury profiles (1 for free) |
| `maxHistoryDays` | nil for .plus/.premium | History retention (30 days for free) |
| `dailyAIGenerations` | 0 free, 3 plus, 10 premium | AI generations per day |

### Layer 2: ViewModel Subscription Checks

These view models call `subscriptionClient.getSubscriptionInfo()` and store tier state.

| File | Property/Method | Gate Logic |
|------|----------------|------------|
| `DashboardViewModel` (in DashboardView.swift:487-656) | `subscriptionTier`, `canGenerateAIWorkout` | `tier.hasAIBuilder`, `tier.hasCoachMemory` |
| `AnalyticsViewModel` | `subscriptionTier`, `hasCycleAccess` | `tier.hasAdvancedInsights` controls `cycleData` computation |
| `ExportViewModel` | `currentTier`, `canExport` | `tier.hasExportShare` |
| `PainTrackingViewModel` | Inline check in `loadSubstitutionSuggestions()` | `tier.hasSmartSubstitutions` |
| `SettingsViewModel` | `currentTier`, `showingSubscription` | Loads tier for UI display, manages subscription sheet |
| `CoachContextBuilder` | `loadSubscription()` | Fetches tier and passes into `CoachContext.tier` |

### Layer 3: UI Views with Paywall/Upgrade UX

These views render upgrade cards, lock icons, or subscription sheets.

| File | Element | Behavior |
|------|---------|----------|
| `DashboardView.swift:369-440` | `upgradePrompts` + `lockedFeatureCard` | Shows "Unlock with Plus" for free users, "Unlock with Pro" for free/plus users |
| `DashboardView.swift:321-367` | `coachingInsightsCard` | Only renders if `tier == .premium` |
| `CycleCorrelationChart.swift:48-79` | `upgradeCard` | Lock icon + "Unlock with Plus" CTA when `!hasAccess` |
| `ExportView.swift:43-76` | `upgradeSection` | Lock icon + "Upgrade to Pro" when `!canExport` |
| `SettingsView.swift:312-410` | `SubscriptionView` | Full subscription management UI with tier cards, purchase, restore |
| `SettingsView.swift:645-668` | `TierBadge` | Visual badge showing current tier |

### Layer 4: App Entry Point (StoreKit Bootstrap)

| File | Code | Purpose |
|------|------|---------|
| `App.swift:12-17` | `StoreKitClient()` creation, `SubscriptionClientFactory.shared.client` assignment | Initializes StoreKit for entire app |
| `AuthViewModel.swift:88-89` | `SubscriptionClientFactory.shared.client as? StoreKitClient` + `identify()` | Associates user with subscription tracking |
| `AuthViewModel.swift:164-165` | `subscriptionClient.logout()` on sign-out | Clears subscription identity |
| `AuthViewModel.swift:200-201` | `subscriptionClient.identify()` on session restore | Re-associates user after app restart |

### Layer 5: Domain Layer

| File | Code | Purpose |
|------|------|---------|
| `CoachContext.swift:27` | `tier: SubscriptionTier` field | Tier passed into coach context |
| `CoachContext.swift:209-215` | `loadSubscription()` async method | Fetches tier from subscription client |

## Recommended Architecture Changes

### Strategy: Tier Flag Flip (Not File Deletion)

The safest, most incremental approach is to flip all capability flags to `true` while preserving the module structure. This avoids cascading build failures from removing types that ViewModels still reference.

**Why not delete the Subscription module outright:**
- `SubscriptionTier` enum is referenced in 15+ files across Domain, UI, and Tests
- `SubscriptionClientProtocol` is injected into 6 view models via constructors
- `CoachContext` stores a `SubscriptionTier` value
- Removing the module means touching 20+ files simultaneously with high regression risk

**Why flipping flags is better:**
- Single file change (`SubscriptionTier.swift`) unlocks all features
- View models still load subscription info (no broken references)
- Tests still compile and pass (just need expectation updates)
- Can be done in one commit, verified in one build

### Phase 1: Remove Feature Gating (Core Change)

**File: `SubscriptionTier.swift`**

Change all capability flags to return `true` and remove limits:

```swift
// BEFORE (current)
public var hasCustomBenchmarks: Bool { self != .free }
public var maxLifts: Int? { switch self { case .free: return 5 ... } }

// AFTER (free app -- all features unlocked)
public var hasCustomBenchmarks: Bool { true }
public var maxLifts: Int? { nil }  // unlimited for all
```

Every flag and limit in `SubscriptionTier` changes:
- `hasCustomBenchmarks` -> `true`
- `hasPainTrends` -> `true`
- `hasAdvancedInsights` -> `true`
- `hasAIBuilder` -> `true`
- `hasRecoveryAdjustments` -> `true`
- `hasAdaptivePlanner` -> `true`
- `hasCoachMemory` -> `true`
- `hasSmartSubstitutions` -> `true`
- `hasPlateauDetection` -> `true`
- `hasPreferenceLearning` -> `true`
- `hasWeeklyRecap` -> `true`
- `hasExportShare` -> `true`
- `maxLifts` -> `nil`
- `maxInjuries` -> `nil`
- `maxHistoryDays` -> `nil`
- `dailyAIGenerations` -> `Int.max` (or a very high number)

**File: `SubscriptionInfo.swift` (in SubscriptionTier.swift)**

```swift
// BEFORE
public var hasAccess: Bool { status.hasAccess && tier != .free }

// AFTER (free app -- always has access)
public var hasAccess: Bool { true }
```

### Phase 2: Remove Paywall UI

**Files to modify (not delete):**

| File | Change |
|------|--------|
| `DashboardView.swift` | Remove `upgradePrompts` view builder (lines 369-440). Remove `lockedFeatureCard` helper. Remove `showingSubscription` state. Remove `.sheet` for SubscriptionView. Change `coachingInsightsCard` to show for all users (remove `== .premium` check). Remove `canGenerateAIWorkout` gate or always set to `true`. |
| `CycleCorrelationChart.swift` | Remove `hasAccess` parameter. Remove `upgradeCard` view builder. Remove `showingSubscription` state and `.sheet`. Always show chart data (never show lock icon). |
| `ExportView.swift` | Remove `upgradeSection` view builder. Remove `canExport` conditional in body. Remove `showingSubscription` state and `.sheet`. Always show export flow. |
| `SettingsView.swift` | Remove entire `SubscriptionView` struct (lines 312-410). Remove `SubscriptionViewModel` class (lines 496-542). Remove `TierBadge` struct (lines 645-668). Remove `showingSubscription` from `SettingsViewModel`. Remove membership/subscription section from settings UI. Remove "Restore Purchases" button. |
| `AnalyticsView.swift` | Remove `showingSubscription` state (unused if CycleCorrelationChart no longer needs it). |

### Phase 3: Simplify Subscription Infrastructure

**Option A (Recommended): Stub the protocol, keep the module**

Keep `SubscriptionClientProtocol` and `MockSubscriptionClient` for test injection, but replace `StoreKitClient` with a simple stub that always returns premium access.

**New file: `FreeSubscriptionClient.swift`**

```swift
/// Client for the free app -- always returns full access.
public actor FreeSubscriptionClient: SubscriptionClientProtocol {
    public init() {}

    public var currentSubscription: SubscriptionInfo? {
        SubscriptionInfo(tier: .premium, status: .active)
    }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        SubscriptionInfo(tier: .premium, status: .active)
    }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo {
        throw SubscriptionError.productUnavailable(productId: tier.rawValue)
    }

    public func restorePurchases() async throws -> SubscriptionInfo {
        SubscriptionInfo(tier: .premium, status: .active)
    }

    public func presentManageSubscriptions() async throws { /* no-op */ }
    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool { false }
    public func getPrice(for tier: SubscriptionTier) async -> String? { nil }
}
```

**Option B (Later cleanup): Delete the module entirely**

This is a larger refactor that removes `StoreKitClient.swift`, `SubscriptionError.swift`, and the `StoreKit` import entirely. Only do this after Phase 1-3 are verified stable.

### Phase 4: App Entry Point Changes

**File: `SundeeFundeeApp/SundeeFundee/App.swift`**

```swift
// BEFORE
init() {
    let storeKitClient = StoreKitClient()
    SubscriptionClientFactory.shared.client = storeKitClient
    Task { await storeKitClient.startTransactionListener() }
}

// AFTER
init() {
    SubscriptionClientFactory.shared.client = FreeSubscriptionClient()
}
```

Remove `StoreKitClient` import/creation. No transaction listener needed.

**File: `AuthViewModel.swift`**

Remove three `StoreKitClient` identify/logout calls (lines 88-89, 164-165, 200-201). The `FreeSubscriptionClient` has no user identity to manage.

### Phase 5: Entitlements Cleanup

**File: `SundeeFundee.entitlements`**

Remove the `com.apple.developer.in-app-payments` entry:
```xml
<!-- REMOVE THIS -->
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.sundeefundee.app</string>
</array>
```

Keep all other entitlements (Apple Sign-In, HealthKit, CloudKit) -- they are still needed.

### Phase 6: Test Updates

**File: `AnalyticsViewModelTests.swift`**

Tests that check `tier == .free` expecting `hasCycleAccess == false` need updating:

| Test | Current Expectation | New Expectation |
|------|-------------------|-----------------|
| `testFreeTierNoCycleAccess` | `hasCycleAccess == false`, `cycleData.isEmpty` | `hasCycleAccess == true`, cycle data populated |
| `testCycleGatingOnTimeRangeChange` | `cycleData.isEmpty` after range change | `cycleData` populated (no longer gated) |
| `testPlusTierHasCycleAccess` | Verifies plus tier gets cycle data | Still passes (plus still works) |
| `testPremiumTierHasCycleAccess` | Verifies premium tier gets cycle data | Still passes |

Strategy: These tests currently pass `tier: .free` to `MockSubscriptionClient`. Since the flag change is in `SubscriptionTier`, the mock setup stays the same, but `hasAdvancedInsights` now returns `true` for `.free`. Tests verifying gating need to be updated to verify feature availability instead.

### Phase 7: App Store Preparation

**Files that need attention for App Store submission:**

| File/Area | Change | Reason |
|-----------|--------|--------|
| `PrivacyInfo.xcprivacy` | Review -- currently declares Health, Fitness, UserID data collection | App Store privacy labels must match. Since no purchase data is collected, no changes needed for subscription removal. |
| `project.yml` | `MARKETING_VERSION` bump to `1.1.0`, `CURRENT_PROJECT_VERSION` bump | Version for new submission |
| `Info.plist` | Ensure `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` are present | HealthKit permissions text for review |
| App Store Connect metadata | Set `isFree` = true, remove subscription products | App is now free with no IAP |
| App Store Connect metadata | Remove any subscription-related screenshots or marketing text | Store listing must not reference paid tiers |
| `SundeeFundee.entitlements` | Remove `com.apple.developer.in-app-payments` | No longer processing payments |

## Component Change Matrix

Summary of every file touched, categorized by change type.

### MODIFY (feature unlock)

| File | Change Type | Risk |
|------|-------------|------|
| `SubscriptionTier.swift` | Flip all flags to true/unlimited | LOW -- single source of truth |
| `SubscriptionInfo.hasAccess` | Return `true` always | LOW |

### MODIFY (UI cleanup)

| File | Change Type | Risk |
|------|-------------|------|
| `DashboardView.swift` | Remove upgrade prompts, unlock coaching card | MEDIUM -- substantial UI change |
| `CycleCorrelationChart.swift` | Remove upgrade card, always show chart | LOW -- small view |
| `ExportView.swift` | Remove upgrade section, always show export | LOW -- small view |
| `AnalyticsView.swift` | Remove unused subscription state | LOW -- minor |
| `SettingsView.swift` | Remove subscription section, ViewModel, TierBadge | MEDIUM -- multiple removals |

### MODIFY (infrastructure)

| File | Change Type | Risk |
|------|-------------|------|
| `App.swift` | Replace StoreKitClient with FreeSubscriptionClient | MEDIUM -- app bootstrap |
| `AuthViewModel.swift` | Remove StoreKit identify/logout calls | LOW -- 3 lines removed |
| `SundeeFundee.entitlements` | Remove in-app-payments | LOW -- config only |

### CREATE

| File | Change Type | Risk |
|------|-------------|------|
| `FreeSubscriptionClient.swift` | New stub client | LOW -- simple implementation |

### POTENTIALLY DELETE (after Phase 3 verified)

| File | Change Type | Risk |
|------|-------------|------|
| `StoreKitClient.swift` | Delete entirely | MEDIUM -- verify no other references |
| `SubscriptionError.swift` | Delete entirely | LOW -- only used by StoreKitClient |
| `StoreKitConfiguration.storekit` | Delete (does not exist yet) | N/A |

### UPDATE (tests)

| File | Change Type | Risk |
|------|-------------|------|
| `AnalyticsViewModelTests.swift` | Update expectations for unlocked features | LOW |

## Build Order (Dependency-Aware)

This order respects that changes in `SubscriptionTier` cascade to all consumers.

```
1. SubscriptionTier.swift          (foundation -- all flags flip here)
   |
2. FreeSubscriptionClient.swift    (new file, depends on SubscriptionClientProtocol)
   |
3. App.swift                       (swap StoreKitClient -> FreeSubscriptionClient)
   AuthViewModel.swift             (remove StoreKit identify/logout)
   |
4. DashboardView.swift             (remove upgrade UI)
   CycleCorrelationChart.swift     (remove upgrade card)
   ExportView.swift                 (remove upgrade section)
   AnalyticsView.swift              (minor cleanup)
   SettingsView.swift               (remove subscription UI)
   |
5. SundeeFundee.entitlements       (remove in-app-payments)
   |
6. Tests                           (update expectations)
   |
7. Build & Verify                  (full test run + manual verification)
```

Steps 1-3 can be committed together as one atomic "remove paywall" change. Steps 4-5 are UI/config cleanup that can follow. Step 6 validates.

## Data Flow After Changes

```
Before (current):
  App.swift -> StoreKitClient -> SubscriptionClientFactory
  ViewModel -> subscriptionClient.getSubscriptionInfo() -> SubscriptionInfo(tier: .free/.plus/.premium)
  ViewModel -> tier.hasFeature -> Bool (gated)
  View -> if !hasAccess { upgradeCard } else { feature }

After (free app):
  App.swift -> FreeSubscriptionClient -> SubscriptionClientFactory
  ViewModel -> subscriptionClient.getSubscriptionInfo() -> SubscriptionInfo(tier: .premium)
  ViewModel -> tier.hasFeature -> always true (flags flipped)
  View -> feature always shown (no upgradeCard code paths remain)
```

The key insight: `SubscriptionTier.premium` becomes the universal default. Every user gets premium-tier access. The protocol-based architecture means this swap is a one-line change in `App.swift`.

## What Stays Unchanged

These components remain exactly as-is:

- **Data Layer** (`DataClientProtocol`, `CloudKitClient`, `LocalDataClient`, `SyncQueue`) -- no subscription dependency
- **Domain Layer** (`Cycle/`, `Injury/`, `Benchmark/`, `AIWorkout/`, `Program/`, `Analytics/`, `Celebration/`) -- pure logic, no tier checks
- **Auth** (`AuthViewModel`, Apple Sign-In, Keychain) -- only the StoreKit identify calls change
- **HealthKit** (`HealthClientProtocol`, `HealthClientFactory`) -- no subscription dependency
- **Coach Domain** (`CoachServiceProtocol`, `CoachServiceFactory`) -- the tier field in CoachContext becomes `.premium` for all users
- **MockSubscriptionClient** -- still useful for tests
- **SubscriptionClientProtocol** -- still useful as the protocol FreeSubscriptionClient conforms to
- **SubscriptionClientFactory** -- still the central lookup for subscription client

## App Store Submission Checklist

Architecture-adjacent items for App Store readiness:

| Item | Status | Action Needed |
|------|--------|---------------|
| Privacy manifest (`PrivacyInfo.xcprivacy`) | EXISTS | Review -- health data collection declared, no purchase data. Valid for free app. |
| Entitlements | EXISTS | Remove `com.apple.developer.in-app-payments`. Keep HealthKit, CloudKit, Apple Sign-In. |
| `UIRequiredDeviceCapabilities` | Need to verify | Must be `arm64`, not `armv7` per CLAUDE.md |
| Code signing | `CODE_SIGN_STYLE: Automatic` | Correct -- no change needed |
| App icon | Need 1024x1024 universal | Verify in asset catalog |
| Subscription products in App Store Connect | Need to remove | Delete `sundee_plus_monthly`, `sundee_plus_annual`, `sundee_premium_monthly`, `sundee_premium_annual` |
| StoreKit configuration file | DOES NOT EXIST | Good -- nothing to clean up |
| Test email overrides | In `StoreKitClient.swift` DEBUG only | Will be removed when StoreKitClient is deleted |

## Sources

- Full source code audit of SundeeFundee/ and SundeeFundeeApp/ directories
- All 6 files in `Subscription/` module read and analyzed
- All paywall UI views traced through view model dependency injection
- Entitlements and privacy manifest reviewed
- App entry point bootstrap flow verified
