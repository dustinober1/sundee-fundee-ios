import Foundation

// MARK: - Cycle Phase

/// The four phases of the menstrual cycle
public enum CyclePhase: String, Codable, Sendable {
    case menstrual
    case follicular
    case ovulation
    case luteal
}

// MARK: - Types

/// Settings for cycle phase calculations
public struct CycleSettings: Codable, Sendable {
    public let averageCycleLengthDays: Int
    public let averagePeriodLengthDays: Int
    public let lutealPhaseLengthDays: Int

    public init(
        averageCycleLengthDays: Int = 28,
        averagePeriodLengthDays: Int = 5,
        lutealPhaseLengthDays: Int = 14
    ) {
        self.averageCycleLengthDays = averageCycleLengthDays
        self.averagePeriodLengthDays = averagePeriodLengthDays
        self.lutealPhaseLengthDays = lutealPhaseLengthDays
    }
}

/// A period log entry
public struct PeriodLog: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date?

    public init(startDate: Date, endDate: Date? = nil) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

/// Boundary days within a cycle (1-indexed)
public struct PhaseBoundary: Sendable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

/// Result of cycle status calculation
public struct CycleStatusResult: Sendable {
    public let currentPhase: CyclePhase
    public let cycleDay: Int
    public let daysUntilNextPhase: Int
    public let predictedNextPeriod: Date
    public let phaseStartDate: Date
    public let phaseEndDate: Date
}

/// Training recommendation for a cycle phase
public struct PhaseRecommendation: Sendable {
    public let phase: CyclePhase
    public let title: String
    public let description: String
    public let trainingFocus: String
    public let intensityRecommendation: String
    public let exercisesToEmphasize: [String]
    public let exercisesToAvoid: [String]
}

// MARK: - Date Helpers

private let calendar = Calendar.current

private func startOfDay(_ date: Date) -> Date {
    calendar.startOfDay(for: date)
}

private func addDays(_ date: Date, _ days: Int) -> Date {
    calendar.date(byAdding: .day, value: days, to: startOfDay(date)) ?? date
}

private func daysBetween(from: Date, to: Date) -> Int {
    let fromStart = startOfDay(from)
    let toStart = startOfDay(to)
    return calendar.dateComponents([.day], from: fromStart, to: toStart).day ?? 0
}

private func isWithin(_ target: Date, start: Date, end: Date) -> Bool {
    let t = startOfDay(target)
    return t >= startOfDay(start) && t <= startOfDay(end)
}

// MARK: - Phase Boundaries

/// Calculate phase day boundaries for a given cycle settings
public func getPhaseBoundaries(settings: CycleSettings) -> [CyclePhase: PhaseBoundary] {
    getPhaseBoundaries(settings: settings, menstrualLengthOverride: nil)
}

private func getPhaseBoundaries(
    settings: CycleSettings,
    menstrualLengthOverride: Int?
) -> [CyclePhase: PhaseBoundary] {
    let cycleLen = max(1, settings.averageCycleLengthDays)
    let periodLen = min(max(1, menstrualLengthOverride ?? settings.averagePeriodLengthDays), cycleLen)
    let lutealLen = settings.lutealPhaseLengthDays

    let ovDay = cycleLen - lutealLen
    let ovStart = min(cycleLen, max(periodLen + 2, ovDay - 2))
    let ovEnd = min(cycleLen, max(ovStart, ovDay + 2))

    return [
        .menstrual:  PhaseBoundary(start: 1, end: periodLen),
        .follicular: PhaseBoundary(start: periodLen + 1, end: ovStart - 1),
        .ovulation:  PhaseBoundary(start: ovStart, end: ovEnd),
        .luteal:     PhaseBoundary(start: ovEnd + 1, end: cycleLen),
    ]
}

// MARK: - Calculate Cycle Status

