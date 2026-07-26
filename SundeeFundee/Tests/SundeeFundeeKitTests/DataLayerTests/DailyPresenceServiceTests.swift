import CloudKit
import Foundation
import Testing
@testable import SundeeFundeeKit

actor MemoryPresenceStore: PresenceLocalStoring {
    let ownerID: String
    var records: [String: DailyPresenceRecord] = [:]
    var pendingRevisions: [String: Int] = [:]
    var nextRevision = 1

    init(ownerID: String = "account-a") {
        self.ownerID = ownerID
    }

    func load(ownerID: String) throws -> [DailyPresenceRecord] {
        try validate(ownerID)
        return records.values.sorted { $0.dayKey < $1.dayKey }
    }

    func save(
        _ record: DailyPresenceRecord,
        ownerID: String
    ) throws -> PendingPresenceRecord {
        try validate(ownerID)
        let existing = records[record.dayKey]
        let merged = existing?.merging(with: record) ?? record
        records[record.dayKey] = merged
        let revision = nextRevision
        nextRevision += 1
        pendingRevisions[record.dayKey] = revision
        return PendingPresenceRecord(record: merged, revision: revision)
    }

    func storeRemote(
        _ remoteRecords: [DailyPresenceRecord],
        ownerID: String
    ) throws {
        try validate(ownerID)
        for remote in remoteRecords {
            let existing = records[remote.dayKey]
            let merged = existing?.merging(with: remote) ?? remote
            records[remote.dayKey] = merged
            if existing != nil, merged != remote {
                let revision = nextRevision
                nextRevision += 1
                pendingRevisions[remote.dayKey] = revision
            }
        }
    }

    func markSynced(
        _ pendingRecord: PendingPresenceRecord,
        ownerID: String
    ) throws {
        try validate(ownerID)
        guard pendingRevisions[pendingRecord.record.dayKey] == pendingRecord.revision else {
            return
        }
        pendingRevisions.removeValue(forKey: pendingRecord.record.dayKey)
    }

    func pending(ownerID: String) throws -> [PendingPresenceRecord] {
        try validate(ownerID)
        return pendingRevisions.compactMap { dayKey, revision in
            records[dayKey].map { PendingPresenceRecord(record: $0, revision: revision) }
        }.sorted { $0.record.dayKey < $1.record.dayKey }
    }

    func importRecords(
        _ importedRecords: [DailyPresenceRecord],
        ownerID: String,
        markPending: Bool
    ) throws {
        try validate(ownerID)
        for record in importedRecords {
            records[record.dayKey] = records[record.dayKey]?.merging(with: record) ?? record
            if markPending {
                pendingRevisions[record.dayKey] = nextRevision
                nextRevision += 1
            }
        }
    }

    func clear(ownerID: String) throws {
        try validate(ownerID)
        records.removeAll()
        pendingRevisions.removeAll()
    }

    private func validate(_ requestedOwnerID: String) throws {
        guard requestedOwnerID == ownerID else {
            throw PresenceStoreError.ownershipMismatch(
                expected: ownerID,
                actual: requestedOwnerID
            )
        }
    }
}

