import Foundation

public actor TodayWorkoutPreferenceService {
    private let dataClient: DataClientProtocol
    private static let recordType = "TodayWorkoutPreference"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func saveDurationPreference(minutes: Int, date: Date = Date()) async throws {
        var record = try await loadOrCreate(date: date)
        record.preferredMinutes = minutes
        try await dataClient.save(record, recordType: Self.recordType)
    }

    public func saveReducedVolume(date: Date = Date()) async throws {
        var record = try await loadOrCreate(date: date)
        record.reduceVolumeSelected = true
        try await dataClient.save(record, recordType: Self.recordType)
    }

    private func loadOrCreate(date: Date) async throws -> TodayWorkoutPreferenceRecord {
        let key = Self.dateKey(for: date)
        let records: [TodayWorkoutPreferenceRecord] = try await dataClient.fetchAll(recordType: Self.recordType)
        if let existing = records.first(where: { $0.dateKey == key }) {
            return existing
        }
        return TodayWorkoutPreferenceRecord(id: "today_preferences_\(key)", dateKey: key)
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
