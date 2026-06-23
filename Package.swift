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
            name: "Parseable ASCII Primitives",
            targets: ["Parseable ASCII Primitives"]
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
        .package(url: "https://github.com/swift-primitives/swift-ascii-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-parser-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-shared-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Sub-namespace

        // Owns `extension ASCII { protocol Parseable }` — the ASCII-substrate
        // sibling protocol. Extends the upstream `ASCII` namespace, so it has
        // no zero-dep root of its own (discipline package, [MOD-017]/§7).
        .target(
            name: "Parseable ASCII Primitives",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),

        // MARK: - Core (transitional shim)

        // DEPRECATED — exports-only shim (L1 core-dissolution sweep 2026-06-23).
        // Re-exports the dissolved Core surface; removed in the cleanup wave.
        .target(
            name: "ASCII Parser Primitives Core",
            dependencies: [
                "Parseable ASCII Primitives",
                .product(name: "Parser Primitives Core", package: "swift-parser-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),

        // MARK: - Subject Domains

        .target(
            name: "ASCII Decimal Parser Primitives",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
                .product(name: "Parser Primitives Core", package: "swift-parser-primitives"),
            ]
        ),
        .target(
            name: "ASCII Hexadecimal Parser Primitives",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
                .product(name: "Parser Primitives Core", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Conformances

        .target(
            name: "ASCII Parser Primitives Standard Library Integration",
            dependencies: [
                "ASCII Decimal Parser Primitives",
                "Parseable ASCII Primitives",
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
                .product(name: "Shared Primitive", package: "swift-shared-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "ASCII Parser Primitives",
            dependencies: [
                "Parseable ASCII Primitives",
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
            ],
            // Swift 6.3.2 compiler ICE in opaque-return type-checking of
            // `var body: some Parser_Primitives.Parser.`Protocol`<TypeParam, Output, Error>`
            // when the test target depends on `Parser_Primitives_Test_Support`.
            // FIXED upstream in Swift 6.4-dev (snapshot 2026-05-12-a).
            // Remove this exclude when the workspace migrates to Swift 6.4+.
            // See swift-institute/Issues/swift-issue-parameterized-typealias-opaque-return-ice/
            // and swift-institute/Research/swift-compiler-bug-catalog.md § A8.
            exclude: ["Declarative Parser Syntax Tests.swift"]
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
