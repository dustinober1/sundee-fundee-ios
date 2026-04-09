# Technology Stack

**Project:** Sundee Fundee v1.1 Free App Launch
**Researched:** 2026-04-08
**Scope:** Removing StoreKit paywall and preparing App Store submission

## Executive Summary

This is a **reduction** milestone, not an addition milestone. The primary stack change is removing StoreKit dependencies and simplifying the subscription layer. No new frameworks, libraries, or SaaS tools are required. The App Store submission tooling is already available through Blitz MCP and the `asc` CLI bundled in the development environment. The existing project already has the correct privacy manifest, entitlements, and Info.plist configuration.

## Recommended Stack (Unchanged Core)

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift** | 6.0 | Core language | Swift 6 with complete concurrency checking; strict mode enabled via `SWIFT_STRICT_CONCURRENCY: complete` |
| **SwiftUI** | iOS 18+ | UI framework | Native declarative UI with Art Deco theme system |
| **XcodeGen** | Latest | Project generation | Generates Xcode project from `project.yml`; already configured |

### Data and Integration (Changes Noted)

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| **CloudKit** | iOS 18+ | Cloud sync | KEEP -- unchanged |
| **HealthKit** | iOS 18+ | Health data | KEEP -- unchanged |
| **StoreKit 2** | iOS 15+ | In-app purchases | REMOVE -- entire StoreKit integration being stripped |
| **Keychain Services** | Built-in | Secure storage | KEEP -- unchanged |
| **WidgetKit** | iOS 18+ | Live Activities | KEEP -- unchanged |
| **Apple Sign-In** | iOS 18+ | Authentication | KEEP -- unchanged |

### Testing (Unchanged)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **XCTest** | Built-in | Unit testing | Native testing framework |
| **Swift Testing** | Built-in | Modern test declarations | `@Test` functions, `import Testing` |
| **MockSubscriptionClient** | Existing | Test mocking | KEEP for test DI; simplified |

### Submission Tooling (Already Available)

| Tool | Location | Purpose |
|------|----------|---------|
| Blitz MCP (`blitz-macos`) | `.mcp.json` | Build, upload, fill ASC forms, submit for review |
| Blitz iPhone MCP (`blitz-iphone`) | `.mcp.json` | Simulator screenshots, UI inspection |
| `asc` CLI | `~/.blitz/bin/asc` | App Store Connect API operations (60+ subcommands) |
| `xcodebuild` | System | CLI builds for verification |

## What to REMOVE

### Files to Delete Entirely

| File | Lines | Why Delete |
|------|-------|-----------|
| `SundeeFundee/Sources/SundeeFundeeKit/Subscription/StoreKitClient.swift` | 313 | StoreKit 2 purchase/restore/listen logic entirely unused in free app. Contains `import StoreKit`, product IDs, transaction listener, pro test email overrides. |

### Entitlements to Remove

**File:** `SundeeFundeeApp/SundeeFundee/SundeeFundee.entitlements`

Remove the `com.apple.developer.in-app-payments` entry and its `merchant.com.sundeefundee.app` string. Everything else (Apple Sign-In, HealthKit, CloudKit, APS environment) stays.

### UI Components to Remove

| Component | File | What to Remove |
|-----------|------|---------------|
| `SubscriptionView` | `Settings/SettingsView.swift` (lines 312-494) | Entire paywall UI with tier cards, purchase buttons, restore button |
| `SubscriptionViewModel` | `Settings/SettingsView.swift` (lines 498-542) | Purchase/restore view model |
| `TierBadge` | `Settings/SettingsView.swift` (lines 648-668) | Tier display badge component |
| "Manage Subscription" button | `Settings/SettingsView.swift` (lines 46-48) | Subscription management trigger |
| Upgrade prompts section | `Dashboard/DashboardView.swift` (lines 372-428) | `upgradePrompts`, `lockedFeatureCard`, "Unlock with Plus/Pro" CTAs |
| Export upgrade section | `Export/ExportView.swift` | Lock icon, upgrade CTA, subscription check |
| Subscription sheet presentation | DashboardView, SettingsView, ExportView, BenchmarksListView, AnalyticsView | `.sheet(isPresented: $showingSubscription)` across 5 views |

### Subscription Gating Logic to Remove

