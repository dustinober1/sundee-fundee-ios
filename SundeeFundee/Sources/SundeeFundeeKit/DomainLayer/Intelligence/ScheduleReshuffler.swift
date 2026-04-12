import Foundation

// MARK: - ScheduleReshuffler

/// Redistributes missed workout sessions across remaining available days.
///
/// Given a weekly plan and the days already completed or missed,
/// the reshuffler moves uncompleted sessions to available slots
/// without exceeding volume thresholds.
///
/// Pure domain logic — no framework dependencies.
public enum ScheduleReshuffler {

    // MARK: - Types

    /// Priority level for sessions — determines drop order when capacity is limited.
    public enum SessionPriority: Int, Sendable, Equatable, Comparable {
        /// Conditioning/cardio — dropped first.
        case conditioning = 0
        /// Accessory/isolation work — dropped second.
        case accessory = 1
        /// Major compound lifts — dropped last.
        case compound = 2

        public static func < (lhs: SessionPriority, rhs: SessionPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// A planned session in the weekly schedule.
    public struct PlannedSession: Sendable, Equatable {
        /// The day of the week (1 = Monday, 7 = Sunday).
        public let dayOfWeek: Int

        /// Session name or identifier.
        public let sessionName: String

        /// Primary focus of the session.
        public let focus: String

        /// Estimated duration in minutes.
        public let estimatedMinutes: Int

        /// Priority level (compound > accessory > conditioning).
        /// Defaults to `.accessory` for backward compatibility.
        public let priority: SessionPriority

        public init(
            dayOfWeek: Int,
            sessionName: String,
            focus: String,
            estimatedMinutes: Int,
            priority: SessionPriority = .accessory
        ) {
            self.dayOfWeek = dayOfWeek
            self.sessionName = sessionName
            self.focus = focus
            self.estimatedMinutes = estimatedMinutes
            self.priority = priority
        }
    }

    /// The result of a reshuffle operation.
    public struct ReshuffleResult: Sendable, Equatable {
        /// The redistributed schedule (sessions mapped to new days).
        public let rescheduledSessions: [PlannedSession]

        /// Sessions that couldn't be fit into the remaining week.
        public let droppedSessions: [PlannedSession]

        /// Human-readable explanation of what changed.
        public let summary: String
    }

    // MARK: - Configuration

    /// Maximum sessions per day after reshuffling.
    public static let maxSessionsPerDay = 2

    /// Maximum total minutes per day after reshuffling.
    public static let maxMinutesPerDay = 120

    // MARK: - Reshuffling

    /// Reshuffles missed sessions into available days.
    ///
    /// - Parameters:
    ///   - plan: The original weekly plan.
    ///   - completedDays: Days of the week (1-7) where sessions were completed.
    ///   - missedDays: Days of the week (1-7) where sessions were missed.
    ///   - currentDay: The current day of the week (1-7).
    /// - Returns: A reshuffle result with the new schedule and any dropped sessions.
    public static func reshuffle(
        plan: [PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int
    ) -> ReshuffleResult {
        // Identify missed sessions
        let missed = plan.filter { missedDays.contains($0.dayOfWeek) }

        guard !missed.isEmpty else {
            return ReshuffleResult(
                rescheduledSessions: plan.filter { $0.dayOfWeek >= currentDay },
                droppedSessions: [],
                summary: "No missed sessions to reschedule."
            )
        }

        // Find available future days (not yet completed, not yet missed, >= current day)
        let usedDays = completedDays.union(missedDays)
        let futureDays = (currentDay...7).filter { !usedDays.contains($0) }

        // Sessions already planned for future days
        let futurePlanned = plan.filter { futureDays.contains($0.dayOfWeek) }

        // Build a capacity map for each future day
        var dayLoad: [Int: (count: Int, minutes: Int)] = [:]
        for day in futureDays {
            let existingSessions = futurePlanned.filter { $0.dayOfWeek == day }
            dayLoad[day] = (
                count: existingSessions.count,
                minutes: existingSessions.map(\.estimatedMinutes).reduce(0, +)
            )
        }

        var rescheduled: [PlannedSession] = futurePlanned
        var dropped: [PlannedSession] = []

        // Sort missed sessions by priority descending (compound first, conditioning last)
        // so that high-priority sessions get placed first and are dropped last.
        let missedByPriority = missed.sorted { $0.priority > $1.priority }

        // Try to place each missed session into the best available day
        // Prefer days with the same focus, then days with the most remaining capacity
        for session in missedByPriority {
            var bestDay: Int?
            var bestScore = -1

            for day in futureDays {
                guard let load = dayLoad[day] else { continue }

                // Check capacity
                guard load.count < maxSessionsPerDay else { continue }
                guard load.minutes + session.estimatedMinutes <= maxMinutesPerDay else { continue }

                // Score: prefer same-focus days, then emptier days
                var score = 100 - load.count * 30 - load.minutes
                let sameFocus = futurePlanned.contains {
                    $0.dayOfWeek == day && $0.focus == session.focus
                }
                if sameFocus { score += 50 }

                if score > bestScore {
                    bestScore = score
                    bestDay = day
                }
            }

            if let day = bestDay {
                let moved = PlannedSession(
                    dayOfWeek: day,
                    sessionName: session.sessionName,
                    focus: session.focus,
                    estimatedMinutes: session.estimatedMinutes,
                    priority: session.priority
                )
                rescheduled.append(moved)
                dayLoad[day]?.count += 1
                dayLoad[day]?.minutes += session.estimatedMinutes
            } else {
                dropped.append(session)
            }
        }

        // Sort by day
        rescheduled.sort { $0.dayOfWeek < $1.dayOfWeek }

        let summary = buildSummary(
            missed: missed,
            rescheduled: rescheduled.filter { session in
                missed.contains(where: { $0.sessionName == session.sessionName })
            },
            dropped: dropped
        )

        return ReshuffleResult(
            rescheduledSessions: rescheduled,
            droppedSessions: dropped,
            summary: summary
        )
    }

    // MARK: - Private

    private static func buildSummary(
        missed: [PlannedSession],
        rescheduled: [PlannedSession],
        dropped: [PlannedSession]
    ) -> String {
        var parts: [String] = []

        if !rescheduled.isEmpty {
            let names = rescheduled.map(\.sessionName).joined(separator: ", ")
            parts.append("Moved \(rescheduled.count) session(s) (\(names)) to later this week.")
        }

        if !dropped.isEmpty {
            let keptNames = rescheduled.map(\.sessionName)
            let droppedNames = dropped.map(\.sessionName).joined(separator: ", ")

            if !keptNames.isEmpty && dropped.contains(where: { $0.priority < rescheduled.first?.priority ?? .accessory }) {
                let keptStr = keptNames.joined(separator: ", ")
                parts.append("Kept higher-priority session(s) (\(keptStr)) and dropped \(droppedNames) due to limited availability.")
            } else {
                parts.append("Couldn't fit \(dropped.count) session(s) (\(droppedNames)) — consider a longer session or adding them next week.")
            }
        }

        return parts.isEmpty ? "Schedule unchanged." : parts.joined(separator: " ")
    }
}
