import SwiftUI
import SwiftData

/// Browse and start shared workouts from the community database (free tier feature).
struct WorkoutDatabaseView: View {
    @State private var sharedWorkouts: [SharedWorkoutTemplate] = []
    @State private var isLoading = false
    @State private var selectedFocus: String?
    @State private var maxDuration: Int = 90

    private let repository: any SharedWorkoutRepository

    init(repository: any SharedWorkoutRepository) {
        self.repository = repository
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Shared Workouts")
                        .font(AppTheme.Fonts.heading)
                    Text("Browse and try community-created AI workouts")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.md)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sharedWorkouts.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
                        Text("No shared workouts available")
                            .font(AppTheme.Fonts.body)
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(sharedWorkouts) { template in
                                workoutCard(template)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                }
            }
        }
        .task {
            await loadWorkouts()
        }
    }

    @ViewBuilder
    private func workoutCard(_ template: SharedWorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(template.workout.questionnaire.focus.displayName)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .textCase(.uppercase)

                    Text(String(template.durationMinutes) + " min")
                        .font(AppTheme.Fonts.body)
                }

                Spacer()

                Text(String(template.workout.exercises.count) + " exercises")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }

            Text(template.workout.coachingSummary)
                .font(AppTheme.Fonts.caption)
                .lineLimit(2)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.8))

            NavigationLink(
                destination: SharedWorkoutDetailView(workout: template.workout)
            ) {
                Text("View & Start")
                    .font(AppTheme.Fonts.caption)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.accentOrange)
                    .foregroundStyle(AppTheme.Colors.cream)
                    .cornerRadius(AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.navy.opacity(0.05))
        .cornerRadius(AppTheme.Spacing.sm)
    }

    private func loadWorkouts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let focus = selectedFocus
            sharedWorkouts = try await repository.fetchShared(
                focus: focus,
                maxDuration: maxDuration
            )
        } catch {
            print("Failed to load shared workouts: \(error)")
        }
    }
}

// MARK: - SharedWorkoutDetailView

struct SharedWorkoutDetailView: View {
    let workout: GeneratedWorkout

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text(workout.coachingSummary)
                        .font(AppTheme.Fonts.body)
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Colors.navy.opacity(0.05))
                        .cornerRadius(AppTheme.Spacing.sm)

                    ForEach(workout.exercises) { exercise in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(exercise.name)
                                .font(AppTheme.Fonts.subheading)
                            Text("\(exercise.sets) sets × \(exercise.reps)")
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.7))
                            if let notes = exercise.notes {
                                Text(notes)
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle(workout.questionnaire.focus.displayName)
    }
}
