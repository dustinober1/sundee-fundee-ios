import Foundation

// MARK: - Program Template Types

/// Available program templates
public enum ProgramTemplate: String, Codable, Sendable, CaseIterable {
    case firstMargarita
    case strength
    case hypertrophy
    case fullBody
    case linear
    case dup
    case block
}

/// Default settings per template
public struct TemplateDefaults: Sendable {
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
}

/// Template defaults
public let templateDefaults: [ProgramTemplate: TemplateDefaults] = [
    .firstMargarita: TemplateDefaults(durationWeeks: 8, sessionsPerWeek: 3),
    .strength:    TemplateDefaults(durationWeeks: 4, sessionsPerWeek: 3),
    .hypertrophy: TemplateDefaults(durationWeeks: 6, sessionsPerWeek: 4),
    .fullBody:    TemplateDefaults(durationWeeks: 4, sessionsPerWeek: 3),
    .linear:      TemplateDefaults(durationWeeks: 6, sessionsPerWeek: 3),
    .dup:         TemplateDefaults(durationWeeks: 4, sessionsPerWeek: 3),
    .block:       TemplateDefaults(durationWeeks: 9, sessionsPerWeek: 3),
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

// MARK: - Generate Program

/// Generate a program from a template
public func generateProgram(
    template: ProgramTemplate,
    name: String,
    durationWeeks: Int? = nil,
    sessionsPerWeek: Int? = nil
) -> GeneratedProgram {
    // Hand-crafted programs bypass the generic generation path
    if template == .firstMargarita {
        return generateFirstMargaritaProgram()
    }

    guard let defaults = templateDefaults[template] else {
        return GeneratedProgram(
            id: "template-\(template.rawValue)-\(Int(Date().timeIntervalSince1970 * 1000))",
            name: name,
            category: "custom",
            description: "\(name) program",
            durationWeeks: durationWeeks ?? 4,
            sessionsPerWeek: sessionsPerWeek ?? 3,
            difficulty: "intermediate",
            phases: [],
            weeks: []
        )
    }
    let totalWeeks = durationWeeks ?? defaults.durationWeeks
    let totalSessions = sessionsPerWeek ?? defaults.sessionsPerWeek

    let phases: [GeneratedProgramPhase] = template == .block ? blockPhases(totalWeeks) : []

    let weeks = (1...totalWeeks).map { weekNum in
        let sessions = (1...totalSessions).map { dayNum in
            buildSession(template: template, week: weekNum, day: dayNum, sessionsPerWeek: totalSessions, totalWeeks: totalWeeks)
        }
        let phaseId = template == .block ? blockPhaseId(weekNum, totalWeeks: totalWeeks) : nil
        return GeneratedProgramWeek(week: weekNum, phaseId: phaseId, sessions: sessions)
    }

    let displayName = templateDisplayName(template)

    return GeneratedProgram(
        id: "template-\(template.rawValue)-\(Int(Date().timeIntervalSince1970 * 1000))",
        name: name,
        category: "custom",
        description: "\(displayName) program — \(totalWeeks) weeks, \(totalSessions)x/week",
        durationWeeks: totalWeeks,
        sessionsPerWeek: totalSessions,
        difficulty: "intermediate",
        phases: phases,
        weeks: weeks
    )
}

// MARK: - Private Helpers

private func templateDisplayName(_ template: ProgramTemplate) -> String {
    switch template {
    case .firstMargarita: return "The First Margarita"
    case .strength:    return "Strength"
    case .hypertrophy: return "Hypertrophy"
    case .fullBody:    return "Full Body"
    case .linear:      return "Linear"
    case .dup:         return "Daily Undulating"
    case .block:       return "Block"
    }
}

private func buildSession(template: ProgramTemplate, week: Int, day: Int, sessionsPerWeek: Int, totalWeeks: Int) -> GeneratedProgramSession {
    let focus = sessionFocus(template: template, day: day)
    let sessionName = buildSessionName(template: template, day: day, focus: focus)
    let exercises = sessionExercises(template: template, focus: focus, week: week, day: day, totalWeeks: totalWeeks)

    return GeneratedProgramSession(sessionId: "w\(week)d\(day)", sessionName: sessionName, sessionType: "strength", focus: focus, exercises: exercises)
}

private func buildSessionName(template: ProgramTemplate, day: Int, focus: String) -> String {
    if template == .dup {
        let labels = ["Heavy", "Moderate", "Volume", "Heavy", "Moderate"]
        let label = labels[(day - 1) % labels.count]
        return "Day \(day) — \(label)"
    }
    return "Day \(day) — \(focus.prefix(1).uppercased() + focus.dropFirst()) Focus"
}

private func sessionFocus(template: ProgramTemplate, day: Int) -> String {
    let idx = day - 1
    switch template {
    case .firstMargarita, .strength, .linear, .block:
        let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
        return focuses[idx % focuses.count]
    case .hypertrophy:
        let focuses = ["upper", "lower", "push", "pull", "upper"]
        return focuses[idx % focuses.count]
    case .fullBody:
        let focuses = ["full body a", "full body b", "full body c", "full body a", "full body b"]
        return focuses[idx % focuses.count]
    case .dup:
        return "full body"
    }
}

// Exercise tuple: (name, sets, reps, basePct1RM, restMinutes, bodyweightOnly)
private typealias ExerciseTuple = (String, Int, Int, Double, Double, Bool)

private func sessionExercises(template: ProgramTemplate, focus: String, week: Int, day: Int, totalWeeks: Int) -> [GeneratedProgramExercise] {
    switch template {
    case .firstMargarita:
        return [] // Hand-crafted; generateProgram short-circuits before reaching here
    case .strength, .hypertrophy, .fullBody:
        let pool = exercisePool(template: template, focus: focus)
        let progressionOffset = Double(week - 1) * 0.02
        return pool.map { (name, sets, reps, basePct, rest, bw) in
            GeneratedProgramExercise(
                exercise: name,
                sets: .fixed(value: sets),
                reps: reps == 0 ? .text(value: "hold") : .fixed(value: reps),
                percent1RM: bw ? nil : basePct + progressionOffset,
                restMinutes: rest,
                bodyweightOnly: bw
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

private func exercisePool(template: ProgramTemplate, focus: String) -> [ExerciseTuple] {
    switch template {
    case .strength: return strengthExercises(focus: focus)
    case .hypertrophy: return hypertrophyExercises(focus: focus)
    case .fullBody: return fullBodyExercises(focus: focus)
    default: return []
    }
}

private func strengthExercises(focus: String) -> [ExerciseTuple] {
    switch focus {
    case "squat":
        return [("Back Squat", 4, 5, 0.78, 3.0, false), ("Front Squat", 3, 5, 0.68, 2.5, false), ("Leg Press", 3, 8, 0.0, 2.0, false), ("Walking Lunge", 3, 10, 0.0, 1.5, false), ("Calf Raise", 3, 12, 0.0, 1.0, false)]
    case "bench":
        return [("Bench Press", 4, 5, 0.78, 3.0, false), ("Incline Dumbbell Press", 3, 8, 0.0, 2.0, false), ("Barbell Row", 4, 5, 0.72, 2.5, false), ("Dumbbell Lateral Raise", 3, 12, 0.0, 1.0, false), ("Tricep Pushdown", 3, 10, 0.0, 1.0, false)]
    case "deadlift":
        return [("Deadlift", 4, 5, 0.78, 3.0, false), ("Romanian Deadlift", 3, 8, 0.65, 2.0, false), ("Pull-Up", 3, 8, 0.0, 2.0, true), ("Hip Thrust", 3, 10, 0.0, 1.5, false), ("Plank", 3, 0, 0.0, 1.0, true)]
    default:
        return [("Overhead Press", 4, 5, 0.72, 3.0, false), ("Push Press", 3, 5, 0.68, 2.5, false), ("Lateral Raise", 3, 12, 0.0, 1.0, false), ("Face Pull", 3, 15, 0.0, 1.0, false), ("Dip", 3, 8, 0.0, 1.5, true)]
    }
}

private func hypertrophyExercises(focus: String) -> [ExerciseTuple] {
    switch focus {
    case "upper":
        return [("Bench Press", 4, 10, 0.65, 2.0, false), ("Dumbbell Row", 4, 10, 0.0, 1.5, false), ("Overhead Press", 3, 10, 0.62, 1.5, false), ("Lat Pulldown", 3, 12, 0.0, 1.5, false), ("Bicep Curl", 3, 12, 0.0, 1.0, false), ("Tricep Extension", 3, 12, 0.0, 1.0, false)]
    case "lower":
        return [("Back Squat", 4, 10, 0.65, 2.0, false), ("Romanian Deadlift", 3, 10, 0.62, 2.0, false), ("Leg Press", 3, 12, 0.0, 1.5, false), ("Leg Curl", 3, 12, 0.0, 1.0, false), ("Calf Raise", 4, 15, 0.0, 1.0, false), ("Plank", 3, 0, 0.0, 1.0, true)]
    case "push":
        return [("Incline Bench Press", 4, 10, 0.62, 2.0, false), ("Dumbbell Fly", 3, 12, 0.0, 1.0, false), ("Overhead Press", 3, 10, 0.60, 1.5, false), ("Lateral Raise", 3, 15, 0.0, 1.0, false), ("Tricep Pushdown", 3, 12, 0.0, 1.0, false)]
    default: // pull
        return [("Barbell Row", 4, 10, 0.65, 2.0, false), ("Pull-Up", 3, 8, 0.0, 2.0, true), ("Face Pull", 3, 15, 0.0, 1.0, false), ("Hammer Curl", 3, 12, 0.0, 1.0, false), ("Shrug", 3, 12, 0.0, 1.0, false)]
    }
}

private func fullBodyExercises(focus: String) -> [ExerciseTuple] {
    switch focus {
    case "full body a":
        return [("Back Squat", 3, 8, 0.70, 2.5, false), ("Bench Press", 3, 8, 0.70, 2.0, false), ("Barbell Row", 3, 8, 0.68, 2.0, false), ("Overhead Press", 3, 10, 0.62, 1.5, false), ("Plank", 3, 0, 0.0, 1.0, true)]
    case "full body b":
        return [("Deadlift", 3, 6, 0.75, 3.0, false), ("Incline Dumbbell Press", 3, 10, 0.0, 1.5, false), ("Pull-Up", 3, 8, 0.0, 2.0, true), ("Walking Lunge", 3, 10, 0.0, 1.5, false), ("Bicep Curl", 3, 12, 0.0, 1.0, false)]
    default: // full body c
        return [("Front Squat", 3, 8, 0.65, 2.5, false), ("Dumbbell Bench Press", 3, 10, 0.0, 1.5, false), ("Seated Row", 3, 10, 0.0, 1.5, false), ("Hip Thrust", 3, 10, 0.0, 1.5, false), ("Lateral Raise", 3, 12, 0.0, 1.0, false)]
    }
}

private func linearExercises(focus: String, week: Int, totalWeeks: Int) -> [GeneratedProgramExercise] {
    let progress = Double(week - 1) / Double(max(totalWeeks - 1, 1))
    let reps = Int(round(10 - progress * 7))
    let pct = 0.60 + progress * 0.28
    let sets = reps <= 3 ? 5 : 4
    let rest = reps <= 5 ? 3.0 : 2.0

    return linearPool(focus: focus).map { (name, bw) in
        GeneratedProgramExercise(exercise: name, sets: .fixed(value: sets), reps: .fixed(value: reps),
                                  percent1RM: bw ? nil : pct, restMinutes: rest, bodyweightOnly: bw)
    }
}

private func linearPool(focus: String) -> [(String, Bool)] {
    switch focus {
    case "squat":    return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
    case "bench":    return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
    case "deadlift": return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
    default:         return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
    }
}

private func dupExercises(day: Int, week: Int) -> [GeneratedProgramExercise] {
    let weekOffset = Double(week - 1) * 0.02
    let dayIndex = (day - 1) % 3

    let reps: Int, basePct: Double, sets: Int, rest: Double
    switch dayIndex {
    case 0: reps = 3; basePct = 0.85; sets = 5; rest = 3.0
    case 1: reps = 6; basePct = 0.72; sets = 4; rest = 2.0
    default: reps = 12; basePct = 0.60; sets = 3; rest = 1.5
    }

    let exercises: [(String, Bool)] = [
        ("Back Squat", false), ("Bench Press", false), ("Deadlift", false),
        ("Overhead Press", false), ("Pull-Up", true),
    ]

    return exercises.map { (name, bw) in
        GeneratedProgramExercise(exercise: name, sets: .fixed(value: sets), reps: .fixed(value: reps),
                                  percent1RM: bw ? nil : basePct + weekOffset, restMinutes: rest, bodyweightOnly: bw)
    }
}

private func blockPhaseId(_ week: Int, totalWeeks: Int) -> String {
    let phaseLength = totalWeeks / 3
    if week <= phaseLength { return "accumulation" }
    if week <= phaseLength * 2 { return "intensification" }
    return "peaking"
}

private func blockPhases(_ totalWeeks: Int) -> [GeneratedProgramPhase] {
    let phaseLength = totalWeeks / 3
    return [
        GeneratedProgramPhase(id: "accumulation", name: "Accumulation", goal: "Build work capacity with high volume, moderate intensity", weekRange: [1, phaseLength]),
        GeneratedProgramPhase(id: "intensification", name: "Intensification", goal: "Increase intensity, reduce volume", weekRange: [phaseLength + 1, phaseLength * 2]),
        GeneratedProgramPhase(id: "peaking", name: "Peaking", goal: "Peak strength with low volume, max intensity", weekRange: [phaseLength * 2 + 1, totalWeeks]),
    ]
}

private func blockExercises(focus: String, week: Int, totalWeeks: Int) -> [GeneratedProgramExercise] {
    let phaseLength = totalWeeks / 3

    let reps: Int, basePct: Double, sets: Int, rest: Double
    if week <= phaseLength {
        let weekInPhase = week - 1
        reps = 10; basePct = 0.60 + Double(weekInPhase) * 0.02; sets = 4; rest = 1.5
    } else if week <= phaseLength * 2 {
        let weekInPhase = week - phaseLength - 1
        reps = 5; basePct = 0.75 + Double(weekInPhase) * 0.02; sets = 4; rest = 2.5
    } else {
        let weekInPhase = week - phaseLength * 2 - 1
        reps = 2; basePct = 0.85 + Double(weekInPhase) * 0.02; sets = 5; rest = 3.0
    }

    return blockPool(focus: focus).map { (name, bw) in
        GeneratedProgramExercise(exercise: name, sets: .fixed(value: sets), reps: .fixed(value: reps),
                                  percent1RM: bw ? nil : basePct, restMinutes: rest, bodyweightOnly: bw)
    }
}

private func blockPool(focus: String) -> [(String, Bool)] {
    switch focus {
    case "squat":    return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
    case "bench":    return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
    case "deadlift": return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
    default:         return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
    }
}
