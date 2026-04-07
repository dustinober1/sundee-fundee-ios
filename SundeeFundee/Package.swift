// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SundeeFundeeKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11)
    ],
    products: [
        // Core library with domain logic, data layer, auth, and subscription
        .library(
            name: "SundeeFundeeKit",
            targets: ["SundeeFundeeKit"]
        ),
    ],
    dependencies: [],
    targets: [
        // Core library target
        .target(
            name: "SundeeFundeeKit",
            dependencies: [],
            path: "Sources/SundeeFundeeKit"
        ),
        // Tests for core library
        .testTarget(
            name: "SundeeFundeeKitTests",
            dependencies: ["SundeeFundeeKit"],
            path: "Tests/SundeeFundeeKitTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

// NOTE: iOS App UI (SwiftUI views, view models) will be created in an Xcode project.
// To create the Xcode project:
// 1. In Xcode: File > New > Project > iOS App
// 2. Name it "SundeeFundee"
// 3. Add SundeeFundeeKit as a local package dependency
// 4. Copy UI files from SundeeFundeeKit/UI/ to the Xcode project
//
// UI structure (to be created in Xcode project):
// - App/
//   - SundeeFundeeApp.swift (main app entry point)
//   - ContentView.swift (TabView navigation)
// - Views/
//   - Dashboard/
//     - DashboardView.swift
//     - DashboardViewModel.swift
//   - Workouts/
//     - WorkoutsListView.swift
//     - WorkoutDetailView.swift
//   - Programs/
//     - ProgramsListView.swift
//     - ProgramDetailView.swift
//   - Maxes/
//     - MaxesListView.swift
//     - OneRepMaxEntryView.swift
//   - Settings/
//     - SettingsView.swift
// - Theme/
//   - AppTheme.swift (Art Deco design tokens)
//   - AppButton.swift
//   - AppCard.swift
// - ViewModels/
//   - AuthViewModel.swift
//   - SubscriptionViewModel.swift
