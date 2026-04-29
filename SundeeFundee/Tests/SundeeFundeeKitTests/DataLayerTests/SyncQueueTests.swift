import XCTest
@testable import SundeeFundeeKit

// MARK: - PendingMutation Tests

final class PendingMutationTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testSaveOperationRoundTrip() throws {
        let data = try JSONEncoder().encode("test-payload")
        let mutation = PendingMutation(
            id: UUID(),
            recordType: "Workout",
            operation: .save,
            encodedData: data,
            enqueuedAt: Date()
        )

        let encoded = try JSONEncoder().encode(mutation)
        let decoded = try JSONDecoder().decode(PendingMutation.self, from: encoded)

        XCTAssertEqual(decoded.id, mutation.id)
        XCTAssertEqual(decoded.recordType, "Workout")
        XCTAssertEqual(decoded.operation, .save)
        XCTAssertEqual(decoded.encodedData, data)
        XCTAssertEqual(decoded.attempts, 0)
    }

    func testDeleteOperationRoundTrip() throws {
        let recordIDs = ["id-1", "id-2", "id-3"]
        let data = try JSONEncoder().encode(recordIDs)
        let mutation = PendingMutation(
            recordType: "Workout",
            operation: .delete(recordIDs: recordIDs),
            encodedData: data
        )

        let encoded = try JSONEncoder().encode(mutation)
        let decoded = try JSONDecoder().decode(PendingMutation.self, from: encoded)

        if case .delete(let ids) = decoded.operation {
            XCTAssertEqual(ids, recordIDs)
        } else {
            XCTFail("Expected delete operation")
        }
    }

    func testMutationEquality() throws {
        let id = UUID()
        let data = Data()
        let enqueuedAt = Date()
        let m1 = PendingMutation(id: id, recordType: "Workout", operation: .save, encodedData: data, enqueuedAt: enqueuedAt)
        let m2 = PendingMutation(id: id, recordType: "Workout", operation: .save, encodedData: data, enqueuedAt: enqueuedAt)
        let m3 = PendingMutation(id: UUID(), recordType: "Workout", operation: .save, encodedData: data, enqueuedAt: enqueuedAt)

        XCTAssertEqual(m1, m2)
        XCTAssertNotEqual(m1, m3)
    }
}

// MARK: - SyncQueueStore Tests

final class SyncQueueStoreTests: XCTestCase {

