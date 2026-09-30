import SwiftUI
#if os(iOS)
import SafariServices
#endif

// MARK: - ProgramsListView
//
// List of available training programs.
// Matches the web app's programs feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ProgramsListView: View {
    @StateObject private var viewModel = ProgramsListViewModel()
    @State private var showingRecommendationQuiz = false
    @State private var showingAIWorkout = false
    @State private var showingReturnToTraining = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                } else if viewModel.programs.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No Programs Available",
                        subtitle: "Programs couldn't be loaded. Pull to refresh or check your connection.",
                        actionLabel: "Try Again",
                        action: {
                            Task { await viewModel.loadPrograms() }
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            programRecommendationPrompt
                            returnToTrainingPrompt

                            ForEach(viewModel.programs) { program in
                                ProgramRow(
                                    program: program,
                                    isEnrolling: viewModel.enrollingProgramId == program.id,
                                    onEnroll: {
                                        Task {
                                            await viewModel.enrollInProgram(program.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Programs")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadPrograms()
            }
            .refreshable {
                await viewModel.loadPrograms()
            }
            .sheet(isPresented: $showingRecommendationQuiz) {
                ProgramRecommendationSheet(
                    viewModel: viewModel,
                    onStartCoachPlan: {
                        showingRecommendationQuiz = false
                        showingAIWorkout = true
                    }
                )
            }
            .sheet(isPresented: $showingReturnToTraining) {
                ReturnToTrainingSheet(viewModel: viewModel)
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #else
            .sheet(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #endif
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

    private var programRecommendationPrompt: some View {
        ArtDecoCard {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.Accent.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Help Me Choose")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(viewModel.topRecommendation?.reason ?? "Answer four quick questions to match your goal, schedule, and equipment.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    viewModel.updateRecommendations()
                    showingRecommendationQuiz = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.Accent.gold)
                .accessibilityLabel("Open program recommendation quiz")
            }
        }
    }

    private var returnToTrainingPrompt: some View {
        ArtDecoCard {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.Accent.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Coming Back After a Break")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(viewModel.isReturnToTrainingEnrolled
                        ? "You're on a structured return. Tap to review the weekly plan."
                        : "A gentle, structured return that starts light and builds back week by week.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    showingReturnToTraining = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.Accent.gold)
                .accessibilityLabel("Set up a return to training program")
            }
        }
    }
}

// MARK: - ReturnToTrainingSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct ReturnToTrainingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgramsListViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    reasonCard
                    planSummaryCard
                    weekByWeekCard
                    startButton
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Return to Training")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var reasonCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("What are you coming back from?")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Picker("Coming back from", selection: $viewModel.returnToTrainingReason) {
                    ForEach(TrainingBreakReason.allCases) { reason in
                        Text(reason.displayName).tag(reason)
                    }
                }
                .accessibilityHint("Sets how light the first weeks start")

                Text("This only changes where the plan starts and how long it takes to build "
                    + "back. Go by how you're feeling, and skip or repeat a week whenever you "
                    + "need to.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var planSummaryCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(viewModel.returnToTrainingPreview.name)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text("\(viewModel.returnToTrainingPreview.durationWeeks) weeks · "
                    + "\(viewModel.returnToTrainingPreview.sessionsPerWeek) sessions a week")
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Text.secondary)

                if let first = viewModel.returnToTrainingWeeks.first {
                    Text(first.focus)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
        }
    }

    private var weekByWeekCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Week by Week")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(viewModel.returnToTrainingWeeks, id: \.week) { week in
                    HStack(alignment: .firstTextBaseline) {
                        Text("Week \(week.week)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(week.phaseName)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        Spacer()

                        Text("\(Int((week.loadPercent * 100).rounded()))%")
                            .font(AppTheme.Typography.monoMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Week \(week.week), \(week.phaseName), "
                            + "\(Int((week.loadPercent * 100).rounded())) percent of usual working weight"
                    )
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            Task {
                await viewModel.enrollInReturnToTraining()
                if viewModel.isReturnToTrainingEnrolled { dismiss() }
            }
        } label: {
            HStack {
                Spacer()
                if viewModel.isEnrollingReturnToTraining {
                    ProgressView()
                        .padding(.trailing, AppTheme.Spacing.sm)
                        .accessibilityLabel("Starting program")
                }
                Text(startButtonTitle)
                    .font(AppTheme.Typography.labelLarge)
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .disabled(viewModel.isEnrollingReturnToTraining)
    }

    private var startButtonTitle: String {
        if viewModel.isEnrollingReturnToTraining { return "Starting..." }
        return viewModel.isReturnToTrainingEnrolled ? "Update This Program" : "Start This Program"
    }
}

// MARK: - ProgramRecommendationSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct ProgramRecommendationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgramsListViewModel
    let onStartCoachPlan: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    quizControls

                    if let recommendation = viewModel.topRecommendation {
                        recommendationCard(recommendation, isPrimary: true)
                    }

                    ForEach(viewModel.programRecommendations.dropFirst()) { recommendation in
                        recommendationCard(recommendation, isPrimary: false)
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Help Me Choose")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: viewModel.recommendationGoal) { _, _ in viewModel.updateRecommendations() }
            .onChange(of: viewModel.recommendationExperience) { _, _ in viewModel.updateRecommendations() }
            .onChange(of: viewModel.recommendationDaysPerWeek) { _, _ in viewModel.updateRecommendations() }
            .onChange(of: viewModel.recommendationEquipment) { _, _ in viewModel.updateRecommendations() }
        }
    }

    private var quizControls: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Picker("Goal", selection: $viewModel.recommendationGoal) {
                    ForEach(PrimaryGoal.recommendationChoices, id: \.self) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }

                Picker("Experience", selection: $viewModel.recommendationExperience) {
                    ForEach(ExperienceLevel.recommendationChoices, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Stepper(
                    "Days per week: \(viewModel.recommendationDaysPerWeek)",
                    value: $viewModel.recommendationDaysPerWeek,
                    in: 1...6
                )

                Picker("Equipment", selection: $viewModel.recommendationEquipment) {
                    ForEach(EquipmentAccess.userSelectableDefaults, id: \.self) { equipment in
                        Text(equipment.displayName).tag(equipment)
                    }
                }
            }
        }
    }

    private func recommendationCard(_ recommendation: ProgramRecommendation, isPrimary: Bool) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(isPrimary ? "Best Match" : "Also Consider")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)

                        Text(recommendation.title)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)
                    }

                    Spacer()

                    Text("\(recommendation.score)")
                        .font(AppTheme.Typography.monoMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .accessibilityLabel("Match score \(recommendation.score)")
                }

                Text(recommendation.subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)

                Text(recommendation.reason)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    select(recommendation)
                } label: {
                    Label(actionTitle(for: recommendation.kind), systemImage: actionIcon(for: recommendation.kind))
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: isPrimary ? .accent : .secondary)
            }
        }
    }

    private func select(_ recommendation: ProgramRecommendation) {
        switch recommendation.kind {
        case .program(let template):
            Task {
                await viewModel.enrollInProgram(template.stableID)
                dismiss()
            }
        case .coachPlan:
            onStartCoachPlan()
        }
    }

    private func actionTitle(for kind: ProgramRecommendationKind) -> String {
        switch kind {
        case .program:
            return "Enroll"
        case .coachPlan:
            return "Build Coach Plan"
        }
    }

    private func actionIcon(for kind: ProgramRecommendationKind) -> String {
        switch kind {
        case .program:
            return "checkmark.seal"
        case .coachPlan:
            return "sparkles"
        }
    }
}

