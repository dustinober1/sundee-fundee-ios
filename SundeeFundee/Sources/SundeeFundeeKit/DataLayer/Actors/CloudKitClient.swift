import CloudKit
import Foundation

// MARK: - CloudKitClient

/// Thread-safe client for CloudKit database operations.
///
/// `CloudKitClient` provides a type-safe interface for fetching, saving, and deleting
/// CloudKit records. It uses JSON encoding/decoding to convert between CloudKit records
/// and Swift model types.
///
/// ## Example Usage
/// ```swift
/// let client = CloudKitClient(containerIdentifier: "iCloud.com.example.app")
///
/// // Fetch workouts
/// let workouts: [Workout] = try await client.fetch(
///     recordType: "Workout",
///     predicate: NSPredicate(value: true),
///     sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
/// )
///
/// // Save a workout
/// try await client.save([workout], recordType: "Workout")
/// ```
public final class CloudKitClient: DataClientProtocol, @unchecked Sendable {
    // MARK: - Properties

    /// The CloudKit container.
    private let container: CKContainer

    /// The database to use (private by default).
    private let database: CKDatabase

    /// JSON encoder for serializing records.
    private let encoder: JSONEncoder

    /// JSON decoder for deserializing records.
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a CloudKitClient with the specified container identifier.
    ///
    /// - Parameters:
    ///   - containerIdentifier: The iCloud container identifier (e.g., "iCloud.com.example.app").
    ///   - databaseScope: The database scope to use (defaults to private).
    public init(
        containerIdentifier: String,
        databaseScope: CKDatabase.Scope = .private
    ) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.database(with: databaseScope)
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Creates a CloudKitClient with the default container.
    ///
    /// - Parameter databaseScope: The database scope to use (defaults to private).
    public init(databaseScope: CKDatabase.Scope = .private) {
        self.container = CKContainer.default()
        self.database = container.database(with: databaseScope)
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - DataClientProtocol

    /// Fetches records of the specified type matching the given predicate.
    public func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        return try await fetchWithQuery(query)
    }

    /// Saves records to CloudKit.
    public func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard !records.isEmpty else { return }

        var ckRecords: [CKRecord] = []
        for record in records {
            let ckRecord = try encodeToCKRecord(record, recordType: recordType)
            ckRecords.append(ckRecord)
        }