@Suite("Daily presence service")
struct DailyPresenceServiceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    @Test func repeatedOpenUpsertsOneLocalDay() async throws {
        let store = MemoryPresenceStore()
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: nil
        )
        let first = Date(timeIntervalSince1970: 1_753_528_400)

        _ = try await service.recordOpen(at: first, calendar: calendar)
        let second = try await service.recordOpen(at: first.addingTimeInterval(60), calendar: calendar)

        #expect(try await store.load(ownerID: "account-a").count == 1)
        #expect(second.firstOpenDate == first)
        #expect(second.mostRecentOpenDate == first.addingTimeInterval(60))
    }

    @Test func localWriteSucceedsWhenRemoteSaveFails() async throws {
        let store = MemoryPresenceStore()
        let failingClient = FailingPresenceDataClient()
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: failingClient
        )

        let record = try await service.recordOpen(
            at: Date(timeIntervalSince1970: 1_753_528_400),
            calendar: calendar
        )

        #expect(
            try await store.pending(ownerID: "account-a").map(\.record.id) == [record.id]
        )
    }

    @Test func promoteTodayNeverDowngradesParticipation() async throws {
        let store = MemoryPresenceStore()
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: nil
        )
        let date = Date(timeIntervalSince1970: 1_753_528_400)

        _ = try await service.promoteToday(to: .acted, status: .trained, at: date, calendar: calendar)
        let promoted = try await service.promoteToday(
            to: .checkedIn,
            status: nil,
            at: date.addingTimeInterval(60),
            calendar: calendar
        )

        #expect(promoted.participationLevel == .acted)
        #expect(promoted.status == .trained)
        #expect(promoted.mostRecentOpenDate == date.addingTimeInterval(60))
    }

    @Test func localStoreRoundTripsRecordAndSyncedState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let date = Date(timeIntervalSince1970: 1_753_528_400)
        let record = DailyPresenceRecord(
            dayKey: "2025-07-23",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: date
        )
        let writer = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        let pendingRecord = try await writer.save(record, ownerID: "account-a")

        let reader = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        #expect(
            try await reader.pending(ownerID: "account-a").map(\.record) == [record]
        )

        try await reader.markSynced(pendingRecord, ownerID: "account-a")
        let reopened = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        #expect(try await reopened.load(ownerID: "account-a") == [record])
        #expect(try await reopened.pending(ownerID: "account-a").isEmpty)
    }

    @Test func corruptCacheBlocksReadsAndNeverOverwritesHistory() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let corruptedData = Data("not valid presence JSON".utf8)
        try corruptedData.write(to: fileURL)
        let store = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")

        var loadFailed = false
        do {
            _ = try await store.load(ownerID: "account-a")
        } catch {
            loadFailed = true
        }
        #expect(loadFailed)

        var pendingFailed = false
        do {
            _ = try await store.pending(ownerID: "account-a")
        } catch {
            pendingFailed = true
        }
        #expect(pendingFailed)

        var saveFailed = false
        do {
            _ = try await store.save(
                makeRecord(dayKey: "2025-07-24"),
                ownerID: "account-a"
            )
        } catch {
            saveFailed = true
        }
        #expect(saveFailed)
        #expect(try Data(contentsOf: fileURL) == corruptedData)
    }

    @Test func separateStoresMergeWritesToOneFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstStore = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        let secondStore = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        let first = makeRecord(dayKey: "2025-07-24")
        let second = makeRecord(dayKey: "2025-07-25")

        _ = try await firstStore.save(first, ownerID: "account-a")
        _ = try await secondStore.save(second, ownerID: "account-a")

        let records = try await PresenceLocalStore(
            fileURL: fileURL,
            ownerID: "account-a"
        ).load(ownerID: "account-a")
        #expect(Set(records.map(\.id)) == Set([first.id, second.id]))
    }

    @Test func failedPersistenceDoesNotChangeInMemoryState() async throws {
        let store = PresenceLocalStore(
            fileURL: URL(fileURLWithPath: "/dev/null/daily-presence.json"),
            ownerID: "account-a"
        )

        var saveFailed = false
        do {
            _ = try await store.save(
                makeRecord(dayKey: "2025-07-24"),
                ownerID: "account-a"
            )
        } catch {
            saveFailed = true
        }

        #expect(saveFailed)
        var loadFailed = false
        do {
            _ = try await store.load(ownerID: "account-a")
        } catch {
            loadFailed = true
        }
        #expect(loadFailed)
    }

    @Test func syncRetriesFailuresAndContinuesWithLaterRecords() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        let first = makeRecord(dayKey: "2025-07-24")
        let second = makeRecord(dayKey: "2025-07-25")
        _ = try await store.save(first, ownerID: "account-a")
        _ = try await store.save(second, ownerID: "account-a")

        let client = StatefulPresenceDataClient(failingIDs: [first.id])
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: client
        )
        _ = await service.syncPending()

        #expect(
            try await store.pending(ownerID: "account-a").map(\.record.id) == [first.id]
        )
        #expect(await client.savedIDs() == [second.id])
        #expect(await client.savedRecordTypes() == [DailyPresenceService.recordType])

        await client.allowAllSaves()
        _ = await service.syncPending()

        #expect(try await store.pending(ownerID: "account-a").isEmpty)
        #expect(await client.savedIDs() == [second.id, first.id])
    }

    @Test func accountNamespacesAreIsolatedAndClearOnlyTheSelectedAccount() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstStore = PresenceLocalStore(ownerID: "account-a", baseDirectoryURL: directory)
        let secondStore = PresenceLocalStore(ownerID: "account-b", baseDirectoryURL: directory)
        let firstRecord = makeRecord(dayKey: "2025-07-24")
        let secondRecord = makeRecord(dayKey: "2025-07-25")

        _ = try await firstStore.save(firstRecord, ownerID: "account-a")
        _ = try await secondStore.save(secondRecord, ownerID: "account-b")

        #expect(try await firstStore.load(ownerID: "account-a") == [firstRecord])
        #expect(try await secondStore.load(ownerID: "account-b") == [secondRecord])

        try await firstStore.clear(ownerID: "account-a")

        #expect(try await firstStore.load(ownerID: "account-a").isEmpty)
        #expect(try await secondStore.load(ownerID: "account-b") == [secondRecord])
    }

    @Test func ownershipMismatchNeverUploadsAnotherAccountsPendingRecord() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        _ = try await store.save(makeRecord(dayKey: "2025-07-24"), ownerID: "account-a")
        let client = StatefulPresenceDataClient(failingIDs: [])
        let service = DailyPresenceService(
            ownerID: "account-b",
            localStore: store,
            dataClient: client
        )

        let state = await service.syncPending()

        #expect(state.status == .actionRequired)
        #expect(await client.savedIDs().isEmpty)
        #expect(try await store.pending(ownerID: "account-a").count == 1)
    }

    @Test func emptyCacheHydratesRemoteHistoryBeforeBuildingSummary() async throws {
        let store = MemoryPresenceStore(ownerID: "account-a")
        let remote = makeRecord(dayKey: "2025-07-24").promoting(
            to: .acted,
            status: .trained,
            action: .trained,
            at: Date(timeIntervalSince1970: 1_753_528_460)
        )
        let client = RemotePresenceDataClient(records: [remote])
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: client
        )

        let summary = try await service.loadSummary(
            referenceDate: Date(timeIntervalSince1970: 1_753_528_460),
            calendar: calendar
        )

        #expect(summary.actionDaysThisWeek == 1)
        let hydrated = try await store.load(ownerID: "account-a")
        #expect(
            hydrated.first?.actionEvidence
                == Set([DailyPresenceActionEvidence.trained])
        )
        #expect(try await store.pending(ownerID: "account-a").isEmpty)
    }

    @Test func secondDeviceOpenCannotDowngradeFirstDevicesTraining() async throws {
        let client = RemotePresenceDataClient()
        let firstStore = MemoryPresenceStore(ownerID: "account-a")
        let secondStore = MemoryPresenceStore(ownerID: "account-a")
        let firstService = DailyPresenceService(
            ownerID: "account-a",
            localStore: firstStore,
            dataClient: client
        )
        let secondService = DailyPresenceService(
            ownerID: "account-a",
            localStore: secondStore,
            dataClient: client
        )
        let date = Date(timeIntervalSince1970: 1_753_528_400)

        _ = try await firstService.promoteToday(
            to: .acted,
            status: .trained,
            action: .trained,
            at: date,
            calendar: calendar
        )
        _ = try await secondService.recordOpen(
            at: date.addingTimeInterval(60),
            calendar: calendar
        )

        let remote = try #require(await client.records().first)
        #expect(remote.participationLevel == .acted)
        #expect(remote.actionEvidence == Set([DailyPresenceActionEvidence.trained]))
        let hydrated = try await secondStore.load(ownerID: "account-a")
        #expect(hydrated.count == 1)
        #expect(
            hydrated.first?.actionEvidence
                == Set([DailyPresenceActionEvidence.trained])
        )
    }

    @Test func olderUploadCannotAcknowledgeANewerLocalMutation() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = PresenceLocalStore(fileURL: fileURL, ownerID: "account-a")
        let original = makeRecord(dayKey: "2025-07-24")
        _ = try await store.save(original, ownerID: "account-a")
        let client = BlockingPresenceSaveDataClient()
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: client
        )

        let sync = Task { await service.syncPending() }
        await client.waitUntilSaveStarts()
        let newer = original.promoting(
            to: .acted,
            status: .trained,
            action: .trained,
            at: original.dateUpdated.addingTimeInterval(60)
        )
        _ = try await store.save(newer, ownerID: "account-a")
        await client.releaseSave()
        _ = await sync.value

        let pending = try await store.pending(ownerID: "account-a")
        #expect(pending.count == 1)
        #expect(
            pending.first?.record.actionEvidence
                == Set([DailyPresenceActionEvidence.trained])
        )
    }

    @Test func recordOpenThenSummaryShowsWelcomeBackAfterGap() async throws {
        let store = MemoryPresenceStore(ownerID: "account-a")
        let service = DailyPresenceService(
            ownerID: "account-a",
            localStore: store,
            dataClient: nil
        )
        let earlier = Date(timeIntervalSince1970: 1_752_948_000)
        _ = try await service.recordOpen(at: earlier, calendar: calendar)
        let returnDate = earlier.addingTimeInterval(7 * 24 * 60 * 60)

        _ = try await service.recordOpen(at: returnDate, calendar: calendar)
        let summary = try await service.loadSummary(
            referenceDate: returnDate,
            calendar: calendar
        )

        #expect(summary.supportiveHeadline == "Welcome back")
    }
}

