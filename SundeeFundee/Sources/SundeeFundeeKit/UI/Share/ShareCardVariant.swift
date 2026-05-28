import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ShareSummary
//
// Compact summary block used as overlay content on SelfieOverlayShareView.

public struct ShareSummary: Sendable, Equatable {
    public let title: String
    public let exerciseCount: Int
    public let totalVolume: Double
    public let durationMinutes: Int
    public let weightUnit: String

    public init(
        title: String,
        exerciseCount: Int,
        totalVolume: Double,
        durationMinutes: Int,
        weightUnit: String = "lb"
    ) {
        self.title = title
        self.exerciseCount = exerciseCount
        self.totalVolume = totalVolume
        self.durationMinutes = durationMinutes
        self.weightUnit = weightUnit
    }

    /// Build a summary from a Workout, picking lb as the display unit.
    public init(workout: Workout, weightUnit: String = "lb") {
        self.init(
            title: workout.name,
            exerciseCount: workout.exercises.count,
            totalVolume: workout.totalVolume,
            durationMinutes: workout.duration,
            weightUnit: weightUnit
        )
    }
}

public struct SharePrivacyOptions: Sendable, Equatable, Codable {
    public var showCycleContext: Bool
    public var showRecoveryScore: Bool
    public var showPainContext: Bool
    public var showExactDate: Bool

    public init(
        showCycleContext: Bool = false,
        showRecoveryScore: Bool = false,
        showPainContext: Bool = false,
        showExactDate: Bool = false
    ) {
        self.showCycleContext = showCycleContext
        self.showRecoveryScore = showRecoveryScore
        self.showPainContext = showPainContext
        self.showExactDate = showExactDate
    }

    public static let privateDefault = SharePrivacyOptions()

    public func redactedDateText(for date: Date) -> String {
        guard showExactDate else { return "Recent Session" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    public func redactSensitiveText(_ text: String) -> String {
        var redacted = text
        if !showCycleContext {
            redacted = redacted.replacingOccurrences(of: "cycle", with: "readiness", options: [.caseInsensitive])
            redacted = redacted.replacingOccurrences(of: "phase", with: "timing", options: [.caseInsensitive])
            redacted = redacted.replacingOccurrences(of: "day ", with: "", options: [.caseInsensitive])
        }
        if !showRecoveryScore {
            redacted = redacted.replacingOccurrences(of: "recovery", with: "readiness", options: [.caseInsensitive])
            redacted = redacted.replacingOccurrences(
                of: "score",
                with: "signal",
                options: [.caseInsensitive]
            )
        }
        if !showPainContext {
            redacted = redacted.replacingOccurrences(of: "pain", with: "comfort", options: [.caseInsensitive])
            redacted = redacted.replacingOccurrences(of: "sore", with: "tight", options: [.caseInsensitive])
        }
        return redacted
    }

    // MARK: - Preset Persistence

    private static let presetKey = "com.sundeefundee.sharePrivacyPreset"

    public static var savedPreset: SharePrivacyOptions {
        get {
            guard let data = UserDefaults.standard.data(forKey: presetKey) else {
                return .privateDefault
            }
            guard let decoded = try? JSONDecoder().decode(
                SharePrivacyOptions.self, from: data
            ) else {
                return .privateDefault
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: presetKey)
        }
    }
}

// MARK: - ShareCardVariant
//
// The data payload driving which card is rendered. Views are matched by
// variant in `ShareCardRenderer`.

public enum ShareCardVariant: Sendable {
    case completedWorkout(workout: Workout, personalRecords: Set<String>)
    case newPR(exerciseName: String, weight: Double, unit: String, previousBest: Double?)
    case cycleInsight(phase: CyclePhase, cycleDay: Int, insight: String)
    case coachSummary(title: String, subtitle: String, badge: String, bullets: [String])
    case weeklyRecap(title: String, subtitle: String, badge: String, bullets: [String])
    #if canImport(UIKit)
    case selfieOverlay(image: UIImage, summary: ShareSummary)
    #endif

    /// Preview title used for the native share sheet.
    public var shareTitle: String {
        switch self {
        case .completedWorkout(let workout, _):
            return workout.name
        case .newPR(let exercise, let weight, let unit, _):
            return "New PR — \(exercise) \(formatWeight(weight)) \(unit)"
        case .cycleInsight:
            return "Cycle-aware training"
        case .coachSummary(let title, _, _, _):
            return title
        case .weeklyRecap(let title, _, _, _):
            return title
        #if canImport(UIKit)
        case .selfieOverlay(_, let summary):
            return summary.title
        #endif
        }
    }

    private func formatWeight(_ w: Double) -> String {
        if w == floor(w) { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }
}
