import Foundation

public enum ProgramAdaptationReasonCode: String, Codable, Sendable, Equatable {
    case cycleAdjustment
    case injurySwap
    case painAdjustment
    case equipmentConversion
    case deloadAdjustment
}

public struct ProgramAdaptationChange: Sendable, Equatable, Identifiable {
    public let id: String
    public let reasonCode: ProgramAdaptationReasonCode
    public let exerciseName: String
    public let detail: String

    public init(
        reasonCode: ProgramAdaptationReasonCode,
        exerciseName: String,
        detail: String
    ) {
        self.id = reasonCode.rawValue + ":" + exerciseName + ":" + detail
        self.reasonCode = reasonCode
        self.exerciseName = exerciseName
        self.detail = detail
    }
}

public struct ProgramAdaptationSummary: Sendable, Equatable {
    public let headline: String
    public let changes: [ProgramAdaptationChange]

    public init(headline: String, changes: [ProgramAdaptationChange]) {
        self.headline = headline
        self.changes = changes
    }
}

public struct ProgramAdaptationResult: Sendable {
    public let exercises: [GeneratedProgramExercise]
    public let summary: ProgramAdaptationSummary

    public init(exercises: [GeneratedProgramExercise], summary: ProgramAdaptationSummary) {
        self.exercises = exercises
        self.summary = summary
    }
}