        let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])
        for (recordID, result) in savedRecords {
            switch result {
            case .failure(let error):
                throw mapCKError(error, recordID: recordID)
            default:
                break
            }
        }
    }

    /// Deletes records from CloudKit.
    public func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        guard !recordIDs.isEmpty else { return }

        let (_, deletedRecordIDs) = try await database.modifyRecords(
            saving: [],
            deleting: recordIDs
        )

        for (recordID, result) in deletedRecordIDs {
            switch result {
            case .failure(let error):
                throw mapCKError(error, recordID: recordID)
            default:
                break
            }
        }
    }

    /// Deletes all data in the private database.
    public func deleteAllData() async throws {
        do {
            _ = try await database.deleteRecordZone(withID: .default)
        } catch {
            throw mapCKError(error, recordID: nil)
        }
    }

    // MARK: - saveFromJSON (SyncQueue replay path)

    /// Saves records from raw JSON data without going through Codable.
    ///
    /// Parses each JSON element into a dictionary and creates CKRecords directly.
    /// This is the replay path for SyncQueue — it allows queued mutations to be
    /// replayed without knowing the original Codable type.
    public func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws {
        guard !jsonRecords.isEmpty else { return }

        var ckRecords: [CKRecord] = []

        for jsonData in jsonRecords {
            guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw DataError.invalidData(description: "Failed to parse JSON record")
            }

            let recordID: CKRecord.ID
            if let id = jsonDict["id"] as? String {
                recordID = CKRecord.ID(recordName: id)
            } else {
                recordID = CKRecord.ID(recordName: UUID().uuidString)
            }

            let record = CKRecord(recordType: recordType, recordID: recordID)
            for (key, value) in jsonDict {
                guard key != "id" else { continue }
                record[key] = convertToCKRecordValue(value) as? (any CKRecordValueProtocol)
            }
            ckRecords.append(record)
        }

        let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])
        for (recordID, result) in savedRecords {
            switch result {
            case .failure(let error):
                throw mapCKError(error, recordID: recordID)
            default:
                break
            }
        }
    }

    // MARK: - Private Helpers

    /// Performs the actual fetch with pagination support.
    private func fetchWithQuery<T: Decodable & Sendable>(
        _ query: CKQuery
    ) async throws -> [T] {
        var allResults: [T] = []
        var cursor: CKQueryOperation.Cursor?

        let (results, nextCursor): ([T], CKQueryOperation.Cursor?) = try await performQuery(query: query)
        allResults.append(contentsOf: results)
        cursor = nextCursor

        while let currentCursor = cursor {
            let (moreResults, nextCursor): ([T], CKQueryOperation.Cursor?) = try await performQueryContinuation(with: currentCursor)
            allResults.append(contentsOf: moreResults)
            cursor = nextCursor
        }

        return allResults
    }

    /// Performs a CKQuery and returns decoded results.
    private func performQuery<T: Decodable & Sendable>(
        query: CKQuery
    ) async throws -> ([T], CKQueryOperation.Cursor?) {
        let (results, cursor) = try await database.records(matching: query)

        var decodedResults: [T] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                do {
                    let decoded: T = try decodeFromCKRecord(record)
                    decodedResults.append(decoded)
                } catch {
                    continue
                }
            case .failure(let error):
                throw mapCKError(error, recordID: nil)
            }
        }

        return (decodedResults, cursor)
    }

    /// Performs a query continuation with a cursor.
    private func performQueryContinuation<T: Decodable & Sendable>(
        with cursor: CKQueryOperation.Cursor
    ) async throws -> ([T], CKQueryOperation.Cursor?) {
        let (results, nextCursor) = try await database.records(continuingMatchFrom: cursor)

        var decodedResults: [T] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                do {
                    let decoded: T = try decodeFromCKRecord(record)
                    decodedResults.append(decoded)
                } catch {
                    continue
                }
            case .failure(let error):
                throw mapCKError(error, recordID: nil)
            }
        }

        return (decodedResults, nextCursor)
    }

    /// Encodes an encodable value to a CKRecord.
    private func encodeToCKRecord<T: Encodable>(
        _ value: T,
        recordType: String
    ) throws -> CKRecord {
        let jsonData = try encoder.encode(value)

        guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw DataError.invalidData(description: "Failed to serialize to JSON dictionary")
        }

        let recordID: CKRecord.ID
        if let id = jsonDict["id"] as? String {
            recordID = CKRecord.ID(recordName: id)
        } else {
            recordID = CKRecord.ID(recordName: UUID().uuidString)
        }

        let record = CKRecord(recordType: recordType, recordID: recordID)
        for (key, value) in jsonDict {
            guard key != "id" else { continue }
            record[key] = convertToCKRecordValue(value) as? (any CKRecordValueProtocol)
        }

        return record
    }

    /// Converts a JSON value to a CKRecord-compatible value.
    private func convertToCKRecordValue(_ value: Any) -> Any? {
        switch value {
        case let stringValue as String:
            return stringValue
        case let intValue as Int:
            return intValue
        case let doubleValue as Double:
            return doubleValue
        case let boolValue as Bool:
            return boolValue
        case let dateValue as String:
            if let date = ISO8601DateFormatter().date(from: dateValue) {
                return date
            }
            return dateValue
        case let arrayValue as [Any]:
            return arrayValue.compactMap { convertToCKRecordValue($0) }
        case let dictValue as [String: Any]:
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return nil
        case Optional<Any>.none:
            return nil
        default:
            return nil
        }
    }

    /// Decodes a CKRecord to a decodable type.
    private func decodeFromCKRecord<T: Decodable>(_ record: CKRecord) throws -> T {
        var jsonDict: [String: Any] = ["id": record.recordID.recordName]

        for key in record.allKeys() {
            if let value = record[key] {
                jsonDict[key] = convertFromCKRecordValue(value)
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
        return try decoder.decode(T.self, from: jsonData)
    }

    /// Converts a CKRecord value to a JSON-compatible value.
    private func convertFromCKRecordValue(_ value: Any) -> Any {
        switch value {
        case let dateValue as Date:
            return ISO8601DateFormatter().string(from: dateValue)
        case let reference as CKRecord.Reference:
            return reference.recordID.recordName
        case let asset as CKAsset:
            return asset.fileURL?.absoluteString ?? ""
        default:
            return value
        }
    }

    /// Maps CKError to DataError.
    private func mapCKError(_ error: Error, recordID: CKRecord.ID?) -> DataError {
        guard let ckError = error as? CKError else {
            return .networkError(underlying: error)
        }

        switch ckError.code {
        case .unknownItem:
            if let recordID = recordID {
                return .recordNotFound(recordID: recordID)
            }
            return .recordNotFound(recordID: CKRecord.ID(recordName: "unknown"))
        case .networkFailure, .networkUnavailable, .serviceUnavailable:
            return .networkError(underlying: ckError)
        case .notAuthenticated, .permissionFailure:
            return .permissionDenied
        default:
            return .networkError(underlying: ckError)
        }
    }
}
