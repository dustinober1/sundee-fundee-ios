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

public enum DailyPresenceActionEvidence: String, Codable, Sendable, CaseIterable, Hashable {
    case trained
    case recovered
    case rested
}

public struct DailyPresenceRecord: Codable, Sendable, Identifiable, Equatable {
    public static let currentModelVersion = 2

    public let id: String
    public let dayKey: String
    public let timeZoneIdentifier: String
    public let firstOpenDate: Date
    public let mostRecentOpenDate: Date
    public let participationLevelRaw: String
    public let statusRaw: String?
    public let actionEvidenceRaw: [String]
    public let dateCreated: Date
    public let dateUpdated: Date
    public let modelVersion: Int

    public var participationLevel: DailyParticipationLevel {
        DailyParticipationLevel(rawValue: participationLevelRaw) ?? .showedUp
    }

    public var status: DailyPresenceStatus? {
        statusRaw.flatMap(DailyPresenceStatus.init(rawValue:))
    }

    public var actionEvidence: Set<DailyPresenceActionEvidence> {
        Set(actionEvidenceRaw.compactMap(DailyPresenceActionEvidence.init(rawValue:)))
    }

    public init(
        dayKey: String,
        timeZoneIdentifier: String,
        firstOpenDate: Date,
        mostRecentOpenDate: Date? = nil,
        participationLevel: DailyParticipationLevel = .showedUp,
        status: DailyPresenceStatus? = nil,
        actionEvidence: Set<DailyPresenceActionEvidence> = [],
        dateCreated: Date? = nil,
        dateUpdated: Date? = nil,
        modelVersion: Int = Self.currentModelVersion
    ) {
        self.init(
            id: Self.makeID(dayKey: dayKey, timeZoneIdentifier: timeZoneIdentifier),
            dayKey: dayKey,
            timeZoneIdentifier: timeZoneIdentifier,
            firstOpenDate: firstOpenDate,
            mostRecentOpenDate: mostRecentOpenDate,
            participationLevel: participationLevel,
            status: status,
            actionEvidence: actionEvidence,
            dateCreated: dateCreated,
            dateUpdated: dateUpdated,
            modelVersion: modelVersion
        )
    }

    init(
        id: String,
        dayKey: String,
        timeZoneIdentifier: String,
        firstOpenDate: Date,
        mostRecentOpenDate: Date? = nil,
        participationLevel: DailyParticipationLevel = .showedUp,
        status: DailyPresenceStatus? = nil,
        actionEvidence: Set<DailyPresenceActionEvidence> = [],
        dateCreated: Date? = nil,
        dateUpdated: Date? = nil,
        modelVersion: Int = Self.currentModelVersion
    ) {
        self.id = id
        self.dayKey = dayKey
        self.timeZoneIdentifier = timeZoneIdentifier
        self.firstOpenDate = firstOpenDate
        self.mostRecentOpenDate = mostRecentOpenDate ?? firstOpenDate
        participationLevelRaw = participationLevel.rawValue
        statusRaw = status?.rawValue
        actionEvidenceRaw = Self.normalizedActionEvidence(
            actionEvidence,
            participationLevel: participationLevel,
            status: status
        ).map(\.rawValue).sorted()
        self.dateCreated = dateCreated ?? firstOpenDate
        self.dateUpdated = dateUpdated ?? firstOpenDate
        self.modelVersion = modelVersion
    }

    public static func makeID(dayKey: String, timeZoneIdentifier: String) -> String {
        _ = timeZoneIdentifier
        let safeDay = dayKey.map { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
                ? String(character)
                : "-"
        }.joined()
        return "presence-\(safeDay)"
    }

    public func promoting(
        to proposedLevel: DailyParticipationLevel,
        status proposedStatus: DailyPresenceStatus?,
        action proposedAction: DailyPresenceActionEvidence? = nil,
        at date: Date
    ) -> Self {
        var mergedEvidence = actionEvidence
        if let proposedAction {
            mergedEvidence.insert(proposedAction)
        }

        return Self(
            dayKey: dayKey,
            timeZoneIdentifier: timeZoneIdentifier,
            firstOpenDate: firstOpenDate,
            mostRecentOpenDate: date,
            participationLevel: max(participationLevel, proposedLevel),
            status: proposedStatus ?? status,
            actionEvidence: mergedEvidence,
            dateCreated: dateCreated,
            dateUpdated: date,
            modelVersion: max(modelVersion, Self.currentModelVersion)
        )
    }

