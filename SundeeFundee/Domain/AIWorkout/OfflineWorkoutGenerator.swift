import Foundation

// MARK: - OfflineWorkoutGenerator

enum OfflineWorkoutGenerator {

    // MARK: - Public API

    static func generate(from context: WorkoutGenerationContext) -> GeneratedWorkout {
        let templates = selectTemplates(focus: context.focus, equipment: context.equipment)
        let scaled = scaleForTime(templates: templates, targetMinutes: context.timeMinutes)
        let withWeights = applyWeights(exercises: scaled, maxes: context.maxes, equipment: context.equipment)
        let adjusted = applyEnergyLevel(exercises: withWeights, energy: context.energyLevel)
        let adapted = applyInjurySubstitutions(exercises: adjusted, injuries: context.activeInjuries)
        let droppedCount = adjusted.count - adapted.count
        let phaseAdjusted = applyCyclePhase(exercises: adapted, phase: context.cyclePhase, readiness: context.readinessTier)

        let summary = buildCoachingSummary(context: context, exerciseCount: phaseAdjusted.count, droppedForInjury: droppedCount)

        return GeneratedWorkout(
            coachingSummary: summary,
            exercises: phaseAdjusted,
            questionnaire: QuestionnaireAnswers(
                timeMinutes: context.timeMinutes,
                focus: context.focus,
                energyLevel: context.energyLevel,
                equipment: context.equipment,
                desiredSkills: context.desiredSkills.isEmpty ? nil : context.desiredSkills
            )
        )
    }

    // MARK: - Exercise Templates

    struct ExerciseTemplate {
        let name: String
        let defaultSets: Int
        let defaultReps: String
        let defaultRestMinutes: Double
        let bodyweightOnly: Bool
        let muscleGroups: [String]
        let requiresBarbell: Bool
        let requiresDumbbells: Bool
        let maxKey: String?

        init(
            name: String,
            defaultSets: Int = 3,
            defaultReps: String = "8-10",
            defaultRestMinutes: Double = 2.0,
            bodyweightOnly: Bool = false,
            muscleGroups: [String] = [],
            requiresBarbell: Bool = false,
            requiresDumbbells: Bool = false,
            maxKey: String? = nil
        ) {
            self.name = name
            self.defaultSets = defaultSets
            self.defaultReps = defaultReps
            self.defaultRestMinutes = defaultRestMinutes
            self.bodyweightOnly = bodyweightOnly
            self.muscleGroups = muscleGroups
            self.requiresBarbell = requiresBarbell
            self.requiresDumbbells = requiresDumbbells
            self.maxKey = maxKey
        }
    }

