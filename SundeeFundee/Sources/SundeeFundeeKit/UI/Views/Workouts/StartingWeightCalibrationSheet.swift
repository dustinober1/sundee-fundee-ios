import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct StartingWeightCalibrationSheet: View {
    let suggestions: [StartingWeightSuggestion]
    let onApplyAll: () -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        suggestions: [StartingWeightSuggestion],
        onApplyAll: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.suggestions = suggestions
        self.onApplyAll = onApplyAll
        self.onSkip = onSkip
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(suggestions) { suggestion in
                        ArtDecoCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(suggestion.exerciseName)
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Text(weightText(for: suggestion))
                                        .font(AppTheme.Typography.monoLarge)
                                        .foregroundColor(AppTheme.Accent.gold)
                                    Text("confidence \(Int((suggestion.confidence * 100).rounded()))%")
                                        .font(AppTheme.Typography.labelSmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }

                                Text(suggestion.reason)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Starting Weights")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        onApplyAll()
                        dismiss()
                    } label: {
                        Label("Use Suggestions", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .accent)

                    Button {
                        onSkip()
                        dismiss()
                    } label: {
                        Text("Keep Current Weights")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .secondary)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Background.cream)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onSkip()
                        dismiss()
                    }
                }
            }
        }
    }

    private func weightText(for suggestion: StartingWeightSuggestion) -> String {
        guard let suggestedWeight = suggestion.suggestedWeight else {
            return "Bodyweight"
        }
        if suggestedWeight.rounded() == suggestedWeight {
            return "\(Int(suggestedWeight)) \(suggestion.unit.rawValue)"
        }
        return "\(String(format: "%.1f", suggestedWeight)) \(suggestion.unit.rawValue)"
    }
}
