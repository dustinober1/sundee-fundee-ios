import SwiftUI

// MARK: - WorkoutsListView
//
// List of completed workouts with filtering and search.
// Matches the web app's workouts feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutsListView: View {
    @StateObject private var viewModel = WorkoutsListViewModel()

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
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingNewWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .task {
                await viewModel.loadWorkouts()
            }
            .refreshable {
                await viewModel.loadWorkouts()
            }
            .sheet(isPresented: $viewModel.showingNewWorkout) {
                NewWorkoutView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Accent.gold.opacity(0.5))

            Text("No Workouts Yet")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Start your first workout to begin tracking your progress")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Button("Start Workout") {
                viewModel.showingNewWorkout = true
            }
            .artDecoButton(style: .primary)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    // MARK: - Workout List

    private var workoutList: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workoutId: workout.id)) {
                    WorkoutRowContent(workout: workout)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let workout = viewModel.workouts[index]
                    Task { await viewModel.deleteWorkout(id: workout.id) }
                }
            }
        }
        .listStyle(.plain)
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
                    }
                }

                Text(workout.date, style: .date)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)

                if let duration = workout.duration {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))

                        Text("\(duration) min")
                            .font(AppTheme.Typography.bodySmall)
                    }
                    .foregroundColor(AppTheme.Text.secondary)
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
                }
            }

            Text(workout.date, style: .date)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

            if let duration = workout.duration {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("\(duration) min")
                        .font(AppTheme.Typography.bodySmall)
                }
                .foregroundColor(AppTheme.Text.secondary)
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
struct WorkoutListItem: Identifiable {
    let id: String
    let name: String
    let date: Date
    let duration: Int?
    let exercises: [String]
    let isComplete: Bool
}

// MARK: - NewWorkoutView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewWorkoutViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
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

                    // Start Workout Button
                    Button {
                        Task {
                            await viewModel.createWorkout()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .accent)
                    .disabled(!viewModel.canCreate)
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
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showingExercisePicker) {
                ExercisePickerView { selectedNames in
                    viewModel.addExercises(selectedNames)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyExerciseState: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.Accent.gold.opacity(0.5))

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

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
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

    func createWorkout() async {
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
            print("Error saving workout: \(error)")
        }
    }
}

// MARK: - WorkoutsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class WorkoutsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var workouts: [WorkoutListItem] = []
    @Published var showingNewWorkout: Bool = false

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
        self.dataClient = dataClient
    }

    func loadWorkouts() async {
        isLoading = true

        do {
            let records = try await dataClient.fetchAll(
                recordType: "Workout"
            ) as [Workout]

            workouts = records
                .sorted { $0.date > $1.date }
                .map { workout in
                    WorkoutListItem(
                        id: workout.id,
                        name: workout.name,
                        date: workout.date,
                        duration: workout.duration > 0 ? workout.duration : nil,
                        exercises: workout.exercises.map(\.name),
                        isComplete: workout.isComplete
                    )
                }
        } catch {
            print("Error loading workouts: \(error)")
        }

        isLoading = false
    }

    func deleteWorkout(id: String) async {
        do {
            try await dataClient.delete(recordType: "Workout", id: id)
            workouts.removeAll { $0.id == id }
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}
