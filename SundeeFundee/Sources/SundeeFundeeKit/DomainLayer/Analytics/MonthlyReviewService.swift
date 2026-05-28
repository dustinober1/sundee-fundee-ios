import Foundation

// MARK: - MonthlyReview

/// A computed summary of a user's training month. Built from existing data —
/// no new CloudKit records required.
public struct MonthlyReview: Sendable, Equatable {
    public let monthTitle: String
    public let workoutCount: Int
    public let personalRecordCount: Int
    public let topWins: [String]
    public let patterns: [String]
    public let nextMonthSuggestions: [String]

    public init(
        monthTitle: String,
        workoutCount: Int,
        personalRecordCount: Int,
        topWins: [String],
        patterns: [String],
        nextMonthSuggestions: [String]
    ) {
        self.monthTitle = monthTitle
        self.workoutCount = workoutCount
        self.personalRecordCount = personalRecordCount
        self.topWins = topWins
        self.patterns = patterns
        self.nextMonthSuggestions = nextMonthSuggestions
    }
}

// MARK: - MonthlyReviewService

/// Pure domain service that aggregates a month of training data into a
/// human-readable review. No framework dependencies beyond Foundation.
public enum MonthlyReviewService {

    public static func build(
        month: Date,
        workouts: [Workout],
        recoveryScores: [RecoveryScoreRecord],
        painLogs: [DailyPainLog],
        effortLogs: [WorkoutEffortLog],
        symptomLogs: [SymptomCheckInRecord]? = nil,
        calendar: Calendar = .current
    ) -> MonthlyReview {
        let monthTitle = formatMonthTitle(month, calendar: calendar)

        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return MonthlyReview(
                monthTitle: monthTitle,
                workoutCount: 0,
                personalRecordCount: 0,
                topWins: [],
                patterns: [],
                nextMonthSuggestions: ["Start training this month to see your review."]
            )
        }

        let start = monthInterval.start
        let end = monthInterval.end

