import Foundation
import SwiftData
import Testing
@testable import SundeeFundee

@Suite("SubscriptionTier")
struct SubscriptionTierTests {

    @Test func dailyLimits() {
        #expect(SubscriptionTier.free.dailyAILimit == 0)
        #expect(SubscriptionTier.plus.dailyAILimit == 1)
        #expect(SubscriptionTier.pro.dailyAILimit == 3)
    }

    @Test func displayNames() {
        #expect(SubscriptionTier.free.displayName == "Free")
        #expect(SubscriptionTier.plus.displayName == "Plus")
        #expect(SubscriptionTier.pro.displayName == "Pro")
    }

    @Test func productIDs() {
        #expect(SubscriptionTier.plus.productID == "com.sundeefundee.plus.monthly")
        #expect(SubscriptionTier.pro.productID == "com.sundeefundee.pro.monthly")
        #expect(SubscriptionTier.free.productID == nil)
    }

    @Test func tierFromProductID() {
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.plus.monthly") == .plus)
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.pro.monthly") == .pro)
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.unknown") == .free)
    }

    @Test func highestTierResolution() {
        #expect(SubscriptionTier.highest([]) == .free)
        #expect(SubscriptionTier.highest([.free]) == .free)
        #expect(SubscriptionTier.highest([.plus]) == .plus)
        #expect(SubscriptionTier.highest([.plus, .pro]) == .pro)
        #expect(SubscriptionTier.highest([.free, .plus]) == .plus)
    }

    @Test func comparable() {
        #expect(SubscriptionTier.free < .plus)
        #expect(SubscriptionTier.plus < .pro)
        #expect(!(SubscriptionTier.pro < .plus))
    }

    @Test func allProductIDs() {
        #expect(SubscriptionTier.allProductIDs.count == 2)
        #expect(SubscriptionTier.allProductIDs.contains("com.sundeefundee.plus.monthly"))
        #expect(SubscriptionTier.allProductIDs.contains("com.sundeefundee.pro.monthly"))
    }
}

@Suite("SubscriptionService", .serialized)
struct SubscriptionServiceTests {

    private static func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "com.sundeefundee.subscription.tier")
    }

    @Test @MainActor func defaultsToFree() {
        Self.resetUserDefaults()
        let service = SubscriptionService()
        #expect(service.currentTier == .free)
        #expect(service.isPremium == false)
    }

    @Test @MainActor func isPremiumTrueForPlus() {
        Self.resetUserDefaults()
        let service = SubscriptionService()
        service.setTierForTesting(.plus)
        #expect(service.isPremium == true)
        #expect(service.currentTier == .plus)
        Self.resetUserDefaults()
    }

    @Test @MainActor func isPremiumTrueForPro() {
        Self.resetUserDefaults()
        let service = SubscriptionService()
        service.setTierForTesting(.pro)
        #expect(service.isPremium == true)
        #expect(service.currentTier == .pro)
        Self.resetUserDefaults()
    }

    @Test @MainActor func restoresTierFromUserDefaults() {
        Self.resetUserDefaults()
        UserDefaults.standard.set("pro", forKey: "com.sundeefundee.subscription.tier")
        let service = SubscriptionService()
        #expect(service.currentTier == .pro)
        Self.resetUserDefaults()
    }
}

@Suite("PaywallView Statics")
struct PaywallViewStaticTests {

    @Test func headlineForNeedsSubscription() {
        let headline = PaywallView.headline(for: .needsSubscription)
        #expect(headline == "Unlock AI-Powered Workouts")
    }

    @Test func headlineForDailyLimit() {
        let headline = PaywallView.headline(for: .dailyLimitReached(upgradeAvailable: true))
        #expect(headline == "Need More Workouts?")
    }

    @Test func subtitleForNeedsSubscription() {
        let subtitle = PaywallView.subtitle(for: .needsSubscription)
        #expect(subtitle.contains("personalized"))
    }

    @Test func subtitleForDailyLimit() {
        let subtitle = PaywallView.subtitle(for: .dailyLimitReached(upgradeAvailable: true))
        #expect(subtitle.contains("Pro"))
    }

