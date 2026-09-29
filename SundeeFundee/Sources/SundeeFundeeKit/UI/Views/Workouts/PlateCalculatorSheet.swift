import SwiftUI

// MARK: - BarbellType

public enum BarbellType: String, CaseIterable, Identifiable, Sendable {
    case standardOlympic = "Standard (45 lb / 20 kg)"
    case technique = "Technique (35 lb / 15 kg)"
    case trapBar = "Trap Bar (55 lb / 25 kg)"

    public var id: String { rawValue }

    public func weight(for unit: WeightUnit) -> Double {
        switch self {
        case .standardOlympic:
            return unit == .kg ? 20.0 : 45.0
        case .technique:
            return unit == .kg ? 15.0 : 35.0
        case .trapBar:
            return unit == .kg ? 25.0 : 55.0
        }
    }
}

// MARK: - PlateCalculatorSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct PlateCalculatorSheet: View {
    @State private var targetWeight: Double
    @State private var selectedBar: BarbellType
    @State private var unit: WeightUnit

    @Environment(\.dismiss) private var dismiss

    public init(
        initialWeight: Double,
        unit: WeightUnit = .lbs,
        initialBar: BarbellType = .standardOlympic
    ) {
        _targetWeight = State(initialValue: max(0, initialWeight))
        _unit = State(initialValue: unit)
        _selectedBar = State(initialValue: initialBar)
    }

    private var availablePlates: [Double] {
        unit == .kg ? PlateCalculatorService.defaultMetricPlates : PlateCalculatorService.defaultImperialPlates
    }

    private var barWeight: Double {
        selectedBar.weight(for: unit)
    }

    private var calculation: PlateCalculationResult {
        PlateCalculatorService.calculate(
            targetWeight: targetWeight,
            barWeight: barWeight,
            availablePlates: availablePlates
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    weightControlCard
                    barbellPickerCard
                    visualBarbellStackCard
                    breakdownCard
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Plate Calculator")
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

    private var weightControlCard: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Target Load")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                    Text(String(format: targetWeight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", targetWeight))
                        .font(AppTheme.Typography.monoLarge)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(unit == .kg ? "KG" : "LBS")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)
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

    private var visualBarbellStackCard: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Each Side of Bar")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)

                if calculation.platesPerSide.isEmpty {
                    Text("Bar only — no plates needed.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.vertical, AppTheme.Spacing.md)
                } else {
                    HStack(alignment: .center, spacing: AppTheme.Spacing.xs) {
                        // Collar / Bar shaft representation
                        Rectangle()
                            .fill(AppTheme.Text.secondary.opacity(0.4))
                            .frame(width: 14, height: 50)
                            .cornerRadius(2)

                        // Plates rendered from heaviest (inside) to lightest (outside)
                        ForEach(expandedPlates.indices, id: \.self) { idx in
                            plateView(for: expandedPlates[idx])
                        }

                        // Outer sleeve tip
                        Rectangle()
                            .fill(AppTheme.Text.secondary.opacity(0.25))
                            .frame(width: 8, height: 26)
                            .cornerRadius(2)
                    }
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Background.card)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var breakdownCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("Weight per side:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                    Spacer()
                    Text(String(format: "%.1f %@", calculation.weightPerSide, unit == .kg ? "kg" : "lbs"))
                        .font(AppTheme.Typography.monoMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }

                Divider()
                    .background(AppTheme.Text.secondary.opacity(0.2))

                if calculation.platesPerSide.isEmpty {
                    Text("No plates to load.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                } else {
                    ForEach(calculation.platesPerSide, id: \.weight) { plate in
                        HStack {
                            Text("\(plate.countPerSide) ×")
                                .font(AppTheme.Typography.monoMedium)
                                .foregroundColor(AppTheme.Accent.gold)
                            Text(String(format: "%.1f %@", plate.weight, unit == .kg ? "kg" : "lbs"))
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Spacer()
                            Text(String(format: "%.1f %@", Double(plate.countPerSide) * plate.weight, unit == .kg ? "kg" : "lbs"))
                                .font(AppTheme.Typography.monoSmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }

                if !calculation.isExact {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(AppTheme.Accent.orange)
                        Text("Target cannot be matched exactly. Total loaded: \(String(format: "%.1f", calculation.totalLoadedWeight)) \(unit == .kg ? "kg" : "lbs") (\(String(format: "%.1f", abs(calculation.remainder))) remainder).")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Accent.orange)
                    }
                    .padding(.top, AppTheme.Spacing.xs)
                }
            }
        }
    }

    private var expandedPlates: [Double] {
        var result: [Double] = []
        for plate in calculation.platesPerSide {
            for _ in 0..<plate.countPerSide {
                result.append(plate.weight)
            }
        }
        return result
    }

    private func plateView(for weight: Double) -> some View {
        let height: CGFloat = plateHeight(for: weight)
        let width: CGFloat = plateWidth(for: weight)

        return VStack(spacing: 0) {
            Text(String(format: weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", weight))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.white)
        }
        .frame(width: width, height: height)
        .background(plateColor(for: weight))
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(AppTheme.Accent.goldDark.opacity(0.5), lineWidth: 1)
        )
    }

    private func plateHeight(for weight: Double) -> CGFloat {
        if weight >= 45 || (unit == .kg && weight >= 20) {
            return 90
        } else if weight >= 25 || (unit == .kg && weight >= 15) {
            return 75
        } else if weight >= 10 || (unit == .kg && weight >= 5) {
            return 60
        } else {
            return 45
        }
    }

    private func plateWidth(for weight: Double) -> CGFloat {
        if weight >= 45 || (unit == .kg && weight >= 20) {
            return 22
        } else if weight >= 25 || (unit == .kg && weight >= 10) {
            return 18
        } else {
            return 14
        }
    }

    private func plateColor(for weight: Double) -> Color {
        // Art Deco palette for barbell plates
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

    private func adjustWeight(by delta: Double) {
        let newWeight = targetWeight + delta
        if newWeight >= 0 {
            targetWeight = newWeight
        }
    }
}
