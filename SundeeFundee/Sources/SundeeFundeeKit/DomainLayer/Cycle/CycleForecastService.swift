import Foundation

// MARK: - ForecastEnergyTier

/// Projected energy and capacity tier for forward planning.
public enum ForecastEnergyTier: String, Sendable, Codable {
    case recovering
    case moderate
    case peak
    case steady

    public var displayName: String {
        switch self {
        case .recovering: return "Recovery Focus"
        case .moderate:   return "Steady Building"
        case .peak:       return "Peak Capacity"
        case .steady:     return "Consistent Baseline"
        }
    }
}

// MARK: - CycleDayForecast

/// Projected cycle status and training recommendations for an upcoming day.
public struct CycleDayForecast: Sendable, Identifiable, Equatable {
    public var id: String {
        "\(dayOffset)_\(Int(date.timeIntervalSince1970))"
    }

    public let date: Date
    public let dayOffset: Int
    public let dayOfWeek: String
    public let dayOfMonth: Int
    public let phase: CyclePhase?
    public let cycleDay: Int?
    public let energyTier: ForecastEnergyTier
    public let headline: String
    public let summary: String
    public let trainingFocus: String
    public let suggestedIntensity: String
    public let mode: CycleTrackingMode
    public let isToday: Bool

    public init(
        date: Date,
        dayOffset: Int,
        dayOfWeek: String,
        dayOfMonth: Int,
        phase: CyclePhase?,
        cycleDay: Int?,
        energyTier: ForecastEnergyTier,
        headline: String,
        summary: String,
        trainingFocus: String,
        suggestedIntensity: String,
        mode: CycleTrackingMode,
        isToday: Bool
    ) {
        self.date = date
        self.dayOffset = dayOffset
        self.dayOfWeek = dayOfWeek
        self.dayOfMonth = dayOfMonth
        self.phase = phase
        self.cycleDay = cycleDay
        self.energyTier = energyTier
        self.headline = headline
        self.summary = summary
        self.trainingFocus = trainingFocus
        self.suggestedIntensity = suggestedIntensity
        self.mode = mode
        self.isToday = isToday
    }
}

// MARK: - CycleForecastService

/// Pure domain service that generates a forward-looking 7-day training forecast
/// adapting to the user's specific cycle tracking mode and period history.
public struct CycleForecastService: Sendable {

    /// Generates a 7-day forecast starting from referenceDate.
    ///
    /// - Parameters:
    ///   - periodLogs: User's historical and active period logs.
    ///   - settings: User's cycle settings.
    ///   - mode: User's tracking mode (standard, contraceptive, irregular, perimenopause).
    ///   - referenceDate: Anchor date (typically today).
    ///   - calendar: Calendar to use for date math.
    /// - Returns: An array of exactly 7 `CycleDayForecast` values.
    public static func generateSevenDayForecast(
        periodLogs: [PeriodLog],
        settings: CycleSettings,
        mode: CycleTrackingMode = .standard,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [CycleDayForecast] {
        let anchor = calendar.startOfDay(for: referenceDate)
        var forecasts: [CycleDayForecast] = []

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for offset in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: offset, to: anchor) ?? anchor
            let dayOfWeek = dayFormatter.string(from: targetDate)
            let dayOfMonth = calendar.component(.day, from: targetDate)
            let isToday = (offset == 0)

            let forecast = projectDay(
                targetDate: targetDate,
                dayOffset: offset,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                isToday: isToday,
                periodLogs: periodLogs,
                settings: settings,
                mode: mode,
                calendar: calendar
            )
            forecasts.append(forecast)
        }

