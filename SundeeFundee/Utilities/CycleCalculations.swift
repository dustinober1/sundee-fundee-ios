import Foundation

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

struct PhasePerformance {
    let phase: CyclePhase
    let avgPerformanceDelta: Double
    let sampleSize: Int
}

struct PhaseStrengthProfile {
    let userId: String
    let phases: [PhasePerformance]
    let strongestPhase: CyclePhase
    let weakestPhase: CyclePhase
    let confidence: Double
}

struct StrengthWindow {
    let startDate: Date
    let endDate: Date
    let confidence: Double
}

enum CycleCalculations {
    /// Calculate current cycle status based on period logs and settings.
    static func calculateCycleStatus(
        periodLogs: [PeriodLog],
        settings: CycleSettings,
        referenceDate: Date = .now
    ) -> CycleStatusResult? {
        guard !periodLogs.isEmpty else { return nil }

        let sortedPeriods = periodLogs.sorted { $0.startDate > $1.startDate }
        var cycleStartDate: Date?

        for period in sortedPeriods {
            let periodStart = period.startDate
            let periodEnd = period.endDate ?? Calendar.current.date(
                byAdding: .day,
                value: settings.averagePeriodLength - 1,
                to: period.startDate
            )!

            if referenceDate >= periodStart && referenceDate <= periodEnd {
                cycleStartDate = periodStart
                break
            }

            let nextExpected = Calendar.current.date(
                byAdding: .day,
                value: settings.averageCycleLength,
                to: periodStart
            )!
            if referenceDate > periodEnd && referenceDate < nextExpected {
                cycleStartDate = periodStart
                break
            }
        }

        if cycleStartDate == nil {
            let mostRecent = sortedPeriods[0]
            var start = mostRecent.startDate
            let daysSince = Calendar.current.dateComponents([.day], from: start, to: referenceDate).day ?? 0
            let completedCycles = daysSince / settings.averageCycleLength
            start = Calendar.current.date(
                byAdding: .day,
                value: completedCycles * settings.averageCycleLength,
                to: start
            )!
            cycleStartDate = start
        }

        guard let startDate = cycleStartDate else { return nil }

        let cycleDay = (Calendar.current.dateComponents([.day], from: startDate, to: referenceDate).day ?? 0) + 1
        let boundaries = getPhaseBoundaries(settings: settings)

        var currentPhase: CyclePhase = .follicular
        var phaseStartDay = 1
        var phaseEndDay = settings.averageCycleLength

        for phase in CyclePhase.allCases {
            if let bounds = boundaries[phase], cycleDay >= bounds.start && cycleDay <= bounds.end {
                currentPhase = phase
                phaseStartDay = bounds.start
                phaseEndDay = bounds.end
                break
            }
        }

        let daysUntilNextPhase: Int
        switch currentPhase {
        case .menstrual:
            daysUntilNextPhase = (boundaries[.follicular]?.start ?? 6) - cycleDay
        case .follicular:
            daysUntilNextPhase = (boundaries[.ovulation]?.start ?? 13) - cycleDay
        case .ovulation:
            daysUntilNextPhase = (boundaries[.luteal]?.start ?? 16) - cycleDay
        case .luteal:
            daysUntilNextPhase = settings.averageCycleLength - cycleDay + 1
        }

        let phaseStart = Calendar.current.date(byAdding: .day, value: phaseStartDay - 1, to: startDate)!
        let phaseEnd = Calendar.current.date(byAdding: .day, value: phaseEndDay - 1, to: startDate)!
        let predictedNext = Calendar.current.date(byAdding: .day, value: settings.averageCycleLength, to: startDate)!

        return CycleStatusResult(
            currentPhase: currentPhase,
            cycleDay: cycleDay,
            daysUntilNextPhase: daysUntilNextPhase,
            predictedNextPeriod: predictedNext,
            phaseStartDate: phaseStart,
            phaseEndDate: phaseEnd
        )
    }

    /// Get phase boundaries based on cycle settings.
    static func getPhaseBoundaries(settings: CycleSettings) -> [CyclePhase: PhaseBoundary] {
        let cycleLength = settings.averageCycleLength
        let periodLength = settings.averagePeriodLength
        let lutealLength = settings.lutealPhaseLength

        let ovulationDay = cycleLength - lutealLength
        let ovulationStart = max(periodLength + 2, ovulationDay - 2)
        let ovulationEnd = min(ovulationDay + 2, cycleLength - lutealLength + 2)

        return [
            .menstrual: PhaseBoundary(start: 1, end: periodLength),
            .follicular: PhaseBoundary(start: periodLength + 1, end: ovulationStart - 1),
            .ovulation: PhaseBoundary(start: ovulationStart, end: ovulationEnd),
            .luteal: PhaseBoundary(start: ovulationEnd + 1, end: cycleLength),
        ]
    }

    /// Get phase-based training recommendations.
    static func getPhaseRecommendation(phase: CyclePhase) -> PhaseRecommendation {
        switch phase {
        case .menstrual:
            return PhaseRecommendation(
                phase: .menstrual,
                title: "Menstrual Phase",
                description: "Your period phase. Energy may be lower, and you might feel more fatigued.",
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
}
