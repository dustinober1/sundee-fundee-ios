import Foundation

// MARK: - QuestionnaireAnswers

struct QuestionnaireAnswers: Codable, Sendable, Equatable, Hashable {
    let timeMinutes: Int
    let focus: WorkoutFocus
    let energyLevel: EnergyLevel
    let equipment: EquipmentAccess
}

// MARK: - GeneratedExercise

struct GeneratedExercise: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var sets: Int
    var reps: String  // "8-10", "5", "AMRAP"
    var weightKg: Double?
    var restMinutes: Double?
    var notes: String?
    let reasoning: String?
    var bodyweightOnly: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        sets: Int,
        reps: String,
        weightKg: Double? = nil,
        restMinutes: Double? = nil,
        notes: String? = nil,
        reasoning: String? = nil,
        bodyweightOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.restMinutes = restMinutes
        self.notes = notes
        self.reasoning = reasoning
        self.bodyweightOnly = bodyweightOnly
    }
}

// MARK: - GeneratedWorkout

struct GeneratedWorkout: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    let createdAt: Date
    var isFavorite: Bool
    let coachingSummary: String
    var exercises: [GeneratedExercise]
    let questionnaire: QuestionnaireAnswers

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        isFavorite: Bool = false,
        coachingSummary: String,
        exercises: [GeneratedExercise],
        questionnaire: QuestionnaireAnswers
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.coachingSummary = coachingSummary
        self.exercises = exercises
        self.questionnaire = questionnaire
    }

    var totalEstimatedMinutes: Int {
        let setTime = exercises.reduce(0) { total, ex in
            let repTime = 0.5  // ~30s per set average
            let rest = ex.restMinutes ?? 1.5
            return total + Double(ex.sets) * (repTime + rest)
        }
        return max(1, Int(setTime.rounded()))
    }

    var muscleGroups: [String] {
        Self.extractMuscleGroups(from: exercises)
    }

    static func extractMuscleGroups(from exercises: [GeneratedExercise]) -> [String] {
        var groups = Set<String>()
        for ex in exercises {
            let name = ex.name.lowercased()
            if name.contains("squat") || name.contains("lunge") || name.contains("leg press") {
                groups.insert("Quads")
            }
            if name.contains("deadlift") || name.contains("hip thrust") || name.contains("glute") {
                groups.insert("Glutes")
            }
            if name.contains("bench") || name.contains("push") || name.contains("chest") || name.contains("fly") {
                groups.insert("Chest")
            }
            if name.contains("row") || name.contains("pull") || name.contains("lat") {
                groups.insert("Back")
            }
            if name.contains("press") && (name.contains("overhead") || name.contains("shoulder") || name.contains("military")) {
                groups.insert("Shoulders")
            }
            if name.contains("curl") || name.contains("bicep") {
                groups.insert("Biceps")
            }
            if name.contains("tricep") || name.contains("extension") || name.contains("dip") {
                groups.insert("Triceps")
            }
            if name.contains("core") || name.contains("plank") || name.contains("crunch") || name.contains("ab") {
                groups.insert("Core")
            }
            if name.contains("calf") {
                groups.insert("Calves")
            }
            if name.contains("hamstring") || name.contains("romanian") || name.contains("nordic") {
                groups.insert("Hamstrings")
            }
        }
        return groups.sorted()
    }
}
