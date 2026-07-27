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

struct PresenceSessionToken: Sendable, Equatable {
    let ownerID: String
    let generation: UInt64
}

public struct AchievementAnnouncementClaim: Sendable, Equatable {
    public let id: UUID
    public let ownerID: String
    public let achievements: Set<ConsistencyAchievement>

    public init(
        id: UUID = UUID(),
        ownerID: String,
        achievements: Set<ConsistencyAchievement>
    ) {
        self.id = id
        self.ownerID = ownerID
        self.achievements = achievements
    }
}

public protocol AchievementAnnouncementStoring: Sendable {
    func claimNew(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) async -> AchievementAnnouncementClaim
    func commit(
        _ claim: AchievementAnnouncementClaim,
        ifCurrent: @escaping @Sendable () -> Bool
    ) async -> Set<ConsistencyAchievement>?
    func release(_ claim: AchievementAnnouncementClaim) async
}

public actor AccountAchievementAnnouncementStore: AchievementAnnouncementStoring {
    public static let shared = AccountAchievementAnnouncementStore()

    private var announcedByOwner: [String: Set<ConsistencyAchievement>] = [:]
    private var pendingClaims: [UUID: AchievementAnnouncementClaim] = [:]

    public init() {}

    public func claimNew(
        _ achievements: Set<ConsistencyAchievement>,
        ownerID: String
    ) -> AchievementAnnouncementClaim {
        let existing = announcedByOwner[ownerID, default: []]
        let claim = AchievementAnnouncementClaim(
            ownerID: ownerID,
            achievements: achievements.subtracting(existing)
        )
        pendingClaims[claim.id] = claim
        return claim
    }

    public func commit(
        _ claim: AchievementAnnouncementClaim,
        ifCurrent: @escaping @Sendable () -> Bool
    ) -> Set<ConsistencyAchievement>? {
        guard pendingClaims.removeValue(forKey: claim.id) == claim,
              ifCurrent() else {
            return nil
        }
        let existing = announcedByOwner[claim.ownerID, default: []]
        let new = claim.achievements.subtracting(existing)
        announcedByOwner[claim.ownerID] = existing.union(new)
        return new
    }

    public func release(_ claim: AchievementAnnouncementClaim) {
        pendingClaims.removeValue(forKey: claim.id)
    }
}

@MainActor
public final class TodayEngagementViewModel: ObservableObject {
    @Published public private(set) var today: DailyPresenceRecord?
    @Published public private(set) var summary: ConsistencyMomentumSummary?
    @Published public private(set) var syncState: PresenceSyncState = .synced
    @Published public private(set) var isLoading = false
    @Published public private(set) var message: String?

    private let operationContextProvider: @Sendable () -> OperationContext
    private let sessionTokenProvider: (@Sendable () -> PresenceSessionToken)?
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let achievementHaptic: @MainActor @Sendable () -> Void
    private let achievementStore: any AchievementAnnouncementStoring
    private let networkMonitor: NetworkMonitor?
    private var connectivityTask: Task<Void, Never>?
    private var needsReload = false
    private var needsSyncRetry = false
    private var pendingAction: PendingAction?
    private var presentedSessionToken: PresenceSessionToken?

    private struct OperationContext: Sendable {
        let service: any DailyPresenceServicing
        let sessionToken: PresenceSessionToken?
    }

    private struct ResolvedOperationContext: Sendable {
        let service: any DailyPresenceServicing
        let sessionToken: PresenceSessionToken
    }

    private struct PendingAction {
        let level: DailyParticipationLevel
        let status: DailyPresenceStatus?
        let evidence: DailyPresenceActionEvidence?
        let operationDate: Date
        let sessionToken: PresenceSessionToken
    }

    private enum SummaryUpdateResult {
        case stale
        case updated(announcedAchievement: Bool)
    }

