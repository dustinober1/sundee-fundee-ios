import XCTest
@testable import SundeeFundeeKit

final class HistoryReadinessProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testNewestSameDaySymptomsAndPainWin() async throws {
        let client = MockCloudKitClient()
        try await client.save([
            SymptomCheckInRecord(symptomDate: now, cramps: 1, fatigue: 3, soreness: 2, energy: 7,
                                 dateCreated: now.addingTimeInterval(-60)),
            SymptomCheckInRecord(symptomDate: now, cramps: 2, fatigue: 6, soreness: 5, energy: 4,
                                 dateCreated: now)
        ], recordType: "SymptomCheckInRecord")
        try await client.save(
            DailyPainLog(id: "pain", locationIds: "knee", intensity: 7, painType: .sharp, date: now),
            recordType: "DailyPainLog"
        )

        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertEqual(result.subjective.energy, 4)
        XCTAssertEqual(result.subjective.fatigue, 6)
        XCTAssertEqual(result.pain?.intensity, 7)
        XCTAssertEqual(result.pain?.locationIDs, ["knee"])
    }

    func testLoadRatioAndFourNewestCompletionCheckInsAreAggregated() async throws {
        let client = MockCloudKitClient()
        let calendar = utcCalendar()
        let workouts = [1, 3, 8, 12, 18].enumerated().map { index, days in
            CompletedWorkoutRecord(
                id: "w\(index)", name: "Workout", date: calendar.date(byAdding: .day, value: -days, to: now)!,
                duration: 30, exerciseNames: ["Squat"], isComplete: true
            )
        }
        try await client.save(workouts, recordType: "CompletedWorkoutRecord")
        let checkIns = [
            WorkoutCompletionCheckInRecord(id: "c1", workoutID: "w1", sessionRPE: 6, soreness: 2, pain: 0,
                                           wasRightForToday: true, dateCreated: now),
            WorkoutCompletionCheckInRecord(id: "c2", workoutID: "w2", sessionRPE: 8, soreness: 3, pain: 0,
                                           wasRightForToday: true, dateCreated: now.addingTimeInterval(-1)),
            WorkoutCompletionCheckInRecord(id: "c3", workoutID: "w3", sessionRPE: nil, soreness: 2, pain: 0,
                                           wasRightForToday: false, dateCreated: now.addingTimeInterval(-2)),
            WorkoutCompletionCheckInRecord(id: "c4", workoutID: "w4", sessionRPE: 7, soreness: 1, pain: 0,
                                           wasRightForToday: true, dateCreated: now.addingTimeInterval(-3))
        ]
        try await client.save(checkIns, recordType: "WorkoutCompletionCheckIn")

        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: calendar
        )
        XCTAssertEqual(try XCTUnwrap(result.training.weeklyLoadRatio), 2, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.training.averageSessionRPE), 7, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.training.rightForTodayRate), 0.75, accuracy: 0.001)
        XCTAssertEqual(result.training.completedWorkoutsInLast28Days, 5)
    }

    func testNoSameDayPainReturnsNil() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            DailyPainLog(id: "old", locationIds: "back", intensity: 5, painType: .aching,
                         date: now.addingTimeInterval(-86_400)),
            recordType: "DailyPainLog"
        )
        let result = await HistoryReadinessProvider(dataClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )
        XCTAssertNil(result.pain)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
