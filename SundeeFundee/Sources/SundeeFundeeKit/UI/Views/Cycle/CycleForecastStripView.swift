import SwiftUI

// MARK: - CycleForecastStripView

/// An Art Deco 7-day forward-looking cycle and training forecast strip.
///
/// Surfaces projected phase transitions and energy capacity for the upcoming week,
/// respecting standard, contraceptive, irregular, and perimenopause modes.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CycleForecastStripView: View {
    public let forecasts: [CycleDayForecast]
    public let terminologyStyle: CycleTerminologyStyle

    @State private var selectedDayOffset: Int = 0

    public init(
        forecasts: [CycleDayForecast],
        terminologyStyle: CycleTerminologyStyle = .physiological
    ) {
        self.forecasts = forecasts
        self.terminologyStyle = terminologyStyle
    }

    private var selectedForecast: CycleDayForecast? {
        forecasts.first(where: { $0.dayOffset == selectedDayOffset }) ?? forecasts.first
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Accent.gold)

                    Text("7-Day Forecast")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }

                Spacer()

                if let current = selectedForecast, current.isToday {
                    Text("Today")
                        .font(AppTheme.Typography.labelSmall)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(AppTheme.Accent.gold.opacity(0.18))
                        .foregroundColor(AppTheme.Accent.gold)
                        .clipShape(Capsule())
                }
            }

            // Horizontal Strip of 7 Days
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(forecasts) { day in
                        DayPillView(
                            forecast: day,
                            isSelected: day.dayOffset == selectedDayOffset,
                            onSelect: {
                                selectedDayOffset = day.dayOffset
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            // Expanded Detail for Selected Day
            if let selected = selectedForecast {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(color(for: selected.energyTier))
                            .frame(width: 8, height: 8)

                        Text(selected.headline)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Spacer()

                        Text(selected.suggestedIntensity)
                            .font(AppTheme.Typography.labelSmall)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(color(for: selected.energyTier).opacity(0.15))
                            .foregroundColor(color(for: selected.energyTier))
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }

                    Text(selected.trainingFocus)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(selected.summary)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Background.card)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Border.subtle, lineWidth: 1)
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Color Helper

    private func color(for tier: ForecastEnergyTier) -> Color {
        switch tier {
        case .peak:       return AppTheme.Accent.gold
        case .moderate:   return AppTheme.Recovery.green
        case .recovering: return AppTheme.Accent.orange
        case .steady:     return AppTheme.Accent.navy
        }
    }
}

// MARK: - DayPillView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct DayPillView: View {
    let forecast: CycleDayForecast
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(forecast.dayOfWeek.uppercased())
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(isSelected ? AppTheme.Accent.gold : AppTheme.Text.secondary)

                Text("\(forecast.dayOfMonth)")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(isSelected ? AppTheme.Text.primary : AppTheme.Text.secondary)

                Circle()
                    .fill(tierColor)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 48, height: 72)
            .background(isSelected ? AppTheme.Background.card : Color.clear)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Accent.gold : AppTheme.Border.subtle, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(forecast.dayOfWeek), day \(forecast.dayOfMonth): \(forecast.headline)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var tierColor: Color {
        switch forecast.energyTier {
        case .peak:       return AppTheme.Accent.gold
        case .moderate:   return AppTheme.Recovery.green
        case .recovering: return AppTheme.Accent.orange
        case .steady:     return AppTheme.Accent.navy
        }
    }
}
