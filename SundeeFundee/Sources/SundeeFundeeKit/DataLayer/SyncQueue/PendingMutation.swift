import Foundation

// MARK: - MutationOperation

/// Represents the type of data operation that was queued for later retry.
public enum MutationOperation: Codable, Sendable, Equatable {
    /// Save one or more records of the given type.
    case save
    /// Delete records by their string IDs.
    case delete(recordIDs: [String])
}

// MARK: - PendingMutation

/// A single data mutation that failed due to network conditions and is waiting
/// to be replayed when connectivity returns.
///
/// Mutations are persisted to UserDefaults so they survive app restarts.
/// Each mutation captures everything needed to replay the operation:
/// the operation type, the record type, and the encoded payload.
public struct PendingMutation: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for deduplication.
    public let id: UUID

    /// The CloudKit record type (e.g. "Workout", "OneRepMaxRecord").
    public let recordType: String

    /// The operation to replay.
    public let operation: MutationOperation

    /// JSON-encoded payload — records for saves, record IDs for deletes.
    public let encodedData: Data

    /// When this mutation was first enqueued.
    public let enqueuedAt: Date

    /// How many times we've tried to flush this mutation.
    public var attempts: Int

    public init(
        id: UUID = UUID(),
        recordType: String,
        operation: MutationOperation,
        encodedData: Data,
        enqueuedAt: Date = Date(),
        attempts: Int = 0
    ) {
        self.id = id
        self.recordType = recordType
        self.operation = operation
        self.encodedData = encodedData
        self.enqueuedAt = enqueuedAt
        self.attempts = attempts
    }
}

// MARK: - SyncQueueStore

/// Persists pending mutations to UserDefaults so they survive app restarts.
///
/// Uses a configurable UserDefaults (defaults to .standard, can be an App Group suite)
/// and stores mutations as a JSON array under a fixed key.
public actor SyncQueueStore: Sendable {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let storageKey = "sync_queue_pending_mutations"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// In-memory cache of pending mutations, loaded from disk on init.
    private var mutations: [PendingMutation]

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Load from disk
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                self.mutations = try decoder.decode([PendingMutation].self, from: data)
            } catch {
                // Corrupted data — clear and start fresh
                print("[SyncQueueStore] Failed to decode persisted mutations: \(error). Clearing queue.")
                self.mutations = []
                userDefaults.removeObject(forKey: storageKey)
            }
        } else {
            self.mutations = []
        }
    }

    // MARK: - Public API

    /// Number of mutations waiting to be flushed.
    public var pendingCount: Int {
        mutations.count
    }

    /// All pending mutations in enqueue order (oldest first).
    public func allMutations() -> [PendingMutation] {
        mutations
    }

    /// Appends a new mutation and persists to disk.
    public func append(_ mutation: PendingMutation) {
        mutations.append(mutation)
        persistToDisk()
    }

    /// Removes mutations with the given IDs and persists the change.
    public func remove(ids: Set<UUID>) {
        mutations.removeAll { ids.contains($0.id) }
        persistToDisk()
    }

    /// Increments the attempt counter for mutations with the given IDs and persists.
    public func incrementAttempts(ids: Set<UUID>) {
        for index in mutations.indices {
            if ids.contains(mutations[index].id) {
                mutations[index].attempts += 1
            }
        }
        persistToDisk()
    }

    /// Removes all pending mutations and clears disk storage.
    public func removeAll() {
        mutations = []
        userDefaults.removeObject(forKey: storageKey)
    }

    // MARK: - Private

    private func persistToDisk() {
        do {
            let data = try encoder.encode(mutations)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("[SyncQueueStore] Failed to persist mutations: \(error)")
        }
    }
}
