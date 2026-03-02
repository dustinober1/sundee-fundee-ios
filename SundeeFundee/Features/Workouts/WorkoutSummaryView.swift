import SwiftUI
import SwiftData

/// Post-workout summary showing stats, set breakdown, and auto-detected PRs.
struct WorkoutSummaryView: View {
    let workout: CompletedWorkout
    @State private var viewModel: WorkoutSummaryViewModel

    @State private var celebrationEvent: CelebrationEvent?

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
                    spicyRating
                    if !viewModel.newPRs.isEmpty || !viewModel.newConditioningPRs.isEmpty { prBanner }
                    setBreakdown
                    doneButton
                }
                .padding(AppTheme.Spacing.md)
            }
            if let event = celebrationEvent {
                CelebrationOverlayView(event: event, weightUnit: viewModel.weightUnit) {
                    celebrationEvent = nil
                }
            }
        }
        .navigationTitle("Workout Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.detectPRs(modelContext: modelContext)
            if !viewModel.newPRs.isEmpty || !viewModel.newConditioningPRs.isEmpty {
                NotificationCenter.default.post(name: .didSaveNewPRs, object: nil)
            }
            celebrationEvent = viewModel.primaryCelebrationEvent
        }
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
        }
    }

    private var spicyRating: some View {
        SpicyRatingView(rating: Bindable(viewModel).perceivedEffort)
            .onChange(of: viewModel.perceivedEffort) {
                viewModel.saveSpicyRating(modelContext: modelContext)
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
                    Text(WeightUnitConversion.formatWithUnit(kilograms: value, unit: viewModel.weightUnit))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                }
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy)
            }
            ForEach(viewModel.newConditioningPRs, id: \.0) { (exercise, value, scoringType) in
                HStack {
                    Text(exercise)
                    Spacer()
                    Text(scoringType.formatValue(value))
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
                    if let sets = viewModel.groupedSets[exercise] {
                        ForEach(sets, id: \.id) { set in
                            SetSummaryRow(set: set, weightUnit: viewModel.weightUnit)
                        }
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            }
        }
    }

    private var doneButton: some View {
        Button("Done", action: dismiss.callAsFunction)
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, AppTheme.Spacing.xl)
    }

    // MARK: - Formatting helpers

    private func formatDuration(_ secs: Int) -> String {
        let m = secs / 60
        return m < 60 ? "\(m)m" : "\(m / 60)h \(m % 60)m"
    }


}

// MARK: - SetSummaryRow

struct SetSummaryRow: View {
    let set: CompletedSet
    let weightUnit: WeightUnit

    init(set: CompletedSet, weightUnit: WeightUnit = .pounds) {
        self.set = set
        self.weightUnit = weightUnit
    }

    var body: some View {
        HStack {
            Text("Set \(set.setIndex + 1)")
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            Spacer()
            let repsDisplay = Self.repsDisplay(for: set)
            Text(repsDisplay.text)
                .foregroundStyle(repsDisplay.isFallback ? AppTheme.Colors.navy.opacity(0.5) : AppTheme.Colors.navy)
            if let kg = set.actualWeightKg {
                Text("@ \(WeightUnitConversion.format(kilograms: kg, unit: weightUnit, maximumFractionDigits: 1))\(weightUnit.symbol)")
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
        .font(AppTheme.Fonts.caption)
        .foregroundStyle(AppTheme.Colors.navy)
    }

    static func repsDisplay(for set: CompletedSet) -> (text: String, isFallback: Bool) {
        if let reps = set.actualReps {
            return ("\(reps) reps", false)
        }
        return (set.prescribedReps, true)
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class WorkoutSummaryViewModel {
    let workout: CompletedWorkout
    var newPRs: [(String, Double)] = []
    var newConditioningPRs: [(String, Double, ConditioningScoringType)] = []
    var groupedSets: [String: [CompletedSet]] = [:]
    var totalSets: Int = 0
    var totalVolumeKg: Double = 0
    var weightUnit: WeightUnit = .pounds
    var perceivedEffort: Int? = nil

    init(workout: CompletedWorkout) {
        self.workout = workout
        self.perceivedEffort = workout.perceivedEffort
    }

    func saveSpicyRating(modelContext: ModelContext) {
        workout.perceivedEffort = perceivedEffort
        try? modelContext.save()
    }

    func detectPRs(modelContext: ModelContext) async {
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        let liftRepo = SwiftDataLiftRepository(context: modelContext)
        let userRepo = SwiftDataUserRepository(context: modelContext)
        weightUnit = (try? userRepo.fetchCurrentUser())?.weightUnit ?? .pounds

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

        // Auto-detect conditioning PRs
        var detectedConditioningPRs: [(String, Double, ConditioningScoringType)] = []
        for (exercise, exerciseSets) in grouped {
            guard let scoringType = ConditioningExerciseCatalog.scoringType(for: exercise) else { continue }

            let bestValue: Double? = {
                switch scoringType {
                case .reps:
                    return exerciseSets.compactMap { $0.actualReps.map(Double.init) }.max()
                case .time:
                    return exerciseSets.compactMap { $0.actualTimeSeconds }.filter { $0 > 0 }.min()
                }
            }()

            guard let newValue = bestValue else { continue }

            let existing = try? liftRepo.fetchConditioningPR(exercise: exercise)
            if scoringType.isBetterThan(newValue: newValue, existingValue: existing?.bestValue) {
                let pr = ConditioningPR(
                    id: UUID().uuidString,
                    userID: workout.userID,
                    exerciseID: exercise,
                    scoringType: scoringType,
                    bestValue: newValue,
                    weightKg: exerciseSets.first?.actualWeightKg,
                    achievedAt: workout.completedAt,
                    workoutID: workout.id
                )
                try? liftRepo.saveConditioningPR(pr)
                detectedConditioningPRs.append((exercise, newValue, scoringType))
            }
        }
        newConditioningPRs = detectedConditioningPRs
    }

    var primaryCelebrationEvent: CelebrationEvent? {
        if let first = newPRs.first {
            return .newPersonalRecord(exerciseName: first.0, weightKg: first.1)
        }
        if let first = newConditioningPRs.first {
            return .newConditioningPR(exerciseName: first.0, value: first.1, scoringType: first.2)
        }
        return .workoutCompleted(durationSeconds: workout.durationSeconds)
    }
}
