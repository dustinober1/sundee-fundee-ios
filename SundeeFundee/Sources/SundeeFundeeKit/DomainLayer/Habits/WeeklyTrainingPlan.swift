import Foundation

public struct WeeklyTrainingPlan: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let weekStartDate: Date
    public var targetWorkoutCount: Int
    public var preferredWeekdays: [Int]
    /// CloudKit-safe map of weekday number (as String) -> available minutes.
    public var timeAvailableMinutesByWeekdayRaw: [String: Int]?
    public var cycleAwarePlanningEnabled: Bool?
    public var completedWorkoutIDs: [String]
    public var dateCreated: Date
    public var dateUpdated: Date

    public init(
        id: String = UUID().uuidString,
        weekStartDate: Date,
        targetWorkoutCount: Int,
        preferredWeekdays: [Int],
        timeAvailableMinutesByWeekdayRaw: [String: Int]? = nil,
        cycleAwarePlanningEnabled: Bool? = nil,
        completedWorkoutIDs: [String] = [],
        dateCreated: Date = Date(),
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.targetWorkoutCount = targetWorkoutCount
        self.preferredWeekdays = preferredWeekdays
        self.timeAvailableMinutesByWeekdayRaw = timeAvailableMinutesByWeekdayRaw
        self.cycleAwarePlanningEnabled = cycleAwarePlanningEnabled
        self.completedWorkoutIDs = completedWorkoutIDs
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }

    public var timeAvailableMinutesByWeekday: [Int: Int] {
        guard let raw = timeAvailableMinutesByWeekdayRaw else { return [:] }
        var parsed: [Int: Int] = [:]
        for (weekdayRaw, minutes) in raw {
            guard let weekday = Int(weekdayRaw), (1...7).contains(weekday), minutes > 0 else { continue }
            parsed[weekday] = minutes
        }
        return parsed
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
    public var dailyPlanEnabled: Bool
    public var dailyPlanHour: Int
    public var dailyPlanMinute: Int
    public var dateUpdated: Date

    public init(
        id: String = "workout_reminder_settings",
        isEnabled: Bool = false,
        preferredWeekdays: [Int] = [2, 4, 6],
        hour: Int = 9,
        minute: Int = 0,
        dailyPlanEnabled: Bool = false,
        dailyPlanHour: Int = 8,
        dailyPlanMinute: Int = 0,
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.preferredWeekdays = preferredWeekdays
        self.hour = Self.validatedHour(hour)
        self.minute = Self.validatedMinute(minute)
        self.dailyPlanEnabled = dailyPlanEnabled
        self.dailyPlanHour = Self.validatedHour(dailyPlanHour)
        self.dailyPlanMinute = Self.validatedMinute(dailyPlanMinute)
        self.dateUpdated = dateUpdated
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case isEnabled
        case preferredWeekdays
        case hour
        case minute
        case dailyPlanEnabled
        case dailyPlanHour
        case dailyPlanMinute
        case dateUpdated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        isEnabled = try Self.decodeBool(from: container, forKey: .isEnabled)
        preferredWeekdays = try container.decode([Int].self, forKey: .preferredWeekdays)
        hour = Self.validatedHour(try container.decode(Int.self, forKey: .hour))
        minute = Self.validatedMinute(try container.decode(Int.self, forKey: .minute))
        dailyPlanEnabled = try Self.decodeBoolIfPresent(
            from: container,
            forKey: .dailyPlanEnabled
        ) ?? false
        dailyPlanHour = Self.validatedHour(
            try container.decodeIfPresent(Int.self, forKey: .dailyPlanHour) ?? 8
        )
        dailyPlanMinute = Self.validatedMinute(
            try container.decodeIfPresent(Int.self, forKey: .dailyPlanMinute) ?? 0
        )
        dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
    }

    private static func decodeBool(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Bool {
        guard container.contains(key), try !container.decodeNil(forKey: key) else {
            throw boolTypeMismatch(in: container, forKey: key)
        }
        return try decodePresentBool(from: container, forKey: key)
    }

    private static func decodeBoolIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Bool? {
        guard container.contains(key), try !container.decodeNil(forKey: key) else {
            return nil
        }
        return try decodePresentBool(from: container, forKey: key)
    }

    private static func decodePresentBool(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value != 0
        }
        throw boolTypeMismatch(in: container, forKey: key)
    }

    private static func boolTypeMismatch(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> DecodingError {
        DecodingError.typeMismatch(
            Bool.self,
            DecodingError.Context(
                codingPath: container.codingPath + [key],
                debugDescription: "Expected a Bool or integer-backed Bool for \(key.stringValue)."
            )
        )
    }

    private static func validatedHour(_ hour: Int) -> Int {
        min(max(hour, 0), 23)
    }

    private static func validatedMinute(_ minute: Int) -> Int {
        min(max(minute, 0), 59)
    }
}
