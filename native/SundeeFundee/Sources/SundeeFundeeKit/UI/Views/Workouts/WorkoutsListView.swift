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
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.workouts) { workout in
                    WorkoutRow(workout: workout)
                        .onTapGesture {
                            viewModel.selectedWorkout = workout
                        }
                }
            }
            .padding(AppTheme.Spacing.lg)
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

// MARK: - NewWorkoutView (Placeholder)

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("New Workout")
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Create a new workout or generate one with AI")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                Button("Generate AI Workout") {
                    // Handle AI generation
                }
                .artDecoButton(style: .accent)

                Button("Create Custom Workout") {
                    // Handle custom creation
                }
                .artDecoButton(style: .secondary)
            }
            .padding(AppTheme.Spacing.xl)
            .artDecoBackground()
            .navigationTitle("New Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - WorkoutsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class WorkoutsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var workouts: [WorkoutListItem] = []
    @Published var selectedWorkout: WorkoutListItem?
    @Published var showingNewWorkout: Bool = false

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
        self.dataClient = dataClient
    }

    func loadWorkouts() async {
        isLoading = true

        do {
            let records = try await dataClient.fetchAll(
                recordType: "CompletedWorkoutRecord"
            ) as [CompletedWorkoutRecord]

            workouts = records.map { record in
                WorkoutListItem(
                    id: record.id,
                    name: record.name,
                    date: record.date,
                    duration: record.duration,
                    exercises: record.exerciseNames,
                    isComplete: record.isComplete
                )
            }
        } catch {
            print("Error loading workouts: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Model Types (shared in SharedModels.swift)
