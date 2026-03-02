import XCTest
@testable import SundeeFundee

@MainActor
final class WODTests: XCTestCase {

    // MARK: - Codable

    func testWODDecodesFromJSON() throws {
        let json = """
        {
            "id": "wod-2026-03-01",
            "date": "2026-03-01",
            "title": "Sunday Starter",
            "description": "Posterior chain focus.",
            "exercises": [
                {
                    "exercise": "Romanian Deadlift",
                    "variant": null,
                    "sets": 4,
                    "reps": 8,
                    "percent1RM": 0.65,
                    "restMinutes": 2.5,
                    "notes": "Slow eccentric.",
                    "bodyweightOnly": false
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let wod = try JSONDecoder().decode(WOD.self, from: data)

        XCTAssertEqual(wod.id, "wod-2026-03-01")
        XCTAssertEqual(wod.date, "2026-03-01")
        XCTAssertEqual(wod.title, "Sunday Starter")
        XCTAssertEqual(wod.description, "Posterior chain focus.")
        XCTAssertEqual(wod.exercises.count, 1)
        XCTAssertEqual(wod.exercises[0].exercise, "Romanian Deadlift")
        XCTAssertEqual(wod.exercises[0].percent1RM, 0.65)
    }

    func testWODArrayDecodesFromJSON() throws {
        let json = """
        [
            {
                "id": "wod-1",
                "date": "2026-03-01",
                "title": "WOD 1",
                "description": "First",
                "exercises": []
            },
            {
                "id": "wod-2",
                "date": "2026-03-02",
                "title": "WOD 2",
                "description": "Second",
                "exercises": []
            }
        ]
        """
        let data = json.data(using: .utf8)!
        let wods = try JSONDecoder().decode([WOD].self, from: data)
        XCTAssertEqual(wods.count, 2)
        XCTAssertEqual(wods[0].id, "wod-1")
        XCTAssertEqual(wods[1].id, "wod-2")
    }

    func testWODEncodesAndDecodesRoundTrip() throws {
        let wod = WOD(
            id: "wod-rt",
            date: "2026-03-15",
            title: "Round Trip",
            description: "Test encoding.",
            exercises: [
                ProgramExercise(
                    exercise: "Squat",
                    variant: nil,
                    sets: .fixed(3),
                    reps: .fixed(5),
                    percent1RM: 0.80,
                    restMinutes: 3,
                    notes: nil
                )
            ]
        )
        let data = try JSONEncoder().encode(wod)
        let decoded = try JSONDecoder().decode(WOD.self, from: data)
        XCTAssertEqual(decoded.id, wod.id)
        XCTAssertEqual(decoded.exercises.count, 1)
    }

    // MARK: - Hashable / Equatable

    func testWODHashableAndEquatable() {
        let wod1 = WOD(id: "wod-1", date: "2026-03-01", title: "A", description: "a", exercises: [])
        let wod2 = WOD(id: "wod-1", date: "2026-03-02", title: "B", description: "b", exercises: [])
        let wod3 = WOD(id: "wod-3", date: "2026-03-01", title: "A", description: "a", exercises: [])

        XCTAssertEqual(wod1, wod2) // Same ID
        XCTAssertNotEqual(wod1, wod3) // Different ID
        XCTAssertEqual(wod1.hashValue, wod2.hashValue)
    }

    // MARK: - Date filtering

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func testFindTodayWODFindsMatchingDate() {
        let todayString = dateFormatter.string(from: .now)

        let todayWOD = WOD(id: "wod-today", date: todayString, title: "Today", description: "", exercises: [])
        let otherWOD = WOD(id: "wod-other", date: "2020-01-01", title: "Other", description: "", exercises: [])

        let result = DashboardViewModel.findTodayWOD(from: [otherWOD, todayWOD])
        XCTAssertEqual(result?.id, "wod-today")
    }

    func testFindTodayWODReturnsNilWhenNoMatch() {
        let wod = WOD(id: "wod-old", date: "2020-01-01", title: "Old", description: "", exercises: [])
        let result = DashboardViewModel.findTodayWOD(from: [wod])
        XCTAssertNil(result)
    }

    func testFindTodayWODReturnsNilForEmptyArray() {
        let result = DashboardViewModel.findTodayWOD(from: [])
        XCTAssertNil(result)
    }

    func testFindTodayWODUsesSpecificDate() {
        let specificDate = dateFormatter.date(from: "2026-06-15")!

        let wod = WOD(id: "wod-june", date: "2026-06-15", title: "June", description: "", exercises: [])
        let result = DashboardViewModel.findTodayWOD(from: [wod], now: specificDate)
        XCTAssertEqual(result?.id, "wod-june")
    }
}
