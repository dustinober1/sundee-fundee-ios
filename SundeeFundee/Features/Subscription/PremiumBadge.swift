import SwiftUI

/// Small capsule badge indicating the required subscription tier.
struct PremiumBadge: View {
    let tier: SubscriptionTier

    var body: some View {
        if tier != .free {
            Text(Self.badgeText(for: tier))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.Colors.cream)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Self.badgeColor(for: tier))
                .clipShape(Capsule())
        }
    }

    static func badgeText(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:    return ""
        case .plus:    return "PLUS"
        case .premium: return "PREMIUM"
        }
    }

    static func badgeColor(for tier: SubscriptionTier) -> Color {
        switch tier {
        case .free:    return .clear
        case .plus:    return AppTheme.Colors.gold
        case .premium: return AppTheme.Colors.accentOrange
        }
    }
}
