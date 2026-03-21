import XCTest
@testable import SundeeFundee

@MainActor
final class WODsViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeWOD(id: String = "wod-1", date: String, title: String = "Test WOD") -> WOD {
        WOD(id: id, date: date, title: title, description: "Test", exercises: [])
    }

    private func date(from string: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt.date(from: string)!
    }

    // MARK: - wodsInRange

    func testWODsInRangeReturnsCorrectWindow() {
        let ref = date(from: "2026-03-09")
        let wods = [
            makeWOD(id: "w1", date: "2026-03-03"), // -6 days, out
            makeWOD(id: "w2", date: "2026-03-04"), // -5 days, in
            makeWOD(id: "w3", date: "2026-03-09"), // today, in
            makeWOD(id: "w4", date: "2026-03-14"), // +5 days, in
            makeWOD(id: "w5", date: "2026-03-15"), // +6 days, out
        ]

        let result = WODsViewModel.wodsInRange(from: wods, around: ref, dayRange: 5)

        XCTAssertEqual(result.map(\.id), ["w2", "w3", "w4"])
    }

    func testWODsInRangeReturnsEmptyForNoMatches() {
        let ref = date(from: "2026-06-01")
        let wods = [makeWOD(date: "2026-03-09")]

        let result = WODsViewModel.wodsInRange(from: wods, around: ref, dayRange: 5)
        XCTAssertTrue(result.isEmpty)
    }

    func testWODsInRangeSortsAscending() {
        let ref = date(from: "2026-03-09")
        let wods = [
            makeWOD(id: "w3", date: "2026-03-11"),
            makeWOD(id: "w1", date: "2026-03-07"),
            makeWOD(id: "w2", date: "2026-03-09"),
        ]

        let result = WODsViewModel.wodsInRange(from: wods, around: ref, dayRange: 5)
        XCTAssertEqual(result.map(\.id), ["w1", "w2", "w3"])
    }

    // MARK: - displayDate

    func testDisplayDateToday() {
        let ref = date(from: "2026-03-09")
        XCTAssertEqual(WODsViewModel.displayDate(from: "2026-03-09", referenceDate: ref), "Today")
    }

    func testDisplayDateYesterday() {
        let ref = date(from: "2026-03-09")
        XCTAssertEqual(WODsViewModel.displayDate(from: "2026-03-08", referenceDate: ref), "Yesterday")
    }

    func testDisplayDateTomorrow() {
        let ref = date(from: "2026-03-09")
        XCTAssertEqual(WODsViewModel.displayDate(from: "2026-03-10", referenceDate: ref), "Tomorrow")
    }

    func testDisplayDateOtherDay() {
        let ref = date(from: "2026-03-09")
        let result = WODsViewModel.displayDate(from: "2026-03-12", referenceDate: ref)
        // Should be something like "Thu, Mar 12"
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("12"))
    }

    func testDisplayDateInvalidString() {
        let ref = date(from: "2026-03-09")
        let result = WODsViewModel.displayDate(from: "not-a-date", referenceDate: ref)
        XCTAssertEqual(result, "not-a-date")
    }

    // MARK: - isToday

    func testIsTodayReturnsTrue() {
        let ref = date(from: "2026-03-09")
        XCTAssertTrue(WODsViewModel.isToday("2026-03-09", referenceDate: ref))
    }

    func testIsTodayReturnsFalse() {
        let ref = date(from: "2026-03-09")
        XCTAssertFalse(WODsViewModel.isToday("2026-03-10", referenceDate: ref))
    }

    // MARK: - load

    func testLoadPopulatesWODs() async {
        let stubWODs = [makeWOD(date: "2026-03-09")]
        let repo = StubWODRepository(wods: stubWODs)
        let vm = WODsViewModel(wodRepo: repo)

        await vm.load()

        XCTAssertEqual(vm.allWODs.count, 1)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadHandlesFailureGracefully() async {
        let repo = StubWODRepository(shouldFail: true)
        let vm = WODsViewModel(wodRepo: repo)

        await vm.load()

        XCTAssertTrue(vm.allWODs.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - WODListCard static

    func testTemplateBadgeText() {
        let wod = makeWOD(date: "2026-03-09")
        let text = WODListCard.templateBadgeText(for: wod)
        XCTAssertFalse(text.isEmpty)
    }
}

// MARK: - Stub

private final class StubWODRepository: WODRepository, @unchecked Sendable {
    let wods: [WOD]
    let shouldFail: Bool

    init(wods: [WOD] = [], shouldFail: Bool = false) {
        self.wods = wods
        self.shouldFail = shouldFail
    }

    func fetchWODs() async throws -> [WOD] {
        if shouldFail { throw NSError(domain: "test", code: 1) }
        return wods
    }
}