    @MainActor
    func testStartsEmpty() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        let count = await store.pendingCount
        XCTAssertEqual(count, 0)
        let mutations = await store.allMutations()
        XCTAssertTrue(mutations.isEmpty)
    }

    @MainActor
    func testAppendIncreasesCount() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        let mutation = PendingMutation(
            recordType: "Workout",
            operation: .save,
            encodedData: Data()
        )

        await store.append(mutation)
        let count = await store.pendingCount
        XCTAssertEqual(count, 1)

        let mutations = await store.allMutations()
        XCTAssertEqual(mutations.first?.recordType, "Workout")
        XCTAssertEqual(mutations.first?.operation, .save)
    }

    @MainActor
    func testAppendMultipleMutations() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)

        for i in 0..<5 {
            let mutation = PendingMutation(
                recordType: "Type\(i)",
                operation: .save,
                encodedData: Data()
            )
            await store.append(mutation)
        }

        let count = await store.pendingCount
        XCTAssertEqual(count, 5)

        let mutations = await store.allMutations()
        XCTAssertEqual(mutations.map(\.recordType), ["Type0", "Type1", "Type2", "Type3", "Type4"])
    }

    @MainActor
    func testRemoveById() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        let id1 = UUID()
        let id2 = UUID()

        await store.append(PendingMutation(id: id1, recordType: "A", operation: .save, encodedData: Data()))
        await store.append(PendingMutation(id: id2, recordType: "B", operation: .save, encodedData: Data()))

        await store.remove(ids: [id1])

        let mutations = await store.allMutations()
        XCTAssertEqual(mutations.count, 1)
        XCTAssertEqual(mutations.first?.recordType, "B")
    }

    @MainActor
    func testRemoveNonexistentIdIsNoop() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        await store.append(PendingMutation(recordType: "A", operation: .save, encodedData: Data()))

        await store.remove(ids: [UUID()])

        let count = await store.pendingCount
        XCTAssertEqual(count, 1)
    }

    @MainActor
    func testRemoveAll() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        await store.append(PendingMutation(recordType: "A", operation: .save, encodedData: Data()))
        await store.append(PendingMutation(recordType: "B", operation: .save, encodedData: Data()))

        await store.removeAll()

        let count = await store.pendingCount
        XCTAssertEqual(count, 0)
    }

    // MARK: - Persistence

    @MainActor
    func testMutationsPersistAcrossInstances() async {
        let suiteName = "Test.SyncQueueStore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let mutation = PendingMutation(
            recordType: "Workout",
            operation: .save,
            encodedData: try! JSONEncoder().encode("payload")
        )

        let store1 = SyncQueueStore(userDefaults: defaults)
        await store1.append(mutation)

        // New instance reading from same UserDefaults
        let defaults2 = UserDefaults(suiteName: suiteName)!
        let store2 = SyncQueueStore(userDefaults: defaults2)
        let count = await store2.pendingCount
        XCTAssertEqual(count, 1)

        let mutations = await store2.allMutations()
        XCTAssertEqual(mutations.first?.recordType, "Workout")
        XCTAssertEqual(mutations.first?.id, mutation.id)
    }

    @MainActor
    func testRemovePersistsAcrossInstances() async {
        let suiteName = "Test.SyncQueueStore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let id = UUID()
        let store1 = SyncQueueStore(userDefaults: defaults)
        await store1.append(PendingMutation(id: id, recordType: "A", operation: .save, encodedData: Data()))
        await store1.append(PendingMutation(recordType: "B", operation: .save, encodedData: Data()))
        await store1.remove(ids: [id])

        let defaults2 = UserDefaults(suiteName: suiteName)!
        let store2 = SyncQueueStore(userDefaults: defaults2)
        let mutations = await store2.allMutations()
        XCTAssertEqual(mutations.count, 1)
        XCTAssertEqual(mutations.first?.recordType, "B")
    }

    // MARK: - Attempt Tracking

    @MainActor
    func testIncrementAttempts() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        let id1 = UUID()
        let id2 = UUID()

        await store.append(PendingMutation(id: id1, recordType: "A", operation: .save, encodedData: Data()))
        await store.append(PendingMutation(id: id2, recordType: "B", operation: .save, encodedData: Data()))

        let attemptDate = Date(timeIntervalSince1970: 1_700_000_000)
        await store.incrementAttempts(ids: [id1], lastAttemptAt: attemptDate)

        let mutations = await store.allMutations()
        XCTAssertEqual(mutations.first { $0.id == id1 }?.attempts, 1)
        XCTAssertEqual(mutations.first { $0.id == id1 }?.lastAttemptAt, attemptDate)
        XCTAssertEqual(mutations.first { $0.id == id2 }?.attempts, 0)
        XCTAssertNil(mutations.first { $0.id == id2 }?.lastAttemptAt)
    }

    @MainActor
    func testIncrementAttemptsMultipleTimes() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        let store = SyncQueueStore(userDefaults: defaults)
        let id = UUID()
        await store.append(PendingMutation(id: id, recordType: "A", operation: .save, encodedData: Data()))

        await store.incrementAttempts(ids: [id])
        await store.incrementAttempts(ids: [id])
        await store.incrementAttempts(ids: [id])

        let mutations = await store.allMutations()
        XCTAssertEqual(mutations.first?.attempts, 3)
    }

    // MARK: - Corrupted Data Recovery

    @MainActor
    func testCorruptedDataRecovery() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        // Write garbage data to the storage key
        defaults.set(Data("not valid json".utf8), forKey: "sync_queue_pending_mutations")

        // Store should recover gracefully
        let store = SyncQueueStore(userDefaults: defaults)
        let count = await store.pendingCount
        XCTAssertEqual(count, 0, "Should start empty after corrupted data recovery")
    }

    @MainActor
    func testEmptyDataKey() async {
        let defaults = UserDefaults(suiteName: "Test.SyncQueueStore.\(UUID().uuidString)")!
        // No data at the key
        let store = SyncQueueStore(userDefaults: defaults)
        let count = await store.pendingCount
        XCTAssertEqual(count, 0)
    }
}
