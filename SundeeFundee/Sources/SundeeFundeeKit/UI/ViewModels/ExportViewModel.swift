import Foundation

// MARK: - ExportViewModel

/// Manages export loading state, subscription gating, and JSON file generation
/// for the data export feature.
///
/// Follows the same `@MainActor @ObservableObject` pattern as `AnalyticsViewModel`.
/// The export feature is gated behind `SubscriptionTier.hasExportShare` (Pro only).
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class ExportViewModel: ObservableObject {

    // MARK: - Published State

    /// Whether an export is currently in progress.
    @Published public var isExporting: Bool = false

    /// The exported data once loaded.
    @Published public var exportedData: ExportedData?

    /// Category-level record counts for summary display.
    @Published public var categoryCounts: [String: Int] = [:]

    /// Error message to display if export fails.
    @Published public var errorMessage: String?

    // MARK: - Dependencies

    private let service: DataExportService

    // MARK: - Initialization

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.service = DataExportService(dataClient: dataClient)
    }

    /// Initializer accepting a pre-built service (for testing).
    init(
        service: DataExportService
    ) {
        self.service = service
    }

    // MARK: - Public Methods

    /// Fetches all user data and populates `exportedData` and `categoryCounts`.
    public func loadExportData() async {
        isExporting = true
        errorMessage = nil

        do {
            let data = await service.exportAll()
            exportedData = data
            categoryCounts = data.categoryCounts
        }

        isExporting = false
    }

    /// Encodes the current `exportedData` to JSON and writes it to a temporary file.
    ///
    /// - Returns: The file URL of the written JSON, or `nil` if no data is available
    ///   or encoding/writing fails.
    public func generateJSONFile() -> URL? {
        guard let data = exportedData else { return nil }

        do {
            let jsonData = try service.encode(data)

            let fileName = "sundee-fundee-export-\(Int(data.exportDate.timeIntervalSince1970)).json"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)

            try jsonData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            errorMessage = "Failed to generate export file: \(error.localizedDescription)"
            return nil
        }
    }
}
