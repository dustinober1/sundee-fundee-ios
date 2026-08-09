import Foundation

// MARK: - Program Template Types

/// Available program templates
public enum ProgramTemplate: String, Codable, Sendable, CaseIterable {
    case firstMargarita = "first-margarita"
    case beginnerStrength = "beginner-strength"
    case dumbbellStrength = "dumbbell-strength"
    case glutesCoreConditioning = "glutes-core-conditioning"
    case russianSquat = "russian-squat-program"
    case hundredPushUps = "100-push-ups"

    public var stableID: String { rawValue }

    public var displayName: String {
        switch self {
        case .firstMargarita: return "The First Margarita"
        case .beginnerStrength: return "Beginner Strength"
        case .dumbbellStrength: return "Dumbbell Strength"
        case .glutesCoreConditioning: return "Glutes, Core & Conditioning"
        case .russianSquat: return "Russian Squat"
        case .hundredPushUps: return "100 Push-Ups"
        }
    }

    public var printablePDFURLString: String {
        switch self {
        case .firstMargarita:
            return "https://sundeefundee.com/workout-plans/the-first-margarita-strength-program.pdf"
        case .beginnerStrength:
            return "https://sundeefundee.com/workout-plans/4-week-beginner-strength-plan.pdf"
        case .dumbbellStrength:
            return "https://sundeefundee.com/workout-plans/6-week-dumbbell-strength-plan.pdf"
        case .glutesCoreConditioning:
            return "https://sundeefundee.com/workout-plans/8-week-glutes-core-conditioning-plan.pdf"
        case .russianSquat:
            return "https://sundeefundee.com/workout-plans/6-week-russian-squat-program.pdf"
        case .hundredPushUps:
            return "https://sundeefundee.com/workout-plans/8-week-100-push-ups-program.pdf"
        }
    }

    public var printablePDFURL: URL? {
        URL(string: printablePDFURLString)
    }
}

/// Default settings per template
public struct TemplateDefaults: Sendable {
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
}

/// Template defaults
public let templateDefaults: [ProgramTemplate: TemplateDefaults] = [
    .firstMargarita: TemplateDefaults(durationWeeks: 8, sessionsPerWeek: 3),
    .beginnerStrength: TemplateDefaults(durationWeeks: 4, sessionsPerWeek: 4),
    .dumbbellStrength: TemplateDefaults(durationWeeks: 6, sessionsPerWeek: 4),
    .glutesCoreConditioning: TemplateDefaults(durationWeeks: 8, sessionsPerWeek: 4),
    .russianSquat: TemplateDefaults(durationWeeks: 6, sessionsPerWeek: 3),
    .hundredPushUps: TemplateDefaults(durationWeeks: 8, sessionsPerWeek: 3),
]

// MARK: - Generated Program Types

public struct GeneratedProgramExercise: Sendable {
    public let exercise: String
    public let sets: ExerciseValue
    public let reps: ExerciseValue
    public let percent1RM: Double?
    public let restMinutes: Double
    public let bodyweightOnly: Bool
}

public struct GeneratedProgramSession: Sendable {
    public let sessionId: String
    public let sessionName: String
    public let sessionType: String
    public let focus: String
    public let exercises: [GeneratedProgramExercise]
}

public struct GeneratedProgramWeek: Sendable {
    public let week: Int
    public let phaseId: String?
    public let sessions: [GeneratedProgramSession]
}

public struct GeneratedProgramPhase: Sendable {
    public let id: String
    public let name: String
    public let goal: String
    public let weekRange: [Int]
}

public struct GeneratedProgram: Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
    public let difficulty: String
    public let phases: [GeneratedProgramPhase]
    public let weeks: [GeneratedProgramWeek]
}

struct ProgramSessionSpec: Sendable {
    let name: String
    let focus: String
    let exercises: [GeneratedProgramExercise]
}

// MARK: - Generate Program

/// Generate a program from a template
public func generateProgram(
    template: ProgramTemplate,
    name: String,
    durationWeeks: Int? = nil,
    sessionsPerWeek: Int? = nil
) -> GeneratedProgram {
    switch template {
    case .firstMargarita:
        return generateFirstMargaritaProgram()
    case .beginnerStrength:
        return generateBeginnerStrengthProgram()
    case .dumbbellStrength:
        return generateDumbbellStrengthProgram()
    case .glutesCoreConditioning:
        return generateGlutesCoreConditioningProgram()
    case .russianSquat:
        return generateRussianSquatProgram()
    case .hundredPushUps:
        return generateHundredPushUpsProgram()
    }
}

// MARK: - Return to Training

