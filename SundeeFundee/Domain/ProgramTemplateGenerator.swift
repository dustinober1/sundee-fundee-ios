import Foundation

enum ProgramTemplate: String, CaseIterable, Sendable {
    case strength
    case hypertrophy
    case fullBody
    case linear
    case dup
    case block

    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .hypertrophy: "Hypertrophy"
        case .fullBody: "Full Body"
        case .linear: "Linear"
        case .dup: "Daily Undulating"
        case .block: "Block"
        }
    }

    var icon: String {
        switch self {
        case .strength: "figure.strengthtraining.traditional"
        case .hypertrophy: "figure.highintensity.intervaltraining"
        case .fullBody: "bolt.fill"
        case .linear: "chart.line.uptrend.xyaxis"
        case .dup: "arrow.up.arrow.down"
        case .block: "square.stack.3d.up"
        }
    }

    var subtitle: String {
        switch self {
        case .strength: "Heavy compounds, low reps"
        case .hypertrophy: "Higher volume, muscle growth"
        case .fullBody: "Balanced, all muscle groups"
        case .linear: "Progressive overload, decreasing reps"
        case .dup: "Vary intensity daily"
        case .block: "Accumulation → Intensification → Peaking"
        }
    }

    var descriptionText: String {
        switch self {
        case .strength: "4 weeks · 3x/week"
        case .hypertrophy: "6 weeks · 4x/week"
        case .fullBody: "4 weeks · 3x/week"
        case .linear: "6 weeks · 3x/week"
        case .dup: "4 weeks · 3x/week"
        case .block: "9 weeks · 3x/week"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .strength: 4
        case .hypertrophy: 6
        case .fullBody: 4
        case .linear: 6
        case .dup: 4
        case .block: 9
        }
    }

    var defaultFrequency: Int {
        switch self {
        case .strength: 3
        case .hypertrophy: 4
        case .fullBody: 3
        case .linear: 3
        case .dup: 3
        case .block: 3
        }
    }

    var isPeriodization: Bool {
        switch self {
        case .linear, .dup, .block: true
        case .strength, .hypertrophy, .fullBody: false
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
                buildSession(template: template, week: weekNum, day: dayNum, sessionsPerWeek: sessionsPerWeek, totalWeeks: durationWeeks)
            }
            let phaseID: String? = if template == .block {
                blockPhaseID(week: weekNum, totalWeeks: durationWeeks)
            } else {
                nil
            }
            return ProgramWeek(week: weekNum, phaseID: phaseID, isTestWeek: nil, sessions: sessions)
        }

        let phases = template == .block ? blockPhases(totalWeeks: durationWeeks) : []

        return Program(
            id: UUID().uuidString,
            name: name,
            category: "custom",
            description: "\(template.displayName) program — \(durationWeeks) weeks, \(sessionsPerWeek)x/week",
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek,
            difficulty: "intermediate",
            phases: phases,
            weeks: weeks,
            cycleAdjustmentProfile: nil
        )
    }

    // MARK: - Session Building

    private static func buildSession(
        template: ProgramTemplate,
        week: Int,
        day: Int,
        sessionsPerWeek: Int,
        totalWeeks: Int
    ) -> ProgramSession {
        let focus = sessionFocus(template: template, day: day, sessionsPerWeek: sessionsPerWeek)
        let exercises = sessionExercises(template: template, focus: focus, week: week, day: day, totalWeeks: totalWeeks)

        return ProgramSession(
            sessionID: "w\(week)d\(day)",
            sessionName: sessionName(template: template, day: day, focus: focus),
            sessionType: "strength",
            focus: focus,
            exercises: exercises
        )
    }

    private static func sessionName(template: ProgramTemplate, day: Int, focus: String) -> String {
        switch template {
        case .dup:
            let labels = ["Heavy", "Moderate", "Volume", "Heavy", "Moderate"]
            let label = labels[(day - 1) % labels.count]
            return "Day \(day) — \(label)"
        default:
            return "Day \(day) — \(focus.capitalized) Focus"
        }
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
        case .linear:
            let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
            return focuses[(day - 1) % focuses.count]
        case .dup:
            return "full body"
        case .block:
            let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
            return focuses[(day - 1) % focuses.count]
        }
    }

    private static func sessionExercises(template: ProgramTemplate, focus: String, week: Int, day: Int = 1, totalWeeks: Int = 4) -> [ProgramExercise] {
        switch template {
        case .strength, .hypertrophy, .fullBody:
            let baseExercises = exercisePool(template: template, focus: focus)
            let progressionOffset = Double(week - 1) * 0.02
            return baseExercises.map { (name, sets, reps, basePct, rest, bw) in
                ProgramExercise(
                    exercise: name, variant: nil, sets: .fixed(sets), reps: .fixed(reps),
                    percent1RM: bw ? nil : basePct + progressionOffset,
                    restMinutes: rest, notes: nil, bodyweightOnly: bw
                )
            }
        case .linear:
            return linearExercises(focus: focus, week: week, totalWeeks: totalWeeks)
        case .dup:
            return dupExercises(day: day, week: week)
        case .block:
            return blockExercises(focus: focus, week: week, totalWeeks: totalWeeks)
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
        case .linear, .dup, .block:
            return [] // Handled by dedicated methods in sessionExercises
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

    // MARK: - Linear Periodization

    private static func linearExercises(focus: String, week: Int, totalWeeks: Int) -> [ProgramExercise] {
        let progress = Double(week - 1) / Double(max(totalWeeks - 1, 1))
        let reps = Int(round(10.0 - progress * 7.0))  // 10 → 3
        let pct = 0.60 + progress * 0.28              // 60% → 88%
        let sets = reps <= 3 ? 5 : 4
        let rest = reps <= 5 ? 3.0 : 2.0

        let pool = linearPool(focus: focus)
        return pool.map { (name, bw) in
            ProgramExercise(
                exercise: name, variant: nil, sets: .fixed(sets),
                reps: .fixed(reps),
                percent1RM: bw ? nil : pct,
                restMinutes: rest, notes: nil, bodyweightOnly: bw
            )
        }
    }

    private static func linearPool(focus: String) -> [(String, Bool)] {
        switch focus {
        case "squat":
            return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
        case "bench":
            return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
        case "deadlift":
            return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
        default:
            return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
        }
    }

    // MARK: - Daily Undulating Periodization

    private static func dupExercises(day: Int, week: Int) -> [ProgramExercise] {
        let weekOffset = Double(week - 1) * 0.02

        let dayIndex = (day - 1) % 3
        let (reps, basePct, sets, rest): (Int, Double, Int, Double) = switch dayIndex {
        case 0: (3, 0.85, 5, 3.0)   // Heavy
        case 1: (6, 0.72, 4, 2.0)   // Moderate
        default: (12, 0.60, 3, 1.5) // Volume
        }

        let exercises: [(String, Bool)] = [
            ("Back Squat", false),
            ("Bench Press", false),
            ("Deadlift", false),
            ("Overhead Press", false),
            ("Pull-Up", true),
        ]

        return exercises.map { (name, bw) in
            ProgramExercise(
                exercise: name, variant: nil, sets: .fixed(sets),
                reps: .fixed(reps),
                percent1RM: bw ? nil : basePct + weekOffset,
                restMinutes: rest, notes: nil, bodyweightOnly: bw
            )
        }
    }

    // MARK: - Block Periodization

    private static func blockPhases(totalWeeks: Int) -> [ProgramPhase] {
        let phaseLength = totalWeeks / 3
        return [
            ProgramPhase(id: "accumulation", name: "Accumulation", goal: "Build work capacity with high volume, moderate intensity", weekRange: [1, phaseLength]),
            ProgramPhase(id: "intensification", name: "Intensification", goal: "Increase intensity, reduce volume", weekRange: [phaseLength + 1, phaseLength * 2]),
            ProgramPhase(id: "peaking", name: "Peaking", goal: "Peak strength with low volume, max intensity", weekRange: [phaseLength * 2 + 1, totalWeeks]),
        ]
    }

    private static func blockPhaseID(week: Int, totalWeeks: Int) -> String {
        let phaseLength = totalWeeks / 3
        if week <= phaseLength { return "accumulation" }
        if week <= phaseLength * 2 { return "intensification" }
        return "peaking"
    }

    private static func blockExercises(focus: String, week: Int, totalWeeks: Int) -> [ProgramExercise] {
        let phaseLength = totalWeeks / 3
        let (reps, basePct, sets, rest): (Int, Double, Int, Double)

        if week <= phaseLength {
            // Accumulation: high volume
            let weekInPhase = week - 1
            reps = 10
            basePct = 0.60 + Double(weekInPhase) * 0.02
            sets = 4
            rest = 1.5
        } else if week <= phaseLength * 2 {
            // Intensification: moderate volume, high intensity
            let weekInPhase = week - phaseLength - 1
            reps = 5
            basePct = 0.75 + Double(weekInPhase) * 0.02
            sets = 4
            rest = 2.5
        } else {
            // Peaking: low volume, max intensity
            let weekInPhase = week - phaseLength * 2 - 1
            reps = 2
            basePct = 0.85 + Double(weekInPhase) * 0.02
            sets = 5
            rest = 3.0
        }

        let pool = blockPool(focus: focus)
        return pool.map { (name, bw) in
            ProgramExercise(
                exercise: name, variant: nil, sets: .fixed(sets),
                reps: .fixed(reps),
                percent1RM: bw ? nil : basePct,
                restMinutes: rest, notes: nil, bodyweightOnly: bw
            )
        }
    }

    private static func blockPool(focus: String) -> [(String, Bool)] {
        switch focus {
        case "squat":
            return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
        case "bench":
            return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
        case "deadlift":
            return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
        default:
            return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
        }
    }
}
