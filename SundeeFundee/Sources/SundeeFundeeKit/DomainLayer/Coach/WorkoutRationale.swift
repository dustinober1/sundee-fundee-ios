import Foundation

public struct WorkoutRationale: Codable, Sendable, Equatable {
    public let headline: String
    public let reasons: [String]
    public let cautions: [String]

    public init(headline: String, reasons: [String], cautions: [String] = []) {
        self.headline = headline
        self.reasons = reasons
        self.cautions = cautions
    }
}

public struct WorkoutCompletionMemory: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let exerciseNames: [String]
    public let energyLevel: String?
    public let substitutionsAccepted: [String]
    public let painRelatedSwaps: [String]
    public let personalRecords: [String]
    public let skippedOrChangedExercises: [String]
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        workoutID: String,
        exerciseNames: [String],
        energyLevel: String? = nil,
        substitutionsAccepted: [String] = [],
        painRelatedSwaps: [String] = [],
        personalRecords: [String] = [],
        skippedOrChangedExercises: [String] = [],
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.exerciseNames = exerciseNames
        self.energyLevel = energyLevel
        self.substitutionsAccepted = substitutionsAccepted
        self.painRelatedSwaps = painRelatedSwaps
        self.personalRecords = personalRecords
        self.skippedOrChangedExercises = skippedOrChangedExercises
        self.dateCreated = dateCreated
    }
}