/// Stable identifier for generated return-to-training programs.
///
/// Deliberately not a `ProgramTemplate` case. That enum is the printable PDF
/// catalog — every case maps to a fixed plan hosted on the website, and the
/// generator tests enforce it. A return-to-training block has no fixed plan to
/// print: its loads are derived per person from the break reason, so it is
/// generated on demand instead of bundled as static content.
public let returnToTrainingProgramID = "return-to-training"

/// Generate a return-to-training program for a non-injury break.
///
/// Week-by-week loads come from `ReturnToTrainingSchedule`, which advances the
/// same ramp the injury path uses, so nothing here is a hand-authored
/// percentage table. Program length follows from the starting point: a more
/// cautious return produces a longer block rather than a steeper climb.
///
/// `percent1RM` carries the ramp's meaning here — a fraction of the person's
/// usual working load, not a tested one-rep max. The return block never asks
/// for a max test.
public func generateReturnToTrainingProgram(
    breakReason: TrainingBreakReason
) -> GeneratedProgram {
    let schedule = ReturnToTrainingSchedule.weeks(for: breakReason)

    let weeks = schedule.map { week in
        GeneratedProgramWeek(
            week: week.week,
            phaseId: "week-\(week.week)",
            sessions: returnToTrainingSessions(for: week).enumerated().map { dayIndex, spec in
                GeneratedProgramSession(
                    sessionId: "w\(week.week)d\(dayIndex + 1)",
                    sessionName: "Day \(dayIndex + 1) - \(spec.name)",
                    sessionType: "strength",
                    focus: spec.focus,
                    exercises: spec.exercises
                )
            }
        )
    }

    let phases = schedule.map { week in
        GeneratedProgramPhase(
            id: "week-\(week.week)",
            name: week.phaseName,
            goal: week.focus,
            weekRange: [week.week, week.week]
        )
    }

    return GeneratedProgram(
        id: returnToTrainingProgramID,
        name: "Return to Training",
        category: "Return to Training",
        description: "A \(schedule.count)-week structured return that starts light and builds back "
            + "week by week, paced by how you're feeling. \(breakReason.programOpening)",
        durationWeeks: schedule.count,
        sessionsPerWeek: 3,
        difficulty: "Beginner",
        phases: phases,
        weeks: weeks
    )
}

/// Three full-body sessions, identical in shape every week so the movements
/// stay familiar; only the load and set caps move.
private func returnToTrainingSessions(for week: ReturnToTrainingWeek) -> [ProgramSessionSpec] {
    let sets = week.workingSets
    let load = week.loadPercent

    return [
        ProgramSessionSpec(name: "Full Body A", focus: "full body", exercises: [
            rampedExercise("Goblet Squat", sets: sets, reps: .range(low: 8, high: 10), percent: load),
            rampedExercise("Dumbbell Bench Press", sets: sets, reps: .range(low: 8, high: 10), percent: load),
            rampedExercise("Seated Cable Row", sets: sets, reps: .range(low: 10, high: 12), percent: load),
            makeExercise("Dead Bug", sets: 2, reps: .text(value: "6/side"), rest: 1.0, bodyweight: true),
            makeExercise("Farmers Carry", sets: 2, reps: .text(value: "30 sec"), rest: 1.0),
        ]),
        ProgramSessionSpec(name: "Hinge + Press", focus: "hinge", exercises: [
            rampedExercise("Dumbbell Romanian Deadlift", sets: sets, reps: .range(low: 8, high: 10), percent: load),
            rampedExercise("Dumbbell Overhead Press", sets: sets, reps: .range(low: 8, high: 10), percent: load),
            rampedExercise("Lat Pulldown", sets: sets, reps: .range(low: 10, high: 12), percent: load),
            makeExercise("Glute Bridge", sets: 2, reps: .range(low: 10, high: 12), rest: 1.0, bodyweight: true),
            makeExercise("Side Plank", sets: 2, reps: .text(value: "20 sec/side"), rest: 1.0, bodyweight: true),
        ]),
        ProgramSessionSpec(name: "Unilateral + Carry", focus: "unilateral", exercises: [
            rampedExercise("Box Step-Up", sets: sets, reps: .text(value: "8/side"), percent: load),
            rampedExercise("Half-Kneeling Dumbbell Press", sets: sets, reps: .text(value: "8/side"), percent: load),
            rampedExercise("Supported Dumbbell Row", sets: sets, reps: .text(value: "10/side"), percent: load),
            makeExercise("Pallof Press", sets: 2, reps: .text(value: "10/side"), rest: 1.0),
            makeExercise("Incline Walk", sets: 1, reps: .text(value: "8 min"), rest: 0.5, bodyweight: true),
        ]),
    ]
}

