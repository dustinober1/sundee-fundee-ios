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
        referenceDate: Date = .now,
        readinessScore: Double? = nil
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

        let readiness = policy.resolveReadinessTier(readinessScore: readinessScore)

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
                            let adapted = policy.applyPhaseAdjustment(
                                exercise: ex,
                                phase: effectivePhase,
                                readinessTier: readiness,
                                confidence: confidence,
                                profile: program.cycleAdjustmentProfile
                            )
                            let cycleNote = Self.cycleAdjustmentNote(
                                original: ex,
                                adapted: adapted,
                                phase: effectivePhase
                            )
                            guard let cycleNote else { return adapted }
                            let combinedNote = [ex.notes, cycleNote]
                                .compactMap { $0 }
                                .joined(separator: " · ")
                            return ProgramExercise(
                                exercise: adapted.exercise,
                                variant: adapted.variant,
                                sets: adapted.sets,
                                reps: adapted.reps,
                                percent1RM: adapted.percent1RM,
                                restMinutes: adapted.restMinutes,
                                notes: combinedNote,
                                bodyweightOnly: adapted.bodyweightOnly
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
            cycleAdjustmentProfile: program.cycleAdjustmentProfile,
            weeks: adaptedWeeks
        )
    }

    // MARK: - Note generation

    /// Returns a note string describing the original prescription and the cycle-adjusted values,
    /// or nil if no meaningful adjustment was made.
    static func cycleAdjustmentNote(
        original: ProgramExercise,
        adapted: ProgramExercise,
        phase: CyclePhase
    ) -> String? {
        let origSets = original.sets.description
        let origReps = original.reps.description
        let adaptSets = adapted.sets.description
        let adaptReps = adapted.reps.description

        let origLoad: String? = original.percent1RM.map { "\(Int(($0 * 100).rounded()))%" }
        let adaptLoad: String? = adapted.percent1RM.map { "\(Int(($0 * 100).rounded()))%" }

        let setsChanged = origSets != adaptSets
        let repsChanged = origReps != adaptReps
        let loadChanged = origLoad != adaptLoad

        guard setsChanged || repsChanged || loadChanged else { return nil }

        let origScheme = formatScheme(sets: origSets, reps: origReps, load: origLoad)
        let adaptScheme = formatScheme(sets: adaptSets, reps: adaptReps, load: adaptLoad)

        return "Program: \(origScheme) → \(phase.displayName): \(adaptScheme)"
    }

    private static func formatScheme(sets: String, reps: String, load: String?) -> String {
        if let load {
            return "\(sets)×\(reps) @ \(load)"
        }
        return "\(sets)×\(reps)"
    }
}
