import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor GrowthAnalyticsService {
    private let dataClient: DataClientProtocol
    private static let recordType = "GrowthEvent"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func track(
        _ name: String,
        source: String? = nil,
        properties: [String: String] = [:]
    ) async {
        // Analytics is presentation telemetry only. Keep arbitrary callers from
        // accidentally persisting health, cycle, pain, or private-note content.
        let safeSource = Self.isSafeMetadata(source) ? source : nil
        let safeProperties = properties.filter { key, value in
            Self.isSafeMetadata(key) && Self.isSafeMetadata(value)
        }
        let propertiesJSON: String?
        if safeProperties.isEmpty {
            propertiesJSON = nil
        } else if let data = try? JSONEncoder().encode(safeProperties) {
            propertiesJSON = String(data: data, encoding: .utf8)
        } else {
            propertiesJSON = nil
        }

        let event = GrowthEvent(
            name: name,
            source: safeSource,
            propertiesJSON: propertiesJSON
        )

        try? await dataClient.save(event, recordType: Self.recordType)
    }

    private static func isSafeMetadata(_ value: String?) -> Bool {
        guard let value else { return true }
        let normalized = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let prohibited = [
            "healthkit", "health kit", "menstrual", "ovulation", "fertility", "cycle",
            "period", "pain", "sore", "cramp", "symptom", "private note", "private-note", "private_note",
            "sleep", "hrv", "heart rate", "blood pressure", "medication", "diagnosis"
        ]
        guard prohibited.allSatisfy({ !normalized.contains($0) }) else { return false }
        return value.count <= 120 && !value.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }
}
