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
        #expect(SubscriptionTier.plus.monthlyProductID == "com.sundeefundee.sub.plus.monthly")
        #expect(SubscriptionTier.premium.monthlyProductID == "com.sundeefundee.sub.premium.monthly")
    }

    @Test func annualProductIDs() {
        #expect(SubscriptionTier.free.annualProductID == "")
        #expect(SubscriptionTier.plus.annualProductID == "com.sundeefundee.sub.plus.annual")
        #expect(SubscriptionTier.premium.annualProductID == "com.sundeefundee.sub.premium.annual")
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
        #expect(ids.contains("com.sundeefundee.sub.plus.monthly"))
        #expect(ids.contains("com.sundeefundee.sub.plus.annual"))
        #expect(ids.contains("com.sundeefundee.sub.premium.monthly"))
        #expect(ids.contains("com.sundeefundee.sub.premium.annual"))
    }

    @Test func fromProductIDMapsCorrectly() {
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.sub.plus.monthly") == .plus)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.sub.plus.annual") == .plus)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.sub.premium.monthly") == .premium)
        #expect(SubscriptionTier.fromProductID("com.sundeefundee.sub.premium.annual") == .premium)
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
        #expect(GatedFeature.allCases.count == 20)
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
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.sub.plus.monthly") == .plus)
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.sub.plus.annual") == .plus)
    }

    @Test func tierFromProductIDPremium() {
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.sub.premium.monthly") == .premium)
        #expect(SubscriptionManager.tierFromProductID("com.sundeefundee.sub.premium.annual") == .premium)
    }

    @Test func tierFromProductIDUnknown() {
        #expect(SubscriptionManager.tierFromProductID("unknown") == .free)
    }

    @Test func highestTierFromEmpty() {
        #expect(SubscriptionManager.highestTier(from: []) == .free)
    }

    @Test func highestTierPrefersPremium() {
        let ids = ["com.sundeefundee.sub.plus.monthly", "com.sundeefundee.sub.premium.monthly"]
        #expect(SubscriptionManager.highestTier(from: ids) == .premium)
    }

    @Test func highestTierSinglePlus() {
        #expect(SubscriptionManager.highestTier(from: ["com.sundeefundee.sub.plus.annual"]) == .plus)
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

    @Test func fallbackPricesUpdated() {
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .monthly) == "$4.99")
        #expect(PaywallView.fallbackPrice(tier: .plus, period: .annual) == "$39.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .monthly) == "$9.99")
        #expect(PaywallView.fallbackPrice(tier: .premium, period: .annual) == "$79.99")
        #expect(PaywallView.fallbackPrice(tier: .free, period: .monthly) == "Free")
    }

    @Test func tierHighlightsPlusUpdated() {
        let highlights = PaywallView.tierHighlights(for: .plus)
        #expect(highlights.count == 7)
        #expect(highlights.contains("Sundee AI cloud workouts (1/day)"))
        #expect(highlights.contains("Custom program builder"))
        #expect(highlights.contains("Periodization templates"))
    }

    @Test func tierHighlightsPremiumUpdated() {
        let highlights = PaywallView.tierHighlights(for: .premium)
        #expect(highlights.count == 7)
        #expect(highlights.contains("Everything in Plus"))
        #expect(highlights.contains("Sundee AI Pro cloud workouts (10/day)"))
        #expect(highlights.contains("AI mesocycle plans"))
    }

    @Test func tierHighlightsFreeEmpty() {
        #expect(PaywallView.tierHighlights(for: .free).isEmpty)
    }

    @Test func comparisonRowsUpdated() {
        let rows = PaywallView.comparisonRows()
        #expect(rows.count == 14)
        let aiRow = rows.first { $0.feature == "Cloud AI Workouts" }
        #expect(aiRow?.free == "--")
        #expect(aiRow?.plus == "1/day")
        #expect(aiRow?.premium == "10/day")
        let onDeviceRow = rows.first { $0.feature == "On-Device AI" }
        #expect(onDeviceRow?.free == "Unlimited")
        #expect(onDeviceRow?.plus == "Unlimited")
        #expect(onDeviceRow?.premium == "Unlimited")
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

// MARK: - ManageSubscriptionView Static Tests

@Suite("ManageSubscriptionView Statics")
@MainActor
struct ManageSubscriptionViewStaticTests {

    @Test func tierDescriptions() {
        #expect(ManageSubscriptionView.tierDescription(.free) == "Unlimited on-device AI workouts")
        #expect(ManageSubscriptionView.tierDescription(.plus) == "Sundee AI-powered cloud workouts and programming tools")
        #expect(ManageSubscriptionView.tierDescription(.premium) == "Sundee AI Pro personal coach")
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

// MARK: - AIWorkoutLimits Tests

@Suite("AIWorkoutLimits")
struct AIWorkoutLimitsTests {

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

    @Test func canGenerateOnDeviceAlwaysTrue() {
        for tier in SubscriptionTier.allCases {
            #expect(AIWorkoutLimits.canGenerateOnDevice(tier: tier) == true)
        }
    }
}

// MARK: - DowngradePolicy Tests

@Suite("DowngradePolicy")
struct DowngradePolicyTests {

    @Test func canViewExistingDataAlwaysTrue() {
        for feature in GatedFeature.allCases {
            for tier in SubscriptionTier.allCases {
                #expect(DowngradePolicy.canViewExistingData(feature: feature, currentTier: tier) == true)
            }
        }
    }

    @Test func canCreateNewRespectsEntitlements() {
        #expect(DowngradePolicy.canCreateNew(feature: .customBenchmarks, currentTier: .free) == false)
        #expect(DowngradePolicy.canCreateNew(feature: .customBenchmarks, currentTier: .plus) == true)
        #expect(DowngradePolicy.canCreateNew(feature: .rehabSessions, currentTier: .plus) == false)
        #expect(DowngradePolicy.canCreateNew(feature: .rehabSessions, currentTier: .premium) == true)
    }

    @Test func canDeleteOwnDataAlwaysTrue() {
        for tier in SubscriptionTier.allCases {
            #expect(DowngradePolicy.canDeleteOwnData(currentTier: tier) == true)
        }
    }
}

// MARK: - AnalyticsEvent Tests

@Suite("AnalyticsEvent")
struct AnalyticsEventTests {

    @Test func allEventsHaveStableRawValues() {
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
        #expect(AnalyticsEvent.cloudAIWorkoutGenerated.rawValue == "cloud_ai_workout_generated")
        #expect(AnalyticsEvent.cloudAIDailyLimitReached.rawValue == "cloud_ai_daily_limit_reached")
        #expect(AnalyticsEvent.cloudAISoftNudgeShown.rawValue == "cloud_ai_soft_nudge_shown")
        #expect(AnalyticsEvent.workoutEditedBeforeStart.rawValue == "workout_edited_before_start")
    }

    @Test func eventNameReturnsRawValue() {
        #expect(AnalyticsEvent.eventName(for: .paywallImpression) == "paywall_impression")
        #expect(AnalyticsEvent.eventName(for: .subscriptionChanged) == "subscription_changed")
        #expect(AnalyticsEvent.eventName(for: .cloudAIWorkoutGenerated) == "cloud_ai_workout_generated")
    }

    @Test func allCasesCountIsStable() {
        #expect(AnalyticsEvent.allCases.count == 16)
    }
}

// MARK: - AnalyticsService Tests

@Suite("AnalyticsService")
struct AnalyticsServiceTests {

    @Test func formatPropertiesEmpty() {
        #expect(AnalyticsService.formatProperties([:]) == "")
    }

    @Test func formatPropertiesWithEntries() {
        let result = AnalyticsService.formatProperties(["tier": "plus", "feature": "lifts"])
        #expect(result.contains("tier=plus"))
        #expect(result.contains("feature=lifts"))
    }

    @Test @MainActor func sharedInstanceExists() {
        let service = AnalyticsService.shared
        // Just verify it can track without crashing
        service.track(.paywallImpression)
        service.track(.purchaseStarted, properties: ["tier": "plus"])
    }
}

// MARK: - InjuryProfilesView Limit Tests

@Suite("InjuryProfilesView Limits")
struct InjuryProfilesViewLimitTests {

    @Test func canAddInjuryFreeUnderLimit() {
        #expect(InjuryProfilesView.canAddInjury(tier: .free, currentCount: 0) == true)
    }

    @Test func canAddInjuryFreeAtLimit() {
        #expect(InjuryProfilesView.canAddInjury(tier: .free, currentCount: 1) == false)
        #expect(InjuryProfilesView.canAddInjury(tier: .free, currentCount: 5) == false)
    }

    @Test func canAddInjuryPlusAlways() {
        #expect(InjuryProfilesView.canAddInjury(tier: .plus, currentCount: 100) == true)
    }

    @Test func canAddInjuryPremiumAlways() {
        #expect(InjuryProfilesView.canAddInjury(tier: .premium, currentCount: 100) == true)
    }
}

// MARK: - DashboardView Helpers Tests

@Suite("DashboardView Helpers")
struct DashboardViewHelperTests {

    @Test func historyLimitMessageForFree() {
        #expect(DashboardView.historyLimitMessage(tier: .free) == "Showing last 30 days")
    }

    @Test func historyLimitMessageNilForPlus() {
        #expect(DashboardView.historyLimitMessage(tier: .plus) == nil)
    }

    @Test func historyLimitMessageNilForPremium() {
        #expect(DashboardView.historyLimitMessage(tier: .premium) == nil)
    }
}

// MARK: - PaywallView Context Tests

@Suite("PaywallView Context")
struct PaywallViewContextTests {

    @Test func contextSubtitleReturnsMessage() {
        #expect(PaywallView.contextSubtitle(message: "You've tracked 5 lifts") == "You've tracked 5 lifts")
    }

    @Test func contextSubtitleNilForNil() {
        #expect(PaywallView.contextSubtitle(message: nil) == nil)
    }

    @Test func contextSubtitleNilForEmpty() {
        #expect(PaywallView.contextSubtitle(message: "") == nil)
    }
}

// MARK: - AIWorkoutCTACard Tests

@Suite("AIWorkoutCTACard")
struct AIWorkoutCTACardTests {

    @Test func shouldShowPaywallAtLimit() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .free, generatedToday: 1) == true)
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .plus, generatedToday: 1) == true)
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .plus, generatedToday: 0) == false)
    }

    @Test func shouldShowPaywallPremiumNever() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .premium, generatedToday: 9) == false)
    }
}

