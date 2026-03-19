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
    /// Weight value in the unit specified by `weightUnit`.
    var weight: Double?
    /// The unit for the `weight` field: "kg" or "lb". Defaults to "lb" for backward compatibility.
    var weightUnit: String
    var restMinutes: Double?
    var notes: String?
    let reasoning: String?
    var bodyweightOnly: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, weight, weightUnit, restMinutes, notes, reasoning, bodyweightOnly
        // Legacy key for backward compatibility with stored records
        case weightLbLegacy = "weightLb"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        sets: Int,
        reps: String,
        weight: Double? = nil,
        weightUnit: String = "lb",
        restMinutes: Double? = nil,
        notes: String? = nil,
        reasoning: String? = nil,
        bodyweightOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.weightUnit = weightUnit
        self.restMinutes = restMinutes
        self.notes = notes
        self.reasoning = reasoning
        self.bodyweightOnly = bodyweightOnly
    }

    // MARK: - Custom Decoding (backward compatibility)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(String.self, forKey: .reps)
        restMinutes = try container.decodeIfPresent(Double.self, forKey: .restMinutes)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
        bodyweightOnly = try container.decode(Bool.self, forKey: .bodyweightOnly)

        // Try new `weight` field first; fall back to legacy `weightLb` field
        if let w = try container.decodeIfPresent(Double.self, forKey: .weight) {
            weight = w
            weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit) ?? "lb"
        } else if let legacyW = try container.decodeIfPresent(Double.self, forKey: .weightLbLegacy) {
            weight = legacyW
            weightUnit = "lb"
        } else {
            weight = nil
            weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit) ?? "lb"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encode(weightUnit, forKey: .weightUnit)
        try container.encodeIfPresent(restMinutes, forKey: .restMinutes)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(reasoning, forKey: .reasoning)
        try container.encode(bodyweightOnly, forKey: .bodyweightOnly)
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

    /// Returns the weight value in pounds, regardless of the stored unit.
    /// Used for snapping logic (which operates in lbs) and backward compatibility.
    var weightInPounds: Double? {
        guard let w = weight else { return nil }
        if weightUnit.lowercased().contains("kg") {
            return w * WeightUnitConversion.poundsPerKilogram
        }
        return w
    }

    /// Returns a copy with the weight snapped to the nearest physically loadable value.
    /// - Parameter barLb: Bar weight in pounds (45 for men's, 35 for women's).
    func withSnappedWeight(barLb: Double = 45.0) -> GeneratedExercise {
        guard let raw = weightInPounds, raw > 0, !bodyweightOnly else { return self }
        var copy = self
        let snappedLb: Double
        switch equipmentType {
        case .barbell:
            snappedLb = WeightCalculations.snapBarbellWeightLb(raw, barLb: barLb)
        case .dumbbell:
            snappedLb = WeightCalculations.snapDumbbellWeightLb(raw)
        case .kettlebell:
            snappedLb = WeightCalculations.snapKettlebellWeightLb(raw)
        case .other:
            return copy
        }
        // Convert snapped lb value back to stored unit
        if weightUnit.lowercased().contains("kg") {
            copy.weight = snappedLb / WeightUnitConversion.poundsPerKilogram
        } else {
            copy.weight = snappedLb
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
                weight: nil,
                weightUnit: exercise.weightUnit,
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