// MARK: - ProgramRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramRow: View {
    let program: ProgramListItem
    let isEnrolling: Bool
    let onEnroll: () -> Void

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        if program.template == .firstMargarita {
                            Text("FEATURED")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.orange)
                                .accessibilityLabel("Featured program")
                        }

                        Text(program.name)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)
                    }

                    Spacer()

                    if program.isEnrolled {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityLabel("Currently enrolled")
                    }
                }

                Text(program.category)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                Text(program.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)

                HStack(spacing: AppTheme.Spacing.lg) {
                    Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                    Label("\(program.sessionsPerWeek)/wk", systemImage: "figure.strengthtraining.traditional")
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

                Text(program.difficulty)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                if program.isEnrolled {
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        Label("View Program", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                    }
                    .artDecoButton(style: .primary)
                    .accessibilityHint("Open the program and start a session")
                } else {
                    Button {
                        onEnroll()
                    } label: {
                        if isEnrolling {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .accessibilityLabel("Enrolling in program")
                        } else {
                            Text("Enroll")
                        }
                    }
                    .artDecoButton(style: .secondary)
                    .disabled(isEnrolling)
                    .accessibilityHint("Start this program")
                    .accessibilityValue(isEnrolling ? "Enrolling…" : "")
                }
            }
        }
    }
}

// MARK: - ProgramListItem

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramListItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let isEnrolled: Bool
    let template: ProgramTemplate?
    let printablePDFURL: URL?
}

