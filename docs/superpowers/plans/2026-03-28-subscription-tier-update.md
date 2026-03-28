# Subscription Tier Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the subscription infrastructure to reflect the new three-tier model: Free (on-device AI, unlimited), Plus ($6.99, Haiku, 1 cloud/day), Premium ($12.99, Sonnet, 10 cloud/day with nudge at 7).

**Architecture:** Update four Domain files (SubscriptionTier, FeatureEntitlement, AIWorkoutLimits, DowngradePolicy), analytics events, PaywallView, ManageSubscriptionView, StoreKit config, and all corresponding tests. Remove WOD execution gating (now free). Switch AI limits from monthly to daily. Add new GatedFeature cases for future Plus/Premium features. No new files — all changes modify existing files.

**Tech Stack:** Swift 6, SwiftUI, StoreKit 2, Swift Testing framework

**Scope note:** This plan covers the subscription infrastructure changes only. The actual implementation of new features (program builder, mesocycle plans, AI coach memory, etc.) will each require their own spec → plan cycles. This plan adds them as gated feature *placeholders* so the entitlement system is ready when those features ship.

---

### Task 1: Update SubscriptionTier — Value Propositions and AI Model Identifier

**Files:**
- Modify: `SundeeFundee/Domain/Subscription/SubscriptionTier.swift`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing tests**

Add to `SubscriptionTierTests` in `SundeeFundeTests/SubscriptionTests.swift`:

```swift
@Test func valuePropositions() {
    #expect(SubscriptionTier.free.valueProposition == "Unlimited on-device AI workouts")
    #expect(SubscriptionTier.plus.valueProposition == "Cloud-powered AI workouts and programming tools")
    #expect(SubscriptionTier.premium.valueProposition == "Personal AI coach that learns and adapts")
}

@Test func subscriptionDescriptions() {
    #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
    #expect(SubscriptionTier.plus.subscriptionDescription == "Haiku-powered cloud AI and custom programming tools.")
    #expect(SubscriptionTier.premium.subscriptionDescription == "Sonnet-powered AI coach with persistent memory.")
}

@Test func aiModelIdentifier() {
    #expect(SubscriptionTier.free.aiModelIdentifier == "on-device")
    #expect(SubscriptionTier.plus.aiModelIdentifier == "haiku")
    #expect(SubscriptionTier.premium.aiModelIdentifier == "sonnet")
}

@Test func dailyCloudAILimit() {
    #expect(SubscriptionTier.free.dailyCloudAILimit == nil)
    #expect(SubscriptionTier.plus.dailyCloudAILimit == 1)
    #expect(SubscriptionTier.premium.dailyCloudAILimit == 10)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/SubscriptionTierTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL — `valueProposition` strings don't match, `aiModelIdentifier` and `dailyCloudAILimit` don't exist.

- [ ] **Step 3: Update SubscriptionTier.swift**

In `SundeeFundee/Domain/Subscription/SubscriptionTier.swift`, replace the `valueProposition` computed property:

```swift
var valueProposition: String {
    switch self {
    case .free:
        return "Unlimited on-device AI workouts"
    case .plus:
        return "Cloud-powered AI workouts and programming tools"
    case .premium:
        return "Personal AI coach that learns and adapts"
    }
}
```

Replace the `subscriptionDescription` computed property:

```swift
var subscriptionDescription: String {
    switch self {
    case .free:
        return "Core training tools with unlimited on-device AI."
    case .plus:
        return "Haiku-powered cloud AI and custom programming tools."
    case .premium:
        return "Sonnet-powered AI coach with persistent memory."
    }
}
```

Add two new computed properties after `rank`:

```swift
/// Anthropic model identifier for cloud AI routing. nil for on-device only.
var aiModelIdentifier: String {
    switch self {
    case .free:    return "on-device"
    case .plus:    return "haiku"
    case .premium: return "sonnet"
    }
}

/// Maximum cloud AI workout generations per day. nil means no cloud access (free).
var dailyCloudAILimit: Int? {
    switch self {
    case .free:    return nil
    case .plus:    return 1
    case .premium: return 10
    }
}
```

- [ ] **Step 4: Remove the old `subscriptionDescriptionCopy` test**

In `SundeeFundeTests/SubscriptionTests.swift`, find the `SubscriptionTierCopyTests` suite (around line 549) and update the test:

```swift
@Suite("SubscriptionTier Copy")
struct SubscriptionTierCopyTests {

