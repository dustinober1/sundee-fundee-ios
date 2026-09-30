import Foundation
import SwiftUI

// MARK: - ProgramsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var programs: [ProgramListItem] = []
    @Published var errorMessage: String?
    /// Tracks which program is currently being enrolled so the row can show a spinner.
    @Published var enrollingProgramId: String? = nil
    @Published var recommendationGoal: PrimaryGoal = .strength
    @Published var recommendationExperience: ExperienceLevel = .beginner
    @Published var recommendationDaysPerWeek: Int = 3
    @Published var recommendationEquipment: EquipmentAccess = .fullGym
    @Published var programRecommendations: [ProgramRecommendation] = []

    // MARK: - Return to Training
    //
    // Held separately from `programs` because this block is not part of the
    // printable catalog the content client serves — it is generated per person
    // from the selected break reason, so there is nothing to bundle.

    @Published var returnToTrainingReason: TrainingBreakReason = .extendedTimeOff
    @Published var isEnrollingReturnToTraining: Bool = false
    @Published var isReturnToTrainingEnrolled: Bool = false

    /// The block that would be generated for the currently-selected reason.
    var returnToTrainingPreview: GeneratedProgram {
        generateReturnToTrainingProgram(breakReason: returnToTrainingReason)
    }

    /// Week-by-week load plan for the currently-selected reason.
    var returnToTrainingWeeks: [ReturnToTrainingWeek] {
        ReturnToTrainingSchedule.weeks(for: returnToTrainingReason)
    }

    /// Persists across CloudKit re-fetches so optimistically-enrolled programs
    /// stay visible even while CloudKit index lag hasn't caught up yet.
    private var knownEnrolledIds: Set<String> = []
    private var hasLoadedRecommendationDefaults = false

    private let dataClient: DataClientProtocol
    private let contentClient: ContentClientProtocol

    // Maps known program display names to their template type so the detail view
    // can regenerate sessions without storing the full program in CloudKit.
    private static let nameToTemplate: [String: ProgramTemplate] = [
        "The First Margarita": .firstMargarita,
        "The First Margarita Strength Program": .firstMargarita,
        "Beginner Strength": .beginnerStrength,
        "4-Week Beginner Strength Plan": .beginnerStrength,
        "Dumbbell Strength": .dumbbellStrength,
        "6-Week Dumbbell Strength Plan": .dumbbellStrength,
        "Glutes, Core & Conditioning": .glutesCoreConditioning,
        "8-Week Glutes, Core & Conditioning Plan": .glutesCoreConditioning,
        "Russian Squat": .russianSquat,
        "6-Week Russian Squat Program": .russianSquat,
    ]

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        contentClient: ContentClientProtocol? = nil
    ) {
        self.dataClient = dataClient
        self.contentClient = contentClient ?? BundledContentProvider()
    }

    func loadPrograms() async {
        isLoading = true
        await loadRecommendationDefaultsIfNeeded()

        var enrolledIds: Set<String> = []
        do {
            let enrolled = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]
            enrolledIds = Set(enrolled.filter(\.isActive).map(\.id))
        } catch {
            errorMessage = "We couldn't load programs. Pull to refresh or try again in a moment."
        }
        // Merge with locally-known enrolled IDs so CloudKit index lag doesn't
        // wipe enrollment state on every tab switch.
        enrolledIds = enrolledIds.union(knownEnrolledIds)
        isReturnToTrainingEnrolled = enrolledIds.contains(returnToTrainingProgramID)

        do {
            let contentPrograms = try await contentClient.fetchPrograms()
            programs = contentPrograms.map { prog in
                ProgramListItem(
                    id: prog.id,
                    name: prog.name,
                    category: prog.category,
                    description: prog.description,
                    durationWeeks: prog.durationWeeks,
                    sessionsPerWeek: prog.sessionsPerWeek,
                    difficulty: prog.difficulty,
                    isEnrolled: enrolledIds.contains(prog.id),
                    template: Self.nameToTemplate[prog.name],
                    printablePDFURL: prog.printablePDFURL
                )
            }
        } catch {
            programs = ProgramTemplate.allCases.map { template in
                let program = generateProgram(template: template, name: templateDisplayName(template))
                return ProgramListItem(
                    id: program.id,
                    name: program.name,
                    category: program.category,
                    description: program.description,
                    durationWeeks: program.durationWeeks,
                    sessionsPerWeek: program.sessionsPerWeek,
                    difficulty: program.difficulty,
                    isEnrolled: enrolledIds.contains(program.id),
                    template: template,
                    printablePDFURL: template.printablePDFURL
                )
            }
        }

        isLoading = false
    }

    var topRecommendation: ProgramRecommendation? {
        programRecommendations.first
    }

    func updateRecommendations() {
        programRecommendations = ProgramRecommendationService.recommend(
            goal: recommendationGoal,
            experience: recommendationExperience,
            daysPerWeek: recommendationDaysPerWeek,
            equipment: recommendationEquipment
        )
    }

    func enrollInProgram(_ programId: String) async {
        enrollingProgramId = programId
        defer { enrollingProgramId = nil }

        do {
            let record = EnrolledProgramRecord(
                id: programId,
                name: programs.first(where: { $0.id == programId })?.name ?? "",
                isActive: true
            )
            try await dataClient.save(record, recordType: "EnrolledProgramRecord")
            knownEnrolledIds.insert(programId)

            // Update local state immediately. CloudKit query indexes may not reflect
            // a fresh write instantly (especially under rate limiting), so re-fetching
            // can silently return stale empty results and leave the row showing as unenrolled.
            programs = programs.map { p in
                guard p.id == programId else { return p }
                return ProgramListItem(
                    id: p.id,
                    name: p.name,
                    category: p.category,
                    description: p.description,
                    durationWeeks: p.durationWeeks,
                    sessionsPerWeek: p.sessionsPerWeek,
                    difficulty: p.difficulty,
                    isEnrolled: true,
                    template: p.template,
                    printablePDFURL: p.printablePDFURL
                )
            }
        } catch {
            errorMessage = "We couldn't enroll you in that program. Check your connection and try again."
        }
    }

    /// Enrolls in a return-to-training block for the selected break reason.
    ///
    /// Separate from `enrollInProgram` because that method resolves the program
    /// name out of `programs`, and this block deliberately does not live there.
    func enrollInReturnToTraining() async {
        isEnrollingReturnToTraining = true
        defer { isEnrollingReturnToTraining = false }

        do {
            let record = EnrolledProgramRecord(
                id: returnToTrainingProgramID,
                name: returnToTrainingPreview.name,
                isActive: true
            )
            try await dataClient.save(record, recordType: "EnrolledProgramRecord")
            knownEnrolledIds.insert(returnToTrainingProgramID)
            isReturnToTrainingEnrolled = true
        } catch {
            errorMessage = "We couldn't start that program. Check your connection and try again."
        }
    }

    private func templateDisplayName(_ template: ProgramTemplate) -> String {
        template.displayName
    }

    private func loadRecommendationDefaultsIfNeeded() async {
        guard !hasLoadedRecommendationDefaults else {
            updateRecommendations()
            return
        }
        hasLoadedRecommendationDefaults = true

        if let settings = (try? await dataClient.fetchAll(recordType: "UserSettings") as [UserSettingsRecord])?.last {
            recommendationGoal = PrimaryGoal(rawValue: settings.primaryGoal) ?? .strength
            recommendationExperience = ExperienceLevel(rawValue: settings.experienceLevel) ?? .beginner
            recommendationEquipment = settings.defaultEquipment
        }

        updateRecommendations()
    }
}

extension PrimaryGoal {
    static let recommendationChoices: [PrimaryGoal] = [.strength, .hypertrophy, .endurance, .weightLoss]

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle"
        case .endurance: return "Endurance"
        case .weightLoss: return "Conditioning"
        }
    }
}

extension ExperienceLevel {
    static let recommendationChoices: [ExperienceLevel] = [.beginner, .intermediate, .advanced]

    // displayName lives on ExperienceLevel itself (SettingsView.swift) —
    // this file used to duplicate it as a fileprivate extension, which the
    // compiler rejects as a redeclaration now that the type has a real one.
}
