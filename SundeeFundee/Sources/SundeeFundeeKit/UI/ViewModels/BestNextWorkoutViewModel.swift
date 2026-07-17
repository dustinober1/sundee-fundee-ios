import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class BestNextWorkoutViewModel: ObservableObject {
    @Published public var isBuilding = false
    @Published public var errorMessage: String?
    @Published public private(set) var adjustment: BestNextWorkoutRequestBuilder.Adjustment = .init(decision: nil, explanation: "Using your standard session.", isStandardSession: true)

    private let dataClient: DataClientProtocol
    private var isGuest: Bool

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client, isGuest: Bool = false) {
        self.dataClient = dataClient
        self.isGuest = isGuest
    }

    /// Keeps workout-entry policy aligned with the live authentication session.
    /// Guest mode must never consult persisted readiness or deload history.
    public func updateGuestState(_ isGuest: Bool) {
        self.isGuest = isGuest
        if isGuest {
            adjustment = BestNextWorkoutRequestBuilder.adjustment(for: nil)
        }
    }

    public func buildWorkout(useStandardSession: Bool = false) async -> QuickWorkoutResult? {
        isBuilding = true
        errorMessage = nil
        defer { isBuilding = false }

        async let settingsTask: [UserSettingsRecord] = fetch("UserSettings")
        async let painTask: [DailyPainLog] = fetch("DailyPainLog")
        async let checkInTask: [SymptomCheckInRecord] = fetch("SymptomCheckInRecord")

        let settings = (try? await settingsTask) ?? []
        let painLogs = recentPainLogs((try? await painTask) ?? [])
        let checkIns = (try? await checkInTask) ?? []
        let deloadDecision = await loadDeloadDecision(painLogs: painLogs)

        let defaultEquipment = settings.last?.defaultEquipment ?? .fullGym
        let latestEnergy = latestEnergyLevel(from: checkIns)
        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: defaultEquipment,
            latestEnergy: latestEnergy,
            painLogs: painLogs,
            todayDecisionKind: .modify,
            deloadDecision: deloadDecision,
            useStandardSession: useStandardSession
        )
        adjustment = BestNextWorkoutRequestBuilder.adjustment(for: deloadDecision, useStandardSession: useStandardSession)

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

    private func loadDeloadDecision(painLogs: [DailyPainLog]) async -> DeloadDecision? {
        guard !isGuest else { return nil }
        let records: [DailyReadinessRecord] = (try? await fetch("DailyReadinessRecord")) ?? []
        // A persisted assessment is only actionable for the calendar day it was
        // captured. Never carry yesterday's low score into today's workout.
        guard let readinessRecord = records
            .compactMap({ record -> (DailyReadinessRecord, ReadinessAssessment)? in
                guard let assessment = try? record.assessment() else { return nil }
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: record.timeZoneIdentifier) ?? .current
                guard calendar.isDate(assessment.assessmentDate, inSameDayAs: Date()) else { return nil }
                return (record, assessment)
            })
            .sorted(by: { $0.1.assessmentDate > $1.1.assessmentDate })
            .first else { return nil }
        let readiness = readinessRecord.1

        let workouts: [Workout] = (try? await fetch("Workout")) ?? []
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let recent = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= cutoff
        }
        let load: RecentTrainingLoadEvidence = recent.count >= 6 ? .excessive : (recent.count >= 4 ? .elevated : .balanced)
        let history: DeloadHistory = recent.contains { $0.name.localizedCaseInsensitiveContains("deload") } ? .recent : .none
        let pain = painLogs.map(\.intensity).max() ?? 0
        return DeloadDecisionService.evaluate(readiness: readiness, trainingLoad: load, pain: pain, history: history)
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
