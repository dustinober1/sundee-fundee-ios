import Foundation

public enum DeepLinkRoute: String, Sendable, Equatable {
    case cycle
    case todayCheckIn
    case readinessDetail

    public var targetTab: Tab {
        switch self {
        case .cycle:
            return .cycle
        case .todayCheckIn, .readinessDetail:
            return .today
        }
    }

    public var opensQuickCheckIn: Bool {
        switch self {
        case .cycle, .readinessDetail:
            return false
        case .todayCheckIn:
            return true
        }
    }

    public var opensReadinessDetail: Bool {
        switch self {
        case .cycle, .todayCheckIn:
            return false
        case .readinessDetail:
            return true
        }
    }
}

public enum DeepLinkRouter {
    public static let scheme = "sundeefundee"

    public static func route(for url: URL) -> DeepLinkRoute? {
        guard url.scheme == scheme else { return nil }

        let path = [url.host, url.path]
            .compactMap { $0 }
            .joined()
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch path {
        case "cycle":
            return .cycle
        case "today/check-in":
            return .todayCheckIn
        case "today/readiness":
            return .readinessDetail
        default:
            return nil
        }
    }

    public static func url(for route: DeepLinkRoute) -> URL {
        switch route {
        case .cycle:
            return URL(string: "\(scheme)://cycle")!
        case .todayCheckIn:
            return URL(string: "\(scheme)://today/check-in")!
        case .readinessDetail:
            return URL(string: "\(scheme)://today/readiness")!
        }
    }
}
