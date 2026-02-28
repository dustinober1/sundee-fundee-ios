import SwiftUI
import SwiftData

/// Settings — profile, injury profiles, legal sections.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showSignOutConfirm = false
    @State private var seedMessage: String?
    
    static func presentSignOutConfirmation(_ isPresented: inout Bool) {
        isPresented = true
    }

    static func presentSignOutConfirmationAction(isPresented: Binding<Bool>) -> () -> Void {
        { isPresented.wrappedValue = true }
    }
    
    #if DEBUG
    static func seedDataAction(modelContext: ModelContext, seedMessage: Binding<String?>) -> () -> Void {
        {
            Task {
                await DebugSeedData.seed(modelContext: modelContext)
                seedMessage.wrappedValue = "Sample data seeded!"
            }
        }
    }
    
    static func clearDataAction(modelContext: ModelContext, seedMessage: Binding<String?>) -> () -> Void {
        {
            DebugSeedData.clearAll(modelContext: modelContext)
            seedMessage.wrappedValue = "All data cleared."
        }
    }
    
    @ViewBuilder
    static func debugMessageView(_ message: String?) -> some View {
        if let msg = message {
            Text(msg)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.accentOrange)
        }
    }
    #endif

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
                        Button(
                            "Sign Out",
                            role: .destructive,
                            action: Self.presentSignOutConfirmationAction(isPresented: $showSignOutConfirm)
                        )
                    } else {
                        Text("Guest Mode")
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button("Seed Sample Data", action: Self.seedDataAction(modelContext: modelContext, seedMessage: $seedMessage))
                    Button("Clear All Data", role: .destructive, action: Self.clearDataAction(modelContext: modelContext, seedMessage: $seedMessage))
                    Self.debugMessageView(seedMessage)
                }
                #endif

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
            Button("Sign Out", role: .destructive, action: appState.signOut)
        }
        .task { await viewModel.load(modelContext: modelContext, userID: appState.currentUserID ?? "") }
    }
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    static func saveAction(viewModel: SettingsViewModel, dismiss: @escaping () -> Void) -> () -> Void {
        {
            Task {
                await viewModel.saveProfile()
                dismiss()
            }
        }
    }

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
                Button("Save", action: Self.saveAction(viewModel: viewModel, dismiss: dismiss.callAsFunction))
            }
        }
    }
}

// MARK: - InjuryProfilesView

struct InjuryProfilesView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showAdd: Bool
    
    init(viewModel: SettingsViewModel, showAdd: Bool = false) {
        self.viewModel = viewModel
        _showAdd = State(initialValue: showAdd)
    }
    
    static func presentAddSheetAction(isPresented: Binding<Bool>) -> () -> Void {
        { isPresented.wrappedValue = true }
    }
    
    static func destination(viewModel: SettingsViewModel) -> (InjuryProfile) -> EditInjuryView {
        { injury in
            EditInjuryView(injury: injury, viewModel: viewModel)
        }
    }
    
    static func addSheetContent(viewModel: SettingsViewModel) -> () -> AddInjurySheet {
        { AddInjurySheet(viewModel: viewModel) }
    }

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
                Button(action: Self.presentAddSheetAction(isPresented: $showAdd)) { Image(systemName: "plus") }
            }
        }
        .navigationDestination(for: InjuryProfile.self, destination: Self.destination(viewModel: viewModel))
        .sheet(isPresented: $showAdd, content: Self.addSheetContent(viewModel: viewModel))
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
    
    static func resolveAction(
        injury: InjuryProfile,
        viewModel: SettingsViewModel,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            viewModel.resolveInjury(injury)
            dismiss()
        }
    }
    
    static func saveAction(
        injury: InjuryProfile,
        viewModel: SettingsViewModel,
        location: String,
        limitations: String,
        recoveryGoal: String,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            viewModel.updateInjury(injury, location: location, limitations: limitations, recoveryGoal: recoveryGoal)
            dismiss()
        }
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
                    Button("Mark as Resolved", role: .destructive, action: Self.resolveAction(
                        injury: injury,
                        viewModel: viewModel,
                        dismiss: dismiss.callAsFunction
                    ))
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.cream)
        .navigationTitle("Edit Injury")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: Self.saveAction(
                    injury: injury,
                    viewModel: viewModel,
                    location: location,
                    limitations: limitations,
                    recoveryGoal: recoveryGoal,
                    dismiss: dismiss.callAsFunction
                ))
            }
        }
    }
}

struct AddInjurySheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var location: String
    @State private var limitations: String
    @State private var recoveryGoal: String
    
    init(
        viewModel: SettingsViewModel,
        location: String = "",
        limitations: String = "",
        recoveryGoal: String = ""
    ) {
        self.viewModel = viewModel
        _location = State(initialValue: location)
        _limitations = State(initialValue: limitations)
        _recoveryGoal = State(initialValue: recoveryGoal)
    }
    
    static func saveAction(
        viewModel: SettingsViewModel,
        location: String,
        limitations: String,
        recoveryGoal: String,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            guard !location.isEmpty else { return }
            viewModel.addInjury(location: location, limitations: limitations, recoveryGoal: recoveryGoal)
            dismiss()
        }
    }

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
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: dismiss.callAsFunction) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        location: location,
                        limitations: limitations,
                        recoveryGoal: recoveryGoal,
                        dismiss: dismiss.callAsFunction
                    ))
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
        case .terms:   return LegalContent.termsOfService
        case .privacy: return LegalContent.privacyPolicy
        case .medical: return LegalContent.medicalDisclaimer
        }
    }
}
