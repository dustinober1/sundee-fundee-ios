import CloudKit

public enum ProgramDecodingError: Error, Sendable {
    case missingFields
}

extension Program {
    public init(from record: CKRecord) throws {
        guard
            let id = record["id"] as? String,
            let name = record["name"] as? String,
            let category = record["category"] as? String,
            let description = record["description"] as? String,
            let durationWeeks = record["durationWeeks"] as? Int,
            let sessionsPerWeek = record["sessionsPerWeek"] as? Int,
            let difficulty = record["difficulty"] as? String,
            let weeksJSON = record["weeksJSON"] as? String,
            let weeksData = weeksJSON.data(using: .utf8)
        else { throw ProgramDecodingError.missingFields }

        let weeks = try JSONDecoder().decode([ProgramWeek].self, from: weeksData)

        var adjustmentProfile: ProgramCycleAdjustmentProfile?
        if let profileJSON = record["cycleAdjustmentProfileJSON"] as? String,
           let profileData = profileJSON.data(using: .utf8) {
            adjustmentProfile = try? JSONDecoder().decode(ProgramCycleAdjustmentProfile.self, from: profileData)
        }

        var phases: [ProgramPhase] = []
        if let phasesJSON = record["phasesJSON"] as? String,
           let phasesData = phasesJSON.data(using: .utf8) {
            phases = (try? JSONDecoder().decode([ProgramPhase].self, from: phasesData)) ?? []
        }

        self.init(id: id, name: name, category: category, description: description,
                  durationWeeks: durationWeeks, sessionsPerWeek: sessionsPerWeek,
                  difficulty: difficulty, phases: phases, weeks: weeks,
                  cycleAdjustmentProfile: adjustmentProfile)
    }

    public func toCKRecord(recordID: CKRecord.ID? = nil) -> CKRecord {
        let record = CKRecord(recordType: "Program",
                              recordID: recordID ?? CKRecord.ID(recordName: id))
        record["id"] = id as CKRecordValue
        record["name"] = name as CKRecordValue
        record["category"] = category as CKRecordValue
        record["description"] = description as CKRecordValue
        record["durationWeeks"] = durationWeeks as CKRecordValue
        record["sessionsPerWeek"] = sessionsPerWeek as CKRecordValue
        record["difficulty"] = difficulty as CKRecordValue

        let encoder = JSONEncoder()
        if let weeksData = try? encoder.encode(weeks),
           let weeksJSON = String(data: weeksData, encoding: .utf8) {
            record["weeksJSON"] = weeksJSON as CKRecordValue
        }
        if let phasesData = try? encoder.encode(phases),
           let phasesJSON = String(data: phasesData, encoding: .utf8) {
            record["phasesJSON"] = phasesJSON as CKRecordValue
        }
        if let profile = cycleAdjustmentProfile,
           let profileData = try? encoder.encode(profile),
           let profileJSON = String(data: profileData, encoding: .utf8) {
            record["cycleAdjustmentProfileJSON"] = profileJSON as CKRecordValue
        }
        return record
    }
}
