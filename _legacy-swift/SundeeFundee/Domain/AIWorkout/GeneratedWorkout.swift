import Foundation

// MARK: - QuestionnaireAnswers

struct QuestionnaireAnswers: Codable, Sendable, Equatable, Hashable {
    let timeMinutes: Int
    let focus: WorkoutFocus
    let energyLevel: EnergyLevel
    let equipment: EquipmentAccess
    let desiredSkills: [String]?

    init(timeMinutes: Int, focus: WorkoutFocus, energyLevel: EnergyLevel,
         equipment: EquipmentAccess, desiredSkills: [String]? = nil) {
        self.timeMinutes = timeMinutes
        self.focus = focus
        self.energyLevel = energyLevel
        self.equipment = equipment
        self.desiredSkills = desiredSkills
    }
}

// MARK: - ExerciseEquipmentType

enum ExerciseEquipmentType {
    case barbell
    case dumbbell
    case kettlebell
    case other
}

// MARK: - GeneratedExercise

struct GeneratedExercise: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var sets: Int
    var reps: String  // "8-10", "5", "AMRAP"
    var weightLb: Double?
    var restMinutes: Double?
    var notes: String?
    let reasoning: String?
    var bodyweightOnly: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        sets: Int,
        reps: String,
        weightLb: Double? = nil,
        restMinutes: Double? = nil,
        notes: String? = nil,
        reasoning: String? = nil,
        bodyweightOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightLb = weightLb
        self.restMinutes = restMinutes
        self.notes = notes
        self.reasoning = reasoning
        self.bodyweightOnly = bodyweightOnly
    }

    /// Infers the primary equipment type from the exercise name.
    var equipmentType: ExerciseEquipmentType {
        let n = name.lowercased()
        if n.contains("kettlebell") || n.contains("kb ") || n.contains("kb swing") || n.contains("kb snatch") {
            return .kettlebell
        }
        if n.contains("dumbbell") || n.contains("db ") || n.contains("goblet") || n.contains("lateral raise") {
            return .dumbbell
        }
        if n.contains("barbell") || n.contains("bench press") || n.contains("back squat") ||
           n.contains("front squat") || n.contains("deadlift") || n.contains("strict press") ||
           n.contains("military press") || n.contains("barbell row") || n.contains("hip thrust") ||
           n.contains("romanian deadlift") || n.contains("overhead press") {
            return .barbell
        }
        return .other
    }

    /// Returns a copy with the weight snapped to the nearest physically loadable value.
    /// - Parameter barLb: Bar weight in pounds (45 for men's, 35 for women's).
    func withSnappedWeight(barLb: Double = 45.0) -> GeneratedExercise {
        guard let raw = weightLb, raw > 0, !bodyweightOnly else { return self }
        var copy = self
        switch equipmentType {
        case .barbell:
            copy.weightLb = WeightCalculations.snapBarbellWeightLb(raw, barLb: barLb)
        case .dumbbell:
            copy.weightLb = WeightCalculations.snapDumbbellWeightLb(raw)
        case .kettlebell:
            copy.weightLb = WeightCalculations.snapKettlebellWeightLb(raw)
        case .other:
            break
        }
        return copy
    }
}

// MARK: - GeneratedWorkout

struct GeneratedWorkout: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    let createdAt: Date
    var isFavorite: Bool
    var isCompleted: Bool
    let coachingSummary: String
    var exercises: [GeneratedExercise]
    let questionnaire: QuestionnaireAnswers

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        isFavorite: Bool = false,
        isCompleted: Bool = false,
        coachingSummary: String,
        exercises: [GeneratedExercise],
        questionnaire: QuestionnaireAnswers
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.isCompleted = isCompleted
        self.coachingSummary = coachingSummary
        self.exercises = exercises
        self.questionnaire = questionnaire
    }

    /// Returns a copy with all weight data stripped for anonymous sharing.
    /// Generates a new ID so the shared copy is independent of the original.
    func strippedForSharing() -> GeneratedWorkout {
        let strippedExercises = exercises.map { exercise in
            GeneratedExercise(
                name: exercise.name,
                sets: exercise.sets,
                reps: exercise.reps,
                weightLb: nil,
                restMinutes: exercise.restMinutes,
                notes: exercise.notes,
                reasoning: nil,
                bodyweightOnly: exercise.bodyweightOnly
            )
        }
        return GeneratedWorkout(
            id: UUID().uuidString,
            createdAt: createdAt,
            isFavorite: false,
            isCompleted: false,
            coachingSummary: Self.stripHealthReferences(from: coachingSummary),
            exercises: strippedExercises,
            questionnaire: questionnaire
        )
    }

    /// Removes cycle phase and injury references from a coaching summary for anonymous sharing.
    static func stripHealthReferences(from summary: String) -> String {
        var result = summary
        let healthPatterns = [
            #"Adjusted for \w+ phase\."#,
            #"Exercises modified for .+ injury considerations\."#,
        ]
        for pattern in healthPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
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
