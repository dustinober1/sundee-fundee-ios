import Foundation

@MainActor
@Observable
final class WODsViewModel {
    var allWODs: [WOD] = []
    var isLoading = false

    private let wodRepo: any WODRepository

    init(wodRepo: any WODRepository = CloudKitWODRepository()) {
        self.wodRepo = wodRepo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        allWODs = (try? await wodRepo.fetchWODs()) ?? []
    }

    // MARK: - Static helpers (testable)

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt
    }()

    /// Returns WODs within ±dayRange of the reference date, sorted ascending by date.
    static func wodsInRange(
        from wods: [WOD],
        around referenceDate: Date = .now,
        dayRange: Int = 5
    ) -> [WOD] {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -dayRange, to: referenceDate),
              let end = calendar.date(byAdding: .day, value: dayRange, to: referenceDate) else {
            return []
        }
        let startString = dateFormatter.string(from: start)
        let endString = dateFormatter.string(from: end)

        return wods
            .filter { $0.date >= startString && $0.date <= endString }
            .sorted { $0.date < $1.date }
    }

    /// Returns a display-friendly date from a "yyyy-MM-dd" string.
    static func displayDate(from dateString: String, referenceDate: Date = .now) -> String {
        let todayString = dateFormatter.string(from: referenceDate)
        if dateString == todayString { return "Today" }

        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
           dateString == dateFormatter.string(from: yesterday) {
            return "Yesterday"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate),
           dateString == dateFormatter.string(from: tomorrow) {
            return "Tomorrow"
        }

        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "EEE, MMM d"
        return displayFmt.string(from: date)
    }

    /// Whether a WOD date is today.
    static func isToday(_ dateString: String, referenceDate: Date = .now) -> Bool {
        dateString == dateFormatter.string(from: referenceDate)
    }
}
