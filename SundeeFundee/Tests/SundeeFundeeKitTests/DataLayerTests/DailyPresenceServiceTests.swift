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
        #expect(await reader.pending() == [record])

        try await reader.markSynced(id: record.id)
        let reopened = PresenceLocalStore(fileURL: fileURL)
        #expect(await reopened.load() == [record])
        #expect(await reopened.pending().isEmpty)
    }
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