// MARK: - SubscriptionTier Updated Copy Tests

@Suite("SubscriptionTier Copy")
struct SubscriptionTierCopyTests {

    @Test func subscriptionDescriptionCopy() {
        #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
        #expect(SubscriptionTier.plus.subscriptionDescription == "Sundee AI-powered cloud workouts and custom programming tools.")
        #expect(SubscriptionTier.premium.subscriptionDescription == "Sundee AI Pro coach with persistent memory.")
    }
}

// MARK: - SubscriptionTier New Properties Tests

@Suite("SubscriptionTierTests")
struct SubscriptionTierNewPropertiesTests {

    @Test func valuePropositions() {
        #expect(SubscriptionTier.free.valueProposition == "Unlimited on-device AI workouts")
        #expect(SubscriptionTier.plus.valueProposition == "Cloud-powered AI workouts and programming tools")
        #expect(SubscriptionTier.premium.valueProposition == "Personal AI coach that learns and adapts")
    }

    @Test func subscriptionDescriptions() {
        #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
        #expect(SubscriptionTier.plus.subscriptionDescription == "Sundee AI-powered cloud workouts and custom programming tools.")
        #expect(SubscriptionTier.premium.subscriptionDescription == "Sundee AI Pro coach with persistent memory.")
    }

    @Test func aiModelIdentifier() {
        #expect(SubscriptionTier.free.aiModelIdentifier == "on-device")
        #expect(SubscriptionTier.plus.aiModelIdentifier == "@cf/qwen/qwen3-30b-a3b-fp8")
        #expect(SubscriptionTier.premium.aiModelIdentifier == "@cf/nvidia/nemotron-3-120b-a12b")
    }

