import Foundation

// MARK: - Celebration Event

/// A celebration-worthy event in the app
public enum CelebrationEvent: Sendable {
    case workoutCompleted(durationSeconds: Int)
    case newPersonalRecord(exerciseName: String, weightKg: Double)
    case programCompleted(programName: String)
    case weightMilestone(exerciseName: String, thresholdKg: Double)
    case newConditioningPR(exerciseName: String, value: Double, scoringType: BenchmarkScoringType)
    case challengeTierCompleted(challengeTitle: String, tierName: String, volumeLbs: Double)
    case challengeCompleted(challengeTitle: String)
}

// MARK: - Formatting Helpers

/// Format a conditioning value based on scoring type
private func formatConditioningValue(_ value: Double, scoringType: BenchmarkScoringType) -> String {
    switch scoringType {
    case .time:
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    case .reps:
        let count = Int(value)
        return count == 1 ? "1 rep" : "\(count) reps"
    case .roundsAndReps:
        let rounds = Int(value) / 10000
        let reps = Int(value) % 10000
        return "\(rounds) rounds + \(reps) reps"
    case .distance:
        return "\(Int(value)) m"
    case .load, .calories:
        return "\(Int(value)) kg"
    }
}

// MARK: - Title & Subtitle

/// Title for a celebration event
public func celebrationTitle(_ event: CelebrationEvent) -> String {
    switch event {
    case .workoutCompleted:
        return "Workout Complete!"
    case .newPersonalRecord:
        return "New Personal Record!"
    case .programCompleted:
        return "Program Complete!"
    case .weightMilestone:
        return "Weight Milestone!"
    case .newConditioningPR:
        return "New Conditioning PR!"
    case .challengeTierCompleted:
        return "Challenge Milestone!"
    case .challengeCompleted:
        return "Challenge Complete!"
    }
}

/// Subtitle for a celebration event
public func celebrationSubtitle(_ event: CelebrationEvent, unit: String = "kg") -> String {
    switch event {
    case .workoutCompleted(let durationSeconds):
        let minutes = durationSeconds / 60
        return minutes > 0 ? "Completed in \(minutes) min" : "Workout saved!"
    case .newPersonalRecord(let exerciseName, let weightKg):
        let converted = unit == "lb" ? weightKg * 2.20462 : weightKg
        let formatted = formatWeight(converted)
        return "\(exerciseName) — \(formatted) \(unit) estimated 1RM"
    case .programCompleted(let programName):
        return "You finished \(programName). Time to level up!"
    case .weightMilestone(let exerciseName, let thresholdKg):
        let converted = unit == "lb" ? thresholdKg * 2.20462 : thresholdKg
        return "\(exerciseName) hit \(Int(converted.rounded())) \(unit)!"
    case .newConditioningPR(let exerciseName, let value, let scoringType):
        let formatted = formatConditioningValue(value, scoringType: scoringType)
        return "\(exerciseName) — \(formatted)"
    case .challengeTierCompleted(let challengeTitle, let tierName, let volumeLbs):
        let formatted = formatWeight(volumeLbs)
        return "\(challengeTitle) — \(tierName) tier at \(formatted) lbs!"
    case .challengeCompleted(let challengeTitle):
        return "You've completed \(challengeTitle)!"
    }
}

/// Format a weight value, removing trailing .0
private func formatWeight(_ value: Double) -> String {
    if value == value.rounded() {
        return "\(Int(value))"
    }
    return String(format: "%.1f", value)
}
