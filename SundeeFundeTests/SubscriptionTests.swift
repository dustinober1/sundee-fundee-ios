import Testing
import Foundation
@testable import SundeeFundee

// MARK: - SubscriptionTier Tests

@Suite("SubscriptionTier")
struct SubscriptionTierTests {

    @Test func displayNames() {
        #expect(SubscriptionTier.free.displayName == "Free")
        #expect(SubscriptionTier.plus.displayName == "Sundee Plus")
        #expect(SubscriptionTier.premium.displayName == "Sundee Premium")
    }

    @Test func monthlyProductIDs() {
        #expect(SubscriptionTier.free.monthlyProductID == "")
        #expect(SubscriptionTier.plus.monthlyProductID == "com.sundeefundee.app.plus.monthly")
        #expect(SubscriptionTier.premium.monthlyProductID == "com.sundeefundee.app.premium.monthly")
    }

    @Test func annualProductIDs() {
        #expect(SubscriptionTier.free.annualProductID == "")
        #expect(SubscriptionTier.plus.annualProductID == "com.sundeefundee.app.plus.annual")
        #expect(SubscriptionTier.premium.annualProductID == "com.sundeefundee.app.premium.annual")
    }

    @Test func ranks() {
        #expect(SubscriptionTier.free.rank == 0)
        #expect(SubscriptionTier.plus.rank == 1)
        #expect(SubscriptionTier.premium.rank == 2)
        #expect(SubscriptionTier.free.rank < SubscriptionTier.plus.rank)
        #expect(SubscriptionTier.plus.rank < SubscriptionTier.premium.rank)
    }

    @Test func allProductIDsContainsFourIDs() {
        let ids = SubscriptionTier.allProductIDs
        #expect(ids.count == 4)
        #expect(ids.contains("com.sundeefundee.app.plus.monthly"))
        #expect(ids.contains("com.sundeefundee.app.plus.annual"))
        #expect(ids.contains("com.sundeefundee.app.premium.monthly"))
        #expect(ids.contains("com.sundeefundee.app.premium.annual"))
    }

    @Test func fromProductIDMapsCorrectly() {
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.app.plus.monthly") == .plus)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.app.plus.annual") == .plus)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.app.premium.monthly") == .premium)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.app.premium.annual") == .premium)
        #expect(SubscriptionTier.fromProductID("unknown.product.id") == .free)
        #expect(SubscriptionTier.fromProductID("") == .free)
    }

    @Test func allCasesIncludesAllTiers() {
        #expect(SubscriptionTier.allCases.count == 3)
        #expect(SubscriptionTier.allCases.contains(.free))
        #expect(SubscriptionTier.allCases.contains(.plus))
        #expect(SubscriptionTier.allCases.contains(.premium))
    }

    @Test func codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for tier in SubscriptionTier.allCases {
            let data = try encoder.encode(tier)
            let decoded = try decoder.decode(SubscriptionTier.self, from: data)
            #expect(decoded == tier)
        }
    }
}

// MARK: - FeatureEntitlement Tests

@Suite("FeatureEntitlement")
struct FeatureEntitlementTests {

    // MARK: AI Workout Limits

    @Test func aiWorkoutLimitPerTier() {
        #expect(FeatureEntitlement.aiWorkoutLimit(for: .free) == 3)
        #expect(FeatureEntitlement.aiWorkoutLimit(for: .plus) == 15)
        #expect(FeatureEntitlement.aiWorkoutLimit(for: .premium) == nil)
    }

    @Test func canGenerateAIWorkoutFree() {
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .free, usedThisMonth: 0) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .free, usedThisMonth: 2) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .free, usedThisMonth: 3) == false)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .free, usedThisMonth: 10) == false)
    }

    @Test func canGenerateAIWorkoutPlus() {
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .plus, usedThisMonth: 0) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .plus, usedThisMonth: 14) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .plus, usedThisMonth: 15) == false)
    }

    @Test func canGenerateAIWorkoutPremiumAlwaysTrue() {
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .premium, usedThisMonth: 0) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .premium, usedThisMonth: 100) == true)
        #expect(FeatureEntitlement.canGenerateAIWorkout(tier: .premium, usedThisMonth: 999) == true)
    }

    @Test func aiWorkoutsRemainingFree() {
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .free, usedThisMonth: 0) == 3)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .free, usedThisMonth: 1) == 2)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .free, usedThisMonth: 3) == 0)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .free, usedThisMonth: 5) == 0)
    }

    @Test func aiWorkoutsRemainingPlus() {
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .plus, usedThisMonth: 0) == 15)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .plus, usedThisMonth: 10) == 5)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .plus, usedThisMonth: 15) == 0)
    }

    @Test func aiWorkoutsRemainingPremiumIsMaxInt() {
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .premium, usedThisMonth: 0) == Int.max)
        #expect(FeatureEntitlement.aiWorkoutsRemaining(tier: .premium, usedThisMonth: 999) == Int.max)
    }

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

    // MARK: Feature Access

    @Test func plusFeaturesRequirePlus() {
        let plusFeatures: [GatedFeature] = [.customBenchmarks, .painTrends, .effortTrends, .wodExecution, .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory]
        for feature in plusFeatures {
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .free) == false)
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .plus) == true)
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .premium) == true)
            #expect(FeatureEntitlement.minimumTierRequired(for: feature) == .plus)
        }
    }

    @Test func premiumFeaturesRequirePremium() {
        let premiumFeatures: [GatedFeature] = [.rehabSessions, .aiWorkoutHistory, .exportData]
        for feature in premiumFeatures {
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .free) == false)
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .plus) == false)
            #expect(FeatureEntitlement.canAccess(feature: feature, tier: .premium) == true)
            #expect(FeatureEntitlement.minimumTierRequired(for: feature) == .premium)
        }
    }

    @Test func allGatedFeaturesHaveDisplayNameAndDescription() {
        for feature in GatedFeature.allCases {
            #expect(!feature.displayName.isEmpty)
            #expect(!feature.featureDescription.isEmpty)
        }
    }
}

