import Foundation
import SwiftData

@Observable
final class MaxLiftsViewModel {

    private(set) var records: [String: LiftMax] = [:]

    /// Composite key for lookup
    private func key(exerciseId: String, repCount: Int, withStraps: Bool) -> String {
        "\(exerciseId)|\(repCount)|\(withStraps)"
    }

    // MARK: - Load

    func load(userId: String, context: ModelContext) {
        let descriptor = FetchDescriptor<LiftMax>(
            predicate: #Predicate { $0.userId == userId }
        )
        let results = (try? context.fetch(descriptor)) ?? []
        records = [:]
        for r in results {
            let k = key(exerciseId: r.exerciseId, repCount: r.repCount, withStraps: r.withStraps)
            records[k] = r
        }
    }

    // MARK: - Read

    func weight(for exerciseId: String, repCount: Int, withStraps: Bool = false) -> Double? {
        let k = key(exerciseId: exerciseId, repCount: repCount, withStraps: withStraps)
        guard let record = records[k], record.weight > 0 else { return nil }
        return record.weight
    }

    // MARK: - Save / Upsert

    func save(
        userId: String,
        exerciseId: String,
        repCount: Int,
        weight: Double,
        withStraps: Bool = false,
        context: ModelContext
    ) {
        let k = key(exerciseId: exerciseId, repCount: repCount, withStraps: withStraps)

        if let existing = records[k] {
            existing.weight = weight
            existing.updatedAt = .now
        } else {
            let record = LiftMax(
                userId: userId,
                exerciseId: exerciseId,
                repCount: repCount,
                weight: weight,
                withStraps: withStraps
            )
            context.insert(record)
            records[k] = record
        }

        try? context.save()
    }
}
