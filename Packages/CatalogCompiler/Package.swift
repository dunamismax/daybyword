// swift-tools-version: 6.2
// CatalogCompiler: the `catalog` tool, which validates catalog/, evaluates
// calendar rules, and writes Catalog.sqlite. Foundation only, and built and
// tested on macOS and Linux (AGENTS.md §5).

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "CatalogCompiler",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "catalog", targets: ["catalog"])
    ],
    dependencies: [
        .package(path: "../ReadingEngine"),
        .package(path: "../ReadingData"),
    ],
    targets: [
        .target(
            name: "CatalogCompiler",
            dependencies: [
                .product(name: "ReadingEngine", package: "ReadingEngine"),
                .product(name: "ReadingData", package: "ReadingData"),
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "catalog",
            dependencies: ["CatalogCompiler"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CatalogCompilerTests",
            dependencies: [
                "CatalogCompiler",
                .product(name: "ReadingData", package: "ReadingData"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