// MARK: - AIUsageTracker Tests

@Suite("AIUsageTracker")
struct AIUsageTrackerTests {

    private func freshDefaults() -> UserDefaults {
        let suite = "test.aiUsageTracker.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func currentMonthKeyFormat() {
        let date = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!
        let key = AIUsageTracker.currentMonthKey(now: date)
        #expect(key == "2026-03")
    }

    @Test func currentMonthKeySingleDigitMonth() {
        let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 1).date!
        let key = AIUsageTracker.currentMonthKey(now: date)
        #expect(key == "2026-01")
    }

    @Test func usageStartsAtZero() {
        let defaults = freshDefaults()
        let usage = AIUsageTracker.usageThisMonth(defaults: defaults)
        #expect(usage == 0)
    }

    @Test func incrementUsageIncrementsCount() {
        let defaults = freshDefaults()
        AIUsageTracker.incrementUsage(defaults: defaults)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults) == 1)
        AIUsageTracker.incrementUsage(defaults: defaults)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults) == 2)
    }

    @Test func usageResetsOnNewMonth() {
        let defaults = freshDefaults()
        let march = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!
        let april = DateComponents(calendar: .current, year: 2026, month: 4, day: 1).date!

        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults, now: march) == 2)

        // New month resets
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults, now: april) == 0)
    }

    @Test func incrementInNewMonthResetsAndStartsAtOne() {
        let defaults = freshDefaults()
        let march = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!
        let april = DateComponents(calendar: .current, year: 2026, month: 4, day: 1).date!

        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.incrementUsage(defaults: defaults, now: april)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults, now: april) == 1)
    }

    @Test func resetIfNewMonthClearsCount() {
        let defaults = freshDefaults()
        let march = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!
        let april = DateComponents(calendar: .current, year: 2026, month: 4, day: 1).date!

        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.resetIfNewMonth(defaults: defaults, now: april)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults, now: april) == 0)
    }

    @Test func resetIfNewMonthNoop() {
        let defaults = freshDefaults()
        let march = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!

        AIUsageTracker.incrementUsage(defaults: defaults, now: march)
        AIUsageTracker.resetIfNewMonth(defaults: defaults, now: march)
        #expect(AIUsageTracker.usageThisMonth(defaults: defaults, now: march) == 1)
    }
}

// MARK: - SubscriptionManager Static Tests

@Suite("SubscriptionManager Statics")
@MainActor
struct SubscriptionManagerStaticTests {

    @Test func tierFromProductIDNil() {
        #expect(SubscriptionManager.tierFromProductID(nil) == .free)
    }

    @Test func tierFromProductIDPlus() {
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.app.plus.monthly") == .plus)
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.app.plus.annual") == .plus)
    }

    @Test func tierFromProductIDPremium() {
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.app.premium.monthly") == .premium)
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.app.premium.annual") == .premium)
    }

    @Test func tierFromProductIDUnknown() {
        #expect(SubscriptionManager.tierFromProductID("unknown") == .free)
    }

    @Test func highestTierFromEmpty() {
        #expect(SubscriptionManager.highestTier(from: []) == .free)
    }

    @Test func highestTierPrefersPremium() {
        let ids = ["com.sundeefundee.app.plus.monthly", "com.sundeefundee.app.premium.monthly"]
        #expect(SubscriptionManager.highestTier(from: ids) == .premium)
    }

    @Test func highestTierSinglePlus() {
        #expect(SubscriptionManager.highestTier(from: ["com.sundeefundee.app.plus.annual"]) == .plus)
    }
}

