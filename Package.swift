// swift-tools-version: 6.3.1

import PackageDescription

// ASCII Parser Primitives - Tier 18
//
// Subject-first ASCII parsing types: ASCII.Decimal.Parser, ASCII.Hexadecimal.Parser.
// Bridges ascii-primitives (Tier 0) with parser-primitives (Tier 17).

let package = Package(
    name: "swift-ascii-parser-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "ASCII Parser Primitives Core",
            targets: ["ASCII Parser Primitives Core"]
        ),
        .library(
            name: "ASCII Decimal Parser Primitives",
            targets: ["ASCII Decimal Parser Primitives"]
        ),
        .library(
            name: "ASCII Hexadecimal Parser Primitives",
            targets: ["ASCII Hexadecimal Parser Primitives"]
        ),
        .library(
            name: "ASCII Parser Primitives Standard Library Integration",
            targets: ["ASCII Parser Primitives Standard Library Integration"]
        ),
        .library(
            name: "ASCII Parser Primitives",
            targets: ["ASCII Parser Primitives"]
        ),
        .library(
            name: "ASCII Parser Primitives Test Support",
            targets: ["ASCII Parser Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-ascii-primitives"),
        .package(path: "../swift-byte-parser-primitives"),
        .package(path: "../swift-parser-primitives"),
    ],
    targets: [
        // MARK: - Core

        .target(
            name: "ASCII Parser Primitives Core",
            dependencies: [
                .product(name: "Parser Primitives Core", package: "swift-parser-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),

        // MARK: - Subject Domains

        .target(
            name: "ASCII Decimal Parser Primitives",
            dependencies: [
                "ASCII Parser Primitives Core",
            ]
        ),
        .target(
            name: "ASCII Hexadecimal Parser Primitives",
            dependencies: [
                "ASCII Parser Primitives Core",
            ]
        ),

        // MARK: - Conformances

        .target(
            name: "ASCII Parser Primitives Standard Library Integration",
            dependencies: [
                "ASCII Decimal Parser Primitives",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "ASCII Parser Primitives",
            dependencies: [
                "ASCII Decimal Parser Primitives",
                "ASCII Hexadecimal Parser Primitives",
                "ASCII Parser Primitives Standard Library Integration",
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "ASCII Decimal Parser Primitives Tests",
            dependencies: [
                "ASCII Decimal Parser Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),
        .testTarget(
            name: "ASCII Hexadecimal Parser Primitives Tests",
            dependencies: [
                "ASCII Hexadecimal Parser Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),
        .testTarget(
            name: "ASCII Parser Primitives Standard Library Integration Tests",
            dependencies: [
                "ASCII Parser Primitives Standard Library Integration",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),
        .testTarget(
            name: "Declarative Parser Syntax Tests",
            dependencies: [
                "ASCII Decimal Parser Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "ASCII Parser Primitives Test Support",
            dependencies: [
                "ASCII Parser Primitives",
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
            ],
            path: "Tests/Support"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
