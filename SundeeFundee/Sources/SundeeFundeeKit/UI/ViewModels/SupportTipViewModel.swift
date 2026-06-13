import SwiftUI

public enum SupportTipViewState: Sendable, Equatable {
    case idle
    case loading
    case ready
    case purchasing
    case failed
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class SupportTipViewModel: ObservableObject {
    @Published public private(set) var offer: SupportTipOffer?
    @Published public private(set) var state: SupportTipViewState = .idle
    @Published public var message: String?

    private let store: SupportTipStoreProtocol

    public convenience init() {
        self.init(store: StoreKitSupportTipStore())
    }

    public init(store: SupportTipStoreProtocol) {
        self.store = store
    }

    public var priceText: String {
        offer?.displayPrice ?? "$1.99"
    }

    public var isPurchaseDisabled: Bool {
        state == .loading || state == .purchasing || offer == nil
    }

    public func loadOffer() async {
        guard state != .loading else { return }
        state = .loading
        message = nil

        do {
            offer = try await store.loadSupportTip()
            state = .ready
        } catch let error as SupportTipStoreError {
            state = .failed
            message = error.userMessage
        } catch {
            state = .failed
            message = SupportTipStoreError.storeKitFailure.userMessage
        }
    }

    public func purchase() async {
        state = .purchasing
        message = nil

        let outcome = await store.purchaseSupportTip()

        switch outcome {
        case .purchased:
            state = .ready
            message = "Thank you for supporting Sundee Fundee."
        case .pending:
            state = .ready
            message = "The purchase is pending App Store approval."
        case .cancelled:
            state = .ready
            message = nil
        case .unavailable:
            state = .failed
            message = SupportTipStoreError.productUnavailable.userMessage
        case .unverified:
            state = .failed
            message = SupportTipStoreError.unverifiedTransaction.userMessage
        case .failed:
            state = .failed
            message = SupportTipStoreError.storeKitFailure.userMessage
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct StoreKitSupportTipStore: SupportTipStoreProtocol {
    func loadSupportTip() async throws -> SupportTipOffer {
        throw SupportTipStoreError.productUnavailable
    }

    func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        .unavailable
    }
}
