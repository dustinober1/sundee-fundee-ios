import Foundation

public enum SupportTipProduct {
    public static let id = "com.sundeefundee.app.support.tip199"
    public static let referenceName = "Support the Developer Tip 1.99"
    public static let displayName = "Support the Developer"
    public static let description = "An optional tip to support ongoing Sundee Fundee development. It is not required for any feature."
}

public struct SupportTipOffer: Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String

    public init(id: String, displayName: String, description: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
    }
}

public enum SupportTipPurchaseOutcome: Sendable, Equatable {
    case purchased
    case pending
    case cancelled
    case unavailable
    case unverified
    case failed
}

public enum SupportTipStoreError: Error, Sendable, Equatable {
    case productUnavailable
    case unexpectedProductType
    case unverifiedTransaction
    case storeKitFailure

    public var userMessage: String {
        switch self {
        case .productUnavailable:
            return "Support tips are unavailable right now. Please try again later."
        case .unexpectedProductType:
            return "Support tips are unavailable right now. Please try again later."
        case .unverifiedTransaction:
            return "The purchase could not be verified. Check your App Store purchase history or try again later."
        case .storeKitFailure:
            return "The App Store could not complete the request. Please try again."
        }
    }
}

public protocol SupportTipStoreProtocol: Sendable {
    func loadSupportTip() async throws -> SupportTipOffer
    func purchaseSupportTip() async -> SupportTipPurchaseOutcome
}