    public init(
        service: (any DailyPresenceServicing)? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        if let service {
            operationContextProvider = {
                OperationContext(service: service, sessionToken: nil)
            }
            sessionTokenProvider = nil
            networkMonitor = nil
        } else {
            operationContextProvider = {
                let session = DataClientFactory.shared.session
                return OperationContext(
                    service: DailyPresenceService(
                        ownerID: session.ownerID,
                        localStore: PresenceLocalStore(ownerID: session.ownerID),
                        dataClient: session.client
                    ),
                    sessionToken: PresenceSessionToken(
                        ownerID: session.ownerID,
                        generation: session.generation
                    )
                )
            }
            sessionTokenProvider = {
                let session = DataClientFactory.shared.session
                return PresenceSessionToken(
                    ownerID: session.ownerID,
                    generation: session.generation
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
        networkMonitor: NetworkMonitor? = nil,
        sessionTokenProvider: (@Sendable () -> PresenceSessionToken)? = nil
    ) {
        operationContextProvider = {
            OperationContext(
                service: serviceProvider(),
                sessionToken: sessionTokenProvider?()
            )
        }
        self.sessionTokenProvider = sessionTokenProvider
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
        let context = await makeOperationContext()
        prepareForOperation(in: context.sessionToken)
        guard !isLoading else {
            needsReload = true
            return
        }
        isLoading = true
        let operationDate = now()

        do {
            let loadedToday = try await context.service.recordOpen(
                at: operationDate,
                calendar: calendar
            )
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            today = loadedToday

            let loadedSummary = try await context.service.loadSummary(
                referenceDate: operationDate,
                calendar: calendar
            )
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            let updateResult = await updateSummary(
                loadedSummary,
                ownerID: context.sessionToken.ownerID,
                sessionToken: context.sessionToken
            )
            guard case .updated = updateResult else {
                await completeOperation()
                return
            }

            let updatedSyncState = await context.service.currentSyncState()
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            syncState = updatedSyncState
            message = nil
        } catch {
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
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
        let context = await makeOperationContext()
        prepareForOperation(in: context.sessionToken)
        guard !isLoading else {
            needsSyncRetry = true
            return
        }
        isLoading = true
        let updatedSyncState = await context.service.syncPending()
        if await isCurrent(context.sessionToken) {
            syncState = updatedSyncState
        }
        await completeOperation()
    }

    private func recordExternalAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date
    ) async {
        let context = await makeOperationContext()
        prepareForOperation(in: context.sessionToken)
        guard !isLoading else {
            enqueueAction(
                level: level,
                status: status,
                evidence: evidence,
                operationDate: operationDate,
                sessionToken: context.sessionToken
            )
            return
        }
        await promote(
            level: level,
            status: status,
            evidence: evidence,
            operationDate: operationDate,
            context: context
        )
    }

    private func promote(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date,
        context suppliedContext: ResolvedOperationContext? = nil
    ) async {
        guard !isLoading else { return }
        let context = if let suppliedContext {
            suppliedContext
        } else {
            await makeOperationContext()
        }
        prepareForOperation(in: context.sessionToken)
        isLoading = true

        do {
            let promotedToday = try await context.service.promoteToday(
                to: level,
                status: status,
                action: evidence,
                at: operationDate,
                calendar: calendar
            )
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            today = promotedToday

            do {
                let loadedSummary = try await context.service.loadSummary(
                    referenceDate: operationDate,
                    calendar: calendar
                )
                guard await isCurrent(context.sessionToken) else {
                    await completeOperation()
                    return
                }
                let updateResult = await updateSummary(
                    loadedSummary,
                    ownerID: context.sessionToken.ownerID,
                    sessionToken: context.sessionToken
                )
                guard case .updated(let announcedAchievement) = updateResult else {
                    await completeOperation()
                    return
                }
                if !announcedAchievement {
                    HapticFeedback.light()
                }
                message = nil
            } catch {
                guard await isCurrent(context.sessionToken) else {
                    await completeOperation()
                    return
                }
                HapticFeedback.light()
                message = "Your check-in is saved. Momentum will refresh when it can."
            }
            let updatedSyncState = await context.service.currentSyncState()
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            syncState = updatedSyncState
        } catch {
            guard await isCurrent(context.sessionToken) else {
                await completeOperation()
                return
            }
            message = "That check-in did not save. Please try again."
            HapticFeedback.warning()
        }

        await completeOperation()
    }

    private func completeOperation() async {
        isLoading = false

        if let pendingAction {
            self.pendingAction = nil
            if await isCurrent(pendingAction.sessionToken) {
                await promote(
                    level: pendingAction.level,
                    status: pendingAction.status,
                    evidence: pendingAction.evidence,
                    operationDate: pendingAction.operationDate
                )
                return
            }
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
        ownerID: String,
        sessionToken: PresenceSessionToken
    ) async -> SummaryUpdateResult {
        guard await isCurrent(sessionToken) else { return .stale }
        let claim = await achievementStore.claimNew(
            updatedSummary.achievements,
            ownerID: ownerID
        )
        guard await isCurrent(sessionToken) else {
            await achievementStore.release(claim)
            return .stale
        }
        let sessionTokenProvider = self.sessionTokenProvider
        guard let newlyAnnounced = await achievementStore.commit(
            claim,
            ifCurrent: {
                sessionTokenProvider?() == sessionToken
                    || sessionTokenProvider == nil
            }
        ) else {
            await achievementStore.release(claim)
            return .stale
        }
        summary = updatedSummary
        guard !newlyAnnounced.isEmpty else {
            return .updated(announcedAchievement: false)
        }

        achievementHaptic()
        return .updated(announcedAchievement: true)
    }

    private func enqueueAction(
        level: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        evidence: DailyPresenceActionEvidence?,
        operationDate: Date,
        sessionToken: PresenceSessionToken
    ) {
        guard let pendingAction, pendingAction.sessionToken == sessionToken else {
            self.pendingAction = PendingAction(
                level: level,
                status: status,
                evidence: evidence,
                operationDate: operationDate,
                sessionToken: sessionToken
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
            operationDate: min(operationDate, pendingAction.operationDate),
            sessionToken: sessionToken
        )
    }

    private func makeOperationContext() async -> ResolvedOperationContext {
        let provided = operationContextProvider()
        let ownerID = await provided.service.ownerID
        return ResolvedOperationContext(
            service: provided.service,
            sessionToken: provided.sessionToken
                ?? PresenceSessionToken(ownerID: ownerID, generation: 0)
        )
    }

    private func isCurrent(_ operationToken: PresenceSessionToken) async -> Bool {
        if let sessionTokenProvider {
            return sessionTokenProvider() == operationToken
        }
        return await operationContextProvider().service.ownerID == operationToken.ownerID
    }

    private func prepareForOperation(in sessionToken: PresenceSessionToken) {
        guard presentedSessionToken != sessionToken else { return }
        presentedSessionToken = sessionToken
        today = nil
        summary = nil
        syncState = .synced
        message = nil
        if pendingAction?.sessionToken != sessionToken {
            pendingAction = nil
        }
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