    public func merging(with other: Self) -> Self {
        guard dayKey == other.dayKey else { return self }

        let earliest = earliestRecord(comparedWith: other)
        let mergedStatus = latestNonNilStatus(comparedWith: other)

        return Self(
            dayKey: dayKey,
            timeZoneIdentifier: earliest.timeZoneIdentifier,
            firstOpenDate: min(firstOpenDate, other.firstOpenDate),
            mostRecentOpenDate: max(mostRecentOpenDate, other.mostRecentOpenDate),
            participationLevel: max(participationLevel, other.participationLevel),
            status: mergedStatus,
            actionEvidence: actionEvidence.union(other.actionEvidence),
            dateCreated: min(dateCreated, other.dateCreated),
            dateUpdated: max(dateUpdated, other.dateUpdated),
            modelVersion: max(modelVersion, other.modelVersion, Self.currentModelVersion)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, dayKey, timeZoneIdentifier, firstOpenDate, mostRecentOpenDate
        case participationLevelRaw, statusRaw, actionEvidenceRaw
        case dateCreated, dateUpdated, modelVersion
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        dayKey = try values.decode(String.self, forKey: .dayKey)
        timeZoneIdentifier = try values.decode(String.self, forKey: .timeZoneIdentifier)
        firstOpenDate = try values.decode(Date.self, forKey: .firstOpenDate)
        mostRecentOpenDate = try values.decode(Date.self, forKey: .mostRecentOpenDate)
        let decodedParticipationLevelRaw = try values.decode(
            String.self,
            forKey: .participationLevelRaw
        )
        let decodedStatusRaw = try values.decodeIfPresent(String.self, forKey: .statusRaw)
        participationLevelRaw = decodedParticipationLevelRaw
        statusRaw = decodedStatusRaw
        let decodedEvidence = try values.decodeIfPresent([String].self, forKey: .actionEvidenceRaw)
        if let decodedEvidence {
            actionEvidenceRaw = decodedEvidence
        } else {
            let decodedParticipationLevel =
                DailyParticipationLevel(rawValue: decodedParticipationLevelRaw) ?? .showedUp
            let decodedStatus = decodedStatusRaw.flatMap(DailyPresenceStatus.init(rawValue:))
            actionEvidenceRaw = Self.normalizedActionEvidence(
                [],
                participationLevel: decodedParticipationLevel,
                status: decodedStatus
            ).map(\.rawValue).sorted()
        }
        dateCreated = try values.decode(Date.self, forKey: .dateCreated)
        dateUpdated = try values.decode(Date.self, forKey: .dateUpdated)
        modelVersion = try values.decodeIfPresent(Int.self, forKey: .modelVersion) ?? 1
    }

    private static func normalizedActionEvidence(
        _ explicitEvidence: Set<DailyPresenceActionEvidence>,
        participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?
    ) -> Set<DailyPresenceActionEvidence> {
        guard participationLevel == .acted, explicitEvidence.isEmpty else {
            return explicitEvidence
        }

        var evidence = explicitEvidence
        switch status {
        case .trained:
            evidence.insert(.trained)
        case .resting:
            evidence.insert(.rested)
        case .ready, .tired, .sore, .none:
            break
        }
        return evidence
    }

    private func earliestRecord(comparedWith other: Self) -> Self {
        if firstOpenDate != other.firstOpenDate {
            return firstOpenDate < other.firstOpenDate ? self : other
        }
        if dateCreated != other.dateCreated {
            return dateCreated < other.dateCreated ? self : other
        }
        return timeZoneIdentifier <= other.timeZoneIdentifier ? self : other
    }

    private func latestNonNilStatus(comparedWith other: Self) -> DailyPresenceStatus? {
        switch (status, other.status) {
        case (.none, let status?):
            return status
        case (let status?, .none):
            return status
        case (.none, .none):
            return nil
        case (let ownStatus?, let otherStatus?):
            if dateUpdated != other.dateUpdated {
                return dateUpdated > other.dateUpdated ? ownStatus : otherStatus
            }
            return ownStatus.rawValue >= otherStatus.rawValue ? ownStatus : otherStatus
        }
    }
}
