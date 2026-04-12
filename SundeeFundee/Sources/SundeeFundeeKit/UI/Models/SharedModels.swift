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
}

public extension Workout {
    var completedWorkoutRecord: CompletedWorkoutRecord? {
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
