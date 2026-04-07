import CloudKit
@preconcurrency import Foundation

// NSPredicate and NSSortDescriptor are immutable after creation and thread-safe
// in practice, but Foundation hasn't formally added Sendable conformances yet.
extension NSPredicate: @retroactive @unchecked Sendable {}
extension NSSortDescriptor: @retroactive @unchecked Sendable {}

// MARK: - DataError

/// Errors that can occur during CloudKit data operations.
public enum DataError: Error, LocalizedError, Sendable {
    case recordNotFound(recordID: CKRecord.ID)
    case networkError(underlying: Error?)
    case permissionDenied
    case invalidData(description: String)

    public var errorDescription: String? {
        switch self {
        case .recordNotFound(let recordID):
            return "Record not found: \(recordID.recordName)"
        case .networkError(let underlying):
            if let underlying = underlying {
                return "Network error: \(underlying.localizedDescription)"
            }
            return "Network error occurred"
        case .permissionDenied:
            return "Permission denied. Please check iCloud settings."
        case .invalidData(let description):
            return "Invalid data: \(description)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .recordNotFound:
            return "The record may have been deleted. Try refreshing your data."
        case .networkError:
            return "Check your internet connection and try again."
        case .permissionDenied:
            return "Sign in to iCloud in Settings and ensure the app has access."
        case .invalidData:
            return "Contact support if this issue persists."
        }
    }
}

// MARK: - DataClientProtocol

/// Protocol defining CloudKit data operations.
///
/// Implementations handle fetching, saving, and deleting records from CloudKit.
/// The generic `T` parameter represents the model type that conforms to `Decodable` and `Sendable`.
///
/// ## Example Usage
/// ```swift
/// let workouts = try await dataClient.fetch(
///     recordType: "Workout",
///     predicate: NSPredicate(value: true),
///     sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
/// )
/// ```
public protocol DataClientProtocol: Sendable {
    /// Fetches records of the specified type matching the given predicate.
    ///
    /// - Parameters:
    ///   - recordType: The CloudKit record type identifier.
    ///   - predicate: The predicate to filter records.
    ///   - sortDescriptors: Optional sort descriptors for ordering results.
    /// - Returns: An array of decoded model objects.
    /// - Throws: `DataError` if the fetch operation fails.
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable

    /// Saves records to CloudKit.
    ///
    /// - Parameters:
    ///   - records: The model objects to save.
    ///   - recordType: The CloudKit record type identifier.
    /// - Throws: `DataError` if the save operation fails.
    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable

    /// Deletes records from CloudKit.
    ///
    /// - Parameters:
    ///   - recordIDs: The IDs of the records to delete.
    ///   - recordType: The CloudKit record type identifier.
    /// - Throws: `DataError` if the delete operation fails.
    func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws

    /// Deletes all data from the database.
    ///
    /// Used for account deletion to ensure no user data remains.
    /// - Throws: `DataError` if the operation fails.
    func deleteAllData() async throws

    /// Saves records from raw JSON data.
    ///
    /// Used by SyncQueue to replay previously queued mutations without
    /// knowing the original Codable type. Each element of `jsonRecords`
    /// is a complete JSON object that will be deserialized and stored.
    ///
    /// - Parameters:
    ///   - jsonRecords: Array of raw JSON data, one per record.
    ///   - recordType: The CloudKit record type identifier.
    /// - Throws: `DataError` if the operation fails.
    func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws
}

// MARK: - Default Implementations

extension DataClientProtocol {
    /// Fetches all records of the specified type.
    public func fetchAll<T>(
        recordType: String,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [T] where T: Decodable & Sendable {
        try await fetch(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            sortDescriptors: sortDescriptors
        )
    }

    /// Saves a single record to CloudKit.
    public func save<T>(
        _ record: T,
        recordType: String
    ) async throws where T: Encodable & Sendable {
        try await save([record], recordType: recordType)
    }

    /// Saves records from raw JSON data (default: decode then delegate).
    public func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws {
        // No default implementation — clients must implement this
        // if they support offline replay.
        throw DataError.invalidData(description: "saveFromJSON not implemented")
    }

    /// Deletes a single record from CloudKit.
    public func delete(
        recordID: CKRecord.ID,
        recordType: String
    ) async throws {
        try await delete(recordIDs: [recordID], recordType: recordType)
    }

    /// Deletes a record by its string ID.
    public func delete(
        recordType: String,
        id: String
    ) async throws {
        let recordID = CKRecord.ID(recordName: id)
        try await delete(recordIDs: [recordID], recordType: recordType)
    }
}

