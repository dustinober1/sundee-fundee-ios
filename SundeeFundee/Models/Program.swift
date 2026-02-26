import Foundation

// MARK: - Program (Codable — sourced from bundled JSON or CloudKit Public DB)

struct Program: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let phases: [ProgramPhase]
    let weeks: [ProgramWeek]
    let cycleAdjustmentProfile: ProgramCycleAdjustmentProfile?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Program, rhs: Program) -> Bool { lhs.id == rhs.id }
}

struct ProgramPhase: Codable, Identifiable {
    let id: String
    let name: String
    let goal: String
    let weekRange: [Int]
}

struct ProgramWeek: Codable {
    let week: Int
    let phaseID: String?
    let isTestWeek: Bool?
    let sessions: [ProgramSession]

    enum CodingKeys: String, CodingKey {
        case week, phaseID = "phaseId", isTestWeek, sessions
    }
}

struct ProgramSession: Codable, Identifiable {
    let sessionID: String
    let sessionName: String
    let sessionType: String
    let focus: String
    let exercises: [ProgramExercise]

    var id: String { sessionID }

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId", sessionName, sessionType, focus, exercises
    }
}

struct ProgramExercise: Codable {
    let exercise: String
    let variant: String?
    let sets: ExerciseValue
    let reps: ExerciseValue
    let percent1RM: Double?
    let restMinutes: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case exercise, variant, sets, reps
        case percent1RM = "percent1RM"
        case restMinutes, notes
    }
}

// MARK: - ExerciseValue

enum ExerciseValue: Codable, CustomStringConvertible {
    case fixed(Int)
    case amrap
    case range(Int, Int)
    case text(String)

    var description: String {
        switch self {
        case .fixed(let n): return "\(n)"
        case .amrap: return "AMRAP"
        case .range(let lo, let hi): return "\(lo)–\(hi)"
        case .text(let t): return t
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let n = try? container.decode(Int.self) {
            self = .fixed(n); return
        }
        if let d = try? container.decode(Double.self) {
            self = .fixed(Int(d)); return
        }
        if let s = try? container.decode(String.self) {
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased() == "AMRAP" { self = .amrap; return }
            if trimmed.contains("-") {
                let parts = trimmed.split(separator: "-")
                if parts.count == 2,
                   let lo = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                   let hi = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    self = .range(lo, hi); return
                }
            }
            if let n = Int(trimmed) { self = .fixed(n); return }
            self = .text(s); return
        }
        if let arr = try? container.decode([Int].self), arr.count == 2 {
            self = .range(arr[0], arr[1]); return
        }
        self = .fixed(0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let n): try container.encode(n)
        case .amrap: try container.encode("AMRAP")
        case .range(let lo, let hi): try container.encode([lo, hi])
        case .text(let t): try container.encode(t)
        }
    }
}

// MARK: - Cycle adjustment

struct ProgramCycleAdjustmentProfile: Codable {
    let fallbackPhase: String
    let lowConfidenceScale: Double
    let phaseSettings: [String: ProgramPhaseAdjustmentSettings]

    init(
        fallbackPhase: String = "follicular",
        lowConfidenceScale: Double = 0.7,
        phaseSettings: [String: ProgramPhaseAdjustmentSettings] = [:]
    ) {
        self.fallbackPhase = fallbackPhase
        self.lowConfidenceScale = lowConfidenceScale
        self.phaseSettings = phaseSettings
    }
}

struct ProgramPhaseAdjustmentSettings: Codable {
    let loadMultiplier: Double
    let setsMultiplier: Double
    let repsMultiplier: Double

    init(loadMultiplier: Double = 1.0, setsMultiplier: Double = 1.0, repsMultiplier: Double = 1.0) {
        self.loadMultiplier = loadMultiplier
        self.setsMultiplier = setsMultiplier
        self.repsMultiplier = repsMultiplier
    }
}