/// Calculate current cycle status from period logs and settings
public func calculateCycleStatus(
    periodLogs: [PeriodLog],
    settings: CycleSettings,
    referenceDate: Date = Date()
) -> CycleStatusResult? {
    guard !periodLogs.isEmpty else { return nil }

    let ref = startOfDay(referenceDate)
    let sorted = periodLogs.sorted { startOfDay($0.startDate) > startOfDay($1.startDate) }

    var cycleStartDate: Date? = nil
    var loggedMenstrualLength: Int? = nil

    for period in sorted {
        let pStart = startOfDay(period.startDate)
        let pEnd: Date
        if let logEnd = period.endDate {
            pEnd = startOfDay(logEnd)
        } else if ref >= pStart {
            // Active period (no end date): treat as ongoing through reference date
            pEnd = ref
        } else {
            pEnd = addDays(pStart, settings.averagePeriodLengthDays - 1)
        }

        if isWithin(ref, start: pStart, end: pEnd) {
            cycleStartDate = pStart
            if period.endDate != nil {
                loggedMenstrualLength = daysBetween(from: pStart, to: pEnd) + 1
            }
            break
        }
        let nextExpected = addDays(pStart, settings.averageCycleLengthDays)
        if ref > pEnd && ref < nextExpected {
            cycleStartDate = pStart
            if period.endDate != nil {
                loggedMenstrualLength = daysBetween(from: pStart, to: pEnd) + 1
            }
            break
        }
    }

    let cycleStart: Date
    if let found = cycleStartDate {
        cycleStart = found
    } else {
        let most = sorted[0]
        var start = startOfDay(most.startDate)
        let daysSince = daysBetween(from: start, to: ref)
        let safeCycleLength = max(1, settings.averageCycleLengthDays)
        let completed = daysSince / safeCycleLength
        start = addDays(start, completed * safeCycleLength)
        cycleStart = start
    }

    let cycleDay = daysBetween(from: cycleStart, to: ref) + 1
    let boundaries = getPhaseBoundaries(settings: settings, menstrualLengthOverride: loggedMenstrualLength)

    let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]
    var currentPhase: CyclePhase = .follicular
    var phaseStartDay = 1
    var phaseEndDay = settings.averageCycleLengthDays

    for phase in phases {
        if let b = boundaries[phase], cycleDay >= b.start && cycleDay <= b.end {
            currentPhase = phase
            phaseStartDay = b.start
            phaseEndDay = b.end
            break
        }
    }

    let daysUntilNext: Int
    switch currentPhase {
    case .menstrual:
        daysUntilNext = (boundaries[.follicular]?.start ?? cycleDay) - cycleDay
    case .follicular:
        daysUntilNext = (boundaries[.ovulation]?.start ?? cycleDay) - cycleDay
    case .ovulation:
        daysUntilNext = (boundaries[.luteal]?.start ?? cycleDay) - cycleDay
    case .luteal:
        daysUntilNext = settings.averageCycleLengthDays - cycleDay + 1
    }

    return CycleStatusResult(
        currentPhase: currentPhase,
        cycleDay: cycleDay,
        daysUntilNextPhase: max(0, daysUntilNext),
        predictedNextPeriod: addDays(cycleStart, settings.averageCycleLengthDays),
        phaseStartDate: addDays(cycleStart, phaseStartDay - 1),
        phaseEndDate: addDays(cycleStart, phaseEndDay - 1)
    )
}

// MARK: - Phase Recommendations

/// Get training recommendation for a cycle phase
public func getPhaseRecommendation(phase: CyclePhase) -> PhaseRecommendation {
    switch phase {
    case .menstrual:
        return PhaseRecommendation(
            phase: .menstrual,
            title: "Shark Week",
            description: "Your period phase. Energy may be lower — you might feel more fatigued.",
            trainingFocus: "Recovery and light movement",
            intensityRecommendation: "low",
            exercisesToEmphasize: ["yoga", "walking", "light stretching"],
            exercisesToAvoid: ["heavy compound lifts", "max effort attempts"]
        )
    case .follicular:
        return PhaseRecommendation(
            phase: .follicular,
            title: "Follicular Phase",
            description: "Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.",
            trainingFocus: "Building strength and endurance",
            intensityRecommendation: "moderate",
            exercisesToEmphasize: ["compound movements", "strength training", "cardio"],
            exercisesToAvoid: []
        )
    case .ovulation:
        return PhaseRecommendation(
            phase: .ovulation,
            title: "Ovulation Phase",
            description: "Peak estrogen and testosterone. Often the strongest phase for performance.",
            trainingFocus: "High-intensity training and PR attempts",
            intensityRecommendation: "peak",
            exercisesToEmphasize: ["max effort attempts", "heavy compound lifts", "power-focused workouts"],
            exercisesToAvoid: []
        )
    case .luteal:
        return PhaseRecommendation(
            phase: .luteal,
            title: "Luteal Phase",
            description: "Progesterone rises, which may affect recovery and energy. Focus on maintenance.",
            trainingFocus: "Maintenance and technique refinement",
            intensityRecommendation: "moderate",
            exercisesToEmphasize: ["technique work", "volume training", "recovery-focused sessions"],
            exercisesToAvoid: ["max effort attempts", "extremely heavy loads"]
        )
    }
}
