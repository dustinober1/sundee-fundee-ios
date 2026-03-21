import Foundation

public struct ProgramValidationError: Sendable {
    public let field: String
    public let message: String
    public init(field: String, message: String) { self.field = field; self.message = message }
}

public enum ProgramValidator {
    public static func validate(_ program: Program) -> [ProgramValidationError] {
        var errors: [ProgramValidationError] = []
        if program.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "name", message: "Name is required"))
        }
        if program.id.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "id", message: "ID is required"))
        } else {
            let slugRegex = /^[a-z0-9]+(-[a-z0-9]+)*$/
            if program.id.wholeMatch(of: slugRegex) == nil {
                errors.append(.init(field: "id", message: "ID must be a valid slug (lowercase, hyphens only)"))
            }
        }
        if program.durationWeeks != program.weeks.count {
            errors.append(.init(field: "durationWeeks", message: "Duration (\(program.durationWeeks)) doesn't match week count (\(program.weeks.count))"))
        }
        let phaseIDs = Set(program.phases.map(\.id))
        for (i, week) in program.weeks.enumerated() {
            if week.sessions.isEmpty {
                errors.append(.init(field: "weeks[\(i)]", message: "Week \(week.week) has no sessions"))
            }
            if let phaseID = week.phaseID, !phaseIDs.contains(phaseID) {
                errors.append(.init(field: "weeks[\(i)].phaseID", message: "Week \(week.week) references unknown phase '\(phaseID)'"))
            }
            for (j, session) in week.sessions.enumerated() {
                if session.exercises.isEmpty {
                    errors.append(.init(field: "weeks[\(i)].sessions[\(j)]", message: "Session '\(session.sessionName)' has no exercises"))
                }
                for (k, exercise) in session.exercises.enumerated() {
                    if exercise.exercise.trimmingCharacters(in: .whitespaces).isEmpty {
                        errors.append(.init(field: "weeks[\(i)].sessions[\(j)].exercises[\(k)]", message: "Exercise name is empty"))
                    }
                    if let pct = exercise.percent1RM, (pct < 0.0 || pct > 1.5) {
                        errors.append(.init(field: "weeks[\(i)].sessions[\(j)].exercises[\(k)].percent1RM", message: "percent1RM \(pct) must be between 0.0 and 1.5"))
                    }
                }
            }
        }
        return errors
    }
}
