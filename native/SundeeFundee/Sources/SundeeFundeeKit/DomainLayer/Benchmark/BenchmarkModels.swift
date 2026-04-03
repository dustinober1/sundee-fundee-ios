import Foundation

// MARK: - Benchmark Models

/// Intensity level of a benchmark (1-5)
public enum BenchmarkIntensity: Int, Codable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
}

/// How a benchmark is scored
public enum BenchmarkScoringType: String, Codable, Sendable {
    case time
    case roundsAndReps
    case load
    case reps
    case calories
    case distance
}

/// Readiness tier for attempting a benchmark
public enum ReadinessTier: String, Codable, Sendable {
    case peak
    case moderate
    case recovery
}

/// Category of benchmark
public enum BenchmarkCategory: String, Codable, Sendable, CaseIterable {
    case sundeeFundee = "Sundee Fundee"
    case classicWODs = "Classic WODs"
    case strength = "Strength"
    case endurance = "Endurance"
    case gymnastics = "Gymnastics"
    case generalFitness = "General Fitness"
}

/// A predefined or custom benchmark definition
public struct BenchmarkDefinition: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public let workoutDescription: String
    public let scoringType: BenchmarkScoringType
    public let isPredefined: Bool
    public let sortOrder: Int
    public let intensity: BenchmarkIntensity?
    public let movementTags: [String]?
    public let equipment: [String]?
    public let timeDomain: String?
    public let coachNotes: String?

    public init(
        id: String,
        name: String,
        category: String,
        workoutDescription: String,
        scoringType: BenchmarkScoringType,
        isPredefined: Bool,
        sortOrder: Int,
        intensity: BenchmarkIntensity? = nil,
        movementTags: [String]? = nil,
        equipment: [String]? = nil,
        timeDomain: String? = nil,
        coachNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.workoutDescription = workoutDescription
        self.scoringType = scoringType
        self.isPredefined = isPredefined
        self.sortOrder = sortOrder
        self.intensity = intensity
        self.movementTags = movementTags
        self.equipment = equipment
        self.timeDomain = timeDomain
        self.coachNotes = coachNotes
    }
}

/// Result of a benchmark attempt
public struct BenchmarkResult: Codable, Sendable, Identifiable {
    public let id: String
    public let benchmarkId: String
    public let benchmarkName: String
    public let score: Double
    public let notes: String?
    public let date: Date
    public let cyclePhase: CyclePhase?

    public init(
        id: String,
        benchmarkId: String,
        benchmarkName: String,
        score: Double,
        notes: String? = nil,
        date: Date,
        cyclePhase: CyclePhase? = nil
    ) {
        self.id = id
        self.benchmarkId = benchmarkId
        self.benchmarkName = benchmarkName
        self.score = score
        self.notes = notes
        self.date = date
        self.cyclePhase = cyclePhase
    }
}

/// Readiness assessment for attempting a benchmark
public struct BenchmarkReadiness: Codable, Sendable {
    public let tier: ReadinessTier
    public let reason: String
    public let recommendation: String
    public let phaseMultiplier: Double
    public let emoji: String
    public let color: String

    public init(
        tier: ReadinessTier,
        reason: String,
        recommendation: String,
        phaseMultiplier: Double,
        emoji: String,
        color: String
    ) {
        self.tier = tier
        self.reason = reason
        self.recommendation = recommendation
        self.phaseMultiplier = phaseMultiplier
        self.emoji = emoji
        self.color = color
    }
}

/// Best attempt window based on cycle
public struct AttemptWindow: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let reason: String

    public init(startDate: Date, endDate: Date, reason: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.reason = reason
    }
}
