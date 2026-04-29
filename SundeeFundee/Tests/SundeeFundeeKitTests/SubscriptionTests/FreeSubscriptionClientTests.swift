import Testing
import Foundation
@testable import SundeeFundeeKit

@Suite("FreeSubscriptionClient")
struct FreeSubscriptionClientTests {

    private func makeClient() -> FreeSubscriptionClient {
        FreeSubscriptionClient()
    }

    // MARK: - currentSubscription

    @Test("currentSubscription returns non-nil premium active subscription")
    func testCurrentSubscription() async {
        let client = makeClient()
        let sub = client.currentSubscription

        #expect(sub != nil)
        #expect(sub?.tier == .premium)
        #expect(sub?.status == .active)
    }

    // MARK: - getSubscriptionInfo

    @Test("getSubscriptionInfo returns premium active subscription")
    func testGetSubscriptionInfo() async throws {
        let client = makeClient()
        let sub = try await client.getSubscriptionInfo()

        #expect(sub.tier == .premium)
        #expect(sub.status == .active)
    }

    // MARK: - purchase

    @Test("purchase with free tier returns premium info")
    func testPurchaseFreeTierReturnsPremium() async throws {
        let client = makeClient()
        let sub = try await client.purchase(tier: .free)

        #expect(sub.tier == .premium)
        #expect(sub.status == .active)
    }

    @Test("purchase with plus tier returns premium info")
    func testPurchasePlusTierReturnsPremium() async throws {
        let client = makeClient()
        let sub = try await client.purchase(tier: .plus)

        #expect(sub.tier == .premium)
        #expect(sub.status == .active)
    }

    // MARK: - restorePurchases

    @Test("restorePurchases returns premium info")
    func testRestorePurchases() async throws {
        let client = makeClient()
        let sub = try await client.restorePurchases()

        #expect(sub.tier == .premium)
        #expect(sub.status == .active)
    }

    // MARK: - presentManageSubscriptions

    @Test("presentManageSubscriptions completes without throwing")
    func testPresentManageSubscriptions() async throws {
        let client = makeClient()
        // Should not throw — no-op for free app
        try await client.presentManageSubscriptions()
    }

    // MARK: - isTierAvailable

    @Test("isTierAvailable returns true for premium")
    func testIsTierAvailablePremium() async {
        let client = makeClient()
        let available = await client.isTierAvailable(.premium)

        #expect(available == true)
    }

    @Test("isTierAvailable returns true for all tiers")
    func testIsTierAvailableAllTiers() async {
        let client = makeClient()

        for tier in SubscriptionTier.allCases {
            let available = await client.isTierAvailable(tier)
            #expect(available == true, "isTierAvailable(\(tier)) should be true")
        }
    }

    // MARK: - getPrice

    @Test("getPrice returns nil for premium tier")
    func testGetPriceReturnsNil() async {
        let client = makeClient()
        let price = await client.getPrice(for: .premium)

        #expect(price == nil)
    }
}
