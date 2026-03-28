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

    static func hasFreeTrial(_ product: Product) -> Bool {
        guard let intro = product.subscription?.introductoryOffer else { return false }
        return intro.paymentMode == .freeTrial
    }

    static func trialDurationText(_ product: Product) -> String? {
        guard let intro = product.subscription?.introductoryOffer,
              intro.paymentMode == .freeTrial else { return nil }
        let period = intro.period
        switch period.unit {
        case .day:   return period.value == 1 ? "1-day" : "\(period.value)-day"
        case .week:  return period.value == 1 ? "7-day" : "\(period.value * 7)-day"
        case .month: return period.value == 1 ? "1-month" : "\(period.value)-month"
        case .year:  return period.value == 1 ? "1-year" : "\(period.value)-year"
        @unknown default: return nil
        }
    }
}
