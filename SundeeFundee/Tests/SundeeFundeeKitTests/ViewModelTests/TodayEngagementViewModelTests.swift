import Foundation
import Testing
@testable import SundeeFundeeKit

@MainActor
@Suite("Today engagement view model")
struct TodayEngagementViewModelTests {
    @Test func loadRecordsPresenceWithoutRequiringAStatus() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(
            service: service,
            now: { Date(timeIntervalSince1970: 1_753_528_400) }
        )

        await viewModel.load()

        #expect(viewModel.today?.participationLevel == .showedUp)
        #expect(viewModel.today?.status == nil)
        #expect(viewModel.summary?.daysPresentThisWeek == 1)
        #expect(viewModel.message == nil)
        #expect(await service.recordOpenCallCount == 1)
    }

    @Test func selectingRestingPromotesToAction() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.select(.resting)

        #expect(viewModel.today?.participationLevel == .acted)
        #expect(viewModel.today?.status == .resting)
        #expect(await service.lastPromotion?.0 == .acted)
        #expect(await service.lastPromotion?.1 == .resting)
    }
}

private actor PresenceServiceSpy: DailyPresenceServicing {
    private(set) var recordOpenCallCount = 0
    private(set) var lastPromotion: (DailyParticipationLevel, DailyPresenceStatus?)?

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        recordOpenCallCount += 1
        return record(participationLevel: .showedUp, status: nil, date: date)
    }

    func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        lastPromotion = (participationLevel, status)
        return record(participationLevel: participationLevel, status: status, date: date)
    }

    func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary {
        ConsistencyMomentumSummary(
            daysPresentThisWeek: 1,
            checkInsThisWeek: 0,
            actionDaysThisWeek: 0,
            rollingWeeks: [],
            supportiveHeadline: "1 day present this week"
        )
    }

    private func record(
        participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        date: Date
    ) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: "2025-07-23",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: date,
            participationLevel: participationLevel,
            status: status
        )
    }
}
