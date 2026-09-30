import SwiftUI

// MARK: - WorkoutPreviewSheet
//
// Presents a comprehensive summary of a generated or scheduled workout
// before the user commits to starting the active timer session.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let workout: Workout
    public let onStart: (Workout) -> Void

    public init(
        workout: Workout,
        onStart: @escaping (Workout) -> Void
    ) {
        self.workout = workout
        self.onStart = onStart
    }

    private var estimatedDurationMinutes: Int {
        if workout.duration > 0 {
            return workout.duration
        }
        let totalSets = workout.exercises.reduce(0) { $0 + $1.targetSets.count }
        return max(15, totalSets * 3 + workout.exercises.count * 2)
    }

    private var totalSetsCount: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header Overview
                    headerCard

                    // Exercise List
                    exerciseSection
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Background.cream.ignoresSafeArea())
            .navigationTitle("Workout Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text(workout.name)
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Text.primary)

                HStack(spacing: AppTheme.Spacing.md) {
                    statPill(
                        icon: "figure.strengthtraining.traditional",
                        label: "\(workout.exercises.count) Exercises"
                    )
                    statPill(
                        icon: "repeat",
                        label: "\(totalSetsCount) Sets"
                    )
                    statPill(
                        icon: "clock",
                        label: "~\(estimatedDurationMinutes) min"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statPill(icon: String, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Accent.orange)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Background.cream.opacity(0.8))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    // MARK: - Exercise Section

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Exercises")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                exercisePreviewCard(exercise: exercise, index: index + 1)
            }
        }
    }

    private func exercisePreviewCard(exercise: Exercise, index: Int) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    // Index Badge
                    Text("\(index)")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)
                        .frame(width: 24, height: 24)
                        .background(AppTheme.Background.navy.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text(exercise.category.rawValue)
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.orange)

                            if let group = exercise.grouping {
                                Text("·")
                                    .foregroundColor(AppTheme.Text.secondary)
                                Text(group.label)
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                        }
                    }

                    Spacer()

                    Text("\(Int(exercise.restMinutes * 60))s rest")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Divider()
                    .background(AppTheme.Text.secondary.opacity(0.2))

                // Sets breakdown
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(Array(exercise.targetSets.enumerated()), id: \.element.id) { setIndex, set in
                        HStack {
                            Text("Set \(setIndex + 1)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)

                            Spacer()

                            Text("\(set.reps) reps")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            if set.prescribedWeight > 0 {
                                Text("@ \(Int(set.prescribedWeight)) lbs")
                                    .font(AppTheme.Typography.monoMedium)
                                    .foregroundColor(AppTheme.Accent.gold)
                            } else if exercise.bodyweight > 0 {
                                Text("(Bodyweight)")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Button {
                HapticFeedback.light()
                dismiss()
                onStart(workout)
            } label: {
                Text("Start Workout")
                    .font(AppTheme.Typography.labelLarge)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ArtDecoButtonStyle(style: .accent))
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Background.cream)
    }
}
