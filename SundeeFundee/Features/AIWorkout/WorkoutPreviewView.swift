import SwiftUI

struct WorkoutPreviewView: View {
    @State var viewModel: WorkoutPreviewViewModel
    let userID: String
    var onStartWorkout: (GeneratedWorkout) -> Void = { _ in }
    var onRegenerate: () -> Void = {}

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    coachingCard
                    exerciseList
                    actionButtons
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Your Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleFavorite(userID: userID) }
                } label: {
                    Image(systemName: viewModel.workout.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.workout.isFavorite ? AppTheme.Colors.warmRose : AppTheme.Colors.navy)
                }
            }
        }
    }

    // MARK: - Coaching Summary

    private var coachingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation { viewModel.showCoachingSummary.toggle() }
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                    Text("Coaching Notes")
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Spacer()
                    Image(systemName: viewModel.showCoachingSummary ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            if viewModel.showCoachingSummary {
                Text(viewModel.workout.coachingSummary)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .cardStyle()
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(viewModel.workout.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: GeneratedExercise) -> some View {
        let isExpanded = viewModel.expandedExerciseID == exercise.id
        return VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button {
                withAnimation { viewModel.toggleExpanded(exerciseID: exercise.id) }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(AppTheme.Fonts.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.Colors.navy)
                        Text(WorkoutPreviewViewModel.exerciseSummary(exercise))
                            .font(AppTheme.Fonts.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .font(.caption)
                }
                .padding(AppTheme.Spacing.md)
            }

            if isExpanded {
                expandedContent(exercise)
            }
        }
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.card)
        .shadow(color: AppTheme.Colors.navy.opacity(0.05), radius: 2, y: 1)
    }

    private func expandedContent(_ exercise: GeneratedExercise) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Divider()

            if let reasoning = exercise.reasoning {
                Text(reasoning)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .italic()
            }

            if let notes = exercise.notes {
                Text(notes)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }

            if let rest = WorkoutPreviewViewModel.restLabel(exercise.restMinutes) {
                Text(rest)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            HStack {
                Spacer()
                Button(role: .destructive) {
                    withAnimation { viewModel.removeExercise(id: exercise.id) }
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(AppTheme.Fonts.caption)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                onStartWorkout(viewModel.workout)
            } label: {
                Text("Start Workout")
                    .font(AppTheme.Fonts.subheading)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.accentOrange)
            .disabled(viewModel.workout.exercises.isEmpty)

            Button {
                onRegenerate()
            } label: {
                Text("Regenerate")
                    .font(AppTheme.Fonts.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.Colors.navy)
        }
    }
}
