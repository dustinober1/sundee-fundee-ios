import Foundation
import SwiftData

@Model
final class PeriodLog {
    @Attribute(.unique) var id: String
    var userId: String
    var startDate: Date
    var endDate: Date?
    var flowLevelRaw: String
    var notes: String?

    var flowLevel: FlowLevel {
        get { FlowLevel(rawValue: flowLevelRaw) ?? .medium }
        set { flowLevelRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        startDate: Date,
        endDate: Date? = nil,
        flowLevel: FlowLevel = .medium,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevelRaw = flowLevel.rawValue
        self.notes = notes
    }
}

@Model
final class SymptomLog {
    @Attribute(.unique) var id: String
    var userId: String
    var date: Date
    var symptomId: String
    var severity: Int
    var notes: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date = .now,
        symptomId: String,
        severity: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.symptomId = symptomId
        self.severity = min(max(severity, 1), 5)
        self.notes = notes
    }
}

@Model
final class BBTLog {
    @Attribute(.unique) var id: String
    var userId: String
    var date: Date
    var temperature: Double
    var time: Date?
    var notes: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date = .now,
        temperature: Double,
        time: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.temperature = temperature
        self.time = time
        self.notes = notes
    }
}

@Model
final class SymptomDefinition {
    @Attribute(.unique) var id: String
    var name: String
    var categoryRaw: String
    var isDefault: Bool
    var userId: String?

    var category: SymptomCategory {
        get { SymptomCategory(rawValue: categoryRaw) ?? .physical }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        category: SymptomCategory,
        isDefault: Bool = true,
        userId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.isDefault = isDefault
        self.userId = userId
    }
}

@Model
final class CycleSettings {
    @Attribute(.unique) var id: String
    var userId: String
    var averageCycleLength: Int
    var averagePeriodLength: Int
    var lutealPhaseLength: Int
    var enabledSymptomIds: [String]
    var notificationsEnabled: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        averageCycleLength: Int = 28,
        averagePeriodLength: Int = 5,
        lutealPhaseLength: Int = 14,
        enabledSymptomIds: [String] = [],
        notificationsEnabled: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.lutealPhaseLength = lutealPhaseLength
        self.enabledSymptomIds = enabledSymptomIds
        self.notificationsEnabled = notificationsEnabled
    }
}