private func rampedExercise(
    _ name: String,
    sets: Int,
    reps: ExerciseValue,
    percent: Double,
    rest: Double = 1.5
) -> GeneratedProgramExercise {
    GeneratedProgramExercise(
        exercise: name,
        sets: .fixed(value: sets),
        reps: reps,
        percent1RM: percent,
        restMinutes: rest,
        bodyweightOnly: false
    )
}

// MARK: - Private Helpers

func templateDisplayName(_ template: ProgramTemplate) -> String {
    template.displayName
}

func makeExercise(
    _ name: String,
    sets: Int,
    reps: ExerciseValue,
    rest: Double = 1.5,
    bodyweight: Bool = false
) -> GeneratedProgramExercise {
    GeneratedProgramExercise(
        exercise: name,
        sets: .fixed(value: sets),
        reps: reps,
        percent1RM: nil,
        restMinutes: rest,
        bodyweightOnly: bodyweight
    )
}

func makeProgram(
    template: ProgramTemplate,
    category: String,
    description: String,
    difficulty: String,
    weekNames: [String],
    weeklyFocus: [String],
    sessionsForWeek: (Int) -> [ProgramSessionSpec]
) -> GeneratedProgram {
    let weeks = weekNames.indices.map { index in
        let week = index + 1
        let sessions = sessionsForWeek(week).enumerated().map { dayIndex, spec in
            GeneratedProgramSession(
                sessionId: "w\(week)d\(dayIndex + 1)",
                sessionName: "Day \(dayIndex + 1) - \(spec.name)",
                sessionType: "strength",
                focus: spec.focus,
                exercises: spec.exercises
            )
        }
        return GeneratedProgramWeek(week: week, phaseId: "week-\(week)", sessions: sessions)
    }

    let phases = zip(weekNames.indices, weekNames).map { index, name in
        GeneratedProgramPhase(
            id: "week-\(index + 1)",
            name: name,
            goal: weeklyFocus[index],
            weekRange: [index + 1, index + 1]
        )
    }

    return GeneratedProgram(
        id: template.stableID,
        name: template.displayName,
        category: category,
        description: description,
        durationWeeks: weekNames.count,
        sessionsPerWeek: sessionsForWeek(1).count,
        difficulty: difficulty,
        phases: phases,
        weeks: weeks
    )
}

