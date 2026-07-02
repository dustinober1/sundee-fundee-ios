#if os(iOS) && canImport(StoreKitTest)
@testable import SundeeFundeeKit
import StoreKitTest
import XCTest

@available(iOS 18.0, *)
final class StoreKitSupportTipStoreIntegrationTests: XCTestCase {
    private var session: SKTestSession?

    override func tearDown() {
        session?.clearTransactions()
        session = nil
        super.tearDown()
    }

    func testRealStoreKitConfigurationLoadsAndPurchasesSupportTip() async throws {
        let session = try SKTestSession(contentsOf: storeKitConfigurationURL())
        session.disableDialogs = true
        session.clearTransactions()
        self.session = session

        let store = StoreKitSupportTipStore()

        let offer = try await store.loadSupportTip()
        XCTAssertEqual(offer.id, SupportTipProduct.id)
        XCTAssertEqual(offer.displayPrice, "$1.99")

        let outcome = await store.purchaseSupportTip()
        XCTAssertEqual(outcome, .purchased)
    }

    private func storeKitConfigurationURL() -> URL {
        let testFileURL = URL(fileURLWithPath: #filePath)
        return testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("SundeeFundeeApp/StoreKit/SundeeFundee.storekit")
    }
}
#endif
