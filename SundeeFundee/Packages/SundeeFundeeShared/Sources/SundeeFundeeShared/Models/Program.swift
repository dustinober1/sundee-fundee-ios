import Foundation

public struct Program: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
    public let difficulty: String
    public let phases: [ProgramPhase]
    public let weeks: [ProgramWeek]
    public let cycleAdjustmentProfile: ProgramCycleAdjustmentProfile?
    public let status: String?
    public let startDate: String?
    public let endDate: String?
    public let createdAt: String?
    public let updatedAt: String?

    public init(id: String, name: String, category: String, description: String, durationWeeks: Int, sessionsPerWeek: Int, difficulty: String, phases: [ProgramPhase], weeks: [ProgramWeek], cycleAdjustmentProfile: ProgramCycleAdjustmentProfile?, status: String? = nil, startDate: String? = nil, endDate: String? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id; self.name = name; self.category = category; self.description = description
        self.durationWeeks = durationWeeks; self.sessionsPerWeek = sessionsPerWeek; self.difficulty = difficulty
        self.phases = phases; self.weeks = weeks; self.cycleAdjustmentProfile = cycleAdjustmentProfile
        self.status = status; self.startDate = startDate; self.endDate = endDate
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: Program, rhs: Program) -> Bool { lhs.id == rhs.id }
}

public struct ProgramPhase: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let goal: String
    public let weekRange: [Int]
    public init(id: String, name: String, goal: String, weekRange: [Int]) {
        self.id = id; self.name = name; self.goal = goal; self.weekRange = weekRange
    }
}

public struct ProgramWeek: Codable, Sendable {
    public let week: Int
    public let phaseID: String?
    public let isTestWeek: Bool?
    public let sessions: [ProgramSession]

    public init(week: Int, phaseID: String?, isTestWeek: Bool?, sessions: [ProgramSession]) {
        self.week = week; self.phaseID = phaseID; self.isTestWeek = isTestWeek; self.sessions = sessions
    }

    enum CodingKeys: String, CodingKey {
        case week, phaseID = "phaseId", isTestWeek, sessions
    }
}

public struct ProgramSession: Codable, Identifiable, Sendable {
    public let sessionID: String
    public let sessionName: String
    public let sessionType: String
    public let focus: String
    public let exercises: [ProgramExercise]

    public var id: String { sessionID }

    public init(sessionID: String, sessionName: String, sessionType: String, focus: String, exercises: [ProgramExercise]) {
        self.sessionID = sessionID; self.sessionName = sessionName; self.sessionType = sessionType
        self.focus = focus; self.exercises = exercises
    }

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId", sessionName, sessionType, focus, exercises
    }
}

public struct ProgramExercise: Codable, Sendable {
    public let exercise: String
    public let variant: String?
    public let sets: ExerciseValue
    public let reps: ExerciseValue
    public let percent1RM: Double?
    public let restMinutes: Double?
    public let notes: String?
    public let bodyweightOnly: Bool?

    public init(exercise: String, variant: String?, sets: ExerciseValue, reps: ExerciseValue, percent1RM: Double?, restMinutes: Double?, notes: String?, bodyweightOnly: Bool? = nil) {
        self.exercise = exercise; self.variant = variant; self.sets = sets; self.reps = reps
        self.percent1RM = percent1RM; self.restMinutes = restMinutes; self.notes = notes; self.bodyweightOnly = bodyweightOnly
    }

    enum CodingKeys: String, CodingKey {
        case exercise, variant, sets, reps, percent1RM = "percent1RM", restMinutes, notes, bodyweightOnly
    }
}
