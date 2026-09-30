import SwiftUI

// MARK: - WarmupCalculatorSheet

/// Interactive Art Deco sheet displaying a progressive warmup ramp for barbell movements.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WarmupCalculatorSheet: View {
    let exerciseName: String
    @State private var workingWeight: Double
    @State private var targetReps: Int
    @State private var unit: WeightUnit
    @State private var selectedBar: BarbellType
    @State private var completedSetIds: Set<UUID> = []
    @State private var selectedSetId: UUID?

    @Environment(\.dismiss) private var dismiss

    public init(
        exerciseName: String = "Barbell Exercise",
        workingWeight: Double,
        targetReps: Int = 5,
        unit: WeightUnit = .lbs,
        initialBar: BarbellType = .standardOlympic
    ) {
        self.exerciseName = exerciseName
        _workingWeight = State(initialValue: max(0, workingWeight))
        _targetReps = State(initialValue: max(1, targetReps))
        _unit = State(initialValue: unit)
        _selectedBar = State(initialValue: initialBar)
    }

    private var barWeight: Double {
        selectedBar.weight(for: unit)
    }

    private var progression: WarmupProgression {
        WarmupProgressionService.generateProgression(
            targetWeight: workingWeight,
            barWeight: barWeight,
            unit: unit,
            targetReps: targetReps
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerCard
                    barbellPickerCard
                    warmupSetsCard
                    if let selectedSet = progression.sets.first(where: { $0.id == selectedSetId }) {
                        selectedSetDetailCard(for: selectedSet)
                    }
                    guidanceCard
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Warmup Ramp")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Accent.gold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(exerciseName.uppercased())
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Accent.gold)
                    .tracking(1.2)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                    Text(String(format: workingWeight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", workingWeight))
                        .font(AppTheme.Typography.monoLarge)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(unit == .kg ? "KG" : "LBS")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)

                    Text("× \(targetReps) reps")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        adjustWeight(by: unit == .kg ? -2.5 : -5.0)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(AppTheme.Text.secondary)

                    Button {
                        adjustWeight(by: unit == .kg ? 2.5 : 5.0)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(AppTheme.Accent.gold)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var barbellPickerCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Barbell Weight")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)

                Picker("Bar", selection: $selectedBar) {
                    ForEach(BarbellType.allCases) { bar in
                        Text(bar.rawValue).tag(bar)
                    }
                }
                #if os(watchOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.segmented)
                #endif
            }
        }
    }

    private var warmupSetsCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("RAMP PROTOCOL")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                        .tracking(1.0)
                    Spacer()
                    Text("\(progression.sets.count) sets")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Divider()
                    .background(AppTheme.Text.secondary.opacity(0.2))

                ForEach(progression.sets) { set in
                    let isCompleted = completedSetIds.contains(set.id)
                    let isSelected = selectedSetId == set.id

                    HStack(spacing: AppTheme.Spacing.md) {
                        Button {
                            toggleCompleted(set.id)
                        } label: {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(isCompleted ? AppTheme.Recovery.high : AppTheme.Text.secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(badgeText(for: set))
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(set.isWorkingSet ? AppTheme.Accent.orange : AppTheme.Accent.gold)

                                Spacer()

                                Text(String(format: set.weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", set.weight) + (unit == .kg ? " kg" : " lb"))
                                    .font(AppTheme.Typography.monoMedium)
                                    .foregroundColor(isCompleted ? AppTheme.Text.secondary : AppTheme.Text.primary)
                                    .strikethrough(isCompleted)
                            }

                            HStack {
                                Text("\(set.targetReps) \(set.targetReps == 1 ? "rep" : "reps")")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)

                                Spacer()

                                Text(set.plateSummary)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if selectedSetId == set.id {
                                selectedSetId = nil
                            } else {
                                selectedSetId = set.id
                            }
                        }
                    }

                    if set.id != progression.sets.last?.id {
                        Divider()
                            .background(AppTheme.Text.secondary.opacity(0.1))
                    }
                }
            }
        }
    }

    private func selectedSetDetailCard(for set: WarmupSet) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("Plate Stack: Set \(set.setNumber)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                    Spacer()
                    Text(set.plateSummary)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                if set.platesPerSide.isEmpty {
                    Text("Bar only — no plates needed.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.vertical, AppTheme.Spacing.sm)
                } else {
                    let expanded = expandPlates(set.platesPerSide)
                    HStack(alignment: .center, spacing: AppTheme.Spacing.xs) {
                        Rectangle()
                            .fill(AppTheme.Text.secondary.opacity(0.4))
                            .frame(width: 12, height: 44)
                            .cornerRadius(2)

                        ForEach(expanded.indices, id: \.self) { idx in
                            miniPlateView(for: expanded[idx])
                        }

                        Rectangle()
                            .fill(AppTheme.Text.secondary.opacity(0.25))
                            .frame(width: 6, height: 22)
                            .cornerRadius(2)
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Background.card)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
    }

    private var guidanceCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "timer")
                        .foregroundColor(AppTheme.Accent.gold)
                    Text("Warmup Rest Guidance")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                }
                Text("Rest 45–60s between warmups, and 2–3 minutes before your first working set. Move with explosive intent to prime neuromuscular potentiation without accumulating fatigue.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func badgeText(for set: WarmupSet) -> String {
        if set.isWorkingSet {
            return "WORKING SET (100%)"
        }
        if set.setNumber == 1 {
            return "EMPTY BAR (10 REPS)"
        }
        let pct = Int(round(set.percentOfWorking * 100))
        return "WARMUP \(set.setNumber) (\(pct)%)"
    }

    private func toggleCompleted(_ id: UUID) {
        if completedSetIds.contains(id) {
            completedSetIds.remove(id)
        } else {
            completedSetIds.insert(id)
            HapticFeedback.light()
        }
    }

    private func adjustWeight(by delta: Double) {
        let newWeight = workingWeight + delta
        if newWeight >= 0 {
            workingWeight = newWeight
        }
    }

    private func expandPlates(_ plates: [PlateCount]) -> [Double] {
        var result: [Double] = []
        for plate in plates {
            for _ in 0..<plate.countPerSide {
                result.append(plate.weight)
            }
        }
        return result
    }

    private func miniPlateView(for weight: Double) -> some View {
        let height: CGFloat = weight >= 45 || (unit == .kg && weight >= 20) ? 65 : (weight >= 25 || (unit == .kg && weight >= 10) ? 52 : 38)
        let width: CGFloat = weight >= 45 || (unit == .kg && weight >= 20) ? 18 : (weight >= 25 || (unit == .kg && weight >= 10) ? 14 : 10)

        return VStack {
            Text(String(format: weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", weight))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.white)
        }
        .frame(width: width, height: height)
        .background(plateColor(for: weight))
        .cornerRadius(2)
    }

    private func plateColor(for weight: Double) -> Color {
        if weight >= 45 || (unit == .kg && weight >= 20) {
            return AppTheme.Background.navy
        } else if weight >= 25 || (unit == .kg && weight >= 10) {
            return AppTheme.Accent.gold
        } else if weight >= 10 || (unit == .kg && weight >= 5) {
            return AppTheme.Accent.orange
        } else {
            return AppTheme.Text.secondary
        }
    }
}
