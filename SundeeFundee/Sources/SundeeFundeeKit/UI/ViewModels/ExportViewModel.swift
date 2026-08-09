import Foundation

// MARK: - ExportViewModel

/// Manages export loading state and JSON file generation for the data export feature.
///
/// Follows the same `@MainActor @ObservableObject` pattern as `AnalyticsViewModel`.
/// The export feature is available to every user.
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

    // MARK: - Coach Report State

    /// The window the shareable training report covers.
    @Published public var reportRange: TrainingReportRange = .last30Days

    /// Whether cycle-phase and symptom detail is included in the report.
    ///
    /// Defaults to false and is not persisted between visits. Sharing context
    /// with a clinician is not the same as viewing it in the app, so this is an
    /// explicit per-report choice every time rather than a remembered setting.
    @Published public var includeCycleDetailInReport: Bool = false

    /// Whether a report is currently being generated.
    @Published public var isGeneratingReport: Bool = false

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

    /// Prefills category counts for the export screen without generating a share file.
    public func loadCategoryCountsIfNeeded() async {
        guard categoryCounts.isEmpty, !isExporting else { return }

        isExporting = true
        errorMessage = nil

        do {
            let data = await service.exportAll()
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
            errorMessage = "We couldn't generate your export file. Please try again."
            return nil
        }
    }

    // MARK: - Coach Report

    #if canImport(UIKit)
    /// Fetches fresh data, renders the training report to a PDF, and writes it
    /// to a temporary file for the share sheet.
    ///
    /// Always re-fetches rather than reusing `exportedData`. A report is a
    /// point-in-time artifact someone may hand to a clinician, so it must never
    /// be built from data cached earlier in the session.
    ///
    /// - Returns: The file URL of the written PDF, or nil if generation failed.
    public func generateReportPDF() async -> URL? {
        isGeneratingReport = true
        errorMessage = nil
        defer { isGeneratingReport = false }

        let data = await service.exportAll()
        exportedData = data
        categoryCounts = data.categoryCounts

        let content = TrainingReportAssembler.assemble(
            exportedData: data,
            range: reportRange,
            includeCycleDetail: includeCycleDetailInReport
        )
        let pdfData = TrainingReportPDFRenderer.render(content)

        do {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(reportFileName(generatedAt: content.generatedAt))
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            errorMessage = "We couldn't generate your training report. Please try again."
            return nil
        }
    }

    /// A filename a recipient can make sense of in a downloads folder.
    private func reportFileName(generatedAt: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "training-summary-\(formatter.string(from: generatedAt)).pdf"
    }
    #endif
}
