import SwiftUI
import os.log

private let dashLogger = Logger(subsystem: "com.sundeefundee.app", category: "Dashboard")

// MARK: - DashboardView

// MARK: - DashboardView
//
// Today screen showing cycle phase, stats, suggested workout, quick actions, and recent wins.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cyclePhaseCache: CyclePhaseCache
    @State private var showingAIWorkout = false
    @State private var starterWorkout: Workout?
    @State private var resumeWorkoutID: String?
    @State private var showingRecoveryOverview = false
    @State private var showingCycleTracking = false
    #if canImport(UIKit)
    @State private var showingCycleShare = false
    #endif

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Welcome Header
                    welcomeHeader

                    if let decision = viewModel.todayTrainingDecision {
                        todayTrainingDecisionCard(decision)
                    }

                    if let todayAction = viewModel.todayAction {
                        todayActionCard(todayAction)
                    }

                    // Recovery Score hidden from Dashboard until the algorithm is reworked.
                    // Domain layer, widget, and intent remain available for future re-enable.

                    // Cycle Phase Banner (if enabled)
                    cyclePhaseBanner

                    // Stat Cards
                    if viewModel.isInitialLoad {
                        SkeletonStatRow()
                    } else {
                        statCards
                    }

                    weeklyPlanCard

                    if viewModel.shouldShowFirstWeekChecklist {
                        firstWeekChecklistCard
                    }

                    if !viewModel.recoveryInputStatuses.isEmpty {
                        recoveryInputChecklistCard
                    }

                    // Empty state for brand-new users (no data anywhere)
                    if viewModel.showsNewUserEmptyState {
                        EmptyStateView(
                            icon: "figure.strengthtraining.traditional",
                            title: "Welcome to Sundee Fundee",
                            subtitle: "Start your first workout to unlock stats, benchmarks, and cycle-aware programming.",
                            actionLabel: "Start First Workout",
                            action: {
                                Task {
                                    starterWorkout = await viewModel.buildStarterWorkout()
                                }
                            },
                            secondaryActionLabel: "Log a Max",
                            secondaryAction: { viewModel.navigateToLogMax = true }
                        )
                    }

                    // Challenge Progress Widget
                    if let challengeData = viewModel.activeChallengeData {
                        challengeProgressCard(challengeData)
                    }

                    // Divider
                    Divider()
                        .background(AppTheme.Accent.gold.opacity(0.3))

                    // Suggested Workout
                    suggestedWorkoutCard

                    // Coaching Insights
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
            .navigationTitle("Today")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Open app settings")
                }
            }
            .task {
                await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
            }
            .refreshable {
                await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
                Task { await viewModel.loadData(cyclePhaseCache: cyclePhaseCache) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .cycleDataUpdated)) { _ in
                Task {
                    await cyclePhaseCache.refresh()
                    await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingAIWorkout) {
                AIWorkoutView()
            }
            #else
            .sheet(isPresented: $showingAIWorkout) {
                AIWorkoutView()
            }
            #endif
            .sheet(item: $starterWorkout) { workout in
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutSessionViewModel(workout: workout)
                )
            }
            .navigationDestination(isPresented: $viewModel.navigateToLogMax) {
                MaxesListView()
            }
            .navigationDestination(isPresented: Binding(
                get: { resumeWorkoutID != nil },
                set: { if !$0 { resumeWorkoutID = nil } }
            )) {
                if let resumeWorkoutID {
                    WorkoutDetailView(workoutId: resumeWorkoutID)
                }
            }
            .navigationDestination(isPresented: $showingRecoveryOverview) {
                RecoveryOverviewView()
            }
            .navigationDestination(isPresented: $showingCycleTracking) {
                CycleTrackingView()
            }
            .navigationDestination(isPresented: $viewModel.navigateToPainTracking) {
                PainTrackingView()
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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    private var todayDate: String {
        Self.dateFormatter.string(from: Date())
    }

    // MARK: - Today Training Decision

    private func todayTrainingDecisionCard(_ decision: TodayTrainingDecision) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: decision.systemImage)
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.gold)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(decision.title)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(decision.subtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                if !decision.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        ForEach(Array(decision.reasons.prefix(3).enumerated()), id: \.offset) { _, reason in
                            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                                Circle()
                                    .fill(AppTheme.Accent.gold.opacity(0.6))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 5)
                                    .accessibilityHidden(true)
                                Text(reason)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if !viewModel.recoveryExplanations.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        ForEach(viewModel.recoveryExplanations.prefix(2)) { explanation in
                            Text(explanation.text)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Button {
                    handleTodayTrainingDecision(decision)
                } label: {
                    Label(decision.primaryActionTitle, systemImage: decision.systemImage)
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .accent)

                Button {
                    Task {
                        starterWorkout = await viewModel.buildQuickWorkout()
                    }
                } label: {
                    Label("Best next 20 min", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .secondary)

                if let deload = viewModel.deloadRecommendation, deload.isRecommended {
                    Button {
                        Task {
                            starterWorkout = await viewModel.buildActiveRecoveryWorkout(
                                cyclePhase: cyclePhaseCache.currentPhase
                            )
                        }
                    } label: {
                        Label("Take an Active Recovery Day", systemImage: "figure.cooldown")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .secondary)

                    Text(deload.reason)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func handleTodayTrainingDecision(_ decision: TodayTrainingDecision) {
        switch decision.kind {
        case .train, .modify:
            Task { starterWorkout = await viewModel.buildStarterWorkout() }
        case .recover:
            Task {
                starterWorkout = await viewModel.buildActiveRecoveryWorkout(
                    cyclePhase: cyclePhaseCache.currentPhase
                )
            }
        }
    }

    // MARK: - Today Action

    private func todayActionCard(_ action: TodayAction) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: action.systemImage)
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.orange)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(action.title)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(action.subtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Button {
                    handleTodayAction(action)
                } label: {
                    Label(primaryActionLabel(for: action.kind), systemImage: action.systemImage)
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .accent)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func primaryActionLabel(for kind: TodayActionKind) -> String {
        switch kind {
        case .resumeWorkout:
            return "Resume Workout"
        case .resumeProgramSession:
            return "Resume Program"
        case .startScheduledWorkout:
            return "Start Workout"
        case .completeFirstWeekChecklist(let checklistKind):
            return checklistKind.actionTitle
        case .logRecovery(let inputKind):
            return inputKind.actionTitle
        case .startFirstWorkout:
            return "Start Workout"
        }
    }

    private func handleTodayAction(_ action: TodayAction) {
        switch action.kind {
        case .resumeWorkout(let workoutID):
            resumeWorkoutID = workoutID
        case .resumeProgramSession, .startScheduledWorkout, .startFirstWorkout:
            Task { starterWorkout = await viewModel.buildStarterWorkout() }
        case .completeFirstWeekChecklist(let kind):
            handleFirstWeekChecklistAction(kind)
        case .logRecovery(let kind):
            handleRecoveryInputAction(kind)
        }
    }

    private func handleFirstWeekChecklistAction(_ kind: FirstWeekChecklistKind) {
        switch kind {
        case .firstWorkout:
            Task { starterWorkout = await viewModel.buildStarterWorkout() }
        case .logMax:
            viewModel.navigateToLogMax = true
        case .weeklySchedule:
            Task { await viewModel.resetWeeklyPlan() }
        }
    }

    private func handleRecoveryInputAction(_ kind: RecoveryInputKind) {
        switch kind {
        case .recentWorkout:
            Task { starterWorkout = await viewModel.buildStarterWorkout() }
        case .painLog:
            showingRecoveryOverview = false
            resumeWorkoutID = nil
            // Pain tracking lives outside the recovery overview, so use the existing quick action.
            viewModel.navigateToPainTracking = true
        case .cyclePhase:
            showingCycleTracking = true
        case .sleep, .hrv:
            showingRecoveryOverview = true
        }
    }

    // MARK: - Cycle Phase Banner

    @ViewBuilder
    private var cyclePhaseBanner: some View {
        if viewModel.cycleTrackingEnabled, let phase = cyclePhaseCache.currentPhase {
            NavigationLink(destination: CycleCalendarView()) {
            ArtDecoCard {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: cyclePhaseIcon(for: phase))
                        .font(.title3)
                        .foregroundColor(cyclePhaseColor(for: phase))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(cyclePhaseTitle(for: phase))
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(cyclePhaseDescription(for: phase))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        if let confidence = cyclePhaseCache.confidence {
                            Text(cycleConfidenceText(confidence))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    // Confidence indicator
                    if let confidence = cyclePhaseCache.confidence {
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
            .accessibilityHint("Tap to view cycle calendar. Long press for share options.")
            #if canImport(UIKit)
            .contextMenu {
                Button {
                    showingCycleShare = true
                } label: {
                    Label("Share insight", systemImage: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showingCycleShare) {
                if let currentPhase = cyclePhaseCache.currentPhase {
                    ShareCardSheet(
                        variant: .cycleInsight(
                            phase: currentPhase,
                            cycleDay: cyclePhaseCache.cycleDay ?? 1,
                            insight: cyclePhaseDescription(for: currentPhase)
                        ),
                        defaultAspect: .story
                    )
                }
            }
            #endif
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
        case .menstrual: return AppTheme.Semantic.error
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
            return AppTheme.Semantic.success
        } else if confidence >= 0.4 {
            return AppTheme.Accent.gold
        } else {
            return AppTheme.Accent.orange
        }
    }

    private func cycleConfidenceText(_ confidence: Double) -> String {
        CycleConfidenceExplainer.explain(confidence: confidence).description
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(
                value: "\(viewModel.workoutsThisWeek)",
                label: "This Week"
            )
            .accessibilityLabel("Workouts this week")
            .accessibilityValue("\(viewModel.workoutsThisWeek)")

            StatCard(
                value: "\(viewModel.prsThisMonth)",
                label: "PRs Month"
            )
            .accessibilityLabel("Personal records this month")
            .accessibilityValue("\(viewModel.prsThisMonth)")

            StatCard(
                value: viewModel.activeProgramName ?? "None",
                label: "Program"
            )
            .accessibilityLabel("Active program")
            .accessibilityValue(viewModel.activeProgramName ?? "none")
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
                        Text("Coach Plan")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        Text("Built around your cycle phase and energy level")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary.opacity(0.8))

                        Button("Build Coach Plan") {
                            showingAIWorkout = true
                        }
                        .artDecoButton(style: .accent)
                        .accessibilityLabel("Build Coach Plan")
                        .accessibilityHint("Creates a workout plan based on your cycle phase")
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

                            NavigationLink("Start This Workout", destination: Text("Workout Detail"))
                                .artDecoButton(style: .primary)
                        } else {
                            Text("No workout scheduled")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                    .artDecoButton(style: .accent)
                    .accessibilityLabel("Today's workout")
                    .accessibilityHint("View today's scheduled workout")
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

                    NavigationLink(destination: ChallengesView()) {
                        quickActionContent("Challenges", icon: "flag.fill", isPrimary: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Navigate to challenges")
                }
            }
        }
    }

    @ViewBuilder
    private var weeklyPlanCard: some View {
        if let progress = viewModel.weeklyPlanProgress {
            ArtDecoCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("This Week")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Text(progress.displayText)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                        Spacer()
                        if let streak = viewModel.weeklyStreak, streak.currentWeeklyStreak > 0 {
                            Text("\(streak.currentWeeklyStreak) wk")
                                .font(AppTheme.Typography.monoMedium)
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }

                    if let weekday = progress.nextWorkoutWeekday {
                        Text("Next: \(weekdayName(weekday))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    HStack {
                        Button {
                            Task { starterWorkout = await viewModel.buildStarterWorkout() }
                        } label: {
                            Label("Start This Workout", systemImage: "figure.strengthtraining.traditional")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .primary)

                        Button {
                            Task { await viewModel.resetWeeklyPlan() }
                        } label: {
                            Label("Edit Plan", systemImage: "calendar")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .secondary)
                    }
                }
            }
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "Soon" }
        return symbols[weekday - 1]
    }

    private var firstWeekChecklistCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("First Week Checklist")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(viewModel.firstWeekChecklist) { item in
                    Button {
                        handleFirstWeekChecklistAction(item.kind)
                    } label: {
                        checklistRow(
                            title: item.title,
                            subtitle: item.isComplete ? "Done" : item.actionTitle,
                            isComplete: item.isComplete
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(item.isComplete)
                }
            }
        }
    }

    private var recoveryInputChecklistCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Recovery Inputs")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Missing inputs explain how to improve your score without blocking today's workout.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(viewModel.recoveryInputStatuses) { item in
                    Button {
                        handleRecoveryInputAction(item.kind)
                    } label: {
                        checklistRow(
                            title: item.title,
                            subtitle: item.displayText,
                            isComplete: item.isAvailable
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(item.isAvailable)
                }
            }
        }
    }

    private func checklistRow(title: String, subtitle: String, isComplete: Bool) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.headline)
                .foregroundColor(isComplete ? AppTheme.Semantic.success : AppTheme.Accent.gold)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private func quickActionContent(_ title: String, icon: String, isPrimary: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.headline)

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
                                    .font(.caption)
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

    // MARK: - Challenge Progress Widget

    private func challengeProgressCard(_ data: (Challenge, ChallengeProgress)) -> some View {
        let (challenge, progress) = data
        return NavigationLink(destination: ChallengesView()) {
            ArtDecoCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                        Text(challenge.title)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)
                        Spacer()
                        Text(progress.currentTierName)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.Background.navy.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.Accent.gold)
                                .frame(width: geo.size.width * progress.percentComplete, height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(Int(progress.percentComplete * 100))%")
                            .font(AppTheme.Typography.monoMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                        Spacer()
                        let remaining = progress.volumeRemaining
                        if remaining >= 1_000 {
                            Text("\(String(format: "%.0fK", remaining / 1_000)) lbs to go")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        } else {
                            Text("\(Int(remaining)) lbs to go")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DashboardViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var isInitialLoad: Bool = true
    @Published var navigateToLogMax: Bool = false
    @Published var errorMessage: String?

    @Published var workoutsThisWeek: Int = 0
    @Published var prsThisMonth: Int = 0
    @Published var activeProgramName: String?
    @Published var nextWorkout: String?
    @Published var canGenerateAIWorkout: Bool = false
    @Published var isGeneratingWorkout: Bool = false
    @Published var recentWins: [String] = []
    @Published var insightsSummary: String?
    @Published var insightsActions: [String] = []
    @Published var activeChallengeData: (Challenge, ChallengeProgress)?
    @Published var weeklyPlanProgress: WeeklyPlanProgress?
    @Published var weeklyStreak: WeeklyStreak?
    @Published var cycleTrackingEnabled: Bool = false
    @Published var todayAction: TodayAction?
    @Published var firstWeekChecklist: [FirstWeekChecklistItem] = []
    @Published var recoveryInputStatuses: [RecoveryInputStatus] = []
    @Published var navigateToPainTracking: Bool = false
    @Published var todayTrainingDecision: TodayTrainingDecision?
    @Published var recoveryExplanations: [RecoveryExplanation] = []
    @Published var deloadRecommendation: DeloadRecommendation?

    // MARK: - Dependencies

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol
    private var hasRequestedHealthAuth = false
    private var hasTrackedFirstWorkoutPrompt = false

    // MARK: - Initialization

    init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    var showsNewUserEmptyState: Bool {
        !isInitialLoad
            && workoutsThisWeek == 0
            && prsThisMonth == 0
            && activeProgramName == nil
            && recentWins.isEmpty
    }

    // MARK: - Public Methods

    func loadData(cyclePhaseCache: CyclePhaseCache) async {
        isLoading = true
        errorMessage = nil
        let settings = await loadUserSettings()
        cycleTrackingEnabled = settings.cycleTrackingEnabled

        if !hasRequestedHealthAuth {
            hasRequestedHealthAuth = true
            if healthClient.isAvailable {
                try? await healthClient.requestStandardAuthorization()
            }
        }

        // Tier 1: Load critical data in parallel
        async let statsTask: Void = loadStats()
        async let programTask: Void = loadProgramInfo()
        async let winsTask: Void = loadRecentWins()
        async let cycleTask: Void = cyclePhaseCache.refreshIfNeeded()
        _ = await (statsTask, programTask, winsTask, cycleTask)

        canGenerateAIWorkout = true
        isLoading = false
        isInitialLoad = false

        // Tier 2: Non-critical data loads after UI is visible
        await loadCoachingInsights()
        await loadActiveChallenge()
        await loadWeeklyPlan(cyclePhase: cyclePhaseCache.currentPhase)
        await loadTodayGuidance(cyclePhaseCache: cyclePhaseCache)
        await trackFirstWorkoutPromptIfNeeded()
    }

    func resetWeeklyPlan() async {
        let service = WeeklyPlanService(dataClient: dataClient)
        _ = try? await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [2, 4, 6]
        )
        await loadWeeklyPlan()
        await loadTodayGuidance(cyclePhaseCache: nil)
    }

    func buildStarterWorkout() async -> Workout {
        let settings = await loadUserSettings()
        let workout = StarterWorkoutBuilder.build(
            context: StarterWorkoutContext(
                experienceLevel: settings.experienceLevel,
                primaryGoal: settings.primaryGoal,
                weightUnit: settings.weightUnit,
                cycleTrackingEnabled: settings.cycleTrackingEnabled,
                defaultEquipment: settings.defaultEquipment
            )
        )
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutStarted,
            source: "dashboard"
        )
        return workout
    }

    func buildActiveRecoveryWorkout(cyclePhase: CyclePhase?) async -> Workout {
        let settings = await loadUserSettings()
        return ActiveRecoveryWorkoutBuilder.build(
            equipment: settings.defaultEquipment,
            cyclePhase: cyclePhase
        )
    }

    func buildQuickWorkout() async -> Workout {
        let settings = await loadUserSettings()
        let recoveryRecords: [RecoveryScoreRecord] = (try? await dataClient.fetchAll(recordType: "RecoveryScore")) ?? []
        let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
        let latestRecovery = latestRecoveryScore(from: recoveryRecords)
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentPainLogs = painLogs.filter { $0.date >= recentCutoff }

        let request = QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: energyLevel(from: latestRecovery?.total),
            equipment: settings.defaultEquipment,
            todayDecisionKind: todayTrainingDecision?.kind ?? .modify,
            recoveryScoreTotal: latestRecovery?.total,
            painLogs: recentPainLogs
        )

        return QuickWorkoutBuilder.build(request: request).workout
    }

    /// Generates an AI workout based on cycle phase and energy
    func generateAIWorkout() async {
        isGeneratingWorkout = true

        // Simulate AI generation
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isGeneratingWorkout = false

        // In real implementation, this would call the AI service
        // and navigate to the built workout
    }

    // MARK: - Private Methods

    private func loadStats() async {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        let monthStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        if healthClient.isAvailable {
            do {
                let workouts = try await healthClient.fetchWorkouts(startDate: weekStart, endDate: nil, limit: 30)
                if let weekStart {
                    workoutsThisWeek = workouts.filter { $0.startDate >= weekStart }.count
                }
            } catch {
                // HealthKit not authorized or query failed
            }
        }

        if workoutsThisWeek == 0 {
            do {
                let recentWorkouts: [Workout] = try await dataClient.fetch(
                    recordType: "Workout",
                    predicate: NSPredicate(value: true),
                    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
                )
                if let weekStart {
                    workoutsThisWeek = recentWorkouts.filter { $0.completedAt != nil && $0.completedAt! >= weekStart }.count
                }
            } catch {
                // CloudKit unavailable — leave at default 0
            }
        }

        do {
            let prs: [OneRepMaxRecord] = try await dataClient.fetch(
                recordType: "OneRepMaxRecord",
                predicate: NSPredicate(value: true),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )
            prsThisMonth = prs.filter { $0.date >= monthStart }.count
        } catch {
            // CloudKit unavailable — leave prsThisMonth at default 0
        }
    }

    private func loadProgramInfo() async {
        do {
            let programs = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]

            let currentProgramIds = Set(ProgramTemplate.allCases.map(\.stableID))
            if let program = programs.first(where: { $0.isActive && currentProgramIds.contains($0.id) }) {
                activeProgramName = program.name
                nextWorkout = "Day \(programs.count + 1)" // Simplified
            } else {
                activeProgramName = nil
                nextWorkout = nil
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

    private func loadActiveChallenge(cachedWorkouts: [Workout]? = nil) async {
        let service = ChallengeService(dataClient: dataClient)
        do {
            let workouts: [Workout]
            if let cached = cachedWorkouts {
                workouts = cached
                dashLogger.info("📊 Challenge: using cached \(workouts.count) workouts")
            } else {
                workouts = try await dataClient.fetchAll(recordType: "Workout")
                dashLogger.info("📊 Challenge: fetched \(workouts.count) workouts")
            }
            let challenge = try await service.ensureLifetimeChallenge(from: workouts)
            dashLogger.info("📊 Challenge: ensured lifetime challenge = \(challenge?.id ?? "nil")")
            if let closest = try await service.closestToCompletion() {
                dashLogger.info("📊 Challenge: closest = \(closest.0.title), \(Int(closest.1.percentComplete * 100))%")
                activeChallengeData = closest
            } else {
                dashLogger.info("📊 Challenge: no active challenge found by closestToCompletion")
            }
        } catch {
            dashLogger.error("📊 Challenge load failed: \(error.localizedDescription)")
        }
    }

    private func loadWeeklyPlan(
        cyclePhase: CyclePhase? = nil,
        recoveryScore: Int? = nil
    ) async {
        let workouts: [Workout] = (try? await dataClient.fetchAll(recordType: "Workout")) ?? []
        let service = WeeklyPlanService(dataClient: dataClient)
        var plan = await service.currentPlan()
        if plan == nil {
            plan = try? await service.createOrUpdateCurrentPlan(
                targetWorkoutCount: 3,
                preferredWeekdays: [2, 4, 6]
            )
        }
        if let plan {
            weeklyPlanProgress = await service.progress(
                plan: plan,
                workouts: workouts,
                cyclePhase: cyclePhase,
                recoveryScore: recoveryScore
            )
            weeklyStreak = StreakService.calculate(workouts: workouts, targetPerWeek: plan.targetWorkoutCount)
        }
    }

    var shouldShowFirstWeekChecklist: Bool {
        !firstWeekChecklist.isEmpty && firstWeekChecklist.contains { !$0.isComplete }
    }

    private func loadTodayGuidance(cyclePhaseCache: CyclePhaseCache?) async {
        let calendar = Calendar.current
        let now = Date()
        let workouts: [Workout] = (try? await dataClient.fetchAll(
            recordType: "Workout",
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        )) ?? []
        let maxes: [OneRepMaxRecord] = (try? await dataClient.fetchAll(recordType: "OneRepMaxRecord")) ?? []
        let recoveryRecords: [RecoveryScoreRecord] = (try? await dataClient.fetchAll(recordType: "RecoveryScore")) ?? []
        let hasWeeklyPlan = weeklyPlanProgress != nil
        let checklist = TodayGuidanceService.firstWeekChecklist(
            completedWorkoutCount: workouts.filter { $0.completedAt != nil }.count,
            maxCount: maxes.count,
            hasWeeklyPlan: hasWeeklyPlan
        )

        let recentCutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let hasRecentWorkout = workouts.contains { workout in
            let date = workout.completedAt ?? workout.date
            return date >= recentCutoff
        }

        let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
        let hasPainLogToday = painLogs.contains { calendar.isDate($0.date, inSameDayAs: now) }
        let hasCyclePhase = cycleTrackingEnabled && cyclePhaseCache?.currentPhase != nil
        let painIntensityToday = painLogs
            .filter { calendar.isDate($0.date, inSameDayAs: now) }
            .map(\.intensity)
            .max()
        let latestRecovery = latestRecoveryScore(from: recoveryRecords)

        async let hasSleep = hasRecentSleepData()
        async let hasHRV = hasRecentHRVData()
        let (sleepAvailable, hrvAvailable) = await (hasSleep, hasHRV)
        let inputs = TodayGuidanceService.recoveryInputStatuses(
            hasRecentWorkout: hasRecentWorkout,
            hasPainLogToday: hasPainLogToday,
            hasCyclePhase: hasCyclePhase,
            hasSleep: sleepAvailable,
            hasHRV: hrvAvailable
        )

        let deload = DeloadDetectionService.recommendation(
            recentScores: recoveryRecords,
            recentPainLogs: painLogs
        )
        let decision = TodayTrainingDecisionService.decision(
            recoveryScore: latestRecovery,
            cyclePhase: cyclePhaseCache?.currentPhase,
            cycleConfidence: cyclePhaseCache?.confidence,
            painIntensity: painIntensityToday,
            energyLevel: nil,
            weeklyPlanProgress: weeklyPlanProgress,
            deloadRecommended: deload.isRecommended
        )

        firstWeekChecklist = checklist
        recoveryInputStatuses = inputs
        deloadRecommendation = deload
        todayTrainingDecision = decision
        recoveryExplanations = RecoveryExplanationService.topExplanations(from: latestRecovery)
        todayAction = TodayGuidanceService.primaryAction(
            workouts: workouts,
            weeklyPlanProgress: weeklyPlanProgress,
            firstWeekChecklist: checklist,
            recoveryInputs: inputs,
            now: now
        )
    }

    private func latestRecoveryScore(from records: [RecoveryScoreRecord]) -> RecoveryScore? {
        guard let latest = records.max(by: { $0.scoreDate < $1.scoreDate }) else { return nil }

        var subScores: [RecoveryInput: Int] = [:]
        if let hrv = latest.hrvSubScore { subScores[.hrv] = hrv }
        if let sleep = latest.sleepSubScore { subScores[.sleep] = sleep }
        if let load = latest.loadSubScore { subScores[.trainingLoad] = load }
        if let cycle = latest.cyclePhaseSubScore { subScores[.cyclePhase] = cycle }
        if let pain = latest.painSubScore { subScores[.pain] = pain }

        var explanations: [RecoveryInput: String] = [:]
        if let value = latest.hrvSubScore {
            explanations[.hrv] = "HRV signal is \(value)/100 today."
        }
        if let value = latest.sleepSubScore {
            explanations[.sleep] = "Sleep signal is \(value)/100."
        }
        if let value = latest.loadSubScore {
            explanations[.trainingLoad] = "Recent training load signal is \(value)/100."
        }
        if let value = latest.cyclePhaseSubScore {
            explanations[.cyclePhase] = "Cycle context signal is \(value)/100."
        }
        if let value = latest.painSubScore {
            explanations[.pain] = "Pain context signal is \(value)/100."
        }

        let recommendation = TrainingRecommendation(rawValue: latest.recommendationRaw) ?? .moderate
        return RecoveryScore(
            total: latest.totalScore,
            recommendation: recommendation,
            subScores: subScores,
            presentInputCount: latest.presentInputCount,
            totalInputCount: RecoveryInput.allCases.count,
            explanations: explanations
        )
    }

    private func energyLevel(from recoveryScoreTotal: Int?) -> EnergyLevel {
        guard let recoveryScoreTotal else { return .medium }
        if recoveryScoreTotal <= 45 { return .low }
        if recoveryScoreTotal >= 75 { return .high }
        return .medium
    }

    private func hasRecentSleepData() async -> Bool {
        guard healthClient.isAvailable else { return false }
        return ((try? await healthClient.fetchRecentSleepAnalysis()) ?? []).isEmpty == false
    }

    private func hasRecentHRVData() async -> Bool {
        guard healthClient.isAvailable else { return false }
        return ((try? await healthClient.fetchWeeklyHeartRateVariability()) ?? []).isEmpty == false
    }

    private func trackFirstWorkoutPromptIfNeeded() async {
        guard showsNewUserEmptyState, !hasTrackedFirstWorkoutPrompt else { return }
        hasTrackedFirstWorkoutPrompt = true
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutPromptSeen,
            source: "dashboard"
        )
    }

    private func loadUserSettings() async -> (
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        weightUnit: WeightUnit,
        cycleTrackingEnabled: Bool,
        defaultEquipment: EquipmentAccess
    ) {
        let records: [UserSettingsRecord] = (try? await dataClient.fetchAll(recordType: "UserSettings")) ?? []
        guard let settings = records.last else {
            return (.beginner, .strength, .lbs, false, .fullGym)
        }
        return (
            ExperienceLevel(rawValue: settings.experienceLevel) ?? .beginner,
            PrimaryGoal(rawValue: settings.primaryGoal) ?? .strength,
            WeightUnit(rawValue: settings.weightUnit) ?? .lbs,
            settings.cycleTrackingEnabled,
            settings.defaultEquipment
        )
    }
}

private extension FirstWeekChecklistKind {
    var actionTitle: String {
        switch self {
        case .firstWorkout: return "Start first workout"
        case .logMax: return "Log a max"
        case .weeklySchedule: return "Set schedule"
        }
    }
}

private extension RecoveryInputKind {
    var actionTitle: String {
        switch self {
        case .recentWorkout: return "Start workout"
        case .painLog: return "Log pain"
        case .cyclePhase: return "Update cycle"
        case .sleep, .hrv: return "Review recovery"
        }
    }
}