    @Test func subscriptionDescriptionCopy() {
        #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
        #expect(SubscriptionTier.plus.subscriptionDescription == "Haiku-powered cloud AI and custom programming tools.")
        #expect(SubscriptionTier.premium.subscriptionDescription == "Sonnet-powered AI coach with persistent memory.")
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/SubscriptionTierTests -only-testing:SundeeFundeTests/SubscriptionTierCopyTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/Subscription/SubscriptionTier.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: update SubscriptionTier with AI model identifiers and daily cloud limits"
```

---

### Task 2: Rewrite AIWorkoutLimits — Monthly to Daily, Remove On-Device Limits

**Files:**
- Modify: `SundeeFundee/Domain/Subscription/AIWorkoutLimits.swift`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace the entire `AIWorkoutLimitsTests` suite in `SundeeFundeTests/SubscriptionTests.swift`:

```swift
@Suite("AIWorkoutLimits")
struct AIWorkoutLimitsTests {

    // MARK: - Daily Cloud Limits

    @Test func dailyCloudLimitForAllTiers() {
        #expect(AIWorkoutLimits.dailyCloudLimit(for: .free) == 0)
        #expect(AIWorkoutLimits.dailyCloudLimit(for: .plus) == 1)
        #expect(AIWorkoutLimits.dailyCloudLimit(for: .premium) == 10)
    }

    @Test func canGenerateCloudWorkoutFreeNever() {
        #expect(AIWorkoutLimits.canGenerateCloud(tier: .free, generatedToday: 0) == false)
    }

    @Test func canGenerateCloudWorkoutPlusUnderLimit() {
        #expect(AIWorkoutLimits.canGenerateCloud(tier: .plus, generatedToday: 0) == true)
    }

    @Test func canGenerateCloudWorkoutPlusAtLimit() {
        #expect(AIWorkoutLimits.canGenerateCloud(tier: .plus, generatedToday: 1) == false)
    }

    @Test func canGenerateCloudWorkoutPremiumUnderLimit() {
        #expect(AIWorkoutLimits.canGenerateCloud(tier: .premium, generatedToday: 9) == true)
    }

    @Test func canGenerateCloudWorkoutPremiumAtLimit() {
        #expect(AIWorkoutLimits.canGenerateCloud(tier: .premium, generatedToday: 10) == false)
    }

    // MARK: - Soft Nudge

    @Test func shouldShowNudgePremiumAt7() {
        #expect(AIWorkoutLimits.shouldShowSoftNudge(tier: .premium, generatedToday: 7) == true)
        #expect(AIWorkoutLimits.shouldShowSoftNudge(tier: .premium, generatedToday: 8) == true)
    }

    @Test func shouldShowNudgePremiumUnder7() {
        #expect(AIWorkoutLimits.shouldShowSoftNudge(tier: .premium, generatedToday: 6) == false)
    }

    @Test func shouldShowNudgePlusNever() {
        #expect(AIWorkoutLimits.shouldShowSoftNudge(tier: .plus, generatedToday: 0) == false)
    }

    @Test func shouldShowNudgeFreeNever() {
        #expect(AIWorkoutLimits.shouldShowSoftNudge(tier: .free, generatedToday: 0) == false)
    }

    // MARK: - Remaining Text

    @Test func remainingCloudTextForPlus() {
        let text = AIWorkoutLimits.remainingCloudText(tier: .plus, generatedToday: 0)
        #expect(text == "1 cloud AI workout available today")
    }

    @Test func remainingCloudTextForPlusAtLimit() {
        let text = AIWorkoutLimits.remainingCloudText(tier: .plus, generatedToday: 1)
        #expect(text == "Daily cloud AI workout used — try on-device AI or come back tomorrow")
    }

    @Test func remainingCloudTextForPremium() {
        let text = AIWorkoutLimits.remainingCloudText(tier: .premium, generatedToday: 7)
        #expect(text == "3 of 10 cloud AI workouts left today")
    }

    @Test func remainingCloudTextForFree() {
        let text = AIWorkoutLimits.remainingCloudText(tier: .free, generatedToday: 0)
        #expect(text == nil)
    }

    // MARK: - On-Device Always Allowed

    @Test func canGenerateOnDeviceAlwaysTrue() {
        for tier in SubscriptionTier.allCases {
            #expect(AIWorkoutLimits.canGenerateOnDevice(tier: tier) == true)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/AIWorkoutLimitsTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL — old methods exist, new methods don't.

- [ ] **Step 3: Rewrite AIWorkoutLimits.swift**

Replace the entire contents of `SundeeFundee/Domain/Subscription/AIWorkoutLimits.swift`:

```swift
import Foundation

/// Pure-logic AI workout generation limits per subscription tier.
/// On-device generation is unlimited for all tiers.
/// Cloud AI (Anthropic) generation is gated by daily limits per tier.
enum AIWorkoutLimits {

    /// Soft nudge threshold for Premium users (show "try editing" message).
    static let premiumSoftNudgeThreshold = 7

    /// Maximum cloud AI generations per day. 0 means no cloud access.
    static func dailyCloudLimit(for tier: SubscriptionTier) -> Int {
        switch tier {
        case .free:    return 0
        case .plus:    return 1
        case .premium: return 10
        }
    }

    /// Whether the user can generate another cloud AI workout today.
    static func canGenerateCloud(tier: SubscriptionTier, generatedToday: Int) -> Bool {
        let limit = dailyCloudLimit(for: tier)
        guard limit > 0 else { return false }
        return generatedToday < limit
    }

    /// On-device AI is always available regardless of tier.
    static func canGenerateOnDevice(tier: SubscriptionTier) -> Bool {
        true
    }

    /// Whether to show the soft nudge ("try editing your workout instead") for Premium users.
    static func shouldShowSoftNudge(tier: SubscriptionTier, generatedToday: Int) -> Bool {
        tier == .premium && generatedToday >= premiumSoftNudgeThreshold
    }

    /// User-facing text showing remaining cloud AI workouts today.
    /// Returns nil for free tier (no cloud access).
    static func remainingCloudText(tier: SubscriptionTier, generatedToday: Int) -> String? {
        let limit = dailyCloudLimit(for: tier)
        guard limit > 0 else { return nil }
        let remaining = max(0, limit - generatedToday)
        if limit == 1 {
            return remaining > 0
                ? "1 cloud AI workout available today"
                : "Daily cloud AI workout used — try on-device AI or come back tomorrow"
        }
        return "\(remaining) of \(limit) cloud AI workouts left today"
    }
}
```

- [ ] **Step 4: Update AIWorkoutCTACard tests**

The `AIWorkoutCTACardTests` suite references the old `monthlyLimit` API. Find the `AIWorkoutCTACardTests` suite in `SundeeFundeTests/SubscriptionTests.swift` and update it. First check if `AIWorkoutCTACard.shouldShowPaywall` references the old API — if it does, update both the source and test. The test should become:

```swift
@Suite("AIWorkoutCTACard")
struct AIWorkoutCTACardTests {

    @Test func shouldShowPaywallFreeNoCloud() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .free, generatedToday: 0) == true)
    }

    @Test func shouldShowPaywallPlusAtLimit() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .plus, generatedToday: 1) == true)
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .plus, generatedToday: 0) == false)
    }

    @Test func shouldShowPaywallPremiumNever() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .premium, generatedToday: 9) == false)
    }
}
```

**Important:** You must also update the `AIWorkoutCTACard.shouldShowPaywall` static method in the source file to accept `generatedToday` instead of `generatedThisMonth`, and use `AIWorkoutLimits.canGenerateCloud`. Find the source file with: `grep -rn "shouldShowPaywall" SundeeFundee/Features/`

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/AIWorkoutLimitsTests -only-testing:SundeeFundeTests/AIWorkoutCTACardTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/Subscription/AIWorkoutLimits.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: rewrite AIWorkoutLimits from monthly to daily cloud limits with soft nudge"
```

---

### Task 3: Update GatedFeature — Remove WOD Execution Gate, Add New Feature Cases

**Files:**
- Modify: `SundeeFundee/Domain/Subscription/FeatureEntitlement.swift`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace the `FeatureEntitlementTests` suite in `SundeeFundeTests/SubscriptionTests.swift`:

```swift
@Suite("FeatureEntitlement")
struct FeatureEntitlementTests {

    // MARK: Tracking Limits

    @Test func maxTrackedLifts() {
        #expect(FeatureEntitlement.maxTrackedLifts(for: .free) == 5)
        #expect(FeatureEntitlement.maxTrackedLifts(for: .plus) == nil)
        #expect(FeatureEntitlement.maxTrackedLifts(for: .premium) == nil)
    }

    @Test func maxActiveInjuries() {
        #expect(FeatureEntitlement.maxActiveInjuries(for: .free) == 1)
        #expect(FeatureEntitlement.maxActiveInjuries(for: .plus) == nil)
        #expect(FeatureEntitlement.maxActiveInjuries(for: .premium) == nil)
    }

    @Test func workoutHistoryDaysLimit() {
        #expect(FeatureEntitlement.workoutHistoryDaysLimit(for: .free) == 30)
        #expect(FeatureEntitlement.workoutHistoryDaysLimit(for: .plus) == nil)
        #expect(FeatureEntitlement.workoutHistoryDaysLimit(for: .premium) == nil)
    }

    // MARK: Feature Access — Plus

    @Test func plusFeaturesRequirePlus() {
        let plusFeatures: [GatedFeature] = [
            .customBenchmarks, .painTrends, .effortTrends,
            .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory,
            .programBuilder, .periodizationTemplates, .autoDeload,
            .advancedAnalytics, .streaksAchievements,
        ]
        for feature in plusFeatures {
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .free) == false, "Free should NOT access \(feature)")
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .plus) == true, "Plus SHOULD access \(feature)")
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .premium) == true, "Premium SHOULD access \(feature)")
            #expect(FeatureEntitlement.minimumTierRequired(for: feature) == .plus)
        }
    }

    // MARK: Feature Access — Premium

    @Test func premiumFeaturesRequirePremium() {
        let premiumFeatures: [GatedFeature] = [
            .rehabSessions, .aiWorkoutHistory, .exportData,
            .aiCoachMemory, .mesocyclePlans, .progressiveOverload,
            .plateauDetection, .weeklyReports, .smartSubstitutions,
        ]
        for feature in premiumFeatures {
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .free) == false, "Free should NOT access \(feature)")
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .plus) == false, "Plus should NOT access \(feature)")
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .premium) == true, "Premium SHOULD access \(feature)")
            #expect(FeatureEntitlement.minimumTierRequired(for: feature) == .premium)
        }
    }

    @Test func allGatedFeaturesHaveDisplayNameAndDescription() {
        for feature in GatedFeature.allCases {
            #expect(!feature.displayName.isEmpty)
            #expect(!feature.featureDescription.isEmpty)
        }
    }

    @Test func gatedFeatureCaseCount() {
        // 11 Plus + 9 Premium = 20 total (wodExecution removed — now free)
        #expect(GatedFeature.allCases.count == 20)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/FeatureEntitlementTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL — new cases don't exist, `wodExecution` still exists.

- [ ] **Step 3: Update FeatureEntitlement.swift**

Replace the entire contents of `SundeeFundee/Domain/Subscription/FeatureEntitlement.swift`:

```swift
import Foundation

/// Features that can be gated behind a subscription tier.
enum GatedFeature: String, CaseIterable, Sendable {
    // Plus features
    case customBenchmarks
    case painTrends
    case effortTrends
    case unlimitedLifts
    case unlimitedInjuries
    case unlimitedHistory
    case programBuilder
    case periodizationTemplates
    case autoDeload
    case advancedAnalytics
    case streaksAchievements

    // Premium features
    case rehabSessions
    case aiWorkoutHistory
    case exportData
    case aiCoachMemory
    case mesocyclePlans
    case progressiveOverload
    case plateauDetection
    case weeklyReports
    case smartSubstitutions

    var displayName: String {
        switch self {
        case .customBenchmarks:       return "Custom Benchmarks"
        case .painTrends:             return "Recovery Trend Insights"
        case .effortTrends:           return "Workout Intelligence Trends"
        case .unlimitedLifts:         return "Unlimited Lift Tracking"
        case .unlimitedInjuries:      return "Unlimited Injury Profiles"
        case .unlimitedHistory:       return "Unlimited Workout History"
        case .programBuilder:         return "Custom Program Builder"
        case .periodizationTemplates: return "Periodization Templates"
        case .autoDeload:             return "Auto-Deload Scheduling"
        case .advancedAnalytics:      return "Advanced Analytics Dashboard"
        case .streaksAchievements:    return "Streaks & Achievements"
        case .rehabSessions:          return "Personalized Recovery Coaching"
        case .aiWorkoutHistory:       return "Coach Memory & Saved AI Workouts"
        case .exportData:             return "Progress Exports"
        case .aiCoachMemory:          return "Persistent AI Coach Memory"
        case .mesocyclePlans:         return "AI Mesocycle Plans"
        case .progressiveOverload:    return "Progressive Overload Tracking"
        case .plateauDetection:       return "Plateau Detection & Recommendations"
        case .weeklyReports:          return "Weekly AI Training Reports"
        case .smartSubstitutions:     return "Smart Exercise Substitutions"
        }
    }

    var featureDescription: String {
        switch self {
        case .customBenchmarks:       return "Create and track your own custom benchmark workouts."
        case .painTrends:             return "Unlock smarter recovery trend insights and pattern detection."
        case .effortTrends:           return "See advanced workout intelligence across your recent sessions."
        case .unlimitedLifts:         return "Track unlimited lifts and one-rep maxes."
        case .unlimitedInjuries:      return "Manage multiple active injury profiles simultaneously."
        case .unlimitedHistory:       return "Access your complete workout history without time limits."
        case .programBuilder:         return "Create your own multi-week training programs."
        case .periodizationTemplates: return "Use pre-built linear, undulating, and block periodization structures."
        case .autoDeload:             return "AI suggests deload weeks based on training volume and fatigue."
        case .advancedAnalytics:      return "Volume trends, intensity tracking, and muscle group balance."
        case .streaksAchievements:    return "Track consistency streaks and earn milestone badges."
        case .rehabSessions:          return "Get premium recovery coaching tailored to your current needs."
        case .aiWorkoutHistory:       return "Save workouts with coach memory for more personalized follow-ups."
        case .exportData:             return "Export progress data and coaching-ready summaries."
        case .aiCoachMemory:          return "Your AI coach remembers your training history and preferences."
        case .mesocyclePlans:         return "Multi-week periodized plans tailored to your cycle phase and goals."
        case .progressiveOverload:    return "Automatic load progression suggestions based on your performance."
        case .plateauDetection:       return "AI identifies stalls and suggests programming changes."
        case .weeklyReports:          return "Weekly summary of volume, intensity, recovery, and recommendations."
        case .smartSubstitutions:     return "Context-aware exercise swaps based on equipment, injuries, and fatigue."
        }
    }
}

/// Pure-logic feature gating — no framework dependencies. All static for testability.
enum FeatureEntitlement {

    // MARK: - Tracking Limits

    /// Maximum tracked lifts. Returns nil for unlimited.
    static func maxTrackedLifts(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 5
        case .plus:    return nil
        case .premium: return nil
        }
    }

    /// Maximum active injury profiles. Returns nil for unlimited.
    static func maxActiveInjuries(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 1
        case .plus:    return nil
        case .premium: return nil
        }
    }

    /// Workout history day limit. Returns nil for unlimited.
    static func workoutHistoryDaysLimit(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 30
        case .plus:    return nil
        case .premium: return nil
        }
    }

    // MARK: - Feature Access

    static func canAccess(feature: GatedFeature, tier: SubscriptionTier) -> Bool {
        tier.rank >= minimumTierRequired(for: feature).rank
    }

    static func minimumTierRequired(for feature: GatedFeature) -> SubscriptionTier {
        switch feature {
        case .customBenchmarks, .painTrends, .effortTrends,
             .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory,
             .programBuilder, .periodizationTemplates, .autoDeload,
             .advancedAnalytics, .streaksAchievements:
            return .plus
        case .rehabSessions, .aiWorkoutHistory, .exportData,
             .aiCoachMemory, .mesocyclePlans, .progressiveOverload,
             .plateauDetection, .weeklyReports, .smartSubstitutions:
            return .premium
        }
    }
}
```

- [ ] **Step 4: Fix references to removed `.wodExecution` case**

Search for all references to `.wodExecution` in the codebase:

```bash
grep -rn "wodExecution" SundeeFundee/ SundeeFundeTests/
```

Remove or update every reference:
- Any `.requiresSubscription(.wodExecution)` view modifier — remove the modifier entirely (WOD execution is now free)
- Any test assertions about `.wodExecution` — remove them
- The `FeatureGateModifierStaticTests` suite lists `.wodExecution` in `plusFeatures` — remove it from that array

- [ ] **Step 5: Update FeatureGateModifier tests**

In `SundeeFundeTests/SubscriptionTests.swift`, update the `FeatureGateModifierStaticTests` suite:

```swift
@Suite("FeatureGateModifier Statics")
@MainActor
struct FeatureGateModifierStaticTests {

    @Test func isLockedForFreeUser() {
        for feature in GatedFeature.allCases {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .free) == true)
        }
    }

    @Test func plusFeaturesUnlockedForPlus() {
        let plusFeatures: [GatedFeature] = [
            .customBenchmarks, .painTrends, .effortTrends,
            .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory,
            .programBuilder, .periodizationTemplates, .autoDeload,
            .advancedAnalytics, .streaksAchievements,
        ]
        for feature in plusFeatures {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .plus) == false)
        }
    }

    @Test func premiumFeaturesLockedForPlus() {
        let premiumFeatures: [GatedFeature] = [
            .rehabSessions, .aiWorkoutHistory, .exportData,
            .aiCoachMemory, .mesocyclePlans, .progressiveOverload,
            .plateauDetection, .weeklyReports, .smartSubstitutions,
        ]
        for feature in premiumFeatures {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .plus) == true)
        }
    }

    @Test func allFeaturesUnlockedForPremium() {
        for feature in GatedFeature.allCases {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .premium) == false)
        }
    }
}
```

- [ ] **Step 6: Run all subscription tests to verify**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/FeatureEntitlementTests -only-testing:SundeeFundeTests/FeatureGateModifierStaticTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add SundeeFundee/Domain/Subscription/FeatureEntitlement.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: remove wodExecution gate (now free), add 10 new GatedFeature cases for Plus/Premium"
```

---

### Task 4: Add New Analytics Events

**Files:**
- Modify: `SundeeFundee/Observability/AnalyticsEvent.swift`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing tests**

Update the `AnalyticsEventTests` suite in `SundeeFundeTests/SubscriptionTests.swift`:

```swift
@Suite("AnalyticsEvent")
struct AnalyticsEventTests {

    @Test func allEventsHaveStableRawValues() {
        // Existing events
        #expect(AnalyticsEvent.paywallImpression.rawValue == "paywall_impression")
        #expect(AnalyticsEvent.paywallDismissed.rawValue == "paywall_dismissed")
        #expect(AnalyticsEvent.purchaseStarted.rawValue == "purchase_started")
        #expect(AnalyticsEvent.purchaseCompleted.rawValue == "purchase_completed")
        #expect(AnalyticsEvent.purchaseCancelled.rawValue == "purchase_cancelled")
        #expect(AnalyticsEvent.purchaseFailed.rawValue == "purchase_failed")
        #expect(AnalyticsEvent.restoreStarted.rawValue == "restore_started")
        #expect(AnalyticsEvent.restoreCompleted.rawValue == "restore_completed")
        #expect(AnalyticsEvent.featureGateTapped.rawValue == "feature_gate_tapped")
        #expect(AnalyticsEvent.limitReached.rawValue == "limit_reached")
        #expect(AnalyticsEvent.subscriptionChanged.rawValue == "subscription_changed")
        #expect(AnalyticsEvent.trialStarted.rawValue == "trial_started")

        // New events
        #expect(AnalyticsEvent.cloudAIWorkoutGenerated.rawValue == "cloud_ai_workout_generated")
        #expect(AnalyticsEvent.cloudAIDailyLimitReached.rawValue == "cloud_ai_daily_limit_reached")
        #expect(AnalyticsEvent.cloudAISoftNudgeShown.rawValue == "cloud_ai_soft_nudge_shown")
        #expect(AnalyticsEvent.workoutEditedBeforeStart.rawValue == "workout_edited_before_start")
    }

    @Test func eventNameReturnsRawValue() {
        #expect(AnalyticsEvent.eventName(for: .paywallImpression) == "paywall_impression")
        #expect(AnalyticsEvent.eventName(for: .cloudAIWorkoutGenerated) == "cloud_ai_workout_generated")
    }

    @Test func allCasesCountIsStable() {
        #expect(AnalyticsEvent.allCases.count == 16)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/AnalyticsEventTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL — new cases don't exist, count is wrong.

- [ ] **Step 3: Add new cases to AnalyticsEvent.swift**

In `SundeeFundee/Observability/AnalyticsEvent.swift`, add the new cases before the `static func`:

```swift
enum AnalyticsEvent: String, CaseIterable, Sendable {
    // Paywall
    case paywallImpression = "paywall_impression"
    case paywallDismissed = "paywall_dismissed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case restoreStarted = "restore_started"
    case restoreCompleted = "restore_completed"

    // Feature gating
    case featureGateTapped = "feature_gate_tapped"
    case limitReached = "limit_reached"

    // Subscription lifecycle
    case subscriptionChanged = "subscription_changed"
    case trialStarted = "trial_started"

    // Cloud AI
    case cloudAIWorkoutGenerated = "cloud_ai_workout_generated"
    case cloudAIDailyLimitReached = "cloud_ai_daily_limit_reached"
    case cloudAISoftNudgeShown = "cloud_ai_soft_nudge_shown"
    case workoutEditedBeforeStart = "workout_edited_before_start"

    static func eventName(for event: AnalyticsEvent) -> String {
        event.rawValue
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/AnalyticsEventTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Observability/AnalyticsEvent.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add cloud AI analytics events for tier-based workout generation"
```

---

### Task 5: Update PaywallView — New Pricing, Comparison Table, Highlights

**Files:**
- Modify: `SundeeFundee/Features/Subscription/PaywallView.swift`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing tests**

Update the `PaywallViewStaticTests` suite in `SundeeFundeTests/SubscriptionTests.swift`:

```swift
@Suite("PaywallView Statics")
@MainActor
struct PaywallViewStaticTests {

    @Test func headerTitleWithFeature() {
        let title = PaywallView.headerTitle(triggeredBy: .customBenchmarks)
        #expect(title == "Unlock Custom Benchmarks")
    }

    @Test func headerTitleWithoutFeature() {
        let title = PaywallView.headerTitle(triggeredBy: nil)
        #expect(title == "Upgrade Your Training")
    }

    @Test func headerSubtitleWithFeature() {
        let subtitle = PaywallView.headerSubtitle(triggeredBy: .rehabSessions)
        #expect(subtitle == GatedFeature.rehabSessions.featureDescription)
    }

    @Test func headerSubtitleWithoutFeature() {
        let subtitle = PaywallView.headerSubtitle(triggeredBy: nil)
        #expect(subtitle.contains("Sundee Plus"))
    }

    @Test func ctaText() {
        #expect(PaywallView.ctaText(for: .plus) == "Subscribe to Sundee Plus")
        #expect(PaywallView.ctaText(for: .premium) == "Subscribe to Sundee Premium")
    }

    @Test func periodLabel() {
        #expect(PaywallView.periodLabel(for: .monthly) == "per month")
        #expect(PaywallView.periodLabel(for: .annual) == "per year")
    }

    @Test func fallbackPricesUpdated() {
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .monthly) == "$6.99")
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .annual) == "$54.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .monthly) == "$12.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .annual) == "$99.99")
        #expect(PaywallView.fallbackPrice(tier: .free, period: .monthly) == "Free")
    }

    @Test func tierHighlightsPlusUpdated() {
        let highlights = PaywallView.tierHighlights(for: .plus)
        #expect(highlights.count == 7)
        #expect(highlights.contains("Haiku-powered cloud AI (1/day)"))
        #expect(highlights.contains("Custom program builder"))
        #expect(highlights.contains("Periodization templates"))
    }

    @Test func tierHighlightsPremiumUpdated() {
        let highlights = PaywallView.tierHighlights(for: .premium)
        #expect(highlights.count == 7)
        #expect(highlights.contains("Everything in Plus"))
        #expect(highlights.contains("Sonnet-powered cloud AI (10/day)"))
        #expect(highlights.contains("AI mesocycle plans"))
    }

    @Test func tierHighlightsFreeEmpty() {
        #expect(PaywallView.tierHighlights(for: .free).isEmpty)
    }

    @Test func comparisonRowsUpdated() {
        let rows = PaywallView.comparisonRows()
        #expect(rows.count == 14)
        // Verify AI row reflects new limits
        let aiRow = rows.first { $0.feature == "Cloud AI Workouts" }
        #expect(aiRow?.free == "--")
        #expect(aiRow?.plus == "1/day")
        #expect(aiRow?.premium == "10/day")
        // Verify on-device row
        let onDeviceRow = rows.first { $0.feature == "On-Device AI" }
        #expect(onDeviceRow?.free == "Unlimited")
        #expect(onDeviceRow?.plus == "Unlimited")
        #expect(onDeviceRow?.premium == "Unlimited")
        // WOD execution should not appear (now free for all)
        let wodRow = rows.first { $0.feature == "WOD Execution" }
        #expect(wodRow == nil)
        for row in rows {
            #expect(!row.feature.isEmpty)
            #expect(!row.free.isEmpty)
            #expect(!row.plus.isEmpty)
            #expect(!row.premium.isEmpty)
        }
    }

    @Test func savingsText() {
        let text = PaywallView.savingsText(monthlyPrice: 6.99, annualPrice: 54.99)
        #expect(text.contains("Save"))
    }

    @Test func savingsTextZeroMonthly() {
        let text = PaywallView.savingsText(monthlyPrice: 0, annualPrice: 0)
        #expect(text == "")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/PaywallViewStaticTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL — old prices, old highlights, old comparison rows.

- [ ] **Step 3: Update PaywallView.swift static helpers**

In `SundeeFundee/Features/Subscription/PaywallView.swift`, update the following static methods:

Replace `fallbackPrice`:
```swift
static func fallbackPrice(tier: SubscriptionTier, period: BillingPeriod) -> String {
    switch (tier, period) {
    case (.plus, .monthly):    return "$6.99"
    case (.plus, .annual):     return "$54.99"
    case (.premium, .monthly): return "$12.99"
    case (.premium, .annual):  return "$99.99"
    default:                   return "Free"
    }
}
```

Replace `tierHighlights`:
```swift
static func tierHighlights(for tier: SubscriptionTier) -> [String] {
    switch tier {
    case .free:
        return []
    case .plus:
        return [
            "Haiku-powered cloud AI (1/day)",
            "Custom program builder",
            "Periodization templates",
            "Advanced analytics dashboard",
            "Full lift & history tracking",
            "Recovery trend insights",
            "Streaks & achievements",
        ]
    case .premium:
        return [
            "Everything in Plus",
            "Sonnet-powered cloud AI (10/day)",
            "Persistent AI coach memory",
            "AI mesocycle plans",
            "Plateau detection",
            "Weekly AI training reports",
            "Rehab coaching & data export",
        ]
    }
}
```

Replace `comparisonRows`:
```swift
static func comparisonRows() -> [ComparisonRow] {
    [
        ComparisonRow(feature: "On-Device AI", free: "Unlimited", plus: "Unlimited", premium: "Unlimited"),
        ComparisonRow(feature: "Cloud AI Workouts", free: "--", plus: "1/day", premium: "10/day"),
        ComparisonRow(feature: "AI Model", free: "On-device", plus: "Haiku", premium: "Sonnet"),
        ComparisonRow(feature: "Lift Tracking", free: "5", plus: "All", premium: "All"),
        ComparisonRow(feature: "Injury Profiles", free: "1", plus: "All", premium: "All"),
        ComparisonRow(feature: "Workout History", free: "30 days", plus: "All", premium: "All"),
        ComparisonRow(feature: "Program Builder", free: "--", plus: "Yes", premium: "Yes"),
        ComparisonRow(feature: "Periodization", free: "--", plus: "Yes", premium: "Yes"),
        ComparisonRow(feature: "Analytics Dashboard", free: "--", plus: "Yes", premium: "Yes"),
        ComparisonRow(feature: "AI Coach Memory", free: "--", plus: "--", premium: "Yes"),
        ComparisonRow(feature: "Mesocycle Plans", free: "--", plus: "--", premium: "Yes"),
        ComparisonRow(feature: "Plateau Detection", free: "--", plus: "--", premium: "Yes"),
        ComparisonRow(feature: "Weekly Reports", free: "--", plus: "--", premium: "Yes"),
        ComparisonRow(feature: "Data Export", free: "--", plus: "--", premium: "Yes"),
    ]
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/PaywallViewStaticTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/Subscription/PaywallView.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: update PaywallView with new pricing, AI model highlights, and expanded comparison"
```

---

### Task 6: Update ManageSubscriptionView and StoreKit Config

**Files:**
- Modify: `SundeeFundee/Features/Subscription/ManageSubscriptionView.swift`
- Modify: `SundeeFundee/Resources/SundeeFundee.storekit`
- Test: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write the failing test**

Update the `ManageSubscriptionViewStaticTests` suite:

```swift
@Suite("ManageSubscriptionView Statics")
@MainActor
struct ManageSubscriptionViewStaticTests {

    @Test func tierDescriptions() {
        #expect(ManageSubscriptionView.tierDescription(.free) == "Unlimited on-device AI workouts")
        #expect(ManageSubscriptionView.tierDescription(.plus) == "Haiku-powered cloud AI and programming tools")
        #expect(ManageSubscriptionView.tierDescription(.premium) == "Sonnet-powered personal AI coach")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/ManageSubscriptionViewStaticTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: FAIL

- [ ] **Step 3: Update ManageSubscriptionView.swift**

Replace the `tierDescription` static method:

```swift
static func tierDescription(_ tier: SubscriptionTier) -> String {
    switch tier {
    case .free:    return "Unlimited on-device AI workouts"
    case .plus:    return "Haiku-powered cloud AI and programming tools"
    case .premium: return "Sonnet-powered personal AI coach"
    }
}
```

- [ ] **Step 4: Update SundeeFundee.storekit**

Update the pricing in the StoreKit configuration file. This is a JSON file — update the `displayPrice` fields:

- `com.sundeefundee.sub.plus.monthly`: change `"displayPrice": "4.99"` to `"displayPrice": "6.99"`
- `com.sundeefundee.sub.plus.annual`: change `"displayPrice": "39.99"` to `"displayPrice": "54.99"`
- `com.sundeefundee.sub.premium.monthly`: change `"displayPrice": "9.99"` to `"displayPrice": "12.99"`
- `com.sundeefundee.sub.premium.annual`: change `"displayPrice": "79.99"` to `"displayPrice": "99.99"`

Also update the `description` fields:
- Plus products: `"Enhanced cloud AI workouts with Haiku, programming tools, and unlimited tracking."`
- Premium products: `"Sonnet-powered personal AI coach with persistent memory, mesocycle plans, and full feature access."`

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests/ManageSubscriptionViewStaticTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Features/Subscription/ManageSubscriptionView.swift SundeeFundee/Resources/SundeeFundee.storekit SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: update ManageSubscriptionView descriptions and StoreKit pricing"
```

---

### Task 7: Fix All Remaining Compilation Errors and Run Full Test Suite

**Files:**
- Potentially modify: any file referencing removed `.wodExecution` case or old `AIWorkoutLimits` API

- [ ] **Step 1: Build the project to find all compilation errors**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:"`

- [ ] **Step 2: Fix each compilation error**

Common issues to expect:
1. **`.wodExecution` references** — any view using `.requiresSubscription(.wodExecution)` needs that modifier removed
2. **Old `AIWorkoutLimits` API callers** — any code calling `monthlyLimit`, `canGenerate(tier:generatedThisMonth:)`, `remainingGenerations(tier:generatedThisMonth:)`, or `remainingText(tier:generatedThisMonth:)` needs updating to use the new daily API
3. **`AIWorkoutCTACard.shouldShowPaywall`** — update the static method signature from `generatedThisMonth` to `generatedToday` and use `AIWorkoutLimits.canGenerateCloud`

For each file, grep for the old API:
```bash
grep -rn "generatedThisMonth\|monthlyLimit\|wodExecution" SundeeFundee/ SundeeFundeTests/
```

Fix each reference to use the new API.

- [ ] **Step 3: Build again to verify zero errors**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | head -20`

Expected: No errors

- [ ] **Step 4: Run the full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30`

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "fix: update all callers for new daily AI limits and removed wodExecution gate"
```

---

### Task 8: Regenerate Xcode Project

**Files:**
- Regenerate: `SundeeFundee.xcodeproj`

- [ ] **Step 1: Run XcodeGen**

```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate
```

Expected: "Project generated"

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run full test suite one final time**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30`

Expected: All tests pass

- [ ] **Step 4: Commit if xcodeproj changed**

```bash
git add SundeeFundee.xcodeproj
git commit -m "chore: regenerate Xcode project after subscription tier updates"
```

---

## Future Plans (Out of Scope)

Each of these requires its own brainstorm → spec → plan cycle:

1. **Cloudflare Worker Anthropic Proxy** — Route cloud AI requests through the existing worker, add tier-based model selection (Haiku/Sonnet), server-side rate limiting via KV store
2. **Cloud AI Workout Integration** — Wire the iOS app to call the proxy instead of on-device for Plus/Premium users, with edit-before-start flow
3. **Program Builder** (Plus) — Custom multi-week program creation UI
4. **Periodization Templates** (Plus) — Pre-built periodization structures
5. **Auto-Deload Scheduling** (Plus) — AI-suggested deload weeks
6. **Advanced Analytics Dashboard** (Plus) — Volume trends, intensity tracking, muscle group balance
7. **Streaks & Achievements** (Plus) — Consistency tracking and milestone badges
8. **AI Coach Memory** (Premium) — Persistent training context across sessions
9. **AI Mesocycle Plans** (Premium) — Multi-week periodized plan generation
10. **Progressive Overload Tracking** (Premium) — Load progression suggestions
11. **Plateau Detection** (Premium) — Stall identification and recommendations
12. **Weekly AI Reports** (Premium) — Training summary and recommendations
13. **Smart Substitutions** (Premium) — Context-aware exercise swaps