    @Test func tierNameFromProductID() {
        #expect(PaywallView.tierName(for: "com.sundeefundee.plus.monthly") == "Plus")
        #expect(PaywallView.tierName(for: "com.sundeefundee.pro.monthly") == "Pro")
    }
}

@Suite("QuestionnaireViewModel Gating")
struct QuestionnaireViewModelGatingTests {

    @Test @MainActor func canGenerateAIReturnsFalseForFree() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .free, todayCount: 0)
        #expect(result == .blocked(.needsSubscription))
    }

    @Test @MainActor func canGenerateAIReturnsTrueForPlusUnderLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .plus, todayCount: 0)
        #expect(result == .allowed)
    }

    @Test @MainActor func canGenerateAIReturnsFalseForPlusAtLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .plus, todayCount: 1)
        #expect(result == .blocked(.dailyLimitReached(upgradeAvailable: true)))
    }

    @Test @MainActor func canGenerateAIReturnsTrueForProUnderLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .pro, todayCount: 2)
        #expect(result == .allowed)
    }

    @Test @MainActor func canGenerateAIReturnsFalseForProAtLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .pro, todayCount: 3)
        #expect(result == .blocked(.dailyLimitReached(upgradeAvailable: false)))
    }
}

@Suite("QuestionnaireViewModel Generate with Gating")
struct QuestionnaireViewModelGenerateGatingTests {

    @Test @MainActor func freeUserShowsPaywall() {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .free, todayCount: 0)
        #expect(vm.showPaywall == true)
        #expect(vm.generationBlockReason == .needsSubscription)
        #expect(vm.generatedWorkout == nil)
    }

    @Test @MainActor func plusUserAtLimitShowsPaywall() {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .plus, todayCount: 1)
        #expect(vm.showPaywall == true)
        #expect(vm.generationBlockReason == .dailyLimitReached(upgradeAvailable: true))
    }

    @Test @MainActor func proUserAtLimitShowsLimitMessage() {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .pro, todayCount: 3)
        #expect(vm.showPaywall == false)
        #expect(vm.generationBlockReason == .dailyLimitReached(upgradeAvailable: false))
        #expect(vm.errorMessage == "You've reached today's limit. Come back tomorrow!")
    }
}

@Suite("SubscriptionManagementView Statics")
struct SubscriptionManagementViewStaticTests {

    @Test func dailyLimitTextForFree() {
        #expect(SubscriptionManagementView.dailyLimitText(for: .free) == "None")
    }

    @Test func dailyLimitTextForPlus() {
        #expect(SubscriptionManagementView.dailyLimitText(for: .plus) == "1 per day")
    }

    @Test func dailyLimitTextForPro() {
        #expect(SubscriptionManagementView.dailyLimitText(for: .pro) == "3 per day")
    }

    @Test func tierNameFromProductID() {
        #expect(SubscriptionManagementView.tierName(for: "com.sundeefundee.plus.monthly") == "Plus")
        #expect(SubscriptionManagementView.tierName(for: "com.sundeefundee.pro.monthly") == "Pro")
    }
}

@Suite("AIWorkoutCTACard Statics")
struct AIWorkoutCTACardStaticTests {

    @Test func ctaTextForFree() {
        #expect(AIWorkoutCTACard.ctaText(for: .free) == "Upgrade to Unlock")
    }

    @Test func ctaTextForPlus() {
        #expect(AIWorkoutCTACard.ctaText(for: .plus) == "New AI Workout")
    }

    @Test func ctaTextForPro() {
        #expect(AIWorkoutCTACard.ctaText(for: .pro) == "New AI Workout")
    }

    @Test func subtitleForFree() {
        let subtitle = AIWorkoutCTACard.subtitleText(for: .free)
        #expect(subtitle.contains("Upgrade"))
    }

    @Test func subtitleForPaid() {
        let subtitle = AIWorkoutCTACard.subtitleText(for: .plus)
        #expect(subtitle.contains("personalized"))
    }
}
