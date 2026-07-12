import Foundation

public enum ReadinessState: String, Codable, Sendable, Equatable, CaseIterable {
    case ready, maintain, recover, rest

    public var rank: Int {
        switch self { case .ready: 3; case .maintain: 2; case .recover: 1; case .rest: 0 }
    }

    public static func from(score: Int) -> Self {
        switch min(100, max(0, score)) {
        case 80...100: .ready
        case 60..<80: .maintain
        case 35..<60: .recover
        default: .rest
        }
    }

    public static func stricter(_ lhs: Self, _ rhs: Self) -> Self { lhs.rank <= rhs.rank ? lhs : rhs }
}

public enum ReadinessConfidence: String, Codable, Sendable, Equatable { case low, medium, high }

public enum ReadinessScoreGroup: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case physiological, subjective, training, symptomsAndPain
    public var weight: Double {
        switch self { case .physiological, .subjective: 0.30; case .training: 0.25; case .symptomsAndPain: 0.15 }
    }
}

public enum ReadinessSignalID: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case sleep, hrv, restingHeartRate, energy, fatigue, stress, soreness, perceivedReadiness
    case trainingLoad, sessionRPE, rightForToday, cramps, pain
    // Retained as a compatibility symbol for context-only cycle metadata; it is not a score signal.
    case cyclePhase

    public static var allCases: [Self] {
        [.sleep, .hrv, .restingHeartRate, .energy, .fatigue, .stress, .soreness, .perceivedReadiness,
         .trainingLoad, .sessionRPE, .rightForToday, .cramps, .pain]
    }
}

public enum ReadinessReasonCode: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case stillLearning, missingSignals, goodSleep, hrvAtOrAboveBaseline, restingHeartRateNormal
    case highEnergy, balancedTrainingLoad, sleepBelowBaseline, hrvBelowBaseline, restingHeartRateElevated
    case lowEnergy, highFatigue, highStress, highSoreness, highTrainingLoad, highPain
}

public struct ReadinessMetricSnapshot: Sendable, Equatable {
    public let currentValue: Double
    public let baselineValues: [Double]
    public let observedAt: Date
    public init(currentValue: Double, baselineValues: [Double], observedAt: Date) { self.currentValue = currentValue; self.baselineValues = baselineValues; self.observedAt = observedAt }
}

public struct PhysiologicalReadinessSnapshot: Sendable, Equatable {
    public let sleepHours: ReadinessMetricSnapshot?
    public let hrvMilliseconds: ReadinessMetricSnapshot?
    public let restingHeartRateBPM: ReadinessMetricSnapshot?
    public init(sleepHours: ReadinessMetricSnapshot? = nil, hrvMilliseconds: ReadinessMetricSnapshot? = nil, restingHeartRateBPM: ReadinessMetricSnapshot? = nil) { self.sleepHours = sleepHours; self.hrvMilliseconds = hrvMilliseconds; self.restingHeartRateBPM = restingHeartRateBPM }
    public static let empty = Self()
}

public struct SubjectiveReadinessSnapshot: Sendable, Equatable {
    public let energy: Int?
    public let fatigue: Int?
    public let soreness: Int?
    public let stress: Int?
    public let perceivedReadiness: Int?
    public let cramps: Int?
    public init(energy: Int? = nil, fatigue: Int? = nil, soreness: Int? = nil, stress: Int? = nil, perceivedReadiness: Int? = nil, cramps: Int? = nil) { self.energy = energy; self.fatigue = fatigue; self.soreness = soreness; self.stress = stress; self.perceivedReadiness = perceivedReadiness; self.cramps = cramps }
    public static let empty = Self()
}

public struct TrainingReadinessSnapshot: Sendable, Equatable {
    public let weeklyLoadRatio: Double?
    public let averageSessionRPE: Double?
    public let rightForTodayRate: Double?
    public let completedWorkoutsInLast28Days: Int
    public init(weeklyLoadRatio: Double? = nil, averageSessionRPE: Double? = nil, rightForTodayRate: Double? = nil, completedWorkoutsInLast28Days: Int = 0) { self.weeklyLoadRatio = weeklyLoadRatio; self.averageSessionRPE = averageSessionRPE; self.rightForTodayRate = rightForTodayRate; self.completedWorkoutsInLast28Days = completedWorkoutsInLast28Days }
    public static let empty = Self()
}

public struct PainReadinessSnapshot: Sendable, Equatable {
    public let intensity: Int
    public let painType: PainType
    public let locationIDs: [String]
    public let observedAt: Date
    public init(intensity: Int, painType: PainType, locationIDs: [String], observedAt: Date) { self.intensity = intensity; self.painType = painType; self.locationIDs = locationIDs; self.observedAt = observedAt }
}

public struct DailyTrainingContext: Sendable, Equatable {
    public let assessmentDate: Date
    public let timeZoneIdentifier: String
    public let physiological: PhysiologicalReadinessSnapshot
    public let subjective: SubjectiveReadinessSnapshot
    public let training: TrainingReadinessSnapshot
    public let pain: PainReadinessSnapshot?
    public let cyclePhase: CyclePhase?
    public let cycleConfidence: Double?
    public init(assessmentDate: Date, timeZoneIdentifier: String, physiological: PhysiologicalReadinessSnapshot, subjective: SubjectiveReadinessSnapshot, training: TrainingReadinessSnapshot, pain: PainReadinessSnapshot?, cyclePhase: CyclePhase?, cycleConfidence: Double?) { self.assessmentDate = assessmentDate; self.timeZoneIdentifier = timeZoneIdentifier; self.physiological = physiological; self.subjective = subjective; self.training = training; self.pain = pain; self.cyclePhase = cyclePhase; self.cycleConfidence = cycleConfidence }
}

public struct ReadinessAssessment: Sendable, Equatable {
    public let assessmentDate: Date
    public let state: ReadinessState
    public let totalScore: Int
    public let confidence: ReadinessConfidence
    public let subScores: [ReadinessScoreGroup: Int]
    public let availableSignals: [ReadinessSignalID]
    public let missingSignals: [ReadinessSignalID]
    public let staleSignals: [ReadinessSignalID]
    public let positiveReasons: [ReadinessReasonCode]
    public let cautionReasons: [ReadinessReasonCode]
    public let modelVersion: String
    public init(assessmentDate: Date, state: ReadinessState, totalScore: Int, confidence: ReadinessConfidence, subScores: [ReadinessScoreGroup: Int], availableSignals: [ReadinessSignalID], missingSignals: [ReadinessSignalID], staleSignals: [ReadinessSignalID], positiveReasons: [ReadinessReasonCode], cautionReasons: [ReadinessReasonCode], modelVersion: String) { self.assessmentDate = assessmentDate; self.state = state; self.totalScore = totalScore; self.confidence = confidence; self.subScores = subScores; self.availableSignals = availableSignals; self.missingSignals = missingSignals; self.staleSignals = staleSignals; self.positiveReasons = positiveReasons; self.cautionReasons = cautionReasons; self.modelVersion = modelVersion }
}
