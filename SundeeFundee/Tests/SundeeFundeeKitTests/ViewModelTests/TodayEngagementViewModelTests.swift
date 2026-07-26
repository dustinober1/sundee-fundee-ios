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

    @Test func newlyDerivedAchievementsTriggerOneSuccessHapticPerProcess() async {
        let service = PresenceServiceSpy(achievements: [.firstConsistentWeek, .recoveryChoice])
        let hapticCounter = AchievementHapticCounter()
        let viewModel = TodayEngagementViewModel(
            serviceProvider: { service },
            achievementHaptic: hapticCounter.trigger
        )

        await viewModel.load()
        await viewModel.load()

        #expect(
            viewModel.summary?.achievements
                == Set([ConsistencyAchievement.firstConsistentWeek, .recoveryChoice])
        )
        #expect(hapticCounter.count == 1)
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

    @Test func workoutCompletionPromotesTrainedAction() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.recordAction(.trained)

        #expect(await service.lastPromotion?.0 == .acted)
        #expect(await service.lastPromotion?.1 == .trained)
    }

    @Test func richCheckInDoesNotPretendWorkoutWasCompleted() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.recordCheckIn()

        #expect(await service.lastPromotion?.0 == .checkedIn)
        #expect(await service.lastPromotion?.1 == nil)
    }

    @Test func coalescesActionsReceivedDuringLoadWithoutDowngradingWorkoutCompletion() async {
        let service = BlockingLoadPresenceService()
        let viewModel = TodayEngagementViewModel(service: service)

        let load = Task { await viewModel.load() }
        await service.waitUntilLoadStarts()

        await viewModel.recordAction(.trained)
        await viewModel.recordCheckIn()

        #expect(await service.promotionCallCount == 0)

        await service.releaseLoad()
        await load.value

        #expect(await service.promotionCallCount == 1)
        #expect(await service.lastPromotion?.0 == .acted)
        #expect(await service.lastPromotion?.1 == .trained)
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
    private let achievements: Set<ConsistencyAchievement>

    init(
        summaryShouldFail: Bool = false,
        achievements: Set<ConsistencyAchievement> = []
    ) {
        self.summaryShouldFail = summaryShouldFail
        self.achievements = achievements
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
            supportiveHeadline: "1 day present this week",
            achievements: achievements
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

@MainActor
private final class AchievementHapticCounter {
    private(set) var count = 0

    func trigger() {
        count += 1
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

private actor BlockingLoadPresenceService: DailyPresenceServicing {
    private(set) var promotionCallCount = 0
    private(set) var lastPromotion: (DailyParticipationLevel, DailyPresenceStatus?)?
    private var didStartLoad = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        didStartLoad = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()
        await withCheckedContinuation { continuation in
            loadWaiters.append(continuation)
        }
        return record(participationLevel: .showedUp, status: nil, date: date)
    }

    func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        promotionCallCount += 1
        lastPromotion = (participationLevel, status)
        return record(participationLevel: participationLevel, status: status, date: date)
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

    func waitUntilLoadStarts() async {
        guard !didStartLoad else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func releaseLoad() {
        loadWaiters.forEach { $0.resume() }
        loadWaiters.removeAll()
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
