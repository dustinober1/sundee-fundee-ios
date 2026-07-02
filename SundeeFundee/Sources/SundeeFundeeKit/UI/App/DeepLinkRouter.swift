import Foundation

public enum DeepLinkRoute: String, Sendable, Equatable {
    case cycle
    case todayCheckIn

    public var targetTab: Tab {
        switch self {
        case .cycle:
            return .cycle
        case .todayCheckIn:
            return .today
        }
    }

    public var opensQuickCheckIn: Bool {
        switch self {
        case .cycle:
            return false
        case .todayCheckIn:
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
        }
    }
}