// MARK: - ProgramDetailView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramDetailView: View {
    let program: ProgramListItem
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: ProgramDetailViewModel
    @State private var activeWorkout: Workout?
    @State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?
    @State private var resumeWorkoutId: String?
    @State private var printablePDFURLToPresent: URL?

    init(program: ProgramListItem) {
        self.program = program
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(program: program))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                programHeaderCard

                if let summary = viewModel.latestAdaptationSummary, !summary.changes.isEmpty {
                    adaptationSummaryCard(summary)
                }

                if let generated = viewModel.generatedProgram {
                    ForEach(generated.weeks, id: \.week) { week in
                        weekSection(week, phases: generated.phases)
                    }
                } else {
                    ProgressView("Loading sessions...")
                        .padding(AppTheme.Spacing.xxl)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .artDecoBackground()
        .navigationTitle(program.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationDestination(isPresented: Binding(
            get: { activeWorkout != nil },
            set: { if !$0 { activeWorkout = nil } }
        )) {
            if let workout = activeWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { resumeWorkoutId != nil },
            set: { if !$0 { resumeWorkoutId = nil } }
        )) {
            if let id = resumeWorkoutId {
                WorkoutDetailView(workoutId: id)
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $activeWorkoutSession) { session in
            ActiveWorkoutView(viewModel: session)
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            activeWorkoutSession = nil
        }
        #endif
        .onAppear {
            viewModel.generateSessions()
        }
        .task {
            await viewModel.loadSessionProgress()
            await viewModel.loadAdaptationPreviews()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            Task { await viewModel.loadSessionProgress() }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        #if os(iOS)
        .sheet(isPresented: Binding(
            get: { printablePDFURLToPresent != nil },
            set: { if !$0 { printablePDFURLToPresent = nil } }
        )) {
            if let printablePDFURLToPresent {
                SafariView(url: printablePDFURLToPresent)
                    .ignoresSafeArea()
            }
        }
        #endif
    }

    // MARK: - Program Header

    private var programHeaderCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    statPill(value: "\(program.durationWeeks)", label: "Weeks")
                    statPill(value: "\(program.sessionsPerWeek)", label: "Sessions/wk")
                    statPill(value: program.difficulty.capitalized, label: "Level")
                }

                Text(program.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                if let printablePDFURL = program.printablePDFURL {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Button {
                            #if os(iOS)
                            printablePDFURLToPresent = printablePDFURL
                            #else
                            openURL(printablePDFURL)
                            #endif
                        } label: {
                            Label("Printable PDF", systemImage: "doc.richtext")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .secondary)
                        .accessibilityHint("Open the printable base plan PDF")

                        Text("This is the base printable plan. Sundee Fundee may adapt in-app workouts around cycle phase, recovery, pain, and injuries.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }
            }
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.monoLarge)
                .foregroundColor(AppTheme.Text.primary)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    private func adaptationSummaryCard(_ summary: ProgramAdaptationSummary) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Session Adaptation")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text(summary.headline)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(summary.changes.prefix(3)) { change in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                        Circle()
                            .fill(AppTheme.Accent.gold.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                            .accessibilityHidden(true)
                        Text(change.detail)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Latest adaptation summary")
    }

    // MARK: - Week Section

    private func weekSection(_ week: GeneratedProgramWeek, phases: [GeneratedProgramPhase]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            weekHeader(week, phases: phases)

            ForEach(week.sessions, id: \.sessionId) { session in
                sessionCard(session, week: week.week)
            }
        }
    }

    private func weekHeader(_ week: GeneratedProgramWeek, phases: [GeneratedProgramPhase]) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Week \(week.week)")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            if let phaseId = week.phaseId,
               let phase = phases.first(where: { $0.id == phaseId }) {
                Text("· \(phase.name)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Accent.gold)
            }

            Spacer()
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Session Card

    private func sessionCard(_ session: GeneratedProgramSession, week: Int) -> some View {
        let isCompleted = viewModel.completedSessionIds.contains(session.sessionId)
        let resumeId = viewModel.resumeWorkoutId(for: session.sessionId)

        return ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(session.sessionName)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(session.focus.prefix(1).uppercased() + session.focus.dropFirst())
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                        Label("\(session.exercises.count) exercises", systemImage: "list.bullet")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        if isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.gold)
                        } else if resumeId != nil {
                            Label("In Progress", systemImage: "circle.dashed")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.orange)
                        }
                    }
                }

                Divider()
                    .background(AppTheme.Accent.gold.opacity(0.2))

                sessionLoadBar(session)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    ForEach(session.exercises.prefix(4), id: \.exercise) { ex in
                        exercisePreviewRow(ex)
                    }
                    if session.exercises.count > 4 {
                        Text("+ \(session.exercises.count - 4) more")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }

                if let workoutId = resumeId {
                    Button {
                        resumeWorkoutId = workoutId
                    } label: {
                        Label("Resume Session", systemImage: "arrow.forward.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .secondary)
                    .accessibilityHint("Return to your in-progress workout")
                }

                if let summary = viewModel.adaptationPreview(for: session.sessionId), !summary.changes.isEmpty {
                    whatChangedRow(summary)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Quick start edits")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        programQuickEditButton("20m", edit: .shorten(minutes: 20), session: session, week: week)
                        programQuickEditButton("30m", edit: .shorten(minutes: 30), session: session, week: week)
                        programQuickEditButton("45m", edit: .shorten(minutes: 45), session: session, week: week)
                    }

                    HStack(spacing: AppTheme.Spacing.xs) {
                        programQuickEditButton("Less Volume", edit: .reduceVolume, session: session, week: week)
                        programQuickEditButton("Skip Last", edit: .removeLastExercise, session: session, week: week)
                    }

                    HStack(spacing: AppTheme.Spacing.xs) {
                        programQuickEditButton("Swap Last", edit: .swapLastExercise, session: session, week: week)
                        programQuickEditButton("Original", edit: .restoreOriginal, session: session, week: week)
                    }
                }

                Button {
                    Task {
                        let launchResult = await viewModel.startSession(
                            session,
                            week: week,
                            programName: program.name
                        )
                        if let launchResult {
                            activeWorkoutSession = ActiveWorkoutSessionViewModel(
                                workout: launchResult.workout,
                                adaptationDecisionRecord: launchResult.adaptationDecisionRecord
                            )
                        }
                    }
                } label: {
                    if viewModel.startingSessionId == session.sessionId {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .accessibilityLabel("Starting session")
                    } else {
                        Label(isCompleted ? "Start Again" : "Start Session",
                              systemImage: isCompleted ? "arrow.clockwise" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .artDecoButton(style: isCompleted ? .secondary : .accent)
                .disabled(viewModel.startingSessionId != nil)
                .accessibilityHint(isCompleted
                    ? "Start this session again from scratch"
                    : "Create a workout from this session and open it")
            }
        }
    }

    private func programQuickEditButton(
        _ title: String,
        edit: ProgramSessionQuickEdit,
        session: GeneratedProgramSession,
        week: Int
    ) -> some View {
        Button {
            Task {
                let launchResult = await viewModel.startSession(
                    session,
                    week: week,
                    programName: program.name,
                    quickEdit: edit
                )
                if let launchResult {
                    activeWorkoutSession = ActiveWorkoutSessionViewModel(
                        workout: launchResult.workout,
                        adaptationDecisionRecord: launchResult.adaptationDecisionRecord
                    )
                }
            }
        } label: {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .frame(maxWidth: .infinity)
        }
        .artDecoButton(style: .ghost)
        .disabled(viewModel.startingSessionId != nil)
        .accessibilityHint("Start this session with the \(title) edit applied")
    }

    private func whatChangedRow(_ summary: ProgramAdaptationSummary) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Label("What changed", systemImage: "sparkles")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text(summary.headline)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let change = summary.changes.first {
                Text(change.detail)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Background.cream.opacity(0.45))
        .cornerRadius(AppTheme.CornerRadius.small)
        .accessibilityElement(children: .combine)
    }

    private func sessionLoadBar(_ session: GeneratedProgramSession) -> some View {
        let totalSets = session.exercises.reduce(0) { $0 + setsCount($1.sets) }
        let lightCeiling = 18
        let moderateCeiling = 26
        let displayCap = 32
        let fillFraction = min(Double(totalSets) / Double(displayCap), 1.0)
        let (color, label): (Color, String) = {
            switch totalSets {
            case 0..<lightCeiling:
                return (AppTheme.Recovery.green, "Light")
            case lightCeiling..<moderateCeiling:
                return (AppTheme.Recovery.yellow, "Moderate")
            default:
                return (AppTheme.Accent.orange, "Heavy")
            }
        }()

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("Session load")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .tracking(1)
                Spacer()
                Text("\(label) \u{00B7} \(totalSets) sets")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.Accent.gold.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * fillFraction)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session load: \(label), \(totalSets) total sets")
    }

    private func setsCount(_ value: ExerciseValue) -> Int {
        switch value {
        case .fixed(let v): return v
        case .range(let low, let high): return (low + high) / 2
        case .amrap: return 1
        case .text: return 3
        }
    }

    private func exercisePreviewRow(_ ex: GeneratedProgramExercise) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Accent.gold.opacity(0.4))
                .frame(width: 4, height: 4)
                .accessibilityHidden(true)

            Text(ex.exercise)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.primary)

            Spacer()

            Text("\(ex.sets.description) × \(ex.reps.description)")
                .font(AppTheme.Typography.monoSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }
}

#if os(iOS)
@available(iOS 18.0, *)
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

// MARK: - ProgramSessionQuickEdit

enum ProgramSessionQuickEdit: Equatable {
    case shorten(minutes: Int)
    case reduceVolume
    case removeLastExercise
    case swapLastExercise
    case restoreOriginal
}

struct ProgramSessionLaunchResult {
    let workout: Workout
    let adaptationDecisionRecord: WorkoutAdaptationDecisionRecord?
}
