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
                                ProgramRow(program: program)
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
        }
    }
}

// MARK: - ProgramRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramRow: View {
    let program: ProgramListItem

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

                if program.isEnrolled {
                    Button("Continue") {
                        // Navigate to program detail
                    }
                    .artDecoButton(style: .primary)
                } else {
                    Button("Enroll") {
                        // Enroll in program
                    }
                    .artDecoButton(style: .secondary)
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

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
        self.dataClient = dataClient
    }

    func loadPrograms() async {
        isLoading = true

        // For now, use mock data
        // In production, this would fetch from CloudKit or a bundled catalog
        programs = [
            ProgramListItem(
                id: "strength-basics",
                name: "Strength Basics",
                category: "Strength",
                description: "Build a solid foundation with compound movements and progressive overload",
                durationWeeks: 8,
                sessionsPerWeek: 3,
                difficulty: "Beginner",
                isEnrolled: false
            ),
            ProgramListItem(
                id: "hypertrophy-phase-1",
                name: "Hypertrophy Phase 1",
                category: "Hypertrophy",
                description: "Focus on muscle growth with volume and intensity progression",
                durationWeeks: 12,
                sessionsPerWeek: 4,
                difficulty: "Intermediate",
                isEnrolled: false
            ),
            ProgramListItem(
                id: "powerbuilding",
                name: "Powerbuilding",
                category: "Strength",
                description: "Combine strength and hypertrophy training for maximum gains",
                durationWeeks: 16,
                sessionsPerWeek: 5,
                difficulty: "Advanced",
                isEnrolled: false
            )
        ]

        isLoading = false
    }
}
