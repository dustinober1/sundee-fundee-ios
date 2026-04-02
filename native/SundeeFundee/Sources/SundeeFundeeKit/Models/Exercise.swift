import Foundation

// MARK: - Exercise Type
enum ExerciseType: Equatable, Codable {
    case fixed
    case amrap
    case range(min: Int, max: Int)
    case text(String)

    var description: String {
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
enum ExerciseCategory: String, Equatable, Codable, CaseIterable {
    case compound = "Compound"
    case isolation = "Isolation"
    case accessory = "Accessory"
    case warmup = "Warm-up"
    case cooldown = "Cool-down"
}

// MARK: - Exercise Set
struct ExerciseSet: Equatable, Codable, Identifiable {
    let id: String
    var reps: Int
    var prescribedWeight: Double
    var type: ExerciseType
    var completedWeight: Double?
    var actualReps: Int?
    var isComplete: Bool

    init(
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
struct Exercise: Equatable, Codable, Identifiable {
    let id: String
    var name: String
    var category: ExerciseCategory
    var bodyweight: Double
    var targetSets: [ExerciseSet]
    var notes: String?
    var restMinutes: Double

    init(
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
