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
    public var showPainContext: Bool
    public var showExactDate: Bool

    public init(
        showCycleContext: Bool = false,
        showPainContext: Bool = false,
        showExactDate: Bool = false
    ) {
        self.showCycleContext = showCycleContext
        self.showPainContext = showPainContext
        self.showExactDate = showExactDate
    }

    public static let privateDefault = SharePrivacyOptions()

    /// Plain-language summary of what the selected share card includes and
    /// which sensitive details remain private.
    public var shareDisclosureText: String {
        let selectedDetails = [
            showCycleContext ? "cycle context" : nil,
            showPainContext ? "pain context" : nil,
            showExactDate ? "an exact date" : nil,
        ].compactMap { $0 }
        let previewBoundary = "Only information shown in this preview is shared."

        guard !selectedDetails.isEmpty else {
            return "\(previewBoundary) Health data and private notes not shown here stay on your device."
        }

        let includedDetails = Self.formattedList(
            selectedDetails,
            capitalizingFirst: true
        )
        let remainingHealthData = showCycleContext || showPainContext
            ? "Other health data"
            : "Health data"

        return "\(previewBoundary) \(includedDetails) may be included when available. \(remainingHealthData) and private notes not shown here stay on your device."
    }

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
        if !showPainContext {
            redacted = redacted.replacingOccurrences(of: "pain", with: "comfort", options: [.caseInsensitive])
            redacted = redacted.replacingOccurrences(of: "sore", with: "tight", options: [.caseInsensitive])
        }
        return redacted
    }

    private static func formattedList(
        _ items: [String],
        capitalizingFirst: Bool = false
    ) -> String {
        guard let first = items.first, let last = items.last else { return "" }
        let initial = capitalizingFirst
            ? first.prefix(1).uppercased() + first.dropFirst()
            : first
        let normalized = [initial] + items.dropFirst()

        switch normalized.count {
        case 1:
            return normalized[0]
        case 2:
            return "\(normalized[0]) and \(normalized[1])"
        default:
            return "\(normalized.dropLast().joined(separator: ", ")), and \(last)"
        }
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
    case buddyCheckIn(summary: BuddyCheckInSummary, displayName: String)
    case monthlyReview(review: MonthlyReview)
    /// Privacy-safe 2.0 outcome cards. These cases intentionally accept only
    /// `ShareSanitizedSummary`; raw readiness, HealthKit, cycle, pain, and note
    /// data cannot reach the renderer or share sheet.
    case readiness(summary: ShareSanitizedSummary)
    case deload(summary: ShareSanitizedSummary)
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
        case .buddyCheckIn(_, let displayName):
            return "Buddy Check-In — \(displayName)"
        case .monthlyReview(let review):
            return "Monthly Review — \(review.monthTitle)"
        case .readiness(let summary), .deload(let summary):
            return summary.title
        #if canImport(UIKit)
        case .selfieOverlay(_, let summary):
            return summary.title
        #endif
        }
    }

    /// Descriptive aliases for call sites that prefer the share-oriented name.
    public static func readinessShare(summary: ShareSanitizedSummary) -> ShareCardVariant {
        .readiness(summary: summary)
    }

    public static func deloadShare(summary: ShareSanitizedSummary) -> ShareCardVariant {
        .deload(summary: summary)
    }

    private func formatWeight(_ w: Double) -> String {
        if w == floor(w) { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }

    /// Analytics attribution is omitted for privacy-safe variants.
    func shareSheetOpenedSource(shareContext: ShareContext?) -> String? {
        switch self {
        case .readiness, .deload:
            return nil
        default:
            return shareContext?.surface.rawValue
        }
    }
}
