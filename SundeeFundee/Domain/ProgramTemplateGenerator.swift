import Foundation

enum ProgramTemplate: String, CaseIterable, Sendable {
    case strength
    case hypertrophy
    case fullBody

    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .hypertrophy: "Hypertrophy"
        case .fullBody: "Full Body"
        }
    }

    var icon: String {
        switch self {
        case .strength: "figure.strengthtraining.traditional"
        case .hypertrophy: "figure.highintensity.intervaltraining"
        case .fullBody: "bolt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .strength: "Heavy compounds, low reps"
        case .hypertrophy: "Higher volume, muscle growth"
        case .fullBody: "Balanced, all muscle groups"
        }
    }

    var descriptionText: String {
        switch self {
        case .strength: "4 weeks · 3x/week"
        case .hypertrophy: "6 weeks · 4x/week"
        case .fullBody: "4 weeks · 3x/week"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .strength: 4
        case .hypertrophy: 6
        case .fullBody: 4
        }
    }

    var defaultFrequency: Int {
        switch self {
        case .strength: 3
        case .hypertrophy: 4
        case .fullBody: 3
        }
    }
}

enum ProgramTemplateGenerator {

    static func generate(
        template: ProgramTemplate,
        name: String,
        durationWeeks: Int,
        sessionsPerWeek: Int
    ) -> Program {
        let weeks = (1...durationWeeks).map { weekNum in
            let sessions = (1...sessionsPerWeek).map { dayNum in
                buildSession(template: template, week: weekNum, day: dayNum, sessionsPerWeek: sessionsPerWeek)
            }
            return ProgramWeek(week: weekNum, phaseID: nil, isTestWeek: nil, sessions: sessions)
        }

        return Program(
            id: UUID().uuidString,
            name: name,
            category: "custom",
            description: "\(template.displayName) program — \(durationWeeks) weeks, \(sessionsPerWeek)x/week",
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek,
            difficulty: "intermediate",
            phases: [],
            weeks: weeks,
            cycleAdjustmentProfile: nil
        )
    }

    // MARK: - Session Building

    private static func buildSession(
        template: ProgramTemplate,
        week: Int,
        day: Int,
        sessionsPerWeek: Int
    ) -> ProgramSession {
        let focus = sessionFocus(template: template, day: day, sessionsPerWeek: sessionsPerWeek)
        let exercises = sessionExercises(template: template, focus: focus, week: week)

        return ProgramSession(
            sessionID: "w\(week)d\(day)",
            sessionName: "Day \(day) — \(focus.capitalized) Focus",
            sessionType: "strength",
            focus: focus,
            exercises: exercises
        )
    }

    private static func sessionFocus(template: ProgramTemplate, day: Int, sessionsPerWeek: Int) -> String {
        switch template {
        case .strength:
            let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
            return focuses[(day - 1) % focuses.count]
        case .hypertrophy:
            let focuses = ["upper", "lower", "push", "pull", "upper"]
            return focuses[(day - 1) % focuses.count]
        case .fullBody:
            let focuses = ["full body a", "full body b", "full body c", "full body a", "full body b"]
            return focuses[(day - 1) % focuses.count]
        }
    }

    private static func sessionExercises(template: ProgramTemplate, focus: String, week: Int) -> [ProgramExercise] {
        let baseExercises = exercisePool(template: template, focus: focus)
        let progressionOffset = Double(week - 1) * 0.02 // +2% per week

        return baseExercises.map { (name, sets, reps, basePct, rest, bw) in
            ProgramExercise(
                exercise: name,
                variant: nil,
                sets: .fixed(sets),
                reps: .fixed(reps),
                percent1RM: bw ? nil : basePct + progressionOffset,
                restMinutes: rest,
                notes: nil,
                bodyweightOnly: bw
            )
        }
    }

    // MARK: - Exercise Pools

    // Returns: (name, sets, reps, basePct1RM, restMinutes, bodyweightOnly)
    private static func exercisePool(
        template: ProgramTemplate,
        focus: String
    ) -> [(String, Int, Int, Double, Double, Bool)] {
        switch template {
        case .strength:
            return strengthExercises(focus: focus)
        case .hypertrophy:
            return hypertrophyExercises(focus: focus)
        case .fullBody:
            return fullBodyExercises(focus: focus)
        }
    }

