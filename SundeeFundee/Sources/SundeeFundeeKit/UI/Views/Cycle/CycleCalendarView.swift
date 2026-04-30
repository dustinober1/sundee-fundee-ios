import SwiftUI

// MARK: - CycleCalendarView
//
// Month calendar with cycle phase overlays.
// Uses getCycleCalendarData() from the domain layer.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CycleCalendarView: View {
    @StateObject private var viewModel = CycleCalendarViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Month Navigation
                monthNavigation

                // Day-of-week Headers
                dayOfWeekHeaders

                // Calendar Grid
                calendarGrid

                // Phase Legend
                phaseLegend

                // Current Phase Detail
                if let status = viewModel.currentStatus {
                    phaseDetailCard(status)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Cycle Calendar")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadCalendarData()
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cycleDataUpdated)) { _ in
            Task { await viewModel.loadData() }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                viewModel.previousMonth()
                Task { await viewModel.loadCalendarData() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.Text.primary)
            }
            .accessibilityLabel("Previous Month")

            Spacer()

            Text(viewModel.monthTitle)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)

            Spacer()

            Button {
                viewModel.nextMonth()
                Task { await viewModel.loadCalendarData() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.Text.primary)
            }
            .accessibilityLabel("Next Month")
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Day of Week Headers

    private var dayOfWeekHeaders: some View {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        return LazyVGrid(columns: columns, spacing: 2) {
            // Leading empty cells for the first week offset
            ForEach(0..<viewModel.firstDayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 48)
            }

            // Day cells
            ForEach(viewModel.calendarDays, id: \.date) { dayData in
                dayCellView(dayData)
            }
        }
    }

    private func dayCellView(_ dayData: CalendarDayData) -> some View {
        let dayNumber = Calendar.current.component(.day, from: dayData.date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let monthName = dateFormatter.string(from: dayData.date)
        let phaseName = dayData.phase.map { phaseLabel($0) } ?? ""

        return VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(dayData.isToday ? AppTheme.Typography.headlineSmall : AppTheme.Typography.bodySmall)
                .foregroundColor(dayData.isToday ? .white : AppTheme.Text.primary)
                .frame(width: 28, height: 28)
                .background(
                    dayData.isToday
                        ? AnyShapeStyle(AppTheme.Background.navy)
                        : AnyShapeStyle(phaseBackgroundColor(dayData.phase))
                )
                .clipShape(Circle())

            // Period indicator dot
            if dayData.isPeriodLogged {
                Circle()
                    .fill(AppTheme.Accent.orange)
                    .frame(width: 5, height: 5)
            } else {
                Color.clear.frame(width: 5, height: 5)
            }

            // Cycle day number
            if let cycleDay = dayData.cycleDay {
                Text("\(cycleDay)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary.opacity(0.6))
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .frame(height: 48)
        .accessibilityLabel({
            var parts = ["\(dayNumber), \(monthName)"]
            if !phaseName.isEmpty { parts.append(phaseName) }
            if let cycleDay = dayData.cycleDay { parts.append("cycle day \(cycleDay)") }
            if dayData.isPeriodLogged { parts.append("period logged") }
            return parts.joined(separator: ", ")
        }())
    }

    // MARK: - Phase Legend

    private var phaseLegend: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Phases")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                HStack(spacing: AppTheme.Spacing.lg) {
                    legendItem(.menstrual, "Menstrual")
                    legendItem(.follicular, "Follicular")
                    legendItem(.ovulation, "Ovulation")
                    legendItem(.luteal, "Luteal")
                }
            }
        }
    }

    private func legendItem(_ phase: CyclePhase, _ label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(phaseColor(phase))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.primary)
        }
        .accessibilityLabel("\(label) phase")
    }

    // MARK: - Phase Detail Card

    private func phaseDetailCard(_ status: CycleStatusResult) -> some View {
        let rec = getPhaseRecommendation(phase: status.currentPhase)

        return ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Image(systemName: phaseIcon(status.currentPhase))
                        .font(.title3)
                        .foregroundColor(phaseColor(status.currentPhase))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(rec.title)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text("Day \(status.cycleDay) \u{2022} \(status.daysUntilNextPhase) days until next phase")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    Spacer()
                }

                Text(rec.description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)

                Divider()
                    .background(AppTheme.Accent.gold.opacity(0.3))

                // Training Focus
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Training Focus")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)

                    Text(rec.trainingFocus)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }

                // Adjustment Summary
                Text(getPhaseAdjustmentSummary(status.currentPhase))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .italic()

                // Next Period
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Text.secondary)
                        .accessibilityHidden(true)
                    Text("Next period: \(status.predictedNextPeriod, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
        }
    }

    // MARK: - Phase Colors

    private func phaseBackgroundColor(_ phase: CyclePhase?) -> Color {
        guard let phase else { return .clear }
        switch phase {
        case .menstrual: return AppTheme.Accent.orange.opacity(0.15)
        case .follicular: return AppTheme.Accent.gold.opacity(0.15)
        case .ovulation: return AppTheme.Accent.orange.opacity(0.15)
        case .luteal: return AppTheme.Text.secondary.opacity(0.1)
        }
    }

    private func phaseColor(_ phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual: return .red
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Text.secondary
        }
    }

    private func phaseIcon(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sun.max.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        }
    }

    private func phaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}

