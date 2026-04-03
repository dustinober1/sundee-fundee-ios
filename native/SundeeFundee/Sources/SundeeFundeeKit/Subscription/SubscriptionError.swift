import Foundation

// MARK: - SubscriptionError

/// Errors that can occur during subscription operations.
///
/// `SubscriptionError` provides detailed error cases for common subscription
/// failures with localized descriptions and recovery suggestions.
public enum SubscriptionError: Error, LocalizedError, Sendable, Equatable {
    /// The user is not subscribed to any plan.
    case notSubscribed

    /// The subscription has expired.
    case subscriptionExpired(expiryDate: Date?)

    /// The purchase failed.
    case purchaseFailed(underlying: Error?)

    /// The purchase was cancelled by the user.
    case purchaseCancelled

    /// Restoration of previous purchases failed.
    case restoreFailed(underlying: Error?)

    /// No previous purchases found to restore.
    case noPurchasesToRestore

    /// The product is not available in the current region.
    case productUnavailable(productId: String)

    /// The app store is not available.
    case storeNotAvailable

    /// Network error during subscription operation.
    case networkError(underlying: Error?)

    /// Invalid receipt or verification failed.
    case invalidReceipt

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .notSubscribed:
            return "You are not currently subscribed."
        case .subscriptionExpired(let expiryDate):
            if let date = expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Your subscription expired on \(formatter.string(from: date))."
            }
            return "Your subscription has expired."
        case .purchaseFailed(let underlying):
            if let error = underlying {
                return "Purchase failed: \(error.localizedDescription)"
            }
            return "Purchase failed. Please try again."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .restoreFailed(let underlying):
            if let error = underlying {
                return "Could not restore purchases: \(error.localizedDescription)"
            }
            return "Could not restore purchases. Please try again."
        case .noPurchasesToRestore:
            return "No previous purchases found to restore."
        case .productUnavailable(let productId):
            return "Product '\(productId)' is not available."
        case .storeNotAvailable:
            return "The App Store is not available. Please check your connection."
        case .networkError(let underlying):
            if let error = underlying {
                return "Network error: \(error.localizedDescription)"
            }
            return "A network error occurred. Please check your connection."
        case .invalidReceipt:
            return "Could not verify your purchase."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notSubscribed:
            return "Choose a subscription plan to unlock all features."
        case .subscriptionExpired:
            return "Renew your subscription to continue using premium features."
        case .purchaseFailed:
            return "Check your payment method and try again."
        case .purchaseCancelled:
            return "You can subscribe anytime from Settings."
        case .restoreFailed:
            return "Make sure you're signed in with the same Apple ID used for the purchase."
        case .noPurchasesToRestore:
            return "If you recently subscribed, please wait a moment and try again."
        case .productUnavailable:
            return "Contact support if this issue persists."
        case .storeNotAvailable:
            return "Check your internet connection and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidReceipt:
            return "Try restoring your purchases from Settings."
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SubscriptionError, rhs: SubscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.notSubscribed, .notSubscribed):
            return true
        case (.subscriptionExpired(let l), .subscriptionExpired(let r)):
            return l == r
        case (.purchaseFailed(let l), .purchaseFailed(let r)):
            return l?.localizedDescription == r?.localizedDescription
        case (.purchaseCancelled, .purchaseCancelled):
            return true
        case (.restoreFailed(let l), .restoreFailed(let r)):
            return l?.localizedDescription == r?.localizedDescription
        case (.noPurchasesToRestore, .noPurchasesToRestore):
            return true
        case (.productUnavailable(let l), .productUnavailable(let r)):
            return l == r
        case (.storeNotAvailable, .storeNotAvailable):
            return true
        case (.networkError(let l), .networkError(let r)):
            return l?.localizedDescription == r?.localizedDescription
        case (.invalidReceipt, .invalidReceipt):
            return true
        default:
            return false
        }
    }
}
