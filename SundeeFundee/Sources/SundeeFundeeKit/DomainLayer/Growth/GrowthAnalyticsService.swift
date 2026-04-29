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
        let propertiesJSON: String?
        if properties.isEmpty {
            propertiesJSON = nil
        } else if let data = try? JSONEncoder().encode(properties) {
            propertiesJSON = String(data: data, encoding: .utf8)
        } else {
            propertiesJSON = nil
        }

        let event = GrowthEvent(
            name: name,
            source: source,
            propertiesJSON: propertiesJSON
        )

        try? await dataClient.save(event, recordType: Self.recordType)
    }
}
