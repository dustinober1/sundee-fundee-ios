import Foundation
import SwiftData

@MainActor
@Observable
final class MaxLiftsViewModel {
    var exerciseNames: [String] = []
    var oneRepMaxes: [String: OneRepMax] = [:]
    var personalRecords: [String: [PersonalRecord]] = [:]

    private var modelContext: ModelContext?
    private var userID: String = ""

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        let repo = SwiftDataLiftRepository(context: modelContext)

        let orms = (try? repo.fetchOneRepMaxes()) ?? []
        let prs = (try? repo.fetchPersonalRecords()) ?? []

        // Build exercise name index from all tracked data
        var names = Set<String>()
        orms.forEach { names.insert($0.exerciseID) }
        prs.forEach { names.insert($0.exerciseID) }
        exerciseNames = names.sorted()

        // Build lookup dicts (latest 1RM per exercise)
        var ormDict: [String: OneRepMax] = [:]
        for orm in orms {
            if let existing = ormDict[orm.exerciseID] {
                if orm.date > existing.date { ormDict[orm.exerciseID] = orm }
            } else {
                ormDict[orm.exerciseID] = orm
            }
        }
        oneRepMaxes = ormDict

        // Group PRs by exercise
        var prDict: [String: [PersonalRecord]] = [:]
        for pr in prs {
            prDict[pr.exerciseID, default: []].append(pr)
        }
        personalRecords = prDict
    }

    func addMax(exercise: String, weightKg: Double, reps: Int, isEstimated: Bool) {
        guard let ctx = modelContext else { return }
        let repo = SwiftDataLiftRepository(context: ctx)

        // Always save LiftMax
        let liftMax = LiftMax(
            id: UUID().uuidString,
            userID: userID,
            exerciseID: exercise,
            weightKg: weightKg
        )
        try? repo.saveLiftMax(liftMax)

        // If reps == 1, also update OneRepMax
        if reps == 1 {
            let orm = OneRepMax(
                id: UUID().uuidString,
                userID: userID,
                exerciseID: exercise,
                weightKg: weightKg,
                isEstimated: isEstimated
            )
            try? repo.saveOneRepMax(orm)
            oneRepMaxes[exercise] = orm
        }

        if !exerciseNames.contains(exercise) {
            exerciseNames.append(exercise)
            exerciseNames.sort()
        }
    }
}
