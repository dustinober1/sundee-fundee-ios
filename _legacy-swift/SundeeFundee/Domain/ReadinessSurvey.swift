import Foundation

struct ReadinessResult: Equatable {
    let score: Double
    let tier: AdaptationReadinessTier
}

enum ReadinessSurvey {
    private static let sleepWeight = 0.4
    private static let stressWeight = 0.3
    private static let sorenessWeight = 0.3

    static func score(
        sleepQuality: Double,
        stressLevel: Double,
        sorenessLevel: Double
    ) -> ReadinessResult {
        let invertedStress = 10.0 - stressLevel
        let invertedSoreness = 10.0 - sorenessLevel
        let raw = sleepQuality * sleepWeight
            + invertedStress * stressWeight
            + invertedSoreness * sorenessWeight
        let clamped = raw.clamped(to: 0...10)
        return ReadinessResult(score: clamped, tier: tierFromScore(clamped))
    }

    static func blendWithHealthKit(
        surveyScore: Double,
        healthKitScore: Double?
    ) -> ReadinessResult {
        guard let hk = healthKitScore else {
            return ReadinessResult(score: surveyScore, tier: tierFromScore(surveyScore))
        }
        let blended = (surveyScore * 0.7 + hk * 0.3).clamped(to: 0...10)
        return ReadinessResult(score: blended, tier: tierFromScore(blended))
    }

    static func tierFromScore(_ score: Double) -> AdaptationReadinessTier {
        if score <= 3 { return .low }
        if score >= 8 { return .high }
        return .neutral
    }

    static func tierDisplayName(_ tier: AdaptationReadinessTier) -> String {
        switch tier {
        case .low: "Fatigued"
        case .neutral: "Normal"
        case .high: "Prime"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt
    }()

    static func saveTodayResult(_ result: ReadinessResult, defaults: UserDefaults = .standard) {
        let dateStr = dateFormatter.string(from: .now)
        defaults.set(result.score, forKey: "readiness-score-\(dateStr)")
        defaults.set(tierRawValue(result.tier), forKey: "readiness-tier-\(dateStr)")
    }

    static func loadTodayResult(defaults: UserDefaults = .standard) -> ReadinessResult? {
        let dateStr = dateFormatter.string(from: .now)
        let scoreKey = "readiness-score-\(dateStr)"
        let tierKey = "readiness-tier-\(dateStr)"
        guard defaults.object(forKey: scoreKey) != nil else { return nil }
        let score = defaults.double(forKey: scoreKey)
        let tierStr = defaults.string(forKey: tierKey) ?? "neutral"
        return ReadinessResult(score: score, tier: tierFromRawValue(tierStr))
    }

    private static func tierRawValue(_ tier: AdaptationReadinessTier) -> String {
        switch tier {
        case .low: "low"
        case .neutral: "neutral"
        case .high: "high"
        }
    }

    private static func tierFromRawValue(_ raw: String) -> AdaptationReadinessTier {
        switch raw {
        case "low": .low
        case "high": .high
        default: .neutral
        }
    }

    static func tierStringForAI(_ tier: AdaptationReadinessTier) -> String {
        switch tier {
        case .low: "fatigued"
        case .neutral: "normal"
        case .high: "prime"
        }
    }

    static func todayTierStringForAI(defaults: UserDefaults = .standard) -> String? {
        loadTodayResult(defaults: defaults).map { tierStringForAI($0.tier) }
    }

    static func adjustmentBannerText(for tier: AdaptationReadinessTier) -> String? {
        switch tier {
        case .low: "Volume reduced 40% — low readiness"
        case .high: "Intensity boosted 20% — high readiness"
        case .neutral: nil
        }
    }
}
