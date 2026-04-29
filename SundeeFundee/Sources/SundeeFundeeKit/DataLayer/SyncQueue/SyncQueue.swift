import CloudKit
@preconcurrency import Foundation

/// Error types specific to the sync queue.
public enum SyncQueueError: Error, LocalizedError, Sendable {
    case decodeFailed(String)
    case flushFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .decodeFailed(let detail):
            return "Failed to decode queued mutation: \(detail)"
        case .flushFailed(let reason):
            return "Flush failed: \(reason)"
        }
    }
}

/// An actor that wraps a `DataClientProtocol` and transparently queues
/// save/delete operations when the network is unavailable.
///
/// When a save or delete throws `DataError.networkError`, the mutation
/// is captured as a `PendingMutation` and persisted to disk via `SyncQueueStore`.
/// When connectivity returns (detected by `NetworkMonitor`), the queue is
/// automatically flushed, replaying all pending mutations in order.
///
/// Fetch operations always delegate directly — reads are never queued.
///
/// Usage:
/// ```swift
/// let queue = SyncQueue(wrapping: cloudKitClient, store: store, monitor: monitor)
/// // ViewModels use `queue` as their DataClientProtocol — no code changes needed
/// ```
public actor SyncQueue: @preconcurrency DataClientProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let wrappedClient: any DataClientProtocol
    private let store: SyncQueueStore
    private let monitor: NetworkMonitor
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var isFlushing = false

    /// Maximum number of retry attempts before giving up on a mutation.
    public let maxRetryAttempts: Int

    /// Task handle for the connectivity change listener.
    /// `nonisolated(unsafe)` because it is set only once in the synchronous
    /// nonisolated init (before the actor is shared) and cancelled in deinit.
    nonisolated(unsafe) private var connectivityTask: Task<Void, Never>?

    /// Last error from a flush attempt, for diagnostics.
    public private(set) var lastFlushError: String?

    // MARK: - Initialization

    public init(
        wrapping client: any DataClientProtocol,
        store: SyncQueueStore,
        monitor: NetworkMonitor,
        maxRetryAttempts: Int = 10
    ) {
        self.wrappedClient = client
        self.store = store
        self.monitor = monitor
        self.maxRetryAttempts = maxRetryAttempts
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Start listening for connectivity changes
        self.connectivityTask = Task { [weak self] in
            for await connected in monitor.connectivityChanges {
                guard let self else { return }
                if connected {
                    await self.flushQueue(allowBackoff: true)
                }
            }
        }
    }

    deinit {
        connectivityTask?.cancel()
    }

    // MARK: - Diagnostics

    /// Number of mutations currently queued.
    public var pendingCount: Int {
        get async {
            await store.pendingCount
        }
    }

    /// Mutations that exceeded `maxRetryAttempts` and were moved out of the
    /// active queue. Surfaced so diagnostics UI can warn the user that some
    /// writes will not be retried automatically.
    public var stuckMutations: [PendingMutation] {
        get async {
            await store.allStuckMutations()
        }
    }

    /// Clears the stuck-mutations list — e.g. after the user acknowledges them
    /// or manually re-enqueues them. Does not affect `pending`.
    public func clearStuckMutations() async {
        await store.clearStuck()
    }

    // MARK: - DataClientProtocol

    public func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        // Reads always delegate directly — never queued
        try await wrappedClient.fetch(
            recordType: recordType,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
    }

    public func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard !records.isEmpty else { return }

        do {
            try await wrappedClient.save(records, recordType: recordType)
        } catch let error as DataError {
            if case .networkError = error {
                await enqueueSave(records: records, recordType: recordType)
                return
            }
            throw error
        }
    }

    public func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        guard !recordIDs.isEmpty else { return }

        do {
            try await wrappedClient.delete(recordIDs: recordIDs, recordType: recordType)
        } catch let error as DataError {
            if case .networkError = error {
                await enqueueDelete(recordIDs: recordIDs, recordType: recordType)
                return
            }
            throw error
        }
    }

    public func deleteAllData() async throws {
        try await wrappedClient.deleteAllData()
    }

    public func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws {
        // Delegate directly — the wrapped client handles raw JSON
        try await wrappedClient.saveFromJSON(jsonRecords, recordType: recordType)
    }

    // MARK: - Queue Operations

    /// Manually trigger a flush of all pending mutations.
    /// Called automatically when connectivity returns.
    /// Can be called manually (e.g., on app foreground).
    public func flushQueue(allowBackoff: Bool = false) async {
        guard !isFlushing else { return }
        isFlushing = true
        defer { isFlushing = false }

        let mutations = await store.allMutations()
        guard !mutations.isEmpty else { return }

        var succeeded: Set<UUID> = []
        var failedToReplay: Set<UUID> = []
        var stuckOut: Set<UUID> = []
        let now = Date()

        for mutation in mutations {
            // Mutations already at/over the retry budget are stuck —
            // move them aside so they don't clog the queue forever.
            if mutation.attempts >= maxRetryAttempts {
                stuckOut.insert(mutation.id)
                continue
            }

            if allowBackoff, shouldBackOff(mutation, now: now) {
                continue
            }

            do {
                try await replay(mutation)
                succeeded.insert(mutation.id)
            } catch {
                // Bumping this attempt would exceed the retry budget —
                // move to stuck instead of incrementing.
                if mutation.attempts + 1 >= maxRetryAttempts {
                    stuckOut.insert(mutation.id)
                } else {
                    failedToReplay.insert(mutation.id)
                }
                lastFlushError = "Mutation \(mutation.id) failed on attempt \(mutation.attempts + 1): \(error.localizedDescription)"
            }
        }

        // Remove succeeded mutations, increment attempts on failed ones,
        // and move stuck mutations out of the active queue.
        await store.remove(ids: succeeded)
        if !failedToReplay.isEmpty {
            await store.incrementAttempts(ids: failedToReplay, lastAttemptAt: now)
        }
        if !stuckOut.isEmpty {
            await store.moveToStuck(ids: stuckOut)
        }
    }

    private func shouldBackOff(_ mutation: PendingMutation, now: Date) -> Bool {
        guard let lastAttemptAt = mutation.lastAttemptAt else { return false }
        let delay = min(60.0 * pow(2.0, Double(max(0, mutation.attempts - 1))), 30.0 * 60.0)
        return now.timeIntervalSince(lastAttemptAt) < delay
    }

    // MARK: - Private: Enqueue

    private func enqueueSave<T: Encodable & Sendable>(
        records: [T],
        recordType: String
    ) async {
        do {
            let encodedData = try encoder.encode(records)
            let mutation = PendingMutation(
                recordType: recordType,
                operation: .save,
                encodedData: encodedData
            )
            await store.append(mutation)
        } catch {
            lastFlushError = "Failed to encode mutation for queueing: \(error.localizedDescription)"
        }
    }

    private func enqueueDelete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async {
        let ids = recordIDs.map { $0.recordName }
        do {
            let encodedData = try encoder.encode(ids)
            let mutation = PendingMutation(
                recordType: recordType,
                operation: .delete(recordIDs: ids),
                encodedData: encodedData
            )
            await store.append(mutation)
        } catch {
            lastFlushError = "Failed to encode delete mutation: \(error.localizedDescription)"
        }
    }

    // MARK: - Private: Replay

    private func replay(_ mutation: PendingMutation) async throws {
        switch mutation.operation {
        case .save:
            // The encoded data is a JSON array of record dictionaries.
            // Split into individual elements and replay through saveFromJSON.
            let jsonArray = try JSONSerialization.jsonObject(with: mutation.encodedData)

            var individualRecords: [Data] = []
            if let array = jsonArray as? [[String: Any]] {
                for dict in array {
                    individualRecords.append(try JSONSerialization.data(withJSONObject: dict))
                }
            } else if let dict = jsonArray as? [String: Any] {
                individualRecords.append(try JSONSerialization.data(withJSONObject: dict))
            } else {
                throw SyncQueueError.decodeFailed("Unexpected JSON structure in save payload")
            }

            try await wrappedClient.saveFromJSON(individualRecords, recordType: mutation.recordType)

        case .delete(let recordIDs):
            let ckRecordIDs = recordIDs.map { CKRecord.ID(recordName: $0) }
            try await wrappedClient.delete(recordIDs: ckRecordIDs, recordType: mutation.recordType)
        }
    }
}
