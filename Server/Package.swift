// swift-tools-version: 6.2
// DayByWordServer: daybyword.com's pages, web app, and sync API, on
// Hummingbird 2 (D5). Dependencies are recorded in docs/decisions.md and
// pinned in Package.resolved.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "DayByWordServer",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "DayByWordServer", targets: ["DayByWordServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", .upToNextMinor(from: "2.28.0")),
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMinor(from: "1.8.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMinor(from: "1.16.2")),
        .package(path: "../Packages/ReadingEngine"),
        .package(path: "../Packages/ReadingData"),
    ],
    targets: [
        .target(
            name: "DayByWordWeb",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ReadingEngine", package: "ReadingEngine"),
                .product(name: "ReadingData", package: "ReadingData"),
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "DayByWordServer",
            dependencies: ["DayByWordWeb"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DayByWordWebTests",
            dependencies: [
                "DayByWordWeb",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
