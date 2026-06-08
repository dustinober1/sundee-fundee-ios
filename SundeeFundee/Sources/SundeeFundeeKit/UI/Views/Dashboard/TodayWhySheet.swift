import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TodayWhySheet: View {
    @Environment(\.dismiss) private var dismiss

    let decision: TodayTrainingDecision?
    let recoveryExplanations: [RecoveryExplanation]
    let deloadRecommendation: DeloadRecommendation?
    let cyclePhase: CyclePhase?
    let cycleConfidence: Double?

    var body: some View {
        NavigationStack {
            List {
                if let decision {
                    Section("Today") {
                        Text(decision.subtitle)
                        ForEach(decision.reasons.prefix(3), id: \.self) { reason in
                            Text(reason)
                        }
                    }
                }

                if !recoveryExplanations.isEmpty {
                    Section("Recovery") {
                        ForEach(recoveryExplanations.prefix(3)) { explanation in
                            Text(explanation.text)
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