        return forecasts
    }

    // MARK: - Private Helpers

    private static func projectDay(
        targetDate: Date,
        dayOffset: Int,
        dayOfWeek: String,
        dayOfMonth: Int,
        isToday: Bool,
        periodLogs: [PeriodLog],
        settings: CycleSettings,
        mode: CycleTrackingMode,
        calendar: Calendar
    ) -> CycleDayForecast {
        let status = calculateCycleStatus(
            periodLogs: periodLogs,
            settings: settings,
            referenceDate: targetDate
        )

        // Check if an active period log covers this day
        let isPeriodActiveOnTarget = periodLogs.contains { log in
            let start = calendar.startOfDay(for: log.startDate)
            let end = log.endDate.map { calendar.startOfDay(for: $0) }
                ?? calendar.date(byAdding: .day, value: settings.averagePeriodLengthDays - 1, to: start)
                ?? start
            return targetDate >= start && targetDate <= end
        }

        switch mode {
        case .contraceptive:
            // Contraceptive suppresses natural ovulation.
            if isPeriodActiveOnTarget || status?.currentPhase == .menstrual {
                return CycleDayForecast(
                    date: targetDate,
                    dayOffset: dayOffset,
                    dayOfWeek: dayOfWeek,
                    dayOfMonth: dayOfMonth,
                    phase: .menstrual,
                    cycleDay: status?.cycleDay ?? (dayOffset + 1),
                    energyTier: .recovering,
                    headline: "Withdrawal Bleed · Reset",
                    summary: "Scheduled withdrawal bleed. Maintain lighter active movement and respect daily comfort.",
                    trainingFocus: "Mobility, lighter compound technique, and generous rest intervals.",
                    suggestedIntensity: "Low - Moderate",
                    mode: mode,
                    isToday: isToday
                )
            } else {
                return CycleDayForecast(
                    date: targetDate,
                    dayOffset: dayOffset,
                    dayOfWeek: dayOfWeek,
                    dayOfMonth: dayOfMonth,
                    phase: nil,
                    cycleDay: nil,
                    energyTier: .steady,
                    headline: "Steady Baseline",
                    summary: "Hormone levels remain stable. Autoregulate training using sleep, resting heart rate, and RPE.",
                    trainingFocus: "Progressive overload, high volume, and consistent pacing.",
                    suggestedIntensity: "Autoregulated",
                    mode: mode,
                    isToday: isToday
                )
            }

        case .irregular:
            let cycleDay = status?.cycleDay ?? (dayOffset + 1)
            let phase = status?.currentPhase ?? .follicular

            if cycleDay > 38 {
                return CycleDayForecast(
                    date: targetDate,
                    dayOffset: dayOffset,
                    dayOfWeek: dayOfWeek,
                    dayOfMonth: dayOfMonth,
                    phase: nil,
                    cycleDay: cycleDay,
                    energyTier: .steady,
                    headline: "Extended Cycle · Day \(cycleDay)",
                    summary: "Cycle length is extended. Phase predictions widen; train based on morning readiness and RPE.",
                    trainingFocus: "Autoregulated sets and listening to neuromuscular feedback.",
                    suggestedIntensity: "By Feel",
                    mode: mode,
                    isToday: isToday
                )
            } else {
                let energy = energyTier(for: phase)
                let rec = getPhaseRecommendation(phase: phase, style: .physiological)
                return CycleDayForecast(
                    date: targetDate,
                    dayOffset: dayOffset,
                    dayOfWeek: dayOfWeek,
                    dayOfMonth: dayOfMonth,
                    phase: phase,
                    cycleDay: cycleDay,
                    energyTier: energy,
                    headline: "\(rec.title) (Estimated)",
                    summary: rec.description,
                    trainingFocus: rec.trainingFocus,
                    suggestedIntensity: rec.intensityRecommendation.capitalized,
                    mode: mode,
                    isToday: isToday
                )
            }

        case .perimenopause:
            let cycleDay = status?.cycleDay ?? (dayOffset + 1)
            let phase = status?.currentPhase ?? .follicular
            let energy = energyTier(for: phase)
            let rec = getPhaseRecommendation(phase: phase, style: .physiological)

            return CycleDayForecast(
                date: targetDate,
                dayOffset: dayOffset,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                phase: phase,
                cycleDay: cycleDay,
                energyTier: energy,
                headline: "Perimenopause · \(rec.title)",
                summary: "Hormonal shifts may influence sleep or joint sensitivity. Prioritize warmups and tendon prep.",
                trainingFocus: "Extended dynamic warmup, controlled eccentric tempos, and recovery-first pacing.",
                suggestedIntensity: "Autoregulated",
                mode: mode,
                isToday: isToday
            )

        case .standard:
            let cycleDay = status?.cycleDay ?? (dayOffset + 1)
            let phase = status?.currentPhase ?? .follicular
            let energy = energyTier(for: phase)
            let rec = getPhaseRecommendation(phase: phase, style: .physiological)

            return CycleDayForecast(
                date: targetDate,
                dayOffset: dayOffset,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                phase: phase,
                cycleDay: cycleDay,
                energyTier: energy,
                headline: rec.title,
                summary: rec.description,
                trainingFocus: rec.trainingFocus,
                suggestedIntensity: rec.intensityRecommendation.capitalized,
                mode: mode,
                isToday: isToday
            )
        }
    }

    private static func energyTier(for phase: CyclePhase) -> ForecastEnergyTier {
        switch phase {
        case .menstrual:  return .recovering
        case .follicular: return .moderate
        case .ovulation:  return .peak
        case .luteal:     return .moderate
        }
    }
}
