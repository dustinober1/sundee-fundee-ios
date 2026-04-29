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

    /// The most recent time we attempted to replay this mutation.
    public var lastAttemptAt: Date?

    public init(
        id: UUID = UUID(),
        recordType: String,
        operation: MutationOperation,
        encodedData: Data,
        enqueuedAt: Date = Date(),
        attempts: Int = 0,
        lastAttemptAt: Date? = nil
    ) {
        self.id = id
        self.recordType = recordType
        self.operation = operation
        self.encodedData = encodedData
        self.enqueuedAt = enqueuedAt
        self.attempts = attempts
        self.lastAttemptAt = lastAttemptAt
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
    private let stuckStorageKey = "sync_queue_stuck_mutations"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// In-memory cache of pending mutations, loaded from disk on init.
    private var mutations: [PendingMutation]

    /// Mutations that exceeded `maxRetryAttempts` and were moved out of the
    /// active queue. Persisted under a separate key so they survive restarts
    /// and can be surfaced in diagnostics UI.
    private var stuck: [PendingMutation]

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
                // Corrupted queue data — clear and rebuild on next mutation
                self.mutations = []
                userDefaults.removeObject(forKey: storageKey)
            }
        } else {
            self.mutations = []
        }

        if let stuckData = userDefaults.data(forKey: stuckStorageKey) {
            do {
                self.stuck = try decoder.decode([PendingMutation].self, from: stuckData)
            } catch {
                self.stuck = []
                userDefaults.removeObject(forKey: stuckStorageKey)
            }
        } else {
            self.stuck = []
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
    public func incrementAttempts(ids: Set<UUID>, lastAttemptAt: Date = Date()) {
        for index in mutations.indices {
            if ids.contains(mutations[index].id) {
                mutations[index].attempts += 1
                mutations[index].lastAttemptAt = lastAttemptAt
            }
        }
        persistToDisk()
    }

    /// Removes all pending mutations and clears disk storage.
    public func removeAll() {
        mutations = []
        userDefaults.removeObject(forKey: storageKey)
    }

    // MARK: - Stuck Mutations

    /// Mutations that exceeded the retry budget. Surfaced for diagnostics.
    public func allStuckMutations() -> [PendingMutation] {
        stuck
    }

    /// Moves the given mutations out of `pending` into `stuck` and persists both.
    /// IDs not found in `pending` are ignored.
    public func moveToStuck(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let moved = mutations.filter { ids.contains($0.id) }
        guard !moved.isEmpty else { return }
        mutations.removeAll { ids.contains($0.id) }
        stuck.append(contentsOf: moved)
        persistToDisk()
        persistStuckToDisk()
    }

    /// Clears all stuck mutations (e.g. after the user acknowledges them).
    public func clearStuck() {
        stuck = []
        userDefaults.removeObject(forKey: stuckStorageKey)
    }

    // MARK: - Private

    private func persistToDisk() {
        do {
            let data = try encoder.encode(mutations)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Persistence failure — mutations will be lost on restart but app continues
        }
    }

    private func persistStuckToDisk() {
        do {
            let data = try encoder.encode(stuck)
            userDefaults.set(data, forKey: stuckStorageKey)
        } catch {
            // Persistence failure — stuck mutations may be lost on restart
        }
    }
}
