import Foundation

public struct PendingPresenceRecord: Sendable, Equatable {
    public let record: DailyPresenceRecord
    public let revision: Int

    public init(record: DailyPresenceRecord, revision: Int) {
        self.record = record
        self.revision = revision
    }
}

public enum PresenceStoreError: Error, Sendable, Equatable {
    case ownershipMismatch(expected: String, actual: String)
    case legacyOwnershipUnknown
}

public protocol PresenceLocalStoring: Sendable {
    func load(ownerID: String) async throws -> [DailyPresenceRecord]

    @discardableResult
    func save(
        _ record: DailyPresenceRecord,
        ownerID: String
    ) async throws -> PendingPresenceRecord

    func storeRemote(
        _ records: [DailyPresenceRecord],
        ownerID: String
    ) async throws

    func markSynced(
        _ pendingRecord: PendingPresenceRecord,
        ownerID: String
    ) async throws

    func pending(ownerID: String) async throws -> [PendingPresenceRecord]

    func importRecords(
        _ records: [DailyPresenceRecord],
        ownerID: String,
        markPending: Bool
    ) async throws

    func clear(ownerID: String) async throws
}

private struct PresenceCacheEnvelope: Codable, Sendable {
    var ownerID: String
    var records: [DailyPresenceRecord]
    var pendingRevisions: [String: Int]
    var nextRevision: Int

    init(
        ownerID: String,
        records: [DailyPresenceRecord] = [],
        pendingRevisions: [String: Int] = [:],
        nextRevision: Int = 1
    ) {
        self.ownerID = ownerID
        self.records = records
        self.pendingRevisions = pendingRevisions
        self.nextRevision = nextRevision
    }

    private enum CodingKeys: String, CodingKey {
        case ownerID, records, pendingRevisions, nextRevision, pendingIDs
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ownerID = try values.decodeIfPresent(String.self, forKey: .ownerID) ?? ""
        records = try values.decodeIfPresent([DailyPresenceRecord].self, forKey: .records) ?? []

        if let revisions = try values.decodeIfPresent(
            [String: Int].self,
            forKey: .pendingRevisions
        ) {
            pendingRevisions = revisions
        } else {
            let pendingIDs =
                try values.decodeIfPresent(Set<String>.self, forKey: .pendingIDs) ?? []
            pendingRevisions = Dictionary(
                uniqueKeysWithValues: pendingIDs.sorted().enumerated().map { offset, id in
                    (id, offset + 1)
                }
            )
        }

        let largestRevision = pendingRevisions.values.max() ?? 0
        nextRevision = max(
            try values.decodeIfPresent(Int.self, forKey: .nextRevision) ?? 1,
            largestRevision + 1
        )
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(ownerID, forKey: .ownerID)
        try values.encode(records, forKey: .records)
        try values.encode(pendingRevisions, forKey: .pendingRevisions)
        try values.encode(nextRevision, forKey: .nextRevision)
    }
}

