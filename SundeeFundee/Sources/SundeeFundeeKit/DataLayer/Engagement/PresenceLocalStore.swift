import Foundation

public protocol PresenceLocalStoring: Sendable {
    func load() async throws -> [DailyPresenceRecord]
    func save(_ record: DailyPresenceRecord) async throws
    func markSynced(id: String) async throws
    func pending() async throws -> [DailyPresenceRecord]
}

private struct PresenceCacheEnvelope: Codable, Sendable {
    var records: [DailyPresenceRecord]
    var pendingIDs: Set<String>

    init(records: [DailyPresenceRecord] = [], pendingIDs: Set<String> = []) {
        self.records = records
        self.pendingIDs = pendingIDs
    }
}

private actor PresenceCacheCoordinator {
    static let shared = PresenceCacheCoordinator()

    func load(from fileURL: URL) throws -> [DailyPresenceRecord] {
        try PresenceCacheFile.read(from: fileURL).records
    }

    func save(_ record: DailyPresenceRecord, to fileURL: URL) throws {
        var nextEnvelope = try PresenceCacheFile.read(from: fileURL)
        if let index = nextEnvelope.records.firstIndex(where: { $0.id == record.id }) {
            nextEnvelope.records[index] = record
        } else {
            nextEnvelope.records.append(record)
        }
        nextEnvelope.pendingIDs.insert(record.id)
        try PresenceCacheFile.persist(nextEnvelope, to: fileURL)
    }

    func markSynced(id: String, in fileURL: URL) throws {
        var nextEnvelope = try PresenceCacheFile.read(from: fileURL)
        nextEnvelope.pendingIDs.remove(id)
        try PresenceCacheFile.persist(nextEnvelope, to: fileURL)
    }

    func pending(from fileURL: URL) throws -> [DailyPresenceRecord] {
        let envelope = try PresenceCacheFile.read(from: fileURL)
        return envelope.records.filter { envelope.pendingIDs.contains($0.id) }
    }
}

private enum PresenceCacheFile {
    static func read(from fileURL: URL) throws -> PresenceCacheEnvelope {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return PresenceCacheEnvelope()
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PresenceCacheEnvelope.self, from: data)
    }

    static func persist(_ envelope: PresenceCacheEnvelope, to fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: .atomic)
    }
}

public actor PresenceLocalStore: PresenceLocalStoring {
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("daily-presence.json")
        self.fileURL = resolvedURL
    }

    public func load() async throws -> [DailyPresenceRecord] {
        try await PresenceCacheCoordinator.shared.load(from: fileURL)
    }

    public func save(_ record: DailyPresenceRecord) async throws {
        try await PresenceCacheCoordinator.shared.save(record, to: fileURL)
    }

    public func markSynced(id: String) async throws {
        try await PresenceCacheCoordinator.shared.markSynced(id: id, in: fileURL)
    }

    public func pending() async throws -> [DailyPresenceRecord] {
        try await PresenceCacheCoordinator.shared.pending(from: fileURL)
    }
}
