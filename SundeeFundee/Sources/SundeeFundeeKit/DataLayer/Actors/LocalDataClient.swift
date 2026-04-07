import CloudKit
import Foundation

// MARK: - LocalDataClient
//
// UserDefaults-backed persistent data client for guest users.
// Implements the same DataClientProtocol as CloudKitClient so all ViewModels
// work without modification. Data survives app restarts but stays on-device only.

public actor LocalDataClient: @preconcurrency DataClientProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let keyPrefix = "local_data_"

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - DataClientProtocol

    public func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        let records = load(recordType: recordType)
        let filtered = records.filter { predicate.evaluate(with: $0 as NSDictionary) }

        let sorted: [[String: Any]]
        if let descriptors = sortDescriptors, !descriptors.isEmpty {
            sorted = (filtered as NSArray).sortedArray(using: descriptors) as? [[String: Any]] ?? filtered
        } else {
            sorted = filtered
        }

        return try sorted.map { record in
            let jsonData = try JSONSerialization.data(withJSONObject: record)
            return try decoder.decode(T.self, from: jsonData)
        }
    }

    public func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard !records.isEmpty else { return }

        var existing = load(recordType: recordType)

        for record in records {
            let jsonData = try encoder.encode(record)
            guard var jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw DataError.invalidData(description: "Failed to serialize record")
            }

            if jsonDict["id"] == nil {
                jsonDict["id"] = UUID().uuidString
            }

            if let id = jsonDict["id"] as? String,
               let idx = existing.firstIndex(where: { $0["id"] as? String == id }) {
                existing[idx] = jsonDict
            } else {
                existing.append(jsonDict)
            }
        }

        persist(existing, recordType: recordType)
    }

    public func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        let idsToDelete = Set(recordIDs.map { $0.recordName })
        var existing = load(recordType: recordType)
        existing.removeAll { record in
            guard let id = record["id"] as? String else { return false }
            return idsToDelete.contains(id)
        }
        persist(existing, recordType: recordType)
    }

    public func deleteAllData() async throws {
        clearAll()
    }

    // MARK: - Helpers

    /// Removes all locally stored data — call when a guest signs out.
    private func clearAll() {
        userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .forEach { userDefaults.removeObject(forKey: $0) }
    }

    // MARK: - Private

    private func storageKey(for recordType: String) -> String {
        "\(keyPrefix)\(recordType)"
    }

    private func load(recordType: String) -> [[String: Any]] {
        guard let data = userDefaults.data(forKey: storageKey(for: recordType)),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return array
    }

    public func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws {
        guard !jsonRecords.isEmpty else { return }
        // For local client, parse each JSON record and a dictionary and save
        for jsonData in jsonRecords {
            guard var dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw DataError.invalidData(description: "Failed to parse JSON record for local save")
            }
            var existing = load(recordType: recordType)

            if dict["id"] == nil {
                dict["id"] = UUID().uuidString
            }

            if let id = dict["id"] as? String,
               let idx = existing.firstIndex(where: { $0["id"] as? String == id }) {
                existing[idx] = dict
            } else {
                existing.append(dict)
            }

            persist(existing, recordType: recordType)
        }
    }

    private func persist(_ records: [[String: Any]], recordType: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: records) else { return }
        userDefaults.set(data, forKey: storageKey(for: recordType))
    }
}

