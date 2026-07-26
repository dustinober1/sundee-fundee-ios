import Foundation

public actor DailyPresenceService {
    public static let recordType = "DailyPresenceRecord"

    private let localStore: any PresenceLocalStoring
    private let dataClient: (any DataClientProtocol)?
    private let momentumService: ConsistencyMomentumService

    public init(
        localStore: any PresenceLocalStoring = PresenceLocalStore(),
        dataClient: (any DataClientProtocol)? = nil,
        momentumService: ConsistencyMomentumService = ConsistencyMomentumService()
    ) {
        self.localStore = localStore
        self.dataClient = dataClient
        self.momentumService = momentumService
    }

    public func recordOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        let record = try await upsertOpen(at: date, calendar: calendar)
        await syncPending()
        return record
    }

    public func promoteToday(
        to participationLevel: DailyParticipationLevel,
        status: DailyPresenceStatus?,
        at date: Date,
        calendar: Calendar
    ) async throws -> DailyPresenceRecord {
        let opened = try await recordOpen(at: date, calendar: calendar)
        let promoted = opened.promoting(to: participationLevel, status: status, at: date)
        try await localStore.save(promoted)
        await syncPending()
        return promoted
    }

    public func loadSummary(
        referenceDate: Date,
        calendar: Calendar
    ) async throws -> ConsistencyMomentumSummary {
        let records = try await localStore.load()
        return momentumService.summarize(
            records: records,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    public func syncPending() async {
        guard let dataClient else { return }
        guard let records = try? await localStore.pending() else { return }

        for record in records {
            do {
                try await dataClient.save(record, recordType: Self.recordType)
                try await localStore.markSynced(id: record.id)
            } catch {
                continue
            }
        }
    }

    private func upsertOpen(at date: Date, calendar: Calendar) async throws -> DailyPresenceRecord {
        let key = dayKey(for: date, calendar: calendar)
        let timeZoneIdentifier = calendar.timeZone.identifier
        let id = DailyPresenceRecord.makeID(dayKey: key, timeZoneIdentifier: timeZoneIdentifier)
        let records = try await localStore.load()

        let record: DailyPresenceRecord
        if let existing = records.first(where: { $0.id == id }) {
            record = existing.promoting(to: .showedUp, status: nil, at: date)
        } else {
            record = DailyPresenceRecord(
                dayKey: key,
                timeZoneIdentifier: timeZoneIdentifier,
                firstOpenDate: date
            )
        }

        try await localStore.save(record)
        return record
    }

    private func dayKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
