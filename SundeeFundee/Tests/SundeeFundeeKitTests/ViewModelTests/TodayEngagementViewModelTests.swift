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

    @Test func newlyDerivedAchievementsTriggerOncePerAccount() async {
        let firstService = PresenceServiceSpy(
            ownerID: "account-a",
            achievements: [.firstConsistentWeek, .recoveryChoice]
        )
        let secondService = PresenceServiceSpy(
            ownerID: "account-b",
            achievements: [.firstConsistentWeek, .recoveryChoice]
        )
        let hapticCounter = AchievementHapticCounter()
        let achievementStore = AccountAchievementAnnouncementStore()
        let viewModel = TodayEngagementViewModel(
            serviceProvider: { firstService },
            achievementHaptic: hapticCounter.trigger,
            achievementStore: achievementStore
        )

        await viewModel.load()
        await viewModel.load()
        let recreatedViewModel = TodayEngagementViewModel(
            serviceProvider: { firstService },
            achievementHaptic: hapticCounter.trigger,
            achievementStore: achievementStore
        )
        await recreatedViewModel.load()
        let otherAccountViewModel = TodayEngagementViewModel(
            serviceProvider: { secondService },
            achievementHaptic: hapticCounter.trigger,
            achievementStore: achievementStore
        )
        await otherAccountViewModel.load()

        #expect(
            viewModel.summary?.achievements
                == Set([ConsistencyAchievement.firstConsistentWeek, .recoveryChoice])
        )
        #expect(hapticCounter.count == 2)
    }

    @Test func sessionChangeDuringAchievementClaimPreservesFutureAnnouncement() async {
        let service = PresenceServiceSpy(
            ownerID: "account-a",
            achievements: [.firstConsistentWeek]
        )
        let sessionProvider = MutablePresenceSessionProvider(
            token: PresenceSessionToken(ownerID: "account-a", generation: 1)
        )
        let achievementStore = SuspendingAchievementAnnouncementStore()
        let hapticCounter = AchievementHapticCounter()
        let viewModel = TodayEngagementViewModel(
            serviceProvider: { service },
            achievementHaptic: hapticCounter.trigger,
            achievementStore: achievementStore,
            sessionTokenProvider: sessionProvider.current
        )

        let staleLoad = Task { await viewModel.load() }
        await achievementStore.waitUntilClaimStarts()
        sessionProvider.set(
            PresenceSessionToken(ownerID: "account-a", generation: 2)
        )
        await achievementStore.releaseClaim()
        await staleLoad.value

        #expect(await achievementStore.claimed(ownerID: "account-a").isEmpty)
        #expect(hapticCounter.count == 0)

        await viewModel.load()

        #expect(
            await achievementStore.claimed(ownerID: "account-a")
                == Set([ConsistencyAchievement.firstConsistentWeek])
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
        #expect(await service.lastPromotion?.2 == .rested)
    }

    @Test func workoutCompletionPromotesTrainedAction() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.recordAction(.trained)

        #expect(await service.lastPromotion?.0 == .acted)
        #expect(await service.lastPromotion?.1 == .trained)
        #expect(await service.lastPromotion?.2 == .trained)
    }

    @Test func recoveryCompletionPreservesTrustedEvidenceAndOperationDate() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)
        let completionDate = Date(timeIntervalSince1970: 1_753_528_123)

        await viewModel.recordAction(
            .resting,
            evidence: .recovered,
            at: completionDate
        )

        #expect(await service.lastPromotion?.1 == .resting)
        #expect(await service.lastPromotion?.2 == .recovered)
        #expect(await service.lastPromotion?.3 == completionDate)
    }

    @Test func richCheckInDoesNotPretendWorkoutWasCompleted() async {
        let service = PresenceServiceSpy()
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.recordCheckIn()

        #expect(await service.lastPromotion?.0 == .checkedIn)
        #expect(await service.lastPromotion?.1 == nil)
        #expect(await service.lastPromotion?.2 == nil)
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
        #expect(await service.lastPromotion?.2 == .trained)
    }

    @Test func completionReceivedDuringStatusSaveIsQueuedAndPersisted() async {
        let service = BlockingPresenceService()
        let viewModel = TodayEngagementViewModel(service: service)
        let completionDate = Date(timeIntervalSince1970: 1_753_528_123)

        let selection = Task { await viewModel.select(.ready) }
        await service.waitUntilPromotionStarts()
        await viewModel.recordAction(
            .trained,
            evidence: .trained,
            at: completionDate
        )

        await service.releasePromotions()
        await selection.value

        #expect(await service.promotionCallCount == 2)
        #expect(await service.lastPromotionEvidence == .trained)
        #expect(await service.lastPromotionDate == completionDate)
    }

    @Test func oneOperationCapturesNowExactlyOnce() async {
        let service = PresenceServiceSpy()
        let clock = LockedDateSequence([
            Date(timeIntervalSince1970: 1_753_528_123),
            Date(timeIntervalSince1970: 1_753_999_999)
        ])
        let viewModel = TodayEngagementViewModel(
            service: service,
            now: clock.next
        )

        await viewModel.select(.ready)

        #expect(clock.callCount == 1)
        #expect(await service.lastPromotion?.3 == Date(timeIntervalSince1970: 1_753_528_123))
    }

    @Test func reportsPartialSuccessWhenMomentumRefreshFails() async {
        let service = PresenceServiceSpy(summaryShouldFail: true)
        let viewModel = TodayEngagementViewModel(service: service)

        await viewModel.select(.ready)

        #expect(viewModel.today?.status == .ready)
        #expect(viewModel.message == "Your check-in is saved. Momentum will refresh when it can.")
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

    @Test(
        "Session changes discard late results and clear state when the new load fails",
        arguments: ["account-b", "account-a"]
    )
    func sessionChangeDiscardsLateResults(nextOwnerID: String) async {
        let firstService = BlockingLoadPresenceService(ownerID: "account-a")
        let secondService = FailingPresenceService(ownerID: nextOwnerID)
        let provider = MutablePresenceServiceProvider(service: firstService)
        let sessionProvider = MutablePresenceSessionProvider(
            token: PresenceSessionToken(ownerID: "account-a", generation: 1)
        )
        let viewModel = TodayEngagementViewModel(
            serviceProvider: provider.current,
            sessionTokenProvider: sessionProvider.current
        )

        let firstLoad = Task { await viewModel.load() }
        await firstService.waitUntilLoadStarts()

        provider.set(secondService)
        sessionProvider.set(
            PresenceSessionToken(ownerID: nextOwnerID, generation: 2)
        )
        await viewModel.load()
        await firstService.releaseLoad()
        await firstLoad.value

        #expect(await firstService.recordOpenCallCount == 1)
        #expect(await secondService.recordOpenCallCount == 1)
        #expect(viewModel.today == nil)
        #expect(viewModel.summary == nil)
        #expect(viewModel.message == "Daily momentum is taking a moment to update. Your training plan is ready.")
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

private final class MutablePresenceSessionProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var token: PresenceSessionToken

    init(token: PresenceSessionToken) {
        self.token = token
    }

    func current() -> PresenceSessionToken {
        lock.withLock { token }
    }

    func set(_ token: PresenceSessionToken) {
        lock.withLock { self.token = token }
    }
}

private actor PresenceServiceSpy: DailyPresenceServicing {
    private enum TestError: Error {
        case summaryUnavailable
    }

    private(set) var recordOpenCallCount = 0
    private(set) var lastPromotion:
        (DailyParticipationLevel, DailyPresenceStatus?, DailyPresenceActionEvidence?, Date)?
    let ownerID: String
    private let summaryShouldFail: Bool
    private let achievements: Set<ConsistencyAchievement>

    init(
        ownerID: String = "test-account",
        summaryShouldFail: Bool = false,
        achievements: Set<ConsistencyAchievement> = []
    ) {
        self.ownerID = ownerID
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
        action: DailyPresenceActionEvidence?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        lastPromotion = (participationLevel, status, action, date)
        return record(
            participationLevel: participationLevel,
            status: status,
            action: action,
            date: date
        )
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
        action: DailyPresenceActionEvidence? = nil,
        date: Date
    ) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: "2025-07-23",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: date,
            participationLevel: participationLevel,
            status: status,
            actionEvidence: action.map { Set([$0]) } ?? []
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

private actor SuspendingAchievementAnnouncementStore: AchievementAnnouncementStoring {
    private var announcedByOwner: [String: Set<ConsistencyAchievement>] = [:]
    private var shouldSuspend = true
    private var didStartClaim = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var claimWaiters: [CheckedContinuation<Void, Never>] = []

    func claimNew(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) async -> Set<ConsistencyAchievement> {
        didStartClaim = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()
        if shouldSuspend {
            shouldSuspend = false
            await withCheckedContinuation { continuation in
                claimWaiters.append(continuation)
            }
        }

        let existing = announcedByOwner[ownerID, default: []]
        let new = achievements.subtracting(existing)
        announcedByOwner[ownerID] = existing.union(new)
        return new
    }

    func release(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) {
        announcedByOwner[ownerID, default: []].subtract(achievements)
    }

    func waitUntilClaimStarts() async {
        guard !didStartClaim else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func releaseClaim() {
        claimWaiters.forEach { $0.resume() }
        claimWaiters.removeAll()
    }

    func claimed(ownerID: String) -> Set<ConsistencyAchievement> {
        announcedByOwner[ownerID, default: []]
    }
}

private actor BlockingPresenceService: DailyPresenceServicing {
    private(set) var recordOpenCallCount = 0
    private(set) var promotionCallCount = 0
    private(set) var lastPromotionEvidence: DailyPresenceActionEvidence?
    private(set) var lastPromotionDate: Date?
    private var didStartPromotion = false
    private var shouldBlockPromotion = true
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var promotionWaiters: [CheckedContinuation<Void, Never>] = []

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        recordOpenCallCount += 1
        return record(status: nil, date: date)
    }

    func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        action: DailyPresenceActionEvidence?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        promotionCallCount += 1
        lastPromotionEvidence = action
        lastPromotionDate = date
        didStartPromotion = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()

        if shouldBlockPromotion {
            shouldBlockPromotion = false
            await withCheckedContinuation { continuation in
                promotionWaiters.append(continuation)
            }
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

private final class LockedDateSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Date]
    private var calls = 0

    init(_ values: [Date]) {
        self.values = values
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    func next() -> Date {
        lock.withLock {
            calls += 1
            return values.isEmpty ? Date(timeIntervalSince1970: 0) : values.removeFirst()
        }
    }
}

private actor BlockingLoadPresenceService: DailyPresenceServicing {
    let ownerID: String
    private(set) var recordOpenCallCount = 0
    private(set) var promotionCallCount = 0
    private(set) var lastPromotion:
        (DailyParticipationLevel, DailyPresenceStatus?, DailyPresenceActionEvidence?)?
    private var didStartLoad = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []

    init(ownerID: String = "injected-presence-owner") {
        self.ownerID = ownerID
    }

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        recordOpenCallCount += 1
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
        action: DailyPresenceActionEvidence?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        promotionCallCount += 1
        lastPromotion = (participationLevel, status, action)
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

private actor FailingPresenceService: DailyPresenceServicing {
    private enum TestFailure: Error {
        case unavailable
    }

    let ownerID: String
    private(set) var recordOpenCallCount = 0

    init(ownerID: String) {
        self.ownerID = ownerID
    }

    func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        recordOpenCallCount += 1
        throw TestFailure.unavailable
    }

    func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        action: DailyPresenceActionEvidence?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        throw TestFailure.unavailable
    }

    func loadSummary(
        referenceDate: Date,
        calendar: Calendar
    ) async throws -> ConsistencyMomentumSummary {
        throw TestFailure.unavailable
    }
}
