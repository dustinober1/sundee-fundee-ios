import Foundation

enum ProgramAvailability: Equatable, Sendable {
    case upcoming(startDate: Date)
    case active
    case past

    static func status(for program: Program, now: Date = .now) -> ProgramAvailability {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        if let startString = program.startDate,
           let start = Self.parseDate(startString) {
            let startDay = calendar.startOfDay(for: start)
            if startDay > today {
                return .upcoming(startDate: start)
            }
        }

        if let endString = program.endDate,
           let end = Self.parseDate(endString) {
            let endDay = calendar.startOfDay(for: end)
            if endDay < today {
                return .past
            }
        }

        return .active
    }

    static func sortedPrograms(_ programs: [Program], now: Date = .now) -> [Program] {
        programs.sorted { a, b in
            let statusA = status(for: a, now: now)
            let statusB = status(for: b, now: now)
            return sortOrder(statusA) < sortOrder(statusB)
        }
    }

    static func nextUpcomingProgram(from programs: [Program], now: Date = .now) -> Program? {
        programs
            .filter {
                if case .upcoming = status(for: $0, now: now) { return true }
                return false
            }
            .sorted {
                (parseDate($0.startDate ?? "") ?? .distantFuture) < (parseDate($1.startDate ?? "") ?? .distantFuture)
            }
            .first
    }

    private static func sortOrder(_ availability: ProgramAvailability) -> Int {
        switch availability {
        case .active: return 0
        case .upcoming: return 1
        case .past: return 2
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    static func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    static func formattedStartDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
