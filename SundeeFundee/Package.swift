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
        // Shared library imported by the iOS app, widget extension, and tests.
        .library(
            name: "SundeeFundeeKit",
            targets: ["SundeeFundeeKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SundeeFundeeKit",
            dependencies: [],
            path: "Sources/SundeeFundeeKit"
        ),
        .testTarget(
            name: "SundeeFundeeKitTests",
            dependencies: ["SundeeFundeeKit"],
            path: "Tests/SundeeFundeeKitTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
