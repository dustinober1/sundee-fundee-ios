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

    @Test func reportsPartialSuccessWhenMomentumRefreshFails() async {
        let service = PresenceServiceSpy(summaryShouldFail: true)
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.select(.ready)

        #expect(viewModel.today?.status == .ready)
        #expect(viewModel.message == "Your check-in was saved, but momentum couldn’t refresh yet.")
    }

    @Test func resolvesTheCurrentServiceForEachOperation() async {
        let firstService = PresenceServiceSpy()
        let secondService = PresenceServiceSpy()
        let provider = MutablePresenceServiceProvider(service: firstService)
        let viewModel = TodayEngagementViewModel(serviceProvider: provider.current)

        await viewModel.load()
        provider.set(secondService)
        await viewModel.select(.ready)

        #expect(await firstService.recordOpenCallCount == 1)
        #expect(await firstService.lastPromotion == nil)
        #expect(await secondService.lastPromotion?.1 == .ready)
    }

    @Test func ignoresASecondSelectionWhileTheFirstIsSaving() async throws {
        let service = BlockingPresenceService()
        let viewModel = TodayEngagementViewModel(service: service)

        let firstSelection = Task { await viewModel.select(.ready) }
        await service.waitUntilPromotionStarts()

        let release = Task {
            try await Task.sleep(for: .milliseconds(50))
            await service.releasePromotions()
        }
        await viewModel.select(.tired)
        try await release.value
        await firstSelection.value

        #expect(await service.promotionCallCount == 1)
        #expect(viewModel.today?.status == .ready)
    }

    @Test func defersReloadUntilAnInFlightSelectionFinishes() async {
        let service = BlockingPresenceService()
        let viewModel = TodayEngagementViewModel(service: service)

        let selection = Task { await viewModel.select(.ready) }
        await service.waitUntilPromotionStarts()
        await viewModel.load()

        #expect(await service.recordOpenCallCount == 0)

        await service.releasePromotions()
        await selection.value

        #expect(await service.recordOpenCallCount == 1)
    }
}

private final class MutablePresenceServiceProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var service: any DailyPresenceServicing

    init(service: any DailyPresenceServicing) {
        self.service = service
    }

    func current() -> any DailyPresenceServicing {
        lock.withLock { service }
    }

    func set(_ service: any DailyPresenceServicing) {
        lock.withLock { self.service = service }
    }
}

private actor PresenceServiceSpy: DailyPresenceServicing {
    private enum TestError: Error {
        case summaryUnavailable
    }

    private(set) var recordOpenCallCount = 0
    private(set) var lastPromotion: (DailyParticipationLevel, DailyPresenceStatus?)?
    private let summaryShouldFail: Bool

    init(summaryShouldFail: Bool = false) {
        self.summaryShouldFail = summaryShouldFail
    }

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
        if summaryShouldFail {
            throw TestError.summaryUnavailable
        }
        return ConsistencyMomentumSummary(
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

private actor BlockingPresenceService: DailyPresenceServicing {
    private(set) var recordOpenCallCount = 0
    private(set) var promotionCallCount = 0
    private var didStartPromotion = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var promotionWaiters: [CheckedContinuation<Void, Never>] = []

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        recordOpenCallCount += 1
        return record(status: nil, date: date)
    }

    func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        promotionCallCount += 1
        didStartPromotion = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()

        await withCheckedContinuation { continuation in
            promotionWaiters.append(continuation)
        }
        return record(status: status, date: date)
    }

    func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary {
        ConsistencyMomentumSummary(
            daysPresentThisWeek: 1,
            checkInsThisWeek: 1,
            actionDaysThisWeek: 0,
            rollingWeeks: [],
            supportiveHeadline: "1 day present this week"
        )
    }

    func waitUntilPromotionStarts() async {
        guard !didStartPromotion else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func releasePromotions() {
        promotionWaiters.forEach { $0.resume() }
        promotionWaiters.removeAll()
    }

    private func record(status: DailyPresenceStatus?, date: Date) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: "2025-07-23",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: date,
            participationLevel: .checkedIn,
            status: status
        )
    }
}
