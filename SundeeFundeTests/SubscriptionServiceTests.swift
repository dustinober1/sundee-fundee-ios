import Foundation
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
