import SwiftUI
import SwiftData

/// Dashboard — home screen showing active enrollment, cycle phase, and recent workouts.
struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var showSkipConfirmation = false
    @State private var workoutToDelete: CompletedWorkout?
    @State private var showDeleteConfirmation = false

    init(viewModel: DashboardViewModel = DashboardViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    greetingHeader
                    if viewModel.currentCyclePhase == .menstrual {
                        MenstrualPhaseCard()
                    }
                    if let state = Self.activeEnrollmentState(
                        enrollment: viewModel.activeEnrollment,
                        program: viewModel.activeProgram
                    ) {
                        ActiveEnrollmentCard(
                            enrollment: state.enrollment,
                            program: state.program,
                            nextSession: viewModel.nextSession,
                            cyclePhase: viewModel.currentCyclePhase,
                            onSkip: { showSkipConfirmation = true }
                        )
                        .accessibilityIdentifier("active-cycle-card")
                    } else {
                        NoEnrollmentCard()
                    }
                    recentWorkoutsSection
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Dashboard")
        .navigationDestination(for: StartWorkoutDestination.self) { dest in
            if let program = viewModel.activeProgram {
                WorkoutExecutionView(
                    viewModel: WorkoutExecutionViewModel(
                        session: dest.session,
                        enrollment: dest.enrollment,
                        program: program,
                        oneRepMaxes: viewModel.oneRepMaxes,
                        barbellWeightKg: viewModel.barbellWeightKg,
                        weightUnit: viewModel.weightUnit
                    )
                )
            }
        }
        .confirmationDialog("Skip this workout?", isPresented: $showSkipConfirmation, titleVisibility: .visible) {
            Button("Mark as Skipped") {
                viewModel.skipWorkout(
                    modelContext: modelContext,
                    userID: appState.currentUserID ?? "",
                    recordAs: .markAsSkipped
                )
            }
            Button("Don't Record") {
                viewModel.skipWorkout(
                    modelContext: modelContext,
                    userID: appState.currentUserID ?? "",
                    recordAs: .noRecord
                )
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Skipping will advance you to the next workout in the program.")
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    viewModel.deleteWorkout(workout, modelContext: modelContext)
                    workoutToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { workoutToDelete = nil }
        } message: {
            Text("This will remove the workout record and roll back your program progress by one session.")
        }
        .task { await viewModel.load(modelContext: modelContext) }
        .refreshable(action: Self.refreshAction(viewModel: viewModel, modelContext: modelContext))
    }

    @MainActor
    private final class RefreshPerformer: @unchecked Sendable {
        let viewModel: DashboardViewModel
        let modelContext: ModelContext

        init(viewModel: DashboardViewModel, modelContext: ModelContext) {
            self.viewModel = viewModel
            self.modelContext = modelContext
        }

        func refresh() async {
            await viewModel.load(modelContext: modelContext)
        }
    }

    @MainActor
    static func refreshAction(viewModel: DashboardViewModel, modelContext: ModelContext) -> @Sendable () async -> Void {
        let performer = RefreshPerformer(viewModel: viewModel, modelContext: modelContext)
        return { await performer.refresh() }
    }

    @MainActor
    static func performRefresh(viewModel: DashboardViewModel, modelContext: ModelContext) async {
        await viewModel.load(modelContext: modelContext)
    }

    // MARK: - Subviews

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(AppTheme.Fonts.heading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Date.now, style: .date)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            if let phase = viewModel.currentCyclePhase {
                CyclePhaseBadge(phase: phase)
            }
        }
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Recent Workouts")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)

            if Self.shouldShowEmptyRecentWorkouts(viewModel.recentWorkouts) {
                Text("No workouts yet. Enroll in a program to get started.")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .padding(.vertical, AppTheme.Spacing.sm)
            } else {
                ForEach(viewModel.recentWorkouts) { workout in
                    WorkoutHistoryRow(workout: workout)
                        .contextMenu {
                            Button(role: .destructive) {
                                workoutToDelete = workout
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Workout", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var greeting: String {
        Self.greeting(for: Date(), calendar: .current)
    }

    static func activeEnrollmentState(
        enrollment: EnrolledProgram?,
        program: Program?
    ) -> (enrollment: EnrolledProgram, program: Program)? {
        guard let enrollment, let program else { return nil }
        return (enrollment, program)
    }

    static func shouldShowEmptyRecentWorkouts(_ workouts: [CompletedWorkout]) -> Bool {
        workouts.isEmpty
    }

    static func greeting(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - ActiveEnrollmentCard

struct ActiveEnrollmentCard: View {
    let enrollment: EnrolledProgram
    let program: Program
    let nextSession: ProgramSession?
    let cyclePhase: CyclePhase?
    var onSkip: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Program name + week progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Text("Week \(enrollment.currentWeek) of \(program.durationWeeks)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.separator)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.accentOrange)
                        .frame(width: geo.size.width * progressFraction, height: 8)
                }
            }
            .frame(height: 8)

            // Next session
            if let session = nextSession {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("UP NEXT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)
                    Text(session.sessionName)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Text(session.focus)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                    if cyclePhase == .menstrual {
                        Text("Load adjusted for your phase — go at your pace.")
                            .font(AppTheme.Fonts.caption)
                            .italic()
                            .foregroundStyle(AppTheme.Colors.warmRose)
                    }
                }

                NavigationLink(value: StartWorkoutDestination(enrollment: enrollment, session: session)) {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("start-workout-button")

                if let onSkip {
                    Button(action: onSkip) {
                        Label("Skip Workout", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("skip-workout-button")
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private var progressFraction: Double {
        Self.progressFraction(currentWeek: enrollment.currentWeek, durationWeeks: program.durationWeeks)
    }

    static func progressFraction(currentWeek: Int, durationWeeks: Int) -> Double {
        let total = Double(durationWeeks)
        guard total > 0 else { return 0 }
        return min(1.0, Double(currentWeek - 1) / total)
    }
}

// MARK: - StartWorkoutDestination

struct StartWorkoutDestination: Hashable {
    let enrollment: EnrolledProgram
    let session: ProgramSession

    func hash(into hasher: inout Hasher) { hasher.combine(enrollment.id) }
    static func == (lhs: StartWorkoutDestination, rhs: StartWorkoutDestination) -> Bool {
        lhs.enrollment.id == rhs.enrollment.id && lhs.session.sessionID == rhs.session.sessionID
    }
}

// MARK: - NoEnrollmentCard

struct NoEnrollmentCard: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
            Text("No Active Program")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)
            Text("Browse and enroll in a program to start training.")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }
}

// MARK: - CyclePhaseBadge

struct CyclePhaseBadge: View {
    let phase: CyclePhase

    var body: some View {
        Text(phase.displayName)
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy)   // navy passes WCAG AA on all badge colors
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        Self.badgeColor(for: phase)
    }

    static func badgeColor(for phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual:  return AppTheme.Colors.warmRose
        case .follicular: return Color(red: 0.20, green: 0.55, blue: 0.80)
        case .ovulation:  return AppTheme.Colors.accentOrange
        case .luteal:     return Color(red: 0.50, green: 0.35, blue: 0.65)
        }
    }
}

// MARK: - WorkoutHistoryRow

struct WorkoutHistoryRow: View {
    let workout: CompletedWorkout

    var isSkipped: Bool { workout.notes == "skipped" }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Session \(workout.day) — Week \(workout.week)")
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(isSkipped ? AppTheme.Colors.navy.opacity(0.4) : AppTheme.Colors.navy)
                    if isSkipped {
                        Text("Skipped")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.cream)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.navy.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                Text(workout.completedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            Spacer()
            if !isSkipped {
                Text("\(workout.durationSeconds / 60)m")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - MenstrualPhaseCard

struct MenstrualPhaseCard: View {
    static let supportiveMessages = [
        "Take it easy today — your program has been gently adjusted.",
        "Rest is training. Today's lighter load is by design.",
        "Listen to your body. Lighter weights, same dedication.",
        "Your strength is still here. Today we train smarter.",
    ]

    static func message(for date: Date = .now) -> String {
        let day = Calendar.current.component(.day, from: date)
        return supportiveMessages[day % supportiveMessages.count]
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.Colors.warmRose)
            VStack(alignment: .leading, spacing: 4) {
                Text("Menstrual Phase")
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Self.message())
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.warmRose.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }
}
