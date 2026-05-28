import SwiftUI

// MARK: - ChallengesView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ChallengesView: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showingCreateChallenge = false
    @State private var showingJoinChallenge = false
    @State private var showingBuddyCheckIn = false
    @State private var pendingTemplate: ChallengeShareTemplate?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if viewModel.isLoading {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ProgressView()
                        Text("Loading challenges…")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.loadError {
                    errorState(error)
                } else if viewModel.activeChallenges.isEmpty && viewModel.completedChallenges.isEmpty {
                    emptyState
                } else {
                    // Active Challenges
                    if !viewModel.activeChallenges.isEmpty {
                        sectionHeader("Active Challenges")
                        ForEach(viewModel.activeChallenges) { challenge in
                            challengeCard(challenge)
                        }
                    }

                    // Completed Challenges
                    if !viewModel.completedChallenges.isEmpty {
                        sectionHeader("Completed")
                        ForEach(viewModel.completedChallenges) { challenge in
                            challengeCard(challenge)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Challenges")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {
                        showingBuddyCheckIn = true
                    } label: {
                        Image(systemName: "person.2.checkmark")
                    }
                    .tint(AppTheme.Accent.gold)
                    .accessibilityLabel("Check in with buddy")

                    Button {
                        showingJoinChallenge = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .tint(AppTheme.Accent.gold)
                    .accessibilityLabel("Join challenge")

                    Button {
                        showingCreateChallenge = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(AppTheme.Accent.gold)
                    .accessibilityLabel("Create new challenge")
                }
            }
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBuddyCheckIn) {
            BuddyCheckInSheet()
        }
        .sheet(isPresented: $showingJoinChallenge) {
            JoinChallengeView { template in
                pendingTemplate = template
                showingJoinChallenge = false
            }
        }
        .sheet(item: $pendingTemplate) { template in
            CreateChallengeView(viewModel: viewModel, template: template)
        }
        .task {
            await viewModel.loadChallenges()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "trophy")
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Accent.gold)

            Text("No Challenges Yet")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Text.primary)

            Text("Start a volume challenge to track total pounds lifted across your workouts.")
                .font(AppTheme.Typography.bodyLarge)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateChallenge = true
            } label: {
                Text("Create Challenge")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.cream)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Accent.gold)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Accent.orange)

            Text("Unable to Load Progress")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Text.primary)

            Text("Challenge data couldn't be loaded from iCloud. Make sure you're signed in to iCloud and try again.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppTheme.Typography.monoSmall)
                .foregroundColor(AppTheme.Text.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.loadChallenges() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.cream)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Accent.gold)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Text.primary)
            Spacer()
        }
    }

    // MARK: - Challenge Card

    private func challengeCard(_ challenge: Challenge) -> some View {
        let progress = ChallengeEngine.computeProgress(challenge: challenge)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    if challenge.status == .completed {
                        Text("Completed")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    } else if challenge.status == .expired {
                        Text("Expired")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                    } else {
                        Text(progress.currentTierName)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
                Spacer()
                Text("\(Int(progress.percentComplete * 100))%")
                    .font(AppTheme.Typography.monoMedium)
                    .foregroundColor(AppTheme.Accent.gold)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Background.navy.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Accent.gold)
                        .frame(width: geo.size.width * progress.percentComplete, height: 8)
                }
            }
            .frame(height: 8)

            // Volume info
            HStack {
                Text(formatVolume(challenge.accumulatedVolumeLbs))
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                if challenge.status == .active {
                    Spacer()
                    Text("\(formatVolume(progress.volumeRemaining)) remaining")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }

            if let endDate = challenge.challengeEndDate, challenge.status == .active {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                Text("\(max(0, daysLeft)) days left")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(daysLeft < 7 ? AppTheme.Accent.orange : AppTheme.Text.secondary)
            }

            if challenge.type == .lifetimeVolume {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(challenge.tiers.sorted { $0.ordinal < $1.ordinal }, id: \.ordinal) { tier in
                            tierBadge(tier, challenge: challenge)
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.xs)
            }

            if challenge.status == .active {
                ChallengeInviteShareLink(challenge: challenge)
                    .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Background.cream)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Background.navy.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title). \(Int(progress.percentComplete * 100)) percent complete. \(formatVolume(challenge.accumulatedVolumeLbs)) accumulated")
    }

    private func formatVolume(_ lbs: Double) -> String {
        if lbs >= 1_000_000 {
            return String(format: "%.1fM lbs", lbs / 1_000_000)
        } else if lbs >= 1_000 {
            return String(format: "%.0fK lbs", lbs / 1_000)
        }
        return "\(Int(lbs)) lbs"
    }

    private func tierBadge(_ tier: ChallengeTier, challenge: Challenge) -> some View {
        let isUnlocked = challenge.currentTierIndex > tier.ordinal || challenge.status == .completed
        let isCurrent = challenge.status == .active && challenge.currentTierIndex == tier.ordinal

        return VStack(alignment: .leading, spacing: 2) {
            Text(tier.name)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(isUnlocked ? AppTheme.Text.cream : AppTheme.Text.primary)
            Text(formatVolume(tier.targetVolumeLbs))
                .font(AppTheme.Typography.monoSmall)
                .foregroundColor(isUnlocked ? AppTheme.Text.cream.opacity(0.85) : AppTheme.Text.secondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(badgeBackground(isUnlocked: isUnlocked, isCurrent: isCurrent))
        .overlay(
            Capsule()
                .stroke(isCurrent ? AppTheme.Accent.orange : AppTheme.Background.navy.opacity(0.12), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func badgeBackground(isUnlocked: Bool, isCurrent: Bool) -> Color {
        if isUnlocked {
            return AppTheme.Background.navy
        }

        if isCurrent {
            return AppTheme.Accent.goldLight
        }

        return AppTheme.Background.white
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct ChallengeInviteShareLink: View {
    let challenge: Challenge
    @State private var shareText = "Preparing challenge invite..."

    var body: some View {
        ShareLink(item: shareText) {
            Label("Challenge a Friend", systemImage: "square.and.arrow.up")
                .font(AppTheme.Typography.labelMedium)
                .frame(maxWidth: .infinity)
        }
        .artDecoButton(style: .secondary)
        .simultaneousGesture(
            TapGesture().onEnded {
                HapticFeedback.success()
                Task {
                    await GrowthAnalyticsService().track(
                        GrowthEventName.challengeInviteShared,
                        source: "challenge_card",
                        properties: ["challengeID": challenge.id]
                    )
                }
            }
        )
        .task {
            await prepareInvite()
        }
    }

    private func prepareInvite() async {
        let service = ChallengeInviteService()
        let template = await service.template(from: challenge)
        if let invite = try? await SocialChallengeService().createInvite(template: template, userID: nil) {
            shareText = await service.inviteText(template: template, inviteToken: invite.inviteToken)
        } else {
            let fallbackToken = await service.makeInviteToken()
            shareText = await service.inviteText(template: template, inviteToken: fallbackToken)
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct JoinChallengeView: View {
    let onTemplateLoaded: (ChallengeShareTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var joinCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ABCDEFGH", text: $joinCode)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Semantic.warning)
                    }
                } header: {
                    Text("Join Code")
                } footer: {
                    Text("Paste the code your friend shared. You can review the challenge before creating it.")
                }
            }
            .navigationTitle("Join Challenge")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        Task { await loadTemplate() }
                    }
                    .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }

    private func loadTemplate() async {
        isLoading = true
        defer { isLoading = false }

        let token = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        do {
            if let invite = try await SocialChallengeService().fetchInvite(token: token) {
                onTemplateLoaded(invite.template)
                dismiss()
            } else {
                errorMessage = "No challenge found for that code."
            }
        } catch {
            errorMessage = "Challenge invites are not available right now."
        }
    }
}

// MARK: - BuddyCheckInSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct BuddyCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var message = ""
    @State private var status: BuddyCheckInStatus = .completed
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $displayName)
                } header: {
                    Text("Display Name")
                }

                Section {
                    Picker("Status", selection: $status) {
                        Text("Completed").tag(BuddyCheckInStatus.completed)
                        Text("Planned").tag(BuddyCheckInStatus.planned)
                        Text("Skipped").tag(BuddyCheckInStatus.skipped)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Check-In Status")
                }

                Section {
                    TextField("How did it go? (optional)", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Message")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Semantic.warning)
                    }
                }
            }
            .navigationTitle("Buddy Check-In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveCheckIn() }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveCheckIn() async {
        isSaving = true
        defer { isSaving = false }

        let service = BuddyCheckInService(dataClient: DataClientFactory.shared.client)
        let record = BuddyCheckInRecord(
            id: UUID().uuidString,
            threadID: "buddy-\(displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())",
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            statusRaw: status.rawValue,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil : message.trimmingCharacters(in: .whitespacesAndNewlines),
            checkInDate: Date(),
            dateCreated: Date()
        )

        do {
            try await service.save(record)
            HapticFeedback.success()
            dismiss()
        } catch {
            HapticFeedback.warning()
            errorMessage = "Could not save check-in. Please try again."
        }
    }
}

// MARK: - ChallengesViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ChallengesViewModel: ObservableObject {
    @Published var activeChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let challengeService: ChallengeService
    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
        self.challengeService = ChallengeService(dataClient: dataClient)
    }

    func loadChallenges() async {
        isLoading = true
        do {
            let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            _ = try await challengeService.ensureLifetimeChallenge(from: workouts)
            let all = try await challengeService.loadAll()
            activeChallenges = all.filter { $0.status == .active }
                .sorted { $0.dateCreated > $1.dateCreated }
            completedChallenges = all.filter { $0.status == .completed || $0.status == .expired }
                .sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    func createLifetimeChallenge() async {
        do {
            let workouts: [Workout] = try await DataClientFactory.shared.client.fetchAll(
                recordType: "Workout"
            )
            _ = try await challengeService.initializeLifetimeChallenge(from: workouts)
            await loadChallenges()
        } catch {
            // Show error in future iteration
        }
    }

    func createCustomChallenge(title: String, targetVolume: Double, endDate: Date?) async {
        let challenge = ChallengeEngine.createCustomChallenge(
            title: title,
            targetVolumeLbs: targetVolume,
            endDate: endDate
        )
        do {
            try await challengeService.save(challenge)
            await loadChallenges()
        } catch {
            // Show error in future iteration
        }
    }

    func createExerciseChallenge(exerciseName: String, targetVolume: Double) async {
        let tier = ChallengeTier(name: "Goal", targetVolumeLbs: targetVolume, ordinal: 0)
        let challenge = ChallengeEngine.createExerciseChallenge(
            exerciseName: exerciseName,
            tiers: [tier]
        )
        do {
            try await challengeService.save(challenge)
            await loadChallenges()
        } catch {
            // Show error in future iteration
        }
    }
}