    private static let upperBodyTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Flat Barbell Bench Press", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["chest", "triceps", "shoulders"], requiresBarbell: true, maxKey: "Flat Barbell Bench Press"),
        ExerciseTemplate(name: "Dumbbell Bench Press", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 2.0, muscleGroups: ["chest", "triceps"], requiresDumbbells: true),
        ExerciseTemplate(name: "Strict Press / Military Press", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["shoulders", "triceps"], requiresBarbell: true, maxKey: "Strict Press / Military Press"),
        ExerciseTemplate(name: "Dumbbell Overhead Press", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 2.0, muscleGroups: ["shoulders"], requiresDumbbells: true),
        ExerciseTemplate(name: "Barbell Row", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 2.5, muscleGroups: ["back", "biceps"], requiresBarbell: true),
        ExerciseTemplate(name: "Dumbbell Row", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 1.5, muscleGroups: ["back", "biceps"], requiresDumbbells: true),
        ExerciseTemplate(name: "Pull-Up", defaultSets: 3, defaultReps: "AMRAP", defaultRestMinutes: 2.0, bodyweightOnly: true, muscleGroups: ["back", "biceps"]),
        ExerciseTemplate(name: "Push-Ups", defaultSets: 3, defaultReps: "15-20", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["chest", "triceps"]),
        ExerciseTemplate(name: "Lateral Raises", defaultSets: 3, defaultReps: "12-15", defaultRestMinutes: 1.0, muscleGroups: ["shoulders"], requiresDumbbells: true),
        ExerciseTemplate(name: "Tricep Dips", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ["triceps", "chest"]),
    ]

    private static let lowerBodyTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Back Squat", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["quads", "glutes"], requiresBarbell: true, maxKey: "Back Squat"),
        ExerciseTemplate(name: "Front Squat", defaultSets: 3, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["quads"], requiresBarbell: true, maxKey: "Front Squat"),
        ExerciseTemplate(name: "Conventional Deadlift (No Straps)", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.5, muscleGroups: ["back", "glutes", "hamstrings"], requiresBarbell: true, maxKey: "Conventional Deadlift (No Straps)"),
        ExerciseTemplate(name: "Romanian Deadlift (No Straps)", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 2.5, muscleGroups: ["hamstrings", "glutes"], requiresBarbell: true),
        ExerciseTemplate(name: "Goblet Squat", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 2.0, muscleGroups: ["quads", "glutes"], requiresDumbbells: true),
        ExerciseTemplate(name: "Walking Lunges", defaultSets: 3, defaultReps: "10", defaultRestMinutes: 1.5, muscleGroups: ["quads", "glutes"], requiresDumbbells: true),
        ExerciseTemplate(name: "Hip Thrust", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 2.0, muscleGroups: ["glutes"], requiresBarbell: true),
        ExerciseTemplate(name: "Air Squats", defaultSets: 3, defaultReps: "20", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["quads", "glutes"]),
        ExerciseTemplate(name: "Bodyweight Lunges", defaultSets: 3, defaultReps: "12", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["quads", "glutes"]),
        ExerciseTemplate(name: "Glute Bridge", defaultSets: 3, defaultReps: "15", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["glutes"]),
    ]

    private static let pushTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Flat Barbell Bench Press", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["chest"], requiresBarbell: true, maxKey: "Flat Barbell Bench Press"),
        ExerciseTemplate(name: "Strict Press / Military Press", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.0, muscleGroups: ["shoulders"], requiresBarbell: true, maxKey: "Strict Press / Military Press"),
        ExerciseTemplate(name: "Dumbbell Bench Press", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 2.0, muscleGroups: ["chest"], requiresDumbbells: true),
        ExerciseTemplate(name: "Dumbbell Overhead Press", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 2.0, muscleGroups: ["shoulders"], requiresDumbbells: true),
        ExerciseTemplate(name: "Push-Ups", defaultSets: 3, defaultReps: "15-20", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["chest", "triceps"]),
        ExerciseTemplate(name: "Tricep Dips", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ["triceps"]),
        ExerciseTemplate(name: "Lateral Raises", defaultSets: 3, defaultReps: "12-15", defaultRestMinutes: 1.0, muscleGroups: ["shoulders"], requiresDumbbells: true),
    ]

    private static let pullTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Conventional Deadlift (No Straps)", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 3.5, muscleGroups: ["back", "hamstrings"], requiresBarbell: true, maxKey: "Conventional Deadlift (No Straps)"),
        ExerciseTemplate(name: "Barbell Row", defaultSets: 4, defaultReps: "5", defaultRestMinutes: 2.5, muscleGroups: ["back"], requiresBarbell: true),
        ExerciseTemplate(name: "Pull-Up", defaultSets: 3, defaultReps: "AMRAP", defaultRestMinutes: 2.0, bodyweightOnly: true, muscleGroups: ["back", "biceps"]),
        ExerciseTemplate(name: "Dumbbell Row", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 1.5, muscleGroups: ["back"], requiresDumbbells: true),
        ExerciseTemplate(name: "Face Pulls", defaultSets: 3, defaultReps: "15", defaultRestMinutes: 1.0, muscleGroups: ["shoulders", "back"]),
        ExerciseTemplate(name: "Dumbbell Curl", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 1.0, muscleGroups: ["biceps"], requiresDumbbells: true),
    ]

    private static let coreTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Plank Hold", defaultSets: 3, defaultReps: "45s", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Dead Bug", defaultSets: 3, defaultReps: "10", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Russian Twist", defaultSets: 3, defaultReps: "20", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Hanging Leg Raise", defaultSets: 3, defaultReps: "10-12", defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Ab Wheel Rollout", defaultSets: 3, defaultReps: "8-10", defaultRestMinutes: 1.5, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Bird-Dogs", defaultSets: 3, defaultReps: "10", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["core"]),
    ]

    private static let conditioningTemplates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Burpees", defaultSets: 4, defaultReps: "10", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["full body"]),
        ExerciseTemplate(name: "Kettlebell Swings", defaultSets: 4, defaultReps: "15", defaultRestMinutes: 1.0, muscleGroups: ["glutes", "hamstrings"], requiresDumbbells: true),
        ExerciseTemplate(name: "Box Jumps", defaultSets: 3, defaultReps: "10", defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ["quads", "glutes"]),
        ExerciseTemplate(name: "Mountain Climbers", defaultSets: 3, defaultReps: "30", defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ["core"]),
        ExerciseTemplate(name: "Jump Rope", defaultSets: 4, defaultReps: "60s", defaultRestMinutes: 0.5, bodyweightOnly: true, muscleGroups: ["calves"]),
        ExerciseTemplate(name: "Battle Ropes", defaultSets: 3, defaultReps: "30s", defaultRestMinutes: 1.0, muscleGroups: ["shoulders", "core"]),
    ]

    // MARK: - Template Selection

    static func selectTemplates(focus: WorkoutFocus, equipment: EquipmentAccess) -> [ExerciseTemplate] {
        let pool: [ExerciseTemplate]
        switch focus {
        case .upperBody: pool = upperBodyTemplates
        case .lowerBody: pool = lowerBodyTemplates
        case .fullBody: pool = upperBodyTemplates + lowerBodyTemplates
        case .push: pool = pushTemplates
        case .pull: pool = pullTemplates
        case .core: pool = coreTemplates
        case .conditioning: pool = conditioningTemplates
        case .strength: pool = pushTemplates + pullTemplates + lowerBodyTemplates
        case .olympicLifts: pool = conditioningTemplates + upperBodyTemplates
        case .gymnastics: pool = pullTemplates + coreTemplates
        case .mobility: pool = coreTemplates
        case .stretching: pool = coreTemplates
        }

        return filterForEquipment(templates: pool, equipment: equipment)
    }

    static func filterForEquipment(templates: [ExerciseTemplate], equipment: EquipmentAccess) -> [ExerciseTemplate] {
        templates.filter { template in
            switch equipment {
            case .fullGym:
                return true
            case .homeDumbbells:
                return !template.requiresBarbell
            case .hotelGym:
                return !template.requiresBarbell
            case .bodyweightOnly:
                return template.bodyweightOnly
            case .outdoor:
                return template.bodyweightOnly
            }
        }
    }

    // MARK: - Time Scaling

    static func scaleForTime(templates: [ExerciseTemplate], targetMinutes: Int) -> [ExerciseTemplate] {
        guard !templates.isEmpty else { return [] }

        let estimatedTimePerExercise = 5.0  // ~5 min per exercise (sets + rest)
        let targetCount = max(3, Int((Double(targetMinutes) / estimatedTimePerExercise).rounded()))
        let count = min(targetCount, templates.count)

        // For full body, alternate upper/lower from the pool
        return Array(templates.prefix(count))
    }

    // MARK: - Weight Application

    static func applyWeights(
        exercises: [ExerciseTemplate],
        maxes: [ExerciseMax],
        equipment: EquipmentAccess
    ) -> [GeneratedExercise] {
        let maxDict = Dictionary(maxes.map { ($0.name, $0.weightLb) }, uniquingKeysWith: { first, _ in first })

        return exercises.map { template in
            var weightLb: Double?
            if !template.bodyweightOnly {
                if let key = template.maxKey, let orm = maxDict[key] {
                    let percentage = defaultPercentage(for: template.defaultReps)
                    let raw = orm * percentage
                    weightLb = template.requiresBarbell
                        ? WeightCalculations.snapBarbellWeightLb(raw)
                        : WeightCalculations.roundToNearestFive(raw)
                } else if template.requiresDumbbells {
                    // Default to 25 lb dumbbell (nearest available conservative default)
                    weightLb = WeightCalculations.snapDumbbellWeightLb(25)
                } else if equipment == .homeDumbbells {
                    weightLb = WeightCalculations.snapDumbbellWeightLb(25)
                }
            }

            let exercise = GeneratedExercise(
                name: template.name,
                sets: template.defaultSets,
                reps: template.defaultReps,
                weightLb: weightLb,
                restMinutes: template.defaultRestMinutes,
                notes: nil,
                reasoning: nil,
                bodyweightOnly: template.bodyweightOnly
            )
            // Snap to physically loadable weight for any equipment type detected from the name.
            return exercise.withSnappedWeight()
        }
    }

    static func defaultPercentage(for reps: String) -> Double {
        if reps == "5" || reps == "3" { return 0.80 }
        if reps.contains("8") || reps.contains("10") { return 0.70 }
        if reps.contains("12") || reps.contains("15") { return 0.60 }
        return 0.65
    }

    // MARK: - Energy Level Adjustment

    static func applyEnergyLevel(exercises: [GeneratedExercise], energy: EnergyLevel) -> [GeneratedExercise] {
        let multiplier: Double
        switch energy {
        case .low: multiplier = 0.85
        case .medium: multiplier = 1.0
        case .high: multiplier = 1.05
        }

        guard multiplier != 1.0 else { return exercises }

        return exercises.map { ex in
            var modified = ex
            if let weight = ex.weightLb {
                let raw = WeightCalculations.roundToNearestFive(weight * multiplier)
                modified.weightLb = raw
                modified = modified.withSnappedWeight()
            }
            return modified
        }
    }

    // MARK: - Injury Substitutions

    static func applyInjurySubstitutions(
        exercises: [GeneratedExercise],
        injuries: [InjurySummary]
    ) -> [GeneratedExercise] {
        guard !injuries.isEmpty else { return exercises }

        let injuredLocations = injuries.map { $0.location.lowercased() }

        return exercises.compactMap { exercise in
            let name = exercise.name.lowercased()
            let isContraindicated = injuredLocations.contains { loc in
                contraindicatedKeywords(for: loc).contains { name.contains($0) }
            }

            if isContraindicated {
                if let sub = findSubstitute(for: exercise.name, avoiding: injuredLocations) {
                    var modified = exercise
                    modified.name = sub
                    modified.notes = "Substituted for \(exercise.name) due to injury"
                    return modified
                }
                return nil  // Remove if no safe substitute
            }
            return exercise
        }
    }

    private static func contraindicatedKeywords(for location: String) -> [String] {
        let loc = location.lowercased()
        if loc.contains("knee") { return ["squat", "lunge", "leg press", "step-up"] }
        if loc.contains("shoulder") { return ["press", "bench", "overhead", "clean", "snatch", "jerk"] }
        if loc.contains("back") || loc.contains("spine") { return ["deadlift", "good morning", "hinge", "row"] }
        if loc.contains("hip") { return ["deadlift", "hinge", "lunge", "hip thrust"] }
        if loc.contains("wrist") { return ["clean", "snatch", "jerk"] }
        if loc.contains("ankle") { return ["jump", "run", "calf"] }
        return []
    }

    private static let substitutionMap: [String: String] = [
        "Back Squat": "Goblet Squat",
        "Front Squat": "Goblet Squat",
        "Flat Barbell Bench Press": "Push-Ups",
        "Strict Press / Military Press": "Lateral Raises",
        "Conventional Deadlift (No Straps)": "Hip Thrust",
        "Barbell Row": "Dumbbell Row",
        "Walking Lunges": "Step-Ups",
    ]

    private static func findSubstitute(for exercise: String, avoiding locations: [String]) -> String? {
        guard let sub = substitutionMap[exercise] else { return nil }
        let subLower = sub.lowercased()
        let stillContraindicated = locations.contains { loc in
            contraindicatedKeywords(for: loc).contains { subLower.contains($0) }
        }
        return stillContraindicated ? nil : sub
    }

    // MARK: - Cycle Phase Adjustment

    static func applyCyclePhase(
        exercises: [GeneratedExercise],
        phase: String?,
        readiness: String?
    ) -> [GeneratedExercise] {
        guard let phaseStr = phase else { return exercises }

        let loadMultiplier: Double
        switch phaseStr {
        case "menstrual": loadMultiplier = 0.90
        case "follicular": loadMultiplier = 1.00
        case "ovulation": loadMultiplier = 1.12
        case "luteal": loadMultiplier = 0.97
        default: loadMultiplier = 1.00
        }

        let readinessMultiplier: Double
        switch readiness {
        case "low": readinessMultiplier = 0.85
        case "high": readinessMultiplier = 1.10
        default: readinessMultiplier = 1.0
        }

        let combined = loadMultiplier * readinessMultiplier

        guard combined != 1.0 else { return exercises }

        return exercises.map { ex in
            var modified = ex
            if let weight = ex.weightLb {
                let raw = WeightCalculations.roundToNearestFive(weight * combined)
                modified.weightLb = raw
                modified = modified.withSnappedWeight()
            }
            return modified
        }
    }

    // MARK: - Coaching Summary

    static func buildCoachingSummary(context: WorkoutGenerationContext, exerciseCount: Int, droppedForInjury: Int = 0) -> String {
        var parts: [String] = []

        parts.append("Generated offline: \(exerciseCount)-exercise \(context.focus.displayName.lowercased()) session targeting ~\(context.timeMinutes) minutes.")

        switch context.energyLevel {
        case .low:
            parts.append("Weights reduced for low energy day.")
        case .high:
            parts.append("Slightly increased intensity for high energy.")
        case .medium:
            break
        }

        if let phase = context.cyclePhase {
            parts.append("Adjusted for \(phase) phase.")
        }

        if !context.activeInjuries.isEmpty {
            let locations = context.activeInjuries.map(\.location).joined(separator: ", ")
            parts.append("Exercises modified for \(locations) injury considerations.")
        }

        if droppedForInjury > 0 {
            parts.append("\(droppedForInjury) exercise\(droppedForInjury == 1 ? " was" : "s were") removed due to injury constraints with no safe substitute available.")
        }

        return parts.joined(separator: " ")
    }
}