| View Model | File | Gating to Remove |
|------------|------|-----------------|
| `DashboardViewModel` | `Dashboard/DashboardView.swift` | `subscriptionTier` checks for AI builder, coaching insights, upgrade prompts |
| `ExportViewModel` | `Export/ExportView.swift` | `canExport` check on `currentTier.hasExportShare` |
| `AnalyticsViewModel` | `Analytics/AnalyticsViewModel.swift` | `hasCycleAccess` check on `subscriptionTier.hasAdvancedInsights` |
| `PainTrackingViewModel` | `PainTrackingViewModel.swift` | Smart substitutions gating on `info.tier.hasSmartSubstitutions` |
| `BenchmarksViewModel` | `BenchmarksViewModel.swift` | Custom benchmark restrictions |
| `SettingsViewModel` | `Settings/SettingsView.swift` | `loadSubscriptionTier()`, `currentTier` state |

### Auth Integration to Remove

**File:** `AuthViewModel.swift`

Three `StoreKitClient` cast-and-call sites:
1. Line 88-89: `subscriptionClient.identify(userId:email:)` in `signInWithApple()`
2. Line 164-166: `subscriptionClient.logout()` in `resetState()`
3. Line 200-202: `subscriptionClient.identify(userId:email:)` in `checkExistingSession()`

Safe to remove because `FreeSubscriptionClient` has no user state to manage.

### App Entry Point to Simplify

**File:** `SundeeFundeeApp/SundeeFundee/App.swift`

Remove:
```swift
let storeKitClient = StoreKitClient()
SubscriptionClientFactory.shared.client = storeKitClient
Task { await storeKitClient.startTransactionListener() }
```

Replace with:
```swift
SubscriptionClientFactory.shared.client = FreeSubscriptionClient()
```

## What to KEEP (Simplified)

| Technology | Location | What Changes |
|------------|----------|-------------|
| `SubscriptionTier` enum | `Subscription/SubscriptionTier.swift` | All capability flags (`hasCustomBenchmarks`, `hasPainTrends`, `hasAdvancedInsights`, `hasAIBuilder`, `hasRecoveryAdjustments`, `hasAdaptivePlanner`, `hasCoachMemory`, `hasSmartSubstitutions`, `hasPlateauDetection`, `hasPreferenceLearning`, `hasWeeklyRecap`, `hasExportShare`) return `true`. `maxLifts`/`maxInjuries`/`maxHistoryDays` return `nil` (unlimited). `dailyAIGenerations` returns a generous value. |
| `SubscriptionInfo` struct | `Subscription/SubscriptionInfo.swift` | Keep as-is. `FreeSubscriptionClient` returns an instance with `tier: .free, status: .active`. |
| `SubscriptionClientProtocol` | `Subscription/SubscriptionClientProtocol.swift` | Keep unchanged. View models depend on this protocol for dependency injection. |
| `SubscriptionClientFactory` | `Subscription/SubscriptionClientFactory.swift` | Keep unchanged. `App.swift` sets `.client = FreeSubscriptionClient()`. |
| `MockSubscriptionClient` | `Subscription/MockSubscriptionClient.swift` | Keep for tests. Can seed with any tier for test scenarios. |
| `SubscriptionError` | `Subscription/SubscriptionError.swift` | Keep. Still useful for error handling patterns in tests. |

## What to ADD

### One New File: FreeSubscriptionClient

**File:** `SundeeFundee/Sources/SundeeFundeeKit/Subscription/FreeSubscriptionClient.swift`

This is the linchpin of the paywall removal. By keeping `SubscriptionClientProtocol` and `SubscriptionClientFactory` intact and swapping the production client, no view model code needs to change how it checks subscription state -- every check simply returns "you have full access."

```swift
import Foundation

/// Actor-based client for a free app with no subscriptions.
/// All features are unlocked. Purchase and restore are no-ops.
public actor FreeSubscriptionClient: SubscriptionClientProtocol {
    private let fullAccess = SubscriptionInfo(
        tier: .free,
        status: .active,
        startDate: nil,
        expiryDate: nil,
        willRenew: false,
        entitlementId: nil,
        originalTransactionId: nil
    )

    public init() {}

    public var currentSubscription: SubscriptionInfo? { fullAccess }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo { fullAccess }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo { fullAccess }

    public func restorePurchases() async throws -> SubscriptionInfo { fullAccess }

    public func presentManageSubscriptions() async throws { /* no-op */ }

    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool { true }

    public func getPrice(for tier: SubscriptionTier) async -> String? { nil }
}
```

