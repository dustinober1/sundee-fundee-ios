import Foundation
import CloudKit

// MARK: - Program

enum ProgramDecodingError: Error {
    case missingFields
}

struct Program: Codable, Identifiable, Sendable, Hashable {
    static func == (lhs: Program, rhs: Program) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let phases: [ProgramPhase]
    let cycleAdjustmentProfile: ProgramCycleAdjustmentProfile?
    let weeks: [ProgramWeek]

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, durationWeeks, sessionsPerWeek
        case difficulty, phases, cycleAdjustmentProfile, weeks
    }

    init(
        id: String, name: String, category: String, description: String,
        durationWeeks: Int, sessionsPerWeek: Int, difficulty: String,
        phases: [ProgramPhase] = [], cycleAdjustmentProfile: ProgramCycleAdjustmentProfile? = nil,
        weeks: [ProgramWeek]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.durationWeeks = durationWeeks
        self.sessionsPerWeek = sessionsPerWeek
        self.difficulty = difficulty
        self.phases = phases
        self.cycleAdjustmentProfile = cycleAdjustmentProfile
        self.weeks = weeks
    }

    /// Decode a Program from a CloudKit record with individual fields.
    init(record: CKRecord) throws {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String,
              let category = record["category"] as? String,
              let description = record["description"] as? String,
              let durationWeeks = record["durationWeeks"] as? Int,
              let sessionsPerWeek = record["sessionsPerWeek"] as? Int,
              let difficulty = record["difficulty"] as? String,
              let weeksJSON = record["weeksJSON"] as? String,
              let weeksData = weeksJSON.data(using: .utf8) else {
            throw ProgramDecodingError.missingFields
        }

        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.durationWeeks = durationWeeks
        self.sessionsPerWeek = sessionsPerWeek
        self.difficulty = difficulty
        self.weeks = try JSONDecoder().decode([ProgramWeek].self, from: weeksData)

        if let phasesJSON = record["phasesJSON"] as? String,
           let phasesData = phasesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ProgramPhase].self, from: phasesData) {
            self.phases = decoded
        } else {
            self.phases = []
        }

        if let profileJSON = record["cycleAdjustmentProfileJSON"] as? String,
           let profileData = profileJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ProgramCycleAdjustmentProfile.self, from: profileData) {
            self.cycleAdjustmentProfile = decoded
        } else {
            self.cycleAdjustmentProfile = nil
        }
    }
}

// MARK: - ProgramPhase

struct ProgramPhase: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let goal: String
    let weekRange: [Int]
}

// MARK: - ProgramWeek

struct ProgramWeek: Codable, Sendable, Hashable {
    let week: Int
    let phaseID: String
    let isTestWeek: Bool
    let sessions: [ProgramSession]

    enum CodingKeys: String, CodingKey {
        case week
        case phaseID = "phaseId"
        case isTestWeek
        case sessions
    }
}

// MARK: - ProgramSession

struct ProgramSession: Codable, Sendable, Hashable {
    let sessionID: String
    let sessionName: String
    let sessionType: String
    let focus: String
    let exercises: [ProgramExercise]

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId"
        case sessionName, sessionType, focus, exercises
    }
}

// MARK: - ProgramExercise

struct ProgramExercise: Codable, Sendable, Hashable {
    let exercise: String
    let variant: String?
    let sets: ExerciseValue
    let reps: ExerciseValue
    let percent1RM: Double?
    let restMinutes: Double?
    let notes: String?
    let bodyweightOnly: Bool

    enum CodingKeys: String, CodingKey {
        case exercise, variant, sets, reps, percent1RM, restMinutes, notes, bodyweightOnly
    }

    init(exercise: String, variant: String?, sets: ExerciseValue, reps: ExerciseValue,
         percent1RM: Double?, restMinutes: Double?, notes: String?, bodyweightOnly: Bool = false) {
        self.exercise = exercise
        self.variant = variant
        self.sets = sets
        self.reps = reps
        self.percent1RM = percent1RM
        self.restMinutes = restMinutes
        self.notes = notes
        self.bodyweightOnly = bodyweightOnly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exercise = try container.decode(String.self, forKey: .exercise)
        variant = try container.decodeIfPresent(String.self, forKey: .variant)
        sets = try container.decode(ExerciseValue.self, forKey: .sets)
        reps = try container.decode(ExerciseValue.self, forKey: .reps)
        percent1RM = try container.decodeIfPresent(Double.self, forKey: .percent1RM)
        restMinutes = try container.decodeIfPresent(Double.self, forKey: .restMinutes)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        bodyweightOnly = (try? container.decode(Bool.self, forKey: .bodyweightOnly)) ?? false
    }
}
