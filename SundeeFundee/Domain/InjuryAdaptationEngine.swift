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
        let nonResolved = activeInjuries.filter { $0.recoveryPhase != .resolved }
        guard !nonResolved.isEmpty else { return program }

        let adaptedWeeks = program.weeks.map { week in
            ProgramWeek(
                week: week.week,
                phaseID: week.phaseID,
                isTestWeek: week.isTestWeek,
                sessions: week.sessions.map { adaptSession($0, injuries: nonResolved) }
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

    /// Result including both the adapted program and metadata about which exercises were adapted.
    struct AdaptationResult {
        let program: Program
        /// Maps exercise names to their original exercise names for adapted exercises.
        let adaptedExercises: [String: String]
    }

    /// Adapts a program and returns metadata identifying which exercises are adaptations.
    static func adaptProgramWithMetadata(
        _ program: Program,
        activeInjuries: [InjuryProfile]
    ) -> AdaptationResult {
        let nonResolved = activeInjuries.filter { $0.recoveryPhase != .resolved }
        guard !nonResolved.isEmpty else {
            return AdaptationResult(program: program, adaptedExercises: [:])
        }

        var metadata: [String: String] = [:]

        let adaptedWeeks = program.weeks.map { week in
            ProgramWeek(
                week: week.week,
                phaseID: week.phaseID,
                isTestWeek: week.isTestWeek,
                sessions: week.sessions.map { session in
                    let adapted = adaptSession(session, injuries: nonResolved)
                    // Track which exercises were replaced
                    for (original, replacement) in zip(session.exercises, adapted.exercises) {
                        if original.exercise != replacement.exercise {
                            metadata[replacement.exercise] = original.exercise
                        }
                    }
                    return adapted
                }
            )
        }

        let adaptedProgram = Program(
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

        return AdaptationResult(program: adaptedProgram, adaptedExercises: metadata)
    }

    // MARK: - Clinical synonym normalization

    private static let clinicalSynonyms: [String: String] = [
        "acl": "knee", "mcl": "knee", "pcl": "knee", "meniscus": "knee",
        "patella": "knee", "patellar": "knee", "quad": "knee", "quadriceps": "knee",
        "rotator cuff": "shoulder", "labrum": "shoulder", "deltoid": "shoulder",
        "supraspinatus": "shoulder", "infraspinatus": "shoulder", "bicep tendon": "shoulder",
        "lumbar": "back", "lower back": "back", "upper back": "back",
        "thoracic": "back", "cervical": "back", "disc": "back", "herniated": "back",
        "sciatica": "back", "spinal": "spine", "vertebra": "spine", "vertebrae": "spine",
        "sacroiliac": "hip", "si joint": "hip", "groin": "hip", "labral": "hip",
        "hip flexor": "hip", "piriformis": "hip",
        "achilles": "ankle", "plantar": "ankle", "calf": "ankle",
        "carpal": "wrist", "carpal tunnel": "wrist", "forearm": "wrist",
    ]

    /// Maps free-text injury locations to engine contraindication keys
    /// using clinical synonym matching.
    static func normalizedBodyRegions(from injuries: [InjuryProfile]) -> [String] {
        var regions = Set<String>()
        let knownKeys = Set(contraindicationRules.keys)

        for injury in injuries {
            let loc = injury.location.lowercased()

            // Direct match against known keys
            for key in knownKeys where loc.contains(key) {
                regions.insert(key)
            }

            // Clinical synonym matching
            for (synonym, region) in clinicalSynonyms where loc.contains(synonym) {
                regions.insert(region)
            }
        }

        return Array(regions)
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
        "wrist":    ContraindicationRule(categories: ["Olympic Weightlifting"], muscleGroupKeywords: []),
    ]

    private static let regressionTable: [String: [String]] = [
        // Squat variations
        "Back Squat":                             ["Goblet Squat", "Box Squat", "Wall Ball Thrusters", "Air Squats"],
        "Front Squat":                            ["Goblet Squat", "Safety Bar Squat", "Air Squats"],
        "Walking Lunges":                         ["Stationary Lunges", "Step-Ups", "Wall Ball Thrusters"],
        // Hip hinge
        "Romanian Deadlift (No Straps)":          ["Nordic Curl", "Glute Bridge", "Hip Thrust", "Cable Pull-Through"],
        "Romanian Deadlift (With Straps)":        ["Nordic Curl", "Glute Bridge", "Hip Thrust", "Cable Pull-Through"],
        "Conventional Deadlift (No Straps)":      ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Conventional Deadlift (With Straps)":    ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Sumo Deadlift (No Straps)":              ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Sumo Deadlift (With Straps)":            ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Trap Bar Deadlift (No Straps)":          ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Trap Bar Deadlift (With Straps)":        ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
        "Good Morning":                           ["Cat-Cow", "Bird-Dogs", "Seated Good Morning"],
        // Machine / accessory
        "Wall Ball Thrusters":                    ["Goblet Squat", "Air Squats", "Step-Ups"],
        "Banded Leg Curls":                       ["Nordic Curl", "Glute Bridge", "Swiss Ball Leg Curl"],
        "Plated Calf Step Up":                    ["Seated Calf Raise", "Single-Leg Calf Raise"],
        // Olympic Weightlifting
        "Squat Snatch":                               ["Power Snatch", "Hang Snatch", "Overhead Squat"],
        "Squat Clean":                                ["Power Clean", "Hang Clean", "Front Squat"],
        "Power Clean":                                ["Hang Clean", "Kettlebell Deadlift", "Hip Thrust"],
        "Power Snatch":                               ["Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"],
        "Hang Clean":                                 ["Kettlebell Deadlift", "Hip Thrust", "Cable Pull-Through"],
        "Hang Snatch":                                ["Kettlebell Deadlift", "Hip Thrust", "Cable Pull-Through"],
        "Split Jerk":                                 ["Push Press", "Push Jerk", "Strict Press"],
        "Push Jerk":                                  ["Push Press", "Strict Press", "Dumbbell Overhead Press"],
        "Clean and Jerk":                             ["Power Clean", "Push Press", "Front Squat"],
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
        "shoulder": ["press", "bench", "overhead", "clean", "snatch", "jerk"],
        "back": ["deadlift", "good morning", "hinge", "row"],
        "spine": ["deadlift", "good morning", "hinge", "row"],
        "hip": ["deadlift", "hinge", "lunge", "hip thrust"],
        "wrist": ["clean", "snatch", "jerk"],
    ]

    // MARK: - Private — session / exercise adaptation

    private static func adaptSession(
        _ session: ProgramSession,
        injuries: [InjuryProfile]
    ) -> ProgramSession {
        // Partition injuries by phase for different treatment
        let acuteInjuries = injuries.filter { $0.recoveryPhase == .acute }
        let rehabInjuries = injuries.filter { $0.recoveryPhase == .rehab }
        let lightLoadInjuries = injuries.filter { $0.recoveryPhase == .lightLoad }
        let returnToPlayInjuries = injuries.filter { $0.recoveryPhase == .returnToPlay }

        // Acute + rehab + lightLoad: replace exercises
        let replacementInjuries = acuteInjuries + rehabInjuries + lightLoadInjuries
        var adaptedExercises = session.exercises.map { adaptExercise($0, injuries: replacementInjuries) }

        // Apply load/volume multipliers for the most restrictive phase
        let mostRestrictivePhase = mostRestrictive(phases: injuries.map(\.recoveryPhase))
        if let phase = mostRestrictivePhase, phase != .resolved {
            adaptedExercises = adaptedExercises.map { LoadAdjustmentPolicy.applyMultipliers($0, phase: phase) }
        }

        // rehab: prepend full recovery prep block
        var finalExercises = adaptedExercises
        if !rehabInjuries.isEmpty {
            let prepBlock = buildRecoveryPrepBlock(injuries: rehabInjuries)
            finalExercises = prepBlock + finalExercises
        }

        // returnToPlay: no replacement, but prepend recovery prep as warmup
        if !returnToPlayInjuries.isEmpty {
            let warmupBlock = buildRecoveryPrepBlock(injuries: returnToPlayInjuries)
            finalExercises = warmupBlock + finalExercises
        }

        return ProgramSession(
            sessionID:   session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus:       session.focus,
            exercises:   finalExercises
        )
    }

    private static func adaptExercise(
        _ exercise: ProgramExercise,
        injuries: [InjuryProfile]
    ) -> ProgramExercise {
        guard isContraindicated(exercise.exercise, injuries: injuries) else { return exercise }
        let replacement = findReplacement(exercise.exercise, injuries: injuries)
        return ProgramExercise(
            exercise:      replacement.exerciseName,
            variant:       exercise.variant,
            sets:          exercise.sets,
            reps:          exercise.reps,
            percent1RM:    exercise.percent1RM,
            restMinutes:   exercise.restMinutes,
            notes:         exercise.notes,
            bodyweightOnly: exercise.bodyweightOnly
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

    // MARK: - Phase helpers

    private static let phaseOrder: [RecoveryPhase] = [.acute, .rehab, .lightLoad, .returnToPlay, .resolved]

    /// Returns the most restrictive (earliest) phase from a list.
    static func mostRestrictive(phases: [RecoveryPhase]) -> RecoveryPhase? {
        phases.min { (phaseOrder.firstIndex(of: $0) ?? 0) < (phaseOrder.firstIndex(of: $1) ?? 0) }
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
                        exercise:      ex,
                        variant:       nil,
                        sets:          .fixed(2),
                        reps:          .fixed(10),
                        percent1RM:    nil,
                        restMinutes:   1,
                        notes:         "Recovery prep — gentle movement only",
                        bodyweightOnly: nil
                    ))
                }
            }
        }
        return block
    }
}
