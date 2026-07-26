import CloudKit
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class QuickCheckInViewModelTests: XCTestCase {
    func testSaveSymptomOnlyCheckIn() async {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        let completionExpectation = expectation(
            forNotification: .dailyCheckInCompleted,
            object: nil
        )
        viewModel.energy = 7
        viewModel.fatigue = 3
        viewModel.soreness = 4
        viewModel.cramps = 1

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        await fulfillment(of: [completionExpectation], timeout: 0.1)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 0)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 0)
    }

    func testSavePainAndPeriodCheckIn() async {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        viewModel.energy = 5
        viewModel.fatigue = 6
        viewModel.soreness = 5
        viewModel.cramps = 4
        viewModel.hasPain = true
        viewModel.painIntensity = 6
        viewModel.painType = .soreness
        viewModel.isPeriodActive = true

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 1)
    }

    func testPartialSaveDoesNotPublishDailyCompletion() async {
        let dataClient = PartialFailingCheckInDataClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        let completionExpectation = expectation(
            forNotification: .dailyCheckInCompleted,
            object: nil
        )
        completionExpectation.isInverted = true
        viewModel.hasPain = true
        viewModel.painIntensity = 6

        await viewModel.save()

        await fulfillment(of: [completionExpectation], timeout: 0.1)
        let savedRecordTypes = await dataClient.savedRecordTypes()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(savedRecordTypes, ["SymptomCheckInRecord"])
    }
}

private actor PartialFailingCheckInDataClient: DataClientProtocol {
    private var savedTypes: [String] = []

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        []
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard recordType != "DailyPainLog" else {
            throw DataError.networkError(underlying: nil)
        }
        savedTypes.append(recordType)
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}

    func savedRecordTypes() -> [String] {
        savedTypes
    }
}
