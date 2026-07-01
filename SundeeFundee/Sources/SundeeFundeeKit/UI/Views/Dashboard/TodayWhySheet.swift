import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TodayWhySheet: View {
    @Environment(\.dismiss) private var dismiss

    let decision: TodayTrainingDecision?
    let deloadRecommendation: DeloadRecommendation?
    let cyclePhase: CyclePhase?
    let cycleConfidence: Double?

    private var trustBadges: [WorkoutTrustBadge] {
        WorkoutTrustBadgeBuilder.badges(
            reasons: decision?.reasons ?? [],
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence,
            deloadRecommended: deloadRecommendation?.isRecommended == true
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if !trustBadges.isEmpty {
                    Section("Why this workout") {
                        ForEach(trustBadges) { badge in
                            Label {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text(badge.title)
                                        .font(AppTheme.Typography.headlineSmall)
                                    Text(badge.detail)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            } icon: {
                                Image(systemName: badge.systemImage)
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                        }
                    }
                }

                if let decision {
                    Section("Today") {
                        Text(decision.subtitle)
                        ForEach(decision.reasons.prefix(3), id: \.self) { reason in
                            Text(reason)
                        }
                    }
                }

                if let cyclePhase {
                    Section("Cycle") {
                        Text(cyclePhaseLabel(cyclePhase))
                        if let cycleConfidence {
                            Text("Confidence \(Int(cycleConfidence * 100))%")
                        }
                    }
                }

                if let deloadRecommendation, deloadRecommendation.isRecommended {
                    Section("Deload") {
                        Text(deloadRecommendation.reason)
                    }
                }
            }
            .navigationTitle("Why Today?")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func cyclePhaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}