func generateBeginnerStrengthProgram() -> GeneratedProgram {
    let weeks = [
        "Foundation",
        "Pattern Practice",
        "Build Confidence",
        "Recovery Strength",
    ]
    let focuses = [
        "Learn full-body strength patterns with conservative loading.",
        "Repeat the main movement patterns with slightly more intent.",
        "Add confidence through leg press, rows, and controlled circuits.",
        "Taper the block so the final week stays printable and recoverable.",
    ]
    let sessions: [[ProgramSessionSpec]] = [
        [
            ProgramSessionSpec(name: "Full Body A", focus: "full body", exercises: [
                makeExercise("Goblet Squat", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Incline Push-Up", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5, bodyweight: true),
                makeExercise("Seated Cable Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.5),
                makeExercise("Dead Bug", sets: 3, reps: .text(value: "6/side"), rest: 1.0, bodyweight: true),
                makeExercise("Farmers Carry", sets: 3, reps: .text(value: "40 sec"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Hinge + Press", focus: "hinge", exercises: [
                makeExercise("Dumbbell Romanian Deadlift", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Dumbbell Bench Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Lat Pulldown", sets: 3, reps: .range(low: 10, high: 12), rest: 1.5),
                makeExercise("Glute Bridge", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0, bodyweight: true),
                makeExercise("Side Plank", sets: 3, reps: .text(value: "20 sec/side"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "Unilateral Foundation", focus: "unilateral", exercises: [
                makeExercise("Box Step-Up", sets: 3, reps: .text(value: "8/side"), rest: 1.5),
                makeExercise("Half-Kneeling Dumbbell Press", sets: 3, reps: .text(value: "8/side"), rest: 1.5),
                makeExercise("Supported Dumbbell Row", sets: 3, reps: .text(value: "10/side"), rest: 1.5),
                makeExercise("Bodyweight Reverse Lunge", sets: 2, reps: .text(value: "8/side"), rest: 1.0, bodyweight: true),
                makeExercise("Pallof Press", sets: 3, reps: .text(value: "10/side"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Technique Volume", focus: "technique", exercises: [
                makeExercise("Bodyweight Squat", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0, bodyweight: true),
                makeExercise("Dumbbell Floor Press", sets: 3, reps: .range(low: 10, high: 12), rest: 1.5),
                makeExercise("Cable Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.5),
                makeExercise("Kettlebell Deadlift", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Incline Walk", sets: 1, reps: .text(value: "6 min"), rest: 0.5, bodyweight: true),
            ]),
        ],
        [
            ProgramSessionSpec(name: "Box Squat + Push", focus: "squat", exercises: [
                makeExercise("Box Squat", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Push-Up", sets: 3, reps: .range(low: 6, high: 10), rest: 1.5, bodyweight: true),
                makeExercise("Chest-Supported Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.5),
                makeExercise("Step-Down", sets: 2, reps: .text(value: "8/side"), rest: 1.0, bodyweight: true),
                makeExercise("Front Plank", sets: 3, reps: .text(value: "25 sec"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "Bridge + Pulldown", focus: "posterior chain", exercises: [
                makeExercise("Hip Thrust", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                makeExercise("Lat Pulldown", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                makeExercise("Dumbbell Overhead Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Hamstring Curl", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Dead Bug", sets: 3, reps: .text(value: "8/side"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "Split-Stance Strength", focus: "unilateral", exercises: [
                makeExercise("Split Squat", sets: 3, reps: .text(value: "8/side"), rest: 1.5, bodyweight: true),
                makeExercise("One-Arm Dumbbell Row", sets: 3, reps: .text(value: "10/side"), rest: 1.5),
                makeExercise("Dumbbell Romanian Deadlift", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Incline Dumbbell Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Suitcase Carry", sets: 3, reps: .text(value: "30 sec/side"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Carry + Conditioning", focus: "conditioning", exercises: [
                makeExercise("Goblet Squat", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Cable Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Dumbbell Bench Press", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Farmers Carry", sets: 4, reps: .text(value: "30 sec"), rest: 1.0),
                makeExercise("Bike or Walk", sets: 1, reps: .text(value: "8 min"), rest: 0.5, bodyweight: true),
            ]),
        ],
        [
            ProgramSessionSpec(name: "Leg Press + Row", focus: "full body", exercises: [
                makeExercise("Leg Press", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                makeExercise("Seated Cable Row", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                makeExercise("Dumbbell Bench Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Glute Bridge", sets: 3, reps: .range(low: 12, high: 15), rest: 1.0, bodyweight: true),
                makeExercise("Side Plank", sets: 3, reps: .text(value: "25 sec/side"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "RDL + Overhead", focus: "hinge", exercises: [
                makeExercise("Dumbbell Romanian Deadlift", sets: 4, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Dumbbell Overhead Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Lat Pulldown", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                makeExercise("Reverse Lunge", sets: 3, reps: .text(value: "8/side"), rest: 1.0),
                makeExercise("Pallof Press", sets: 3, reps: .text(value: "10/side"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Step-Up Progression", focus: "unilateral", exercises: [
                makeExercise("Dumbbell Step-Up", sets: 3, reps: .text(value: "8/side"), rest: 1.5),
                makeExercise("Incline Push-Up", sets: 3, reps: .range(low: 8, high: 12), rest: 1.0, bodyweight: true),
                makeExercise("Supported Dumbbell Row", sets: 3, reps: .text(value: "10/side"), rest: 1.5),
                makeExercise("Hamstring Curl", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Suitcase Carry", sets: 3, reps: .text(value: "35 sec/side"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Volume Circuit", focus: "conditioning", exercises: [
                makeExercise("Goblet Squat", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Dumbbell Floor Press", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Cable Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Kettlebell Deadlift", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Incline Walk", sets: 1, reps: .text(value: "10 min"), rest: 0.5, bodyweight: true),
            ]),
        ],
        [
            ProgramSessionSpec(name: "Easy Full Body A", focus: "deload", exercises: [
                makeExercise("Goblet Squat", sets: 2, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Incline Push-Up", sets: 2, reps: .range(low: 8, high: 10), rest: 1.0, bodyweight: true),
                makeExercise("Seated Cable Row", sets: 2, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Dead Bug", sets: 2, reps: .text(value: "6/side"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "Easy Hinge + Pull", focus: "deload", exercises: [
                makeExercise("Dumbbell Romanian Deadlift", sets: 2, reps: .range(low: 8, high: 10), rest: 1.5),
                makeExercise("Lat Pulldown", sets: 2, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Glute Bridge", sets: 2, reps: .range(low: 10, high: 12), rest: 1.0, bodyweight: true),
                makeExercise("Side Plank", sets: 2, reps: .text(value: "20 sec/side"), rest: 1.0, bodyweight: true),
            ]),
            ProgramSessionSpec(name: "Easy Unilateral", focus: "deload", exercises: [
                makeExercise("Box Step-Up", sets: 2, reps: .text(value: "8/side"), rest: 1.0),
                makeExercise("Half-Kneeling Dumbbell Press", sets: 2, reps: .text(value: "8/side"), rest: 1.0),
                makeExercise("Supported Dumbbell Row", sets: 2, reps: .text(value: "10/side"), rest: 1.0),
                makeExercise("Pallof Press", sets: 2, reps: .text(value: "10/side"), rest: 1.0),
            ]),
            ProgramSessionSpec(name: "Recovery Strength", focus: "recovery", exercises: [
                makeExercise("Bodyweight Squat", sets: 2, reps: .range(low: 8, high: 10), rest: 1.0, bodyweight: true),
                makeExercise("Dumbbell Floor Press", sets: 2, reps: .range(low: 8, high: 10), rest: 1.0),
                makeExercise("Cable Row", sets: 2, reps: .range(low: 10, high: 12), rest: 1.0),
                makeExercise("Incline Walk", sets: 1, reps: .text(value: "8 min"), rest: 0.5, bodyweight: true),
            ]),
        ],
    ]

    return makeProgram(
        template: .beginnerStrength,
        category: "Strength",
        description: "A 4-week printable base plan for newer lifters, with four full-body sessions per week and no required maxes.",
        difficulty: "Beginner",
        weekNames: weeks,
        weeklyFocus: focuses,
        sessionsForWeek: { sessions[$0 - 1] }
    )
}

func generateDumbbellStrengthProgram() -> GeneratedProgram {
    let weekNames = [
        "Base Volume",
        "Add Reps",
        "Add Sets",
        "Density",
        "Strength Push",
        "Deload",
    ]
    let weeklyFocus = [
        "Establish lower, upper, unilateral, and density days with dumbbells.",
        "Add reps while keeping movement quality high.",
        "Use one more working set on priority dumbbell lifts.",
        "Keep the same movements and shorten rest where appropriate.",
        "Push heavier dumbbell work without chasing maxes.",
        "Reduce total volume so the next block starts fresh.",
    ]

    func reps(_ week: Int, heavy: Bool = false) -> ExerciseValue {
        if week == 6 { return .range(low: 8, high: 10) }
        if week >= 5 && heavy { return .range(low: 6, high: 8) }
        if week >= 3 { return .range(low: 8, high: 12) }
        return .range(low: 6, high: 10)
    }

    func setCount(_ week: Int, base: Int) -> Int {
        if week == 6 { return max(2, base - 1) }
        if week >= 3 { return base + 1 }
        return base
    }

    return makeProgram(
        template: .dumbbellStrength,
        category: "Strength",
        description: "A 6-week printable dumbbell strength block with lower, upper, unilateral, and full-body density days.",
        difficulty: "Intermediate",
        weekNames: weekNames,
        weeklyFocus: weeklyFocus,
        sessionsForWeek: { week in
            [
                ProgramSessionSpec(name: "Lower Strength + Core", focus: "lower body", exercises: [
                    makeExercise("Dumbbell Front Squat", sets: setCount(week, base: 4), reps: reps(week, heavy: true), rest: 1.75),
                    makeExercise("Dumbbell Romanian Deadlift", sets: setCount(week, base: 3), reps: reps(week), rest: 1.5),
                    makeExercise("Dead Bug Pullover", sets: 3, reps: .text(value: "8/side"), rest: 1.0),
                    makeExercise("Side Plank", sets: 3, reps: .text(value: "25 sec/side"), rest: 1.0, bodyweight: true),
                    makeExercise("Incline Walk", sets: 1, reps: .text(value: "\(week == 6 ? 6 : 8) min"), rest: 0.5, bodyweight: true),
                ]),
                ProgramSessionSpec(name: "Upper Push/Pull", focus: "upper body", exercises: [
                    makeExercise("Dumbbell Bench Press", sets: setCount(week, base: 4), reps: reps(week, heavy: true), rest: 1.75),
                    makeExercise("One-Arm Dumbbell Row", sets: setCount(week, base: 4), reps: .text(value: week >= 5 ? "8/side" : "8-12/side"), rest: 1.5),
                    makeExercise("Dumbbell Overhead Press", sets: 3, reps: reps(week), rest: 1.5),
                    makeExercise("Rear Delt Fly", sets: 3, reps: .range(low: 12, high: 15), rest: 1.0),
                    makeExercise("Farmers Carry", sets: 3, reps: .text(value: "40 sec"), rest: 1.0),
                ]),
                ProgramSessionSpec(name: "Lower Unilateral + Glutes", focus: "glutes", exercises: [
                    makeExercise("Dumbbell Split Squat", sets: setCount(week, base: 3), reps: .text(value: week >= 5 ? "6-8/side" : "8-10/side"), rest: 1.5),
                    makeExercise("Dumbbell Hip Thrust", sets: setCount(week, base: 3), reps: reps(week), rest: 1.5),
                    makeExercise("Dumbbell Step-Up", sets: 3, reps: .text(value: "8/side"), rest: 1.25),
                    makeExercise("Suitcase Carry", sets: 3, reps: .text(value: "35 sec/side"), rest: 1.0),
                    makeExercise("Pallof Press", sets: 3, reps: .text(value: "10/side"), rest: 1.0),
                ]),
                ProgramSessionSpec(name: "Full-Body Density", focus: "conditioning", exercises: [
                    makeExercise("Dumbbell Deadlift", sets: setCount(week, base: 3), reps: .range(low: 8, high: 12), rest: 1.0),
                    makeExercise("Dumbbell Floor Press", sets: setCount(week, base: 3), reps: .range(low: 8, high: 12), rest: 1.0),
                    makeExercise("Goblet Squat", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                    makeExercise("Renegade Row", sets: 3, reps: .text(value: "6/side"), rest: 1.0),
                    makeExercise("Bike or Walk", sets: 1, reps: .text(value: "\(week == 6 ? 8 : 10) min"), rest: 0.5, bodyweight: true),
                ]),
            ]
        }
    )
}

func generateGlutesCoreConditioningProgram() -> GeneratedProgram {
    let weekNames = [
        "Base",
        "Build",
        "Volume",
        "Strength",
        "Density",
        "Peak",
        "Consolidate",
        "Deload",
    ]
    let weeklyFocus = [
        "Set the glute, core, and conditioning rhythm.",
        "Add small rep targets without rushing the finishers.",
        "Use more total work on hip thrust and unilateral days.",
        "Prioritize heavier glute strength while keeping core crisp.",
        "Increase density with short, controlled conditioning blocks.",
        "Push the strongest week before tapering.",
        "Hold quality and reduce unnecessary fatigue.",
        "Deload volume while keeping the movement pattern familiar.",
    ]

    func sets(_ week: Int, base: Int) -> Int {
        if week == 8 { return max(2, base - 1) }
        if week >= 3 && week <= 6 { return base + 1 }
        return base
    }

    func finisherMinutes(_ week: Int) -> Int {
        week == 8 ? 6 : min(12, 6 + week)
    }

    return makeProgram(
        template: .glutesCoreConditioning,
        category: "Strength + Conditioning",
        description: "An 8-week printable lower-body plan with glute strength, core training, short finishers, and a deload week.",
        difficulty: "Intermediate",
        weekNames: weekNames,
        weeklyFocus: weeklyFocus,
        sessionsForWeek: { week in
            [
                ProgramSessionSpec(name: "Glute Strength", focus: "glutes", exercises: [
                    makeExercise("Barbell Hip Thrust", sets: sets(week, base: 4), reps: week >= 6 ? .range(low: 6, high: 8) : .range(low: 6, high: 10), rest: 2.0),
                    makeExercise("Romanian Deadlift", sets: sets(week, base: 3), reps: .range(low: 8, high: 10), rest: 1.75),
                    makeExercise("Cable Pull-Through", sets: 3, reps: .range(low: 10, high: 12), rest: 1.25),
                    makeExercise("Abduction Machine", sets: 3, reps: .range(low: 12, high: 15), rest: 1.0),
                    makeExercise("Dead Bug", sets: 3, reps: .text(value: "8/side"), rest: 1.0, bodyweight: true),
                ]),
                ProgramSessionSpec(name: "Upper Body + Core", focus: "upper body", exercises: [
                    makeExercise("Dumbbell Bench Press", sets: 3, reps: .range(low: 8, high: 10), rest: 1.5),
                    makeExercise("Lat Pulldown", sets: 3, reps: .range(low: 8, high: 12), rest: 1.5),
                    makeExercise("Half-Kneeling Dumbbell Press", sets: 3, reps: .text(value: "8/side"), rest: 1.25),
                    makeExercise("Cable Chop", sets: 3, reps: .text(value: "10/side"), rest: 1.0),
                    makeExercise("Front Plank", sets: 3, reps: .text(value: "\(20 + week * 5) sec"), rest: 1.0, bodyweight: true),
                ]),
                ProgramSessionSpec(name: "Glute Volume + Unilateral", focus: "unilateral glutes", exercises: [
                    makeExercise("Bulgarian Split Squat", sets: sets(week, base: 3), reps: .text(value: "8-10/side"), rest: 1.5),
                    makeExercise("Single-Leg Romanian Deadlift", sets: 3, reps: .text(value: "8/side"), rest: 1.25),
                    makeExercise("Dumbbell Step-Up", sets: 3, reps: .text(value: "10/side"), rest: 1.25),
                    makeExercise("Glute Bridge March", sets: 3, reps: .text(value: "10/side"), rest: 1.0, bodyweight: true),
                    makeExercise("Suitcase Carry", sets: 3, reps: .text(value: "35 sec/side"), rest: 1.0),
                ]),
                ProgramSessionSpec(name: "Full Body + Conditioning", focus: "conditioning", exercises: [
                    makeExercise("Goblet Squat", sets: sets(week, base: 3), reps: .range(low: 10, high: 12), rest: 1.0),
                    makeExercise("Kettlebell Deadlift", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                    makeExercise("Push-Up", sets: 3, reps: .range(low: 8, high: 12), rest: 1.0, bodyweight: true),
                    makeExercise("Cable Row", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0),
                    makeExercise("Bike, Sled, or Incline Walk", sets: 1, reps: .text(value: "\(finisherMinutes(week)) min"), rest: 0.5, bodyweight: true),
                ]),
            ]
        }
    )
}

func generateHundredPushUpsProgram() -> GeneratedProgram {
    let weekNames = [
        "Baseline",
        "Groove",
        "Volume Build",
        "Capacity",
        "Density",
        "Endurance",
        "Peak Volume",
        "Taper and Test",
    ]
    let weeklyFocus = [
        "Set repeatable push-up volume and keep every set clean.",
        "Add small reps while balancing pulling and trunk work.",
        "Build total weekly push-up volume without grinding.",
        "Turn volume into longer repeat sets.",
        "Use denser work to make larger sets feel repeatable.",
        "Practice high-quality fatigue management before peaking.",
        "Reach the largest training week before the test taper.",
        "Reduce fatigue and finish with one clean max-rep test.",
    ]

    let weeklyPushUpSets: [[(sets: Int, reps: Int)]] = [
        [(5, 5), (4, 4), (6, 4)],
        [(5, 7), (4, 6), (6, 6)],
        [(6, 8), (5, 7), (7, 7)],
        [(7, 10), (5, 8), (8, 8)],
        [(8, 11), (5, 10), (8, 10)],
        [(8, 13), (6, 11), (9, 11)],
        [(9, 15), (6, 12), (10, 12)],
        [(5, 8), (3, 6), (1, 0)],
    ]

    func pushUpExercise(week: Int, day: Int) -> GeneratedProgramExercise {
        let prescription = weeklyPushUpSets[week - 1][day - 1]
        if week == 8 && day == 3 {
            return makeExercise("Push-Up", sets: 1, reps: .amrap, rest: 3.0, bodyweight: true)
        }
        return makeExercise(
            "Push-Up",
            sets: prescription.sets,
            reps: .fixed(value: prescription.reps),
            rest: day == 2 ? 2.0 : 1.5,
            bodyweight: true
        )
    }

    func volumeSession(week: Int) -> ProgramSessionSpec {
        ProgramSessionSpec(name: week == 1 ? "Baseline Volume" : "Volume Ladders", focus: "push-up volume", exercises: [
            pushUpExercise(week: week, day: 1),
            makeExercise("Prone W Raise", sets: 4, reps: .range(low: 10, high: 15), rest: 1.0, bodyweight: true),
            makeExercise("Scap Push-Up", sets: 3, reps: .range(low: 8, high: 12), rest: 1.0, bodyweight: true),
            makeExercise("Dead Bug", sets: 3, reps: .text(value: "8/side"), rest: 1.0, bodyweight: true),
        ])
    }

    func strengthSession(week: Int) -> ProgramSessionSpec {
        let accessoryReps = week >= 5 ? "12-15" : "10-12"
        return ProgramSessionSpec(name: "Tempo Strength", focus: "push-up strength", exercises: [
            pushUpExercise(week: week, day: 2),
            makeExercise("Tempo Push-Up", sets: 3, reps: .text(value: "3 sec down"), rest: 1.5, bodyweight: true),
            makeExercise("Reverse Snow Angel", sets: 3, reps: .text(value: accessoryReps), rest: 1.0, bodyweight: true),
            makeExercise("Front Plank", sets: 3, reps: .text(value: "\(min(50, 20 + week * 5)) sec"), rest: 1.0, bodyweight: true),
        ])
    }

    func densitySession(week: Int) -> ProgramSessionSpec {
        if week == 8 {
            return ProgramSessionSpec(name: "100 Push-Up Test", focus: "max test", exercises: [
                pushUpExercise(week: week, day: 3),
                makeExercise("Prone W Raise", sets: 3, reps: .range(low: 10, high: 12), rest: 1.0, bodyweight: true),
                makeExercise("Dead Bug", sets: 2, reps: .text(value: "6/side"), rest: 1.0, bodyweight: true),
            ])
        }
        return ProgramSessionSpec(name: "Density Sets", focus: "push-up endurance", exercises: [
            pushUpExercise(week: week, day: 3),
            makeExercise("Close-Grip Push-Up", sets: 3, reps: .range(low: max(4, week + 4), high: week + 7), rest: 1.25, bodyweight: true),
            makeExercise("Superman Pull", sets: 3, reps: .range(low: 12, high: 15), rest: 1.0, bodyweight: true),
            makeExercise("Side Plank", sets: 3, reps: .text(value: "\(min(45, 20 + week * 3)) sec/side"), rest: 1.0, bodyweight: true),
        ])
    }

    return makeProgram(
        template: .hundredPushUps,
        category: "Bodyweight",
        description: "An 8-week bodyweight plan that builds toward a 100-push-up max set with progressive volume, shoulder balance, and a final test.",
        difficulty: "Intermediate",
        weekNames: weekNames,
        weeklyFocus: weeklyFocus,
        sessionsForWeek: { week in
            [
                volumeSession(week: week),
                strengthSession(week: week),
                densitySession(week: week),
            ]
        }
    )
}

func generateRussianSquatProgram() -> GeneratedProgram {
    let weekNames = [
        "Base Volume",
        "Volume Climb",
        "Overreach",
        "Intensity Shift",
        "Peaking",
        "Test Week",
    ]
    let weeklyFocus = [
        "Establish three technically consistent squat days off a conservative training max.",
        "Keep the 80 percent sessions clean while total reps climb.",
        "Survive the highest volume week without turning easy days into grinders.",
        "Shift from volume to heavier exposures while keeping bar speed honest.",
        "Peak with two demanding heavy days buffered by a repeat 80 percent session.",
        "Turn the final week into clean doubles and singles, not max-effort misses.",
    ]
    let weeklySessions: [[ProgramSessionSpec]] = [
        [
            russianSquatSessionSpec(sessionNumber: 1, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 2, focus: "volume", percent1RM: 0.80, sets: 6, reps: 3),
            russianSquatSessionSpec(sessionNumber: 3, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
        ],
        [
            russianSquatSessionSpec(sessionNumber: 4, focus: "volume", percent1RM: 0.80, sets: 6, reps: 4),
            russianSquatSessionSpec(sessionNumber: 5, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 6, focus: "volume", percent1RM: 0.80, sets: 6, reps: 5),
        ],
        [
            russianSquatSessionSpec(sessionNumber: 7, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 8, focus: "volume", percent1RM: 0.80, sets: 6, reps: 6),
            russianSquatSessionSpec(sessionNumber: 9, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
        ],
        [
            russianSquatSessionSpec(sessionNumber: 10, focus: "heavy", percent1RM: 0.85, sets: 5, reps: 5),
            russianSquatSessionSpec(sessionNumber: 11, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 12, focus: "peak", percent1RM: 0.90, sets: 4, reps: 4),
        ],
        [
            russianSquatSessionSpec(sessionNumber: 13, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 14, focus: "peak", percent1RM: 0.95, sets: 3, reps: 3),
            russianSquatSessionSpec(sessionNumber: 15, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
        ],
        [
            russianSquatSessionSpec(sessionNumber: 16, focus: "peak", percent1RM: 1.00, sets: 2, reps: 2),
            russianSquatSessionSpec(sessionNumber: 17, focus: "technique", percent1RM: 0.80, sets: 6, reps: 2),
            russianSquatSessionSpec(sessionNumber: 18, focus: "peak", percent1RM: 1.05, sets: 1, reps: 1),
        ],
    ]

    return makeProgram(
        template: .russianSquat,
        category: "Strength",
        description: "A 6-week squat peaking block with three back squat sessions per week built from the published Russian Squat table.",
        difficulty: "Advanced",
        weekNames: weekNames,
        weeklyFocus: weeklyFocus,
        sessionsForWeek: { weeklySessions[$0 - 1] }
    )
}

private func russianSquatSessionSpec(
    sessionNumber: Int,
    focus: String,
    percent1RM: Double,
    sets: Int,
    reps: Int
) -> ProgramSessionSpec {
    ProgramSessionSpec(
        name: "Session \(sessionNumber)",
        focus: focus,
        exercises: [
            GeneratedProgramExercise(
                exercise: "Back Squat",
                sets: .fixed(value: sets),
                reps: .fixed(value: reps),
                percent1RM: percent1RM,
                restMinutes: 4.0,
                bodyweightOnly: false
            ),
        ]
    )
}
