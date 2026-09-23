// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftAppToolkit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
    ],
    products: [
        .library(name: "AppLogger", targets: ["AppLogger"]),
        .library(name: "FeatureFlags", targets: ["FeatureFlags"]),
    ],
    targets: [
        .target(name: "AppLogger"),
        .target(name: "FeatureFlags"),
    ]
)
