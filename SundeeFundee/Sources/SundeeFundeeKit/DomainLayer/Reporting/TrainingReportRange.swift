import Foundation

// MARK: - TrainingReportRange

/// The window a training report covers.
///
/// A fixed set of choices rather than an open date picker: this release ships
/// one report type, and three well-understood windows keep the share flow to a
/// single tap for the common case.
public enum TrainingReportRange: String, CaseIterable, Sendable, Identifiable {
    case last30Days
    case last90Days
    case lastYear

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .last30Days: return "Last 30 days"
        case .last90Days: return "Last 90 days"
        case .lastYear: return "Last year"
        }
    }

    public var days: Int {
        switch self {
        case .last30Days: return 30
        case .last90Days: return 90
        case .lastYear: return 365
        }
    }

    /// The equivalent analytics window, so cycle correlation is computed over
    /// the same span the report claims to cover.
    public var chartTimeRange: TimeRange {
        switch self {
        case .last30Days: return .lastMonth
        case .last90Days: return .lastThreeMonths
        case .lastYear: return .lastYear
        }
    }

    /// The half-open interval this range covers, ending at the start of
    /// tomorrow so sessions logged today are included.
    public func interval(
        endingAt referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let end = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end
        return (start, end)
    }
}
