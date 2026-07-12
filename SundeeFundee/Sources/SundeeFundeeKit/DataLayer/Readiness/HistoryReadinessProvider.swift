import Foundation

/// Historical, user-entered and training signals used to build a readiness context.
public struct HistoryReadinessSnapshot: Sendable, Equatable {
    public let subjective: SubjectiveReadinessSnapshot
    public let training: TrainingReadinessSnapshot
    public let pain: PainReadinessSnapshot?

    public init(
        subjective: SubjectiveReadinessSnapshot,
        training: TrainingReadinessSnapshot,
        pain: PainReadinessSnapshot?
    ) {
        self.subjective = subjective
        self.training = training
        self.pain = pain
    }
}

public protocol HistoryReadinessProviding: Sendable {
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot
}

public actor HistoryReadinessProvider: HistoryReadinessProviding {
    private let dataClient: any DataClientProtocol

    public init(dataClient: any DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot {
        async let symptoms: [SymptomCheckInRecord] = fetch("SymptomCheckInRecord")
        async let painLogs: [DailyPainLog] = fetch("DailyPainLog")
        async let completedRecords: [CompletedWorkoutRecord] = fetch("CompletedWorkoutRecord")
        async let fullWorkouts: [Workout] = fetch("Workout")
        async let checkIns: [WorkoutCompletionCheckInRecord] = fetch("WorkoutCompletionCheckIn")

        let values = await (symptoms, painLogs, completedRecords, fullWorkouts, checkIns)
        let workouts = values.2.isEmpty
            ? values.3.compactMap(\.completedWorkoutRecord)
            : values.2

        let sameDaySymptoms = values.0
            .filter { calendar.isDate($0.symptomDate, inSameDayAs: assessmentDate) }
            .max { $0.dateCreated < $1.dateCreated }
        let sameDayPain = values.1
            .filter { calendar.isDate($0.date, inSameDayAs: assessmentDate) }
            .max { $0.date < $1.date }
        let recentCheckIns = values.4.sorted { $0.dateCreated > $1.dateCreated }.prefix(4)
        let rpes = recentCheckIns.compactMap(\.sessionRPE).map(Double.init)
        let rightForTodayRate = recentCheckIns.isEmpty
            ? nil
            : Double(recentCheckIns.filter(\.wasRightForToday).count) / Double(recentCheckIns.count)

        return HistoryReadinessSnapshot(
            subjective: SubjectiveReadinessSnapshot(
                energy: sameDaySymptoms?.energy,
                fatigue: sameDaySymptoms?.fatigue,
                soreness: sameDaySymptoms?.soreness,
                stress: nil,
                perceivedReadiness: nil,
                cramps: sameDaySymptoms?.cramps
            ),
            training: TrainingReadinessSnapshot(
                weeklyLoadRatio: loadRatio(workouts: workouts, assessmentDate: assessmentDate, calendar: calendar),
                averageSessionRPE: rpes.isEmpty ? nil : rpes.reduce(0, +) / Double(rpes.count),
                rightForTodayRate: rightForTodayRate,
                completedWorkoutsInLast28Days: workouts.filter {
                    guard let start = calendar.date(byAdding: .day, value: -28, to: assessmentDate) else { return false }
                    return $0.date >= start && $0.date <= assessmentDate
                }.count
            ),
            pain: sameDayPain.map {
                PainReadinessSnapshot(
                    intensity: $0.intensity,
                    painType: $0.painType,
                    locationIDs: $0.locationIds.split(separator: ",").map(String.init),
                    observedAt: $0.date
                )
            }
        )
    }

    private func fetch<T: Decodable & Sendable>(_ recordType: String) async -> [T] {
        (try? await dataClient.fetchAll(recordType: recordType)) ?? []
    }

    private func loadRatio(
        workouts: [CompletedWorkoutRecord], assessmentDate: Date, calendar: Calendar
    ) -> Double? {
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: assessmentDate),
              let twentyEightDaysAgo = calendar.date(byAdding: .day, value: -28, to: assessmentDate)
        else { return nil }

        let current = workouts.filter { $0.date >= sevenDaysAgo && $0.date <= assessmentDate }.count
        let prior = workouts.filter { $0.date >= twentyEightDaysAgo && $0.date < sevenDaysAgo }.count
        let priorWeeklyAverage = Double(prior) / 3.0
        guard priorWeeklyAverage > 0 else { return nil }
        return Double(current) / priorWeeklyAverage
    }
}
