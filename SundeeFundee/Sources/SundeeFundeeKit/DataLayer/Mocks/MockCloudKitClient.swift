import CloudKit
import Foundation

// MARK: - MockCloudKitClient

/// A mock implementation of `DataClientProtocol` for unit testing.
///
/// `MockCloudKitClient` provides an in-memory storage solution that simulates
/// CloudKit operations without requiring network access. It's designed for
/// use in unit tests to verify data layer behavior in isolation.
///
/// ## Thread Safety
/// This class uses a serial dispatch queue for thread-safe access to storage.
/// All operations are synchronized to prevent data races in concurrent tests.
///
/// ## Example Usage
/// ```swift
/// let mockClient = MockCloudKitClient()
///
/// // Save test data
/// try await mockClient.save([workout], recordType: "Workout")
///
/// // Fetch back
/// let workouts: [Workout] = try await mockClient.fetch(
///     recordType: "Workout",
///     predicate: NSPredicate(value: true),
///     sortDescriptors: nil
/// )
///
/// // Reset for next test
/// mockClient.reset()
/// ```
public final class MockCloudKitClient: DataClientProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// In-memory storage grouped by record type.
    /// Each record is stored as a dictionary representation.
    private var storage: [String: [[String: Any]]] = [:]

    /// Serial queue for thread-safe access.
    private let queue = DispatchQueue(label: "com.sundeefundee.mock-cloudkit-client", qos: .userInitiated)

    /// JSON encoder for serializing records.
    private let encoder: JSONEncoder

    /// JSON decoder for deserializing records.
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a new MockCloudKitClient with empty storage.
    public init() {
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - DataClientProtocol

    /// Fetches records of the specified type matching the given predicate.
    ///
    /// - Parameters:
    ///   - recordType: The record type identifier.
    ///   - predicate: The predicate to filter records (basic support).
    ///   - sortDescriptors: Optional sort descriptors for ordering results.
    /// - Returns: An array of decoded model objects.
    /// - Throws: `DataError` if decoding fails.
    public func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        // Get records for this type (thread-safe)
        let records = queue.sync {
            storage[recordType] ?? []
        }

        // Filter records using predicate
        let filteredRecords = records.filter { record in
            evaluatePredicate(predicate, against: record)
        }

        // Sort records if sort descriptors provided
        let sortedRecords: [[String: Any]]
        if let sortDescriptors = sortDescriptors, !sortDescriptors.isEmpty {
            sortedRecords = filteredRecords.sorted { record1, record2 in
                for descriptor in sortDescriptors {
                    guard let key = descriptor.key else { continue }
                    let ascending = descriptor.ascending

                    let value1 = record1[key]
                    let value2 = record2[key]

                    let comparison = compareValues(value1, value2)
                    if comparison != .orderedSame {
                        return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
                    }
                }
                return false
            }
        } else {
            sortedRecords = filteredRecords
        }

        // Decode records to type T
        var results: [T] = []
        for record in sortedRecords {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: record)
                let decoded = try decoder.decode(T.self, from: jsonData)
                results.append(decoded)
            } catch {
                throw DataError.invalidData(description: "Failed to decode record: \(error.localizedDescription)")
            }
        }

        return results
    }

    /// Saves records to in-memory storage.
    ///
    /// - Parameters:
    ///   - records: The model objects to save.
    ///   - recordType: The record type identifier.
    /// - Throws: `DataError` if encoding fails.
    public func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard !records.isEmpty else { return }

        for record in records {
            var jsonDict: [String: Any]
            do {
                // Encode to JSON data
                let jsonData = try encoder.encode(record)

                // Convert to dictionary
                guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    throw DataError.invalidData(description: "Failed to serialize record to JSON dictionary")
                }
                jsonDict = dict
            } catch let error as DataError {
                throw error
            } catch {
                throw DataError.invalidData(description: "Failed to encode record: \(error.localizedDescription)")
            }

            // Ensure ID exists
            if jsonDict["id"] == nil {
                jsonDict["id"] = UUID().uuidString
            }

            // Thread-safe storage update
            queue.sync {
                // Initialize storage for this record type if needed
                if storage[recordType] == nil {
                    storage[recordType] = []
                }

                // Check if record with this ID already exists
                if let id = jsonDict["id"] as? String {
                    if let existingIndex = storage[recordType]?.firstIndex(where: { $0["id"] as? String == id }) {
                        // Update existing record
                        storage[recordType]?[existingIndex] = jsonDict
                        return
                    }
                }

                // Add new record
                storage[recordType]?.append(jsonDict)
            }
        }
    }

    /// Deletes records from in-memory storage.
    ///
    /// - Parameters:
    ///   - recordIDs: The IDs of the records to delete.
    ///   - recordType: The record type identifier.
    public func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        guard !recordIDs.isEmpty else { return }

        let idsToDelete = Set(recordIDs.map { $0.recordName })

        queue.sync {
            storage[recordType]?.removeAll { record in
                guard let id = record["id"] as? String else {
                    return false
                }
                return idsToDelete.contains(id)
            }
        }
    }

    /// Deletes all data from the database.
    ///
    /// Used for account deletion to ensure no user data remains.
    /// - Throws: `DataError` if the operation fails.
    public func deleteAllData() async throws {
        reset()
    }

    // MARK: - Test Helpers

    /// Clears all stored data.
    ///
    /// Call this method between tests to ensure a clean state.
    public func reset() {
        queue.sync {
            storage.removeAll()
        }
    }

    /// Returns the count of stored records for a given record type.
    ///
    /// - Parameter recordType: The record type identifier.
    /// - Returns: The number of stored records.
    public func recordCount(for recordType: String) -> Int {
        queue.sync {
            storage[recordType]?.count ?? 0
        }
    }

    /// Returns all stored record types.
    ///
    /// - Returns: An array of record type identifiers that have stored data.
    public func storedRecordTypes() -> [String] {
        queue.sync {
            Array(storage.keys)
        }
    }

    // MARK: - Private Helpers

    /// Evaluates a predicate against a record dictionary.
    ///
    /// - Parameters:
    ///   - predicate: The predicate to evaluate.
    ///   - record: The record dictionary to evaluate against.
    /// - Returns: Whether the record matches the predicate.
    private func evaluatePredicate(_ predicate: NSPredicate, against record: [String: Any]) -> Bool {
        // Handle common predicate types
        if predicate.predicateFormat == "TRUEPREDICATE" {
            return true
        }

        if predicate.predicateFormat == "FALSEPREDICATE" {
            return false
        }

        // Handle compound predicates
        if let compound = predicate as? NSCompoundPredicate {
            switch compound.compoundPredicateType {
            case .and:
                return compound.subpredicates.allSatisfy {
                    guard let pred = $0 as? NSPredicate else { return false }
                    return evaluatePredicate(pred, against: record)
                }
            case .or:
                return compound.subpredicates.contains {
                    guard let pred = $0 as? NSPredicate else { return false }
                    return evaluatePredicate(pred, against: record)
                }
            case .not:
                guard let subpredicate = compound.subpredicates.first as? NSPredicate else {
                    return false
                }
                return !evaluatePredicate(subpredicate, against: record)
            default:
                return true
            }
        }

        // Handle comparison predicates
        if let comparison = predicate as? NSComparisonPredicate {
            return evaluateComparisonPredicate(comparison, against: record)
        }

        // Default to true for unsupported predicates
        return true
    }

    /// Evaluates a comparison predicate against a record.
    private func evaluateComparisonPredicate(
        _ predicate: NSComparisonPredicate,
        against record: [String: Any]
    ) -> Bool {
        // Extract left and right values
        let leftValue: Any?
        let rightValue: Any?

        // Get left expression value
        let leftExpr = predicate.leftExpression
        switch leftExpr.expressionType {
        case .keyPath:
            leftValue = record[leftExpr.keyPath]
        case .constantValue:
            leftValue = leftExpr.constantValue
        default:
            leftValue = nil
        }

        // Get right expression value
        let rightExpr = predicate.rightExpression
        switch rightExpr.expressionType {
        case .keyPath:
            rightValue = record[rightExpr.keyPath]
        case .constantValue:
            rightValue = rightExpr.constantValue
        default:
            rightValue = nil
        }

        // Compare values based on predicate operator
        let comparison = compareValues(leftValue, rightValue)

        switch predicate.predicateOperatorType {
        case .equalTo:
            return comparison == .orderedSame
        case .notEqualTo:
            return comparison != .orderedSame
        case .lessThan:
            return comparison == .orderedAscending
        case .lessThanOrEqualTo:
            return comparison == .orderedAscending || comparison == .orderedSame
        case .greaterThan:
            return comparison == .orderedDescending
        case .greaterThanOrEqualTo:
            return comparison == .orderedDescending || comparison == .orderedSame
        default:
            return true
        }
    }

    /// Compares two values and returns their ordering.
    private func compareValues(_ value1: Any?, _ value2: Any?) -> ComparisonResult {
        // Handle nil cases
        if value1 == nil && value2 == nil {
            return .orderedSame
        }
        if value1 == nil {
            return .orderedAscending
        }
        if value2 == nil {
            return .orderedDescending
        }

        // Compare strings
        if let str1 = value1 as? String, let str2 = value2 as? String {
            return str1.compare(str2)
        }

        // Compare numbers
        if let num1 = value1 as? NSNumber, let num2 = value2 as? NSNumber {
            return num1.compare(num2)
        }

        // Compare dates
        if let date1 = value1 as? Date, let date2 = value2 as? Date {
            return date1.compare(date2)
        }

        // Compare ISO8601 date strings
        if let str1 = value1 as? String, let str2 = value2 as? String {
            let formatter = ISO8601DateFormatter()
            if let date1 = formatter.date(from: str1),
               let date2 = formatter.date(from: str2) {
                return date1.compare(date2)
            }
        }

        return .orderedSame
    }
}
