import Foundation

final class CloudAIUsageTracker: @unchecked Sendable {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Daily Count

    var generatedToday: Int {
        defaults.integer(forKey: todayKey)
    }

    func recordGeneration() {
        defaults.set(generatedToday + 1, forKey: todayKey)
    }

    func setGeneratedToday(_ count: Int) {
        defaults.set(count, forKey: todayKey)
    }

    // MARK: - Limits

    func remaining(for tier: SubscriptionTier) -> Int {
        let limit = AIWorkoutLimits.dailyCloudLimit(for: tier)
        return max(0, limit - generatedToday)
    }

    func canGenerate(for tier: SubscriptionTier) -> Bool {
        AIWorkoutLimits.canGenerateCloud(tier: tier, generatedToday: generatedToday)
    }

    // MARK: - UI Text

    static func toggleLabel(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free: return ""
        case .plus: return "Use Sundee AI"
        case .premium: return "Use Sundee AI Pro"
        }
    }

    func subtitleText(for tier: SubscriptionTier) -> String {
        let limit = AIWorkoutLimits.dailyCloudLimit(for: tier)
        let rem = remaining(for: tier)
        if rem == 0 { return "Come back tomorrow" }
        return "\(rem) of \(limit) remaining today"
    }

    // MARK: - Private

    private var todayKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "cloudAIUsage:\(formatter.string(from: Date()))"
    }
}
