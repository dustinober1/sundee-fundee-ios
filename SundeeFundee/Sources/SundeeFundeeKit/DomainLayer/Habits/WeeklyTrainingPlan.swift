import Foundation

public struct WeeklyTrainingPlan: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let weekStartDate: Date
    public var targetWorkoutCount: Int
    public var preferredWeekdays: [Int]
    public var completedWorkoutIDs: [String]
    public var dateCreated: Date
    public var dateUpdated: Date

    public init(
        id: String = UUID().uuidString,
        weekStartDate: Date,
        targetWorkoutCount: Int,
        preferredWeekdays: [Int],
        completedWorkoutIDs: [String] = [],
        dateCreated: Date = Date(),
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.targetWorkoutCount = targetWorkoutCount
        self.preferredWeekdays = preferredWeekdays
        self.completedWorkoutIDs = completedWorkoutIDs
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }
}

public struct WeeklyPlanProgress: Sendable, Equatable {
    public let completed: Int
    public let target: Int
    public let nextWorkoutWeekday: Int?

    public var displayText: String {
        "\(completed) of \(target) workouts complete"
    }
}

public struct WorkoutReminderSettings: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public var isEnabled: Bool
    public var preferredWeekdays: [Int]
    public var hour: Int
    public var minute: Int
    public var dateUpdated: Date

    public init(
        id: String = "workout_reminder_settings",
        isEnabled: Bool = false,
        preferredWeekdays: [Int] = [2, 4, 6],
        hour: Int = 9,
        minute: Int = 0,
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.preferredWeekdays = preferredWeekdays
        self.hour = hour
        self.minute = minute
        self.dateUpdated = dateUpdated
    }
}