private actor PresenceCacheCoordinator {
    static let shared = PresenceCacheCoordinator()

    func load(from fileURL: URL, ownerID: String) throws -> [DailyPresenceRecord] {
        try envelope(from: fileURL, ownerID: ownerID).records.sortedForPresence()
    }

    func save(
        _ record: DailyPresenceRecord,
        to fileURL: URL,
        ownerID: String
    ) throws -> PendingPresenceRecord {
        var envelope = try envelope(from: fileURL, ownerID: ownerID)
        let canonical = record.canonicalizedForPresence()
        envelope.records.upsertPresence(canonical)
        let stored = envelope.records.record(forDayKey: canonical.dayKey) ?? canonical
        let revision = envelope.consumeRevision()
        envelope.pendingRevisions[stored.id] = revision
        try PresenceCacheFile.persist(envelope.normalized(), to: fileURL)
        return PendingPresenceRecord(record: stored, revision: revision)
    }

    func storeRemote(
        _ records: [DailyPresenceRecord],
        in fileURL: URL,
        ownerID: String
    ) throws {
        var envelope = try envelope(from: fileURL, ownerID: ownerID).normalized()

        for remoteValue in records {
            let remote = remoteValue.canonicalizedForPresence()
            let existing = envelope.records.record(forDayKey: remote.dayKey)
            let merged = existing?.merging(with: remote) ?? remote
            let currentRevision = envelope.pendingRevisions[merged.id]
            let localHasEvidenceMissingRemotely = merged != remote

            envelope.records.upsertPresence(merged)

            if currentRevision != nil, merged != existing {
                envelope.pendingRevisions[merged.id] = envelope.consumeRevision()
            } else if currentRevision == nil, localHasEvidenceMissingRemotely {
                envelope.pendingRevisions[merged.id] = envelope.consumeRevision()
            }
        }

        try PresenceCacheFile.persist(envelope.normalized(), to: fileURL)
    }

    func markSynced(
        _ pendingRecord: PendingPresenceRecord,
        in fileURL: URL,
        ownerID: String
    ) throws {
        var envelope = try envelope(from: fileURL, ownerID: ownerID).normalized()
        let canonicalID = pendingRecord.record.canonicalizedForPresence().id
        guard envelope.pendingRevisions[canonicalID] == pendingRecord.revision else {
            return
        }
        envelope.pendingRevisions.removeValue(forKey: canonicalID)
        try PresenceCacheFile.persist(envelope, to: fileURL)
    }

    func pending(from fileURL: URL, ownerID: String) throws -> [PendingPresenceRecord] {
        let envelope = try envelope(from: fileURL, ownerID: ownerID).normalized()
        return envelope.records.compactMap { record in
            envelope.pendingRevisions[record.id].map {
                PendingPresenceRecord(record: record, revision: $0)
            }
        }.sorted {
            if $0.record.dayKey != $1.record.dayKey {
                return $0.record.dayKey < $1.record.dayKey
            }
            return $0.record.id < $1.record.id
        }
    }

    func importRecords(
        _ records: [DailyPresenceRecord],
        into fileURL: URL,
        ownerID: String,
        markPending: Bool
    ) throws {
        var envelope = try envelope(from: fileURL, ownerID: ownerID).normalized()
        for value in records {
            let record = value.canonicalizedForPresence()
            envelope.records.upsertPresence(record)
            guard markPending,
                  let stored = envelope.records.record(forDayKey: record.dayKey) else {
                continue
            }
            envelope.pendingRevisions[stored.id] = envelope.consumeRevision()
        }
        try PresenceCacheFile.persist(envelope.normalized(), to: fileURL)
    }

    func clear(fileURL: URL, ownerID: String) throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try envelope(from: fileURL, ownerID: ownerID)
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func migrateLegacy(
        from legacyURL: URL,
        to destinationURL: URL,
        ownerID: String
    ) throws {
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        let legacy = try PresenceCacheFile.read(from: legacyURL, missingOwnerID: "")
        guard legacy.ownerID.isEmpty else {
            throw PresenceStoreError.ownershipMismatch(
                expected: ownerID,
                actual: legacy.ownerID
            )
        }

        var destination = try envelope(from: destinationURL, ownerID: ownerID).normalized()
        for value in legacy.records {
            let record = value.canonicalizedForPresence()
            destination.records.upsertPresence(record)
            guard let stored = destination.records.record(forDayKey: record.dayKey) else {
                continue
            }
            destination.pendingRevisions[stored.id] = destination.consumeRevision()
        }

        try PresenceCacheFile.persist(destination.normalized(), to: destinationURL)
        try FileManager.default.removeItem(at: legacyURL)
    }

    private func envelope(from fileURL: URL, ownerID: String) throws -> PresenceCacheEnvelope {
        let envelope = try PresenceCacheFile.read(from: fileURL, missingOwnerID: ownerID)
        guard !envelope.ownerID.isEmpty else {
            throw PresenceStoreError.legacyOwnershipUnknown
        }
        guard envelope.ownerID == ownerID else {
            throw PresenceStoreError.ownershipMismatch(
                expected: ownerID,
                actual: envelope.ownerID
            )
        }
        return envelope.normalized()
    }
}

private enum PresenceCacheFile {
    static func read(from fileURL: URL, missingOwnerID: String) throws -> PresenceCacheEnvelope {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            let nsError = error as NSError
            guard nsError.domain == NSCocoaErrorDomain,
                  nsError.code == NSFileReadNoSuchFileError else {
                throw error
            }
            return PresenceCacheEnvelope(ownerID: missingOwnerID)
        }

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
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: .atomic)
    }
}

