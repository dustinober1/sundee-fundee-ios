import SwiftData
import Foundation

enum EnrollmentStatus: String, Codable {
    case active, canceled, completed
}

enum EnrollmentEventType: String, Codable {
    case enrolled, canceled, completed, restored, autoHealed = "auto_healed"
}

@Model
final class EnrolledProgram {
    var id: String
    var userID: String
    var programID: String
    var startDate: Date
    var currentWeek: Int
    var currentDay: Int
    var statusRaw: String
    var completedAt: Date?
    var canceledAt: Date?
    /// Completed week numbers, stored as comma-separated ints.
    var completedWeeksRaw: String
    var lastSyncedAt: Date?

    init(
        id: String,
        userID: String,
        programID: String,
        startDate: Date,
        currentWeek: Int = 1,
        currentDay: Int = 1,
        status: EnrollmentStatus = .active,
        completedAt: Date? = nil,
        canceledAt: Date? = nil,
        completedWeeks: [Int] = [],
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.userID = userID
        self.programID = programID
        self.startDate = startDate
        self.currentWeek = currentWeek
        self.currentDay = currentDay
        self.statusRaw = status.rawValue
        self.completedAt = completedAt
        self.canceledAt = canceledAt
        self.completedWeeksRaw = completedWeeks.sorted().map(String.init).joined(separator: ",")
        self.lastSyncedAt = lastSyncedAt
    }

    var status: EnrollmentStatus {
        get { EnrollmentStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var isActive: Bool { status == .active }

    var completedWeeks: [Int] {
        get {
            completedWeeksRaw
                .split(separator: ",")
                .compactMap { Int($0) }
                .sorted()
        }
        set {
            completedWeeksRaw = newValue.sorted().map(String.init).joined(separator: ",")
        }
    }
}

@Model
final class EnrollmentEvent {
    var id: String
    var enrollmentID: String
    var eventTypeRaw: String
    var occurredAt: Date
    var programID: String?

    init(
        id: String,
        enrollmentID: String,
        eventType: EnrollmentEventType,
        occurredAt: Date = .now,
        programID: String? = nil
    ) {
        self.id = id
        self.enrollmentID = enrollmentID
        self.eventTypeRaw = eventType.rawValue
        self.occurredAt = occurredAt
        self.programID = programID
    }

    var eventType: EnrollmentEventType {
        get { EnrollmentEventType(rawValue: eventTypeRaw) ?? .enrolled }
        set { eventTypeRaw = newValue.rawValue }
    }
}