    @Test func dailyCloudAILimit() {
        #expect(SubscriptionTier.free.dailyCloudAILimit == nil)
        #expect(SubscriptionTier.plus.dailyCloudAILimit == 1)
        #expect(SubscriptionTier.premium.dailyCloudAILimit == 10)
    }
}

// MARK: - DashboardViewModel Filter Tests

@Suite("DashboardViewModel Filtering")
struct DashboardViewModelFilterTests {

    @Test @MainActor func filterWorkoutsByTierFreeFiltersOld() {
        let now = Date()
        let recent = CompletedWorkout(id: "1", userID: "u", activeCycleID: "", programID: "", enrollmentID: "", week: 1, day: 1, sessionID: "", completedAt: now, durationSeconds: 60)
        let old = CompletedWorkout(id: "2", userID: "u", activeCycleID: "", programID: "", enrollmentID: "", week: 1, day: 1, sessionID: "", completedAt: now.addingTimeInterval(-86_400 * 60), durationSeconds: 60)
        let result = DashboardViewModel.filterWorkoutsByTier([recent, old], tier: .free, now: now)
        #expect(result.count == 1)
        #expect(result.first?.id == "1")
    }

    @Test @MainActor func filterWorkoutsByTierPlusKeepsAll() {
        let now = Date()
        let old = CompletedWorkout(id: "1", userID: "u", activeCycleID: "", programID: "", enrollmentID: "", week: 1, day: 1, sessionID: "", completedAt: now.addingTimeInterval(-86_400 * 60), durationSeconds: 60)
        let result = DashboardViewModel.filterWorkoutsByTier([old], tier: .plus, now: now)
        #expect(result.count == 1)
    }
}

