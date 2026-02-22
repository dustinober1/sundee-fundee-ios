import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Environment(AuthenticationViewModel.self) private var authViewModel

    private var currentUser: User? { users.first }
    private var isGuest: Bool { authViewModel.authState == .guest }

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                List {
                    if !isGuest, let user = currentUser {
                        Section("Profile") {
                            LabeledContent("Name", value: user.name)
                            LabeledContent("Experience", value: user.experienceLevel.rawValue.capitalized)
                            LabeledContent("Goal", value: user.primaryGoal.rawValue.capitalized)
                            Picker("Gender", selection: Binding(
                                get: { user.gender },
                                set: {
                                    user.gender = $0
                                    try? modelContext.save()
                                }
                            )) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Text(g.displayName).tag(g)
                                }
                            }
                        }

                        Section("1RM Management") {
                            NavigationLink("View & Edit 1RMs") {
                                OneRepMaxManagementView()
                            }
                        }

                        Section("Training Preferences") {
                            NavigationLink("Rest Timer Defaults") {
                                Text("Rest timer settings — Phase 9")
                            }
                        }

                        Section("Sync") {
                            LabeledContent("CloudKit", value: "Active")
                            Text("Data syncs automatically via iCloud")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if isGuest {
                        Section("Guest Mode") {
                            Text("You are browsing as a guest. Sign in with Apple anytime to save and sync your data.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        if isGuest {
                            Button("Sign In to Save Data") {
                                authViewModel.signOut()
                            }
                        } else {
                            Button("Sign Out", role: .destructive) {
                                authViewModel.signOut()
                            }
                        }
                    }

                    Section {
                        LabeledContent("Version", value: "1.0.0")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - 1RM Management

struct OneRepMaxManagementView: View {
    @Query(sort: \OneRepMax.date, order: .reverse)
    private var allOneRepMaxes: [OneRepMax]

    private var latestByExercise: [OneRepMax] {
        var seen: Set<String> = []
        return allOneRepMaxes.filter { orm in
            guard !seen.contains(orm.exerciseId) else { return false }
            seen.insert(orm.exerciseId)
            return true
        }
    }

    var body: some View {
        BrandBackgroundView {
            List {
                if latestByExercise.isEmpty {
                    Text("No 1RM data yet. Start a program to enter your maxes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(latestByExercise, id: \.id) { orm in
                        HStack {
                            Text(Exercises.find(byId: orm.exerciseId)?.name ?? orm.exerciseId)
                            Spacer()
                            Text("\(orm.weight, specifier: "%.0f") lbs")
                                .fontWeight(.semibold)
                            Text(orm.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("1RM Records")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [User.self, OneRepMax.self], inMemory: true)
        .environment(AuthenticationViewModel())
}
