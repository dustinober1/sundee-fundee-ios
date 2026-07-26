import CloudKit
import Foundation
import Testing
@testable import SundeeFundeeKit

actor MemoryPresenceStore: PresenceLocalStoring {
    var records: [String: DailyPresenceRecord] = [:]
    var pendingIDs: Set<String> = []

    func load() -> [DailyPresenceRecord] { Array(records.values) }

    func save(_ record: DailyPresenceRecord) {
        records[record.id] = record
        pendingIDs.insert(record.id)
    }

    func markSynced(id: String) {
        pendingIDs.remove(id)
    }

    func pending() -> [DailyPresenceRecord] {
        pendingIDs.compactMap { records[$0] }
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
        let service = DailyPresenceService(localStore: store, dataClient: nil)
        let first = Date(timeIntervalSince1970: 1_753_528_400)

        _ = try await service.recordOpen(at: first, calendar: calendar)
        let second = try await service.recordOpen(at: first.addingTimeInterval(60), calendar: calendar)

        #expect(await store.load().count == 1)
        #expect(second.firstOpenDate == first)
        #expect(second.mostRecentOpenDate == first.addingTimeInterval(60))
    }

    @Test func localWriteSucceedsWhenRemoteSaveFails() async throws {
        let store = MemoryPresenceStore()
        let failingClient = FailingPresenceDataClient()
        let service = DailyPresenceService(localStore: store, dataClient: failingClient)

        let record = try await service.recordOpen(
            at: Date(timeIntervalSince1970: 1_753_528_400),
            calendar: calendar
        )

        #expect(await store.pending().map(\.id) == [record.id])
    }

    @Test func promoteTodayNeverDowngradesParticipation() async throws {
        let store = MemoryPresenceStore()
        let service = DailyPresenceService(localStore: store, dataClient: nil)
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
        let writer = PresenceLocalStore(fileURL: fileURL)
        try await writer.save(record)

        let reader = PresenceLocalStore(fileURL: fileURL)
        #expect(try await reader.pending() == [record])

        try await reader.markSynced(id: record.id)
        let reopened = PresenceLocalStore(fileURL: fileURL)
        #expect(try await reopened.load() == [record])
        #expect(try await reopened.pending().isEmpty)
    }

    @Test func corruptCacheBlocksReadsAndNeverOverwritesHistory() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let corruptedData = Data("not valid presence JSON".utf8)
        try corruptedData.write(to: fileURL)
        let store = PresenceLocalStore(fileURL: fileURL)

        var loadFailed = false
        do {
            _ = try await store.load()
        } catch {
            loadFailed = true
        }
        #expect(loadFailed)

        var pendingFailed = false
        do {
            _ = try await store.pending()
        } catch {
            pendingFailed = true
        }
        #expect(pendingFailed)

        var saveFailed = false
        do {
            try await store.save(makeRecord(dayKey: "2025-07-24"))
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

        let firstStore = PresenceLocalStore(fileURL: fileURL)
        let secondStore = PresenceLocalStore(fileURL: fileURL)
        let first = makeRecord(dayKey: "2025-07-24")
        let second = makeRecord(dayKey: "2025-07-25")

        try await firstStore.save(first)
        try await secondStore.save(second)

        let records = try await PresenceLocalStore(fileURL: fileURL).load()
        #expect(Set(records.map(\.id)) == Set([first.id, second.id]))
    }

    @Test func failedPersistenceDoesNotChangeInMemoryState() async throws {
        let store = PresenceLocalStore(fileURL: URL(fileURLWithPath: "/dev/null/daily-presence.json"))

        var saveFailed = false
        do {
            try await store.save(makeRecord(dayKey: "2025-07-24"))
        } catch {
            saveFailed = true
        }

        #expect(saveFailed)
        #expect(try await store.load().isEmpty)
    }

    @Test func syncRetriesFailuresAndContinuesWithLaterRecords() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-presence.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = PresenceLocalStore(fileURL: fileURL)
        let first = makeRecord(dayKey: "2025-07-24")
        let second = makeRecord(dayKey: "2025-07-25")
        try await store.save(first)
        try await store.save(second)

        let client = StatefulPresenceDataClient(failingIDs: [first.id])
        let service = DailyPresenceService(localStore: store, dataClient: client)
        await service.syncPending()

        #expect(try await store.pending().map(\.id) == [first.id])
        #expect(await client.savedIDs() == [second.id])
        #expect(await client.savedRecordTypes() == [DailyPresenceService.recordType])

        await client.allowAllSaves()
        await service.syncPending()

        #expect(try await store.pending().isEmpty)
        #expect(await client.savedIDs() == [second.id, first.id])
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
        []
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