// MARK: - CloudAIConfig Tests

@Suite("CloudAIConfig")
struct CloudAIConfigTests {

    @Test func workerURLIsValid() {
        let url = URL(string: CloudAIConfig.workerURL)
        #expect(url != nil)
        #expect(url?.host?.contains("sundeefundee") == true)
    }

    @Test func createJwtProducesThreeParts() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "user-123", tier: .plus)
        let parts = token.split(separator: ".")
        #expect(parts.count == 3)
    }

    @Test func createJwtPayloadContainsCorrectFields() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "user-456", tier: .premium)
        let parts = token.split(separator: ".")
        let payloadData = CloudAIConfig.base64UrlDecode(String(parts[1]))
        let payload = try JSONDecoder().decode(CloudAIConfig.JwtPayload.self, from: payloadData!)
        #expect(payload.sub == "user-456")
        #expect(payload.tier == "premium")
        #expect(payload.iat > 0)
    }

    @Test func createJwtUsesCorrectTierString() async throws {
        let plusToken = try await CloudAIConfig.createJwt(userID: "u1", tier: .plus)
        let premiumToken = try await CloudAIConfig.createJwt(userID: "u2", tier: .premium)
        let plusPayload = try CloudAIConfig.decodePayload(plusToken)
        let premiumPayload = try CloudAIConfig.decodePayload(premiumToken)
        #expect(plusPayload.tier == "plus")
        #expect(premiumPayload.tier == "premium")
    }

    @Test func createJwtIatIsRecent() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "u1", tier: .plus)
        let payload = try CloudAIConfig.decodePayload(token)
        let now = Int(Date().timeIntervalSince1970)
        #expect(abs(now - payload.iat) < 5)
    }
}

// MARK: - CloudAIUsageTracker Tests

@Suite("CloudAIUsageTracker")
struct CloudAIUsageTrackerTests {

    @Test func initialCountIsZero() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.generatedToday == 0)
    }

    @Test func incrementIncreasesCount() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        tracker.recordGeneration()
        #expect(tracker.generatedToday == 1)
        tracker.recordGeneration()
        #expect(tracker.generatedToday == 2)
    }

    @Test func resetsOnNewDay() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let tracker = CloudAIUsageTracker(defaults: defaults)
        // Simulate yesterday's data
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let yesterdayKey = formatter.string(from: yesterday)
        defaults.set(5, forKey: "cloudAIUsage:\(yesterdayKey)")
        // Today should be 0
        #expect(tracker.generatedToday == 0)
    }

    @Test func remainingForPlusUser() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.remaining(for: .plus) == 1)
        tracker.recordGeneration()
        #expect(tracker.remaining(for: .plus) == 0)
    }

    @Test func remainingForPremiumUser() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.remaining(for: .premium) == 10)
        tracker.recordGeneration()
        #expect(tracker.remaining(for: .premium) == 9)
    }

    @Test func canGenerateRespectsLimit() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.canGenerate(for: .plus) == true)
        tracker.recordGeneration()
        #expect(tracker.canGenerate(for: .plus) == false)
        #expect(tracker.canGenerate(for: .premium) == true)
    }

    @Test func canGenerateAlwaysFalseForFree() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.canGenerate(for: .free) == false)
    }

    @Test func toggleLabelForTiers() {
        #expect(CloudAIUsageTracker.toggleLabel(for: .plus) == "Use Sundee AI")
        #expect(CloudAIUsageTracker.toggleLabel(for: .premium) == "Use Sundee AI Pro")
        #expect(CloudAIUsageTracker.toggleLabel(for: .free) == "")
    }

    @Test func subtitleTextShowsRemaining() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.subtitleText(for: .plus) == "1 of 1 remaining today")
        tracker.recordGeneration()
        #expect(tracker.subtitleText(for: .plus) == "Come back tomorrow")
    }

    @Test func subtitleTextPremium() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.subtitleText(for: .premium) == "10 of 10 remaining today")
    }

    @Test func setGeneratedTodayUpdatesCount() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        tracker.setGeneratedToday(5)
        #expect(tracker.generatedToday == 5)
        #expect(tracker.remaining(for: .premium) == 5)
    }
}

