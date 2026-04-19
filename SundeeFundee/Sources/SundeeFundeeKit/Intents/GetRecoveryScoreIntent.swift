import AppIntents
import Foundation

// MARK: - GetRecoveryScoreIntent
//
// Reads the most recent RecoverySnapshot from the App Group and speaks
// a natural-language summary. Falls back to "no data yet" if the user
// hasn't computed a score.

@available(iOS 18.0, *)
public struct GetRecoveryScoreIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get recovery score"
    public static var description = IntentDescription("Reports today's recovery score and training verdict.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let snapshot = SharedSnapshotStore.readRecovery() else {
            return .result(dialog: "No recovery score yet. Open Sundee Fundee to compute one.")
        }

        let verdict: String
        switch snapshot.recommendationRaw {
        case "pushDay": verdict = "Push day — go train."
        case "moderate": verdict = "Moderate — train with awareness."
        case "restDay": verdict = "Rest day — recover."
        default: verdict = ""
        }

        let suffix = verdict.isEmpty ? "." : ". \(verdict)"
        return .result(dialog: "Your recovery score is \(snapshot.total)\(suffix)")
    }
}
