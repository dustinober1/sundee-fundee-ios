import Foundation

// MARK: - Cycle Calendar

/// Get the phase for a given cycle day, wrapping around cycle length
public func getPhaseForDay(_ cycleDay: Int, settings: CycleSettings) -> CyclePhase {
    let len = max(1, settings.averageCycleLengthDays)
    var normalized: Int

    if cycleDay <= 0 {
        normalized = len + cycleDay
        if normalized <= 0 {
            normalized = ((normalized - 1) % len + len) % len + 1
        }
    } else {
        normalized = ((cycleDay - 1) % len + len) % len + 1
    }

    let boundaries = getPhaseBoundaries(settings: settings)
    let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]

    for phase in phases {
        if let b = boundaries[phase], normalized >= b.start && normalized <= b.end {
            return phase
        }
    }

    return .luteal
}

/// Get a human-readable summary of phase adjustments
public func getPhaseAdjustmentSummary(_ phase: CyclePhase) -> String {
    switch phase {
    case .menstrual:
        return "Recovery focus — load -10%, volume -10%"
    case .follicular:
        return "baseline — no adjustments, building phase"
    case .ovulation:
        return "Peak performance — load +12%, sets +5%"
    case .luteal:
        return "Maintenance — load -3%, volume -8%"
    }
}

/// Get a detailed explanation of what happens in a cycle phase
public func getPhaseExplanation(_ phase: CyclePhase) -> String {
    switch phase {
    case .menstrual:
        return "During menstruation, your body is actively recovering. Energy and iron levels may be lower, so we reduce load and volume to support recovery while keeping you active."
    case .follicular:
        return "Rising estrogen supports muscle growth and endurance. This is your building phase — no adjustments needed, train at your normal capacity."
    case .ovulation:
        return "Peak estrogen and testosterone create an optimal window for strength. Your body can handle higher loads and intensity — this is your time to push for PRs."
    case .luteal:
        return "Progesterone rises, which may affect recovery and thermoregulation. We slightly reduce load and volume to match your body's shifting priorities. Toggle off if you're feeling strong."
    }
}

/// Data for a single calendar day
public struct CalendarDayData: Sendable {
    public let date: Date
    public let cycleDay: Int?
    public let phase: CyclePhase?
    public let isToday: Bool
    public let isPeriodLogged: Bool
}

/// Generate calendar data for a given month/year
public func getCycleCalendarData(
    periodLogs: [PeriodLog],
    settings: CycleSettings,
    month: Int,
    year: Int
) -> [CalendarDayData] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    guard let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month))!) else {
        return []
    }

    return range.map { day in
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        let dateStart = calendar.startOfDay(for: date)
        let isToday = dateStart == today

        let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings, referenceDate: date)

        let isPeriodLogged = periodLogs.contains { log in
            let start = calendar.startOfDay(for: log.startDate)
            let end: Date
            if let logEnd = log.endDate {
                end = calendar.startOfDay(for: logEnd)
            } else {
                end = calendar.date(byAdding: .day, value: settings.averagePeriodLengthDays - 1, to: start)!
            }
            return dateStart >= start && dateStart <= end
        }

        return CalendarDayData(
            date: date,
            cycleDay: status?.cycleDay,
            phase: status?.currentPhase,
            isToday: isToday,
            isPeriodLogged: isPeriodLogged
        )
    }
}
