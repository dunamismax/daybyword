// swift-tools-version: 6.2
// ReadingData: the SQLite wrapper, the catalog reader, the journal, and the
// sync client. Foundation and the system SQLite3 library only, and built and
// tested on macOS and Linux (AGENTS.md §5).

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "ReadingData",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ReadingData", targets: ["ReadingData"])
    ],
    dependencies: [
        .package(path: "../ReadingEngine")
    ],
    targets: [
        // Apple platforms import the SDK's SQLite3 module; Linux uses the
        // system library (libsqlite3-dev) through this module map.
        .systemLibrary(
            name: "CSQLite",
            providers: [.apt(["libsqlite3-dev"])]
        ),
        .target(
            name: "ReadingData",
            dependencies: [
                .product(name: "ReadingEngine", package: "ReadingEngine"),
                .target(name: "CSQLite", condition: .when(platforms: [.linux])),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ReadingDataTests",
            dependencies: ["ReadingData"],
            swiftSettings: swiftSettings
        ),
    ]
)
