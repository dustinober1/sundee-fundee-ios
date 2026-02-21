import Foundation

struct ProgramV2: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let phases: [ProgramPhase]
    let weeks: [ProgramWeek]
}

struct ProgramPhase: Codable, Identifiable {
    let id: String
    let name: String
    let goal: String
    let weekRange: [Int]
}

struct ProgramWeek: Codable {
    let week: Int
    let phaseId: String?
    let isTestWeek: Bool?
    let sessions: [ProgramSession]
}

struct ProgramSession: Codable, Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let sessionName: String
    let sessionType: String
    let focus: String
    let exercises: [ProgramExercise]
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
        case exercise, variant, sets, reps, percent1RM, restMinutes, notes
    }
}

/// Handles values that can be an Int, String ("AMRAP"), or Array [min, max]
enum ExerciseValue: Codable {
    case fixed(Int)
    case amrap
    case range(Int, Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .fixed(intVal)
        } else if let strVal = try? container.decode(String.self), strVal.uppercased() == "AMRAP" {
            self = .amrap
        } else if let arrVal = try? container.decode([Int].self), arrVal.count == 2 {
            self = .range(arrVal[0], arrVal[1])
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected Int, \"AMRAP\", or [Int, Int]"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let val): try container.encode(val)
        case .amrap: try container.encode("AMRAP")
        case .range(let min, let max): try container.encode([min, max])
        }
    }

    var displayString: String {
        switch self {
        case .fixed(let val): return "\(val)"
        case .amrap: return "AMRAP"
        case .range(let min, let max): return "\(min)-\(max)"
        }
    }
}
