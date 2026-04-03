import SwiftUI

// MARK: - WorkoutDetailView
//
// Displays a completed or in-progress workout with exercises, sets,
// weights, completion status, and total volume.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutDetailView: View {
    @StateObject private var viewModel: WorkoutDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(workoutId: String) {
        _viewModel = StateObject(wrappedValue: WorkoutDetailViewModel(workoutId: workoutId))
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
            if let workout = viewModel.workout, !workout.isComplete {
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") {
                        Task { await viewModel.completeWorkout() }
                    }
                    .artDecoButton(style: .accent)
                }
            }
        }
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
        HStack {
            Text("\(setNumber)")
                .font(AppTheme.Typography.monoMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .frame(width: 30, alignment: .leading)

            Text(repDisplay(set))
                .font(AppTheme.Typography.monoMedium)
                .foregroundColor(AppTheme.Text.primary)
                .frame(width: 50, alignment: .center)

            Text(weightDisplay(set.prescribedWeight))
                .font(AppTheme.Typography.monoMedium)
                .foregroundColor(AppTheme.Text.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            if set.isComplete {
                Text(actualDisplay(set))
                    .font(AppTheme.Typography.monoMedium)
                    .foregroundColor(AppTheme.Accent.gold)
                    .frame(maxWidth: .infinity, alignment: .center)
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
            .frame(width: 36)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
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

    private func weightDisplay(_ weight: Double) -> String {
        if weight == 0 { return "BW" }
        return "\(Int(weight)) lb"
    }

    private func actualDisplay(_ set: ExerciseSet) -> String {
        let weight = set.completedWeight ?? set.prescribedWeight
        let reps = set.actualReps ?? set.reps
        if weight == 0 { return "\(reps) reps" }
        return "\(Int(weight)) \u{00D7} \(reps)"
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
}

// MARK: - WorkoutDetailViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class WorkoutDetailViewModel: ObservableObject {
    @Published var workout: Workout?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let workoutId: String
    private let dataClient: DataClientProtocol

    init(
        workoutId: String,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.workoutId = workoutId
        self.dataClient = dataClient
    }

    func loadWorkout() async {
        isLoading = true
        do {
            let workouts = try await dataClient.fetchAll(
                recordType: "Workout"
            ) as [Workout]
            workout = workouts.first { $0.id == workoutId }
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
            // Default actual to prescribed values when completing
            if set.completedWeight == nil {
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
        workout.completedAt = Date()
        self.workout = workout

        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to complete workout: \(error.localizedDescription)"
        }
    }
}
