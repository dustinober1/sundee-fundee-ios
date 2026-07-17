import Foundation

/// CloudKit-safe, versioned persistence representation of a daily readiness assessment.
public struct DailyReadinessRecord: Codable, Sendable, Identifiable, Equatable {
    public static let recordType = "DailyReadinessRecord"
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let id: String
    public let dayKey: String
    public let timeZoneIdentifier: String
    public let assessmentDate: String
    public let dateCreated: String
    public let dateUpdated: String
    public let stateRaw: String
    public let totalScore: Int
    public let confidenceRaw: String
    public let modelVersion: String
    public let physiologicalScore: Int?
    public let subjectiveScore: Int?
    public let trainingScore: Int?
    public let symptomsPainScore: Int?
    public let availableSignalIDs: [String]
    public let missingSignalIDs: [String]
    public let staleSignalIDs: [String]
    public let positiveReasonIDs: [String]
    public let cautionReasonIDs: [String]

    public init(
        assessment: ReadinessAssessment,
        timeZone: TimeZone,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        let dayKey = Self.dayKey(for: assessment.assessmentDate, timeZone: timeZone)
        let formatter = ISO8601DateFormatter()
        self.id = "readiness-\(dayKey)"
        self.dayKey = dayKey
        self.timeZoneIdentifier = timeZone.identifier
        self.assessmentDate = formatter.string(from: assessment.assessmentDate)
        self.dateCreated = formatter.string(from: createdAt)
        self.dateUpdated = formatter.string(from: updatedAt)
        self.stateRaw = assessment.state.rawValue
        self.totalScore = assessment.totalScore
        self.confidenceRaw = assessment.confidence.rawValue
        self.modelVersion = assessment.modelVersion
        self.physiologicalScore = assessment.subScores[.physiological]
        self.subjectiveScore = assessment.subScores[.subjective]
        self.trainingScore = assessment.subScores[.training]
        self.symptomsPainScore = assessment.subScores[.symptomsAndPain]
        self.availableSignalIDs = assessment.availableSignals.map(\.rawValue)
        self.missingSignalIDs = assessment.missingSignals.map(\.rawValue)
        self.staleSignalIDs = assessment.staleSignals.map(\.rawValue)
        self.positiveReasonIDs = assessment.positiveReasons.map(\.rawValue)
        self.cautionReasonIDs = assessment.cautionReasons.map(\.rawValue)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, dayKey, timeZoneIdentifier, assessmentDate, dateCreated, dateUpdated
        case stateRaw, totalScore, confidenceRaw, modelVersion
        case physiologicalScore, subjectiveScore, trainingScore, symptomsPainScore
        case availableSignalIDs, missingSignalIDs, staleSignalIDs, positiveReasonIDs, cautionReasonIDs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard version <= Self.currentSchemaVersion else {
            throw DataError.invalidData(description: "DailyReadinessRecord schema version \(version) is newer than supported version \(Self.currentSchemaVersion)")
        }
        schemaVersion = version
        id = try container.decode(String.self, forKey: .id)
        dayKey = try container.decode(String.self, forKey: .dayKey)
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        assessmentDate = try container.decode(String.self, forKey: .assessmentDate)
        dateCreated = try container.decode(String.self, forKey: .dateCreated)
        dateUpdated = try container.decode(String.self, forKey: .dateUpdated)
        stateRaw = try container.decode(String.self, forKey: .stateRaw)
        totalScore = try container.decode(Int.self, forKey: .totalScore)
        confidenceRaw = try container.decode(String.self, forKey: .confidenceRaw)
        modelVersion = try container.decode(String.self, forKey: .modelVersion)
        physiologicalScore = try container.decodeIfPresent(Int.self, forKey: .physiologicalScore)
        subjectiveScore = try container.decodeIfPresent(Int.self, forKey: .subjectiveScore)
        trainingScore = try container.decodeIfPresent(Int.self, forKey: .trainingScore)
        symptomsPainScore = try container.decodeIfPresent(Int.self, forKey: .symptomsPainScore)
        availableSignalIDs = try container.decode([String].self, forKey: .availableSignalIDs)
        missingSignalIDs = try container.decode([String].self, forKey: .missingSignalIDs)
        staleSignalIDs = try container.decode([String].self, forKey: .staleSignalIDs)
        positiveReasonIDs = try container.decode([String].self, forKey: .positiveReasonIDs)
        cautionReasonIDs = try container.decode([String].self, forKey: .cautionReasonIDs)
    }

    public func assessment() throws -> ReadinessAssessment {
        guard let date = ISO8601DateFormatter().date(from: assessmentDate),
              let state = ReadinessState(rawValue: stateRaw),
              let confidence = ReadinessConfidence(rawValue: confidenceRaw) else {
            throw DataError.invalidData(description: "DailyReadinessRecord contains invalid enum or date values")
        }

        let scores: [(ReadinessScoreGroup, Int?)] = [
            (.physiological, physiologicalScore),
            (.subjective, subjectiveScore),
            (.training, trainingScore),
            (.symptomsAndPain, symptomsPainScore)
        ]
        return ReadinessAssessment(
            assessmentDate: date,
            state: state,
            totalScore: totalScore,
            confidence: confidence,
            subScores: Dictionary(uniqueKeysWithValues: scores.compactMap { group, score in
                score.map { (group, $0) }
            }),
            availableSignals: availableSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            missingSignals: missingSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            staleSignals: staleSignalIDs.compactMap(ReadinessSignalID.init(rawValue:)),
            positiveReasons: positiveReasonIDs.compactMap(ReadinessReasonCode.init(rawValue:)),
            cautionReasons: cautionReasonIDs.compactMap(ReadinessReasonCode.init(rawValue:)),
            modelVersion: modelVersion
        )
    }

    private static func dayKey(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
