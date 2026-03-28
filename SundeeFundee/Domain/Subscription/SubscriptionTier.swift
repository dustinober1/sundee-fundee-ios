import Foundation

/// Subscription tier for the app. Stored as raw string per CloudKit convention.
enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free
    case plus
    case premium

    var displayName: String {
        switch self {
        case .free:    return "Free"
        case .plus:    return "Sundee Plus"
        case .premium: return "Sundee Premium"
        }
    }

    /// Core user promise for each packaging tier.
    var valueProposition: String {
        switch self {
        case .free:
            return "On-device AI baseline workouts"
        case .plus:
            return "Better remote LLM workouts and advanced training intelligence"
        case .premium:
            return "Premium LLM workouts plus personalized coaching"
        }
    }

    /// Short descriptive copy used in subscription surfaces.
    var subscriptionDescription: String {
        switch self {
        case .free:
            return "Core training tools with on-device AI."
        case .plus:
            return "Smarter training intelligence and unlimited tracking."
        case .premium:
            return "Your personal AI coach that learns and adapts."
        }
    }

    var monthlyProductID: String {
        switch self {
        case .free:    return ""
        case .plus:    return "com.sundeefundee.sub.plus.monthly"
        case .premium: return "com.sundeefundee.sub.premium.monthly"
        }
    }

    var annualProductID: String {
        switch self {
        case .free:    return ""
        case .plus:    return "com.sundeefundee.sub.plus.annual"
        case .premium: return "com.sundeefundee.sub.premium.annual"
        }
    }

    /// Numeric rank for tier comparison. Higher is more permissive.
    var rank: Int {
        switch self {
        case .free:    return 0
        case .plus:    return 1
        case .premium: return 2
        }
    }

    static var allProductIDs: Set<String> {
        Set([
            SubscriptionTier.plus.monthlyProductID,
            SubscriptionTier.plus.annualProductID,
            SubscriptionTier.premium.monthlyProductID,
            SubscriptionTier.premium.annualProductID,
        ])
    }

    static func fromProductID(_ productID: String) -> SubscriptionTier {
        switch productID {
        case plus.monthlyProductID, plus.annualProductID:
            return .plus
        case premium.monthlyProductID, premium.annualProductID:
            return .premium
        default:
            return .free
        }
    }
}
