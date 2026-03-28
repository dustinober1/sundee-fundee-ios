import Foundation

@MainActor
@Observable
final class CreateProgramViewModel {
    var selectedTemplate: ProgramTemplate?
    var programName: String = ""
    var programDescription: String = ""
    var durationWeeks: Int = 4
    var sessionsPerWeek: Int = 3

    static let durationOptions = [3, 4, 6, 8]
    static let frequencyOptions = [3, 4, 5]

    var canGenerate: Bool {
        selectedTemplate != nil && !programName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func selectTemplate(_ template: ProgramTemplate) {
        selectedTemplate = template
        durationWeeks = template.defaultDuration
        sessionsPerWeek = template.defaultFrequency
    }

    func generateProgram() -> Program? {
        guard let template = selectedTemplate else { return nil }
        return ProgramTemplateGenerator.generate(
            template: template,
            name: programName.trimmingCharacters(in: .whitespaces),
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek
        )
    }
}
