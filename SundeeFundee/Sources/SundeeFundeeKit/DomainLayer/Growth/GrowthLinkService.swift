import Foundation

public struct GrowthLinkConfiguration: Sendable, Equatable {
    public let providerToken: String?
    public let mediaTypeToken: String

    public init(providerToken: String? = nil, mediaTypeToken: String = "8") {
        self.providerToken = providerToken
        self.mediaTypeToken = mediaTypeToken
    }
}

public enum GrowthLinkService {
    public static let appStoreURL = URL(string: "https://apps.apple.com/app/sundeefundee/id6759870888")!

    public static func link(
        for context: ShareContext? = nil,
        configuration: GrowthLinkConfiguration = GrowthLinkConfiguration()
    ) -> URL {
        guard var components = URLComponents(url: appStoreURL, resolvingAgainstBaseURL: false) else {
            return appStoreURL
        }

        let campaign = context?.surface.rawValue ?? "share"
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "utm_source", value: "sundee_ios"))
        items.append(URLQueryItem(name: "utm_medium", value: "share"))
        items.append(URLQueryItem(name: "utm_term", value: "app_store"))
        items.append(URLQueryItem(name: "utm_campaign", value: campaign))
        if let sourceID = context?.sourceID {
            items.append(URLQueryItem(name: "utm_content", value: sourceID))
        }
        if let providerToken = configuration.providerToken, !providerToken.isEmpty {
            items.append(URLQueryItem(name: "pt", value: providerToken))
            items.append(URLQueryItem(name: "ct", value: normalizeCampaignToken([campaign, context?.sourceID])))
            items.append(URLQueryItem(name: "mt", value: configuration.mediaTypeToken))
        }
        if let referralCode = context?.referralCode {
            items.append(URLQueryItem(name: "ref", value: safeValue(referralCode)))
        }
        components.queryItems = items
        return components.url ?? appStoreURL
    }

    public static func caption(for context: ShareContext? = nil) -> String {
        let url = link(for: context).absoluteString
        guard let context else {
            return "Training with Sundee Fundee - cycle-aware strength. \(url)"
        }

        switch context.surface {
        case .completedWorkout:
            return "I finished \(context.title) on Sundee Fundee. Train with me: \(url)"
        case .personalRecord:
            return "New PR on Sundee Fundee: \(context.title). \(url)"
        case .cycleInsight:
            return "Training with my cycle, not against it. \(context.title) \(url)"
        case .challenge:
            if let code = context.referralCode {
                return "\(context.title)\nJoin my Sundee Fundee challenge with code \(code): \(url)"
            }
            return "\(context.title)\nJoin me on Sundee Fundee: \(url)"
        case .starterWorkout:
            return "Starting strength training with Sundee Fundee: \(context.title). \(url)"
        }
    }

    private static func normalizeCampaignToken(_ parts: [String?]) -> String {
        let raw = parts.compactMap { $0 }.joined(separator: "_")
        let normalized = raw
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return String((normalized.isEmpty ? "ios_share" : normalized).prefix(30))
    }

    private static func safeValue(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
