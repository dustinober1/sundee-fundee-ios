import XCTest
@testable import SundeeFundeeKit

@MainActor
final class DiagnosticsServiceTests: XCTestCase {

    private struct TestError: Error, LocalizedError {
        let errorDescription: String?
    }

    func testStartsEmpty() {
        let service = DiagnosticsService()
        XCTAssertEqual(service.decodeFailureCount, 0)
        XCTAssertTrue(service.recentDecodeFailures.isEmpty)
    }

    func testRecordIncrementsCount() {
        let service = DiagnosticsService()
        service.recordDecodeFailure(
            recordType: "Workout",
            recordID: "abc",
            error: TestError(errorDescription: "bad data")
        )
        XCTAssertEqual(service.decodeFailureCount, 1)
        XCTAssertEqual(service.recentDecodeFailures.count, 1)
        XCTAssertEqual(service.recentDecodeFailures.first?.recordType, "Workout")
        XCTAssertEqual(service.recentDecodeFailures.first?.recordID, "abc")
    }

    func testTrimsTo50MostRecent() {
        let service = DiagnosticsService()
        for i in 0..<75 {
            service.recordDecodeFailure(
                recordType: "Type\(i)",
                recordID: "id-\(i)",
                error: TestError(errorDescription: "error \(i)")
            )
        }
        XCTAssertEqual(service.decodeFailureCount, 75, "Count tracks total, not buffer size")
        XCTAssertEqual(service.recentDecodeFailures.count, 50, "Buffer trims to 50")
        // FIFO: oldest 25 dropped; first kept should be Type25, last Type74.
        XCTAssertEqual(service.recentDecodeFailures.first?.recordType, "Type25")
        XCTAssertEqual(service.recentDecodeFailures.last?.recordType, "Type74")
    }

    func testInsertionOrderPreserved() {
        let service = DiagnosticsService()
        service.recordDecodeFailure(recordType: "A", recordID: "1", error: TestError(errorDescription: "e"))
        service.recordDecodeFailure(recordType: "B", recordID: "2", error: TestError(errorDescription: "e"))
        service.recordDecodeFailure(recordType: "C", recordID: "3", error: TestError(errorDescription: "e"))
        XCTAssertEqual(service.recentDecodeFailures.map(\.recordType), ["A", "B", "C"])
    }
}
