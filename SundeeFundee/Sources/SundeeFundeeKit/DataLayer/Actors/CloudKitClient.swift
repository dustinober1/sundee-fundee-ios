import CloudKit
import Foundation
import os.log

private let ckLogger = Logger(subsystem: "com.sundeefundee.app", category: "CloudKit")

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
        do {
            let results: [T] = try await fetchWithQuery(query)
            ckLogger.info("✅ FETCH \(recordType): \(results.count) records")
            return results
        } catch {
            if isQueryableError(error) {
                ckLogger.error("❌ FETCH \(recordType): queryable/index error — \(error.localizedDescription)")
                throw DataError.schemaNotDeployed(
                    recordType: recordType,
                    detail: error.localizedDescription
                )
            }
            ckLogger.error("❌ FETCH \(recordType): \(error.localizedDescription)")
            throw error
        }
    }

    /// Checks if a CloudKit error is due to missing queryable indexes or unknown record types.
    private func isQueryableError(_ error: Error) -> Bool {
        let description = error.localizedDescription.lowercased()
        return description.contains("not marked queryable")
            || description.contains("not marked indexable")
            || description.contains("unknown item")
            || description.contains("record type does not exist")
            || description.contains("did not find record type")
    }

    /// Checks if a CloudKit error indicates a duplicate record insert.
    private func isDuplicateRecordError(_ error: Error) -> Bool {
        error.localizedDescription.lowercased().contains("record to insert already exists")
    }

    /// Detects whether an error is CKError.serverRecordChanged (client's changeTag is stale).
    ///
    /// Happens when another device (or an earlier in-flight save from the same device)
    /// has already updated the server copy since we last fetched it. The client's
    /// in-memory changeTag is out of date and CloudKit refuses the write. The fix is
    /// to re-merge against the server's current copy and retry once.
    private func isServerRecordChangedError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        return ckError.code == .serverRecordChanged
    }

    /// Extracts per-item errors from a CKError.partialFailure batch wrapper.
    ///
    /// `modifyRecords` can throw a batch-level `CKError.partialFailure` whose
    /// `userInfo[CKPartialErrorsByItemIDKey]` maps each record ID to its own error.
    /// Returns that map, or nil if the error is not a partialFailure.
    private func perItemErrors(from error: Error) -> [CKRecord.ID: Error]? {
        guard let ckError = error as? CKError else { return nil }
        if ckError.code == .partialFailure,
           let items = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error] {
            return items
        }
        return nil
    }

    /// Pulls `CKRecordChangedErrorServerRecordKey` out of each serverRecordChanged CKError.
    ///
    /// CloudKit attaches the server's current copy of the record to every
    /// `.serverRecordChanged` error — cheaper than re-fetching. Records without a
    /// server copy in userInfo are omitted (caller falls back to the original new record).
    private func extractServerRecords(from errors: [CKRecord.ID: Error]) -> [CKRecord.ID: CKRecord] {
        var map: [CKRecord.ID: CKRecord] = [:]
        for (id, error) in errors {
            guard let ckError = error as? CKError,
                  let server = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
            else { continue }
            map[id] = server
        }
        return map
    }

    /// Builds replacement CKRecords by overlaying new field values + nil-key clears
    /// onto the server copies returned in CKError.serverRecordChanged userInfo.
    ///
    /// For records without a server copy, falls back to the original newRecord —
    /// the retry will either succeed (new insert) or fail with a real error.
    private func mergeWithServerRecords(
        newRecords: [CKRecord],
        serverRecords: [CKRecord.ID: CKRecord],
        nilKeys: [CKRecord.ID: Set<String>]
    ) -> [CKRecord] {
        newRecords.map { newRecord in
            guard let serverCopy = serverRecords[newRecord.recordID] else {
                return newRecord
            }
            for key in newRecord.allKeys() {
                serverCopy[key] = newRecord[key]
            }
            if let keysToNil = nilKeys[newRecord.recordID] {
                for key in keysToNil {
                    serverCopy[key] = nil
                }
            }
            return serverCopy
        }
    }

    /// Final bounded-retry step — runs modifyRecords once and throws mapCKError on any failure.
    ///
    /// Bounded retry: caller must not invoke this in a loop. If this throws, the
    /// caller surfaces the error up to the user.
    private func retryModifyRecords(_ records: [CKRecord], recordType: String) async throws {
        let (savedRecords, _) = try await database.modifyRecords(saving: records, deleting: [])
        for (recordID, result) in savedRecords {
            if case .failure(let error) = result {
                throw mapCKError(error, recordID: recordID)
            }
        }
    }

    /// Saves records to CloudKit with upsert semantics (insert-or-update) and
    /// resolves changeTag conflicts via server-merge.
    ///
    /// First attempts a normal save. Two recovery paths are supported, each bounded
    /// to ONE additional attempt:
    /// 1. **Duplicate-on-insert** — CloudKit rejects a record because a record with
    ///    that ID already exists ("record to insert already exists"). We fetch the
    ///    existing record, overlay the new field values onto it (preserving the
    ///    server changeTag), and retry.
    /// 2. **ServerRecordChanged** — CloudKit rejects a record because our in-memory
    ///    changeTag is stale (another device updated the server copy). We use the
    ///    server's current CKRecord attached to the error's userInfo, overlay our
    ///    field values, and retry. This is the multi-device "oplock" fix.
    public func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard !records.isEmpty else { return }
        ckLogger.info("💾 SAVE \(recordType): \(records.count) records")

        var nilKeyMap: [CKRecord.ID: Set<String>] = [:]
        var ckRecords: [CKRecord] = []
        for record in records {
            let ckRecord = try encodeToCKRecord(record, recordType: recordType, nilKeyMap: &nilKeyMap)
            ckRecords.append(ckRecord)
        }

        do {
            let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])

            // Collect per-record errors; classify into duplicate, serverRecordChanged, or fatal
            var serverChangedErrors: [CKRecord.ID: Error] = [:]
            var duplicateDetected = false
            for (recordID, result) in savedRecords {
                if case .failure(let error) = result {
                    if isDuplicateRecordError(error) {
                        duplicateDetected = true
                    } else if isServerRecordChangedError(error) {
                        serverChangedErrors[recordID] = error
                    } else {
                        ckLogger.error("❌ SAVE \(recordType): record error — \(error.localizedDescription)")
                        throw mapCKError(error, recordID: recordID)
                    }
                }
            }

            if !serverChangedErrors.isEmpty {
                ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged for \(serverChangedErrors.count) record(s), merging with server copy")
                let serverCopies = extractServerRecords(from: serverChangedErrors)
                let merged = mergeWithServerRecords(
                    newRecords: ckRecords,
                    serverRecords: serverCopies,
                    nilKeys: nilKeyMap
                )
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE \(recordType): server-merge retry success")
                return
            }

            if duplicateDetected {
                ckLogger.info("🔄 SAVE \(recordType): duplicate detected, merging")
                let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
                let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: nilKeyMap) }
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE \(recordType): merge success")
                return
            }

            ckLogger.info("✅ SAVE \(recordType): success")
        } catch {
            // Batch-level throw: may wrap partialFailure with per-item serverRecordChanged,
            // or be a top-level duplicate/changeTag error.
            if let perItem = perItemErrors(from: error) {
                let serverChanged = perItem.filter { isServerRecordChangedError($0.value) }
                if !serverChanged.isEmpty {
                    ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged in batch (\(serverChanged.count)), merging with server copy")
                    let serverCopies = extractServerRecords(from: serverChanged)
                    let merged = mergeWithServerRecords(
                        newRecords: ckRecords,
                        serverRecords: serverCopies,
                        nilKeys: nilKeyMap
                    )
                    try await retryModifyRecords(merged, recordType: recordType)
                    ckLogger.info("✅ SAVE \(recordType): server-merge retry success")
                    return
                }
            }
            if isServerRecordChangedError(error),
               let ckError = error as? CKError,
               let serverRecord = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                ckLogger.info("🔄 SAVE \(recordType): serverRecordChanged (top-level), merging with server copy")
                let serverCopies: [CKRecord.ID: CKRecord] = [serverRecord.recordID: serverRecord]
                let merged = mergeWithServerRecords(
                    newRecords: ckRecords,
                    serverRecords: serverCopies,
                    nilKeys: nilKeyMap
                )
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE \(recordType): server-merge retry success")
                return
            }
            guard isDuplicateRecordError(error) else {
                ckLogger.error("❌ SAVE \(recordType): \(error.localizedDescription)")
                throw mapCKError(error, recordID: nil)
            }
            ckLogger.info("🔄 SAVE \(recordType): duplicate detected, merging")
            let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
            let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: nilKeyMap) }
            try await retryModifyRecords(merged, recordType: recordType)
            ckLogger.info("✅ SAVE \(recordType): merge success")
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
    /// replayed without knowing the original Codable type. Offline-queued mutations
    /// are especially prone to stale changeTags (the server has moved on while we
    /// were offline), so this path handles `serverRecordChanged` the same way
    /// `save()` does.
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

        // saveFromJSON has no nilKeyMap (raw JSON path) — pass an empty map throughout.
        let emptyNilKeys: [CKRecord.ID: Set<String>] = [:]

        do {
            let (savedRecords, _) = try await database.modifyRecords(saving: ckRecords, deleting: [])

            var serverChangedErrors: [CKRecord.ID: Error] = [:]
            var duplicateDetected = false
            for (recordID, result) in savedRecords {
                if case .failure(let error) = result {
                    if isDuplicateRecordError(error) {
                        duplicateDetected = true
                    } else if isServerRecordChangedError(error) {
                        serverChangedErrors[recordID] = error
                    } else {
                        throw mapCKError(error, recordID: recordID)
                    }
                }
            }

            if !serverChangedErrors.isEmpty {
                ckLogger.info("🔄 SAVE-JSON \(recordType): serverRecordChanged for \(serverChangedErrors.count) record(s), merging with server copy")
                let serverCopies = extractServerRecords(from: serverChangedErrors)
                let merged = mergeWithServerRecords(
                    newRecords: ckRecords,
                    serverRecords: serverCopies,
                    nilKeys: emptyNilKeys
                )
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE-JSON \(recordType): server-merge retry success")
                return
            }

            if duplicateDetected {
                let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
                let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: emptyNilKeys) }
                try await retryModifyRecords(merged, recordType: recordType)
                return
            }
        } catch {
            // Batch-level throw: check partialFailure-wrapped serverRecordChanged first.
            if let perItem = perItemErrors(from: error) {
                let serverChanged = perItem.filter { isServerRecordChangedError($0.value) }
                if !serverChanged.isEmpty {
                    ckLogger.info("🔄 SAVE-JSON \(recordType): serverRecordChanged in batch (\(serverChanged.count)), merging")
                    let serverCopies = extractServerRecords(from: serverChanged)
                    let merged = mergeWithServerRecords(
                        newRecords: ckRecords,
                        serverRecords: serverCopies,
                        nilKeys: emptyNilKeys
                    )
                    try await retryModifyRecords(merged, recordType: recordType)
                    ckLogger.info("✅ SAVE-JSON \(recordType): server-merge retry success")
                    return
                }
            }
            if isServerRecordChangedError(error),
               let ckError = error as? CKError,
               let serverRecord = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                ckLogger.info("🔄 SAVE-JSON \(recordType): serverRecordChanged (top-level), merging with server copy")
                let serverCopies: [CKRecord.ID: CKRecord] = [serverRecord.recordID: serverRecord]
                let merged = mergeWithServerRecords(
                    newRecords: ckRecords,
                    serverRecords: serverCopies,
                    nilKeys: emptyNilKeys
                )
                try await retryModifyRecords(merged, recordType: recordType)
                ckLogger.info("✅ SAVE-JSON \(recordType): server-merge retry success")
                return
            }
            guard isDuplicateRecordError(error) else {
                throw mapCKError(error, recordID: nil)
            }
            let existingRecords = await fetchExistingRecords(ckRecords.map(\.recordID))
            let merged = ckRecords.map { mergeWithExisting($0, existing: existingRecords, nilKeys: emptyNilKeys) }
            try await retryModifyRecords(merged, recordType: recordType)
        }
    }

    // MARK: - Private Helpers

    /// Fetches existing CKRecords for the given record IDs.
    ///
    /// Returns a dictionary mapping record IDs to their existing CKRecords.
    /// Failures for individual records (e.g., not found) are silently skipped.
    private func fetchExistingRecords(_ recordIDs: [CKRecord.ID]) async -> [CKRecord.ID: CKRecord] {
        do {
            let results = try await database.records(for: recordIDs)
            var map: [CKRecord.ID: CKRecord] = [:]
            for (id, result) in results {
                if case .success(let record) = result {
                    map[id] = record
                }
            }
            return map
        } catch {
            return [:]
        }
    }

    /// Merges a new CKRecord with an existing one if present.
    ///
    /// If the record already exists in CloudKit, copies field values from the
    /// new record onto the existing record (preserving the server change tag).
    /// Also clears any fields that were nil in the source model.
    /// Otherwise returns the new record unchanged for a fresh insert.
    private func mergeWithExisting(_ newRecord: CKRecord, existing: [CKRecord.ID: CKRecord], nilKeys: [CKRecord.ID: Set<String>]) -> CKRecord {
        guard let existingRecord = existing[newRecord.recordID] else {
            return newRecord
        }
        for key in newRecord.allKeys() {
            existingRecord[key] = newRecord[key]
        }
        // Clear fields that were nil in the new record
        if let keysToNil = nilKeys[newRecord.recordID] {
            for key in keysToNil {
                existingRecord[key] = nil
            }
        }
        return existingRecord
    }

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
                    ckLogger.error("⚠️ DECODE \(record.recordType)/\(record.recordID.recordName): \(String(describing: error))")
                    ckLogger.error("⚠️ DECODE \(record.recordType)/\(record.recordID.recordName) keys: \(record.allKeys().joined(separator: ", "))")
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
                    ckLogger.error("⚠️ DECODE \(record.recordType)/\(record.recordID.recordName): \(String(describing: error))")
                    ckLogger.error("⚠️ DECODE \(record.recordType)/\(record.recordID.recordName) keys: \(record.allKeys().joined(separator: ", "))")
                    continue
                }
            case .failure(let error):
                throw mapCKError(error, recordID: nil)
            }
        }

        return (decodedResults, nextCursor)
    }

    /// Encodes an encodable value to a CKRecord and tracks which keys were nil.
    private func encodeToCKRecord<T: Encodable>(
        _ value: T,
        recordType: String,
        nilKeyMap: inout [CKRecord.ID: Set<String>]
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
        var keysWithNil = Set<String>()
        for (key, value) in jsonDict {
            guard key != "id" else { continue }
            if value is NSNull {
                keysWithNil.insert(key)
                continue
            }
            record[key] = convertToCKRecordValue(value) as? (any CKRecordValueProtocol)
        }
        if !keysWithNil.isEmpty {
            nilKeyMap[recordID] = keysWithNil
        }

        return record
    }

    /// ISO 8601 formatter (with fractional seconds) for round-tripping dates from CloudKit.
    private nonisolated(unsafe) static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Converts a JSON value to a CKRecord-compatible value.
    /// ISO 8601 date strings are converted to native Date objects so CloudKit
    /// stores them as TIMESTAMP, matching fields defined that way in the schema.
    private func convertToCKRecordValue(_ value: Any) -> Any? {
        if value is NSNull { return nil }
        switch value {
        case let stringValue as String:
            return stringValue
        case let intValue as Int:
            return intValue
        case let doubleValue as Double:
            return doubleValue
        case let boolValue as Bool:
            return boolValue
        case let arrayValue as [Any]:
            let converted = arrayValue.compactMap { convertToCKRecordValue($0) }
            // CloudKit requires typed arrays ([String], [Int], etc.).
            // [Any] does NOT conform to CKRecordValueProtocol and will be
            // silently dropped. Try typed casts first; if the array contains
            // mixed types or dicts-as-strings, serialize the whole thing as
            // a single JSON string.
            if let strings = converted as? [String] { return strings }
            if let ints = converted as? [Int] { return ints }
            if let doubles = converted as? [Double] { return doubles }
            // Fallback: serialize entire array as a JSON string
            if let data = try? JSONSerialization.data(withJSONObject: arrayValue),
               let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
            return nil
        case let dictValue as [String: Any]:
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
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
            // Convert CloudKit TIMESTAMP dates to ISO 8601 strings for JSONDecoder
            return Self.iso8601FractionalFormatter.string(from: dateValue)
        case let reference as CKRecord.Reference:
            return reference.recordID.recordName
        case let asset as CKAsset:
            return asset.fileURL?.absoluteString ?? ""
        case let stringValue as String:
            if let data = stringValue.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) {
                if json is [String: Any] || json is [Any] {
                    return json
                }
            }
            return stringValue
        case let arrayValue as [Any]:
            return arrayValue.map { convertFromCKRecordValue($0) }
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
