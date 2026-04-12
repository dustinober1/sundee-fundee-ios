import SwiftUI

// MARK: - WorkoutDetailView
//
// Displays a completed or in-progress workout with exercises, sets,
// weights, completion status, and total volume.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutDetailView: View {
    @StateObject private var viewModel: WorkoutDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?

    #if os(iOS)
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    #endif

    @State private var editingSetKey: String?
    @State private var editRepsInput: String = ""
    @State private var editWeightInput: String = ""

    public init(workoutId: String) {
        _viewModel = StateObject(wrappedValue: WorkoutDetailViewModel(workoutId: workoutId))
    }

    /// Initialise with a pre-loaded workout (e.g. one just created) to skip
    /// the CloudKit fetch entirely and avoid index-lag "not found" errors.
    public init(workout: Workout) {
        _viewModel = StateObject(wrappedValue: WorkoutDetailViewModel(workout: workout))
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.workout == nil {
                ProgressView("Loading workout...")
            } else if let workout = viewModel.workout {
                workoutContent(workout)
            } else {
                Text("Workout not found")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
        .navigationTitle(viewModel.workout?.name ?? "Workout")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if let workout = viewModel.workout {
                if workout.isComplete {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Button {
                                Task {
                                    if let session = await viewModel.redoWorkout() {
                                        activeWorkoutSession = session
                                    }
                                }
                            } label: {
                                Label("Redo", systemImage: "arrow.counterclockwise")
                            }
                            .accessibilityLabel("Redo this workout")

                            #if os(iOS)
                            Button {
                                renderShareCard(workout: workout)
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share workout")
                            #endif
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Finish") {
                            Task { await viewModel.completeWorkout() }
                        }
                        .artDecoButton(style: .accent)
                        .accessibilityHint("Complete all remaining sets and finish the workout")
                    }
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(
                        viewModel.workout?.name ?? "Workout",
                        image: Image(uiImage: image)
                    )
                )
                .presentationDetents([.medium])
                .padding()
            }
        }
        .fullScreenCover(item: $activeWorkoutSession) { session in
            ActiveWorkoutView(viewModel: session)
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            activeWorkoutSession = nil
        }
        #endif
        .task {
            await viewModel.loadWorkout()
        }
    }

    // MARK: - Workout Content

    private func workoutContent(_ workout: Workout) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Summary Header
                summaryCard(workout)

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesCard(notes)
                }

                // Exercises
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseCard(exercise, exerciseIndex: index)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ workout: Workout) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(workout.date, style: .date)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        if workout.isComplete {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Accent.gold)
                        } else {
                            Label("In Progress", systemImage: "circle.dashed")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Accent.orange)
                        }
                    }

                    Spacer()

                    if workout.duration > 0 {
                        VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                            Text("\(workout.duration)")
                                .font(AppTheme.Typography.displayMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Text("min")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }

                Divider()
                    .background(AppTheme.Accent.gold.opacity(0.3))

                HStack(spacing: AppTheme.Spacing.lg) {
                    StatCard(
                        value: "\(workout.exercises.count)",
                        label: "Exercises"
                    )

                    StatCard(
                        value: "\(totalSets(workout))",
                        label: "Sets"
                    )

                    StatCard(
                        value: formatVolume(workout.totalVolume),
                        label: "Volume"
                    )
                }
            }
        }
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label("Notes", systemImage: "note.text")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                Text(notes)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)
            }
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ exercise: Exercise, exerciseIndex: Int) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Exercise Header
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(exercise.name)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        HStack(spacing: AppTheme.Spacing.sm) {
                            Text(exercise.category.rawValue)
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Accent.gold)

                            if exercise.restMinutes > 0 {
                                Text("\u{2022}")
                                    .foregroundColor(AppTheme.Text.secondary)
                                Text("\(exercise.restMinutes, specifier: "%.1f") min rest")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                    }

                    Spacer()

                    completionBadge(for: exercise)
                }

                // Exercise Notes
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .italic()
                }

                // Sets Header
                HStack {
                    Text("Set")
                        .frame(width: 30, alignment: .leading)
                    Text("Reps")
                        .frame(width: 50, alignment: .center)
                    Text("Weight")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Actual")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("")
                        .frame(width: 36)
                }
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

                // Sets
                ForEach(Array(exercise.targetSets.enumerated()), id: \.element.id) { setIndex, set in
                    setRow(set, setNumber: setIndex + 1, exerciseIndex: exerciseIndex, setIndex: setIndex)
                }
            }
        }
    }

    // MARK: - Set Row

    private func setRow(_ set: ExerciseSet, setNumber: Int, exerciseIndex: Int, setIndex: Int) -> some View {
        let exercises = viewModel.workout?.exercises ?? []
        let isBodyweight = exerciseIndex < exercises.count ? exercises[exerciseIndex].bodyweight > 0 : false
        let setKey = "\(exerciseIndex)-\(setIndex)"
        let isEditing = editingSetKey == setKey

        return VStack(spacing: 0) {
            HStack {
                Text("\(setNumber)")
                    .font(AppTheme.Typography.monoMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .frame(width: 30, alignment: .leading)

                Text(repDisplay(set))
                    .font(AppTheme.Typography.monoMedium)
                    .foregroundColor(AppTheme.Text.primary)
                    .frame(width: 50, alignment: .center)

                Text(weightDisplay(set.prescribedWeight, isBodyweight: isBodyweight, percentage: set.prescribedPercentage))
                    .font(AppTheme.Typography.monoMedium)
                    .foregroundColor(AppTheme.Text.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if set.isComplete {
                    Text(actualDisplay(set, isBodyweight: isBodyweight))
                        .font(AppTheme.Typography.monoMedium)
                        .foregroundColor(AppTheme.Accent.gold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .onTapGesture {
                            editRepsInput = "\(set.actualReps ?? set.reps)"
                            editWeightInput = "\(Int(set.completedWeight ?? set.prescribedWeight))"
                            editingSetKey = setKey
                        }
                } else {
                    Text("--")
                        .font(AppTheme.Typography.monoMedium)
                        .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Button {
                    Task {
                        await viewModel.toggleSetComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    }
                } label: {
                    Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(set.isComplete ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Set \(setNumber), \(repDisplay(set)) reps at \(weightDisplay(set.prescribedWeight, isBodyweight: isBodyweight, percentage: set.prescribedPercentage)). \(set.isComplete ? "Completed" : "Not completed")")
                .frame(width: 36)
            }

            // Inline edit row for completed sets
            if isEditing {
                HStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reps")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)
                        TextField("Reps", text: $editRepsInput)
                            .font(AppTheme.Typography.monoMedium)
                            .padding(AppTheme.Spacing.xs)
                            .background(AppTheme.Background.cream.opacity(0.5))
                            .cornerRadius(AppTheme.CornerRadius.small)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                    .frame(maxWidth: .infinity)

                    if !isBodyweight {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weight")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Text.secondary)
                            TextField("Weight", text: $editWeightInput)
                                .font(AppTheme.Typography.monoMedium)
                                .padding(AppTheme.Spacing.xs)
                                .background(AppTheme.Background.cream.opacity(0.5))
                                .cornerRadius(AppTheme.CornerRadius.small)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Button("Save") {
                        let newReps = Int(editRepsInput)
                        let newWeight = Double(editWeightInput)
                        Task {
                            await viewModel.updateSet(
                                exerciseIndex: exerciseIndex,
                                setIndex: setIndex,
                                actualReps: newReps,
                                completedWeight: newWeight
                            )
                        }
                        editingSetKey = nil
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                    Button("Cancel") {
                        editingSetKey = nil
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                }
                .padding(.top, AppTheme.Spacing.xs)
                .padding(.leading, 30)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .animation(.easeInOut(duration: 0.2), value: editingSetKey)
    }

    // MARK: - Helpers

    private func completionBadge(for exercise: Exercise) -> some View {
        let completed = exercise.targetSets.filter(\.isComplete).count
        let total = exercise.targetSets.count

        return Text("\(completed)/\(total)")
            .font(AppTheme.Typography.monoMedium)
            .foregroundColor(completed == total ? AppTheme.Accent.gold : AppTheme.Text.secondary)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                completed == total
                    ? AppTheme.Accent.goldLight
                    : AppTheme.Background.cream.opacity(0.5)
            )
            .cornerRadius(AppTheme.CornerRadius.small)
    }

    private func repDisplay(_ set: ExerciseSet) -> String {
        if let actual = set.actualReps, set.isComplete {
            return "\(actual)"
        }
        switch set.type {
        case .fixed:
            return "\(set.reps)"
        case .amrap:
            return "AMRAP"
        case .range(let min, let max):
            return "\(min)-\(max)"
        case .text(let value):
            return value
        }
    }

    private func weightDisplay(_ weight: Double, isBodyweight: Bool, percentage: Double? = nil) -> String {
        if weight > 0 { return "\(Int(weight)) lb" }
        if isBodyweight { return "BW" }
        if let pct = percentage { return "\(Int(pct * 100))%" }
        return "--"
    }

    private func actualDisplay(_ set: ExerciseSet, isBodyweight: Bool) -> String {
        let weight = set.completedWeight ?? set.prescribedWeight
        let reps = set.actualReps ?? set.reps
        if isBodyweight { return "\(reps) reps" }
        if weight > 0 { return "\(Int(weight)) \u{00D7} \(reps)" }
        return "\(reps) reps"
    }

    private func totalSets(_ workout: Workout) -> Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 10000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }

    // MARK: - Share Card

    #if os(iOS)
    private func renderShareCard(workout: Workout) {
        let card = WorkoutShareCardView(
            workout: workout,
            personalRecords: viewModel.personalRecords
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareImage = renderer.uiImage
        showingShareSheet = true
    }
    #endif
}

// MARK: - WorkoutDetailViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class WorkoutDetailViewModel: ObservableObject {
    @Published var workout: Workout?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var personalRecords: Set<String> = []

    private let workoutId: String
    private let dataClient: DataClientProtocol

    init(
        workoutId: String,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.workoutId = workoutId
        self.dataClient = dataClient
    }

    /// Initialise with a pre-loaded workout to skip the CloudKit fetch.
    /// Used when navigating from a just-created workout (e.g. program session start)
    /// so CloudKit index lag can't produce a "not found" result.
    init(
        workout: Workout,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.workoutId = workout.id
        self.workout = workout
        self.dataClient = dataClient
    }

    func loadWorkout() async {
        // Skip fetch if the workout was injected directly (already have it).
        guard workout == nil else {
            if let workout, workout.isComplete {
                await detectPersonalRecords()
            }
            return
        }
        isLoading = true
        do {
            let workouts = try await dataClient.fetchAll(
                recordType: "Workout"
            ) as [Workout]
            workout = workouts.first { $0.id == workoutId }
            if let workout, workout.isComplete {
                await detectPersonalRecords()
            }
        } catch {
            errorMessage = "Failed to load workout: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func toggleSetComplete(exerciseIndex: Int, setIndex: Int) async {
        guard var workout = workout else { return }
        guard exerciseIndex < workout.exercises.count,
              setIndex < workout.exercises[exerciseIndex].targetSets.count else { return }

        var set = workout.exercises[exerciseIndex].targetSets[setIndex]
        set.isComplete.toggle()

        if set.isComplete {
            if set.completedWeight == nil, set.prescribedWeight > 0 {
                set.completedWeight = set.prescribedWeight
            }
            if set.actualReps == nil {
                set.actualReps = set.reps
            }
        }

        workout.exercises[exerciseIndex].targetSets[setIndex] = set
        self.workout = workout

        // Persist
        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func completeWorkout() async {
        guard var workout = workout else { return }

        for i in workout.exercises.indices {
            for j in workout.exercises[i].targetSets.indices {
                var set = workout.exercises[i].targetSets[j]
                if !set.isComplete {
                    set.isComplete = true
                    if set.completedWeight == nil, set.prescribedWeight > 0 {
                        set.completedWeight = set.prescribedWeight
                    }
                    if set.actualReps == nil {
                        set.actualReps = set.reps
                    }
                    workout.exercises[i].targetSets[j] = set
                }
            }
        }

        workout.completedAt = Date()
        self.workout = workout

        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to complete workout: \(error.localizedDescription)"
        }
    }

    // MARK: - Edit Set

    func updateSet(exerciseIndex: Int, setIndex: Int, actualReps: Int?, completedWeight: Double?) async {
        guard var workout = workout else { return }
        guard exerciseIndex < workout.exercises.count,
              setIndex < workout.exercises[exerciseIndex].targetSets.count else { return }

        if let reps = actualReps {
            workout.exercises[exerciseIndex].targetSets[setIndex].actualReps = reps
        }
        if let weight = completedWeight {
            workout.exercises[exerciseIndex].targetSets[setIndex].completedWeight = weight
        }

        self.workout = workout

        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Redo Workout

    func redoWorkout() async -> ActiveWorkoutSessionViewModel? {
        guard let original = workout else { return nil }

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
            notes: original.notes
        )

        do {
            try await dataClient.save(newWorkout, recordType: "Workout")
        } catch {
            // Non-critical — continue to active session
        }

        return ActiveWorkoutSessionViewModel(workout: newWorkout)
    }

    // MARK: - PR Detection

    func detectPersonalRecords() async {
        do {
            let records: [OneRepMaxRecord] = try await dataClient.fetchAll(recordType: "OneRepMaxRecord")
            guard let workout = workout else { return }
            var prs: Set<String> = []
            for exercise in workout.exercises {
                let maxCompletedWeight = exercise.targetSets
                    .compactMap { $0.completedWeight }
                    .max() ?? 0
                guard maxCompletedWeight > 0 else { continue }
                let previousRecord = records
                    .filter { $0.exerciseName == exercise.name }
                    .max(by: { $0.weight < $1.weight })
                if let previous = previousRecord {
                    if maxCompletedWeight > previous.weight {
                        prs.insert(exercise.name)
                    }
                }
                // If no previous record exists and they lifted > 0, it's their first time logging — not a PR
            }
            personalRecords = prs
        } catch {
            // Non-critical — PR highlights are best-effort
            personalRecords = []
        }
    }
}
