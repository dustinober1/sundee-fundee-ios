import XCTest
@testable import SundeeFundeeKit

@MainActor
final class SupportTipViewModelTests: XCTestCase {
    func testLoadOfferPublishesPriceAndReadyState() async {
        let store = MockSupportTipStore(
            offer: SupportTipOffer(
                id: SupportTipProduct.id,
                displayName: "Support the Developer",
                description: SupportTipProduct.description,
                displayPrice: "$1.99"
            ),
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()

        XCTAssertEqual(viewModel.offer?.displayPrice, "$1.99")
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertNil(viewModel.message)
    }

    func testSuccessfulPurchaseShowsThankYouAndAllowsRepeat() async {
        let store = MockSupportTipStore(
            offer: SupportTipOffer(
                id: SupportTipProduct.id,
                displayName: "Support the Developer",
                description: SupportTipProduct.description,
                displayPrice: "$1.99"
            ),
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()
        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 2)
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "Thank you for supporting Sundee Fundee.")
    }

    func testPendingPurchaseUsesClearCopy() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .pending
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "The purchase is pending App Store approval.")
    }

    func testCancelledPurchaseDoesNotShowError() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .cancelled
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertNil(viewModel.message)
    }

    func testUnavailableOfferShowsUserFacingError() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .unavailable,
            loadError: SupportTipStoreError.productUnavailable
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()

        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertEqual(viewModel.message, "Support tips are unavailable right now. Please try again later.")
    }
}

private final class MockSupportTipStore: SupportTipStoreProtocol, @unchecked Sendable {
    private let offer: SupportTipOffer?
    private let purchaseOutcome: SupportTipPurchaseOutcome
    private let loadError: Error?
    private(set) var purchaseCount = 0

    init(
        offer: SupportTipOffer?,
        purchaseOutcome: SupportTipPurchaseOutcome,
        loadError: Error? = nil
    ) {
        self.offer = offer
        self.purchaseOutcome = purchaseOutcome
        self.loadError = loadError
    }

    func loadSupportTip() async throws -> SupportTipOffer {
        if let loadError {
            throw loadError
        }
        guard let offer else {
            throw SupportTipStoreError.productUnavailable
        }
        return offer
    }

    func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        purchaseCount += 1
        return purchaseOutcome
    }
}
