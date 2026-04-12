import SwiftUI

// MARK: - DashboardView

// MARK: - DashboardView
//
// Main dashboard showing cycle phase, stats, suggested workout, quick actions, and recent wins.
// Matches the web app's dashboard feature parity.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAIWorkout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Welcome Header
                    welcomeHeader

                    // Cycle Phase Banner (if enabled)
                    cyclePhaseBanner

                    // Stat Cards
                    statCards

                    // Divider
                    Divider()
                        .background(AppTheme.Accent.gold.opacity(0.3))

                    // Suggested Workout
                    suggestedWorkoutCard

                    // Coaching Insights (Pro)
                    coachingInsightsCard

                    // Quick Actions
                    quickActionsCard

                    // Recent Wins
                    if !viewModel.recentWins.isEmpty {
                        recentWinsCard
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
                Task { await viewModel.loadData() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .cycleDataUpdated)) { _ in
                Task { await viewModel.loadData() }
            }
            .sheet(isPresented: $showingAIWorkout) {
                AIWorkoutView()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Welcome Back")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Accent.gold)

            Text("Hey, \(userName)")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Text.primary)

            Text(todayDate)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var userName: String {
        if let name = authViewModel.userName, !name.isEmpty {
            return name
        }
        return "Athlete"
    }

    private var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    // MARK: - Cycle Phase Banner

    @ViewBuilder
    private var cyclePhaseBanner: some View {
        if let phase = viewModel.cyclePhase {
            NavigationLink(destination: CycleCalendarView()) {
            ArtDecoCard {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: cyclePhaseIcon(for: phase))
                        .font(.system(size: 24))
                        .foregroundColor(cyclePhaseColor(for: phase))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(cyclePhaseTitle(for: phase))
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(cyclePhaseDescription(for: phase))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    Spacer()

                    // Confidence indicator
                    if let confidence = viewModel.cycleConfidence {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("\(Int(confidence * 100))%")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            Circle()
                                .fill(confidenceColor(for: confidence))
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Phase confidence: \(Int(confidence * 100)) percent")
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cycle phase: \(cyclePhaseTitle(for: phase))")
            .accessibilityHint("Tap to view cycle calendar")
            }
        }
    }

    private func cyclePhaseIcon(for phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sun.max.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        }
    }

    private func cyclePhaseColor(for phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual: return .red
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Text.secondary
        }
    }

    private func cyclePhaseTitle(for phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual Phase"
        case .follicular: return "Follicular Phase"
        case .ovulation: return "Ovulation Phase"
        case .luteal: return "Luteal Phase"
        }
    }

    private func cyclePhaseDescription(for phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Lower energy, focus on recovery"
        case .follicular: return "Rising energy, great for progress"
        case .ovulation: return "Peak strength potential"
        case .luteal: return "Higher energy, but may need more rest"
        }
    }

    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.4 {
            return AppTheme.Accent.gold
        } else {
            return AppTheme.Accent.orange
        }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(
                value: "\(viewModel.workoutsThisWeek)",
                label: "This Week"
            )

            StatCard(
                value: "\(viewModel.prsThisMonth)",
                label: "PRs Month"
            )

            StatCard(
                value: viewModel.activeProgramName ?? "None",
                label: "Program"
            )
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Suggested Workout

    private var suggestedWorkoutCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Suggested Workout")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                if viewModel.canGenerateAIWorkout {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Generate AI Workout")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        Text("Based on your cycle phase and energy level")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary.opacity(0.8))

                        Button("Generate") {
                            showingAIWorkout = true
                        }
                        .artDecoButton(style: .accent)
                        .accessibilityLabel("Generate AI workout")
                        .accessibilityHint("Creates a workout based on your cycle phase")
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Today's Workout")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        if let nextWorkout = viewModel.nextWorkout {
                            Text(nextWorkout)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            NavigationLink("Start Workout", destination: Text("Workout Detail"))
                                .artDecoButton(style: .primary)
                        } else {
                            Text("No workout scheduled")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                    .artDecoButton(style: .accent)
                    .accessibilityLabel("Generate AI workout")
                    .accessibilityHint("Creates a workout based on your cycle phase")
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Shortcuts")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.sm) {
                    NavigationLink(destination: MaxesListView()) {
                        quickActionContent("Log Max", icon: "scalemass", isPrimary: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Navigate to log a one-rep max")

                    NavigationLink(destination: PainTrackingView()) {
                        quickActionContent("Pain Log", icon: "bandage", isPrimary: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Navigate to pain tracking")

                    NavigationLink(destination: BenchmarksListView()) {
                        quickActionContent("Benchmarks", icon: "trophy", isPrimary: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Navigate to benchmarks")
                }
            }
        }
    }

    private func quickActionContent(_ title: String, icon: String, isPrimary: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))

            Text(title)
                .font(AppTheme.Typography.labelMedium)
        }
        .foregroundColor(isPrimary ? AppTheme.Text.cream : AppTheme.Text.primary)
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(isPrimary ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    // MARK: - Coaching Insights (Pro)

    @ViewBuilder
    private var coachingInsightsCard: some View {
        if let summary = viewModel.insightsSummary {
            ArtDecoCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppTheme.Semantic.success)
                            .accessibilityHidden(true)

                        Text("Your Coach")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)
                    }

                    Text(summary)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)

                    if !viewModel.insightsActions.isEmpty {
                        ForEach(viewModel.insightsActions.prefix(2), id: \.self) { action in
                            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Accent.gold)
                                    .accessibilityHidden(true)

                                Text(action)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.primary)
                            }
                        }
                    }

                    NavigationLink(destination: InsightsView()) {
                        Text("View All Insights")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Semantic.success)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Semantic.success.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    .accessibilityHint("View detailed training insights")
                }
            }
        }
    }

    // MARK: - Recent Wins

    private var recentWinsCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Recent Wins")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(viewModel.recentWins.prefix(3), id: \.self) { win in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityHidden(true)

                        Text(win)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - DashboardViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var cyclePhase: CyclePhase?
    @Published var cycleConfidence: Double?
    @Published var workoutsThisWeek: Int = 0
    @Published var prsThisMonth: Int = 0
    @Published var activeProgramName: String?
    @Published var nextWorkout: String?
    @Published var canGenerateAIWorkout: Bool = false
    @Published var isGeneratingWorkout: Bool = false
    @Published var recentWins: [String] = []
    @Published var insightsSummary: String?
    @Published var insightsActions: [String] = []

    // MARK: - Dependencies

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol
    private var hasRequestedHealthAuth = false

    // MARK: - Initialization

    init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        if !hasRequestedHealthAuth {
            hasRequestedHealthAuth = true
            if healthClient.isAvailable {
                try? await healthClient.requestStandardAuthorization()
            }
        }

        await loadCyclePhase()
        await loadStats()
        await loadProgramInfo()
        canGenerateAIWorkout = true
        await loadCoachingInsights()
        await loadRecentWins()

        isLoading = false
    }

    /// Generates an AI workout based on cycle phase and energy
    func generateAIWorkout() async {
        isGeneratingWorkout = true

        // Simulate AI generation
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isGeneratingWorkout = false

        // In real implementation, this would call the AI service
        // and navigate to the generated workout
    }

    // MARK: - Private Methods

    private func loadCyclePhase() async {
        var periodLogs: [PeriodLog] = []

        // Load HealthKit cycles if available
        do {
            if healthClient.isAvailable {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo,
                    endDate: nil,
                    limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            }
        } catch {
            // No HealthKit data
        }

        // Always merge manual period logs
        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
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

        guard !periodLogs.isEmpty else { return }

        var settings = CycleSettings()
        if let settingsRecords = try? await dataClient.fetchAll(
            recordType: "CycleSettings"
        ) as [CycleSettingsRecord], let first = settingsRecords.first {
            settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
        }

        if let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) {
            cyclePhase = status.currentPhase
            cycleConfidence = CyclePhaseHelper.calculateConfidence(
                periodLogCount: periodLogs.count,
                lastPeriodStart: periodLogs.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
            )
        }
    }

    private func loadStats() async {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start

        if healthClient.isAvailable {
            do {
                let workouts = try await healthClient.fetchWorkouts(startDate: nil, endDate: nil, limit: 30)
                if let weekStart {
                    workoutsThisWeek = workouts.filter { $0.startDate >= weekStart }.count
                }
            } catch {
                // HealthKit not authorized or query failed
            }
        }

        if workoutsThisWeek == 0 {
            do {
                let workouts = try await dataClient.fetchAll(recordType: "Workout") as [Workout]
                if let weekStart {
                    workoutsThisWeek = workouts.filter { $0.completedAt != nil && $0.completedAt! >= weekStart }.count
                }
            } catch {
                // CloudKit unavailable — leave at default 0
            }
        }

        do {
            let prs = try await dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            ) as [OneRepMaxRecord]

            let monthStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            prsThisMonth = prs.filter { pr in
                pr.date >= monthStart
            }.count
        } catch {
            // CloudKit unavailable — leave prsThisMonth at default 0
        }
    }

    private func loadProgramInfo() async {
        do {
            let programs = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]

            if let program = programs.first, program.isActive {
                activeProgramName = program.name
                nextWorkout = "Day \(programs.count + 1)" // Simplified
            }
        } catch {
            // CloudKit unavailable — leave program info at defaults
        }
    }

    private func loadCoachingInsights() async {
        let coachService = CoachServiceFactory.makeService()
        let contextBuilder = CoachContextBuilder(
            healthClient: healthClient,
            dataClient: dataClient
        )
        let context = await contextBuilder.build()
        do {
            let insights = try await coachService.getInsights(context: context)
            insightsSummary = insights.summary
            insightsActions = insights.priorityActions
        } catch {
            // Coaching insights are non-critical — degrade gracefully
        }
    }

    private func loadRecentWins() async {
        do {
            let wins = try await dataClient.fetchAll(
                recordType: "CelebrationEventRecord"
            ) as [CelebrationEventRecord]

            recentWins = wins.map { win in
                String(win.description.prefix(50))
            }
        } catch {
            // Recent wins are non-critical — degrade gracefully
        }
    }
}
