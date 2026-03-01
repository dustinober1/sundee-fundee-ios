import Foundation
import SwiftData

@MainActor
@Observable
final class MaxLiftsViewModel {
    var exerciseNames: [String] = []
    var oneRepMaxes: [String: OneRepMax] = [:]
    var personalRecords: [String: [PersonalRecord]] = [:]
    var liftMaxHistory: [String: [LiftMax]] = [:]
    var conditioningPRs: [ConditioningPR] = []
    var conditioningExerciseNames: [String] = []
    var weightUnit: WeightUnit = .kilograms

    private var modelContext: ModelContext?
    private var userID: String = ""

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        let repo = SwiftDataLiftRepository(context: modelContext)
        let userRepo = SwiftDataUserRepository(context: modelContext)

        let orms = (try? repo.fetchOneRepMaxes()) ?? []
        let prs = (try? repo.fetchPersonalRecords()) ?? []
        weightUnit = (try? userRepo.fetchCurrentUser())?.weightUnit ?? .pounds

        // Build exercise name index from tracked data — weightlifting moves only
        var names = Set<String>()
        orms.forEach { if WeightliftingExerciseCatalog.isWeightliftingExercise($0.exerciseID) { names.insert($0.exerciseID) } }
        prs.forEach  { if WeightliftingExerciseCatalog.isWeightliftingExercise($0.exerciseID) { names.insert($0.exerciseID) } }
        exerciseNames = names.sorted()

        // Build lookup dicts (highest 1RM per exercise)
        oneRepMaxes = Dictionary(grouping: orms, by: \.exerciseID)
            .compactMapValues { $0.max(by: { $0.weightKg < $1.weightKg }) }

        // Build lift max history grouped by exercise
        let allLiftMaxes = (try? repo.fetchLiftMaxes()) ?? []
        liftMaxHistory = Dictionary(grouping: allLiftMaxes, by: \.exerciseID)

        // Group PRs by exercise
        var prDict: [String: [PersonalRecord]] = [:]
        for pr in prs {
            prDict[pr.exerciseID, default: []].append(pr)
        }
        personalRecords = prDict

        // Load conditioning PRs
        let cPRs = (try? repo.fetchAllConditioningPRs()) ?? []
        conditioningPRs = cPRs
        conditioningExerciseNames = Array(Set(cPRs.map(\.exerciseID))).sorted()
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
        liftMaxHistory[exercise, default: []].insert(liftMax, at: 0)

        // Compute the 1RM: actual weight for reps == 1, Epley estimate for reps > 1
        let estimated1RM = EpleyFormula.estimated1RM(weight: weightKg, reps: reps)
        let orm = OneRepMax(
            id: UUID().uuidString,
            userID: userID,
            exerciseID: exercise,
            weightKg: estimated1RM,
            isEstimated: reps > 1 || isEstimated
        )
        try? repo.saveOneRepMax(orm)
        if let existing = oneRepMaxes[exercise] {
            if estimated1RM > existing.weightKg { oneRepMaxes[exercise] = orm }
        } else {
            oneRepMaxes[exercise] = orm
        }

        if !exerciseNames.contains(exercise) {
            exerciseNames.append(exercise)
            exerciseNames.sort()
        }
    }
}
