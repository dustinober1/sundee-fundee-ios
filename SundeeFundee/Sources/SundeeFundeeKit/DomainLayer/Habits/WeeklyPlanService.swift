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
        timeAvailableMinutesByWeekdayRaw: [String: Int]? = nil,
        cycleAwarePlanningEnabled: Bool? = nil,
        recoveryAwarePlanningEnabled: Bool? = nil,
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
        if let timeAvailableMinutesByWeekdayRaw {
            plan.timeAvailableMinutesByWeekdayRaw = timeAvailableMinutesByWeekdayRaw
        }
        if let cycleAwarePlanningEnabled {
            plan.cycleAwarePlanningEnabled = cycleAwarePlanningEnabled
        }
        if let recoveryAwarePlanningEnabled {
            plan.recoveryAwarePlanningEnabled = recoveryAwarePlanningEnabled
        }
        plan.dateUpdated = now
        try await dataClient.save(plan, recordType: Self.recordType)
        return plan
    }

    public func progress(
        plan: WeeklyTrainingPlan,
        workouts: [Workout],
        cyclePhase: CyclePhase? = nil,
        recoveryScore: Int? = nil,
        now: Date = Date()
    ) -> WeeklyPlanProgress {
        let weekStart = startOfWeek(containing: now)
        let completed = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= weekStart && completedAt < calendar.date(byAdding: .day, value: 7, to: weekStart)!
        }
        let next = suggestNextWorkoutDay(
            plan: plan,
            completedCount: completed.count,
            cyclePhase: cyclePhase,
            recoveryScore: recoveryScore,
            now: now
        )
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

    private func suggestNextWorkoutDay(
        plan: WeeklyTrainingPlan,
        completedCount: Int,
        cyclePhase: CyclePhase?,
        recoveryScore: Int?,
        now: Date
    ) -> Int? {
        guard completedCount < plan.targetWorkoutCount else { return nil }

        let prioritized = prioritizedWeekdays(
            plan: plan,
            cyclePhase: cyclePhase,
            recoveryScore: recoveryScore
        )
        guard !prioritized.isEmpty else { return nil }

        let today = calendar.component(.weekday, from: now)
        return prioritized.first { $0 >= today } ?? prioritized.first
    }

    private func prioritizedWeekdays(
        plan: WeeklyTrainingPlan,
        cyclePhase: CyclePhase?,
        recoveryScore: Int?
    ) -> [Int] {
        var weekdays = Array(Set(plan.preferredWeekdays)).sorted()

        let availability = plan.timeAvailableMinutesByWeekday
        if !availability.isEmpty {
            weekdays = weekdays.sorted { lhs, rhs in
                let leftMinutes = availability[lhs] ?? 0
                let rightMinutes = availability[rhs] ?? 0
                if leftMinutes == rightMinutes {
                    return lhs < rhs
                }
                return leftMinutes > rightMinutes
            }
        }

        if (plan.cycleAwarePlanningEnabled ?? false), cyclePhase == .menstrual, weekdays.count > 1 {
            weekdays = Array(weekdays.dropFirst())
        }

        if (plan.recoveryAwarePlanningEnabled ?? false),
           let recoveryScore,
           recoveryScore < 40,
           weekdays.count > 1 {
            weekdays = Array(weekdays.dropFirst())
        }

        return weekdays
    }
}
