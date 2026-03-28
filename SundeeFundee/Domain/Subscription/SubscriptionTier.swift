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
            return "Unlimited on-device AI workouts"
        case .plus:
            return "Cloud-powered AI workouts and programming tools"
        case .premium:
            return "Personal AI coach that learns and adapts"
        }
    }

    /// Short descriptive copy used in subscription surfaces.
    var subscriptionDescription: String {
        switch self {
        case .free:
            return "Core training tools with unlimited on-device AI."
        case .plus:
            return "Sundee AI-powered cloud workouts and custom programming tools."
        case .premium:
            return "Sundee AI Pro coach with persistent memory."
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

    /// Cloudflare Workers AI model identifier for cloud AI routing. "on-device" for free tier.
    var aiModelIdentifier: String {
        switch self {
        case .free:    return "on-device"
        case .plus:    return "@cf/qwen/qwen3-30b-a3b-fp8"
        case .premium: return "@cf/nvidia/nemotron-3-120b-a12b"
        }
    }

    /// Maximum cloud AI workout generations per day. nil means no cloud access (free).
    var dailyCloudAILimit: Int? {
        switch self {
        case .free:    return nil
        case .plus:    return 1
        case .premium: return 10
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