**Why this approach over deleting the entire subscription layer:**
- The protocol/factory pattern is used in 7+ view models and 21 files total
- Deleting the layer means updating every view model, domain type, and test file
- Keeping the protocol and replacing the implementation is a 1-file change for the data layer
- The capability flags on `SubscriptionTier` become the real unlock mechanism (all return `true`)

### No New Frameworks, Libraries, or Tools

The App Store submission workflow uses tools already configured in the project:
- Blitz MCP for build, upload, form filling, submission
- `asc` CLI for API operations beyond MCP scope
- `blitz-iphone` for simulator screenshots
- `xcodebuild` for CLI build verification

## What NOT to Add

| Technology | Why Not |
|------------|--------|
| Any third-party SDK | No new analytics, crash reporting, or monetization. Free app with no tracking. |
| App Tracking Transparency prompt | The app does not track users. `NSPrivacyTracking` is already `false`. |
| RevenueCat / Purchases SDK | Replacing StoreKit with a third-party IAP manager defeats the purpose of removing the paywall. |
| CI/CD service (Fastlane, Xcode Cloud) | Explicitly out of scope per PROJECT.md. Blitz handles build and upload. |
| Screenshot automation (snapshot) | Blitz MCP and `blitz-iphone` handle simulator screenshots natively. |
| SwiftLint | Already configured in v1.0 (`.swiftlint.yml`). |

## App Store Submission Checklist

### Already Correct (No Changes Needed)

| Item | File | Status |
|------|------|--------|
| Privacy manifest | `PrivacyInfo.xcprivacy` | Correct: health data, fitness data, user ID declared as linked for app functionality, not tracking. No changes needed after removing StoreKit. |
| App icon | Asset catalog | 1024x1024 universal icon present |
| Device capabilities | `Info.plist` | `arm64` only (correct) |
| HealthKit usage strings | `Info.plist` | Both share and update descriptions present and accurate |
| Launch screen | `Info.plist` | `UIColorName: LaunchBackground` configured |
| Orientation | `Info.plist` | iPhone portrait only; iPad all orientations |
| Code signing | `project.yml` | `CODE_SIGN_STYLE: Automatic` |
| Bundle ID | `project.yml` | `com.sundeefundee.app` |
| App Group | `project.yml` | `group.com.sundeefundee.shared` |

### Needs Entry (via Blitz MCP or ASC UI)

| Field | Required | Tool | Notes |
|-------|----------|------|-------|
| App title | Yes | `asc_fill_form` tab="appInformation" | Max 30 chars. "Sundee Fundee" fits. |
| Description | Yes | `asc_fill_form` | Max 4000 chars |
| Keywords | Yes | `asc_fill_form` | Max 100 chars, comma-separated |
| Support URL | Yes | `asc_fill_form` | e.g., `https://sundeefundee.com/support` |
| Privacy Policy URL | Yes | `asc_fill_form` | `https://sundeefundee.com/privacy` (already in SettingsView) |
| Copyright | Yes | `asc_fill_form` | e.g., "2026 Sundee Fundee" |
| Primary category | Yes | `asc_fill_form` | `HEALTH_AND_FITNESS` |
| Content rights | Yes | `asc_fill_form` | `DOES_NOT_USE_THIRD_PARTY_CONTENT` |
| Age rating | Yes | `asc_fill_form` tab="review.ageRating" | `healthOrWellnessTopics: true`; likely 4+ or 12+ |
| Review contact | Yes | `asc_fill_form` tab="review.contact" | Name, email, phone required |
| Monetization | Yes | `asc_fill_form` tab="monetization" | Set `isFree: "true"` |
| Privacy Nutrition Labels | Yes | ASC UI (manual) | Not available via API. Must be entered in App Store Connect web interface. |
| Screenshots | Yes | `blitz-iphone` + MCP upload | iPhone 6.7" required (1290x2796). Up to 10 per size. |

### Submission Workflow

1. **Build:** `app_store_build` MCP tool or `xcodebuild` CLI
2. **Upload:** `app_store_upload` MCP tool
3. **Metadata:** `asc_fill_form` for each tab (appInformation, monetization, review.ageRating, review.contact)
4. **Screenshots:** `blitz-iphone` for capture, MCP for upload
5. **Validate:** `asc_open_submit_preview` to check readiness
6. **Submit:** Via Blitz MCP or `asc submit create`

## Integration Points Summary

### Files Touched by Paywall Removal (21 files reference SubscriptionTier)

