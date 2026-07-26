import Foundation
import SwiftUI

public protocol DailyPresenceServicing: Sendable {
    var ownerID: String { get async }

    func recordOpen(at: Date, calendar: Calendar) async throws -> DailyPresenceRecord
    func promoteToday(
        to: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        action: DailyPresenceActionEvidence?,
        at: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord
    func loadSummary(
        referenceDate: Date,
        calendar: Calendar
    ) async throws -> ConsistencyMomentumSummary
    func currentSyncState() async -> PresenceSyncState
    func syncPending() async -> PresenceSyncState
}

public extension DailyPresenceServicing {
    var ownerID: String { get async { "injected-presence-owner" } }

    func currentSyncState() async -> PresenceSyncState { .synced }

    func syncPending() async -> PresenceSyncState { .synced }
}

extension DailyPresenceService: DailyPresenceServicing {}

public protocol AchievementAnnouncementStoring: Sendable {
    func claimNew(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) async -> Set<ConsistencyAchievement>
}

public actor AccountAchievementAnnouncementStore: AchievementAnnouncementStoring {
    public static let shared = AccountAchievementAnnouncementStore()

    private var announcedByOwner: [String: Set<ConsistencyAchievement>] = [:]

    public init() {}

    public func claimNew(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) -> Set<ConsistencyAchievement> {
        let existing = announcedByOwner[ownerID, default: []]
        let new = achievements.subtracting(existing)
        announcedByOwner[ownerID] = existing.union(new)
        return new
    }
}

@MainActor
public final class TodayEngagementViewModel: ObservableObject {
    @Published public private(set) var today: DailyPresenceRecord?
    @Published public private(set) var summary: ConsistencyMomentumSummary?
    @Published public private(set) var syncState: PresenceSyncState = .synced
    @Published public private(set) var isLoading = false
    @Published public private(set) var message: String?

    private let serviceProvider: @Sendable () -> any DailyPresenceServicing
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let achievementHaptic: @MainActor @Sendable () -> Void
    private let achievementStore: any AchievementAnnouncementStoring
    private let networkMonitor: NetworkMonitor?
    private var connectivityTask: Task<Void, Never>?
    private var needsReload = false
    private var needsSyncRetry = false
    private var pendingAction: PendingAction?

    private struct PendingAction {
        let level: DailyParticipationLevel
        let status: DailyPresenceStatus?
        let evidence: DailyPresenceActionEvidence?
        let operationDate: Date
    }

    public init(
        service: (any DailyPresenceServicing)? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        if let service {
            serviceProvider = { service }
            networkMonitor = nil
        } else {
            serviceProvider = {
                let session = DataClientFactory.shared.session
                return DailyPresenceService(
                    ownerID: session.ownerID,
                    localStore: PresenceLocalStore(ownerID: session.ownerID),
                    dataClient: session.client
                )
            }
            networkMonitor = NetworkMonitor()
        }
        self.calendar = calendar
        self.now = now
        achievementHaptic = { HapticFeedback.success() }
        achievementStore = AccountAchievementAnnouncementStore.shared
        startConnectivityRetry()
    }

    init(
        serviceProvider: @escaping @Sendable () -> any DailyPresenceServicing,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        achievementHaptic: @escaping @MainActor @Sendable () -> Void = {
            HapticFeedback.success()
        },
        achievementStore: any AchievementAnnouncementStoring =
            AccountAchievementAnnouncementStore.shared,
        networkMonitor: NetworkMonitor? = nil
    ) {
        self.serviceProvider = serviceProvider
        self.calendar = calendar
        self.now = now
        self.achievementHaptic = achievementHaptic
        self.achievementStore = achievementStore
        self.networkMonitor = networkMonitor
        startConnectivityRetry()
    }

    deinit {
        connectivityTask?.cancel()
    }

    public func load() async {
        guard !isLoading else {
            needsReload = true
            return
        }
        isLoading = true
        let operationDate = now()

        do {
            let service = serviceProvider()
            let operationOwnerID = await service.ownerID
            today = try await service.recordOpen(at: operationDate, calendar: calendar)
            _ = await updateSummary(
                try await service.loadSummary(
                    referenceDate: operationDate,
                    calendar: calendar
                ),
                ownerID: operationOwnerID
            )
            syncState = await service.currentSyncState()
            message = nil
        } catch {
            message = "Daily momentum is taking a moment to update. Your training plan is ready."
        }

        await completeOperation()
    }

