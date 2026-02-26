import SwiftUI
import SwiftData

/// Post-workout summary showing stats, set breakdown, and auto-detected PRs.
struct WorkoutSummaryView: View {
    let workout: CompletedWorkout
    @State private var viewModel: WorkoutSummaryViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(workout: CompletedWorkout) {
        self.workout = workout
        _viewModel = State(initialValue: WorkoutSummaryViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    completionHeader
                    statsRow
                    if !viewModel.newPRs.isEmpty { prBanner }
                    setBreakdown
                    doneButton
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Workout Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task { await viewModel.detectPRs(modelContext: modelContext) }
    }

    // MARK: - Subviews

    private var completionHeader: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.accentOrange)
            Text("Great Work! 💪")
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatBadge(label: "Duration", value: formatDuration(workout.durationSeconds))
            StatBadge(label: "Sets", value: "\(viewModel.totalSets)")
            StatBadge(label: "Volume", value: formatVolume(viewModel.totalVolumeKg))
        }
    }

    private var prBanner: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("New Personal Records!", systemImage: "trophy.fill")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.accentOrange)
            ForEach(viewModel.newPRs, id: \.0) { (exercise, value) in
                HStack {
                    Text(exercise)
                    Spacer()
                    Text(String(format: "%.1f kg", value))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                }
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.accentOrange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private var setBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Set Breakdown")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)

            ForEach(viewModel.groupedSets.keys.sorted(), id: \.self) { exercise in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(exercise)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy)
                    ForEach(viewModel.groupedSets[exercise] ?? [], id: \.id) { set in
                        SetSummaryRow(set: set)
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            }
        }
    }

    private var doneButton: some View {
        Button("Done") { dismiss() }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, AppTheme.Spacing.xl)
    }

    // MARK: - Formatting helpers

    private func formatDuration(_ secs: Int) -> String {
        let m = secs / 60
        return m < 60 ? "\(m)m" : "\(m / 60)h \(m % 60)m"
    }

    private func formatVolume(_ kg: Double) -> String {
        kg >= 1000 ? String(format: "%.1ft", kg / 1000) : "\(Int(kg))kg"
    }
}

// MARK: - SetSummaryRow

struct SetSummaryRow: View {
    let set: CompletedSet

    var body: some View {
        HStack {
            Text("Set \(set.setIndex + 1)")
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            Spacer()
            if let reps = set.actualReps {
                Text("\(reps) reps")
            } else {
                Text(set.prescribedReps)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            if let kg = set.actualWeightKg {
                Text("@ \(kg == kg.rounded() ? "\(Int(kg))" : String(format: "%.1f", kg))kg")
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
        .font(AppTheme.Fonts.caption)
        .foregroundStyle(AppTheme.Colors.navy)
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class WorkoutSummaryViewModel {
    let workout: CompletedWorkout
    var newPRs: [(String, Double)] = []
    var groupedSets: [String: [CompletedSet]] = [:]
    var totalSets: Int = 0
    var totalVolumeKg: Double = 0

    init(workout: CompletedWorkout) {
        self.workout = workout
    }

    func detectPRs(modelContext: ModelContext) async {
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        let liftRepo = SwiftDataLiftRepository(context: modelContext)

        guard let sets = try? workoutRepo.fetchSets(for: workout) else { return }

        // Build grouped set view
        var grouped: [String: [CompletedSet]] = [:]
        for set in sets {
            grouped[set.exerciseName, default: []].append(set)
        }
        groupedSets = grouped
        totalSets = sets.count
        totalVolumeKg = sets.compactMap { set -> Double? in
            guard let reps = set.actualReps, let kg = set.actualWeightKg else { return nil }
            return Double(reps) * kg
        }.reduce(0, +)

        // Auto-detect PRs: compute Epley 1RM per exercise, compare to stored max
        var detectedPRs: [(String, Double)] = []
        for (exercise, exerciseSets) in grouped {
            let best1RM = exerciseSets.compactMap { set -> Double? in
                guard let reps = set.actualReps, reps > 0,
                      let kg = set.actualWeightKg, kg > 0 else { return nil }
                return EpleyFormula.estimated1RM(weight: kg, reps: reps)
            }.max()

            guard let new1RM = best1RM else { continue }

            let existing = try? liftRepo.fetchOneRepMax(exercise: exercise)
            if EpleyFormula.isPR(newEstimate: new1RM, currentMax: existing?.weightKg) {
                // Save updated 1RM
                let orm = OneRepMax(
                    id: UUID().uuidString,
                    userID: workout.userID,
                    exerciseID: exercise,
                    weightKg: new1RM,
                    date: workout.completedAt
                )
                try? liftRepo.saveOneRepMax(orm)
                detectedPRs.append((exercise, new1RM))
            }
        }
        newPRs = detectedPRs
    }
}
