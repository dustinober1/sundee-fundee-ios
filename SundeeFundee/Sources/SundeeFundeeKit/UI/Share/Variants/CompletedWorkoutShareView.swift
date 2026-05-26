import SwiftUI

// MARK: - CompletedWorkoutShareView
//
// Branded share card for a completed workout. Supports story (9:16) and
// square (1:1) aspects. Replaces the legacy WorkoutShareCardView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CompletedWorkoutShareView: View {
    let workout: Workout
    let personalRecords: Set<String>
    let aspect: ShareCardAspect
    let shareURL: URL
    let privacyOptions: SharePrivacyOptions

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                headerSection
                divider
                statsRow
                divider
                exerciseList
                Spacer(minLength: 0)
                ShareFooter(palette: .onDark)
            }
            #if canImport(UIKit)
            if #available(iOS 18.0, *) {
                QRBadge(url: shareURL, size: aspect.size.width * 0.10)
                    .padding(AppTheme.Spacing.lg)
            }
            #endif
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, AppTheme.Spacing.lg)
        .frame(width: aspect.size.width, height: aspect.size.height)
        .background(AppTheme.Background.navy)
    }

    // MARK: Layout knobs

    private var horizontalPadding: CGFloat {
        aspect == .story ? AppTheme.Spacing.xl : AppTheme.Spacing.xxl
    }

    private var topPadding: CGFloat {
        aspect == .story ? AppTheme.Spacing.xxxl : AppTheme.Spacing.xxl
    }

    private var displayedExerciseLimit: Int {
        aspect == .story ? 6 : 4
    }

    // MARK: Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(workout.name)
                .font(AppTheme.Typography.displayMedium)
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

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(workout.duration)", label: "min")
            statColumn(value: "\(workout.exercises.count)", label: "exercises")
            statColumn(value: "\(totalSetCount)", label: "sets")
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.white)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.gold)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(Array(displayedExercises.enumerated()), id: \.offset) { _, exercise in
                exerciseRow(exercise)
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.cream)
                        .lineLimit(1)
                    if personalRecords.contains(exercise.name) {
                        Text("★ PR")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
                if let best = bestSet(for: exercise) {
                    Text(bestSetText(best))
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Text.cream.opacity(0.75))
                }
            }
            Spacer()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.Accent.gold)
            .opacity(0.3)
            .frame(height: 1)
    }

    // MARK: Computed

    private var formattedDate: String {
        privacyOptions.redactedDateText(for: workout.date)
    }

    private var totalSetCount: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    private var displayedExercises: [Exercise] {
        Array(workout.exercises.prefix(displayedExerciseLimit))
    }

    private func bestSet(for exercise: Exercise) -> (weight: Double, reps: Int)? {
        let completed = exercise.targetSets.filter { $0.isComplete }
        guard !completed.isEmpty else { return nil }
        return completed
            .map { set in
                let w = set.completedWeight ?? set.prescribedWeight
                let r = set.actualReps ?? set.reps
                return (weight: w, reps: r, volume: w * Double(r))
            }
            .max(by: { $0.volume < $1.volume })
            .map { (weight: $0.weight, reps: $0.reps) }
    }

    private func bestSetText(_ set: (weight: Double, reps: Int)) -> String {
        let w = set.weight
        let weightStr: String
        if w >= 1000 {
            weightStr = String(format: "%.1fk", w / 1000)
        } else if w == floor(w) {
            weightStr = "\(Int(w))"
        } else {
            weightStr = String(format: "%.1f", w)
        }
        return "\(weightStr) × \(set.reps) reps"
    }
}
