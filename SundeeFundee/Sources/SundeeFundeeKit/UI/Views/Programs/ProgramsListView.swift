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

// MARK: - ProgramDetailViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramDetailViewModel: ObservableObject {
    @Published var generatedProgram: GeneratedProgram?
    @Published var errorMessage: String?
    @Published var startingSessionId: String?
    @Published var completedSessionIds: Set<String> = []
    @Published var inProgressSessionIds: Set<String> = []
    @Published var latestAdaptationSummary: ProgramAdaptationSummary?
    private var adaptationPreviewBySessionId: [String: ProgramAdaptationSummary] = [:]
    private var sessionWorkoutMap: [String: String] = [:]

    private let program: ProgramListItem
    private let dataClient: DataClientProtocol

    private let healthClient: HealthClientProtocol

    init(
        program: ProgramListItem,
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client
    ) {
        self.program = program
        self.dataClient = dataClient
        self.healthClient = healthClient
    }

    func generateSessions() {
        guard let template = program.template else {
            // Fallback: build a minimal program structure from metadata without sessions
            generatedProgram = GeneratedProgram(
                id: program.id,
                name: program.name,
                category: program.category,
                description: program.description,
                durationWeeks: program.durationWeeks,
                sessionsPerWeek: program.sessionsPerWeek,
                difficulty: program.difficulty,
                phases: [],
                weeks: []
            )
            return
        }
        generatedProgram = generateProgram(
            template: template,
            name: program.name,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek
        )
    }

    func loadSessionProgress() async {
        do {
            let allRecords: [ProgramSessionRecord] = try await dataClient.fetchAll(recordType: "ProgramSessionRecord")
            let programRecords = allRecords.filter { $0.programId == program.id }
            guard !programRecords.isEmpty else { return }

            let allWorkouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            let completedWorkoutIds = Set(allWorkouts.filter(\.isComplete).map(\.id))

            var newInProgress: Set<String> = []
            var newCompleted: Set<String> = []
            var newWorkoutMap: [String: String] = [:]
            for record in programRecords {
                newInProgress.insert(record.sessionId)
                newWorkoutMap[record.sessionId] = record.workoutId
                if completedWorkoutIds.contains(record.workoutId) {
                    newCompleted.insert(record.sessionId)
                }
            }

            inProgressSessionIds = newInProgress
            completedSessionIds = newCompleted
            sessionWorkoutMap = newWorkoutMap
        } catch {
            // Non-critical — progress display is best-effort
        }
    }

    func resumeWorkoutId(for sessionId: String) -> String? {
        let workoutId = sessionWorkoutMap[sessionId]
        guard let workoutId, inProgressSessionIds.contains(sessionId),
              !completedSessionIds.contains(sessionId) else { return nil }
        return workoutId
    }

    func adaptationPreview(for sessionId: String) -> ProgramAdaptationSummary? {
        adaptationPreviewBySessionId[sessionId]
    }

    func loadAdaptationPreviews() async {
        guard let generatedProgram else { return }
        let context = await loadAdaptationContext()
        var previews: [String: ProgramAdaptationSummary] = [:]

        for week in generatedProgram.weeks {
            for session in week.sessions {
                let result = ProgramSessionAdaptationService.adaptWithSummary(
                    session.exercises,
                    context: context
                )
                previews[session.sessionId] = result.summary
            }
        }

        adaptationPreviewBySessionId = previews
    }

    func startSession(
        _ session: GeneratedProgramSession,
        week: Int,
        programName: String,
        quickEdit: ProgramSessionQuickEdit? = nil
    ) async -> ProgramSessionLaunchResult? {
        guard startingSessionId == nil else { return nil }
        startingSessionId = session.sessionId
        defer { startingSessionId = nil }

        // Load adaptive context and user maxes in parallel. The PDF remains the
        // base plan; the in-app workout adapts before the active session opens.
        async let adaptationContextTask = loadAdaptationContext()
        async let maxesTask = loadMaxes()
        let (adaptationContext, maxes) = await (adaptationContextTask, maxesTask)
        let adaptationResult = ProgramSessionAdaptationService.adaptWithSummary(
            session.exercises,
            context: adaptationContext
        )
        latestAdaptationSummary = adaptationResult.summary
        let originalEdited = Self.applyQuickEdit(quickEdit, to: session.exercises)
        let edited = Self.applyQuickEdit(quickEdit, to: adaptationResult.exercises)
        for edit in edited.edits {
            await CoachMemoryService(dataClient: dataClient).recordWorkoutEdit(edit)
        }
        let cycleMult = aiCyclePhaseMultiplier(adaptationContext.cyclePhase)
        let workoutID = UUID().uuidString
        let workoutName = "\(programName) — \(session.sessionName)"
        let workoutDate = Date()
        let originalWorkout = Self.makeWorkout(
            id: workoutID,
            date: workoutDate,
            name: workoutName,
            exercises: originalEdited.exercises,
            maxes: maxes,
            cycleMultiplier: 1.0
        )
        let workout = Self.makeWorkout(
            id: workoutID,
            date: workoutDate,
            name: workoutName,
            exercises: edited.exercises,
            maxes: maxes,
            cycleMultiplier: cycleMult
        )

        do {
            try await dataClient.save(workout, recordType: "Workout")
            let quickEditReasons = Self.quickEditReasons(
                edits: edited.edits,
                quickEdit: quickEdit
            )
            let shouldCreateDecisionRecord = !adaptationResult.summary.changes.isEmpty || !quickEditReasons.isEmpty
            let adaptationDecisionRecord = shouldCreateDecisionRecord
                ? try? await WorkoutAdaptationDecisionService.record(
                    originalWorkout: originalWorkout,
                    adaptedWorkout: workout,
                    summary: adaptationResult.summary,
                    context: adaptationContext,
                    additionalReasons: quickEditReasons,
                    dataClient: dataClient
                )
                : nil

            // Save session record to track progress through the program.
            // Non-critical — workout is already saved; session record is for progress display.
            let sessionRecord = ProgramSessionRecord(
                id: UUID().uuidString,
                programId: program.id,
                sessionId: session.sessionId,
                workoutId: workout.id,
                week: week
            )
            try? await dataClient.save(sessionRecord, recordType: "ProgramSessionRecord")
            inProgressSessionIds.insert(session.sessionId)
            sessionWorkoutMap[session.sessionId] = workout.id

            return ProgramSessionLaunchResult(
                workout: workout,
                adaptationDecisionRecord: adaptationDecisionRecord
            )
        } catch {
            errorMessage = "Couldn't start this session right now. Please try again."
            return nil
        }
    }

    // MARK: - Cycle & Max Helpers

    private static func makeWorkout(
        id: String,
        date: Date,
        name: String,
        exercises: [GeneratedProgramExercise],
        maxes: [OneRepMaxRecord],
        cycleMultiplier: Double
    ) -> Workout {
        Workout(
            id: id,
            date: date,
            name: name,
            exercises: exercises.map { ex in
                let setCount: Int
                if case .fixed(let n) = ex.sets { setCount = n } else { setCount = 3 }

                let repCount: Int
                let setType: ExerciseType
                switch ex.reps {
                case .fixed(let n):
                    repCount = n
                    setType = .fixed
                case .amrap:
                    repCount = 0
                    setType = .amrap
                case .range(let lo, let hi):
                    repCount = lo
                    setType = .range(min: lo, max: hi)
                case .text(let t):
                    repCount = 0
                    setType = .text(t)
                }

                var prescribedWeight: Double = 0
                if !ex.bodyweightOnly, ex.percent1RM != nil,
                   let userMax = maxes.first(where: { $0.exerciseName.lowercased() == ex.exercise.lowercased() }) {
                    prescribedWeight = calculatePrescribedWeight(
                        max: userMax.weight,
                        reps: repCount > 0 ? repCount : 5,
                        cycleMultiplier: cycleMultiplier
                    )
                }

                let targetSets = (0..<setCount).map { _ in
                    ExerciseSet(
                        reps: repCount,
                        prescribedWeight: prescribedWeight,
                        prescribedPercentage: ex.percent1RM,
                        type: setType
                    )
                }

                return Exercise(
                    id: UUID().uuidString,
                    name: ex.exercise,
                    category: ex.bodyweightOnly ? .accessory : (isWeightliftingExercise(ex.exercise) ? .compound : .accessory),
                    bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                    targetSets: targetSets,
                    restMinutes: ex.restMinutes
                )
            }
        )
    }

    private static func applyQuickEdit(
        _ edit: ProgramSessionQuickEdit?,
        to exercises: [GeneratedProgramExercise]
    ) -> (exercises: [GeneratedProgramExercise], edits: [WorkoutEdit]) {
        guard let edit else { return (exercises, []) }

        switch edit {
        case .shorten(let minutes):
            let targetCount: Int
            switch minutes {
            case ...20: targetCount = 3
            case 21...30: targetCount = 4
            case 31...45: targetCount = 5
            default: targetCount = exercises.count
            }
            let kept = Array(exercises.prefix(max(1, targetCount)))
            let removed = exercises.dropFirst(kept.count)
            return (
                kept,
                removed.map { WorkoutEdit(editType: .removedExercise, exerciseName: $0.exercise) }
            )
        case .reduceVolume:
            var edits: [WorkoutEdit] = []
            let reduced = exercises.map { exercise in
                let reducedSets = reduceSets(exercise.sets)
                if reducedSets != exercise.sets {
                    edits.append(WorkoutEdit(editType: .changedVolume, exerciseName: exercise.exercise))
                }
                return copyProgramExercise(exercise, sets: reducedSets)
            }
            return (reduced, edits)
        case .removeLastExercise:
            guard exercises.count > 1, let removed = exercises.last else { return (exercises, []) }
            return (
                Array(exercises.dropLast()),
                [WorkoutEdit(editType: .removedExercise, exerciseName: removed.exercise)]
            )
        case .swapLastExercise:
            guard let last = exercises.last,
                  let replacement = replacementExercise(for: last, existingExercises: exercises) else {
                return (exercises, [])
            }
            var swapped = exercises
            swapped[swapped.count - 1] = replacement
            return (
                swapped,
                [WorkoutEdit(
                    editType: .swappedExercise,
                    exerciseName: last.exercise,
                    replacementExercise: replacement.exercise
                )]
            )
        case .restoreOriginal:
            return (exercises, [])
        }
    }

    private static func quickEditReasons(
        edits: [WorkoutEdit],
        quickEdit: ProgramSessionQuickEdit?
    ) -> [(id: String, text: String)] {
        guard !edits.isEmpty else { return [] }

        switch quickEdit {
        case .shorten(let minutes):
            return [("quick_edit", "Session was shortened to fit \(minutes) minutes.")]
        case .reduceVolume:
            return [("quick_edit", "Session volume was reduced before adaptation.")]
        case .removeLastExercise:
            return [("quick_edit", "The last exercise was removed before adaptation.")]
        case .swapLastExercise:
            return [("quick_edit", "The last exercise was swapped before adaptation.")]
        case .restoreOriginal, .none:
            return []
        }
    }

    private static func reduceSets(_ sets: ExerciseValue) -> ExerciseValue {
        switch sets {
        case .fixed(let value):
            return .fixed(value: max(1, value - 1))
        case .range(let low, let high):
            return .range(low: max(1, low - 1), high: max(1, high - 1))
        case .amrap, .text:
            return sets
        }
    }

    private static func copyProgramExercise(
        _ exercise: GeneratedProgramExercise,
        sets: ExerciseValue
    ) -> GeneratedProgramExercise {
        GeneratedProgramExercise(
            exercise: exercise.exercise,
            sets: sets,
            reps: exercise.reps,
            percent1RM: exercise.percent1RM,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }

    private static func copyProgramExercise(
        _ exercise: GeneratedProgramExercise,
        exerciseName: String,
        percent1RM: Double?,
        bodyweightOnly: Bool
    ) -> GeneratedProgramExercise {
        GeneratedProgramExercise(
            exercise: exerciseName,
            sets: exercise.sets,
            reps: exercise.reps,
            percent1RM: percent1RM,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: bodyweightOnly
        )
    }

    private static func replacementExercise(
        for exercise: GeneratedProgramExercise,
        existingExercises: [GeneratedProgramExercise]
    ) -> GeneratedProgramExercise? {
        let existingNames = Set(existingExercises.map { $0.exercise.lowercased() })
        let targetDefinition = trainingExerciseCatalog.first {
            $0.id.compare(exercise.exercise, options: [.caseInsensitive]) == .orderedSame
        }
        let targetPattern = targetDefinition?.movementPattern ?? inferredMovementPattern(for: exercise.exercise)
        let targetTags = Set(targetDefinition?.equipmentTags ?? [])
        let targetCategory = targetDefinition?.categoryLabel.lowercased()

        let candidates = trainingExerciseCatalog
            .filter { candidate in
                candidate.movementPattern == targetPattern
                    && !existingNames.contains(candidate.id.lowercased())
                    && !candidate.equipmentTags.contains(.cardio)
            }
            .sorted { lhs, rhs in
                swapCandidateScore(
                    lhs,
                    targetTags: targetTags,
                    targetCategory: targetCategory,
                    targetBodyweightOnly: exercise.bodyweightOnly,
                    targetIsMaxTrackable: targetDefinition?.isMaxTrackable ?? isWeightliftingExercise(exercise.exercise)
                ) > swapCandidateScore(
                    rhs,
                    targetTags: targetTags,
                    targetCategory: targetCategory,
                    targetBodyweightOnly: exercise.bodyweightOnly,
                    targetIsMaxTrackable: targetDefinition?.isMaxTrackable ?? isWeightliftingExercise(exercise.exercise)
                )
            }

        guard let replacement = candidates.first else { return nil }
        return copyProgramExercise(
            exercise,
            exerciseName: replacement.id,
            percent1RM: replacement.isMaxTrackable ? exercise.percent1RM : nil,
            bodyweightOnly: replacement.bodyweightOnly
        )
    }

    private static func inferredMovementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step-up") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") || lower.contains("swing") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") || lower.contains("dip") {
            return .push
        }
        if lower.contains("pull") || lower.contains("row") || lower.contains("curl") {
            return .pull
        }
        if lower.contains("carry") || lower.contains("walk") {
            return .carry
        }
        if lower.contains("plank") || lower.contains("bug") || lower.contains("sit-up") || lower.contains("v-up") {
            return .core
        }
        return .conditioning
    }

    private static func swapCandidateScore(
        _ candidate: TrainingExerciseDefinition,
        targetTags: Set<TrainingEquipmentTag>,
        targetCategory: String?,
        targetBodyweightOnly: Bool,
        targetIsMaxTrackable: Bool
    ) -> Int {
        var score = 0
        if !targetTags.isDisjoint(with: candidate.equipmentTags) { score += 20 }
        if candidate.categoryLabel.lowercased() == targetCategory { score += 10 }
        if candidate.bodyweightOnly == targetBodyweightOnly { score += 5 }
        if candidate.isMaxTrackable == targetIsMaxTrackable { score += 3 }
        return score
    }

    private func loadAdaptationContext() async -> ProgramSessionAdaptationContext {
        async let cyclePhase = loadCyclePhase()
        async let cycleConfidence = loadCycleConfidence()
        async let injuries = loadInjuries()
        async let painLogs = loadPainLogs()
        async let equipment = loadDefaultEquipment()
        async let recentEffortRPE = loadRecentEffortRPE()

        let (
            resolvedPhase,
            resolvedConfidence,
            resolvedInjuries,
            resolvedPain,
            resolvedEquipment,
            resolvedEffortRPE
        ) = await (
            cyclePhase,
            cycleConfidence,
            injuries,
            painLogs,
            equipment,
            recentEffortRPE
        )

        let painIntensity = resolvedPain
            .sorted(by: { $0.date > $1.date })
            .first?
            .intensity
        let deload = DeloadDetectionService.recommendation(
            recentPainLogs: resolvedPain
        ).isRecommended

        return ProgramSessionAdaptationContext(
            cyclePhase: resolvedPhase,
            injuries: resolvedInjuries,
            painIntensity: painIntensity,
            equipment: resolvedEquipment,
            cycleConfidence: resolvedConfidence,
            deloadRecommended: deload,
            recentEffortRPE: resolvedEffortRPE
        )
    }

    private func loadCyclePhase() async -> CyclePhase? {
        // Fast path: active manual period = menstrual phase
        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            if manualRecords.contains(where: { $0.isActive }) {
                return .menstrual
            }
        } catch { /* continue */ }

        var periodLogs: [PeriodLog] = []

        if healthClient.isAvailable {
            do {
                try? await healthClient.requestStandardAuthorization()
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo, endDate: nil, limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            } catch { /* no HealthKit */ }
        }

        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            for log in manualRecords.map({ $0.toPeriodLog() }) {
                let isDuplicate = periodLogs.contains {
                    abs($0.startDate.timeIntervalSince(log.startDate)) < 86400
                }
                if !isDuplicate { periodLogs.append(log) }
            }
        } catch { /* no manual logs */ }

        guard !periodLogs.isEmpty else { return nil }

        var settings = CycleSettings()
        if let records = try? await dataClient.fetchAll(
            recordType: "CycleSettings"
        ) as [CycleSettingsRecord], let first = records.first {
            settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
        }

        if let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) {
            return status.currentPhase
        }
        return nil
    }

    private func loadInjuries() async -> [Injury] {
        (try? await dataClient.fetchAll(recordType: "Injury") as [Injury]) ?? []
    }

    private func loadCycleConfidence() async -> Double? {
        let logs: [PeriodLog] = (try? await dataClient.fetchAll(recordType: "PeriodLogRecord")) ?? []
        guard !logs.isEmpty else { return nil }
        return CyclePhaseHelper.calculateConfidence(
            periodLogCount: logs.count,
            lastPeriodStart: logs.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
        )
    }

    private func loadPainLogs() async -> [DailyPainLog] {
        (try? await dataClient.fetchAll(recordType: "DailyPainLog") as [DailyPainLog]) ?? []
    }

    private func loadDefaultEquipment() async -> EquipmentAccess {
        let records: [UserSettingsRecord] = (try? await dataClient.fetchAll(recordType: "UserSettings")) ?? []
        return records.last?.defaultEquipment ?? .fullGym
    }

    private func loadRecentEffortRPE() async -> Int? {
        let records: [WorkoutEffortLog] = (try? await dataClient.fetchAll(recordType: "WorkoutEffortLog")) ?? []
        return records.sorted(by: { $0.dateCreated > $1.dateCreated }).first?.rpe
    }

    private func loadMaxes() async -> [OneRepMaxRecord] {
        (try? await dataClient.fetchAll(recordType: "OneRepMaxRecord") as [OneRepMaxRecord]) ?? []
    }
}