// MARK: - CycleCalendarViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class CycleCalendarViewModel: ObservableObject {
    @Published var calendarDays: [CalendarDayData] = []
    @Published var currentStatus: CycleStatusResult?
    @Published var currentMonth: Int
    @Published var currentYear: Int
    @Published var firstDayOffset: Int = 0

    private var periodLogs: [PeriodLog] = []
    private var settings: CycleSettings = CycleSettings()
    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient

        let now = Date()
        let cal = Calendar.current
        self.currentMonth = cal.component(.month, from: now)
        self.currentYear = cal.component(.year, from: now)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = Calendar.current.date(from: DateComponents(year: currentYear, month: currentMonth))!
        return formatter.string(from: date)
    }

    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }

    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }

    func loadData() async {
        await loadCalendarData()

        // Load cycle settings
        do {
            let records = try await dataClient.fetchAll(
                recordType: "CycleSettings"
            ) as [CycleSettingsRecord]
            if let record = records.first {
                settings = CycleSettings(
                    averageCycleLengthDays: record.averageCycleLengthDays
                )
            }
        } catch {
            // Use defaults
        }

        // Reset period logs before loading
        periodLogs = []

        // Load period logs from HealthKit
        do {
            if healthClient.isAvailable {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo, endDate: nil, limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            }
        } catch {
            // No HealthKit data
        }

        // Merge manual period logs
        var hasActivePeriod = false
        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            if manualRecords.contains(where: { $0.isActive }) {
                hasActivePeriod = true
            }
            let manualLogs = manualRecords.map { $0.toPeriodLog() }
            for log in manualLogs {
                let isDuplicate = periodLogs.contains { existing in
                    abs(existing.startDate.timeIntervalSince(log.startDate)) < 86400
                }
                if !isDuplicate {
                    periodLogs.append(log)
                }
            }
        } catch {
            // No manual logs
        }

        // Calculate current status
        if hasActivePeriod, let activePeriodLog = periodLogs.first(where: { $0.endDate == nil }) {
            // Active period: force menstrual status
            let cycleDay = Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: activePeriodLog.startDate),
                to: Calendar.current.startOfDay(for: Date())
            ).day.map { $0 + 1 } ?? 1

            let boundaries = getPhaseBoundaries(settings: settings)
            currentStatus = CycleStatusResult(
                currentPhase: .menstrual,
                cycleDay: cycleDay,
                daysUntilNextPhase: max(0, (boundaries[.follicular]?.start ?? cycleDay) - cycleDay),
                predictedNextPeriod: Calendar.current.date(byAdding: .day, value: settings.averageCycleLengthDays, to: activePeriodLog.startDate) ?? Date(),
                phaseStartDate: activePeriodLog.startDate,
                phaseEndDate: Calendar.current.date(byAdding: .day, value: settings.averagePeriodLengthDays - 1, to: activePeriodLog.startDate) ?? Date()
            )
        } else {
            currentStatus = calculateCycleStatus(
                periodLogs: periodLogs,
                settings: settings
            )
        }

        await loadCalendarData()
    }

    func loadCalendarData() async {
        calendarDays = getCycleCalendarData(
            periodLogs: periodLogs,
            settings: settings,
            month: currentMonth,
            year: currentYear
        )

        // Calculate first day offset (what weekday the 1st falls on)
        let cal = Calendar.current
        if let firstOfMonth = cal.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) {
            firstDayOffset = cal.component(.weekday, from: firstOfMonth) - 1 // Sunday = 0
        }
    }
}
