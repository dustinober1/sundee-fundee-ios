import Foundation

enum CyclePhaseCalculator {
    /// Returns the current cycle phase and day number given the last period start date and cycle settings.
    static func currentPhase(
        lastPeriodStart: Date,
        cycleLength: Int,
        periodLength: Int,
        lutealPhaseLength: Int,
        referenceDate: Date = .now
    ) -> (phase: CyclePhase, dayOfCycle: Int) {
        let calendar = Calendar.current
        let dayOfCycle = calendar.dateComponents([.day], from: lastPeriodStart, to: referenceDate).day.map { $0 + 1 } ?? 1
        let normalised = ((dayOfCycle - 1) % max(cycleLength, 1)) + 1

        let follicularEnd = periodLength
        let ovulationEnd = cycleLength - lutealPhaseLength + 1

        let phase: CyclePhase
        switch normalised {
        case 1...follicularEnd:
            phase = .menstrual
        case (follicularEnd + 1)...(ovulationEnd - 1):
            phase = .follicular
        case ovulationEnd:
            phase = .ovulation
        default:
            phase = .luteal
        }

        return (phase, normalised)
    }

    /// Human-readable description of a cycle phase.
    static func phaseDescription(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:  return "Menstrual Phase — Focus on recovery and lighter movement."
        case .follicular: return "Follicular Phase — Energy rising; great for strength training."
        case .ovulation:  return "Ovulation Phase — Peak energy and power output."
        case .luteal:     return "Luteal Phase — Prioritise consistency and listen to your body."
        }
    }

    /// SF Symbol name for a cycle phase.
    static func phaseIcon(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:  return "drop.fill"
        case .follicular: return "leaf.fill"
        case .ovulation:  return "sun.max.fill"
        case .luteal:     return "moon.fill"
        }
    }

    /// Brand color asset name for a cycle phase (use with `Color(name)`).
    static func phaseColorName(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:  return "BrandDanger"
        case .follicular: return "BrandGold"
        case .ovulation:  return "BrandOrange"
        case .luteal:     return "BrandNavy"
        }
    }
}
