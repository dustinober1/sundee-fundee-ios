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

    @Test func monthlyLimitForAllTiers() {
        #expect(AIWorkoutLimits.monthlyLimit(for: .free) == 3)
        #expect(AIWorkoutLimits.monthlyLimit(for: .plus) == 15)
        #expect(AIWorkoutLimits.monthlyLimit(for: .premium) == nil)
    }

    @Test func canGenerateUnderLimit() {
        #expect(AIWorkoutLimits.canGenerate(tier: .free, generatedThisMonth: 0) == true)
        #expect(AIWorkoutLimits.canGenerate(tier: .free, generatedThisMonth: 2) == true)
    }

    @Test func canGenerateAtLimit() {
        #expect(AIWorkoutLimits.canGenerate(tier: .free, generatedThisMonth: 3) == false)
        #expect(AIWorkoutLimits.canGenerate(tier: .plus, generatedThisMonth: 15) == false)
    }

    @Test func canGenerateUnlimited() {
        #expect(AIWorkoutLimits.canGenerate(tier: .premium, generatedThisMonth: 1000) == true)
    }

    @Test func remainingGenerationsForFree() {
        #expect(AIWorkoutLimits.remainingGenerations(tier: .free, generatedThisMonth: 0) == 3)
        #expect(AIWorkoutLimits.remainingGenerations(tier: .free, generatedThisMonth: 2) == 1)
        #expect(AIWorkoutLimits.remainingGenerations(tier: .free, generatedThisMonth: 5) == 0)
    }

    @Test func remainingGenerationsForPlus() {
        #expect(AIWorkoutLimits.remainingGenerations(tier: .plus, generatedThisMonth: 10) == 5)
    }

    @Test func remainingGenerationsUnlimited() {
        #expect(AIWorkoutLimits.remainingGenerations(tier: .premium, generatedThisMonth: 100) == nil)
    }

    @Test func remainingTextForFree() {
        let text = AIWorkoutLimits.remainingText(tier: .free, generatedThisMonth: 1)
        #expect(text == "2 of 3 AI workouts left this month")
    }

    @Test func remainingTextNilForPremium() {
        #expect(AIWorkoutLimits.remainingText(tier: .premium, generatedThisMonth: 100) == nil)
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
    }

    @Test func eventNameReturnsRawValue() {
        #expect(AnalyticsEvent.eventName(for: .paywallImpression) == "paywall_impression")
        #expect(AnalyticsEvent.eventName(for: .subscriptionChanged) == "subscription_changed")
    }

    @Test func allCasesCountIsStable() {
        #expect(AnalyticsEvent.allCases.count == 12)
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
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .free, generatedThisMonth: 3) == true)
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .free, generatedThisMonth: 2) == false)
    }

    @Test func shouldShowPaywallPremiumNever() {
        #expect(AIWorkoutCTACard.shouldShowPaywall(tier: .premium, generatedThisMonth: 1000) == false)
    }
}

// MARK: - SubscriptionTier Updated Copy Tests

@Suite("SubscriptionTier Copy")
struct SubscriptionTierCopyTests {

    @Test func subscriptionDescriptionCopy() {
        #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
        #expect(SubscriptionTier.plus.subscriptionDescription == "Haiku-powered cloud AI and custom programming tools.")
        #expect(SubscriptionTier.premium.subscriptionDescription == "Sonnet-powered AI coach with persistent memory.")
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

