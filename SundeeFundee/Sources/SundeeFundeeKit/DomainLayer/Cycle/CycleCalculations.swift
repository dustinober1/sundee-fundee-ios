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

// MARK: - Ovulation Biomarker Evidence

/// Objective physiological evidence for ovulation and luteal transition
/// derived from Apple Watch sleeping wrist temperature or LH surge tests.
public struct OvulationBiomarkerEvidence: Sendable, Equatable {
    /// Date of detected LH surge from urine ovulation test strip.
    public let lhSurgeDate: Date?

    /// Estimated date of ovulation.
    public let estimatedOvulationDate: Date?

    /// Whether a biphasic nocturnal wrist temperature shift was detected.
    public let hasThermalShift: Bool

    /// Magnitude of thermal shift in Celsius (typically +0.20°C to +0.50°C).
    public let thermalShiftCelsius: Double?

    /// Whether any biomarker confirms the current cycle's ovulation/luteal timing.
    public var hasBiomarkerConfirmation: Bool {
        lhSurgeDate != nil || hasThermalShift
    }

    public init(
        lhSurgeDate: Date? = nil,
        estimatedOvulationDate: Date? = nil,
        hasThermalShift: Bool = false,
        thermalShiftCelsius: Double? = nil
    ) {
        self.lhSurgeDate = lhSurgeDate
        self.estimatedOvulationDate = estimatedOvulationDate
        self.hasThermalShift = hasThermalShift
        self.thermalShiftCelsius = thermalShiftCelsius
    }
}

private func matchPeriodLog(
    _ period: PeriodLog,
    ref: Date,
    settings: CycleSettings
) -> (matched: Bool, menstrualLength: Int?) {
    let pStart = startOfDay(period.startDate)
    let pEnd: Date
    if let logEnd = period.endDate {
        pEnd = startOfDay(logEnd)
    } else if ref >= pStart {
        pEnd = ref
    } else {
        pEnd = addDays(pStart, settings.averagePeriodLengthDays - 1)
    }

    let isOngoing = isWithin(ref, start: pStart, end: pEnd)
    let nextExpected = addDays(pStart, settings.averageCycleLengthDays)
    let isInWindow = ref > pEnd && ref < nextExpected

    if isOngoing || isInWindow {
        let length = period.endDate != nil ? (daysBetween(from: pStart, to: pEnd) + 1) : nil
        return (true, length)
    }
    return (false, nil)
}

