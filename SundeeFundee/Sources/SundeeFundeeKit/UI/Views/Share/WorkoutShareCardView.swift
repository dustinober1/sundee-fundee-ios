import SwiftUI

// MARK: - WorkoutShareCardView
//
// A static snapshot view designed for ImageRenderer output.
// Renders a styled Art Deco workout summary card at a fixed 400×500pt frame.
// Not part of the app's navigation hierarchy — exists purely to be rendered to a UIImage.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutShareCardView: View {
    let workout: Workout
    let personalRecords: Set<String>

    public init(
        workout: Workout,
        personalRecords: Set<String> = []
    ) {
        self.workout = workout
        self.personalRecords = personalRecords
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            artDecoDivider
            statsRow
            artDecoDivider
            exerciseList
            Spacer(minLength: 0)
            brandingSection
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.xxl)
        .padding(.bottom, AppTheme.Spacing.lg)
        .frame(width: 400, height: 500)
        .background(AppTheme.Background.navy)
        .drawingGroup()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(workout.name)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(formattedDate)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(workout.duration)", label: "min")
            statColumn(value: "\(exerciseCount)", label: "exercises")
            statColumn(value: "\(totalSetCount)", label: "sets")
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text(value)
                .font(AppTheme.Typography.monoMedium)
                .foregroundColor(AppTheme.Text.white)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.gold)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(Array(displayedExercises.enumerated()), id: \.offset) { _, exercise in
                exerciseRow(exercise)
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.cream)
                        .lineLimit(1)

                    if personalRecords.contains(exercise.name) {
                        Text("★ PR")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }

                if let bestSet = bestSet(for: exercise) {
                    Text(bestSetText(bestSet))
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Text.secondary.opacity(0.8))
                }
            }

            Spacer()
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        Text("SUNDEE FUNDEE")
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(AppTheme.Text.gold)
            .tracking(2)
    }

    // MARK: - Art Deco Divider

    private var artDecoDivider: some View {
        Rectangle()
            .fill(AppTheme.Accent.gold)
            .opacity(0.3)
            .frame(height: 1)
    }

    // MARK: - Computed Properties

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workout.date)
    }

    private var exerciseCount: Int {
        workout.exercises.count
    }

    private var totalSetCount: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    private var displayedExercises: [Exercise] {
        Array(workout.exercises.prefix(5))
    }

    // MARK: - Helpers

    private func bestSet(for exercise: Exercise) -> (weight: Double, reps: Int)? {
        let completedSets = exercise.targetSets.filter { $0.isComplete }
        guard !completedSets.isEmpty else { return nil }

        return completedSets
            .map { set in
                let weight = set.completedWeight ?? set.prescribedWeight
                let reps = set.actualReps ?? set.reps
                return (weight: weight, reps: reps, volume: weight * Double(reps))
            }
            .max(by: { $0.volume < $1.volume })
            .map { (weight: $0.weight, reps: $0.reps) }
    }

    private func bestSetText(_ set: (weight: Double, reps: Int)) -> String {
        let weightStr: String
        if set.weight >= 1000 {
            weightStr = String(format: "%.1fk", set.weight / 1000)
        } else if set.weight == floor(set.weight) {
            weightStr = "\(Int(set.weight))"
        } else {
            weightStr = String(format: "%.1f", set.weight)
        }
        return "\(weightStr) × \(set.reps) reps"
    }
}

// MARK: - Spacing Extension

extension AppTheme.Spacing {
    public static let xxs: CGFloat = 2
}

// MARK: - Preview

#if os(iOS)
@available(iOS 18.0, *)
#Preview("Workout Share Card") {
    let sampleWorkout = Workout(
        date: Date(),
        name: "Push Day",
        exercises: [
            Exercise(
                id: "1",
                name: "Bench Press",
                category: .compound,
                bodyweight: 0,
                targetSets: [
                    ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed, completedWeight: 185, actualReps: 5, isComplete: true),
                    ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed, completedWeight: 195, actualReps: 4, isComplete: true),
                ]
            ),
            Exercise(
                id: "2",
                name: "Overhead Press",
                category: .compound,
                bodyweight: 0,
                targetSets: [
                    ExerciseSet(reps: 8, prescribedWeight: 95, type: .fixed, completedWeight: 95, actualReps: 8, isComplete: true),
                ]
            ),
            Exercise(
                id: "3",
                name: "Incline Dumbbell Press",
                category: .compound,
                bodyweight: 0,
                targetSets: [
                    ExerciseSet(reps: 10, prescribedWeight: 60, type: .fixed, completedWeight: 65, actualReps: 10, isComplete: true),
                ]
            ),
        ],
        duration: 52,
        completedAt: Date()
    )

    WorkoutShareCardView(
        workout: sampleWorkout,
        personalRecords: ["Bench Press"]
    )
}
#endif
