import CloudKit

public enum WODDecodingError: Error, Sendable {
    case missingFields
}

extension WOD {
    public init(from record: CKRecord) throws {
        guard
            let id = record["id"] as? String,
            let date = record["date"] as? String,
            let title = record["title"] as? String,
            let description = record["description"] as? String,
            let exercisesJSON = record["exercisesJSON"] as? String,
            let exercisesData = exercisesJSON.data(using: .utf8)
        else { throw WODDecodingError.missingFields }

        let exercises = try JSONDecoder().decode([ProgramExercise].self, from: exercisesData)
        self.init(id: id, date: date, title: title, description: description, exercises: exercises)
    }

    public func toCKRecord(recordID: CKRecord.ID? = nil) -> CKRecord {
        let record = CKRecord(recordType: "WOD",
                              recordID: recordID ?? CKRecord.ID(recordName: id))
        record["id"] = id as CKRecordValue
        record["date"] = date as CKRecordValue
        record["title"] = title as CKRecordValue
        record["description"] = description as CKRecordValue

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(exercises),
           let json = String(data: data, encoding: .utf8) {
            record["exercisesJSON"] = json as CKRecordValue
        }
        return record
    }
}
