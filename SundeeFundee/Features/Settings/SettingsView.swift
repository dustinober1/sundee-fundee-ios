import SwiftUI
import SwiftData

/// Settings — profile, injury profiles, legal sections.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showSignOutConfirm = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                // Profile
                Section("Profile") {
                    NavigationLink("Edit Profile") {
                        EditProfileView(viewModel: viewModel)
                    }
                }

                // Training
                Section("Training") {
                    NavigationLink("Injury Profiles") {
                        InjuryProfilesView(viewModel: viewModel)
                    }
                    NavigationLink("Lift Maxes") {
                        MaxLiftsView()
                    }
                }

                // Legal
                Section("Legal") {
                    NavigationLink("Terms of Service") {
                        LegalView(page: .terms)
                    }
                    NavigationLink("Privacy Policy") {
                        LegalView(page: .privacy)
                    }
                    NavigationLink("Medical Disclaimer") {
                        LegalView(page: .medical)
                    }
                }

                // Account
                Section("Account") {
                    if appState.currentUserID != nil {
                        Button("Sign Out", role: .destructive) {
                            showSignOutConfirm = true
                        }
                    } else {
                        Text("Guest Mode")
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Sundee Fundee v1.0")
                            .font(AppTheme.Fonts.caption)
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.4))
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) { appState.signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .task { await viewModel.load(modelContext: modelContext, userID: appState.currentUserID ?? "") }
    }
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Name") {
                TextField("Display name", text: $viewModel.displayName)
            }
            Section("Experience Level") {
                Picker("Level", selection: $viewModel.experienceLevel) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Primary Goal") {
                Picker("Goal", selection: $viewModel.primaryGoal) {
                    ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.cream)
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - InjuryProfilesView

struct InjuryProfilesView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showAdd = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                if viewModel.injuryProfiles.isEmpty {
                    ContentUnavailableView(
                        "No Injury Profiles",
                        systemImage: "bandage",
                        description: Text("Add an injury profile so the app can adapt your workouts.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.injuryProfiles) { injury in
                        NavigationLink(value: injury) {
                            InjuryRow(injury: injury)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Injury Profiles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .navigationDestination(for: InjuryProfile.self) { injury in
            EditInjuryView(injury: injury, viewModel: viewModel)
        }
        .sheet(isPresented: $showAdd) {
            AddInjurySheet(viewModel: viewModel)
        }
    }
}

struct InjuryRow: View {
    let injury: InjuryProfile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(injury.location.isEmpty ? "Unnamed injury" : injury.location)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(injury.movementLimitations)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .lineLimit(1)
            }
            Spacer()
            Text(injury.isActive ? "Active" : "Resolved")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(injury.isActive ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.4))
        }
        .padding(.vertical, 4)
    }
}

struct EditInjuryView: View {
    let injury: InjuryProfile
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var location: String
    @State private var limitations: String
    @State private var recoveryGoal: String

    init(injury: InjuryProfile, viewModel: SettingsViewModel) {
        self.injury = injury
        self.viewModel = viewModel
        _location = State(initialValue: injury.location)
        _limitations = State(initialValue: injury.movementLimitations)
        _recoveryGoal = State(initialValue: injury.recoveryGoal)
    }

    var body: some View {
        Form {
            Section("Location") {
                TextField("e.g. Lower back, Left knee", text: $location)
            }
            Section("Movement Limitations") {
                TextField("e.g. No deadlifts, limited overhead", text: $limitations, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("Recovery Goal") {
                TextField("e.g. Return to full squats in 8 weeks", text: $recoveryGoal, axis: .vertical)
                    .lineLimit(2...4)
            }
            if injury.isActive {
                Section {
                    Button("Mark as Resolved", role: .destructive) {
                        viewModel.resolveInjury(injury)
                        dismiss()
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.cream)
        .navigationTitle("Edit Injury")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.updateInjury(injury, location: location, limitations: limitations, recoveryGoal: recoveryGoal)
                    dismiss()
                }
            }
        }
    }
}

struct AddInjurySheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var location = ""
    @State private var limitations = ""
    @State private var recoveryGoal = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Injury Location") {
                    TextField("e.g. Lower back, Left knee", text: $location)
                }
                Section("Movement Limitations") {
                    TextField("e.g. No deadlifts, avoid twisting", text: $limitations, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Recovery Goal") {
                    TextField("e.g. Return to full training in 6 weeks", text: $recoveryGoal, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Injury")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !location.isEmpty else { return }
                        viewModel.addInjury(location: location, limitations: limitations, recoveryGoal: recoveryGoal)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - LegalView

enum LegalPage { case terms, privacy, medical }

struct LegalView: View {
    let page: LegalPage

    var body: some View {
        ScrollView {
            Text(content)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy)
                .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.cream.ignoresSafeArea())
        .navigationTitle(title)
    }

    private var title: String {
        switch page {
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        case .medical: return "Medical Disclaimer"
        }
    }

    private var content: String {
        switch page {
        case .terms:
            return """
            By using Sundee Fundee, you agree to these Terms of Service. \
            The app is provided for informational and fitness tracking purposes only. \
            You are responsible for exercising safely and within your physical capabilities.
            """
        case .privacy:
            return """
            Your data is stored privately in iCloud using CloudKit. \
            We do not sell or share your personal health or workout data with third parties. \
            You may delete your data at any time through iOS Settings > iCloud > Manage Storage.
            """
        case .medical:
            return """
            ⚠️ Medical Disclaimer\n\n\
            Sundee Fundee is not a medical application. \
            The training recommendations provided are for general fitness purposes only and \
            should not be construed as medical advice.\n\n\
            Consult a qualified healthcare professional before starting any new exercise program, \
            especially if you have existing injuries, medical conditions, or are pregnant.\n\n\
            The cycle-aware training features are based on general research and may not apply \
            to your individual physiology. Always listen to your body.
            """
        }
    }
}
