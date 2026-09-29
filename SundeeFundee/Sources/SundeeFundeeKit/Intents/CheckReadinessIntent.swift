import AppIntents
import Foundation
import SwiftUI

// MARK: - CheckReadinessIntent
//
// Siri / Shortcuts intent for checking today's readiness score and recovery advice.
// Reads from SharedSnapshotStore without requiring the app UI to launch.

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public struct CheckReadinessIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Readiness"
    public static let description = IntentDescription("Checks your daily readiness score and recovery guidance in Sundee Fundee.")
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let readiness = SharedSnapshotStore.readReadiness()
        let cycle = SharedSnapshotStore.readCycle()

        guard let readiness else {
            let message = "You haven't assessed your readiness yet today. Open Sundee Fundee to complete your check-in."
            return .result(
                dialog: IntentDialog(stringLiteral: message),
                view: ReadinessIntentSnippetView(
                    score: nil,
                    state: nil,
                    cycleDay: cycle?.cycleDay,
                    message: message
                )
            )
        }

        let stateLabel: String
        let guidance: String
        switch readiness.stateRaw {
        case "primed":
            stateLabel = "Primed"
            guidance = "Your readiness score is \(readiness.totalScore), Primed. Optimal capacity for high intensity and progressive loading today."
        case "steady":
            stateLabel = "Steady"
            guidance = "Your readiness score is \(readiness.totalScore), Steady. Balanced work capacity — stick to your scheduled sets and prescribed weights."
        case "recovering":
            stateLabel = "Recovering"
            guidance = "Your readiness score is \(readiness.totalScore), Recovering. Active recovery or reduced volume is advised today to support adaptation."
        default:
            stateLabel = readiness.stateRaw.capitalized
            guidance = "Your readiness score is \(readiness.totalScore). Open Sundee Fundee to view your full recovery breakdown."
        }

        return .result(
            dialog: IntentDialog(stringLiteral: guidance),
            view: ReadinessIntentSnippetView(
                score: readiness.totalScore,
                state: stateLabel,
                cycleDay: cycle?.cycleDay,
                message: guidance
            )
        )
    }
}

// MARK: - Snippet View

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
private struct ReadinessIntentSnippetView: View {
    let score: Int?
    let state: String?
    let cycleDay: Int?
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Daily Readiness", systemImage: "bolt.heart.fill")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundStyle(AppTheme.Accent.orange)
                Spacer()
                if let cycleDay {
                    Text("Cycle Day \(cycleDay)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundStyle(AppTheme.Text.secondary)
                }
            }

            if let score, let state {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(score)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.recoveryColor(for: score))
                    Text("/ 100")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.Text.secondary)
                    Spacer()
                    Text(state.uppercased())
                        .font(AppTheme.Typography.labelMedium.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.recoveryColor(for: score).opacity(0.15))
                        .foregroundStyle(AppTheme.recoveryColor(for: score))
                        .clipShape(Capsule())
                }
            }

            Text(message)
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(AppTheme.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}