    public func select(_ status: DailyPresenceStatus) async {
        guard !isLoading else { return }
        let level: DailyParticipationLevel =
            status == .resting || status == .trained ? .acted : .checkedIn
        let evidence: DailyPresenceActionEvidence? = switch status {
        case .trained: .trained
        case .resting: .rested
        case .ready, .tired, .sore: nil
        }
        await promote(
            level: level,
            status: status,
            evidence: evidence,
            operationDate: now()
        )
    }

    public func recordCheckIn(at operationDate: Date? = nil) async {
        await recordExternalAction(
            level: .checkedIn,
            status: nil,
            evidence: nil,
            operationDate: operationDate ?? now()
        )
    }

    public func recordAction(
        _ status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence? = nil,
        at operationDate: Date? = nil
    ) async {
        let resolvedEvidence = evidence ?? Self.inferredEvidence(for: status)
        await recordExternalAction(
            level: .acted,
            status: status,
            evidence: resolvedEvidence,
            operationDate: operationDate ?? now()
        )
    }

    public func retrySync() async {
        guard !isLoading else {
            needsSyncRetry = true
            return
        }
        isLoading = true
        syncState = await serviceProvider().syncPending()
        await completeOperation()
    }

    private func recordExternalAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date
    ) async {
        guard !isLoading else {
            enqueueAction(
                level: level,
                status: status,
                evidence: evidence,
                operationDate: operationDate
            )
            return
        }
        await promote(
            level: level,
            status: status,
            evidence: evidence,
            operationDate: operationDate
        )
    }

    private func promote(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date
    ) async {
        guard !isLoading else { return }
        isLoading = true

        let service = serviceProvider()
        let operationOwnerID = await service.ownerID

        do {
            today = try await service.promoteToday(
                to: level,
                status: status,
                action: evidence,
                at: operationDate,
                calendar: calendar
            )

            do {
                let announcedAchievement = await updateSummary(
                    try await service.loadSummary(
                        referenceDate: operationDate,
                        calendar: calendar
                    ),
                    ownerID: operationOwnerID
                )
                if !announcedAchievement {
                    HapticFeedback.light()
                }
                message = nil
            } catch {
                HapticFeedback.light()
                message = "Your check-in is saved. Momentum will refresh when it can."
            }
            syncState = await service.currentSyncState()
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
            await promote(
                level: pendingAction.level,
                status: pendingAction.status,
                evidence: pendingAction.evidence,
                operationDate: pendingAction.operationDate
            )
            return
        }

        if needsReload {
            needsReload = false
            await load()
            return
        }

        guard needsSyncRetry else { return }
        needsSyncRetry = false
        await retrySync()
    }

    @discardableResult
    private func updateSummary(
        _ updatedSummary: ConsistencyMomentumSummary,
        ownerID: String
    ) async -> Bool {
        summary = updatedSummary

        let newlyAnnounced = await achievementStore.claimNew(
            updatedSummary.achievements,
            ownerID: ownerID
        )
        guard !newlyAnnounced.isEmpty else { return false }

        achievementHaptic()
        return true
    }

    private func enqueueAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date
    ) {
        guard let pendingAction else {
            self.pendingAction = PendingAction(
                level: level,
                status: status,
                evidence: evidence,
                operationDate: operationDate
            )
            return
        }

        let mergedLevel = max(level, pendingAction.level)
        let mergedEvidence = Self.preferredEvidence(evidence, pendingAction.evidence)
        let prefersNew = level >= pendingAction.level
        self.pendingAction = PendingAction(
            level: mergedLevel,
            status: prefersNew ? status ?? pendingAction.status : pendingAction.status,
            evidence: mergedEvidence,
            operationDate: min(operationDate, pendingAction.operationDate)
        )
    }

    private func startConnectivityRetry() {
        guard let networkMonitor else { return }
        connectivityTask = Task { [weak self] in
            let changes = networkMonitor.connectivityChanges
            for await connected in changes where connected {
                guard !Task.isCancelled else { return }
                await self?.retrySync()
            }
        }
    }

    private static func inferredEvidence(
        for status: DailyPresenceStatus?
    ) -> DailyPresenceActionEvidence? {
        switch status {
        case .trained: .trained
        case .resting: .rested
        case .ready, .tired, .sore, .none: nil
        }
    }

    private static func preferredEvidence(
        _ lhs: DailyPresenceActionEvidence?,
        _ rhs: DailyPresenceActionEvidence?
    ) -> DailyPresenceActionEvidence? {
        let rank: (DailyPresenceActionEvidence) -> Int = {
            switch $0 {
            case .trained: 3
            case .recovered: 2
            case .rested: 1
            }
        }
        return [lhs, rhs].compactMap { $0 }.max { rank($0) < rank($1) }
    }
}
