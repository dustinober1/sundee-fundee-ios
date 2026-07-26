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

public actor PresenceLocalStore: PresenceLocalStoring {
    private let fileURL: URL
    private var envelope: PresenceCacheEnvelope

    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("daily-presence.json")
        self.fileURL = resolvedURL
        envelope = Self.read(from: resolvedURL)
    }

    public func load() -> [DailyPresenceRecord] {
        envelope.records
    }

    public func save(_ record: DailyPresenceRecord) throws {
        if let index = envelope.records.firstIndex(where: { $0.id == record.id }) {
            envelope.records[index] = record
        } else {
            envelope.records.append(record)
        }
        envelope.pendingIDs.insert(record.id)
        try persist()
    }

    public func markSynced(id: String) throws {
        envelope.pendingIDs.remove(id)
        try persist()
    }

    public func pending() -> [DailyPresenceRecord] {
        envelope.records.filter { envelope.pendingIDs.contains($0.id) }
    }

    private static func read(from fileURL: URL) -> PresenceCacheEnvelope {
        guard let data = try? Data(contentsOf: fileURL) else {
            return PresenceCacheEnvelope()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(PresenceCacheEnvelope.self, from: data)) ?? PresenceCacheEnvelope()
    }

    private func persist() throws {
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
