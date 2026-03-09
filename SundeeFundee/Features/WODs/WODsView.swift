import SwiftUI
import SwiftData

struct WODsView: View {
    @State var viewModel: WODsViewModel
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    private var oneRepMaxes: [String: Double] {
        // Lightweight computed — no repo needed, just expose for WOD execution
        [:]
    }

    private var barbellWeightKg: Double {
        DashboardViewModel.barbellWeight(for: currentUser?.gender)
    }

    private var weightUnit: WeightUnit {
        currentUser?.weightUnit ?? .pounds
    }

    init(viewModel: WODsViewModel = WODsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView("Loading WODs...")
                        .foregroundStyle(AppTheme.Colors.navy)
                } else {
                    let rangeWODs = WODsViewModel.wodsInRange(from: viewModel.allWODs)
                    if rangeWODs.isEmpty {
                        ContentUnavailableView(
                            "No WODs Available",
                            systemImage: "flame",
                            description: Text("Check back soon for new Workouts of the Day.")
                        )
                    } else {
                        wodList(rangeWODs)
                    }
                }
            }
        }
        .navigationTitle("WODs")
        .task {
            await viewModel.load()
        }
    }

    private func wodList(_ wods: [WOD]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(wods) { wod in
                    WODListCard(
                        wod: wod,
                        barbellWeightKg: barbellWeightKg,
                        weightUnit: weightUnit
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
    }
}

// MARK: - WODListCard

struct WODListCard: View {
    let wod: WOD
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    private var isToday: Bool {
        WODsViewModel.isToday(wod.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(WODsViewModel.displayDate(from: wod.date).uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isToday ? AppTheme.Colors.accentOrange : AppTheme.Colors.textSecondary)
                        .tracking(1.5)
                    Text(wod.title)
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                }
                Spacer()
                if isToday {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                }
            }

            Text(Self.templateBadgeText(for: wod))
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.cream)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(isToday ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(wod.description)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                .lineLimit(2)

            Text("\(wod.exercises.count) exercises")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))

            if isToday {
                NavigationLink(value: StartWODDestination(wod: wod)) {
                    Label("Start WOD", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("start-wod-button")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(isToday ? 0.08 : 0.04), radius: isToday ? 6 : 3, x: 0, y: isToday ? 3 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(isToday ? AppTheme.Colors.accentOrange.opacity(0.3) : .clear, lineWidth: 1)
        )
    }

    static func templateBadgeText(for wod: WOD) -> String {
        WODTemplateType.from(wod.templateType).displayName
    }
}
