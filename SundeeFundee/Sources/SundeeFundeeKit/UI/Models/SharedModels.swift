import Foundation

// MARK: - Shared Model Types

// Common model types used across multiple views and domain services

public struct OneRepMaxRecord: Codable, Sendable {
    public let id: String
    public let exerciseName: String
    public let weight: Double
    public let unit: WeightUnit
    public let date: Date

    public init(id: String, exerciseName: String, weight: Double, unit: WeightUnit, date: Date) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.unit = unit
        self.date = date
    }
}

public enum WeightUnit: String, Codable, Sendable {
    case lbs
    case kg
}

public struct EnrolledProgramRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let isActive: Bool

    public init(id: String, name: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.isActive = isActive
    }

    // CloudKit stores Bool as Int64. JSONDecoder expects Bool.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        if let boolVal = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = boolVal
        } else {
            isActive = (try? container.decode(Int.self, forKey: .isActive)) != 0
        }
    }
}

public struct CelebrationEventRecord: Codable, Sendable {
    public let id: String
    public let description: String
    public let date: Date

    public init(id: String, description: String, date: Date) {
        self.id = id
        self.description = description
        self.date = date
    }
}

public struct ProgramSessionRecord: Codable, Sendable {
    public let id: String
    public let programId: String
    public let sessionId: String
    public let workoutId: String
    public let week: Int

    public init(id: String, programId: String, sessionId: String, workoutId: String, week: Int) {
        self.id = id
        self.programId = programId
        self.sessionId = sessionId
        self.workoutId = workoutId
        self.week = week
    }
}

public struct CompletedWorkoutRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let date: Date
    public let duration: Int?
    public let exerciseNames: [String]
    public let isComplete: Bool

    public init(id: String, name: String, date: Date, duration: Int?, exerciseNames: [String], isComplete: Bool) {
        self.id = id
        self.name = name
        self.date = date
        self.duration = duration
        self.exerciseNames = exerciseNames
        self.isComplete = isComplete
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, date, duration, exerciseNames, isComplete, completedAt, exercises
    }

    private struct NamedExercise: Decodable {
        let name: String
    }

    // Backwards-compatible decoding: "Workout" CloudKit records are also decoded
    // as CompletedWorkoutRecord by analytics and dashboard flows. Those records lack
    // `exerciseNames`/`isComplete` but carry `exercises` and `completedAt`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        let rawDate = try container.decodeIfPresent(Date.self, forKey: .date)
        date = completedAt ?? rawDate ?? Date()
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        if let names = try? container.decode([String].self, forKey: .exerciseNames) {
            exerciseNames = names
        } else if let exercises = try? container.decode([NamedExercise].self, forKey: .exercises) {
            exerciseNames = exercises.map(\.name)
        } else {
            exerciseNames = []
        }
        if let flag = try? container.decode(Bool.self, forKey: .isComplete) {
            isComplete = flag
        } else if let intFlag = try? container.decode(Int.self, forKey: .isComplete) {
            isComplete = intFlag != 0
        } else {
            isComplete = completedAt != nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encode(exerciseNames, forKey: .exerciseNames)
        try container.encode(isComplete, forKey: .isComplete)
    }
}

extension Workout {
    public var completedWorkoutRecord: CompletedWorkoutRecord? {
        guard isComplete else { return nil }

        return CompletedWorkoutRecord(
            id: id,
            name: name,
            date: completedAt ?? date,
            duration: duration,
            exerciseNames: exercises.map(\.name),
            isComplete: true
        )
    }
}

public struct CyclePhaseInfo: Codable, Sendable {
    public let phase: CyclePhase
    public let confidence: Double
    public let startDate: Date
    public let endDate: Date

    public init(phase: CyclePhase, confidence: Double, startDate: Date, endDate: Date) {
        self.phase = phase
        self.confidence = confidence
        self.startDate = startDate
        self.endDate = endDate
    }
}

// CyclePhase is defined in DomainLayer/Cycle/CycleCalculations.swift
