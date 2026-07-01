import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class BestNextWorkoutViewModel: ObservableObject {
    @Published public var isBuilding = false
    @Published public var errorMessage: String?

    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func buildWorkout() async -> QuickWorkoutResult? {
        isBuilding = true
        errorMessage = nil
        defer { isBuilding = false }

        async let settingsTask: [UserSettingsRecord] = fetch("UserSettings")
        async let painTask: [DailyPainLog] = fetch("DailyPainLog")
        async let checkInTask: [SymptomCheckInRecord] = fetch("SymptomCheckInRecord")

        let settings = (try? await settingsTask) ?? []
        let painLogs = recentPainLogs((try? await painTask) ?? [])
        let checkIns = (try? await checkInTask) ?? []

        let defaultEquipment = settings.last?.defaultEquipment ?? .fullGym
        let latestEnergy = latestEnergyLevel(from: checkIns)
        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: defaultEquipment,
            latestEnergy: latestEnergy,
            painLogs: painLogs,
            todayDecisionKind: .modify
        )

        await GrowthAnalyticsService(dataClient: dataClient).track(
            "best_next_20_generated",
            source: "train",
            properties: [
                "equipment": request.equipment.rawValue,
                "energy": request.energyLevel.rawValue,
                "decision": request.todayDecisionKind.rawValue
            ]
        )

        return QuickWorkoutBuilder.build(request: request)
    }

    private func fetch<T>(_ recordType: String) async throws -> [T] where T: Decodable & Sendable {
        try await dataClient.fetchAll(recordType: recordType)
    }

    private func recentPainLogs(_ logs: [DailyPainLog]) -> [DailyPainLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return logs.filter { $0.date >= cutoff }
    }

    private func latestEnergyLevel(from checkIns: [SymptomCheckInRecord]) -> EnergyLevel? {
        guard let latest = checkIns.sorted(by: { $0.symptomDate > $1.symptomDate }).first else {
            return nil
        }

        switch latest.energy {
        case 0...3:
            return .low
        case 7...10:
            return .high
        default:
            return .medium
        }
    }
}
