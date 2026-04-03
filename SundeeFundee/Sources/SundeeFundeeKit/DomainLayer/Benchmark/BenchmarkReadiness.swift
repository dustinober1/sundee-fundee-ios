import Foundation

// MARK: - Benchmark Readiness Calculations

/// Calculates benchmark readiness based on cycle phase and benchmark characteristics
public struct BenchmarkReadinessCalculator {

    /// Calculate benchmark readiness for a given phase and benchmark
    public static func calculateReadiness(
        phase: CyclePhase?,
        benchmarkIntensity: BenchmarkIntensity?,
        movementTags: [String]?
    ) -> BenchmarkReadiness {
        // No cycle data - return neutral
        guard let phase = phase else {
            return BenchmarkReadiness(
                tier: .moderate,
                reason: "No cycle data available",
                recommendation: "Log your period to get personalized recommendations.",
                phaseMultiplier: 1.0,
                emoji: "⚪",
                color: "text-text-secondary"
            )
        }

        let intensity = benchmarkIntensity ?? .three
        let tags = movementTags ?? []
        let phaseMultiplier = CyclePhaseMultiplier.multiplier(for: phase)

        // Check for high-intensity tags
        let hasHeavyTag = tags.contains { tag in
            let lower = tag.lowercased()
            return lower.contains("heavy") ||
                   lower.contains("max") ||
                   lower.contains("high volume")
        }

        let hasHighCardio = tags.contains { tag in
            let lower = tag.lowercased()
            return lower.contains("cardio") ||
                   lower.contains("sprint") ||
                   lower.contains("high intensity")
        }

        // Determine tier based on phase + intensity
        switch phase {
        case .menstrual:
            // Recovery phase - avoid high intensity
            if intensity.rawValue >= 4 || hasHeavyTag || hasHighCardio {
                return BenchmarkReadiness(
                    tier: .recovery,
                    reason: "Shark Week — energy typically lower",
                    recommendation: "Consider saving this for later. Focus on light movement today.",
                    phaseMultiplier: phaseMultiplier,
                    emoji: "🔴",
                    color: "text-warm-rose"
                )
            }
            return BenchmarkReadiness(
                tier: .moderate,
                reason: "Shark Week — listen to your body",
                recommendation: "Light to moderate intensity is fine. Scale as needed.",
                phaseMultiplier: phaseMultiplier,
                emoji: "🟡",
                color: "text-gold"
            )

        case .follicular:
            // Building phase - good for most things
            if intensity.rawValue <= 3 {
                return BenchmarkReadiness(
                    tier: .peak,
                    reason: "Follicular phase — great for building",
                    recommendation: "Your body is primed for strength and skill work. Go for it!",
                    phaseMultiplier: phaseMultiplier,
                    emoji: "🟢",
                    color: "text-green-600"
                )
            }
            if intensity.rawValue >= 4 || hasHeavyTag {
                return BenchmarkReadiness(
                    tier: .peak,
                    reason: "Follicular phase — strength window",
                    recommendation: "Estrogen is rising. Great time for PR attempts!",
                    phaseMultiplier: phaseMultiplier,
                    emoji: "🟢",
                    color: "text-green-600"
                )
            }
            return BenchmarkReadiness(
                tier: .peak,
                reason: "Follicular phase — energy building",
                recommendation: "You're in a high-energy window. Make the most of it!",
                phaseMultiplier: phaseMultiplier,
                emoji: "🟢",
                color: "text-green-600"
            )

        case .ovulation:
            // Peak performance phase
            return BenchmarkReadiness(
                tier: .peak,
                reason: "Ovulation phase — peak performance window!",
                recommendation: "Estrogen and testosterone peak. This is THE time for PRs and max effort.",
                phaseMultiplier: phaseMultiplier,
                emoji: "🟢",
                color: "text-green-600"
            )

        case .luteal:
            // Maintenance phase
            if intensity.rawValue >= 5 || hasHeavyTag {
                return BenchmarkReadiness(
                    tier: .recovery,
                    reason: "Luteal phase — body preparing for Shark Week",
                    recommendation: "Consider saving max effort for your follicular phase.",
                    phaseMultiplier: phaseMultiplier,
                    emoji: "🔴",
                    color: "text-warm-rose"
                )
            }
            if intensity.rawValue >= 4 {
                return BenchmarkReadiness(
                    tier: .moderate,
                    reason: "Luteal phase — energy may be declining",
                    recommendation: "You can do this, but listen to your body. Scale if needed.",
                    phaseMultiplier: phaseMultiplier,
                    emoji: "🟡",
                    color: "text-gold"
                )
            }
            return BenchmarkReadiness(
                tier: .moderate,
                reason: "Luteal phase — maintenance mode",
                recommendation: "Good for technique work and moderate intensity.",
                phaseMultiplier: phaseMultiplier,
                emoji: "🟡",
                color: "text-gold"
            )
        }
    }

    /// Get best days to attempt a benchmark based on cycle history
    public static func getBestAttemptWindow(
        averageCycleLength: Int,
        lastPeriodStart: Date
    ) -> AttemptWindow {
        // Ovulation window is typically days 12-16 of a 28-day cycle
        // Adjust based on actual cycle length
        let ovulationDay = Int(Double(averageCycleLength) * 0.45) // ~45% into cycle
        let windowStart = ovulationDay - 2
        let windowEnd = ovulationDay + 2

        let startDate = Calendar.current.date(byAdding: .day, value: windowStart, to: lastPeriodStart) ?? lastPeriodStart
        let endDate = Calendar.current.date(byAdding: .day, value: windowEnd, to: lastPeriodStart) ?? lastPeriodStart

        return AttemptWindow(
            startDate: startDate,
            endDate: endDate,
            reason: "Your ovulation window — estrogen and testosterone peak for maximum power output."
        )
    }
}

// MARK: - Cycle Phase Multiplier Helper

/// Helper for getting cycle phase multipliers
enum CyclePhaseMultiplier {
    static func multiplier(for phase: CyclePhase) -> Double {
        switch phase {
        case .menstrual:
            return 0.85
        case .follicular:
            return 1.0
        case .ovulation:
            return 1.05
        case .luteal:
            return 0.95
        }
    }
}
