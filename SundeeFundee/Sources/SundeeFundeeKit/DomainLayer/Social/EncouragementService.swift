import Foundation

// MARK: - NudgeType

public enum NudgeType: String, Codable, Sendable, CaseIterable, Equatable {
    case crushedIt
    case showedUp
    case restUp
    case cheering
    case letsGo

    public var title: String {
        switch self {
        case .crushedIt: return "Crushed it!"
        case .showedUp: return "Way to show up!"
        case .restUp: return "Rest & recharge!"
        case .cheering: return "Cheering for you!"
        case .letsGo: return "Finish strong!"
        }
    }

    public var emoji: String {
        switch self {
        case .crushedIt: return "💥"
        case .showedUp: return "⚡️"
        case .restUp: return "🌿"
        case .cheering: return "🥂"
        case .letsGo: return "🏋️"
        }
    }

    public var displayText: String {
        "\(title) \(emoji)"
    }
}

// MARK: - PodEncouragement

public struct PodEncouragement: Codable, Sendable, Identifiable, Equatable {
    public static let recordType = "PodEncouragementRecord"

    public let id: String
    public let podID: String
    public let senderID: String
    public let senderName: String
    public let recipientID: String?
    public let nudgeTypeRaw: String
    public let dateCreated: Date

    public var nudgeType: NudgeType {
        NudgeType(rawValue: nudgeTypeRaw) ?? .crushedIt
    }

    public init(
        id: String = UUID().uuidString,
        podID: String,
        senderID: String,
        senderName: String,
        recipientID: String? = nil,
        nudgeType: NudgeType,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.podID = podID
        self.senderID = senderID
        self.senderName = senderName
        self.recipientID = recipientID
        self.nudgeTypeRaw = nudgeType.rawValue
        self.dateCreated = dateCreated
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case podID
        case senderID
        case senderName
        case recipientID
        case nudgeTypeRaw
        case dateCreated
    }
}

// MARK: - EncouragementRateLimiter

public enum EncouragementRateLimiter {
    public static let maxNudgesPerDay = 3

    /// Checks if a sender has exceeded the 3 nudges / 24h limit in the specified pod.
    public static func canSendNudge(
        senderID: String,
        podID: String,
        existingEncouragements: [PodEncouragement],
        now: Date = Date()
    ) -> Bool {
        let cutoff = now.addingTimeInterval(-24 * 3600)
        let recentCount = existingEncouragements.filter { encouragement in
            encouragement.senderID == senderID &&
            encouragement.podID == podID &&
            encouragement.dateCreated >= cutoff
        }.count
        return recentCount < maxNudgesPerDay
    }

    /// Number of nudges remaining for this sender in the current 24h rolling window.
    public static func remainingNudges(
        senderID: String,
        podID: String,
        existingEncouragements: [PodEncouragement],
        now: Date = Date()
    ) -> Int {
        let cutoff = now.addingTimeInterval(-24 * 3600)
        let recentCount = existingEncouragements.filter { encouragement in
            encouragement.senderID == senderID &&
            encouragement.podID == podID &&
            encouragement.dateCreated >= cutoff
        }.count
        return max(0, maxNudgesPerDay - recentCount)
    }
}
