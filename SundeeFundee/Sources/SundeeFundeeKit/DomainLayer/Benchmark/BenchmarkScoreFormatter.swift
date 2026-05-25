import Foundation

public enum BenchmarkScoreFormatter {
    public static func string(for score: Double, scoringType: BenchmarkScoringType) -> String {
        switch scoringType {
        case .time:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .roundsAndReps:
            let rounds = Int(score) / 10000
            let reps = Int(score) % 10000
            return "\(rounds) rounds + \(reps) reps"
        case .load:
            return "\(Int(score)) lb"
        case .reps:
            return "\(Int(score)) reps"
        case .calories:
            return "\(Int(score)) cal"
        case .distance:
            return "\(Int(score)) m"
        }
    }

    public static func string(for score: Double, scoringTypeRaw: String) -> String {
        guard let scoringType = BenchmarkScoringType(rawValue: scoringTypeRaw) else {
            return "\(Int(score))"
        }
        return string(for: score, scoringType: scoringType)
    }
}

