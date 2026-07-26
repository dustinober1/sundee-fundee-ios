import Foundation
import SwiftUI

public protocol DailyPresenceServicing: Sendable {
    func recordOpen(at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
    func promoteToday(
        to: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord
    func loadSummary(referenceDate: Date, calendar: Calendar) async throws -> ConsistencyMomentumSummary
}

extension DailyPresenceService: DailyPresenceServicing {}

@MainActor
public final class TodayEngagementViewModel: ObservableObject {
    @Published public private(set) var today: DailyPresenceRecord?
    @Published public private(set) var summary: ConsistencyMomentumSummary?
    @Published public private(set) var isLoading = false
    @Published public private(set) var message: String?

    private let serviceProvider: @Sendable () -> any DailyPresenceServicing
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let achievementHaptic: @MainActor @Sendable () -> Void
    private static var announcedAchievements: Set<ConsistencyAchievement> = []
    private var needsReload = false
    private var isRefreshing = false
    private var pendingAction: PendingAction?

    private struct PendingAction {
        let level: DailyParticipationLevel
        let status: DailyPresenceStatus?
    }

    public init(
        service: (any DailyPresenceServicing)? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        if let service {
            serviceProvider = { service }
        } else {
            let localStore = PresenceLocalStore()
            serviceProvider = {
                DailyPresenceService(
                    localStore: localStore,
                    dataClient: DataClientFactory.shared.client
                )
            }
        }
        self.calendar = calendar
        self.now = now
        achievementHaptic = { HapticFeedback.success() }
    }

    init(
        serviceProvider: @escaping @Sendable () -> any DailyPresenceServicing,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        achievementHaptic: @escaping @MainActor @Sendable () -> Void = {
            HapticFeedback.success()
        }
    ) {
        self.serviceProvider = serviceProvider
        self.calendar = calendar
        self.now = now
        self.achievementHaptic = achievementHaptic
    }

    public func load() async {
        guard !isLoading else {
            needsReload = true
            return
        }
        isLoading = true
        isRefreshing = true

        do {
            let service = serviceProvider()
            today = try await service.recordOpen(at: now(), calendar: calendar)
            updateSummary(
                try await service.loadSummary(referenceDate: now(), calendar: calendar)
            )
            message = nil
        } catch {
            message = "Your daily momentum could not be updated. Your training plan is still available."
        }

        isRefreshing = false
        await completeOperation()
    }

    public func select(_ status: DailyPresenceStatus) async {
        let level: DailyParticipationLevel =
            status == .resting || status == .trained ? .acted : .checkedIn
        await promote(level: level, status: status)
    }

    public func recordCheckIn() async {
        await recordAction(level: .checkedIn, status: nil)
    }

    public func recordAction(_ status: DailyPresenceStatus?) async {
        await recordAction(level: .acted, status: status)
    }

    private func recordAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?
    ) async {
        guard !isLoading else {
            guard isRefreshing else { return }
            enqueueAction(level: level, status: status)
            return
        }
        await promote(level: level, status: status)
    }

    private func promote(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?
    ) async {
        guard !isLoading else { return }
        isLoading = true

        let service = serviceProvider()

        do {
            today = try await service.promoteToday(
                to: level,
                status: status,
                at: now(),
                calendar: calendar
            )

            do {
                let announcedAchievement = updateSummary(
                    try await service.loadSummary(referenceDate: now(), calendar: calendar)
                )
                if !announcedAchievement {
                    HapticFeedback.light()
                }
                message = nil
            } catch {
                HapticFeedback.light()
                message = "Your check-in was saved, but momentum couldn’t refresh yet."
            }
        } catch {
            message = "That check-in did not save. Please try again."
            HapticFeedback.warning()
        }

        await completeOperation()
    }

    private func completeOperation() async {
        isLoading = false

        if let pendingAction {
            self.pendingAction = nil
            await promote(level: pendingAction.level, status: pendingAction.status)
            return
        }

        guard needsReload else { return }
        needsReload = false
        await load()
    }

    @discardableResult
    private func updateSummary(_ updatedSummary: ConsistencyMomentumSummary) -> Bool {
        summary = updatedSummary

        let newlyAnnounced = updatedSummary.achievements.subtracting(Self.announcedAchievements)
        guard !newlyAnnounced.isEmpty else { return false }

        Self.announcedAchievements.formUnion(newlyAnnounced)
        achievementHaptic()
        return true
    }

    private func enqueueAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?
    ) {
        guard let pendingAction else {
            self.pendingAction = PendingAction(level: level, status: status)
            return
        }

        guard level >= pendingAction.level else { return }
        self.pendingAction = PendingAction(level: level, status: status ?? pendingAction.status)
    }
}
