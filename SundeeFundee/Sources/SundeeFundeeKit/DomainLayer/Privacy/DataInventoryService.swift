import Foundation

public struct DataInventoryItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let count: Int?
    public let storage: String
    public let notes: String
    public let canExport: Bool
    public let canDelete: Bool

    public init(
        id: String,
        title: String,
        count: Int?,
        storage: String,
        notes: String,
        canExport: Bool,
        canDelete: Bool
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.storage = storage
        self.notes = notes
        self.canExport = canExport
        self.canDelete = canDelete
    }
}

public struct DataInventorySummary: Sendable, Equatable {
    public let items: [DataInventoryItem]
    public let lastUpdated: Date

    public init(items: [DataInventoryItem], lastUpdated: Date = Date()) {
        self.items = items
        self.lastUpdated = lastUpdated
    }
}

public struct DataInventoryService: Sendable {
    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func loadInventory() async -> DataInventorySummary {
        async let workouts: [Workout] = safeFetch(recordType: "Workout")
        async let maxes: [OneRepMaxRecord] = safeFetch(recordType: "OneRepMaxRecord")
        async let cycleLogs: [PeriodLogRecord] = safeFetch(recordType: "PeriodLogRecord")
        async let painLogs: [DailyPainLog] = safeFetch(recordType: "DailyPainLog")
        async let benchmarks: [BenchmarkResult] = safeFetch(recordType: "BenchmarkResult")
        async let weeklyPlans: [WeeklyTrainingPlan] = safeFetch(recordType: "WeeklyTrainingPlan")
        async let settings: [UserSettingsRecord] = safeFetch(recordType: "UserSettings")

        let items: [DataInventoryItem] = await [
            DataInventoryItem(
                id: "workouts",
                title: "Workouts",
                count: workouts.count,
                storage: "iCloud (CloudKit) or local guest storage",
                notes: "Includes exercises, sets, and completion history.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "maxes",
                title: "Strength Maxes",
                count: maxes.count,
                storage: "iCloud (CloudKit) or local guest storage",
                notes: "Used for progression and starting-weight calibration.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "benchmarks",
                title: "Benchmarks",
                count: benchmarks.count,
                storage: "iCloud (CloudKit) or local guest storage",
                notes: "Benchmark attempts and scores tracked over time.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "cycle",
                title: "Cycle Logs",
                count: cycleLogs.count,
                storage: "iCloud (CloudKit), optional Apple Health read access",
                notes: "Manual logs are stored by the app; Health data is read-only unless explicitly written.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "pain",
                title: "Pain Logs",
                count: painLogs.count,
                storage: "iCloud (CloudKit) or local guest storage",
                notes: "Used for substitutions and daily training decisions.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "planning",
                title: "Weekly Plans",
                count: weeklyPlans.count,
                storage: "iCloud (CloudKit) or local guest storage",
                notes: "Preferred training days, targets, and planning preferences.",
                canExport: true,
                canDelete: true
            ),
            DataInventoryItem(
                id: "healthkit",
                title: "HealthKit Read Access",
                count: nil,
                storage: "Apple Health (read-only unless explicitly saved)",
                notes: "Optional read access can help import workouts and cycle context.",
                canExport: false,
                canDelete: false
            ),
            DataInventoryItem(
                id: "account",
                title: "Account Profile",
                count: settings.isEmpty ? 0 : 1,
                storage: "Sign in with Apple + iCloud",
                notes: "Identity is managed by Apple. The app does not run ad tracking.",
                canExport: true,
                canDelete: true
            )
        ]

        return DataInventorySummary(items: items)
    }

    private func safeFetch<T: Decodable & Sendable>(recordType: String) async -> [T] {
        (try? await dataClient.fetchAll(recordType: recordType)) ?? []
    }
}
