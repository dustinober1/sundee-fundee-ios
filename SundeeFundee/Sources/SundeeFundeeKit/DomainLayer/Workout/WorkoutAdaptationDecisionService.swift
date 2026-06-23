import Foundation

public enum WorkoutUndoResult: Sendable, Equatable {
    case restored(Workout)
    case blocked(reason: String)
}

public enum WorkoutAdaptationDecisionService {
    public static func makeRecord(
        originalWorkout: Workout,
        adaptedWorkout: Workout,
        summary: ProgramAdaptationSummary,
        context: ProgramSessionAdaptationContext,
        additionalReasons: [(id: String, text: String)] = [],
        dateCreated: Date = Date()
    ) throws -> WorkoutAdaptationDecisionRecord {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let originalData = try encoder.encode(originalWorkout)
        let adaptedData = try encoder.encode(adaptedWorkout)
        let reasons = reasonDetails(
            summary: summary,
            context: context,
            additionalReasons: additionalReasons
        )

        return WorkoutAdaptationDecisionRecord(
            workoutID: adaptedWorkout.id,
            originalWorkoutJSON: String(decoding: originalData, as: UTF8.self),
            adaptedWorkoutJSON: String(decoding: adaptedData, as: UTF8.self),
            reasonIDs: reasons.map(\.id),
            reasonText: reasons.map(\.text),
            dateCreated: dateCreated
        )
    }

    @discardableResult
    public static func record(
        originalWorkout: Workout,
        adaptedWorkout: Workout,
        summary: ProgramAdaptationSummary,
        context: ProgramSessionAdaptationContext,
        additionalReasons: [(id: String, text: String)] = [],
        dataClient: DataClientProtocol,
        dateCreated: Date = Date()
    ) async throws -> WorkoutAdaptationDecisionRecord {
        let record = try makeRecord(
            originalWorkout: originalWorkout,
            adaptedWorkout: adaptedWorkout,
            summary: summary,
            context: context,
            additionalReasons: additionalReasons,
            dateCreated: dateCreated
        )
        try await dataClient.save(record, recordType: "WorkoutAdaptationDecisionRecord")
        return record
    }

    public static func undo(
        record: WorkoutAdaptationDecisionRecord,
        currentWorkout: Workout
    ) -> WorkoutUndoResult {
        guard record.workoutID == currentWorkout.id else {
            return .blocked(reason: "These changes belong to a different workout, so they can't be undone here.")
        }

        guard !hasLoggedProgress(currentWorkout) else {
            return .blocked(reason: "Changes can only be undone before you log a set.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = record.originalWorkoutJSON.data(using: .utf8),
              var restored = try? decoder.decode(Workout.self, from: data) else {
            return .blocked(reason: "We couldn't restore the original plan. Please start from the program again.")
        }

        restored.date = currentWorkout.date
        return .restored(restored)
    }

    private static func hasLoggedProgress(_ workout: Workout) -> Bool {
        workout.exercises.contains { exercise in
            exercise.targetSets.contains { set in
                set.isComplete || set.actualReps != nil || set.completedWeight != nil
            }
        }
    }

    private static func reasonDetails(
        summary: ProgramAdaptationSummary,
        context: ProgramSessionAdaptationContext,
        additionalReasons: [(id: String, text: String)]
    ) -> [(id: String, text: String)] {
        let changedCodes = Set(summary.changes.map(\.reasonCode))
        var details: [(id: String, text: String)] = []

        if changedCodes.contains(.cycleAdjustment), let phase = context.cyclePhase {
            details.append(("cycle", "Cycle phase: \(phase.rawValue)."))
        } else if changedCodes.contains(.cycleAdjustment) {
            details.append(("cycle", "Cycle phase adjusted today's load, reps, or rest."))
        }

        if changedCodes.contains(.deloadAdjustment) {
            details.append(("deload", "Deload context adjusted today's volume and intensity."))
        }

        if (changedCodes.contains(.painAdjustment) || changedCodes.contains(.injurySwap)),
           let pain = context.painIntensity {
            details.append(("pain", "Pain check-in \(pain)/10 reduced today's strain."))
        } else if changedCodes.contains(.painAdjustment) || changedCodes.contains(.injurySwap) {
            details.append(("pain", "Pain or injury context adjusted today's exercise choices."))
        }

        if changedCodes.contains(.equipmentConversion), let equipment = context.equipment {
            details.append(("equipment", "Equipment matched to \(equipmentDecisionName(equipment))."))
        } else if changedCodes.contains(.equipmentConversion) {
            details.append(("equipment", "Exercises were converted for your available equipment."))
        }

        if !changedCodes.isEmpty,
           let recentEffortRPE = context.recentEffortRPE,
            (changedCodes.contains(.deloadAdjustment)
                || changedCodes.contains(.painAdjustment)
                || changedCodes.contains(.cycleAdjustment)) {
            details.append(("effort", "Recent effort RPE \(recentEffortRPE) kept today's work in check."))
        }

        details.append(contentsOf: additionalReasons)

        if details.isEmpty, !summary.changes.isEmpty {
            details.append(("adaptation", summary.headline))
        }

        return details
    }

    private static func equipmentDecisionName(_ equipment: EquipmentAccess) -> String {
        switch equipment {
        case .homeDumbbells:
            return "Home Dumbbells"
        default:
            return equipment.displayName
        }
    }
}
