import Foundation

// MARK: - ContentError

/// Errors that can occur when fetching remote content
public enum ContentError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for content API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let message):
            return "Failed to decode content: \(message)"
        }
    }
}

// MARK: - RemoteContentClient

/// Actor that fetches content from Teenybase API, caches locally, and falls back to bundled defaults.
///
/// Fetch flow:
/// 1. Check in-memory cache
/// 2. Try remote API (published items only)
/// 3. Fall back to file cache
/// 4. Fall back to bundled content
///
/// Remote content overlays bundled content by ID — remote items with matching IDs replace
/// bundled items, while new remote items are appended.
public actor RemoteContentClient: ContentClientProtocol {

    // MARK: - Properties

    /// Teenybase API base URL
    private let baseURL: String

    /// Admin auth token
    private let token: String

    /// Directory for caching JSON files
    private let cacheDirectory: URL

    /// JSON decoder
    private let decoder: JSONDecoder

    /// JSON encoder
    private let encoder: JSONEncoder

    /// In-memory cache for exercises
    private var cachedExercises: [ContentExercise]?

    /// In-memory cache for programs
    private var cachedPrograms: [ContentProgram]?

    /// In-memory cache for benchmarks
    private var cachedBenchmarks: [ContentBenchmark]?

    // MARK: - Initialization

    /// Creates a new remote content client.
    ///
    /// - Parameters:
    ///   - baseURL: Teenybase API base URL (e.g., "http://localhost:8787")
    ///   - token: Admin auth token
    ///   - cacheDirectory: Directory for caching JSON files
    public init(
        baseURL: String,
        token: String,
        cacheDirectory: URL
    ) {
        self.baseURL = baseURL
        self.token = token
        self.cacheDirectory = cacheDirectory
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = .prettyPrinted

        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - ContentClientProtocol

    /// Fetches all exercises.
    public func fetchExercises() async throws -> [ContentExercise] {
        if let cached = cachedExercises {
            return cached
        }

        let result: [ContentExercise] = try await fetchWithFallback(
            table: "exercises",
            cachedFile: "exercises.json",
            bundled: BundledContentProvider.exercises
        ) { data in
            let remoteItems = try self.decoder.decode([RemoteExercise].self, from: data)
            return remoteItems.map { $0.toContentExercise() }
        }

        cachedExercises = result
        return result
    }

    /// Fetches all programs.
    public func fetchPrograms() async throws -> [ContentProgram] {
        if let cached = cachedPrograms {
            return cached
        }

        let result: [ContentProgram] = try await fetchWithFallback(
            table: "programs",
            cachedFile: "programs.json",
            bundled: BundledContentProvider.programs
        ) { data in
            let remoteItems = try self.decoder.decode([RemoteProgram].self, from: data)
            return remoteItems.map { $0.toContentProgram() }
        }

        cachedPrograms = result
        return result
    }

    /// Fetches all benchmarks.
    public func fetchBenchmarks() async throws -> [ContentBenchmark] {
        if let cached = cachedBenchmarks {
            return cached
        }

        let result: [ContentBenchmark] = try await fetchWithFallback(
            table: "benchmarks",
            cachedFile: "benchmarks.json",
            bundled: BundledContentProvider.benchmarks
        ) { data in
            let remoteItems = try self.decoder.decode([RemoteBenchmark].self, from: data)
            return remoteItems.map { $0.toContentBenchmark() }
        }

        cachedBenchmarks = result
        return result
    }

    // MARK: - Private Methods

    /// Fetches content with fallback chain: remote → file cache → bundled.
    ///
    /// - Parameters:
    ///   - table: Teenybase table name
    ///   - cachedFile: Filename for file cache
    ///   - bundled: Bundled content to use as ultimate fallback
    ///   - decode: Closure to decode raw remote data into typed content
    /// - Returns: Fetched and merged content
    private func fetchWithFallback<T: Identifiable & Codable>(
        table: String,
        cachedFile: String,
        bundled: [T],
        decode: (Data) throws -> [T]
    ) async throws -> [T] {
        // Try remote first
        do {
            let remote = try await fetchFromAPI(table: table, decode: decode)
            let merged = Self.merge(bundled: bundled, remote: remote)

            // Save to file cache
            try? saveToCache(items: merged, file: cachedFile)

            return merged
        } catch {
            // Remote failed — try file cache
            if let cached = try? loadFromCache(file: cachedFile, decode: decode) {
                return cached
            }

            // File cache failed — return bundled
            return bundled
        }
    }

    /// Fetches content from the Teenybase API.
    ///
    /// - Parameters:
    ///   - table: Teenybase table name
    ///   - decode: Closure to decode raw remote data into typed content
    /// - Returns: Remote content items
    /// - Throws: ContentError if the request fails
    private func fetchFromAPI<T: Decodable>(
        table: String,
        decode: (Data) throws -> [T]
    ) async throws -> [T] {
        guard let url = URL(string: "\(baseURL)/api/v1/table/\(table)/list") else {
            throw ContentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Request body: filter for published items, limit to 200
        let requestBody: [String: Any] = [
            "where": "status='published'",
            "limit": 200
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentError.httpError(-1)
        }

        guard httpResponse.statusCode == 200 else {
            throw ContentError.httpError(httpResponse.statusCode)
        }

        // Parse response as {"data": [...]}
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = json["data"] as? [Any] {
            let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
            return try decode(jsonData)
        }

        // Direct array response
        return try decode(data)
    }

    /// Saves content to file cache.
    ///
    /// - Parameters:
    ///   - items: Items to cache
    ///   - file: Filename for cache
    /// - Throws: Error if encoding or writing fails
    private func saveToCache<T: Encodable>(items: [T], file: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(file)
        let data = try encoder.encode(items)
        try data.write(to: fileURL)
    }

    /// Loads content from file cache.
    ///
    /// - Parameters:
    ///   - file: Filename for cache
    ///   - decode: Closure to decode cached data
    /// - Returns: Cached items, or nil if cache doesn't exist
    /// - Throws: Error if decoding fails
    private func loadFromCache<T>(file: String, decode: (Data) throws -> [T]) throws -> [T] {
        let fileURL = cacheDirectory.appendingPathComponent(file)
        let data = try Data(contentsOf: fileURL)
        return try decode(data)
    }

    // MARK: - Public Static Methods

    /// Merges remote content over bundled content.
    ///
    /// Remote items with IDs matching bundled items REPLACE them (at same position).
    /// Remote items with new IDs are APPENDED.
    ///
    /// - Parameters:
    ///   - bundled: Bundled content items
    ///   - remote: Remote content items
    /// - Returns: Merged array
    public static func merge<T: Identifiable>(bundled: [T], remote: [T]) -> [T] {
        var result = bundled
        let bundledIDs = Set(bundled.map { $0.id })

        for item in remote {
            if let index = result.firstIndex(where: { $0.id == item.id }) {
                // Replace existing item
                result[index] = item
            } else if !bundledIDs.contains(item.id) {
                // Append new item
                result.append(item)
            }
        }

        return result
    }
}

// MARK: - Remote Decoding Types

/// Remote exercise representation from Teenybase.
private struct RemoteExercise: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let bodyweight: Bool?
    let equipment: String? // JSON string in DB
    let movementTags: String? // JSON string in DB
    let sortOrder: Int?

    func toContentExercise() -> ContentExercise {
        ContentExercise(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            category: category ?? "",
            bodyweight: bodyweight ?? false,
            equipment: equipment.flatMap { parseJSONString($0) },
            movementTags: movementTags.flatMap { parseJSONString($0) },
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }

    private func parseJSONString(_ string: String) -> [String]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}

/// Remote program representation from Teenybase.
private struct RemoteProgram: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let description: String?
    let durationWeeks: Int?
    let sessionsPerWeek: Int?
    let difficulty: String?
    let phases: String?
    let sortOrder: Int?

    func toContentProgram() -> ContentProgram {
        ContentProgram(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            category: category ?? "",
            description: description ?? "",
            durationWeeks: durationWeeks ?? 4,
            sessionsPerWeek: sessionsPerWeek ?? 3,
            difficulty: difficulty ?? "beginner",
            phases: phases,
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }
}

/// Remote benchmark representation from Teenybase.
private struct RemoteBenchmark: Decodable, Sendable {
    let id: String?
    let name: String?
    let category: String?
    let workoutDescription: String?
    let scoringType: String?
    let intensity: Int?
    let movementTags: String? // JSON string in DB
    let equipment: String? // JSON string in DB
    let timeDomain: String?
    let coachNotes: String?
    let sortOrder: Int?

    func toContentBenchmark() -> ContentBenchmark {
        ContentBenchmark(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            category: category ?? "",
            workoutDescription: workoutDescription ?? "",
            scoringType: scoringType ?? "reps",
            intensity: intensity,
            movementTags: movementTags.flatMap { parseJSONString($0) },
            equipment: equipment.flatMap { parseJSONString($0) },
            timeDomain: timeDomain,
            coachNotes: coachNotes,
            sortOrder: sortOrder ?? 0,
            source: .remote
        )
    }

    private func parseJSONString(_ string: String) -> [String]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}
