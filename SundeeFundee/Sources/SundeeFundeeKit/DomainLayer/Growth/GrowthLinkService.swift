import Foundation

public enum GrowthLinkService {
    public static let appStoreURL = URL(string: "https://apps.apple.com/app/sundeefundee/id6759870888")!

    public static func link(for context: ShareContext? = nil) -> URL {
        guard let context,
              var components = URLComponents(url: appStoreURL, resolvingAgainstBaseURL: false) else {
            return appStoreURL
        }

        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "pt", value: "growth"))
        items.append(URLQueryItem(name: "ct", value: context.surface.rawValue))
        if let sourceID = context.sourceID {
            items.append(URLQueryItem(name: "mt", value: safeValue(sourceID)))
        }
        if let referralCode = context.referralCode {
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

    private static func safeValue(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