    private static func strengthExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "squat":
            return [
                ("Back Squat", 4, 5, 0.78, 3.0, false),
                ("Front Squat", 3, 5, 0.68, 2.5, false),
                ("Leg Press", 3, 8, 0.0, 2.0, false),
                ("Walking Lunge", 3, 10, 0.0, 1.5, false),
                ("Calf Raise", 3, 12, 0.0, 1.0, false),
            ]
        case "bench":
            return [
                ("Bench Press", 4, 5, 0.78, 3.0, false),
                ("Incline Dumbbell Press", 3, 8, 0.0, 2.0, false),
                ("Barbell Row", 4, 5, 0.72, 2.5, false),
                ("Dumbbell Lateral Raise", 3, 12, 0.0, 1.0, false),
                ("Tricep Pushdown", 3, 10, 0.0, 1.0, false),
            ]
        case "deadlift":
            return [
                ("Deadlift", 4, 5, 0.78, 3.0, false),
                ("Romanian Deadlift", 3, 8, 0.65, 2.0, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Hip Thrust", 3, 10, 0.0, 1.5, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        default:
            return [
                ("Overhead Press", 4, 5, 0.72, 3.0, false),
                ("Push Press", 3, 5, 0.68, 2.5, false),
                ("Lateral Raise", 3, 12, 0.0, 1.0, false),
                ("Face Pull", 3, 15, 0.0, 1.0, false),
                ("Dip", 3, 8, 0.0, 1.5, true),
            ]
        }
    }

    private static func hypertrophyExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "upper":
            return [
                ("Bench Press", 4, 10, 0.65, 2.0, false),
                ("Dumbbell Row", 4, 10, 0.0, 1.5, false),
                ("Overhead Press", 3, 10, 0.62, 1.5, false),
                ("Lat Pulldown", 3, 12, 0.0, 1.5, false),
                ("Bicep Curl", 3, 12, 0.0, 1.0, false),
                ("Tricep Extension", 3, 12, 0.0, 1.0, false),
            ]
        case "lower":
            return [
                ("Back Squat", 4, 10, 0.65, 2.0, false),
                ("Romanian Deadlift", 3, 10, 0.62, 2.0, false),
                ("Leg Press", 3, 12, 0.0, 1.5, false),
                ("Leg Curl", 3, 12, 0.0, 1.0, false),
                ("Calf Raise", 4, 15, 0.0, 1.0, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        case "push":
            return [
                ("Incline Bench Press", 4, 10, 0.62, 2.0, false),
                ("Dumbbell Fly", 3, 12, 0.0, 1.0, false),
                ("Overhead Press", 3, 10, 0.60, 1.5, false),
                ("Lateral Raise", 3, 15, 0.0, 1.0, false),
                ("Tricep Pushdown", 3, 12, 0.0, 1.0, false),
            ]
        default: // pull
            return [
                ("Barbell Row", 4, 10, 0.65, 2.0, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Face Pull", 3, 15, 0.0, 1.0, false),
                ("Hammer Curl", 3, 12, 0.0, 1.0, false),
                ("Shrug", 3, 12, 0.0, 1.0, false),
            ]
        }
    }

    private static func fullBodyExercises(focus: String) -> [(String, Int, Int, Double, Double, Bool)] {
        switch focus {
        case "full body a":
            return [
                ("Back Squat", 3, 8, 0.70, 2.5, false),
                ("Bench Press", 3, 8, 0.70, 2.0, false),
                ("Barbell Row", 3, 8, 0.68, 2.0, false),
                ("Overhead Press", 3, 10, 0.62, 1.5, false),
                ("Plank", 3, 0, 0.0, 1.0, true),
            ]
        case "full body b":
            return [
                ("Deadlift", 3, 6, 0.75, 3.0, false),
                ("Incline Dumbbell Press", 3, 10, 0.0, 1.5, false),
                ("Pull-Up", 3, 8, 0.0, 2.0, true),
                ("Walking Lunge", 3, 10, 0.0, 1.5, false),
                ("Bicep Curl", 3, 12, 0.0, 1.0, false),
            ]
        default: // full body c
            return [
                ("Front Squat", 3, 8, 0.65, 2.5, false),
                ("Dumbbell Bench Press", 3, 10, 0.0, 1.5, false),
                ("Seated Row", 3, 10, 0.0, 1.5, false),
                ("Hip Thrust", 3, 10, 0.0, 1.5, false),
                ("Lateral Raise", 3, 12, 0.0, 1.0, false),
            ]
        }
    }
}
