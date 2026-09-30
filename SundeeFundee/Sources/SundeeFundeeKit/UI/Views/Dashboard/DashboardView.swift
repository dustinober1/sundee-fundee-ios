import SwiftUI
import os.log

private enum ReadinessRoute: Identifiable {
    case details
    case share(summary: ShareSanitizedSummary)

    var id: String {
        switch self {
        case .details: return "details"
        case .share: return "share"
        }
    }
}

private let dashLogger = Logger(subsystem: "com.sundeefundee.app", category: "Dashboard")

// MARK: - DashboardView

// MARK: - DashboardView
//
// Today screen showing cycle phase, stats, suggested workout, quick actions, and recent wins.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct DashboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var readinessViewModel = DailyReadinessViewModel()
    @StateObject private var engagementViewModel = TodayEngagementViewModel()
    @StateObject private var podViewModel = AccountabilityPodViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cyclePhaseCache: CyclePhaseCache
    @State private var showingAIWorkout = false
    @State private var previewWorkout: Workout?
    @State private var starterWorkout: Workout?
    @State private var resumeWorkoutID: String?
    @State private var showingTodayWhy = false
    @State private var showingMoreToday = false
    @State private var showingQuickCheckIn = false
    @State private var readinessRoute: ReadinessRoute?
    @State private var navigationResetID = UUID()
    @State private var showingCycleEducation = false
    #if canImport(UIKit)
    @State private var showingCycleShare = false
    #endif

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if horizontalSizeClass == .regular {
                        regularLayout
                    } else {
                        compactLayout
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Today")
            .screenshotModeBenefitBanner(caption: ScreenshotMode.caption(for: .today))
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
                let currentUserID = authViewModel.userID ?? AuthViewModel.guestUserID
                async let engagementLoad: Void = engagementViewModel.load()
                async let podLoad: Void = podViewModel.load(userID: currentUserID)
                await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
                await refreshReadiness()
                _ = await engagementLoad
                _ = await podLoad
            }
            .refreshable {
                let currentUserID = authViewModel.userID ?? AuthViewModel.guestUserID
                async let engagementLoad: Void = engagementViewModel.load()
                async let podLoad: Void = podViewModel.load(userID: currentUserID)
                await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
                await refreshReadiness()
                _ = await engagementLoad
                _ = await podLoad
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { notification in
                guard let event = WorkoutCompletionEvent.from(notification: notification),
                      event.kind == .standard else { return }
                Task {
                    await engagementViewModel.recordAction(
                        event.presenceStatus,
                        evidence: event.presenceEvidence,
                        at: event.operationDate
                    )
                    await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
                    await refreshReadiness()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyCheckInCompleted)) { _ in
                Task { await engagementViewModel.recordCheckIn() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .intentionalRecoveryCompleted)) { notification in
                guard let event = WorkoutCompletionEvent.from(notification: notification),
                      event.kind == .activeRecovery else { return }
                Task {
                    await engagementViewModel.recordAction(
                        event.presenceStatus,
                        evidence: event.presenceEvidence,
                        at: event.operationDate
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .cycleDataUpdated)) { _ in
                Task {
                    await cyclePhaseCache.refresh()
                    await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
                    await refreshReadiness()
                }
            }
            .onChange(of: authViewModel.userID) { _, _ in
                readinessViewModel.updateGuestState(authViewModel.isGuest)
                Task {
                    async let engagementLoad: Void = engagementViewModel.load()
                    await readinessViewModel.load()
                    _ = await engagementLoad
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await engagementViewModel.retrySync() }
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
            .sheet(item: $previewWorkout) { workout in
                WorkoutPreviewSheet(workout: workout) { workoutToStart in
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        starterWorkout = workoutToStart
                    }
                }
            }
            .sheet(item: $starterWorkout) { workout in
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutSessionViewModel(workout: workout)
                )
            }
            .sheet(isPresented: $showingTodayWhy) {
                TodayWhySheet(
                    decision: viewModel.todayTrainingDecision,
                    deloadRecommendation: viewModel.deloadRecommendation,
                    cyclePhase: cyclePhaseCache.currentPhase,
                    cycleConfidence: cyclePhaseCache.confidence
                )
            }
            .sheet(isPresented: $showingMoreToday) {
                TodayMoreSheet(
                    sections: viewModel.todaySecondarySectionInput,
                    viewModel: viewModel,
                    onStartWorkout: {
                        Task { previewWorkout = await viewModel.buildStarterWorkout() }
                    },
                    onStartQuickWorkout: {
                        Task { previewWorkout = await viewModel.buildQuickWorkout() }
                    },
                    onOpenCoachPlan: {
                        showingAIWorkout = true
                    },
                    onOpenQuickCheckIn: {
                        showingQuickCheckIn = true
                    },
                    onOpenLogMax: { viewModel.navigateToLogMax = true },
                    onOpenPainLog: { viewModel.navigateToPainTracking = true }
                )
            }
            .sheet(isPresented: $showingQuickCheckIn) {
                QuickCheckInView()
            }
            .sheet(isPresented: $showingCycleEducation) {
                CyclePhaseEducationView()
            }
            .sheet(item: $readinessRoute) { route in
                switch route {
                case .details:
                    ReadinessDetailsSheet(
                        snapshot: readinessViewModel.snapshot,
                        state: readinessViewModel.state,
                        guidance: readinessViewModel.guidance,
                        isStale: readinessViewModel.isStale,
                        onRetry: { Task { await readinessViewModel.retry() } },
                        canRetry: readinessViewModel.canRetry,
                        onStartWorkout: {
                            readinessRoute = nil
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                starterWorkout = await viewModel.buildStarterWorkout()
                            }
                        },
                        onShare: {
                            guard let snapshot = SharedSnapshotStore.readReadiness(),
                                  let summary = try? ShareSanitizedSummary(readinessSnapshot: snapshot) else { return }
                            readinessRoute = .share(summary: summary)
                        }
                    )
                case .share(let summary):
                    #if os(iOS)
                    ShareCardSheet(variant: .readiness(summary: summary), defaultAspect: .story)
                    #else
                    Text("Sharing is unavailable on this device.")
                    #endif
                }
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
        .id(navigationResetID)
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkRouteOpened)) { notification in
            guard let route = notification.object as? DeepLinkRoute, route.opensQuickCheckIn else { return }
            showingAIWorkout = false
            starterWorkout = nil
            resumeWorkoutID = nil
            showingTodayWhy = false
            showingMoreToday = false
            viewModel.navigateToLogMax = false
            viewModel.navigateToPainTracking = false
            navigationResetID = UUID()
            showingQuickCheckIn = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkRouteOpened)) { notification in
            guard let route = notification.object as? DeepLinkRoute, route.opensReadinessDetail else { return }
            readinessRoute = .details
        }
    }

    @ViewBuilder
    private var readinessContent: some View {
        switch readinessViewModel.state {
        case .loading:
            ArtDecoCard {
                HStack(spacing: AppTheme.Spacing.md) {
                    ProgressView().tint(AppTheme.Accent.orange)
                    Text("Calculating today's readiness…")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Calculating today's readiness")
        case .content:
            if let readiness = readinessViewModel.snapshot {
                ReadinessCardView(snapshot: readiness, guidance: readinessViewModel.guidance, isStale: readinessViewModel.isStale) {
                    readinessRoute = .details
                }
            }
        case .empty:
            readinessMessage(title: "Readiness needs a little more data", message: readinessViewModel.guidance, action: nil)
        case .error:
            readinessMessage(title: "Readiness is unavailable", message: readinessViewModel.guidance, action: readinessViewModel.canRetry ? { Task { await readinessViewModel.retry() } } : nil)
        }
    }

    private func readinessMessage(title: String, message: String, action: (() -> Void)?) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label(title, systemImage: "gauge.with.dots.needle.67percent")
                    .font(AppTheme.Typography.headlineMedium)
                Text(message)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(AppTheme.Text.secondary)
                if let action {
                    Button("Try again", action: { HapticFeedback.medium(); action() })
                        .artDecoButton(style: .accent)
                }
            }
        }
    }

    private func refreshReadiness() async {
        readinessViewModel.updateGuestState(authViewModel.isGuest)
        await readinessViewModel.load()
    }

    // MARK: - Adaptive Layouts

    private var compactLayout: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            welcomeHeader
            todayPresenceSection
            primaryActionSection
            cyclePhaseBanner
            readinessContent
            statsSection
            accountabilityPodSection
            quickActionsCard
            footerButtonsSection
        }
    }

    private var regularLayout: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            welcomeHeader

            HStack(alignment: .top, spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    readinessContent
                    cyclePhaseBanner
                    statsSection
                    footerButtonsSection
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(spacing: AppTheme.Spacing.lg) {
                    todayPresenceSection
                    primaryActionSection
                    accountabilityPodSection
                    quickActionsCard
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: 1100)
    }

    private var accountabilityPodSection: some View {
        AccountabilityPodCard(
            viewModel: podViewModel,
            userID: authViewModel.userID ?? AuthViewModel.guestUserID,
            displayName: authViewModel.userName ?? "Lifter"
        )
    }

    private var todayPresenceSection: some View {
        TodayPresenceCard(
            today: engagementViewModel.today,
            summary: engagementViewModel.summary,
            message: engagementViewModel.message,
            syncState: engagementViewModel.syncState,
            isUpdating: engagementViewModel.isLoading
        ) { status in
            Task { await engagementViewModel.select(status) }
        } onRetrySync: {
            Task { await engagementViewModel.retrySync() }
        }
    }

    @ViewBuilder
    private var primaryActionSection: some View {
        if let todayAction = viewModel.todayAction {
            todayActionCard(todayAction)
        } else if let decision = viewModel.todayTrainingDecision {
            todayTrainingDecisionCard(decision)
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        if viewModel.isInitialLoad {
            SkeletonStatRow()
        } else {
            compactTodaySnapshot
        }
    }

    @ViewBuilder
    private var footerButtonsSection: some View {
        if viewModel.showsNewUserEmptyState {
            EmptyStateView(
                icon: "figure.strengthtraining.traditional",
                title: "Welcome to Sundee Fundee",
                subtitle: "Start your first workout to unlock stats, benchmarks, and cycle-aware programming.",
                actionLabel: "Start First Workout",
                action: {
                    Task {
                        previewWorkout = await viewModel.buildStarterWorkout()
                    }
                },
                secondaryActionLabel: "Log a Max",
                secondaryAction: { viewModel.navigateToLogMax = true }
            )
        } else {
            Button {
                showingTodayWhy = true
            } label: {
                Label("Why Today?", systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .secondary)

            Button {
                showingMoreToday = true
            } label: {
                Label("More Today", systemImage: "ellipsis.circle")
                    .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .ghost)
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

                Button {
                    handleTodayTrainingDecision(decision)
                } label: {
                    Label(decision.primaryActionTitle, systemImage: decision.systemImage)
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .accent)
            }
        }
    }

    private func handleTodayTrainingDecision(_ decision: TodayTrainingDecision) {
        switch decision.kind {
        case .train, .modify:
            Task { previewWorkout = await viewModel.buildStarterWorkout() }
        case .recover:
            Task {
                previewWorkout = await viewModel.buildActiveRecoveryWorkout(
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
            return "Start Session"
        case .startScheduledWorkout:
            return "Start Workout"
        case .completeFirstWeekChecklist(let checklistKind):
            return checklistKind.actionTitle
        case .startFirstWorkout:
            return "Start Workout"
        }
    }

    private func handleTodayAction(_ action: TodayAction) {
        switch action.kind {
        case .resumeWorkout(let workoutID):
            resumeWorkoutID = workoutID
        case .resumeProgramSession:
            Task {
                if let programWorkout = await viewModel.buildActiveProgramWorkout() {
                    previewWorkout = programWorkout
                } else {
                    previewWorkout = await viewModel.buildStarterWorkout()
                }
            }
        case .startScheduledWorkout, .startFirstWorkout:
            Task { previewWorkout = await viewModel.buildStarterWorkout() }
        case .completeFirstWeekChecklist(let kind):
            handleFirstWeekChecklistAction(kind)
        }
    }

    private func handleFirstWeekChecklistAction(_ kind: FirstWeekChecklistKind) {
        switch kind {
        case .firstWorkout:
            Task { previewWorkout = await viewModel.buildStarterWorkout() }
        case .logMax:
            viewModel.navigateToLogMax = true
        case .weeklySchedule:
            Task { await viewModel.resetWeeklyPlan() }
        }
    }

    // MARK: - Cycle Phase Banner

    @ViewBuilder
    private var cyclePhaseBanner: some View {
        if viewModel.cycleTrackingEnabled {
            ArtDecoCard {
                VStack(spacing: 0) {
                    if let phase = cyclePhaseCache.currentPhase {
                        // Main cycle banner content (tappable to go to calendar)
                        NavigationLink(destination: CycleCalendarView()) {
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
                        .accessibilityHint("Tap to view cycle calendar")
                    } else if cyclePhaseCache.cycleTrackingMode == .contraceptive {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "pills.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Steady Baseline")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                Text("Hormonal contraceptive mode · Training adapts to nocturnal HRV, resting heart rate, and RPE.")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }

                            Spacer()
                        }
                    }

                    if !viewModel.cycleForecast.isEmpty {
                        Divider()
                            .padding(.vertical, AppTheme.Spacing.sm)

                        CycleForecastStripView(
                            forecasts: viewModel.cycleForecast,
                            terminologyStyle: cyclePhaseCache.terminologyStyle
                        )
                    }

                    // Info button footer
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xs)

                    Button {
                        showingCycleEducation = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(AppTheme.Accent.gold)

                            Text("Learn about cycle-aware training")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Accent.gold)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Learn about cycle-aware training")
                    .accessibilityHint("Opens educational guide about menstrual cycle and training")
                }
            }
            #if os(iOS)
            .contextMenu {
                Button {
                    showingCycleShare = true
                } label: {
                    Label("Share insight", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingCycleEducation = true
                } label: {
                    Label("Learn more", systemImage: "info.circle")
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

    private func cyclePhaseIcon(for phase: CyclePhase) -> String {
        if cyclePhaseCache.isGymPrivacyEnabled {
            return "waveform.path.ecg"
        }
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sun.max.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        }
    }

    private func cyclePhaseColor(for phase: CyclePhase) -> Color {
        if cyclePhaseCache.isGymPrivacyEnabled {
            return AppTheme.Accent.gold
        }
        switch phase {
        case .menstrual: return AppTheme.Semantic.error
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Text.secondary
        }
    }

    private func cyclePhaseTitle(for phase: CyclePhase) -> String {
        if cyclePhaseCache.isGymPrivacyEnabled {
            return "Cycle Optimization Active"
        }
        return getPhaseRecommendation(phase: phase, style: cyclePhaseCache.terminologyStyle).title
    }

    private func cyclePhaseDescription(for phase: CyclePhase) -> String {
        if cyclePhaseCache.isGymPrivacyEnabled {
            return "Autoregulated workout recommendations based on your personal profile."
        }
        return getPhaseRecommendation(phase: phase, style: cyclePhaseCache.terminologyStyle).description
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

    private var compactTodaySnapshot: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                StatCard(
                    value: "\(viewModel.workoutsThisWeek)",
                    label: "This Week"
                )
                .accessibilityLabel("Workouts this week")
                .accessibilityValue("\(viewModel.workoutsThisWeek)")

                StatCard(
                    value: "\(viewModel.prsThisMonth)",
                    label: "PRs"
                )
                .accessibilityLabel("Personal records this month")
                .accessibilityValue("\(viewModel.prsThisMonth)")

                StatCard(
                    value: viewModel.activeProgramName ?? "Open",
                    label: "Plan"
                )
                .accessibilityLabel("Active program")
                .accessibilityValue(viewModel.activeProgramName ?? "open")
            }
            .accessibilityElement(children: .contain)

            if let todayAction = viewModel.todayAction {
                actionPill(title: todayAction.title, subtitle: todayAction.subtitle, icon: todayAction.systemImage)
            } else if let decision = viewModel.todayTrainingDecision {
                actionPill(title: decision.title, subtitle: decision.subtitle, icon: decision.systemImage)
            }
        }
    }

    private func actionPill(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Accent.gold)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Text.primary)
                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Background.cream.opacity(0.45))
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Accent.gold.opacity(0.18), lineWidth: 1)
        )
    }

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

                            if let program = viewModel.nextProgramListItem {
                                NavigationLink("Start This Workout", destination: ProgramDetailView(program: program))
                                    .artDecoButton(style: .primary)
                            }
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
                            Task { previewWorkout = await viewModel.buildStarterWorkout() }
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

    // MARK: - Missed Workout Recovery Card

    private func missedWorkoutRecoveryCard(_ plan: MissedWorkoutRecoveryPlan) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.orange)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("You missed workouts this week")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(plan.userSummary)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                HStack {
                    Button {
                        Task { await viewModel.applyMissedWorkoutRecovery() }
                    } label: {
                        Label(plan.actionTitle, systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .accent)

                    Button {
                        viewModel.missedWorkoutRecoveryPlan = nil
                    } label: {
                        Label("Keep Original", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .secondary)
                }
            }
        }
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
