import Foundation

public enum DeepLinkRoute: String, Sendable, Equatable {
    case cycle
    case todayCheckIn
    case readinessDetail
    case workout

    public var targetTab: Tab {
        switch self {
        case .cycle:
            return .cycle
        case .todayCheckIn, .readinessDetail:
            return .today
        case .workout:
            return .train
        }
    }

    public var opensQuickCheckIn: Bool {
        switch self {
        case .cycle, .readinessDetail, .workout:
            return false
        case .todayCheckIn:
            return true
        }
    }

    public var opensReadinessDetail: Bool {
        switch self {
        case .cycle, .todayCheckIn, .workout:
            return false
        case .readinessDetail:
            return true
        }
    }

    public var opensWorkout: Bool {
        switch self {
        case .cycle, .todayCheckIn, .readinessDetail:
            return false
        case .workout:
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
        case "workout":
            return .workout
        default:
            return nil
        }
    }

    public static func url(for route: DeepLinkRoute) -> URL {
        switch route {
        case .cycle:
            return routeURL("cycle")
        case .todayCheckIn:
            return routeURL("today/check-in")
        case .readinessDetail:
            return routeURL("today/readiness")
        case .workout:
            return routeURL("workout")
        }
    }

    private static func routeURL(_ path: String) -> URL {
        // The scheme is a fixed ASCII literal and the paths are constants,
        // so this parse can never fail.
        // swiftlint:disable:next force_unwrapping
        URL(string: "\(scheme)://\(path)")!
    }

    /// Extracts a challenge invite code from `sundeefundee://invite/CODE`.
    /// Codes are uppercased and restricted to the invite alphabet
    /// (A-Z, 2-9 — see `ChallengeInviteService.makeInviteToken`).
    public static func inviteCode(for url: URL) -> String? {
        guard url.scheme == scheme else { return nil }

        let host = url.host?.lowercased()
        let segments = url.path.split(separator: "/").map(String.init)

        let code: String?
        if host == "invite" {
            code = segments.first
        } else if host == "join", let queryCode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value {
            code = queryCode
        } else if segments.first?.lowercased() == "invite" {
            code = segments.dropFirst().first
        } else {
            code = nil
        }

        guard var normalized = code?.uppercased() else { return nil }
        normalized = String(normalized.filter { $0.isLetter || $0.isNumber }.prefix(12))
        return normalized.isEmpty ? nil : normalized
    }

    public static func inviteURL(code: String) -> URL {
        GrowthLinkService.inviteDeepLink(code: code)
    }
}
