import Foundation

public enum WODValidator {
    public static func validate(_ wod: WOD) -> [ProgramValidationError] {
        var errors: [ProgramValidationError] = []
        if wod.id.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "id", message: "ID is required"))
        }
        if wod.title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "title", message: "Title is required"))
        }
        if wod.date.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "date", message: "Date is required"))
        } else {
            let dateRegex = /^\d{4}-\d{2}-\d{2}$/
            if wod.date.wholeMatch(of: dateRegex) == nil {
                errors.append(.init(field: "date", message: "Date must be yyyy-MM-dd format"))
            }
        }
        let validTemplateTypes: Set<String> = ["strength", "amrap", "emom", "forTime", "circuit"]
        if !validTemplateTypes.contains(wod.templateType) {
            errors.append(.init(field: "templateType", message: "Invalid template type '\(wod.templateType)'"))
        }
        if wod.exercises.isEmpty {
            errors.append(.init(field: "exercises", message: "At least one exercise is required"))
        }
        for (i, exercise) in wod.exercises.enumerated() {
            if exercise.exercise.trimmingCharacters(in: .whitespaces).isEmpty {
                errors.append(.init(field: "exercises[\(i)]", message: "Exercise name is empty"))
            }
        }
        return errors
    }
}
