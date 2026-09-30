import SwiftUI

/// Shows which plates to load per side for a barbell lift.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct PlateBreakdownView: View {
    let targetWeight: Double
    let barWeight: Double
    var unit: WeightUnit = .lbs

    private var availablePlates: [Double] {
        unit == .kg ? PlateCalculatorService.defaultMetricPlates : PlateCalculatorService.defaultImperialPlates
    }

    private var calculation: PlateCalculationResult {
        PlateCalculatorService.calculate(
            targetWeight: targetWeight,
            barWeight: barWeight,
            availablePlates: availablePlates
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Per Side (\(Int(barWeight)) \(unit == .kg ? "kg" : "lb") bar)")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            if targetWeight <= barWeight {
                Text("Bar only")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)
            } else if calculation.platesPerSide.isEmpty {
                Text("No combination of standard plates hits this weight exactly")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            } else {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(calculation.platesPerSide, id: \.weight) { plate in
                        plateChip(weight: plate.weight, count: plate.countPerSide)
                    }
                }
            }
        }
    }

    private func plateChip(weight: Double, count: Int) -> some View {
        VStack(spacing: 2) {
            Text(Self.weightLabel(weight))
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Text.primary)
            if count > 1 {
                Text("×\(count)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 1 ? "\(count) times \(Self.weightLabel(weight)) \(unit == .kg ? "kilograms" : "pounds")" : "\(Self.weightLabel(weight)) \(unit == .kg ? "kilograms" : "pounds")")
    }

    private static func weightLabel(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }
}
