import Foundation

public enum DailyPresenceStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case ready
    case tired
    case sore
    case resting
    case trained
}

public extension DailyPresenceStatus {
    var displayName: String {
        switch self {
        case .ready: "Ready"
        case .tired: "Tired"
        case .sore: "Sore"
        case .resting: "Resting"
        case .trained: "Trained"
        }
    }

    var systemImage: String {
        switch self {
        case .ready: "bolt"
        case .tired: "moon.zzz"
        case .sore: "figure.cooldown"
        case .resting: "leaf"
        case .trained: "checkmark.circle"
        }
    }
}

public enum ConsistencyMomentumCopy {
    public static let welcomeBack = "Welcome back"
}

public enum DailyParticipationLevel: String, Codable, Sendable, CaseIterable, Comparable, Equatable {
    case showedUp
    case checkedIn
    case acted

    private var rank: Int {
        switch self {
        case .showedUp: 0
        case .checkedIn: 1
        case .acted: 2
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

public struct DailyPresenceRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let dayKey: String
    public let timeZoneIdentifier: String
    public let firstOpenDate: Date
    public let mostRecentOpenDate: Date
    public let participationLevelRaw: String
    public let statusRaw: String?
    public let dateCreated: Date
    public let dateUpdated: Date
    public let modelVersion: Int

    public var participationLevel: DailyParticipationLevel {
        DailyParticipationLevel(rawValue: participationLevelRaw) ?? .showedUp
    }

    public var status: DailyPresenceStatus? {
        statusRaw.flatMap(DailyPresenceStatus.init(rawValue:))
    }

    public init(
        dayKey: String,
        timeZoneIdentifier: String,
        firstOpenDate: Date,
        mostRecentOpenDate: Date? = nil,
        participationLevel: DailyParticipationLevel = .showedUp,
        status: DailyPresenceStatus? = nil,
        dateCreated: Date? = nil,
        dateUpdated: Date? = nil,
        modelVersion: Int = 1
    ) {
        id = Self.makeID(dayKey: dayKey, timeZoneIdentifier: timeZoneIdentifier)
        self.dayKey = dayKey
        self.timeZoneIdentifier = timeZoneIdentifier
        self.firstOpenDate = firstOpenDate
        self.mostRecentOpenDate = mostRecentOpenDate ?? firstOpenDate
        participationLevelRaw = participationLevel.rawValue
        statusRaw = status?.rawValue
        self.dateCreated = dateCreated ?? firstOpenDate
        self.dateUpdated = dateUpdated ?? firstOpenDate
        self.modelVersion = modelVersion
    }

    public static func makeID(dayKey: String, timeZoneIdentifier: String) -> String {
        let safeZone = timeZoneIdentifier.map { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
                ? String(character)
                : "-"
        }.joined()
        return "presence-\(dayKey)-\(safeZone)"
    }

    public func promoting(
        to proposedLevel: DailyParticipationLevel,
        status proposedStatus: DailyPresenceStatus?,
        at date: Date
    ) -> Self {
        Self(
            dayKey: dayKey,
            timeZoneIdentifier: timeZoneIdentifier,
            firstOpenDate: firstOpenDate,
            mostRecentOpenDate: date,
            participationLevel: max(participationLevel, proposedLevel),
            status: proposedStatus ?? status,
            dateCreated: dateCreated,
            dateUpdated: date,
            modelVersion: modelVersion
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, dayKey, timeZoneIdentifier, firstOpenDate, mostRecentOpenDate
        case participationLevelRaw, statusRaw, dateCreated, dateUpdated, modelVersion
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        dayKey = try values.decode(String.self, forKey: .dayKey)
        timeZoneIdentifier = try values.decode(String.self, forKey: .timeZoneIdentifier)
        firstOpenDate = try values.decode(Date.self, forKey: .firstOpenDate)
        mostRecentOpenDate = try values.decode(Date.self, forKey: .mostRecentOpenDate)
        participationLevelRaw = try values.decode(String.self, forKey: .participationLevelRaw)
        statusRaw = try values.decodeIfPresent(String.self, forKey: .statusRaw)
        dateCreated = try values.decode(Date.self, forKey: .dateCreated)
        dateUpdated = try values.decode(Date.self, forKey: .dateUpdated)
        modelVersion = try values.decodeIfPresent(Int.self, forKey: .modelVersion) ?? 1
    }
}
