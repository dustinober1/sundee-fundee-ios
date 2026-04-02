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
        .library(
            name: "SundeeFundeeKit",
            targets: ["SundeeFundeeKit"]
        ),
    ],
    targets: [
        .target(
            name: "SundeeFundeeKit",
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
