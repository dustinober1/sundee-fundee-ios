import SwiftUI
import SwiftData

/// Settings — profile, injury profiles, legal sections.
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
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
                    NavigationLink("Body Weight") {
                        BodyWeightSettingView(viewModel: viewModel)
                    }
                }

                // Subscription
                Section("Premium") {
                    NavigationLink("Manage Subscription") {
                        SubscriptionManagementView()
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
                    Button("Delete Account & All Data", role: .destructive) {
                        showDeleteAccountConfirm = true
                    }
                    .foregroundStyle(.red)
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
        .confirmationDialog(
            "Delete Account & All Data?",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                appState.deleteAccountAndData(modelContext: modelContext)
            }
        } message: {
            Text("This will permanently delete your profile, workouts, benchmarks, injury data, and all other app data. This action cannot be undone.")
        }
        .task { await viewModel.load(modelContext: modelContext, userID: appState.currentUserID ?? "") }
    }
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    static func shouldHideCycleToggle(for gender: Gender) -> Bool {
        gender == .male
    }

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
            Section("Weight Unit") {
                Picker("Unit", selection: $viewModel.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.symbol.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Body Weight (optional)") {
                HStack {
                    TextField("Body weight", value: $viewModel.bodyWeight, format: .number)
                        .keyboardType(.decimalPad)
                    Text(viewModel.weightUnit.symbol)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }
            }
            Section("Biological Sex") {
                Picker("Sex", selection: $viewModel.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .onChange(of: viewModel.gender) { _, newValue in
                    if newValue == .male {
                        viewModel.cycleTrackingEnabled = false
                    }
                }
            }
            if !Self.shouldHideCycleToggle(for: viewModel.gender) {
                Section("Cycle Tracking") {
                    Toggle("Enable cycle-aware training", isOn: $viewModel.cycleTrackingEnabled)
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
                ForEach(viewModel.transitionSuggestions, id: \.injuryID) { suggestion in
                    PhaseTransitionBanner(
                        suggestion: suggestion,
                        injuryName: viewModel.injuryProfiles.first(where: { $0.id == suggestion.injuryID })?.location ?? "Injury",
                        onAccept: { viewModel.acceptTransition(suggestion) },
                        onDismiss: { viewModel.dismissTransition(suggestion) }
                    )
                }
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
                            InjuryRow(injury: injury, painLogs: viewModel.painLogs[injury.id] ?? [])
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
    var painLogs: [PainLog] = []

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
                if !painLogs.isEmpty {
                    HStack(spacing: 4) {
                        PainSparkline(data: PainTrendAnalyzer.sparklineData(logs: painLogs))
                        if let latest = painLogs.first {
                            Text("\(latest.painLevel)/10")
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(injury.isActive ? "Active" : "Resolved")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(injury.isActive ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.4))
                if injury.isActive {
                    Text(injury.recoveryPhase.displayName)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PainSparkline

struct PainSparkline: View {
    let data: [Int]

    var body: some View {
        Canvas { context, size in
            guard data.count >= 2 else { return }
            let maxVal = Double(max(data.max() ?? 10, 1))
            let stepX = size.width / Double(data.count - 1)
            var path = Path()
            for (index, value) in data.enumerated() {
                let x = stepX * Double(index)
                let y = size.height - (Double(value) / maxVal) * size.height
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(Color(AppTheme.Colors.accentOrange)), lineWidth: 1.5)
        }
        .frame(width: 50, height: 20)
    }
}

// MARK: - PainCheckInView

struct PainCheckInView: View {
    let injury: InjuryProfile
    let onSubmit: (Int, String?) -> Void
    @State private var painLevel: Int = 5
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("How's your \(injury.location) feeling?") {
                    Stepper("Pain Level: \(painLevel)/10", value: $painLevel, in: 1...10)
                }
                Section("Notes (optional)") {
                    TextField("Any observations...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Pain Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: dismiss.callAsFunction) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        onSubmit(painLevel, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditInjuryView: View {
    let injury: InjuryProfile
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var location: String
    @State private var limitations: String
    @State private var recoveryGoal: String
    @State private var selectedPhase: RecoveryPhase

    init(injury: InjuryProfile, viewModel: SettingsViewModel) {
        self.injury = injury
        self.viewModel = viewModel
        _location = State(initialValue: injury.location)
        _limitations = State(initialValue: injury.movementLimitations)
        _recoveryGoal = State(initialValue: injury.recoveryGoal)
        _selectedPhase = State(initialValue: injury.recoveryPhase)
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
        selectedPhase: RecoveryPhase,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            viewModel.updateInjury(injury, location: location, limitations: limitations, recoveryGoal: recoveryGoal, recoveryPhase: selectedPhase)
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
            Section("Recovery Phase") {
                Picker("Phase", selection: $selectedPhase) {
                    ForEach(RecoveryPhase.allCases, id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
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
                    selectedPhase: selectedPhase,
                    dismiss: dismiss.callAsFunction
                ))
            }
            if injury.isActive {
                ToolbarItem(placement: .bottomBar) {
                    Button("Resolve Injury", role: .destructive, action: Self.resolveAction(
                        injury: injury,
                        viewModel: viewModel,
                        dismiss: dismiss.callAsFunction
                    ))
                }
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
    @State private var selectedRegions: Set<BodyLocation.Region>

    init(
        viewModel: SettingsViewModel,
        location: String = "",
        limitations: String = "",
        recoveryGoal: String = "",
        selectedRegions: Set<BodyLocation.Region> = []
    ) {
        self.viewModel = viewModel
        _location = State(initialValue: location)
        _limitations = State(initialValue: limitations)
        _recoveryGoal = State(initialValue: recoveryGoal)
        _selectedRegions = State(initialValue: selectedRegions)
    }

    static func canSave(location: String, selectedRegions: Set<BodyLocation.Region>) -> Bool {
        !selectedRegions.isEmpty || !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func saveAction(
        viewModel: SettingsViewModel,
        location: String,
        limitations: String,
        recoveryGoal: String,
        selectedRegions: Set<BodyLocation.Region>,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            let effectiveLocation = selectedRegions.isEmpty ? location : selectedRegions.map(\.displayName).sorted().joined(separator: ", ")
            guard !effectiveLocation.isEmpty else { return }
            viewModel.addInjury(location: effectiveLocation, limitations: limitations, recoveryGoal: recoveryGoal, locationRegions: Array(selectedRegions))
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Body Region") {
                    BodyMapView(selectedRegions: $selectedRegions)
                }
                Section("Additional Notes") {
                    TextField("e.g. ACL tear, rotator cuff", text: $location)
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
                        selectedRegions: selectedRegions,
                        dismiss: dismiss.callAsFunction
                    ))
                    .disabled(!Self.canSave(location: location, selectedRegions: selectedRegions))
                }
            }
        }
    }
}

// MARK: - PhaseTransitionBanner

struct PhaseTransitionBanner: View {
    let suggestion: PhaseTransitionAdvisor.Suggestion
    let injuryName: String
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                Text("Ready to advance?")
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
            }
            Text("\(injuryName): \(suggestion.currentPhase.displayName) → \(suggestion.suggestedPhase.displayName)")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.7))
            HStack(spacing: 12) {
                Button("Advance", action: onAccept)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Not Yet", action: onDismiss)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.accentOrange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .listRowBackground(Color.clear)
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
