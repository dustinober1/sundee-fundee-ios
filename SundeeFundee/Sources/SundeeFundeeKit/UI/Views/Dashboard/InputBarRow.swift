import SwiftUI

// MARK: - InputBarRow
//
// Horizontal progress bar component for the recovery breakdown screen.
// Shows sub-score, label, SF Symbol icon, and explanation line.
// Missing inputs render grayed out with an enable prompt.
// Per UI-SPEC D-04, D-05.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct InputBarRow: View {

    // MARK: - Properties

    let input: RecoveryInput
    let subScore: Int?
    let explanation: String?
    let animationDelay: Double

    @State private var animatedWidth: CGFloat = 0

    // MARK: - Body

    var body: some View {
        let isMissing = subScore == nil

        VStack(spacing: AppTheme.Spacing.xs) {
            // Label row
            HStack {
                Image(systemName: iconName(for: input))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Text.secondary)
                    .accessibilityHidden(true)

                Text(labelText(for: input))
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)

                Spacer()

                Text(isMissing ? "\u{2014}" : "\(subScore!)")
                    .font(AppTheme.Typography.monoLarge)
                    .foregroundColor(
                        isMissing ? AppTheme.Text.secondary : AppTheme.recoveryColor(for: subScore!)
                    )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.circle)
                        .fill(AppTheme.Background.cream)
                        .frame(height: 8)

                    if !isMissing {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.circle)
                            .fill(AppTheme.recoveryColor(for: subScore!))
                            .frame(width: animatedWidth, height: 8)
                    }
                }
                .onAppear {
                    if let score = subScore {
                        withAnimation(.easeOut(duration: 0.5).delay(animationDelay)) {
                            animatedWidth = geo.size.width * CGFloat(score) / 100.0
                        }
                    }
                }
            }
            .frame(height: 8)

            // Explanation line (D-05)
            if let explanation = explanation {
                Text(explanation)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            } else if isMissing {
                Text(missingExplanation(for: input))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
        .opacity(isMissing ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isMissing
                ? "\(labelText(for: input)): not available. \(missingExplanation(for: input))"
                : "\(labelText(for: input)): \(subScore!) out of 100. \(explanation ?? "")"
        )
    }

    // MARK: - Icon Mapping

    private func iconName(for input: RecoveryInput) -> String {
        switch input {
        case .hrv:          return "heart.text.square"
        case .sleep:        return "bed.double"
        case .trainingLoad: return "figure.strengthtraining.traditional"
        case .cyclePhase:   return "calendar.circle"
        case .pain:         return "bandage"
        }
    }

    // MARK: - Label Mapping (per Copywriting Contract)

    private func labelText(for input: RecoveryInput) -> String {
        switch input {
        case .hrv:          return "Heart Rate Variability"
        case .sleep:        return "Sleep"
        case .trainingLoad: return "Training Load"
        case .cyclePhase:   return "Cycle Phase"
        case .pain:         return "Pain & Soreness"
        }
    }

    // MARK: - Missing Input Explanation (per Copywriting Contract)

    private func missingExplanation(for input: RecoveryInput) -> String {
        switch input {
        case .hrv:          return "Enable HealthKit to include this input"
        case .sleep:        return "Enable HealthKit to include this input"
        case .trainingLoad: return "Complete workouts to include this input"
        case .cyclePhase:   return "Enable cycle tracking to include this input"
        case .pain:         return "Log pain levels to include this input"
        }
    }
}
