import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor WeeklyPlanService {
    private let dataClient: DataClientProtocol
    private let calendar: Calendar
    private static let recordType = "WeeklyTrainingPlan"

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        calendar: Calendar = .current
    ) {
        self.dataClient = dataClient
        self.calendar = calendar
    }

    public func currentPlan(now: Date = Date()) async -> WeeklyTrainingPlan? {
        let weekStart = startOfWeek(containing: now)
        let plans: [WeeklyTrainingPlan] = (try? await dataClient.fetchAll(recordType: Self.recordType)) ?? []
        return plans.first { calendar.isDate($0.weekStartDate, inSameDayAs: weekStart) }
    }

    public func createOrUpdateCurrentPlan(
        targetWorkoutCount: Int,
        preferredWeekdays: [Int],
        now: Date = Date()
    ) async throws -> WeeklyTrainingPlan {
        let weekStart = startOfWeek(containing: now)
        var plan = await currentPlan(now: now) ?? WeeklyTrainingPlan(
            weekStartDate: weekStart,
            targetWorkoutCount: targetWorkoutCount,
            preferredWeekdays: preferredWeekdays
        )
        plan.targetWorkoutCount = max(1, targetWorkoutCount)
        plan.preferredWeekdays = preferredWeekdays.sorted()
        plan.dateUpdated = now
        try await dataClient.save(plan, recordType: Self.recordType)
        return plan
    }

    public func progress(plan: WeeklyTrainingPlan, workouts: [Workout], now: Date = Date()) -> WeeklyPlanProgress {
        let weekStart = startOfWeek(containing: now)
        let completed = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= weekStart && completedAt < calendar.date(byAdding: .day, value: 7, to: weekStart)!
        }
        let next = suggestNextWorkoutDay(plan: plan, completedCount: completed.count, now: now)
        return WeeklyPlanProgress(
            completed: completed.count,
            target: plan.targetWorkoutCount,
            nextWorkoutWeekday: next
        )
    }

    public func markWorkoutCompleted(_ workout: Workout, now: Date = Date()) async {
        guard var plan = await currentPlan(now: now) else { return }
        guard !plan.completedWorkoutIDs.contains(workout.id) else { return }
        plan.completedWorkoutIDs.append(workout.id)
        plan.dateUpdated = now
        try? await dataClient.save(plan, recordType: Self.recordType)
    }

    public func startOfWeek(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func suggestNextWorkoutDay(plan: WeeklyTrainingPlan, completedCount: Int, now: Date) -> Int? {
        guard completedCount < plan.targetWorkoutCount else { return nil }
        let today = calendar.component(.weekday, from: now)
        return plan.preferredWeekdays.first { $0 >= today } ?? plan.preferredWeekdays.first
    }
}