private func findCycleStartDateAndMenstrualLength(
    sorted: [PeriodLog],
    settings: CycleSettings,
    ref: Date
) -> (cycleStart: Date, loggedMenstrualLength: Int?) {
    var cycleStartDate: Date?
    var loggedMenstrualLength: Int?

    for period in sorted {
        let (matched, length) = matchPeriodLog(period, ref: ref, settings: settings)
        if matched {
            cycleStartDate = startOfDay(period.startDate)
            loggedMenstrualLength = length
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

    return (cycleStart, loggedMenstrualLength)
}

private func refinePhaseWithBiomarkers(
    currentPhase: CyclePhase,
    boundaries: [CyclePhase: PhaseBoundary],
    evidence: OvulationBiomarkerEvidence?,
    ref: Date,
    defaultStart: Int,
    defaultEnd: Int
) -> (phase: CyclePhase, startDay: Int, endDay: Int) {
    guard currentPhase != .menstrual, let evidence else {
        return (currentPhase, defaultStart, defaultEnd)
    }

    if let surge = evidence.lhSurgeDate {
        let daysSinceSurge = daysBetween(from: startOfDay(surge), to: ref)
        if daysSinceSurge >= 0 && daysSinceSurge <= 2 {
            let b = boundaries[.ovulation]
            return (.ovulation, b?.start ?? defaultStart, b?.end ?? defaultEnd)
        } else if daysSinceSurge > 2 && evidence.hasThermalShift {
            let b = boundaries[.luteal]
            return (.luteal, b?.start ?? defaultStart, b?.end ?? defaultEnd)
        }
    } else if evidence.hasThermalShift {
        if currentPhase == .follicular || currentPhase == .ovulation {
            let b = boundaries[.luteal]
            return (.luteal, b?.start ?? defaultStart, b?.end ?? defaultEnd)
        }
    }

    return (currentPhase, defaultStart, defaultEnd)
}

// MARK: - Calculate Cycle Status

/// Calculate current cycle status from period logs and settings
public func calculateCycleStatus(
    periodLogs: [PeriodLog],
    settings: CycleSettings,
    referenceDate: Date = Date(),
    biomarkerEvidence: OvulationBiomarkerEvidence? = nil
) -> CycleStatusResult? {
    guard !periodLogs.isEmpty else { return nil }

    let ref = startOfDay(referenceDate)
    let sorted = periodLogs.sorted { startOfDay($0.startDate) > startOfDay($1.startDate) }

    let (cycleStart, loggedMenstrualLength) = findCycleStartDateAndMenstrualLength(
        sorted: sorted,
        settings: settings,
        ref: ref
    )

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

    // Refine phase if objective biomarker evidence is available
    let refined = refinePhaseWithBiomarkers(
        currentPhase: currentPhase,
        boundaries: boundaries,
        evidence: biomarkerEvidence,
        ref: ref,
        defaultStart: phaseStartDay,
        defaultEnd: phaseEndDay
    )
    currentPhase = refined.phase
    phaseStartDay = refined.startDay
    phaseEndDay = refined.endDay

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

// MARK: - Cycle Terminology Style

/// Terminology style for cycle phase labels and recommendations.
public enum CycleTerminologyStyle: String, Codable, Sendable, CaseIterable {
    case physiological
    case hormone
    case casual

    public var displayName: String {
        switch self {
        case .physiological: return "Physiological (e.g., Menstrual)"
        case .hormone: return "Hormone Profile (e.g., Low Hormone)"
        case .casual: return "Casual (e.g., Shark Week)"
        }
    }
}

// MARK: - Phase Recommendations

/// Get training recommendation for a cycle phase
public func getPhaseRecommendation(
    phase: CyclePhase,
    style: CycleTerminologyStyle = .casual
) -> PhaseRecommendation {
    switch phase {
    case .menstrual:
        let title: String
        let description: String
        let exercisesToAvoid: [String]
        switch style {
        case .casual:
            title = "Shark Week"
            description = "Your period phase. Energy may be lower — you might feel more fatigued."
            exercisesToAvoid = ["heavy compound lifts", "max effort attempts"]
        case .physiological:
            title = "Menstrual Phase"
            description = "Low hormone baseline. Individual responses vary — train normally by feel or adjust RPE as needed."
            exercisesToAvoid = []
        case .hormone:
            title = "Low Hormone Phase"
            description = "Estrogen and progesterone at baseline. Autoregulate intensity based on your recovery today."
            exercisesToAvoid = []
        }
        return PhaseRecommendation(
            phase: .menstrual,
            title: title,
            description: description,
            trainingFocus: "Recovery and autoregulated strength",
            intensityRecommendation: "low",
            exercisesToEmphasize: ["yoga", "walking", "light stretching", "technique lifts"],
            exercisesToAvoid: exercisesToAvoid
        )
    case .follicular:
        let title = style == .hormone ? "Estrogen Rise Phase" : "Follicular Phase"
        return PhaseRecommendation(
            phase: .follicular,
            title: title,
            description: "Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.",
            trainingFocus: "Building strength and endurance",
            intensityRecommendation: "moderate",
            exercisesToEmphasize: ["compound movements", "strength training", "cardio"],
            exercisesToAvoid: []
        )
    case .ovulation:
        let title = style == .hormone ? "Peak Estrogen Phase" : "Ovulation Phase"
        return PhaseRecommendation(
            phase: .ovulation,
            title: title,
            description: "Peak estrogen and testosterone. Often high performance; maintain strict form to account for laxity.",
            trainingFocus: "High-intensity training and PR attempts",
            intensityRecommendation: "peak",
            exercisesToEmphasize: ["max effort attempts", "heavy compound lifts", "power-focused workouts"],
            exercisesToAvoid: []
        )
    case .luteal:
        let title = style == .hormone ? "Progesterone Dominant Phase" : "Luteal Phase"
        return PhaseRecommendation(
            phase: .luteal,
            title: title,
            description: "Progesterone rises, slightly elevating core temp. Prioritize hydration and rest intervals.",
            trainingFocus: "Maintenance and technique refinement",
            intensityRecommendation: "moderate",
            exercisesToEmphasize: ["technique work", "volume training", "recovery-focused sessions"],
            exercisesToAvoid: style == .casual ? ["max effort attempts", "extremely heavy loads"] : []
        )
    }
}
