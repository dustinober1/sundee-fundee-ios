import Foundation
import SwiftData

@Model
final class PeriodLog {
    var id: String = UUID().uuidString
    var userId: String = ""
    var startDate: Date = Date.now
    var endDate: Date?
    var flowLevelRaw: String = FlowLevel.medium.rawValue
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
    var id: String = UUID().uuidString
    var userId: String = ""
    var date: Date = Date.now
    var symptomId: String = ""
    var severity: Int = 1
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
    var id: String = UUID().uuidString
    var userId: String = ""
    var date: Date = Date.now
    var temperature: Double = 0
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
    var id: String = UUID().uuidString
    var name: String = ""
    var categoryRaw: String = SymptomCategory.physical.rawValue
    var isDefault: Bool = true
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
    var id: String = UUID().uuidString
    var userId: String = ""
    var averageCycleLength: Int = 28
    var averagePeriodLength: Int = 5
    var lutealPhaseLength: Int = 14
    var enabledSymptomIds: [String] = []
    var notificationsEnabled: Bool = false

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
