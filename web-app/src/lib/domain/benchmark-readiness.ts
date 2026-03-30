import type { CyclePhase } from "./types";
import { PHASE_MULTIPLIERS } from "./cycle-adaptation-policy";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ReadinessTier = "peak" | "moderate" | "recovery";

export interface BenchmarkReadiness {
  tier: ReadinessTier;
  reason: string;
  recommendation: string;
  phaseMultiplier: number;
  emoji: string;
  color: string;
}

// ---------------------------------------------------------------------------
// Phase-based recommendations
// ---------------------------------------------------------------------------

const PHASE_RECOMMENDATIONS: Record<CyclePhase, { peak: string[]; moderate: string[]; recovery: string[] }> = {
  menstrual: {
    peak: ["light cardio", "yoga", "walking", "stretching"],
    moderate: ["technique work", "light strength", "low-impact cardio"],
    recovery: ["heavy lifts", "max effort", "high intensity"],
  },
  follicular: {
    peak: ["strength training", "building volume", "new skills", "PR attempts"],
    moderate: ["moderate cardio", "conditioning", "gymnastics"],
    recovery: ["max effort if feeling fatigued"],
  },
  ovulation: {
    peak: ["PR attempts", "heavy lifts", "max effort", "power work"],
    moderate: ["high intensity", "competition prep"],
    recovery: ["light recovery if needed"],
  },
  luteal: {
    peak: ["technique refinement", "moderate volume", "endurance work"],
    moderate: ["strength maintenance", "light cardio", "flexibility"],
    recovery: ["max effort attempts", "heavy compound lifts"],
  },
};

// ---------------------------------------------------------------------------
// Readiness calculation
// ---------------------------------------------------------------------------

/**
 * Calculate benchmark readiness based on cycle phase and benchmark characteristics.
 *
 * @param phase - Current cycle phase (null if not tracking)
 * @param benchmarkIntensity - Benchmark intensity 1-5
 * @param benchmarkTags - Movement tags like "Heavy Pull", "High Cardio"
 * @returns BenchmarkReadiness with tier, reason, and recommendation
 */
export function calculateBenchmarkReadiness(
  phase: CyclePhase | null,
  benchmarkIntensity: number | undefined,
  benchmarkTags: string[] | undefined
): BenchmarkReadiness {
  // No cycle data - return neutral
  if (phase == null) {
    return {
      tier: "moderate",
      reason: "No cycle data available",
      recommendation: "Log your period to get personalized recommendations.",
      phaseMultiplier: 1.0,
      emoji: "⚪",
      color: "text-text-secondary",
    };
  }

  const intensity = benchmarkIntensity ?? 3;
  const tags = benchmarkTags ?? [];
  const phaseMultiplier = PHASE_MULTIPLIERS[phase]?.load ?? 1.0;

  // Check for high-intensity tags
  const hasHeavyTag = tags.some((t) =>
    t.toLowerCase().includes("heavy") ||
    t.toLowerCase().includes("max") ||
    t.toLowerCase().includes("high volume")
  );
  const hasHighCardio = tags.some((t) =>
    t.toLowerCase().includes("cardio") ||
    t.toLowerCase().includes("sprint") ||
    t.toLowerCase().includes("high intensity")
  );

  // Determine tier based on phase + intensity
  switch (phase) {
    case "menstrual": {
      // Recovery phase - avoid high intensity
      if (intensity >= 4 || hasHeavyTag || hasHighCardio) {
        return {
          tier: "recovery",
          reason: "Menstrual phase — energy typically lower",
          recommendation: "Consider saving this for later. Focus on light movement today.",
          phaseMultiplier,
          emoji: "🔴",
          color: "text-warm-rose",
        };
      }
      return {
        tier: "moderate",
        reason: "Menstrual phase — listen to your body",
        recommendation: "Light to moderate intensity is fine. Scale as needed.",
        phaseMultiplier,
        emoji: "🟡",
        color: "text-gold",
      };
    }

    case "follicular": {
      // Building phase - good for most things
      if (intensity <= 3) {
        return {
          tier: "peak",
          reason: "Follicular phase — great for building",
          recommendation: "Your body is primed for strength and skill work. Go for it!",
          phaseMultiplier,
          emoji: "🟢",
          color: "text-green-600",
        };
      }
      if (intensity >= 4 || hasHeavyTag) {
        return {
          tier: "peak",
          reason: "Follicular phase — strength window",
          recommendation: "Estrogen is rising. Great time for PR attempts!",
          phaseMultiplier,
          emoji: "🟢",
          color: "text-green-600",
        };
      }
      return {
        tier: "peak",
        reason: "Follicular phase — energy building",
        recommendation: "You're in a high-energy window. Make the most of it!",
        phaseMultiplier,
        emoji: "🟢",
        color: "text-green-600",
      };
    }

    case "ovulation": {
      // Peak performance phase
      return {
        tier: "peak",
        reason: "Ovulation phase — peak performance window!",
        recommendation: "Estrogen and testosterone peak. This is THE time for PRs and max effort.",
        phaseMultiplier,
        emoji: "🟢",
        color: "text-green-600",
      };
    }

    case "luteal": {
      // Maintenance phase
      if (intensity >= 5 || hasHeavyTag) {
        return {
          tier: "recovery",
          reason: "Luteal phase — body preparing for menstruation",
          recommendation: "Consider saving max effort for your follicular phase.",
          phaseMultiplier,
          emoji: "🔴",
          color: "text-warm-rose",
        };
      }
      if (intensity >= 4) {
        return {
          tier: "moderate",
          reason: "Luteal phase — energy may be declining",
          recommendation: "You can do this, but listen to your body. Scale if needed.",
          phaseMultiplier,
          emoji: "🟡",
          color: "text-gold",
        };
      }
      return {
        tier: "moderate",
        reason: "Luteal phase — maintenance mode",
        recommendation: "Good for technique work and moderate intensity.",
        phaseMultiplier,
        emoji: "🟡",
        color: "text-gold",
      };
    }

    default:
      return {
        tier: "moderate",
        reason: "Unknown phase",
        recommendation: "Listen to your body and train accordingly.",
        phaseMultiplier: 1.0,
        emoji: "⚪",
        color: "text-text-secondary",
      };
  }
}

/**
 * Get best days to attempt a benchmark based on cycle history.
 *
 * @param averageCycleLength - User's average cycle length in days
 * @param lastPeriodStart - Start date of last period
 * @returns Object with best window dates and reason
 */
export function getBestAttemptWindow(
  averageCycleLength: number,
  lastPeriodStart: Date
): { startDate: Date; endDate: Date; reason: string } {
  // Ovulation window is typically days 12-16 of a 28-day cycle
  // Adjust based on actual cycle length
  const ovulationDay = Math.round(averageCycleLength * 0.45); // ~45% into cycle
  const windowStart = ovulationDay - 2;
  const windowEnd = ovulationDay + 2;

  const startDate = new Date(lastPeriodStart);
  startDate.setDate(startDate.getDate() + windowStart);

  const endDate = new Date(lastPeriodStart);
  endDate.setDate(endDate.getDate() + windowEnd);

  return {
    startDate,
    endDate,
    reason: "Your ovulation window — estrogen and testosterone peak for maximum power output.",
  };
}
