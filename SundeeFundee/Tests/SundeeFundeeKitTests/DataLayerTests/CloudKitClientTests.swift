import CloudKit
import XCTest
@testable import SundeeFundeeKit

// MARK: - CloudKitClientTests
//
// NOTE: CloudKit tests require a real iCloud container and cannot run in CI.
// These tests are commented out and should be run manually with proper provisioning.
// Use MockCloudKitClient for unit testing instead.

/*
final class CloudKitClientTests: XCTestCase {
    var sut: CloudKitClient!

    override func setUp() {
        sut = CloudKitClient(containerIdentifier: "iCloud.com.test.container")
    }

    override func tearDown() {
        sut = nil
    }

    func testInit_WithContainerIdentifier_CreatesClient() async {
        let client = CloudKitClient(containerIdentifier: "iCloud.com.example.app")
        XCTAssertNotNil(client)
    }
}
*/

// MARK: - DataError Tests (these can run without CloudKit)

final class DataErrorTests: XCTestCase {
    func testRecordNotFound_Description() {
        let recordID = CKRecord.ID(recordName: "test-record-123")
        let error = DataError.recordNotFound(recordID: recordID)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("test-record-123"))
    }

    func testNetworkError_WithUnderlying_Description() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = DataError.networkError(underlying: underlying)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Network error"))
    }

    func testNetworkError_WithoutUnderlying_Description() {
        let error = DataError.networkError(underlying: nil)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertEqual(description, "Network error occurred")
    }

    func testPermissionDenied_Description() {
        let error = DataError.permissionDenied

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Permission denied"))
    }

    func testInvalidData_Description() {
        let error = DataError.invalidData(description: "Missing required field")

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Missing required field"))
    }

    func testRecoverySuggestion_RecordNotFound() {
        let error = DataError.recordNotFound(recordID: CKRecord.ID(recordName: "test"))

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("refreshing"))
    }

    func testRecoverySuggestion_NetworkError() {
        let error = DataError.networkError(underlying: nil)

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("internet connection"))
    }

    func testRecoverySuggestion_PermissionDenied() {
        let error = DataError.permissionDenied

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("iCloud"))
    }
}

// MARK: - MockCloudKitClient Upsert Tests

final class MockCloudKitClientUpsertTests: XCTestCase {
    private var sut: MockCloudKitClient!

    override func setUp() {
        sut = MockCloudKitClient()
    }

    override func tearDown() {
        sut = nil
    }

    func testSave_NewRecord_InsertsSuccessfully() async throws {
        let record = EnrolledProgramRecord(id: "prog-1", name: "Test Program", isActive: true)
        try await sut.save(record, recordType: "EnrolledProgramRecord")

        XCTAssertEqual(sut.recordCount(for: "EnrolledProgramRecord"), 1)

        let fetched: [EnrolledProgramRecord] = try await sut.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "prog-1")
        XCTAssertEqual(fetched.first?.name, "Test Program")
        XCTAssertTrue(fetched.first!.isActive)
    }

    func testSave_ExistingRecord_UpdatesInPlace() async throws {
        let original = EnrolledProgramRecord(id: "prog-1", name: "Test Program", isActive: true)
        try await sut.save(original, recordType: "EnrolledProgramRecord")

        let updated = EnrolledProgramRecord(id: "prog-1", name: "Test Program Updated", isActive: false)
        try await sut.save(updated, recordType: "EnrolledProgramRecord")

        XCTAssertEqual(sut.recordCount(for: "EnrolledProgramRecord"), 1)

        let fetched: [EnrolledProgramRecord] = try await sut.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Program Updated")
        XCTAssertFalse(fetched.first!.isActive)
    }

    func testSave_MultipleRecordsSameID_ResultsInSingleRecord() async throws {
        for i in 0..<3 {
            let record = EnrolledProgramRecord(id: "prog-1", name: "Attempt \(i)", isActive: true)
            try await sut.save(record, recordType: "EnrolledProgramRecord")
        }

        XCTAssertEqual(sut.recordCount(for: "EnrolledProgramRecord"), 1)

        let fetched: [EnrolledProgramRecord] = try await sut.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(fetched.first?.name, "Attempt 2")
    }

    func testSave_DifferentRecords_CreatesSeparateEntries() async throws {
        let record1 = EnrolledProgramRecord(id: "prog-1", name: "Program 1", isActive: true)
        let record2 = EnrolledProgramRecord(id: "prog-2", name: "Program 2", isActive: true)
        try await sut.save(record1, recordType: "EnrolledProgramRecord")
        try await sut.save(record2, recordType: "EnrolledProgramRecord")

        XCTAssertEqual(sut.recordCount(for: "EnrolledProgramRecord"), 2)
    }
}
