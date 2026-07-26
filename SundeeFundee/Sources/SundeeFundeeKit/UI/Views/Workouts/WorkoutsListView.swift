import SwiftUI

// MARK: - WorkoutsListView
//
// List of completed workouts with filtering and search.
// Matches the web app's workouts feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutsListView: View {
    @StateObject private var viewModel = WorkoutsListViewModel()
    @State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?
    @StateObject private var bestNextViewModel = BestNextWorkoutViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.workouts.isEmpty {
                    ProgressView("Loading workouts...")
                } else if viewModel.workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                bestNextEntry
            }
            .navigationTitle("Workouts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingNewWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Workout")
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingNewWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Workout")
                }
                #endif
            }
            .task {
                await viewModel.loadWorkouts()
            }
            .refreshable {
                await viewModel.loadWorkouts()
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
                activeWorkoutSession = nil
                Task { await viewModel.loadWorkouts() }
            }
            .sheet(isPresented: $viewModel.showingNewWorkout) {
                NewWorkoutView {
                    viewModel.showingNewWorkout = false
                }
            }
            #if os(iOS)
            .fullScreenCover(item: $activeWorkoutSession) { session in
                ActiveWorkoutView(viewModel: session)
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

    /// Read-only guidance at the history screen's start-workout entry. The
    /// generated session is still launched through the typed adjustment model;
    /// completed history is never changed.
    private var bestNextEntry: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Start a guided 20-minute session")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.primary)
            Text("Best Next adapts effort when recovery calls for a lighter or active-recovery workout. You can always use your standard session.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                startQuickWorkout()
            } label: {
                Label("Best Next 20 Min", systemImage: "timer")
            }
            .disabled(bestNextViewModel.isBuilding)
            .accessibilityHint("Starts a read-only guided workout and applies any recovery adjustment")

            Button {
                startQuickWorkout(useStandardSession: true)
            } label: {
                Label("Use Standard Session", systemImage: "figure.strengthtraining.traditional")
            }
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(AppTheme.Accent.orange)
            .disabled(bestNextViewModel.isBuilding)
            .accessibilityLabel("Use Standard Session")
            .accessibilityHint("Starts a 20-minute workout without recovery adjustments")
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Background.cream)
    }

    private func startQuickWorkout(useStandardSession: Bool = false) {
        Task {
            bestNextViewModel.updateGuestState(authViewModel.isGuest)
            if let result = await bestNextViewModel.buildWorkout(useStandardSession: useStandardSession) {
                activeWorkoutSession = ActiveWorkoutSessionViewModel(workout: result.workout)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
                .accessibilityHidden(true)

            Text("No Workouts Yet")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Start your first workout to begin tracking your progress")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Button("Start This Workout") {
                viewModel.showingNewWorkout = true
            }
            .artDecoButton(style: .primary)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    // MARK: - Workout List

    private var workoutList: some View {
        List {
            if let resumeCandidate = viewModel.resumeCandidate {
                Section {
                    NavigationLink(destination: WorkoutDetailView(workoutId: resumeCandidate.id)) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "arrow.forward.circle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.Accent.orange)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Resume \(resumeCandidate.name)")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                Text("Incomplete workouts stay resumable for 24 hours.")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                    .listRowBackground(AppTheme.Accent.goldLight.opacity(0.35))
                }
            }

            ForEach(viewModel.workouts) { item in
                NavigationLink {
                    destinationView(for: item)
                } label: {
                    WorkoutRowContent(workout: item)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading) {
                    if item.isRedoable, case let .workout(workoutId) = item.source {
                        Button {
                            Task {
                                if let session = await viewModel.redoWorkout(id: workoutId) {
                                    activeWorkoutSession = session
                                }
                            }
                        } label: {
                            Label("Redo", systemImage: "arrow.counterclockwise")
                        }
                        .tint(AppTheme.Accent.orange)
                    }
                }
                .deleteDisabled(item.source.isBenchmark)
            }
            .onDelete { indexSet in
                let itemsToDelete: [WorkoutListItem] = indexSet.compactMap { index in
                    viewModel.workouts.indices.contains(index) ? viewModel.workouts[index] : nil
                }

                Task {
                    for item in itemsToDelete {
                        guard case let .workout(workoutId) = item.source else { continue }
                        await viewModel.deleteWorkout(id: workoutId)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func destinationView(for item: WorkoutListItem) -> some View {
        switch item.source {
        case .workout(let workoutId):
            WorkoutDetailView(workoutId: workoutId)
        case .benchmark(_, let benchmarkId, _):
            BenchmarkDetailView(benchmarkId: benchmarkId)
        }
    }
}

// MARK: - WorkoutRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct WorkoutRow: View {
    let workout: WorkoutListItem

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text(workout.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    if workout.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityLabel("Completed")
                    }
                }

                Text(workout.date, style: .date)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)

                if let duration = workout.duration {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .accessibilityHidden(true)

                        Text("\(duration) min")
                            .font(AppTheme.Typography.bodySmall)
                    }
                    .foregroundColor(AppTheme.Text.secondary)
                    .accessibilityElement(children: .combine)
                }

                if !workout.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Exercises")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        ForEach(workout.exercises.prefix(3), id: \.self) { exercise in
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Circle()
                                    .fill(AppTheme.Accent.gold.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                    .accessibilityHidden(true)

                                Text(exercise)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.primary)
                            }
                        }

                        if workout.exercises.count > 3 {
                            Text("+ \(workout.exercises.count - 3) more")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WorkoutRowContent (for List rows)

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct WorkoutRowContent: View {
    let workout: WorkoutListItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(workout.name)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Spacer()

                if workout.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Accent.gold)
                        .accessibilityLabel("Completed")
                }
            }

            Text(workout.date, style: .date)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

            if case let .benchmark(_, _, scoreText) = workout.source {
                Label(scoreText, systemImage: "trophy.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Accent.gold)
                    .accessibilityLabel("Benchmark score \(scoreText)")
            }

            if let duration = workout.duration {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text("\(duration) min")
                        .font(AppTheme.Typography.bodySmall)
                }
                .foregroundColor(AppTheme.Text.secondary)
                .accessibilityElement(children: .combine)
            }

            if !workout.exercises.isEmpty {
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(workout.exercises.prefix(3), id: \.self) { exercise in
                        Text(exercise)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(AppTheme.Accent.goldLight)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }

                    if workout.exercises.count > 3 {
                        Text("+\(workout.exercises.count - 3)")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - WorkoutListItem

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
enum WorkoutHistorySource: Equatable, Sendable {
    case workout(workoutId: String)
    case benchmark(resultId: String, benchmarkId: String, scoreText: String)

    var isWorkout: Bool {
        if case .workout = self { return true }
        return false
    }

    var isBenchmark: Bool {
        if case .benchmark = self { return true }
        return false
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct WorkoutListItem: Identifiable {
    let id: String
    let name: String
    let date: Date
    let duration: Int?
    let exercises: [String]
    let isComplete: Bool
    let source: WorkoutHistorySource
    let isRedoable: Bool
}

// MARK: - NewWorkoutView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewWorkoutViewModel()

    private let onClose: (() -> Void)?
    @State private var showingAIWorkout: Bool = false
    @State private var isDismissingAIWorkout: Bool = false
    @State private var pendingCloseAfterAIDismiss: Bool = false
    @State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Coach Plan option
                    Button {
                        pendingCloseAfterAIDismiss = false
                        showingAIWorkout = true
                    } label: {
                        ArtDecoCard {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Accent.orange)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Build Coach Plan")
                                        .font(AppTheme.Typography.headlineMedium)
                                        .foregroundColor(AppTheme.Text.primary)

                                    Text("Personalized to your cycle phase and energy")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.Text.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(AppTheme.Accent.gold.opacity(0.3))
                            .frame(height: 1)
                        Text("or build your own")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                        Rectangle()
                            .fill(AppTheme.Accent.gold.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Workout Name
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Workout Name")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            TextField("e.g. Upper Body Push", text: $viewModel.workoutName)
                                .font(AppTheme.Typography.bodyMedium)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Background.cream.opacity(0.5))
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }

                    // Exercises
                    if viewModel.exercises.isEmpty {
                        emptyExerciseState
                    } else {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseConfigCard(exercise, index: index)
                        }
                    }

                    // Add Exercise Button
                    Button {
                        viewModel.showingExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                    }
                    .artDecoButton(style: .secondary)

                    // Notes
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Notes (optional)")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            TextField("Workout notes...", text: $viewModel.notes, axis: .vertical)
                                .font(AppTheme.Typography.bodyMedium)
                                .lineLimit(2...4)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Background.cream.opacity(0.5))
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }

                    // Start workout button
                    Button {
                        Task {
                            if let workout = await viewModel.createWorkout() {
                                activeWorkoutSession = ActiveWorkoutSessionViewModel(workout: workout)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start This Workout")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .accent)
                    .disabled(!viewModel.canCreate)
                    .opacity(viewModel.canCreate ? 1.0 : 0.4)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .artDecoBackground()
            .navigationTitle("New Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isDismissingAIWorkout {
                        Button("Cancel") { close() }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingExercisePicker) {
                ExercisePickerView { selectedNames in
                    viewModel.addExercises(selectedNames)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingAIWorkout, onDismiss: handleAIWorkoutDismissed) {
                AIWorkoutView {
                    isDismissingAIWorkout = true
                    showingAIWorkout = false
                }
            }
            #else
            .sheet(isPresented: $showingAIWorkout, onDismiss: handleAIWorkoutDismissed) {
                AIWorkoutView {
                    isDismissingAIWorkout = true
                    showingAIWorkout = false
                }
            }
            #endif
            #if os(iOS)
            .fullScreenCover(item: $activeWorkoutSession) { session in
                ActiveWorkoutView(viewModel: session)
            }
            #endif
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
                activeWorkoutSession = nil
                close()
            }
        }
    }

    private func close() {
        if isDismissingAIWorkout {
            pendingCloseAfterAIDismiss = true
            return
        }

        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func handleAIWorkoutDismissed() {
        isDismissingAIWorkout = false

        guard pendingCloseAfterAIDismiss else { return }

        pendingCloseAfterAIDismiss = false
        close()
    }

    // MARK: - Empty State

    private var emptyExerciseState: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
                    .accessibilityHidden(true)

                Text("No exercises added yet")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                Text("Tap 'Add Exercise' to pick from the catalog")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.xl)
        }
    }

    // MARK: - Exercise Config Card

    private func exerciseConfigCard(_ config: ExerciseConfig, index: Int) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header with name and remove button
                HStack {
                    Text(config.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    Button {
                        viewModel.removeExercise(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(config.name)")
                }

                // Sets & Reps
                HStack(spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Sets")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        HStack {
                            Button {
                                viewModel.adjustSets(at: index, delta: -1)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease sets")
                            .disabled(config.sets <= 1)

                            Text("\(config.sets)")
                                .font(AppTheme.Typography.monoLarge)
                                .foregroundColor(AppTheme.Text.primary)
                                .frame(width: 30, alignment: .center)

                            Button {
                                viewModel.adjustSets(at: index, delta: 1)
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase sets")
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Reps")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        HStack {
                            Button {
                                viewModel.adjustReps(at: index, delta: -1)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Decrease reps")
                            .disabled(config.reps <= 1)

                            Text("\(config.reps)")
                                .font(AppTheme.Typography.monoLarge)
                                .foregroundColor(AppTheme.Text.primary)
                                .frame(width: 30, alignment: .center)

                            Button {
                                viewModel.adjustReps(at: index, delta: 1)
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Increase reps")
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Weight")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        HStack {
                            TextField("0", text: Binding(
                                get: { config.weight > 0 ? "\(Int(config.weight))" : "" },
                                set: { viewModel.setWeight(at: index, value: Double($0) ?? 0) }
                            ))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .font(AppTheme.Typography.monoLarge)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .padding(AppTheme.Spacing.xs)
                            .background(AppTheme.Background.cream.opacity(0.5))
                            .cornerRadius(AppTheme.CornerRadius.small)

                            Text("lb")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ExerciseConfig

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ExerciseConfig: Identifiable {
    let id: String
    let name: String
    var sets: Int
    var reps: Int
    var weight: Double
}

// MARK: - NewWorkoutViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class NewWorkoutViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var exercises: [ExerciseConfig] = []
    @Published var notes: String = ""
    @Published var showingExercisePicker: Bool = false

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    var canCreate: Bool {
        !workoutName.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    func addExercises(_ names: [String]) {
        for name in names {
            guard !exercises.contains(where: { $0.name == name }) else { continue }
            exercises.append(ExerciseConfig(
                id: UUID().uuidString,
                name: name,
                sets: 3,
                reps: 8,
                weight: 0
            ))
        }
    }

    func removeExercise(at index: Int) {
        guard index < exercises.count else { return }
        exercises.remove(at: index)
    }

    func adjustSets(at index: Int, delta: Int) {
        guard index < exercises.count else { return }
        exercises[index].sets = max(1, exercises[index].sets + delta)
    }

    func adjustReps(at index: Int, delta: Int) {
        guard index < exercises.count else { return }
        exercises[index].reps = max(1, exercises[index].reps + delta)
    }

    func setWeight(at index: Int, value: Double) {
        guard index < exercises.count else { return }
        exercises[index].weight = max(0, value)
    }

    func createWorkout() async -> Workout? {
        let workout = Workout(
            date: Date(),
            name: workoutName.trimmingCharacters(in: .whitespaces),
            exercises: exercises.map { config in
                Exercise(
                    id: UUID().uuidString,
                    name: config.name,
                    category: isWeightliftingExercise(config.name) ? .compound : .accessory,
                    bodyweight: config.weight == 0 ? 1.0 : 0.0,
                    targetSets: (0..<config.sets).map { _ in
                        ExerciseSet(
                            reps: config.reps,
                            prescribedWeight: config.weight,
                            type: .fixed
                        )
                    },
                    restMinutes: config.weight > 0 ? assignRestMinutes(bodyweight: false, reps: "\(config.reps)") : 1.0
                )
            },
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            // Error is non-critical; proceed to active session anyway
        }
        return workout
    }
}

// MARK: - WorkoutsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class WorkoutsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var workouts: [WorkoutListItem] = []
    @Published var resumeCandidate: WorkoutListItem?
    @Published var showingNewWorkout: Bool = false
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol
    private let healthClient: HealthClientProtocol

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client
    ) {
        self.dataClient = dataClient
        self.healthClient = healthClient
    }

    func loadWorkouts() async {
        isLoading = true

        do {
            async let workoutsTask: [Workout] = dataClient.fetchAll(
                recordType: "Workout",
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )
            async let benchmarkResultsTask: [BenchmarkResult] = dataClient.fetchAll(
                recordType: "BenchmarkResult",
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )

            let (workoutRecords, benchmarkResults) = try await (workoutsTask, benchmarkResultsTask)

            let staleThreshold = Date().addingTimeInterval(-24 * 60 * 60)
            let workoutItems = workoutRecords.map { workout in
                WorkoutListItem(
                    id: workout.id,
                    name: workout.name,
                    date: workout.date,
                    duration: workout.duration > 0 ? workout.duration : nil,
                    exercises: workout.exercises.map(\.name),
                    isComplete: workout.isComplete,
                    source: .workout(workoutId: workout.id),
                    isRedoable: workout.isComplete
                )
            }

            let benchmarkItems = benchmarkResults.map { result in
                let benchmark = BenchmarkCatalog.benchmark(id: result.benchmarkId)

                let scoreText: String
                if let benchmark {
                    scoreText = BenchmarkScoreFormatter.string(for: result.score, scoringType: benchmark.scoringType)
                } else {
                    scoreText = "\(Int(result.score))"
                }

                let duration: Int?
                if let benchmark, benchmark.scoringType == .time, result.score.isFinite, result.score >= 0 {
                    duration = Int((result.score / 60.0).rounded(.up))
                } else {
                    duration = nil
                }

                return WorkoutListItem(
                    id: "benchmark-\(result.id)",
                    name: "\(result.benchmarkName) Benchmark",
                    date: result.date,
                    duration: duration,
                    exercises: [],
                    isComplete: true,
                    source: .benchmark(resultId: result.id, benchmarkId: result.benchmarkId, scoreText: scoreText),
                    isRedoable: false
                )
            }

            workouts = (workoutItems + benchmarkItems)
                .sorted { $0.date > $1.date }

            resumeCandidate = workoutItems.first { !$0.isComplete && $0.date >= staleThreshold }

            // Auto-complete stale workouts in background (non-blocking)
            let staleWorkouts = workoutRecords.filter { $0.completedAt == nil && $0.date < staleThreshold }
            if !staleWorkouts.isEmpty {
                let client = dataClient
                Task.detached {
                    for var workout in staleWorkouts {
                        workout.completedAt = workout.date
                        try? await client.save(workout, recordType: "Workout")
                    }
                }
            }
        } catch {
            errorMessage = "We couldn't load your workout history. Pull to refresh or try again in a moment."
        }

        isLoading = false
    }

    func deleteWorkout(id: String) async {
        do {
            try await dataClient.delete(recordType: "Workout", id: id)
            workouts.removeAll { $0.id == id }
        } catch {
            errorMessage = "We couldn't delete that workout. Check your connection and try again."
        }
    }

    func redoWorkout(id: String) async -> ActiveWorkoutSessionViewModel? {
        do {
            let allWorkouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            guard let original = allWorkouts.first(where: { $0.id == id }) else {
                errorMessage = "Workout not found"
                return nil
            }

            // Create a fresh copy with reset sets
            let newWorkout = Workout(
                date: Date(),
                name: original.name,
                exercises: original.exercises.map { exercise in
                    Exercise(
                        id: UUID().uuidString,
                        name: exercise.name,
                        category: exercise.category,
                        bodyweight: exercise.bodyweight,
                        targetSets: exercise.targetSets.map { set in
                            ExerciseSet(
                                reps: set.reps,
                                prescribedWeight: set.completedWeight ?? set.prescribedWeight,
                                prescribedPercentage: set.prescribedPercentage,
                                type: set.type
                            )
                        },
                        notes: exercise.notes,
                        restMinutes: exercise.restMinutes
                    )
                },
                notes: original.notes,
                kind: original.kind
            )

            try await dataClient.save(newWorkout, recordType: "Workout")
            return ActiveWorkoutSessionViewModel(
                workout: newWorkout,
                dataClient: dataClient,
                healthClient: healthClient
            )
        } catch {
            errorMessage = "We couldn't restart that workout. Open it again and try once more."
            return nil
        }
    }
}
