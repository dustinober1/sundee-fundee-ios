import SwiftUI

/// Shows which plates to load per side for a barbell lift. Pounds only —
/// the active workout screen's weight entry is unconditionally in pounds
/// regardless of the user's weight-unit setting, so showing kilogram plate
/// math against that number would silently mismatch units.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct PlateBreakdownView: View {
    let targetWeight: Double
    let barWeight: Double

    private var plates: [Plate] {
        calculatePlates(targetWeight: targetWeight, barWeight: barWeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Per Side (\(Int(barWeight)) lb bar)")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            if targetWeight <= barWeight {
                Text("Bar only")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)
            } else if plates.isEmpty {
                Text("No combination of standard plates hits this weight exactly")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            } else {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(plates, id: \.weight) { plate in
                        plateChip(plate)
                    }
                }
            }
        }
    }

    private func plateChip(_ plate: Plate) -> some View {
        VStack(spacing: 2) {
            Text(Self.weightLabel(plate.weight))
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Text.primary)
            if plate.count > 1 {
                Text("×\(plate.count)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plate.count > 1 ? "\(plate.count) times \(Self.weightLabel(plate.weight)) pounds" : "\(Self.weightLabel(plate.weight)) pounds")
    }

    private static func weightLabel(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }
}
