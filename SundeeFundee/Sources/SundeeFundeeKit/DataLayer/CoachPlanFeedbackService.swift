import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor CoachPlanFeedbackService {
    private let dataClient: DataClientProtocol
    private static let recordType = "CoachPlanFeedback"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func submit(
        rating: CoachPlanFeedbackRating,
        surface: String,
        workoutID: String?,
        copySource: String,
        promptVersion: String,
        reasonCodes: [String]
    ) async throws {
        let reasonCodesJSON: String?
        if reasonCodes.isEmpty {
            reasonCodesJSON = nil
        } else {
            let data = try JSONEncoder().encode(reasonCodes)
            reasonCodesJSON = String(data: data, encoding: .utf8)
        }

        let record = CoachPlanFeedbackRecord(
            rating: rating,
            surface: surface,
            workoutID: workoutID,
            copySource: copySource,
            promptVersion: promptVersion,
            reasonCodesJSON: reasonCodesJSON
        )
        try await dataClient.save(record, recordType: Self.recordType)
    }
}