// MARK: - PaywallView Static Tests

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

    @Test func fallbackPrices() {
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .monthly) == "$4.99")
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .annual) == "$39.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .monthly) == "$9.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .annual) == "$79.99")
        #expect(PaywallView.fallbackPrice(tier: .free, period: .monthly) == "Free")
    }

    @Test func tierHighlightsNotEmpty() {
        #expect(PaywallView.tierHighlights(for: .plus).count > 0)
        #expect(PaywallView.tierHighlights(for: .premium).count > 0)
        #expect(PaywallView.tierHighlights(for: .free).isEmpty)
    }

    @Test func comparisonRowsNotEmpty() {
        let rows = PaywallView.comparisonRows()
        #expect(rows.count > 0)
        for row in rows {
            #expect(!row.feature.isEmpty)
            #expect(!row.free.isEmpty)
            #expect(!row.plus.isEmpty)
            #expect(!row.premium.isEmpty)
        }
    }

    @Test func savingsText() {
        let text = PaywallView.savingsText(monthlyPrice: 4.99, annualPrice: 39.99)
        #expect(text.contains("Save"))
    }

    @Test func savingsTextZeroMonthly() {
        let text = PaywallView.savingsText(monthlyPrice: 0, annualPrice: 0)
        #expect(text == "")
    }
}

// MARK: - PremiumBadge Static Tests

@Suite("PremiumBadge Statics")
@MainActor
struct PremiumBadgeStaticTests {

    @Test func badgeText() {
        #expect(PremiumBadge.badgeText(for: .free) == "")
        #expect(PremiumBadge.badgeText(for: .plus) == "PLUS")
        #expect(PremiumBadge.badgeText(for: .premium) == "PREMIUM")
    }

    @Test func badgeColorDiffers() {
        let free = PremiumBadge.badgeColor(for: .free)
        let plus = PremiumBadge.badgeColor(for: .plus)
        let premium = PremiumBadge.badgeColor(for: .premium)
        #expect(plus != premium)
        #expect(free != plus)
    }
}

// MARK: - FeatureGateModifier Static Tests

@Suite("FeatureGateModifier Statics")
@MainActor
struct FeatureGateModifierStaticTests {

    @Test func isLockedForFreeUser() {
        for feature in GatedFeature.allCases {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .free) == true)
        }
    }

    @Test func plusFeaturesUnlockedForPlus() {
        let plusFeatures: [GatedFeature] = [.customBenchmarks, .painTrends, .effortTrends, .wodExecution, .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory]
        for feature in plusFeatures {
            #expect(FeatureGateModifier.isLocked(feature: feature, tier: .plus) == false)
        }
    }

    @Test func premiumFeaturesLockedForPlus() {
        let premiumFeatures: [GatedFeature] = [.rehabSessions, .aiWorkoutHistory, .exportData]
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

// MARK: - ManageSubscriptionView Static Tests

@Suite("ManageSubscriptionView Statics")
@MainActor
struct ManageSubscriptionViewStaticTests {

    @Test func tierDescriptions() {
        #expect(ManageSubscriptionView.tierDescription(.free).contains("Basic"))
        #expect(ManageSubscriptionView.tierDescription(.plus).contains("Enhanced"))
        #expect(ManageSubscriptionView.tierDescription(.premium).contains("AI"))
    }

    @Test func usageTextWithLimit() {
        #expect(ManageSubscriptionView.usageText(used: 3, limit: 15) == "3 of 15 used")
    }

    @Test func usageTextUnlimited() {
        #expect(ManageSubscriptionView.usageText(used: 42, limit: nil) == "42 used (unlimited)")
    }
}

// MARK: - PaywallViewModel Static Tests

@Suite("PaywallViewModel Statics")
@MainActor
struct PaywallViewModelStaticTests {

    @Test func isGuestUser() {
        #expect(PaywallViewModel.isGuestUser(authState: .guest) == true)
        #expect(PaywallViewModel.isGuestUser(authState: .authenticated(userID: "123")) == false)
        #expect(PaywallViewModel.isGuestUser(authState: .signedOut) == false)
        #expect(PaywallViewModel.isGuestUser(authState: .loading) == false)
        #expect(PaywallViewModel.isGuestUser(authState: .needsOnboarding(userID: "1", appleUserID: "2")) == false)
    }
}

// MARK: - MaxLiftsView Subscription Tests

@Suite("MaxLiftsView Subscription")
@MainActor
struct MaxLiftsViewSubscriptionTests {

    @Test func canAddLiftFreeUnderLimit() {
        #expect(MaxLiftsView.canAddLift(tier: .free, currentCount: 0) == true)
        #expect(MaxLiftsView.canAddLift(tier: .free, currentCount: 4) == true)
    }

    @Test func canAddLiftFreeAtLimit() {
        #expect(MaxLiftsView.canAddLift(tier: .free, currentCount: 5) == false)
        #expect(MaxLiftsView.canAddLift(tier: .free, currentCount: 10) == false)
    }

    @Test func canAddLiftPlusAlways() {
        #expect(MaxLiftsView.canAddLift(tier: .plus, currentCount: 100) == true)
    }

    @Test func canAddLiftPremiumAlways() {
        #expect(MaxLiftsView.canAddLift(tier: .premium, currentCount: 100) == true)
    }
}

// MARK: - AIWorkoutCTACard Static Tests

@Suite("AIWorkoutCTACard Statics")
@MainActor
struct AIWorkoutCTACardStaticTests {

    @Test func remainingLabel() {
        #expect(AIWorkoutCTACard.remainingLabel(remaining: 2, limit: 3) == "2 of 3 left")
        #expect(AIWorkoutCTACard.remainingLabel(remaining: 0, limit: 15) == "0 of 15 left")
    }
}