// MARK: - CustomProgramRecord Tests

@Suite("CustomProgramRecord")
struct CustomProgramRecordTests {

    @Test func roundTripProgramJSON() {
        let program = Program(
            id: "test-1", name: "Test Program", category: "custom",
            description: "A test", durationWeeks: 4, sessionsPerWeek: 3,
            difficulty: "intermediate", phases: [], weeks: [],
            cycleAdjustmentProfile: nil
        )
        let record = CustomProgramRecord.from(program, userID: "user-1")
        #expect(record != nil)
        #expect(record?.name == "Test Program")
        let decoded = record?.toProgram()
        #expect(decoded?.id == "test-1")
        #expect(decoded?.name == "Test Program")
        #expect(decoded?.category == "custom")
        #expect(decoded?.durationWeeks == 4)
    }

    @Test func fromNilForInvalidProgram() {
        let record = CustomProgramRecord(userID: "u1", name: "Bad", programJSON: "not json")
        #expect(record.toProgram() == nil)
    }
}

// MARK: - ProgramTemplateGenerator Tests

@Suite("ProgramTemplateGenerator")
struct ProgramTemplateGeneratorTests {

    @Test func strengthTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "My Strength", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.name == "My Strength")
        #expect(program.category == "custom")
        #expect(program.durationWeeks == 4)
        #expect(program.sessionsPerWeek == 3)
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
            for session in week.sessions {
                #expect(!session.exercises.isEmpty)
            }
        }
    }

    @Test func hypertrophyTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .hypertrophy, name: "Hyper", durationWeeks: 6, sessionsPerWeek: 4
        )
        #expect(program.durationWeeks == 6)
        #expect(program.sessionsPerWeek == 4)
        #expect(program.weeks.count == 6)
        for week in program.weeks {
            #expect(week.sessions.count == 4)
        }
    }

    @Test func fullBodyTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .fullBody, name: "FB", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
        }
    }

    @Test func progressiveOverloadIncreasesPercent1RM() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
        )
        let week1FirstExercise = program.weeks[0].sessions[0].exercises[0]
        let week4FirstExercise = program.weeks[3].sessions[0].exercises[0]
        let w1Pct = week1FirstExercise.percent1RM ?? 0
        let w4Pct = week4FirstExercise.percent1RM ?? 0
        #expect(w4Pct > w1Pct, "Week 4 should have higher %1RM than week 1")
    }

    @Test func customDurationAndFrequency() {
        let program = ProgramTemplateGenerator.generate(
            template: .strength, name: "Custom", durationWeeks: 8, sessionsPerWeek: 5
        )
        #expect(program.weeks.count == 8)
        for week in program.weeks {
            #expect(week.sessions.count == 5)
        }
    }

    @Test func allTemplatesProduceValidIDs() {
        for template in ProgramTemplate.allCases {
            let program = ProgramTemplateGenerator.generate(
                template: template, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
            )
            #expect(!program.id.isEmpty)
        }
    }

    @Test func templateDisplayInfo() {
        #expect(ProgramTemplate.strength.displayName == "Strength")
        #expect(ProgramTemplate.hypertrophy.displayName == "Hypertrophy")
        #expect(ProgramTemplate.fullBody.displayName == "Full Body")
        #expect(!ProgramTemplate.strength.icon.isEmpty)
        #expect(!ProgramTemplate.strength.subtitle.isEmpty)
        #expect(!ProgramTemplate.strength.descriptionText.isEmpty)
    }
}

// MARK: - Periodization Template Tests

@Suite("Periodization Templates")
struct PeriodizationTemplateTests {

