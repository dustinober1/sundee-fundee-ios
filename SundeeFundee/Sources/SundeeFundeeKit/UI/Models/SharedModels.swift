import Foundation

// MARK: - Shared Model Types

// Common model types used across multiple views

struct OneRepMaxRecord: Codable, Sendable {
    let id: String
    let exerciseName: String
    let weight: Double
    let unit: WeightUnit
    let date: Date
}

enum WeightUnit: String, Codable {
    case lbs
    case kg
}

struct EnrolledProgramRecord: Codable, Sendable {
    let id: String
    let name: String
    let isActive: Bool
}

struct CelebrationEventRecord: Codable, Sendable {
    let id: String
    let description: String
    let date: Date
}

struct CompletedWorkoutRecord: Codable, Sendable {
    let id: String
    let name: String
    let date: Date
    let duration: Int?
    let exerciseNames: [String]
    let isComplete: Bool
}

struct CyclePhaseInfo: Codable, Sendable {
    let phase: CyclePhase
    let confidence: Double
    let startDate: Date
    let endDate: Date
}

// CyclePhase is defined in DomainLayer/Cycle/CycleCalculations.swift
