import Foundation

// MARK: - Content Source

/// Origin of content — all content is bundled with the app
public enum ContentSource: String, Codable, Sendable, Equatable {
    case bundled
}

// MARK: - Content Models

/// Exercise definition from content source
public struct ContentExercise: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let bodyweight: Bool
    public let equipment: [String]?
    public let movementTags: [String]?
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        bodyweight: Bool,
        equipment: [String]? = nil,
        movementTags: [String]? = nil,
        sortOrder: Int,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.bodyweight = bodyweight
        self.equipment = equipment
        self.movementTags = movementTags
        self.sortOrder = sortOrder
        self.source = source
    }
}

/// Program definition from content source
public struct ContentProgram: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let durationWeeks: Int
    public let sessionsPerWeek: Int
    public let difficulty: String
    public let phases: String? // JSON string encoding of phases array
    public let printablePDFURL: URL?
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        description: String,
        durationWeeks: Int,
        sessionsPerWeek: Int,
        difficulty: String,
        phases: String? = nil,
        printablePDFURL: URL? = nil,
        sortOrder: Int,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.durationWeeks = durationWeeks
        self.sessionsPerWeek = sessionsPerWeek
        self.difficulty = difficulty
        self.phases = phases
        self.printablePDFURL = printablePDFURL
        self.sortOrder = sortOrder
        self.source = source
    }
}

/// Benchmark definition from content source
public struct ContentBenchmark: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let workoutDescription: String
    public let scoringType: String
    public let intensity: Int?
    public let movementTags: [String]?
    public let equipment: [String]?
    public let timeDomain: String?
    public let coachNotes: String?
    public let sortOrder: Int
    public let source: ContentSource

    public init(
        id: String,
        name: String,
        category: String,
        workoutDescription: String,
        scoringType: String,
        intensity: Int? = nil,
        movementTags: [String]? = nil,
        equipment: [String]? = nil,
        timeDomain: String? = nil,
        coachNotes: String? = nil,
        sortOrder: Int,
        source: ContentSource = .bundled
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.workoutDescription = workoutDescription
        self.scoringType = scoringType
        self.intensity = intensity
        self.movementTags = movementTags
        self.equipment = equipment
        self.timeDomain = timeDomain
        self.coachNotes = coachNotes
        self.sortOrder = sortOrder
        self.source = source
    }
}

// MARK: - Content Client Protocol

/// Protocol for fetching exercise, program, and benchmark content from any source
public protocol ContentClientProtocol: Sendable {
    /// Fetch all exercises
    func fetchExercises() async throws -> [ContentExercise]

    /// Fetch all programs
    func fetchPrograms() async throws -> [ContentProgram]

    /// Fetch all benchmarks
    func fetchBenchmarks() async throws -> [ContentBenchmark]
}

// MARK: - Mock Content Client

/// In-memory content client that returns bundled hardcoded content
public struct MockContentClient: ContentClientProtocol {
    public init() {}

    public func fetchExercises() async throws -> [ContentExercise] {
        BundledContentProvider.exercises
    }

    public func fetchPrograms() async throws -> [ContentProgram] {
        BundledContentProvider.programs
    }

    public func fetchBenchmarks() async throws -> [ContentBenchmark] {
        BundledContentProvider.benchmarks
    }
}
