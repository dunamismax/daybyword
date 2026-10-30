// swift-tools-version: 6.2
// ReadingEngine: references, schedules, progress, and reminder rules.
// Foundation only, and built and tested on macOS and Linux (AGENTS.md §5).

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "ReadingEngine",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ReadingEngine", targets: ["ReadingEngine"])
    ],
    targets: [
        .target(name: "ReadingEngine", swiftSettings: swiftSettings),
        .testTarget(
            name: "ReadingEngineTests",
            dependencies: ["ReadingEngine"],
            swiftSettings: swiftSettings
        ),
    ]
)