private func makeRecord(dayKey: String) -> DailyPresenceRecord {
    DailyPresenceRecord(
        dayKey: dayKey,
        timeZoneIdentifier: "America/New_York",
        firstOpenDate: Date(timeIntervalSince1970: 1_753_528_400)
    )
}

private actor FailingPresenceDataClient: DataClientProtocol {
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        []
    }

    func save<T>(_ records: [T], recordType: String) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}

private actor StatefulPresenceDataClient: DataClientProtocol {
    private var failingIDs: Set<String>
    private var savedRecords: [DailyPresenceRecord] = []
    private var recordTypes: [String] = []

    init(failingIDs: Set<String>) {
        self.failingIDs = failingIDs
    }

    func allowAllSaves() {
        failingIDs.removeAll()
    }

    func savedIDs() -> [String] {
        savedRecords.map(\.id)
    }

    func savedRecordTypes() -> [String] {
        recordTypes
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        guard recordType == DailyPresenceService.recordType,
              let records = savedRecords as? [T] else {
            return []
        }
        return records
    }

    func save<T>(_ records: [T], recordType: String) async throws where T: Encodable & Sendable {
        guard let presenceRecords = records as? [DailyPresenceRecord] else { return }
        guard !presenceRecords.contains(where: { failingIDs.contains($0.id) }) else {
            throw DataError.networkError(underlying: nil)
        }
        savedRecords.append(contentsOf: presenceRecords)
        recordTypes.append(recordType)
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}

private actor RemotePresenceDataClient: DataClientProtocol {
    private var recordsByDay: [String: DailyPresenceRecord]

    init(records: [DailyPresenceRecord] = []) {
        recordsByDay = Dictionary(
            uniqueKeysWithValues: records.map { ($0.dayKey, $0) }
        )
    }

    func records() -> [DailyPresenceRecord] {
        recordsByDay.values.sorted { $0.dayKey < $1.dayKey }
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        guard recordType == DailyPresenceService.recordType,
              let typed = records() as? [T] else {
            return []
        }
        return typed
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        guard recordType == DailyPresenceService.recordType,
              let presenceRecords = records as? [DailyPresenceRecord] else {
            return
        }
        for record in presenceRecords {
            recordsByDay[record.dayKey] =
                recordsByDay[record.dayKey]?.merging(with: record) ?? record
        }
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {
        let deletedIDs = Set(recordIDs.map(\.recordName))
        recordsByDay = recordsByDay.filter { !deletedIDs.contains($0.value.id) }
    }

    func deleteAllData() async throws {
        recordsByDay.removeAll()
    }
}

private actor BlockingPresenceSaveDataClient: DataClientProtocol {
    private var saveStarted = false
    private var saveStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var saveContinuation: CheckedContinuation<Void, Never>?

    func waitUntilSaveStarts() async {
        if saveStarted { return }
        await withCheckedContinuation { continuation in
            saveStartWaiters.append(continuation)
        }
    }

    func releaseSave() {
        saveContinuation?.resume()
        saveContinuation = nil
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        []
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        saveStarted = true
        let waiters = saveStartWaiters
        saveStartWaiters.removeAll()
        waiters.forEach { $0.resume() }
        await withCheckedContinuation { continuation in
            saveContinuation = continuation
        }
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}
