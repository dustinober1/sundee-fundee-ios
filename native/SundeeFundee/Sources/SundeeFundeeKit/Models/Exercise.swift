import Foundation

// MARK: - Exercise Type
public enum ExerciseType: Equatable, Codable, Sendable {
    case fixed
    case amrap
    case range(min: Int, max: Int)
    case text(String)

    public var description: String {
        switch self {
        case .fixed:
            return "Fixed"
        case .amrap:
            return "AMRAP"
        case .range(let min, let max):
            return "\(min)-\(max) reps"
        case .text(let value):
            return value
        }
    }
}

// MARK: - Exercise Category
public enum ExerciseCategory: String, Equatable, Codable, CaseIterable, Sendable {
    case compound = "Compound"
    case isolation = "Isolation"
    case accessory = "Accessory"
    case warmup = "Warm-up"
    case cooldown = "Cool-down"
}

// MARK: - Exercise Set
public struct ExerciseSet: Equatable, Codable, Identifiable, Sendable {
    public let id: String
    public var reps: Int
    public var prescribedWeight: Double
    public var type: ExerciseType
    public var completedWeight: Double?
    public var actualReps: Int?
    public var isComplete: Bool

    public init(
        id: String = UUID().uuidString,
        reps: Int,
        prescribedWeight: Double,
        type: ExerciseType,
        completedWeight: Double? = nil,
        actualReps: Int? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.reps = reps
        self.prescribedWeight = prescribedWeight
        self.type = type
        self.completedWeight = completedWeight
        self.actualReps = actualReps
        self.isComplete = isComplete
    }
}

// MARK: - Exercise
public struct Exercise: Equatable, Codable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var category: ExerciseCategory
    public var bodyweight: Double
    public var targetSets: [ExerciseSet]
    public var notes: String?
    public var restMinutes: Double

    public init(
        id: String,
        name: String,
        category: ExerciseCategory,
        bodyweight: Double,
        targetSets: [ExerciseSet],
        notes: String? = nil,
        restMinutes: Double = 2.5
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bodyweight = bodyweight
        self.targetSets = targetSets
        self.notes = notes
        self.restMinutes = restMinutes
    }
}
