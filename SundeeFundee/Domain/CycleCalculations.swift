import Foundation

// MARK: - Shared enums

enum CyclePhase: String, Codable, CaseIterable {
    case menstrual, follicular, ovulation, luteal
}

// MARK: - Result types

struct CycleStatusResult {
    let currentPhase: CyclePhase
    let cycleDay: Int
    let daysUntilNextPhase: Int
    let predictedNextPeriod: Date
    let phaseStartDate: Date
    let phaseEndDate: Date
}

struct PhaseBoundary {
    let start: Int
    let end: Int
}

struct PhaseRecommendation {
    let phase: CyclePhase
    let title: String
    let description: String
    let trainingFocus: String
    let intensityRecommendation: String
    let exercisesToEmphasize: [String]
    let exercisesToAvoid: [String]
}

// MARK: - CycleCalculations

enum CycleCalculations {

    /// Returns nil if no period logs are available.
    static func calculateCycleStatus(
        periodLogs: [PeriodLog],
        settings: CycleSettings,
        referenceDate: Date = .now
    ) -> CycleStatusResult? {
        guard !periodLogs.isEmpty else { return nil }

        let ref = startOfDay(referenceDate)
        let sorted = periodLogs.sorted { $0.startDate > $1.startDate }

        var cycleStartDate: Date?

        for period in sorted {
            let pStart = startOfDay(period.startDate)
            let pEnd   = period.endDate.map { startOfDay($0) }
                      ?? addDays(pStart, settings.averagePeriodLengthDays - 1)

            if isWithin(ref, start: pStart, end: pEnd) {
                cycleStartDate = pStart; break
            }
            let nextExpected = addDays(pStart, settings.averageCycleLengthDays)
            if ref > pEnd && ref < nextExpected {
                cycleStartDate = pStart; break
            }
        }

        let cycleStart: Date
        if let unwrapped = cycleStartDate {
            cycleStart = unwrapped
        } else {
            let most  = sorted[0]
            var start = startOfDay(most.startDate)
            let daysSince = daysBetween(start, ref)
            let completed = daysSince / settings.averageCycleLengthDays
            start = addDays(start, completed * settings.averageCycleLengthDays)
            cycleStart = start
        }

        let cycleDay  = daysBetween(cycleStart, ref) + 1
        let boundaries = getPhaseBoundaries(settings: settings)

        var currentPhase  = CyclePhase.follicular
        var phaseStartDay = 1
        var phaseEndDay   = settings.averageCycleLengthDays

        for phase in CyclePhase.allCases {
            let b = boundaries[phase]!
            if cycleDay >= b.start && cycleDay <= b.end {
                currentPhase  = phase
                phaseStartDay = b.start
                phaseEndDay   = b.end
                break
            }
        }

        let daysUntilNext: Int
        switch currentPhase {
        case .menstrual:
            daysUntilNext = boundaries[.follicular]!.start - cycleDay
        case .follicular:
            daysUntilNext = boundaries[.ovulation]!.start - cycleDay
        case .ovulation:
            daysUntilNext = boundaries[.luteal]!.start - cycleDay
        case .luteal:
            daysUntilNext = settings.averageCycleLengthDays - cycleDay + 1
        }

        return CycleStatusResult(
            currentPhase:       currentPhase,
            cycleDay:           cycleDay,
            daysUntilNextPhase: max(0, daysUntilNext),
            predictedNextPeriod: addDays(cycleStart, settings.averageCycleLengthDays),
            phaseStartDate:      addDays(cycleStart, phaseStartDay - 1),
            phaseEndDate:        addDays(cycleStart, phaseEndDay   - 1)
        )
    }

    static func getPhaseBoundaries(settings: CycleSettings) -> [CyclePhase: PhaseBoundary] {
        let cycleLen   = settings.averageCycleLengthDays
        let periodLen  = settings.averagePeriodLengthDays
        let lutealLen  = settings.lutealPhaseLengthDays

        let ovDay        = cycleLen - lutealLen
        let ovStart      = max(periodLen + 2, ovDay - 2)
        let ovEnd        = min(ovDay + 2, cycleLen - lutealLen + 2)

        return [
            .menstrual:  PhaseBoundary(start: 1,              end: periodLen),
            .follicular: PhaseBoundary(start: periodLen + 1,  end: ovStart - 1),
            .ovulation:  PhaseBoundary(start: ovStart,        end: ovEnd),
            .luteal:     PhaseBoundary(start: ovEnd + 1,      end: cycleLen),
        ]
    }

    static func getPhaseRecommendation(_ phase: CyclePhase) -> PhaseRecommendation {
        switch phase {
        case .menstrual:
            return PhaseRecommendation(
                phase: .menstrual,
                title: "Menstrual Phase",
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

    // MARK: - Date helpers

    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func addDays(_ date: Date, _ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: startOfDay(date))!
    }

    private static func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day!
    }

    private static func isWithin(_ target: Date, start: Date, end: Date) -> Bool {
        target >= start && target <= end
    }
}

// MARK: - CyclePhase display helpers

extension CyclePhase {
    var displayName: String {
        switch self {
        case .menstrual:  return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation:  return "Ovulation"
        case .luteal:     return "Luteal"
        }
    }

    var emoji: String {
        switch self {
        case .menstrual:  return "🌊"
        case .follicular: return "🌱"
        case .ovulation:  return "⚡️"
        case .luteal:     return "🌕"
        }
    }
}
