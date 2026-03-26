// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SundeeFundeeShared",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "SundeeFundeeShared", targets: ["SundeeFundeeShared"]),
    ],
    targets: [
        .target(name: "SundeeFundeeShared"),
    ]
)
