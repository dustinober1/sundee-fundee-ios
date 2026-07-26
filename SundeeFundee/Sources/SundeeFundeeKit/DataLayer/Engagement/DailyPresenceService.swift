import CloudKit
import Foundation

public enum PresenceSyncStatus: String, Sendable, Equatable {
    case synced
    case pending
    case retrying
    case actionRequired
}

public struct PresenceSyncState: Sendable, Equatable {
    public let status: PresenceSyncStatus
    public let pendingCount: Int

    public init(status: PresenceSyncStatus, pendingCount: Int) {
        self.status = status
        self.pendingCount = pendingCount
    }

    public static let synced = Self(status: .synced, pendingCount: 0)
}

public actor DailyPresenceService {
    public static let recordType = "DailyPresenceRecord"

    public let ownerID: String
    private let localStore: any PresenceLocalStoring
    private let dataClient: (any DataClientProtocol)?
    private let momentumService: ConsistencyMomentumService
    private var syncState: PresenceSyncState = .synced
    private var legacyAliasesByCanonicalID: [String: Set<String>] = [:]

    public init(
        ownerID: String,
        localStore: any PresenceLocalStoring,
        dataClient: (any DataClientProtocol)? = nil,
        momentumService: ConsistencyMomentumService = ConsistencyMomentumService()
    ) {
        self.ownerID = ownerID
        self.localStore = localStore
        self.dataClient = dataClient
        self.momentumService = momentumService
    }

    public init(
        ownerID: String,
        dataClient: (any DataClientProtocol)? = nil,
        momentumService: ConsistencyMomentumService = ConsistencyMomentumService()
    ) {
        self.init(
            ownerID: ownerID,
            localStore: PresenceLocalStore(ownerID: ownerID),
            dataClient: dataClient,
            momentumService: momentumService
        )
    }

    public func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        try await reconcileAllowingTransientFailure()
        let record = try await upsertOpen(at: date, calendar: calendar)
        _ = await syncPendingWithoutReconciliation()
        return record
    }

    public func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        action: DailyPresenceActionEvidence? = nil,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        try await reconcileAllowingTransientFailure()
        let opened = try await upsertOpen(at: date, calendar: calendar)
        let promoted = opened.promoting(
            to: participationLevel,
            status: status,
            action: action,
            at: date
        )
        let pending = try await localStore.save(promoted, ownerID: ownerID)
        _ = await syncPendingWithoutReconciliation()
        return pending.record
    }

    public func loadSummary(
        referenceDate: Date,
        calendar: Calendar
    ) async throws -> ConsistencyMomentumSummary {
        try await reconcileAllowingTransientFailure()
        let records = try await localStore.load(ownerID: ownerID)
        return momentumService.summarize(
            records: records,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    public func currentSyncState() -> PresenceSyncState {
        syncState
    }

    @discardableResult
    public func syncPending() async -> PresenceSyncState {
        do {
            try await reconcileRemote()
        } catch {
            return await recordSyncFailure(error)
        }
        return await syncPendingWithoutReconciliation()
    }

    private func syncPendingWithoutReconciliation() async -> PresenceSyncState {
        guard let dataClient else {
            syncState = .synced
            return syncState
        }

        let initialPending: [PendingPresenceRecord]
        do {
            initialPending = try await localStore.pending(ownerID: ownerID)
        } catch {
            return await recordSyncFailure(error)
        }

        guard !initialPending.isEmpty else {
            await deleteReconciledLegacyAliases(using: dataClient)
            syncState = .synced
            return syncState
        }

        syncState = PresenceSyncState(
            status: .retrying,
            pendingCount: initialPending.count
        )
        var requiresAction = false

        for pendingRecord in initialPending {
            do {
                try await dataClient.save(
                    pendingRecord.record,
                    recordType: Self.recordType
                )
                try await localStore.markSynced(
                    pendingRecord,
                    ownerID: ownerID
                )
            } catch {
                requiresAction = requiresAction || Self.requiresAction(for: error)
            }
        }

        let remaining: [PendingPresenceRecord]
        do {
            remaining = try await localStore.pending(ownerID: ownerID)
        } catch {
            return await recordSyncFailure(error)
        }

        if remaining.isEmpty {
            await deleteReconciledLegacyAliases(using: dataClient)
            syncState = .synced
        } else {
            syncState = PresenceSyncState(
                status: requiresAction ? .actionRequired : .pending,
                pendingCount: remaining.count
            )
        }
        return syncState
    }

    private func reconcileAllowingTransientFailure() async throws {
        do {
            try await reconcileRemote()
        } catch {
            syncState = PresenceSyncState(
                status: Self.requiresAction(for: error) ? .actionRequired : .pending,
                pendingCount: await pendingCountOrZero()
            )
            if Self.isOwnershipFailure(error) {
                throw error
            }
        }
    }

    private func reconcileRemote() async throws {
        guard let dataClient else { return }
        let remoteRecords: [DailyPresenceRecord] = try await dataClient.fetchAll(
            recordType: Self.recordType
        )

        var mergedRemoteByDay: [String: DailyPresenceRecord] = [:]
        var aliasesByCanonicalID: [String: Set<String>] = [:]
        for remoteRecord in remoteRecords {
            let canonicalID = DailyPresenceRecord.makeID(
                dayKey: remoteRecord.dayKey,
                timeZoneIdentifier: remoteRecord.timeZoneIdentifier
            )
            if let existing = mergedRemoteByDay[remoteRecord.dayKey] {
                mergedRemoteByDay[remoteRecord.dayKey] = existing.merging(with: remoteRecord)
            } else {
                mergedRemoteByDay[remoteRecord.dayKey] = remoteRecord
            }
            if remoteRecord.id != canonicalID {
                aliasesByCanonicalID[canonicalID, default: []].insert(remoteRecord.id)
            }
        }

        try await localStore.storeRemote(
            Array(mergedRemoteByDay.values),
            ownerID: ownerID
        )

        let localRecords = try await localStore.load(ownerID: ownerID)
        var pendingIDs = Set(
            try await localStore.pending(ownerID: ownerID).map(\.record.id)
        )
        let remoteDayKeys = Set(mergedRemoteByDay.keys)

        for localRecord in localRecords {
            let needsCanonicalUpload = aliasesByCanonicalID[localRecord.id] != nil
            let isMissingRemotely = !remoteDayKeys.contains(localRecord.dayKey)
            guard (needsCanonicalUpload || isMissingRemotely),
                  !pendingIDs.contains(localRecord.id) else {
                continue
            }
            let pending = try await localStore.save(localRecord, ownerID: ownerID)
            pendingIDs.insert(pending.record.id)
        }

        for (canonicalID, aliases) in aliasesByCanonicalID {
            legacyAliasesByCanonicalID[canonicalID, default: []].formUnion(aliases)
        }
    }

    private func upsertOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        let key = PresenceLocalDay.key(for: date, calendar: calendar)
        let records = try await localStore.load(ownerID: ownerID)

        let record: DailyPresenceRecord
        if let existing = records.first(where: { $0.dayKey == key }) {
            record = existing.promoting(to: .showedUp, status: nil, at: date)
        } else {
            record = DailyPresenceRecord(
                dayKey: key,
                timeZoneIdentifier: calendar.timeZone.identifier,
                firstOpenDate: date
            )
        }

        return try await localStore.save(record, ownerID: ownerID).record
    }

    private func deleteReconciledLegacyAliases(using dataClient: any DataClientProtocol) async {
        guard !legacyAliasesByCanonicalID.isEmpty else { return }

        let pendingIDs =
            (try? await localStore.pending(ownerID: ownerID).map(\.record.id)) ?? []
        let syncedCanonicalIDs = legacyAliasesByCanonicalID.keys.filter {
            !pendingIDs.contains($0)
        }

        for canonicalID in syncedCanonicalIDs {
            guard let aliases = legacyAliasesByCanonicalID[canonicalID] else { continue }
            do {
                try await dataClient.delete(
                    recordIDs: aliases.sorted().map { CKRecord.ID(recordName: $0) },
                    recordType: Self.recordType
                )
                legacyAliasesByCanonicalID.removeValue(forKey: canonicalID)
            } catch {
                continue
            }
        }
    }

    private func recordSyncFailure(_ error: Error) async -> PresenceSyncState {
        syncState = PresenceSyncState(
            status: Self.requiresAction(for: error) ? .actionRequired : .pending,
            pendingCount: await pendingCountOrZero()
        )
        return syncState
    }

    private func pendingCountOrZero() async -> Int {
        (try? await localStore.pending(ownerID: ownerID).count) ?? 0
    }

    private static func isOwnershipFailure(_ error: Error) -> Bool {
        error is PresenceStoreError
    }

    private static func requiresAction(for error: Error) -> Bool {
        if error is PresenceStoreError || error is DecodingError {
            return true
        }
        guard let dataError = error as? DataError else { return false }
        switch dataError {
        case .permissionDenied, .invalidData, .schemaNotDeployed:
            return true
        case .recordNotFound, .networkError:
            return false
        }
    }
}