// MARK: - ProgramsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var programs: [ProgramListItem] = []
    @Published var errorMessage: String?
    /// Tracks which program is currently being enrolled so the row can show a spinner.
    @Published var enrollingProgramId: String? = nil
    @Published var recommendationGoal: PrimaryGoal = .strength
    @Published var recommendationExperience: ExperienceLevel = .intermediate
    @Published var recommendationDaysPerWeek: Int = 3
    @Published var recommendationEquipment: EquipmentAccess = .fullGym
    @Published var programRecommendations: [ProgramRecommendation] = []

    /// Persists across CloudKit re-fetches so optimistically-enrolled programs
    /// stay visible even while CloudKit index lag hasn't caught up yet.
    private var knownEnrolledIds: Set<String> = []
    private var hasLoadedRecommendationDefaults = false

    private let dataClient: DataClientProtocol
    private let contentClient: ContentClientProtocol

    // Maps known program display names to their template type so the detail view
    // can regenerate sessions without storing the full program in CloudKit.
    private static let nameToTemplate: [String: ProgramTemplate] = [
        "The First Margarita": .firstMargarita,
        "The First Margarita Strength Program": .firstMargarita,
        "Beginner Strength": .beginnerStrength,
        "4-Week Beginner Strength Plan": .beginnerStrength,
        "Dumbbell Strength": .dumbbellStrength,
        "6-Week Dumbbell Strength Plan": .dumbbellStrength,
        "Glutes, Core & Conditioning": .glutesCoreConditioning,
        "8-Week Glutes, Core & Conditioning Plan": .glutesCoreConditioning,
        "Russian Squat": .russianSquat,
        "6-Week Russian Squat Program": .russianSquat,
    ]

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        contentClient: ContentClientProtocol? = nil
    ) {
        self.dataClient = dataClient
        self.contentClient = contentClient ?? BundledContentProvider()
    }

    func loadPrograms() async {
        isLoading = true
        await loadRecommendationDefaultsIfNeeded()

        var enrolledIds: Set<String> = []
        do {
            let enrolled = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]
            enrolledIds = Set(enrolled.filter(\.isActive).map(\.id))
        } catch {
            errorMessage = "We couldn't load programs. Pull to refresh or try again in a moment."
        }
        // Merge with locally-known enrolled IDs so CloudKit index lag doesn't
        // wipe enrollment state on every tab switch.
        enrolledIds = enrolledIds.union(knownEnrolledIds)

        do {
            let contentPrograms = try await contentClient.fetchPrograms()
            programs = contentPrograms.map { prog in
                ProgramListItem(
                    id: prog.id,
                    name: prog.name,
                    category: prog.category,
                    description: prog.description,
                    durationWeeks: prog.durationWeeks,
                    sessionsPerWeek: prog.sessionsPerWeek,
                    difficulty: prog.difficulty,
                    isEnrolled: enrolledIds.contains(prog.id),
                    template: Self.nameToTemplate[prog.name],
                    printablePDFURL: prog.printablePDFURL
                )
            }
        } catch {
            programs = ProgramTemplate.allCases.map { template in
                let program = generateProgram(template: template, name: templateDisplayName(template))
                return ProgramListItem(
                    id: program.id,
                    name: program.name,
                    category: program.category,
                    description: program.description,
                    durationWeeks: program.durationWeeks,
                    sessionsPerWeek: program.sessionsPerWeek,
                    difficulty: program.difficulty,
                    isEnrolled: enrolledIds.contains(program.id),
                    template: template,
                    printablePDFURL: template.printablePDFURL
                )
            }
        }

        isLoading = false
    }

    var topRecommendation: ProgramRecommendation? {
        programRecommendations.first
    }

    func updateRecommendations() {
        programRecommendations = ProgramRecommendationService.recommend(
            goal: recommendationGoal,
            experience: recommendationExperience,
            daysPerWeek: recommendationDaysPerWeek,
            equipment: recommendationEquipment
        )
    }

    func enrollInProgram(_ programId: String) async {
        enrollingProgramId = programId
        defer { enrollingProgramId = nil }

        do {
            let record = EnrolledProgramRecord(
                id: programId,
                name: programs.first(where: { $0.id == programId })?.name ?? "",
                isActive: true
            )
            try await dataClient.save(record, recordType: "EnrolledProgramRecord")
            knownEnrolledIds.insert(programId)

            // Update local state immediately. CloudKit query indexes may not reflect
            // a fresh write instantly (especially under rate limiting), so re-fetching
            // can silently return stale empty results and leave the row showing as unenrolled.
            programs = programs.map { p in
                guard p.id == programId else { return p }
                return ProgramListItem(
                    id: p.id,
                    name: p.name,
                    category: p.category,
                    description: p.description,
                    durationWeeks: p.durationWeeks,
                    sessionsPerWeek: p.sessionsPerWeek,
                    difficulty: p.difficulty,
                    isEnrolled: true,
                    template: p.template,
                    printablePDFURL: p.printablePDFURL
                )
            }
        } catch {
            errorMessage = "We couldn't enroll you in that program. Check your connection and try again."
        }
    }

    private func templateDisplayName(_ template: ProgramTemplate) -> String {
        template.displayName
    }

    private func loadRecommendationDefaultsIfNeeded() async {
        guard !hasLoadedRecommendationDefaults else {
            updateRecommendations()
            return
        }
        hasLoadedRecommendationDefaults = true

        if let settings = (try? await dataClient.fetchAll(recordType: "UserSettings") as [UserSettingsRecord])?.last {
            recommendationGoal = PrimaryGoal(rawValue: settings.primaryGoal) ?? .strength
            recommendationExperience = ExperienceLevel(rawValue: settings.experienceLevel) ?? .intermediate
            recommendationEquipment = settings.defaultEquipment
        }

        updateRecommendations()
    }
}

private extension PrimaryGoal {
    static let recommendationChoices: [PrimaryGoal] = [.strength, .hypertrophy, .endurance, .weightLoss]

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle"
        case .endurance: return "Endurance"
        case .weightLoss: return "Conditioning"
        }
    }
}

private extension ExperienceLevel {
    static let recommendationChoices: [ExperienceLevel] = [.beginner, .intermediate, .advanced]

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}
