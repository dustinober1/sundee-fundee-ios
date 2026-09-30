import Foundation

// MARK: - CycleTrackingMode

/// The tracking and adaptation mode representing the user's hormonal baseline.
public enum CycleTrackingMode: String, Codable, Sendable, CaseIterable {
    /// Natural 4-phase ovulatory cycle.
    case standard

    /// Hormonal contraceptive (monophasic pill, patch, ring, implant, hormonal IUD).
    /// Suppresses natural ovulation; keeps hormones at a steady baseline.
    case contraceptive

    /// Irregular cycles, PCOS, or cycle lengths exceeding standard thresholds.
    /// Emphasizes objective biomarkers and wide confidence intervals.
    case irregular

    /// Perimenopausal transition characterized by fluctuating cycle lengths,
    /// vasomotor episodes, and joint sensitivity.
    case perimenopause

    public var displayName: String {
        switch self {
        case .standard:
            return "Standard Natural Cycle"
        case .contraceptive:
            return "Hormonal Contraceptive / Steady"
        case .irregular:
            return "Irregular Cycle / PCOS"
        case .perimenopause:
            return "Perimenopause Transition"
        }
    }

    public var shortDescription: String {
        switch self {
        case .standard:
            return "Four distinct phases. Adapts periodization to natural follicular and luteal shifts."
        case .contraceptive:
            return "Suppresses ovulation and stabilizes hormone levels. Focuses on sleep, nocturnal HRV, and subjective energy rather than artificial phase estimates."
        case .irregular:
            return "Accommodates cycle length variability. Widens prediction windows and anchors training to daily readiness and objective biomarkers."
        case .perimenopause:
            return "Supports fluctuating hormonal baselines. Emphasizes joint prep, extended warmups, and sleep-deficit autoregulation."
        }
    }

    /// Whether cyclical phase predictions (follicular/ovulation/luteal) should be calculated and displayed.
    /// In contraceptive mode, ovulation does not occur so artificial phase estimates are suppressed.
    public var supportsPhasePrediction: Bool {
        switch self {
        case .standard, .irregular, .perimenopause:
            return true
        case .contraceptive:
            return false
        }
    }
}