| File | Change Type | Scope |
|------|-------------|-------|
| `Subscription/StoreKitClient.swift` | DELETE | Entire file |
| `Subscription/SubscriptionTier.swift` | MODIFY | All capability flags to return true; remove limits |
| `Subscription/SubscriptionClientProtocol.swift` | KEEP | No changes |
| `Subscription/SubscriptionClientFactory.swift` | KEEP | No changes |
| `Subscription/MockSubscriptionClient.swift` | KEEP | Still used by tests |
| `Subscription/SubscriptionError.swift` | KEEP | Still used by error handling |
| `Subscription/FreeSubscriptionClient.swift` | CREATE | New file |
| `App.swift` | MODIFY | Swap StoreKitClient for FreeSubscriptionClient |
| `SundeeFundee.entitlements` | MODIFY | Remove in-app-payments entry |
| `UI/Views/Settings/SettingsView.swift` | MODIFY | Remove SubscriptionView, SubscriptionViewModel, TierBadge, Manage button |
| `UI/Views/Dashboard/DashboardView.swift` | MODIFY | Remove upgradePrompts, lockedFeatureCard, subscription checks |
| `UI/Views/Export/ExportView.swift` | MODIFY | Remove export gating, upgrade section |
| `UI/Views/Analytics/AnalyticsView.swift` | MODIFY | Remove cycle gating |
| `UI/Views/Benchmarks/BenchmarksListView.swift` | MODIFY | Remove subscription trigger |
| `UI/ViewModels/AuthViewModel.swift` | MODIFY | Remove StoreKitClient casts and calls |
| `UI/ViewModels/AnalyticsViewModel.swift` | MODIFY | Remove hasCycleAccess tier check |
| `UI/ViewModels/ExportViewModel.swift` | MODIFY | Remove canExport tier check |
| `UI/ViewModels/PainTrackingViewModel.swift` | MODIFY | Remove smart substitutions tier check |
| `UI/ViewModels/BenchmarksViewModel.swift` | MODIFY | Remove tier restrictions |
| `DomainLayer/Coach/CoachContext.swift` | KEEP | References SubscriptionTier but no changes needed |
| `DomainLayer/Benchmark/BenchmarkModels.swift` | KEEP | No subscription references |
| `Tests/.../AnalyticsViewModelTests.swift` | MODIFY | Update gating tests to verify "always unlocked" |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Missed subscription-gating code path | Medium | High (paywall in "free" app = instant rejection) | Grep found all 21 files; methodical layer-by-layer removal |
| Dead paywall strings ("Unlock with Plus") | Medium | Medium (reviewer confusion, user confusion) | Search for "Unlock", "Pro", "Plus", "Upgrade", "lock.fill" across all UI files |
| Test breakage from tier changes | Medium | Medium | Update gating tests; run full `swift test` before submission |
| App Store rejection for metadata | Low | Low | Blitz MCP `asc_open_submit_preview` validates before submit |
| Privacy manifest inaccuracy | Low | High | Review after removing StoreKit; no data types change |
| Entitlements build failure | Low | Medium | `xcodebuild` after entitlements change to verify |

## Installation

```bash
# No new packages to install.
# The change is purely removal and simplification of existing code.

# Verify build after changes:
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests after changes:
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundee
swift test
```

## Confidence Assessment

| Area | Confidence | Reason |
|------|-----------|--------|
| Subscription removal approach | HIGH | All 21 referencing files identified via grep; factory-replacement strategy minimizes blast radius |
| Entitlements changes | HIGH | Single XML key removal; well-understood Apple entitlement model |
| App Store submission tooling | HIGH | Blitz MCP + `asc` CLI already configured, documented, and tested |
| Privacy manifest correctness | HIGH | No data types change when removing StoreKit; manifest already accurate |
| Tier capability flag changes | HIGH | Straightforward boolean flips; existing tests verify behavior |
| App Store metadata | MEDIUM | Requirements well-known but Apple can reject for subjective reasons |

## Sources

- Apple Developer Documentation: [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- Apple Developer Documentation: [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Codebase analysis: 21 files referencing `SubscriptionTier` via `ripgrep`
- Project configuration: `project.yml`, `Package.swift`, `SundeeFundee.entitlements`, `PrivacyInfo.xcprivacy`, `Info.plist`
- Blitz MCP documentation: `.claude/rules/blitz.md` and `SundeeFundeeApp/CLAUDE.md`
