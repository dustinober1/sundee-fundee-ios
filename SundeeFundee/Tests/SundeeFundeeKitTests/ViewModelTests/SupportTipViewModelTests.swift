import XCTest
@testable import SundeeFundeeKit

@MainActor
final class SupportTipViewModelTests: XCTestCase {
    func testLoadOfferPublishesPriceAndReadyState() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
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
            offer: makeOffer(),
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        await viewModel.purchase()
        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 2)
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "Thank you for supporting Sundee Fundee.")
    }

    func testPendingPurchaseUsesClearCopy() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .pending
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "The purchase is pending App Store approval.")
    }

    func testCancelledPurchaseDoesNotShowError() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .cancelled
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertNil(viewModel.message)
    }

    func testUnverifiedPurchaseShowsVerificationError() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .unverified
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 1)
        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertEqual(viewModel.message, SupportTipStoreError.unverifiedTransaction.userMessage)
    }

    func testPurchaseWithoutOfferDoesNotCallStoreAndShowsUnavailableState() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 0)
        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertEqual(viewModel.message, SupportTipStoreError.productUnavailable.userMessage)
    }

    func testPurchaseDoesNotStartWhileLoading() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .purchased,
            suspendLoad: true
        )
        let viewModel = SupportTipViewModel(store: store)

        let loadTask = Task { @MainActor in
            await viewModel.loadOffer()
        }
        await waitForLoadSuspension(in: store)

        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 0)
        XCTAssertEqual(viewModel.state, .loading)
        XCTAssertNil(viewModel.message)

        store.resumeLoad()
        await loadTask.value
    }

    func testPurchaseDoesNotStartWhilePurchaseInFlight() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .purchased,
            suspendPurchase: true
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        let purchaseTask = Task { @MainActor in
            await viewModel.purchase()
        }
        await waitForPurchaseSuspension(in: store)

        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 1)
        XCTAssertEqual(viewModel.state, .purchasing)
        XCTAssertNil(viewModel.message)

        store.resumePurchase()
        await purchaseTask.value
    }

    func testLoadOfferDoesNotStartWhilePurchaseInFlight() async {
        let store = MockSupportTipStore(
            offer: makeOffer(),
            purchaseOutcome: .purchased,
            suspendPurchase: true
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()
        let purchaseTask = Task { @MainActor in
            await viewModel.purchase()
        }
        await waitForPurchaseSuspension(in: store)

        await viewModel.loadOffer()

        XCTAssertEqual(store.loadCount, 1)
        XCTAssertEqual(viewModel.state, .purchasing)
        XCTAssertNil(viewModel.message)

        store.resumePurchase()
        await purchaseTask.value
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

    private func makeOffer(displayPrice: String = "$1.99") -> SupportTipOffer {
        SupportTipOffer(
            id: SupportTipProduct.id,
            displayName: "Support the Developer",
            description: SupportTipProduct.description,
            displayPrice: displayPrice
        )
    }

    private func waitForLoadSuspension(
        in store: MockSupportTipStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if store.isLoadSuspended { return }
            await Task.yield()
        }
        XCTFail("Expected load to suspend", file: file, line: line)
    }

    private func waitForPurchaseSuspension(
        in store: MockSupportTipStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if store.isPurchaseSuspended { return }
            await Task.yield()
        }
        XCTFail("Expected purchase to suspend", file: file, line: line)
    }
}

private final class MockSupportTipStore: SupportTipStoreProtocol, @unchecked Sendable {
    private let offer: SupportTipOffer?
    private let purchaseOutcome: SupportTipPurchaseOutcome
    private let loadError: Error?
    private let suspendLoad: Bool
    private let suspendPurchase: Bool
    private var loadContinuation: CheckedContinuation<SupportTipOffer, Error>?
    private var purchaseContinuation: CheckedContinuation<SupportTipPurchaseOutcome, Never>?
    private(set) var loadCount = 0
    private(set) var purchaseCount = 0
    var isLoadSuspended: Bool { loadContinuation != nil }
    var isPurchaseSuspended: Bool { purchaseContinuation != nil }

    init(
        offer: SupportTipOffer?,
        purchaseOutcome: SupportTipPurchaseOutcome,
        loadError: Error? = nil,
        suspendLoad: Bool = false,
        suspendPurchase: Bool = false
    ) {
        self.offer = offer
        self.purchaseOutcome = purchaseOutcome
        self.loadError = loadError
        self.suspendLoad = suspendLoad
        self.suspendPurchase = suspendPurchase
    }

    func loadSupportTip() async throws -> SupportTipOffer {
        loadCount += 1
        if suspendLoad {
            return try await withCheckedThrowingContinuation { continuation in
                loadContinuation = continuation
            }
        }
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
        if suspendPurchase, purchaseContinuation == nil {
            return await withCheckedContinuation { continuation in
                purchaseContinuation = continuation
            }
        }
        return purchaseOutcome
    }

    func resumeLoad() {
        guard let loadContinuation else { return }
        self.loadContinuation = nil
        guard let offer else {
            loadContinuation.resume(throwing: SupportTipStoreError.productUnavailable)
            return
        }
        loadContinuation.resume(returning: offer)
    }

    func resumePurchase() {
        guard let purchaseContinuation else { return }
        self.purchaseContinuation = nil
        purchaseContinuation.resume(returning: purchaseOutcome)
    }
}
