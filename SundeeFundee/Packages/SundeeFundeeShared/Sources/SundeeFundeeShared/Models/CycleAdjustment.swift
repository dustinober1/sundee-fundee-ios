import Foundation

public struct ProgramCycleAdjustmentProfile: Codable, Sendable {
    public let fallbackPhase: String
    public let lowConfidenceScale: Double
    public let phaseSettings: [String: ProgramPhaseAdjustmentSettings]

    public init(fallbackPhase: String = "follicular", lowConfidenceScale: Double = 0.7, phaseSettings: [String: ProgramPhaseAdjustmentSettings] = [:]) {
        self.fallbackPhase = fallbackPhase; self.lowConfidenceScale = lowConfidenceScale; self.phaseSettings = phaseSettings
    }
}

public struct ProgramPhaseAdjustmentSettings: Codable, Sendable {
    public let loadMultiplier: Double
    public let setsMultiplier: Double
    public let repsMultiplier: Double

    public init(loadMultiplier: Double = 1.0, setsMultiplier: Double = 1.0, repsMultiplier: Double = 1.0) {
        self.loadMultiplier = loadMultiplier; self.setsMultiplier = setsMultiplier; self.repsMultiplier = repsMultiplier
    }
}