        // Filter to completed workouts in the target month
        let completedWorkouts = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= start && completedAt < end
        }

        // Filter effort logs to the month
        let monthEffortLogs = effortLogs.filter { log in
            log.dateCreated >= start && log.dateCreated < end
        }

        // Filter recovery scores to the month
        let monthRecoveryScores = filterRecoveryScores(recoveryScores, from: start, to: end)

        // Filter pain logs to the month
        let monthPainLogs = painLogs.filter { $0.date >= start && $0.date < end }

        // Filter symptom logs to the month
        let monthSymptomLogs: [SymptomCheckInRecord]
        if let symptomLogs {
            monthSymptomLogs = symptomLogs.filter { $0.dateCreated >= start && $0.dateCreated < end }
        } else {
            monthSymptomLogs = []
        }

        let workoutCount = completedWorkouts.count
        let prCount = countPersonalRecords(from: monthEffortLogs)

        let topWins = buildTopWins(
            workoutCount: workoutCount,
            prCount: prCount,
            effortLogs: monthEffortLogs,
            recoveryScores: monthRecoveryScores
        )

        let patterns = buildPatterns(
            workouts: completedWorkouts,
            effortLogs: monthEffortLogs,
            calendar: calendar
        )

        let nextMonthSuggestions = buildSuggestions(
            hasRecoveryData: !monthRecoveryScores.isEmpty,
            hasSymptomData: !monthSymptomLogs.isEmpty,
            hasPainData: !monthPainLogs.isEmpty,
            workoutCount: workoutCount,
            prCount: prCount
        )

        return MonthlyReview(
            monthTitle: monthTitle,
            workoutCount: workoutCount,
            personalRecordCount: prCount,
            topWins: topWins,
            patterns: patterns,
            nextMonthSuggestions: nextMonthSuggestions
        )
    }

    // MARK: - Private Helpers

    private static func formatMonthTitle(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func filterRecoveryScores(
        _ scores: [RecoveryScoreRecord],
        from start: Date,
        to end: Date
    ) -> [RecoveryScoreRecord] {
        let isoFormatter = ISO8601DateFormatter()
        return scores.filter { score in
            guard let scoreDate = isoFormatter.date(from: score.scoreDate) else { return false }
            return scoreDate >= start && scoreDate < end
        }
    }

    private static func countPersonalRecords(from effortLogs: [WorkoutEffortLog]) -> Int {
        // High-RPE sessions (>= 8) serve as a proxy for personal-record-level effort
        effortLogs.filter { $0.rpe >= 8 }.count
    }

    private static func buildTopWins(
        workoutCount: Int,
        prCount: Int,
        effortLogs: [WorkoutEffortLog],
        recoveryScores: [RecoveryScoreRecord]
    ) -> [String] {
        var wins: [String] = []

        // Consistency win
        if workoutCount > 0 {
            wins.append("\(workoutCount) workout\(workoutCount == 1 ? "" : "s") completed")
        }

        // Average RPE win
        if !effortLogs.isEmpty {
            let avgRPE = Double(effortLogs.reduce(0) { $0 + $1.rpe }) / Double(effortLogs.count)
            wins.append(String(format: "Average RPE of %.1f", avgRPE))
        }

        // Personal record / high-effort win
        if prCount > 0 {
            wins.append("\(prCount) high-effort session\(prCount == 1 ? "" : "s")")
        }

        // Recovery score win
        if !recoveryScores.isEmpty {
            let avgScore = recoveryScores.reduce(0) { $0 + $1.totalScore } / recoveryScores.count
            if avgScore >= 60 {
                wins.append("Average recovery score of \(avgScore)")
            }
        }

        return Array(wins.prefix(3))
    }

    private static func buildPatterns(
        workouts: [Workout],
        effortLogs: [WorkoutEffortLog],
        calendar: Calendar
    ) -> [String] {
        var patterns: [String] = []

        // Most frequent training day
        if !workouts.isEmpty {
            let weekdayCounts = Dictionary(grouping: workouts) { workout in
                calendar.component(.weekday, from: workout.date)
            }
            if let (weekday, ws) = weekdayCounts.max(by: { $0.value.count < $1.value.count }),
               ws.count >= 2 {
                let dayName = weekdayName(weekday)
                patterns.append("You trained most consistently on \(dayName)s")
            }
        }

        // Effort trend (compare first half vs second half)
        if effortLogs.count >= 4 {
            let sortedEfforts = effortLogs.sorted { $0.dateCreated < $1.dateCreated }
            let midpoint = sortedEfforts.count / 2
            let firstHalfAvg = Double(sortedEfforts[..<midpoint].reduce(0) { $0 + $1.rpe }) / Double(midpoint)
            let secondHalfAvg = Double(sortedEfforts[midpoint...].reduce(0) { $0 + $1.rpe }) / Double(sortedEfforts.count - midpoint)

            if secondHalfAvg > firstHalfAvg + 0.5 {
                patterns.append("Effort trended up mid-month")
            } else if firstHalfAvg > secondHalfAvg + 0.5 {
                patterns.append("Strongest effort came early in the month")
            }
        }

        // Volume trend
        if workouts.count >= 4 {
            let sortedWorkouts = workouts.sorted { $0.date < $1.date }
            let midpoint = sortedWorkouts.count / 2
            let firstHalfVolume = sortedWorkouts[..<midpoint].reduce(0.0) { $0 + $1.totalVolume }
            let secondHalfVolume = sortedWorkouts[midpoint...].reduce(0.0) { $0 + $1.totalVolume }
            let firstHalfCount = Double(midpoint)
            let secondHalfCount = Double(sortedWorkouts.count - midpoint)

            if firstHalfCount > 0 && secondHalfCount > 0 {
                let avgFirst = firstHalfVolume / firstHalfCount
                let avgSecond = secondHalfVolume / secondHalfCount
                if avgSecond > avgFirst * 1.1 {
                    patterns.append("Training volume increased as the month progressed")
                }
            }
        }

        return Array(patterns.prefix(3))
    }

    private static func buildSuggestions(
        hasRecoveryData: Bool,
        hasSymptomData: Bool,
        hasPainData: Bool,
        workoutCount: Int,
        prCount: Int
    ) -> [String] {
        var suggestions: [String] = []

        // Empty month — encouragement
        if workoutCount == 0 {
            suggestions.append("Start with just one workout this month to build momentum")
            suggestions.append("Even a short session counts toward consistency")
            return suggestions
        }

        // Data-gap suggestions (NOT empty — always actionable)
        if !hasRecoveryData {
            suggestions.append("Log recovery scores for clearer insights next month")
        }
        if !hasSymptomData {
            suggestions.append("Track symptoms to see how they relate to training patterns")
        }
        if !hasPainData && !hasSymptomData {
            suggestions.append("Log pain and symptoms to unlock personalized recovery guidance")
        }

        // Goal suggestions when data is rich
        if hasRecoveryData && hasSymptomData && workoutCount >= 4 {
            suggestions.append("Try to match this month's consistency")
        }

        if prCount >= 2 {
            suggestions.append("Build on your high-effort sessions — aim for one more next month")
        }

        if workoutCount >= 8 {
            suggestions.append("Great training volume — consider adding a deload week if needed")
        }

        // Ensure at least one suggestion is always present
        if suggestions.isEmpty {
            suggestions.append("Keep showing up — consistency builds results")
        }

        return Array(suggestions.prefix(4))
    }

    private static func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Day"
        }
    }
}