public actor PresenceLocalStore: PresenceLocalStoring {
    public let ownerID: String
    private let fileURL: URL

    public init(
        ownerID: String,
        baseDirectoryURL: URL? = nil
    ) {
        self.ownerID = ownerID
        let baseURL = baseDirectoryURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("Presence", isDirectory: true)
        fileURL = baseURL
            .appendingPathComponent(Self.namespace(for: ownerID), isDirectory: true)
            .appendingPathComponent("daily-presence.json")
    }

    public init(fileURL: URL, ownerID: String) {
        self.ownerID = ownerID
        self.fileURL = fileURL
    }

    public func load(ownerID: String) async throws -> [DailyPresenceRecord] {
        try validate(ownerID)
        return try await PresenceCacheCoordinator.shared.load(
            from: fileURL,
            ownerID: ownerID
        )
    }

    @discardableResult
    public func save(
        _ record: DailyPresenceRecord,
        ownerID: String
    ) async throws -> PendingPresenceRecord {
        try validate(ownerID)
        return try await PresenceCacheCoordinator.shared.save(
            record,
            to: fileURL,
            ownerID: ownerID
        )
    }

    public func storeRemote(
        _ records: [DailyPresenceRecord],
        ownerID: String
    ) async throws {
        try validate(ownerID)
        try await PresenceCacheCoordinator.shared.storeRemote(
            records,
            in: fileURL,
            ownerID: ownerID
        )
    }

    public func markSynced(
        _ pendingRecord: PendingPresenceRecord,
        ownerID: String
    ) async throws {
        try validate(ownerID)
        try await PresenceCacheCoordinator.shared.markSynced(
            pendingRecord,
            in: fileURL,
            ownerID: ownerID
        )
    }

    public func pending(ownerID: String) async throws -> [PendingPresenceRecord] {
        try validate(ownerID)
        return try await PresenceCacheCoordinator.shared.pending(
            from: fileURL,
            ownerID: ownerID
        )
    }

    public func importRecords(
        _ records: [DailyPresenceRecord],
        ownerID: String,
        markPending: Bool
    ) async throws {
        try validate(ownerID)
        try await PresenceCacheCoordinator.shared.importRecords(
            records,
            into: fileURL,
            ownerID: ownerID,
            markPending: markPending
        )
    }

    public func clear(ownerID: String) async throws {
        try validate(ownerID)
        try await PresenceCacheCoordinator.shared.clear(
            fileURL: fileURL,
            ownerID: ownerID
        )
    }

    /// Moves the pre-account global cache only when the caller has explicitly
    /// selected its owner (currently the guest account during startup).
    public func migrateLegacyCache(
        from legacyURL: URL,
        ownerID: String
    ) async throws {
        try validate(ownerID)
        try await PresenceCacheCoordinator.shared.migrateLegacy(
            from: legacyURL,
            to: fileURL,
            ownerID: ownerID
        )
    }

    private func validate(_ requestedOwnerID: String) throws {
        guard requestedOwnerID == ownerID else {
            throw PresenceStoreError.ownershipMismatch(
                expected: ownerID,
                actual: requestedOwnerID
            )
        }
    }

    private static func namespace(for ownerID: String) -> String {
        let safePrefix = ownerID.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_"
                ? String(scalar)
                : "-"
        }.joined().prefix(32)

        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in ownerID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return "\(safePrefix.isEmpty ? "account" : String(safePrefix))-\(String(hash, radix: 16))"
    }
}

private extension PresenceCacheEnvelope {
    mutating func consumeRevision() -> Int {
        let revision = nextRevision
        nextRevision += 1
        return revision
    }

    func normalized() -> Self {
        var mergedByDay: [String: DailyPresenceRecord] = [:]
        var revisionsByDay: [String: Int] = [:]

        for record in records {
            let canonical = record.canonicalizedForPresence()
            if let existing = mergedByDay[canonical.dayKey] {
                mergedByDay[canonical.dayKey] = existing.merging(with: canonical)
            } else {
                mergedByDay[canonical.dayKey] = canonical
            }

            if let revision = pendingRevisions[record.id] ?? pendingRevisions[canonical.id] {
                revisionsByDay[canonical.dayKey] = max(
                    revisionsByDay[canonical.dayKey] ?? 0,
                    revision
                )
            }
        }

        let normalizedRecords = Array(mergedByDay.values).sortedForPresence()
        let normalizedRevisions = Dictionary(
            uniqueKeysWithValues: normalizedRecords.compactMap { record in
                revisionsByDay[record.dayKey].map { (record.id, $0) }
            }
        )
        return Self(
            ownerID: ownerID,
            records: normalizedRecords,
            pendingRevisions: normalizedRevisions,
            nextRevision: max(nextRevision, (normalizedRevisions.values.max() ?? 0) + 1)
        )
    }
}

private extension DailyPresenceRecord {
    func canonicalizedForPresence() -> Self {
        Self(
            dayKey: dayKey,
            timeZoneIdentifier: timeZoneIdentifier,
            firstOpenDate: firstOpenDate,
            mostRecentOpenDate: mostRecentOpenDate,
            participationLevel: participationLevel,
            status: status,
            actionEvidence: actionEvidence,
            dateCreated: dateCreated,
            dateUpdated: dateUpdated,
            modelVersion: max(modelVersion, Self.currentModelVersion)
        )
    }
}

private extension Array where Element == DailyPresenceRecord {
    func sortedForPresence() -> Self {
        sorted {
            if $0.dayKey != $1.dayKey {
                return $0.dayKey < $1.dayKey
            }
            return $0.id < $1.id
        }
    }

    func record(forDayKey dayKey: String) -> DailyPresenceRecord? {
        first { $0.dayKey == dayKey }
    }

    mutating func upsertPresence(_ record: DailyPresenceRecord) {
        if let index = firstIndex(where: { $0.dayKey == record.dayKey }) {
            self[index] = self[index].merging(with: record)
        } else {
            append(record)
        }
    }
}
