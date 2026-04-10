import SwiftUI

// MARK: - ProgramsListView
//
// List of available training programs.
// Matches the web app's programs feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ProgramsListView: View {
    @StateObject private var viewModel = ProgramsListViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.programs) { program in
                                ProgramRow(program: program, onEnroll: {
                                    Task {
                                        await viewModel.enrollInProgram(program.id)
                                    }
                                })
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Programs")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadPrograms()
            }
            .refreshable {
                await viewModel.loadPrograms()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - ProgramRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramRow: View {
    let program: ProgramListItem
    let onEnroll: () -> Void

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(program.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    if program.isEnrolled {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityLabel("Currently enrolled")
                    }
                }

                Text(program.category)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                Text(program.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)

                HStack(spacing: AppTheme.Spacing.lg) {
                    Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                    Label("\(program.sessionsPerWeek)/wk", systemImage: "figure.strengthtraining.traditional")
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

                Text(program.difficulty)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                if program.isEnrolled {
                    Label("Enrolled", systemImage: "checkmark.circle.fill")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                } else {
                    Button("Enroll") {
                        onEnroll()
                    }
                    .artDecoButton(style: .secondary)
                    .accessibilityHint("Start this program")
                }
            }
        }
    }
}

// MARK: - ProgramListItem

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramListItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let isEnrolled: Bool
}

// MARK: - ProgramsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var programs: [ProgramListItem] = []
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func loadPrograms() async {
        isLoading = true

        // Load enrolled programs from CloudKit
        var enrolledIds: Set<String> = []
        do {
            let enrolled = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]
            enrolledIds = Set(enrolled.filter(\.isActive).map(\.id))
        } catch {
            errorMessage = "Failed to load programs: \(error.localizedDescription)"
        }

        // Generate program catalog from domain templates
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
                isEnrolled: enrolledIds.contains(program.id)
            )
        }

        isLoading = false
    }

    func enrollInProgram(_ programId: String) async {
        do {
            let record = EnrolledProgramRecord(
                id: programId,
                name: programs.first(where: { $0.id == programId })?.name ?? "",
                isActive: true
            )
            try await dataClient.save(record, recordType: "EnrolledProgramRecord")
            await loadPrograms()
        } catch {
            errorMessage = "Failed to enroll: \(error.localizedDescription)"
        }
    }

    private func templateDisplayName(_ template: ProgramTemplate) -> String {
        switch template {
        case .strength:    return "Strength Basics"
        case .hypertrophy: return "Hypertrophy Phase"
        case .fullBody:    return "Full Body"
        case .linear:      return "Linear Progression"
        case .dup:         return "Daily Undulating"
        case .block:       return "Block Periodization"
        }
    }
}
