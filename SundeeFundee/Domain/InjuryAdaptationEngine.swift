import Foundation

// MARK: - InjuryAdaptationEngine

/// Adapts a Program for active injury profiles.
/// Pure value semantics — never mutates inputs, returns new instances.
enum InjuryAdaptationEngine {

    struct ReplacementResult {
        let exerciseName: String
        let reason: String
    }

    // MARK: - Public API

    /// Returns the same program unchanged if no active injuries exist.
    static func adaptProgram(
        _ program: Program,
        activeInjuries: [InjuryProfile]
    ) -> Program {
        guard !activeInjuries.isEmpty else { return program }

        let adaptedWeeks = program.weeks.map { week in
            ProgramWeek(
                week: week.week,
                phaseID: week.phaseID,
                isTestWeek: week.isTestWeek,
                sessions: week.sessions.map { adaptSession($0, injuries: activeInjuries) }
            )
        }

        return Program(
            id: program.id,
            name: program.name,
            category: program.category,
            description: program.description,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek,
            difficulty: program.difficulty,
            phases: program.phases,
            weeks: adaptedWeeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }

    // MARK: - Private — contraindication tables

    private struct ContraindicationRule {
        let categories: [String]
        let muscleGroupKeywords: [String]
    }

    private static let contraindicationRules: [String: ContraindicationRule] = [
        "knee":     ContraindicationRule(categories: ["Squat Variations"], muscleGroupKeywords: ["quads"]),
        "shoulder": ContraindicationRule(categories: ["Overhead Pressing", "Bench Press Variations"], muscleGroupKeywords: ["shoulders"]),
        "back":     ContraindicationRule(categories: ["Hinge Variations", "Deadlift Variations"], muscleGroupKeywords: ["back"]),
        "spine":    ContraindicationRule(categories: ["Hinge Variations", "Deadlift Variations"], muscleGroupKeywords: ["back"]),
        "hip":      ContraindicationRule(categories: [], muscleGroupKeywords: ["glutes", "hamstrings"]),
    ]

    private static let regressionTable: [String: [String]] = [
        // Squat variations
        "Back Squat":                             ["Goblet Squat", "Box Squat", "Wall Ball Thrusters", "Air Squats"],
        "Front Squat":                            ["Goblet Squat", "Safety Bar Squat", "Air Squats"],
        "Walking Lunges":                         ["Stationary Lunges", "Step-Ups", "Wall Ball Thrusters"],
        // Hip hinge / posterior chain
        "Romanian Deadlift":                      ["Nordic Curl", "Glute Bridge", "Hip Thrust", "Cable Pull-Through"],
        "Conventional Deadlift (No Straps)":      ["Romanian Deadlift / RDL (No Straps)", "Trap Bar / Hex Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Good Morning":                           ["Cat-Cow", "Bird-Dogs", "Seated Good Morning"],
        // Machine / accessory
        "Wall Ball Thrusters":                    ["Goblet Squat", "Air Squats", "Step-Ups"],
        "Leg Curl":                               ["Nordic Curl", "Glute Bridge", "Swiss Ball Leg Curl"],
        "Calf Raise":                             ["Seated Calf Raise", "Single-Leg Calf Raise"],
        // Upper body press
        "Flat Barbell Bench Press":               ["Dumbbell Bench Press", "Floor Press", "Push-Ups"],
        "Strict Press / Military Press":          ["Lateral Raises", "Z-Press", "Seated Dumbbell Press"],
        // Upper body pull
        "Pull-Up":                                ["Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"],
        "Barbell Row":                            ["Dumbbell Row", "Cable Row", "TRX Row"],
    ]

    private static let recoveryPrepMap: [String: [String]] = [
        "knee":     ["Bird-Dogs", "Bodyweight Lunges", "Terminal Knee Extension", "Straight Leg Raises"],
        "shoulder": ["Banded Pull-Aparts", "Face Pulls", "Wall Slides", "Shoulder Circles"],
        "back":     ["Cat-Cow", "Bird-Dogs", "Dead Bug", "Pelvic Tilts"],
        "spine":    ["Cat-Cow", "Bird-Dogs", "Dead Bug", "McGill Curl-Up"],
        "hip":      ["Hip Circles", "Glute Bridges", "Clamshells", "90/90 Hip Stretch"],
        "ankle":    ["Ankle Circles", "Calf Raises (Partial)", "Towel Toe Curls"],
        "wrist":    ["Wrist Circles", "Prayer Stretch", "Reverse Wrist Curl"],
    ]

    private static let safeBodyweight = ["Air Squats", "Bird-Dogs", "Bodyweight Lunges"]
    private static let contraindicatedExerciseKeywords: [String: [String]] = [
        "knee": ["squat", "lunge", "leg press", "step-up"],
        "shoulder": ["press", "bench", "overhead"],
        "back": ["deadlift", "good morning", "hinge", "row"],
        "spine": ["deadlift", "good morning", "hinge", "row"],
        "hip": ["deadlift", "hinge", "lunge", "hip thrust"],
    ]

    // MARK: - Private — session / exercise adaptation

    private static func adaptSession(
        _ session: ProgramSession,
        injuries: [InjuryProfile]
    ) -> ProgramSession {
        ProgramSession(
            sessionID:   session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus:       session.focus,
            exercises:   session.exercises.map { adaptExercise($0, injuries: injuries) }
        )
    }

    private static func adaptExercise(
        _ exercise: ProgramExercise,
        injuries: [InjuryProfile]
    ) -> ProgramExercise {
        guard isContraindicated(exercise.exercise, injuries: injuries) else { return exercise }
        let replacement = findReplacement(exercise.exercise, injuries: injuries)
        return ProgramExercise(
            exercise:    replacement.exerciseName,
            variant:     exercise.variant,
            sets:        exercise.sets,
            reps:        exercise.reps,
            percent1RM:  exercise.percent1RM,
            restMinutes: exercise.restMinutes,
            notes:       exercise.notes
        )
    }

    private static func isContraindicated(_ exerciseID: String, injuries: [InjuryProfile]) -> Bool {
        // For the initial port we use a simplified keyword check.
        // Full category-based check requires an exercise definition catalogue.
        let exerciseName = exerciseID.lowercased()
        for injury in injuries {
            let loc = injury.location.lowercased()
            for (key, rule) in contraindicationRules {
                guard loc.contains(key) else { continue }
                for keyword in rule.muscleGroupKeywords {
                    if exerciseName.contains(keyword) { return true }
                }
                for cat in rule.categories {
                    if exerciseName.contains(cat.lowercased()) { return true }
                }
                if let keywords = contraindicatedExerciseKeywords[key] {
                    for keyword in keywords {
                        if exerciseName.contains(keyword) { return true }
                    }
                }
            }
        }
        return false
    }

    private static func findReplacement(_ exerciseID: String, injuries: [InjuryProfile]) -> ReplacementResult {
        let locations = injuries.map(\.location).joined(separator: ", ")

        if let regressions = regressionTable[exerciseID] {
            for candidate in regressions {
                if !isContraindicated(candidate, injuries: injuries) {
                    return ReplacementResult(exerciseName: candidate,
                                            reason: "Replaced due to \(locations) injury. Using \(candidate).")
                }
            }
        }

        for safe in safeBodyweight where !isContraindicated(safe, injuries: injuries) {
            return ReplacementResult(exerciseName: safe,
                                    reason: "Replaced due to \(locations) injury. Using \(safe).")
        }

        return ReplacementResult(exerciseName: exerciseID,
                                 reason: "Consult your coach — no safe automatic replacement found for \(locations) injury.")
    }

    // MARK: - Recovery prep block

    /// Returns a list of recovery prep exercises for all active injuries.
    static func buildRecoveryPrepBlock(injuries: [InjuryProfile]) -> [ProgramExercise] {
        var seen  = Set<String>()
        var block: [ProgramExercise] = []

        for injury in injuries {
            let loc = injury.location.lowercased()
            for (key, exercises) in recoveryPrepMap {
                guard loc.contains(key) else { continue }
                for ex in exercises where !seen.contains(ex) {
                    seen.insert(ex)
                    block.append(ProgramExercise(
                        exercise:    ex,
                        variant:     nil,
                        sets:        .fixed(2),
                        reps:        .fixed(10),
                        percent1RM:  nil,
                        restMinutes: 1,
                        notes:       "Recovery prep — gentle movement only"
                    ))
                }
            }
        }
        return block
    }
}
