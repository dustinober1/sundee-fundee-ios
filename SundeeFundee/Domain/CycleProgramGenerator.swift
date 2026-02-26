import Foundation

// MARK: - CycleProgramGenerator

/// Adapts a Program's exercises for the user's current cycle phase.
/// Returns the same program unchanged when adaptation is disabled or no phase is available.
enum CycleProgramGenerator {

    static func adaptProgram(
        _ program: Program,
        phase: CyclePhase?,
        settings: CycleSettings?,
        preferences: CycleAdaptationPreferences?,
        periodLogs: [PeriodLog],
        referenceDate: Date = .now
    ) -> Program {
        // Guest users or opt-out: return unchanged
        guard let preferences, preferences.adaptationEnabled else { return program }
        guard let cycleSettings = settings else { return program }

        let policy = CycleAdaptationPolicy()

        // Determine effective phase
        let status = CycleCalculations.calculateCycleStatus(
            periodLogs: periodLogs,
            settings: cycleSettings,
            referenceDate: referenceDate
        )
        let currentPhase  = status?.currentPhase
        let effectivePhase = policy.resolvePhase(
            currentPhase: currentPhase,
            lastKnownPhase: phase,
            fallbackPhase: preferences.fallbackPhase
        )

        // Determine confidence
        let lastPeriodStart = periodLogs.max(by: { $0.startDate < $1.startDate })?.startDate
        let confidence = policy.resolveConfidence(
            currentPhase: currentPhase,
            lastKnownPhase: phase,
            periodLogCount: periodLogs.count,
            lastPeriodStart: lastPeriodStart,
            referenceDate: referenceDate
        )

        let readiness = policy.resolveReadinessTier(readinessScore: nil)

        // Adapt each week's sessions
        let adaptedWeeks = program.weeks.map { week in
            ProgramWeek(
                week: week.week,
                phaseID: week.phaseID,
                isTestWeek: week.isTestWeek,
                sessions: week.sessions.map { session in
                    ProgramSession(
                        sessionID: session.sessionID,
                        sessionName: session.sessionName,
                        sessionType: session.sessionType,
                        focus: session.focus,
                        exercises: session.exercises.map { ex in
                            policy.applyPhaseAdjustment(
                                exercise: ex,
                                phase: effectivePhase,
                                readinessTier: readiness,
                                confidence: confidence,
                                profile: program.cycleAdjustmentProfile
                            )
                        }
                    )
                }
            )
        }

        return Program(
            id: program.id,
            name: program.name,
            category: program.category,
            description: program.description,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek,
            difficulty: program.difficulty,
            phases: program.phases,
            weeks: adaptedWeeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }
}
