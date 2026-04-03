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
