import StoreKit
import SwiftUI

/// ViewModel for the paywall — manages purchase flow and product state.
@Observable
@MainActor
final class PaywallViewModel {
    var selectedTier: SubscriptionTier = .plus
    var billingPeriod: PaywallView.BillingPeriod = .monthly
    var isPurchasing = false
    var errorMessage: String?

    static func productFor(
        tier: SubscriptionTier,
        period: PaywallView.BillingPeriod,
        products: [Product]
    ) -> Product? {
        let targetID = period == .monthly ? tier.monthlyProductID : tier.annualProductID
        return products.first { $0.id == targetID }
    }

    static func isGuestUser(authState: AuthState) -> Bool {
        if case .guest = authState { return true }
        return false
    }
}
