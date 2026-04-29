import CloudKit
import SwiftUI
import SundeeFundeeKit
import os.log
#if canImport(UserNotifications)
import UserNotifications
#endif

private let appLogger = Logger(subsystem: "com.sundeefundee.app", category: "AppStartup")

@main
struct SundeeFundeeMain: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()
    @State private var starterWorkout: Workout?

    private static let isScreenshotMode = CommandLine.arguments.contains("--seed-screenshots")

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    if authViewModel.needsOnboarding {
                        OnboardingView {
                            authViewModel.completeOnboarding()
                        } onStartFirstWorkout: { workout in
                            starterWorkout = workout
                            authViewModel.completeOnboarding()
                        }
                    } else {
                        MainTabView()
                            .environmentObject(authViewModel)
                            .environmentObject(themeViewModel)
                    }
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
            .artDecoBackground()
            .onAppear {
                themeViewModel.applyTheme()
                #if canImport(UserNotifications)
                if #available(iOS 18.0, *) {
                    UNUserNotificationCenter.current().delegate = WorkoutReminderNotificationDelegate.shared
                }
                #endif
                // Force-load App Shortcuts provider so iOS discovers intents
                // declared inside the SundeeFundeeKit package.
                _ = SundeeFundeeShortcuts.self
                Task {
                    let container = CKContainer(identifier: "iCloud.com.sundeefundee.app")
                    do {
                        let status = try await container.accountStatus()
                        switch status {
                        case .available:
                            appLogger.info("☁️ iCloud: AVAILABLE")
                        case .noAccount:
                            appLogger.error("☁️ iCloud: NO ACCOUNT — user not signed into iCloud")
                        case .restricted:
                            appLogger.error("☁️ iCloud: RESTRICTED")
                        case .couldNotDetermine:
                            appLogger.error("☁️ iCloud: COULD NOT DETERMINE")
                        case .temporarilyUnavailable:
                            appLogger.error("☁️ iCloud: TEMPORARILY UNAVAILABLE")
                        @unknown default:
                            appLogger.error("☁️ iCloud: UNKNOWN STATUS")
                        }
                    } catch {
                        appLogger.error("☁️ iCloud status check failed: \(error.localizedDescription)")
                    }
                    let client = DataClientFactory.shared.client
                    appLogger.info("📦 Active DataClient: \(String(describing: type(of: client)))")
                    appLogger.info("👤 Auth: authenticated=\(authViewModel.isAuthenticated), guest=\(authViewModel.isGuest)")
                }
            }
            .task {
                if Self.isScreenshotMode {
                    await ScreenshotSeeder.seed()
                    // Restore auth state after seeding
                    authViewModel.isGuest = true
                    authViewModel.userID = AuthViewModel.guestUserID
                    authViewModel.userName = "Sarah"
                    authViewModel.isAuthenticated = true
                    authViewModel.needsOnboarding = false
                }
            }
            .sheet(item: $starterWorkout) { workout in
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutSessionViewModel(workout: workout)
                )
            }
        }
    }
}
