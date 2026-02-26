import SwiftData
import Foundation

enum FlowLevel: String, Codable, CaseIterable {
    case light, medium, heavy, spotting
}

@Model
final class PeriodLog {
    @Attribute(.unique) var id: String
    var userID: String
    var startDate: Date
    var endDate: Date?
    var flowLevelRaw: String
    var notes: String?

    init(
        id: String,
        userID: String,
        startDate: Date,
        endDate: Date? = nil,
        flowLevel: FlowLevel = .medium,
        notes: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevelRaw = flowLevel.rawValue
        self.notes = notes
    }

    var flowLevel: FlowLevel {
        get { FlowLevel(rawValue: flowLevelRaw) ?? .medium }
        set { flowLevelRaw = newValue.rawValue }
    }
}

@Model
final class SymptomLog {
    @Attribute(.unique) var id: String
    var userID: String
    var date: Date
    var symptomID: String
    var severity: Int   // 1–5
    var notes: String?

    init(
        id: String,
        userID: String,
        date: Date,
        symptomID: String,
        severity: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.date = date
        self.symptomID = symptomID
        self.severity = min(5, max(1, severity))
        self.notes = notes
    }
}

@Model
final class CycleSettings {
    @Attribute(.unique) var id: String
    var userID: String
    var averageCycleLengthDays: Int
    var isTrackingEnabled: Bool
    var updatedAt: Date

    init(
        id: String,
        userID: String,
        averageCycleLengthDays: Int = 28,
        isTrackingEnabled: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.averageCycleLengthDays = averageCycleLengthDays
        self.isTrackingEnabled = isTrackingEnabled
        self.updatedAt = updatedAt
    }
}

@Model
final class CycleAdaptationPreferences {
    @Attribute(.unique) var id: String
    var userID: String
    var adaptationEnabled: Bool
    var fallbackPhase: String
    var updatedAt: Date

    init(
        id: String,
        userID: String,
        adaptationEnabled: Bool = true,
        fallbackPhase: String = "follicular",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.adaptationEnabled = adaptationEnabled
        self.fallbackPhase = fallbackPhase
        self.updatedAt = updatedAt
    }
}
