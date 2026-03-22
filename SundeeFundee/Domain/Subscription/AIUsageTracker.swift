import Foundation

/// Tracks AI workout generation count per calendar month using UserDefaults.
enum AIUsageTracker {

    static let usageCountKey = "aiWorkoutUsageCount"
    static let usageMonthKey = "aiWorkoutUsageMonth"

    static func currentMonthKey(now: Date = .now, calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return String(format: "%04d-%02d", year, month)
    }

    static func usageThisMonth(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) -> Int {
        let current = currentMonthKey(now: now, calendar: calendar)
        let stored = defaults.string(forKey: usageMonthKey) ?? ""
        if stored != current {
            return 0
        }
        return defaults.integer(forKey: usageCountKey)
    }

    static func incrementUsage(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) {
        let current = currentMonthKey(now: now, calendar: calendar)
        let stored = defaults.string(forKey: usageMonthKey) ?? ""
        if stored != current {
            defaults.set(current, forKey: usageMonthKey)
            defaults.set(1, forKey: usageCountKey)
        } else {
            let count = defaults.integer(forKey: usageCountKey)
            defaults.set(count + 1, forKey: usageCountKey)
        }
    }

    static func resetIfNewMonth(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) {
        let current = currentMonthKey(now: now, calendar: calendar)
        let stored = defaults.string(forKey: usageMonthKey) ?? ""
        if stored != current {
            defaults.set(current, forKey: usageMonthKey)
            defaults.set(0, forKey: usageCountKey)
        }
    }
}