    @Test func linearTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Linear Block", durationWeeks: 6, sessionsPerWeek: 3
        )
        #expect(program.name == "Linear Block")
        #expect(program.category == "custom")
        #expect(program.weeks.count == 6)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
            for session in week.sessions {
                #expect(!session.exercises.isEmpty)
            }
        }
    }

    @Test func linearProgressionDecreasesReps() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Test", durationWeeks: 6, sessionsPerWeek: 3
        )
        let week1Ex = program.weeks[0].sessions[0].exercises[0]
        let week6Ex = program.weeks[5].sessions[0].exercises[0]
        let w1Reps = PeriodizationTemplateTests.extractReps(week1Ex.reps)
        let w6Reps = PeriodizationTemplateTests.extractReps(week6Ex.reps)
        #expect(w1Reps > w6Reps, "Linear: reps should decrease over weeks")
    }

    @Test func linearProgressionIncreasesIntensity() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Test", durationWeeks: 6, sessionsPerWeek: 3
        )
        let week1Ex = program.weeks[0].sessions[0].exercises[0]
        let week6Ex = program.weeks[5].sessions[0].exercises[0]
        #expect((week6Ex.percent1RM ?? 0) > (week1Ex.percent1RM ?? 0), "Linear: %1RM should increase over weeks")
    }

    @Test func dupTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .dup, name: "DUP Block", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
        }
    }

    @Test func dupVariesRepSchemeWithinWeek() {
        let program = ProgramTemplateGenerator.generate(
            template: .dup, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
        )
        let week1 = program.weeks[0]
        let day1Reps = PeriodizationTemplateTests.extractReps(week1.sessions[0].exercises[0].reps)
        let day2Reps = PeriodizationTemplateTests.extractReps(week1.sessions[1].exercises[0].reps)
        let day3Reps = PeriodizationTemplateTests.extractReps(week1.sessions[2].exercises[0].reps)
        // DUP: Heavy (low reps), Moderate (mid reps), Volume (high reps)
        #expect(day1Reps < day2Reps, "DUP: Day 1 (heavy) should have fewer reps than Day 2 (moderate)")
        #expect(day2Reps < day3Reps, "DUP: Day 2 (moderate) should have fewer reps than Day 3 (volume)")
    }

    @Test func blockTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Block Periodization", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 9)
        #expect(program.phases.count == 3)
    }

    @Test func blockPhaseNames() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.phases[0].name == "Accumulation")
        #expect(program.phases[1].name == "Intensification")
        #expect(program.phases[2].name == "Peaking")
    }

    @Test func blockPhaseWeekRanges() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.phases[0].weekRange == [1, 3])
        #expect(program.phases[1].weekRange == [4, 6])
        #expect(program.phases[2].weekRange == [7, 9])
    }

    @Test func blockAccumulationHasHighReps() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        let accumEx = program.weeks[0].sessions[0].exercises[0]
        let peakEx = program.weeks[8].sessions[0].exercises[0]
        let accumReps = PeriodizationTemplateTests.extractReps(accumEx.reps)
        let peakReps = PeriodizationTemplateTests.extractReps(peakEx.reps)
        #expect(accumReps > peakReps, "Block: Accumulation reps > Peaking reps")
    }

    @Test func blockPeakingHasHighIntensity() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        let accumEx = program.weeks[0].sessions[0].exercises[0]
        let peakEx = program.weeks[8].sessions[0].exercises[0]
        #expect((peakEx.percent1RM ?? 0) > (accumEx.percent1RM ?? 0), "Block: Peaking %1RM > Accumulation %1RM")
    }

    @Test func newTemplateDisplayInfo() {
        #expect(ProgramTemplate.linear.displayName == "Linear")
        #expect(ProgramTemplate.dup.displayName == "Daily Undulating")
        #expect(ProgramTemplate.block.displayName == "Block")
        #expect(!ProgramTemplate.linear.icon.isEmpty)
        #expect(!ProgramTemplate.dup.icon.isEmpty)
        #expect(!ProgramTemplate.block.icon.isEmpty)
    }

    @Test func allSixTemplatesExist() {
        #expect(ProgramTemplate.allCases.count == 6)
    }

    @Test func periodizationTemplatesAreTagged() {
        #expect(ProgramTemplate.linear.isPeriodization == true)
        #expect(ProgramTemplate.dup.isPeriodization == true)
        #expect(ProgramTemplate.block.isPeriodization == true)
        #expect(ProgramTemplate.strength.isPeriodization == false)
        #expect(ProgramTemplate.hypertrophy.isPeriodization == false)
        #expect(ProgramTemplate.fullBody.isPeriodization == false)
    }

    // Helper
    static func extractReps(_ value: ExerciseValue) -> Int {
        switch value {
        case .fixed(let n): return n
        case .range(let lo, _): return lo
        case .amrap: return 0
        case .text: return 0
        }
    }
}

